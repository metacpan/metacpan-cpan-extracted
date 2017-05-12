package POE::Component::DirWatch::Object::Untouched;
use strict;
use warnings;
use Moose;
use Array::Compare;
use POE;

our $VERSION = "0.1200";

extends 'POE::Component::DirWatch::Object';

has 'stat_interval'=> (is => 'rw', isa => 'Num', required => 1, default => 1);
has 'cmp'          => (is => 'rw', isa => 'Object', required => 1,
		       default => sub{ Array::Compare->new } );

#--------#---------#---------#---------#---------#---------#---------#---------#

#Remind me of stat:
#    7 size     total size of file, in bytes
#    8 atime    last access time in seconds since the epoch
#    9 mtime    last modify time in seconds since the epoch
#   10 ctime    inode change time in seconds since the epoch (*)

before '_start' => sub{
    my ($self, $kernel) = @_[OBJECT, KERNEL];
    $kernel->state('stat_check', $self, '_stat_check');
};

override '_dispatch' => sub{
    my ($self, $kernel, @params) = @_[OBJECT, KERNEL, ARG0, ARG1];
    return unless $self->filter->(@params);

    $kernel->delay(stat_check => $self->stat_interval,
		   \@params, [ ( stat($_->[1]) )[7..10] ]
		  )
};

sub _stat_check{
    my ($self, $kernel, $params, $stats) = @_[OBJECT, KERNEL, ARG0, ARG1];
    $kernel->yield(callback => $params)
	if $self->cmp->compare($stats, [ ( stat($params->[1]) )[7..10] ]);
}


1;

__END__;

#--------#---------#---------#---------#---------#---------#---------#---------#


=head1 NAME

POE::Component::DirWatch::Object::Untouched

=head1 SYNOPSIS

  use POE::Component::DirWatch::Object::Untouched;

  #$watcher is a PoCo::DW:Object::Untouched
  my $watcher = POE::Component::DirWatch::Object::Untouched->new
    (
     alias         => 'dirwatch',
     directory     => '/some_dir',
     filter        => sub { $_[0] =~ /\.gz$/ && -f $_[1] },
     callback      => \&some_sub,
     interval      => 5,
     stat_interval => 2, #pick up files if they are untouched after 2 seconds
    );

  $poe_kernel->run;

=head1 DESCRIPTION

POE::Component::DirWatch::Object::Untouched extends DirWatch::Object in order to
exclude files that appear to be in use or are actively being changed.

=head1 Accessors

=head2 stat_interval

Read-Write. An integer value that specifies how many seconds to wait in between the
call to dispatch and the actual dispatch. The interval here serves as a dead period
in between when the initial stat readings are made and the second reading is made
(the one that determines whether there was any change or not). Note that the
C<interval> in C<POE::Component::DirWatch::Object> will be delayed by this length.
See C<_stat_check> for details.

=head2 cmp

An Array::Compare object

=head1 Extended methods

=head2 _start

C<after '_start'> the kernel is called and a new 'stat_check' event is added.

=head2 _dispatch

C<override '_dispatch'> to delay and delegate the dispatching to _stat_check.
Filtering still happens at this stage.

=head1 New Methods

=head2 _stat_check

Schedule a callback event for every file whose contents have not changed since the
C<poll> event. After all callbacks are scheduled, set an alarm for the next poll.

ARG0 should be the proper params for C<callback> and ARG1 the original C<stat()>
reading we are comparing against.

=head2 meta

Keeping tests happy.

=head1 SEE ALSO

L<POE::Component::DirWatch::Object>, L<Moose>

=head1 AUTHOR

Guillermo Roditi, <groditi@cpan.org>

=head1 BUGS

If a file is created and deleted between polls it will never be seen. Also if a file
is edited more than once in between polls it will never be picked up.

Please report any bugs or feature requests to
C<bug-poe-component-dirwatch-object at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-DirWatch-Object>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::DirWatch::Object::Untouched

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-DirWatch-Object>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-DirWatch-Object>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-DirWatch-Object>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-DirWatch-Object>

=back

=head1 ACKNOWLEDGEMENTS

People who answered way too many questions from an inquisitive idiot:

=over 4

=item #PoE & #Moose

=item Matt S Trout <mst@shadowcatsystems.co.uk>

=item Rocco Caputo

=back

=head1 COPYRIGHT

Copyright 2006 Guillermo Roditi.  All Rights Reserved.  This is
free software; you may redistribute it and/or modify it under the same
terms as Perl itself.

=cut

