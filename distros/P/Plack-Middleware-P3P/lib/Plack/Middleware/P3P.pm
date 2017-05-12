package Plack::Middleware::P3P;

# ABSTRACT: Add standard (or custom) P3P header to response

use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::Util::Accessor qw/policies/;

our $VERSION = '0.001'; # VERSION

sub prepare_app {
    my $self = shift;
    if (!defined $self->policies) {
        $self->policies('CAO PSA OUR');
    } elsif (ref $self->policies && ref $self->policies eq 'ARRAY') {
        $self->policies(join ' ', @{$self->policies});
    }
    $self->policies('CP="' . $self->policies . '"');
}

sub call {
    my ($self, $env) = @_;
    $self->response_cb($self->app->($env), sub{
        my $res = shift;
        Plack::Util::header_set($res->[1], 'P3P', $self->policies);
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::P3P - Add standard (or custom) P3P header to response

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Plack::Builde;
    use Plack::Middleware::P3P

    builder {
        enable 'P3P';
        $app;
    }

or with custom policies:

    builder {
       enable 'P3P', policies => 'FBI CIA NSA';
       $app;
    }

or with an array of custom policies:

    builder {
       enable 'P3P', policies => ['FBI', 'CIA', 'NSA'];
       $app;
    }

=head1 DESCRIPTION

This L<Plack::Middleware> adds a P3P header to all responses (see the
L<W3C page|http://www.w3.org/P3P/>). By default at adds the I<CAO>, I<PSA> and I<OUR> policies.
The default policies are enough to make Internet Explorer accept cookies from an iframe, the
I<raison d'etre> for this module.

=head1 CONFIGURATION

=over 4

=item policies

Sets custom policies in the P3P header. Policies can be specified as a string or as an array of
strings.

=back

=head1 SEE ALSO

L<Plack::Middleware>, L<Plack::Middleware::Headers>

=head1 AUTHOR

Hans Staugaard <staugaard@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Hans Staugaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
