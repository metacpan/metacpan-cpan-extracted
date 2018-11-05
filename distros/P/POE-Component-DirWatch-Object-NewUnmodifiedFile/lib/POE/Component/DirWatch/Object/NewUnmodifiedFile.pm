package POE::Component::DirWatch::Object::NewUnmodifiedFile;
# ABSTRACT: extends DirWatch::Object in order to exclude files that have already been processed

use strict;
use warnings;
use Moose;
use POE;

our $VERSION = "0.002";

extends 'POE::Component::DirWatch::Object';

has 'seen_files' => (is => 'rw', isa => 'HashRef', default => sub{{}});

#--------#---------#---------#---------#---------#---------#---------#---------#

override '_dispatch' => sub{
    my ($self, $kernel, $fname, $fpath) = @_[OBJECT, KERNEL, ARG0, ARG1];

    return if( $self->seen_files->{ $fpath } );

    # Get last modify time of file
    my $mtime = get_mtime($fpath);

    $self->seen_files->{ $fpath } = $mtime;
    super;
};

before '_poll' => sub{
    my $self = shift;

    # Eliminate from seen_files any files that no longer exist or have a different mtime
    %{ $self->seen_files } = map {$_ => $self->seen_files->{$_} }
    grep { $self->seen_files->{$_} == get_mtime($_) } # Check that file has same mtime
    grep {-e $_ }   # Check that file exists
    keys %{ $self->seen_files };
};

sub get_mtime {
    my $file = shift;

    my $mtime;
    my @file_stats = stat($file);
    # In case of file being unavailable for some reason
    if (@file_stats) {
        $mtime = $file_stats[9] || 1;
    }
    else {
        $mtime = 1;
    }
    return $mtime;
}

1;

__END__;

=encoding utf-8

=head1 NAME

POE::Component::DirWatch::Object::NewUnmodifiedFile

=head1 SYNOPSIS


  use POE::Component::DirWatch::Object::NewUnmodifiedFile;

  #$watcher is a PoCo::DW:Object::NewUnmodifiedFile
  my $watcher = POE::Component::DirWatch::Object::NewUnmodifiedFile->new
    (
     alias      => 'dirwatch',
     directory  => '/some_dir',
     filter     => sub { $_[0] =~ /\.gz$/ && -f $_[1] },
     callback   => \&some_sub,
     interval   => 1,
    );

  $poe_kernel->run;

=head1 DESCRIPTION

POE::Component::DirWatch::Object::NewUnmodifiedFile extends DirWatch::Object in order to
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

=head1 AUTHOR

Dominic Humphries E<lt>perl@oneandoneis2.comE<gt>
Based on POE::Component::DirWatch::Object::NewFile by Guillermo Roditi, <groditi@cpan.org>

=head1 COPYRIGHT

Copyright 2018- Dominic Humphries

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
