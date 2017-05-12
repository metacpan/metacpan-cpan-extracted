package Plack::Middleware::Static::Range;
use 5.008001;
use strict;
use warnings;
use Plack::App::File::Range;
use parent 'Plack::Middleware::Static';
our $VERSION = '0.01';

sub _handle_static {
    my ($self, $env) = @_;
    $self->{file} ||= Plack::App::File::Range->new({
        root => $self->root || '.',
        encoding => $self->encoding,
    });
    $self->SUPER::_handle_static($env);
}

1;

__END__

=encoding utf8

=head1 NAME

Plack::Middleware::Static::Range - Serve static files with support for Range requests

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'Static::Range' => (
            path => qr{^/(images|js|css)/},
            root => './htdocs/'
        );
        $app;
    };

=head1 DESCRIPTION

This middleware is a subclass of L<Plack::Middleware::Static> with additional
support for requests with C<Range> headers.

=head1 SEE ALSO

L<Plack::Middleware::Static>, L<Plack::App::File::Range>

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Plack::Middleware::Static::Range>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
