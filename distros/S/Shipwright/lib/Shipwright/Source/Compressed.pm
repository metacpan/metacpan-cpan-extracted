package Shipwright::Source::Compressed;

use warnings;
use strict;
use File::Spec::Functions qw/catfile catdir/;

use base qw/Shipwright::Source::Base/;
use Archive::Extract;
use File::Temp qw/tempdir/;
use File::Copy::Recursive qw/rmove/;
use Shipwright::Util;
use Cwd qw/getcwd/;

=head2 run

=cut

sub run {
    my $self = shift;

    $self->name( $self->just_name( $self->path ) )       unless $self->name;
    $self->version( $self->just_version( $self->path ) ) unless $self->version;
    $self->log->info( 'running source ' . $self->name . ': ' . $self->source );

    $self->_update_version( $self->name, $self->version );

    $self->_update_url( $self->name, 'file:' . $self->source )
      unless $self->{_no_update_url};

    my $newer = $self->_cmd;    # if we really get something new

    my $ret = $self->SUPER::run(@_);

    # follow only if --follow and we really added new stuff.
    $self->_follow( catdir( $self->directory, $self->name ) )
      if $self->follow && $newer;
    return catdir( $self->directory, $self->name );
}

=head2 path

the decompressed source path

=cut

sub path {
    my $self   = shift;

    # we memoize path info so we don't need to extract on each call.
    return $self->{_path} if $self->{_path};

    my $source = $self->source;
    my $ae = Archive::Extract->new( archive => $source );
    # this's to check if $source is valid, aka. it only contains one directory.
    my $tmp_dir = tempdir( 'shipwright_tmp_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    $ae->extract( to => $tmp_dir );
    my $files = $ae->files;

    # 1st file in Crypt-DH-0.07.tar.gz is "./"
    shift @$files if $files->[0] =~ /^\.[\/\\]$/;
    my $base_dir = $files->[0];
    # some compressed file has name like ./PerlImagick-6.67/
    $base_dir =~ s!^\.[/\\]!!;

# sunnavy found that the 1st file is not the directory name when extracting
# HTML-Strip-1.06.tar.gz, which is weird but valid compressed file.
    $base_dir =~ s![/\\].*!!; 

    if ( @$files != grep { /^(?:\.[\/\\])?\Q$base_dir\E/ } @$files ) {
        confess_or_die 'only support compressed file which contains only one directory: '
          . $base_dir;
    }

    $self->{_path} = $base_dir;

    return $base_dir;
}

sub _cmd {
    my $self = shift;
    my $arg;

    my ( $from, $to );
    $from = catdir( $self->directory, $self->path );
    $to   = catdir( $self->directory, $self->name );

    # if it already exists, assuming we have processed it already, don't do it
    # again
    return if -e $to;

    my $ae = Archive::Extract->new( archive => $self->source );

    return sub {
        $ae->extract( to => $self->directory );

        if (   -e catfile( $from, 'dist.ini' )
            && !-e catfile( $from, 'configure' )
            && !-e catfile( $from, 'Makefile.PL' )
            && !-e catfile( $from, 'Build.PL' ) )
        {
            # assume it's a Dist::Zilla dist
            if ( $from eq $to ) {
                rmove( $from, $from . '-tmp' );
            }

            my $old = getcwd();
            chdir $from . '-tmp';
            run_cmd( [ $ENV{SHIPWRIGHT_DZIL}, 'build', '--in', $to ] );
            chdir $old;
        }

        if ( $from ne $to ) {
            rmove( $from, $to );
        }
    };
}

1;

__END__

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2007-2015 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
