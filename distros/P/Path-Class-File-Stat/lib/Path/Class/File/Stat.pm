package Path::Class::File::Stat;
use strict;
use warnings;
use base qw( Path::Class::File );

our $VERSION = '0.05';

my $debug = $ENV{PERL_DEBUG} || 0;

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{_stat} = $self->stat;
    return $self;
}

sub use_md5 {
    my $self = shift;
    if ( exists $self->{_md5} ) {
        $debug and warn "_md5 exists: $self->{_md5}";
        return $self->{_md5};
    }
    require Digest::MD5;
    $self->{_md5} = Digest::MD5::md5_hex( $self->slurp );
    return $self->{_md5};
}

sub changed {
    my $self = shift;
    my ( $old_sig, $new_sig, $sig_changed, $io_changed, $mtime_changed,
        $size_changed );
    if ( exists $self->{_md5} ) {
        $old_sig = $self->{_md5};
        $new_sig = Digest::MD5::md5_hex( $self->slurp );
        $debug and warn "old_sig=$old_sig new_sig=$new_sig";
        $sig_changed = $old_sig ne $new_sig;
    }
    my $new_stat = $self->stat;
    my $old_stat = $self->{_stat};

    $io_changed = ( $old_stat->dev ne $new_stat->dev
            && $old_stat->ino ne $new_stat->ino );
    $mtime_changed = $old_stat->mtime ne $new_stat->mtime;
    $size_changed  = $old_stat->size ne $new_stat->size;

    if ($debug) {
        require Data::Dump;
        Data::Dump::dump($new_stat);
        Data::Dump::dump($old_stat);

        #Data::Dump::dump($self);
    }

    if ( $io_changed || $mtime_changed || $size_changed || $sig_changed ) {
        $debug and warn "$self is not the file it once was\n";
        $self->{_md5} = $new_sig if $sig_changed;
        return $self->restat;
    }
    return 0;
}

sub restat {
    my $self = shift;
    my $old  = $self->{_stat};
    $self->{_stat} = $self->stat;
    return $old;
}

1;

__END__

=head1 NAME

Path::Class::File::Stat - test whether the file beneath a Path::Class::File object has changed

=head1 SYNOPSIS

  use Path::Class::File::Stat;
  my $file = Path::Class::File::Stat->new('path','to','file');
  
  # $file has all the magic of Path::Class::File
  
  # sometime later
  if ($file->changed) {
    # do something provocative
  }

=head1 DESCRIPTION

Path::Class::File::Stat is a simple extension of Path::Class::File.
Path::Class::File::Stat is useful in long-running programs 
(as under mod_perl) where you might have a file
handle opened and want to check if the underlying file has changed.

=head1 METHODS

Path::Class::File::Stat extends Path::Class::File objects in the 
following ways.

=head2 use_md5

Calling this method will attempt to load Digest::MD5 and use that
in addition to stat() for creating file signatures. This is similar
to how L<File::Modified> works.

=head2 changed

Returns the previously cached File::stat object
if the file's device number and inode number have changed, or
if the modification time or size has changed, or if use_md5()
is on, the MD5 signature of the file's contents has changed.

Returns 0 (false) otherwise.

While L<File::Modified> uses a MD5 signature of the stat() of a file
to determine if the file has changed, changed() uses
a simpler (and probably more naive) algorithm. If you need a more sophisticated 
way of determining if a file has changed, use
the restat() method and compare the cached File::stat object it returns with 
the current File::stat object.

Example of your own changed() logic:

 my $oldstat = $file->restat;
 my $newstat = $file->stat;
 # compare $oldstat and $newstat any way you like

Or just use L<File::Modified> instead.

=head2 restat

Re-cache the L<File::stat> object in the Path::Class::File::Stat object. Returns
the previously cached L<File::stat> object.

The changed() method calls this method internally if changed() is going to return
true.

=head1 SEE ALSO

L<Path::Class>, L<Path::Class::File>, L<File::Signature>, L<File::Modified>

=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2013 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
