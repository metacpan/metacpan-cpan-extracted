package POE::Component::DirWatch::Object::NewFile;
use strict;
use warnings;
use Moose;
use POE;

our $VERSION = "0.1200";

extends 'POE::Component::DirWatch::Object';

has 'seen_files' => (is => 'rw', isa => 'HashRef', default => sub{{}});

#--------#---------#---------#---------#---------#---------#---------#---------#

override '_dispatch' => sub{
    my ($self, $kernel, $fname, $fpath) = @_[OBJECT, KERNEL, ARG0, ARG1];

    return if( $self->seen_files->{ $fpath } );
    $self->seen_files->{ $fpath } = 1;
    super;
};

before '_poll' => sub{
    my $self = shift;

    %{ $self->seen_files } = map {$_ => $self->seen_files->{$_} }
	grep {-e $_ } keys %{ $self->seen_files };
};

1;

__END__;

#--------#---------#---------#---------#---------#---------#---------#---------#


=head1 NAME

POE::Component::DirWatch::Object::NewFile

=head1 SYNOPSIS

  use POE::Component::DirWatch::Object::NewFile;

  #$watcher is a PoCo::DW:Object::NewFile
  my $watcher = POE::Component::DirWatch::Object::NewFile->new
    (
     alias      => 'dirwatch',
     directory  => '/some_dir',
     filter     => sub { $_[0] =~ /\.gz$/ && -f $_[1] },
     callback   => \&some_sub,
     interval   => 1,
    );

  $poe_kernel->run;

=head1 DESCRIPTION

POE::Component::DirWatch::Object::NewFile extends DirWatch::Object in order to
exclude files that have already been processed

=head1 Accessors

=head2 seen_files

Read-write. Will return a hash ref in with keys will be the full path
of all previously processed documents.

=head1 Extended methods

=head2 dispatch

C<override 'dispatch'>  Don't dispatch if file has been seen.

=head2 poll

C<before 'poll'> the list of known files is checked and if any of the files no
longer exist they are removed from the list of known files to avoid the list
growing out of control.

=head2 meta

Keeping tests happy.

=head1 SEE ALSO

L<POE::Component::DirWatch::Object>, L<Moose>

=head1 AUTHOR

Guillermo Roditi, <groditi@cpan.org>

Please report any bugs or feature requests to
C<bug-poe-component-dirwatch-object at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-DirWatch-Object>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::DirWatch::Object::NewFile

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

