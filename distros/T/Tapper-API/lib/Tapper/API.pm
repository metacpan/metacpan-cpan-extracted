package Tapper::API;
# git description: v5.0.1-6-g8c2b8e9

our $AUTHORITY = 'cpan:TAPPER';
$Tapper::API::VERSION = '5.0.2';
# ABSTRACT: Tapper - REST frontend

use 5.010;
use strict;
use warnings;

use Mojo::Base 'Mojolicious';
use Tapper::Config;

sub startup {
        my $self = shift;

        $self->plugin('TapperConfig');
        my $cfg = Tapper::Config->subconfig;
        my $r = $self->routes;
        foreach my $target (@{$cfg->{api}->{routes}}) {
                $r->any($target->{url})->partial(1)->to($target->{module});
        }

}

1; # End of Tapper::API

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::API - Tapper - REST frontend

=head1 AUTHOR

Tapper Team <tapper-ops@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Amazon.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
