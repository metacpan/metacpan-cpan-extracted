## no critic (RequireUseStrict)
package Plack::Middleware::Acme::YadaYada;
BEGIN {
  $Plack::Middleware::Acme::YadaYada::VERSION = '0.01';
}

## use critic (RequireUseStrict)
use strict;
use warnings;

use parent 'Plack::Middleware';

use Try::Tiny;

sub call {
    my ( $self, $env ) = @_;

    my $app = $self->app;
    my $retval;

    try {
        $retval = $app->($env);
    } catch {
        if(/^Unimplemented/) {
            $retval = [
                501,
                ['Content-Type' => 'text/plain'],
                ['Not Implemented'],
            ];
        } else {
            die;
        }
    };

    return $retval;
};

1;



=pod

=head1 NAME

Plack::Middleware::Acme::YadaYada - Middleware that handles the Yada Yada operator

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = sub { ... };

  builder {
    enable 'Acme::YadaYada';
    $app;
  };

=head1 DESCRIPTION

This middleware handles exceptions thrown by the Yada Yada operator and
returns "501 Not Implemented" if it encounters any.

=head1 SEE ALSO

L<perlop/Yada_Yada_Operator>, L<Plack::Middleware>

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://github.com/hoelzro/plack-middleware-acme-yadayada/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut


__END__

# ABSTRACT: Middleware that handles the Yada Yada operator

