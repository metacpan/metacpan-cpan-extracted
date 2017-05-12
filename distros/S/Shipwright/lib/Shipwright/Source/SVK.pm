package Shipwright::Source::SVK;

use warnings;
use strict;
use Shipwright::Util;
use File::Spec::Functions qw/catdir/;
use File::Path qw/remove_tree/;

use base qw/Shipwright::Source::Base/;

=head2 new

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->name( $self->just_name( $self->source ) ) unless $self->name;
    return $self;
}

=head2 run

=cut

sub run {
    my $self = shift;
    $self->log->info( "preparing to run source: " . $self->source );

    $self->_update_url( $self->name, 'svk:' . $self->source );

    $self->_run;
    my $s;
    if ( $self->is_compressed ) {
        require Shipwright::Source::Compressed;
        $s = Shipwright::Source::Compressed->new( %$self, _no_update_url => 1 );
    }
    else {
        require Shipwright::Source::Directory;
        $s = Shipwright::Source::Directory->new( %$self, _no_update_url => 1 );
    }
    $s->run(@_);
}

=head2 _run

=cut

sub _run {
    my $self   = shift;
    my $source = $self->source;

    my @cmds;
    my $path = catdir( $self->download_directory, $self->name );
    push @cmds,
      [
        $ENV{'SHIPWRIGHT_SVK'}, 'co',
        $self->source,          $path,
        $self->version ? ( '-r', $self->version ) : ()
      ];
    push @cmds, [ $ENV{'SHIPWRIGHT_SVK'}, 'co', '-d', $path, ];

    unless ( $self->version ) {
        my ($out) = run_cmd(
            [ $ENV{'SHIPWRIGHT_SVK'}, 'info', $self->source, ] );

        if ( $out =~ /^Revision: (\d+)/m ) {
            $self->version($1);
        }
    }

    remove_tree($path) if -e $path;

    $self->source( $path );
    run_cmd($_) for @cmds;
}

1;

__END__

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2007-2015 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
