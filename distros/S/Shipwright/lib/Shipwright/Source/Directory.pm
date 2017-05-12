package Shipwright::Source::Directory;
use strict;
use warnings;
use Shipwright::Util;
use File::Spec::Functions qw/catfile catdir rel2abs/;
use File::Basename;
use File::Copy::Recursive qw/rcopy/;
use Cwd qw/getcwd/;

use base qw/Shipwright::Source::Base/;

=head2 new

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    my $s     = $self->source;
    $s =~ s{/$}{};    # trim the last / to let cp work as we like
    $self->source(rel2abs $s);
    return $self;
}

=head2 run

=cut

sub run {
    my $self = shift;

    $self->name( $self->just_name( $self->path ) )       unless $self->name;
    $self->version( $self->just_version( $self->path ) ) unless $self->version;
    $self->log->info( 'running source ' . $self->name . ': ' . $self->source );

    $self->_update_version( $self->name, $self->version );

    $self->_update_url( $self->name, 'directory:' . $self->source )
      unless $self->{_no_update_url};

    my $newer = $self->_cmd;    # if we really get something new

    $self->SUPER::run(@_);

    # follow only if --follow and we really added new stuff.
    $self->_follow(
        catdir(
            $self->directory, $self->name || $self->just_name( $self->path )
        )
    ) if $self->follow && $newer;
    return catdir( $self->directory,
        $self->name || $self->just_name( $self->path ) );
}

=head2 path

return the basename of source

=cut

sub path {
    my $self = shift;
    return basename $self->source;
}

sub _cmd {
    my $self = shift;
    my $to =
      catdir( $self->directory,
        $self->name || $self->just_name( $self->path ) );
    return if -e $to;

    if (   -e catfile( $self->source, 'dist.ini' )
        && !-e catfile( $self->source, 'configure' )
        && !-e catfile( $self->source, 'Makefile.PL' )
        && !-e catfile( $self->source, 'Build.PL' ) )
    {
        my $old = getcwd();
        # assume it's a Dist::Zilla dist
        return sub {
            chdir $self->source;
            run_cmd( [ $ENV{SHIPWRIGHT_DZIL}, 'build', '--in', $to ] );
            chdir $old;
        };
    }
    else {
        return sub { rcopy( $self->source, $to ) };
    }
}

1;

__END__

=head1 AUTHOR

sunnavy C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2007-2015 Best Practical Solutions LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

