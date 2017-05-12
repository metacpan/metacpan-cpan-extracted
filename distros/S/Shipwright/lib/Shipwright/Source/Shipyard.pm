package Shipwright::Source::Shipyard;
use strict;
use warnings;

use Shipwright::Util;
use File::Spec::Functions qw/catdir/;

use base qw/Shipwright::Source::Base/;

=head2 run

=cut

sub run {
    my $self = shift;

    $self->log->info( "preparing to run source: " . $self->source );
    my ( $base, $dist ) = $self->source =~ m{(.*)/([^/]+)};

    my $source_shipwright = Shipwright->new( repository => $base );
    $self->name($dist) unless $self->name;

    if ( $source_shipwright->backend->has_branch_support ) {
        $source_shipwright->backend->export(
            target => catdir( $self->directory, $self->name ),
            path   => "/sources/$dist",
        );
    }
    else {
        $source_shipwright->backend->export(
            target => catdir( $self->directory, $self->name ),
            path   => "/dists/$dist",
        );
    }

    $source_shipwright->backend->export(
        target => catdir( $self->scripts_directory, $self->name ),
        path   => "/scripts/$dist",
    );
    my $source_version = $source_shipwright->backend->version->{$dist};
    my $source_branch;
    if (   $source_shipwright->backend->branches
        && $source_shipwright->backend->branches->{$dist} )
    {
        $source_branch = $source_shipwright->backend->branches->{$dist};
    }

    $self->_update_version( $self->name, $source_version );
    $self->_update_url( $self->name, 'shipyard:' . $self->source );
    $self->_update_branches( $self->name, $source_branch ) if $source_branch;

    # follow
    if ( $self->follow ) {
        my $out = run_cmd(
            $source_shipwright->backend->_cmd(
                'cat', path => "/scripts/$dist/require.yml",
            ),
            1
        );
        my $require = load_yaml($out) || {};

        for my $type ( keys %$require ) {
            for my $req ( keys %{ $require->{$type} } ) {
                unless ( -e catdir( $self->directory, $req ) ) {
                    my $s = Shipwright::Source->new(
                        %$self,
                        source => "shipyard:$base/$req",
                        name   => $req
                    );
                    $s->run;
                }
            }
        }
    }

    return catdir( $self->directory, $self->name );
}

1;

__END__

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2007-2015 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

