package Shipwright::Script::Maintain;

use strict;
use warnings;
use Shipwright::Util;

use base qw/App::CLI::Command Shipwright::Base Shipwright::Script/;
__PACKAGE__->mk_accessors(
    qw/update_order update_refs graph_deps skip_recommends 
      skip_build_requires skip_requires skip_test_requires for_dists/
);

use Shipwright;

sub options {
    (
        'graph-deps'          => 'graph_deps',
        'update-order'        => 'update_order',
        'update-refs'         => 'update_refs',
        'skip-recommends'     => 'skip_recommends',
        'skip-requires'       => 'skip_requires',
        'skip-build-requires' => 'skip_build_requires',
        'skip-test-requires'  => 'skip_test_requires',
        'for-dists=s'         => 'for_dists',
    );
}

sub run {
    my $self = shift;

    my $shipwright = Shipwright->new( repository => $self->repository, );

    if ( $self->update_order ) {
        $shipwright->backend->update_order(
            for_dists => [ split /,\s*/, $self->for_dists || '' ],
            map { $_ => $self->$_ }
              qw/skip_requires skip_recommends skip_build_requires
              skip_test_requires/,
        );
        $self->log->fatal( 'successfully updated order' );
    } 
    if ($self->graph_deps)  {
        my $out = $shipwright->backend->graph_deps(
            for_dists => [ split /,\s*/, $self->for_dists || '' ],
            map { $_ => $self->$_ }
              qw/skip_requires skip_recommends skip_build_requires/,
        );
        $self->log->fatal( $out );
    }

    if ( $self->update_refs ) {
        $shipwright->backend->update_refs;
        $self->log->fatal( 'successfully updated refs' );
    }
}

1;

__END__

=head1 NAME

Shipwright::Script::Maintain - Maintain a shipyard

=head1 SYNOPSIS

 maintain --update-order

=head1 OPTIONS

 --update-order               : update the build order
 --update-refs                : update refs count
                                times a source shows in all the require.yml
 --graph-deps                 : output a graph of all the dependencies in your vessel
                                suitable for rendering by dot (http://graphviz.org) 
 --for-dists                  : limit the sources
 --skip-requires              : skip requires when finding deps
 --skip-recommends            : skip recommends when finding deps
 --skip-build-requires        : skip build requires when finding deps
 --skip-test-requires         : skip requires when finding deps

=head1 GLOBAL OPTIONS

 -r [--repository] REPOSITORY   : specify the repository uri of our shipyard
 -l [--log-level] LOGLEVEL      : specify the log level
                                  (info, debug, warn, error, or fatal)
 --log-file FILENAME            : specify the log file

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

