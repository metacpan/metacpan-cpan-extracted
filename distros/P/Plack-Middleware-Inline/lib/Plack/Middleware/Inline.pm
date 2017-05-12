package Plack::Middleware::Inline;
BEGIN {
  $Plack::Middleware::Inline::VERSION = '0.02';
}

use warnings;
use strict;

use base qw(Plack::Middleware);

sub call { goto &{ $_[0]->{code} } }

1;

=head1 NAME

Plack::Middleware::Inline - Anonymous Plack::Middlewares

=head1 VERSION

version 0.02

=head1 SYNOPSIS

Note:  Don't actually do this.  This module is only useful if you're not using
L<Plack::Builder>.

    use Plack::Builder;
    builder {
        enable Inline => code => sub {
            my ($self, $env) = @_;
            ...
            $self->app->($env);
        };
        $app
    }

If you're already using L<Plack::Builder>, just pass enable a sub:

    use Plack::Builder;
    builder {
        enable sub {
            my $app = shift;
            return sub {
                my $env = shift;
                ...
                $app->($env);
            };
        };
    }

=cut