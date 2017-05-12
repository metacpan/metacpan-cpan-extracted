package POE::Component::DirWatch::WithCaller;

our $VERSION = "1.00";

use 5.006;
use strict;
use warnings;
use Moose;
use POE;

extends 'POE::Component::DirWatch';

has ignore_seen => (
	is => 'ro',
	isa => 'Int',
	required => 1,
	default => 0,
);
has ensure_seen => (
	is => 'ro',
	isa => 'Int',
	required => 0,
	default => 0,
);
has seen_files => (
	is => 'rw',
	isa => 'HashRef',
	default => sub{{}},
);

override '_poll' => sub {
	# the vast majority of this is copied from POE::Component::DirWatch's _poll subroutine by virtue of not being able to call super
	my ($self, $kernel) = @_[OBJECT, KERNEL];
	$self->clear_next_poll;

	# seen_files portions borrowed from POE::Component::DirWatch::Object::NewFile
	%{ $self->seen_files } = map {$_ => $self->seen_files->{$_} } grep {-e $_ } keys %{ $self->seen_files };
	my $filter = $self->has_filter ? $self->filter : undef;
	my $has_dir_cb  = $self->has_dir_callback;
	my $has_file_cb = $self->has_file_callback;

	while (my $child = $self->directory->next) {
		if($child->is_dir) {
			next unless $has_dir_cb;
			next if ref $filter && !$filter->($self->alias, $child);
			$kernel->yield(dir_callback => $child);
		} else {
			next unless $has_file_cb;
			next if $child->basename =~ /^\.+$/;
			$self->seen_files->{"$child"} = 0 if not defined $self->seen_files->{"$child"};
			next unless $self->seen_files->{"$child"} == 0 or $self->seen_files->{"$child"} > 120 or not $self->ignore_seen;
			$self->seen_files->{"$child"}++ unless ($self->seen_files->{"$child"}*$self->interval) > 120 and $self->seen_files->{"$child"} = -1;
			$self->seen_files->{"$child"} = 1 if $self->ignore_seen and not $self->ensure_seen;
			next if ref $filter && !$filter->($self->alias, $child);
			$kernel->yield(file_callback => $child);
		}
	}
	$self->next_poll( $kernel->delay_set(poll => $self->interval) );
};

override '_file_callback' => sub {
	my ($self, $kernel, $file) = @_[OBJECT, KERNEL, ARG0];
	$self->file_callback->($self->alias, $file);
};

override '_dir_callback' => sub {
	my ($self, $kernel, $dir) = @_[OBJECT, KERNEL, ARG0];
	$self->dir_callback->($self->alias, $dir);
};

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::DirWatch::WithCaller - An extension to POE::Component::DirWatch to pass through the name of the calling DirWatch instance, useful for cases where DirWatch sessions may be dynamically created while sharing callback functions whose behaviour may differ in small ways depending on the caller.

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

Somewhat simple extension to L<POE::Component::DirWatch> that passes the name of the calling DirWatch session to callback functions.

	sub filter { my ($caller,$file) = @_; return 1; }
	sub file { my ($caller,$file) = @_; }
	my $monitor = POE::Component::DirWatch::WithCaller->new(
		alias			=> 'mymonitor',
		directory		=> '/my/path',
		filter			=> \&filter,
		file_callback	=> \&file,
		interval		=> 5,
	);

Filtering already-seen files can be achieved as such:

	sub filter { my ($caller,$file) = @_; return 1; }
	sub file { my ($caller,$file) = @_; }
	my $monitor = POE::Component::DirWatch::WithCaller->new(
		alias			=> 'mymonitor',
		directory		=> '/my/path',
		filter			=> \&filter,
		file_callback	=> \&file,
		interval		=> 5,
		ignore_seen		=> 1,
	);

In some instances, using C<ignore_seen> may result in some files being internally marked as 'seen' without being filtered or sent through callbacks, see below.

=head1 FILTERING PREVIOUSLY-SEEN FILES

Depending on use case, it may be beneficial or necessary to filter out previously-seen files, either for performance reasons when monitoring highly populous directories for specific files, or for avoiding reprocessing files in the event that they are left in the directory after initial processing.
In this case, simply specifying C<ignore_seen =E<gt> 1> as a named argument when creating the DirWatch::WithCaller object will enable this behaviour.
While testing this feature, however, it was observed that some edge cases exist in which a file will be considered 'seen' when it has not been processed despite matching a defined monitor. To account for this, each file that has been considered 'seen' will be reprocessed once around 120 seconds after it was first 'seen'. This behaviour may not be desirable, and as such is disabled by default, and can be enabled by specifying C<ensure_seen =E<gt> 1> when creating the object.


=head1 AUTHOR

Matthew Connelly, C<< <maff at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-dirwatch-withcaller at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-DirWatch-WithCaller>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::DirWatch::WithCaller


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-DirWatch-WithCaller>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-DirWatch-WithCaller>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-DirWatch-WithCaller>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-DirWatch-WithCaller/>

=back


=head1 ACKNOWLEDGEMENTS

Guillermo Roditi, <groditi@cpan.org>
Robert Rothenberg, <rrwo@cpan.org>

=head1 SEE ALSO

L<POE::Component::DirWatch>, L<POE::Component::DirWatch::Object::NewFile>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Matthew Connelly.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

