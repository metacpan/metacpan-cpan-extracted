package POE::Component::DirWatch::Object::Touched;
use strict;
use warnings;
use Moose;
use Array::Compare;
use POE;

our $VERSION = "0.1200";

extends 'POE::Component::DirWatch::Object::NewFile';

has 'cmp' => (is => 'rw', isa => 'Object', required => 1,
	      default => sub{ Array::Compare->new } );

#--------#---------#---------#---------#---------#---------#---------#---------#

#Remind me of stat:
#    7 size     total size of file, in bytes
#    8 atime    last access time in seconds since the epoch
#    9 mtime    last modify time in seconds since the epoch
#   10 ctime    inode change time in seconds since the epoch (*)

#clean seen files from dispatch list

override '_dispatch' => sub{
    my ($self, $kernel, $fname,$fpath) = @_[OBJECT, KERNEL, ARG0, ARG1];

    if( exists $self->seen_files->{ $fpath } ){
	return if $self->cmp->compare( $self->seen_files->{ $fpath },
				       [ ( stat($fpath) )[7..10] ]);
    }

    $self->seen_files->{$fpath} = [ ( stat($fpath) )[7..10] ];
    $kernel->yield(callback => [$fname, $fpath])
	if $self->filter->($fname,$fpath);
};


1;

__END__;

#--------#---------#---------#---------#---------#---------#---------#---------#


=head1 NAME

POE::Component::DirWatch::Object::Touched

=head1 SYNOPSIS

  use POE::Component::DirWatch::Object::Touched;

  #$watcher is a PoCo::DW:Object::Touched
  my $watcher = POE::Component::DirWatch::Object::Touched->new
    (
     alias      => 'dirwatch',
     directory  => '/some_dir',
     filter     => sub { $_[0] =~ /\.gz$/ && -f $_[1] },
     callback   => \&some_sub,
     interval   => 1,
    );

  $poe_kernel->run;

=head1 DESCRIPTION

POE::Component::DirWatch::Object::Touched extends DirWatch::Object::NewFile in order to
exclude files that have already been processed, but still pick up files that have been
changed.

=head1 Accessors

=head2 seen_files

Read-write. Will return a hash ref in with keys will be the full path
of all previously processed documents that still exist in the file system and the
values are listrefs containing the size and last changed dates of the files.
C<[ ( stat($file) )[7..10] ]>

=head2 cmp

An Array::Compare object

=head1 Extended methods

=head2 dispatch

C<override 'dispatch'>  Don't dispatch if file has been seen before and has the
same values for C<stat($file)[7..10]>

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

    perldoc POE::Component::DirWatch::Object::Touched

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

