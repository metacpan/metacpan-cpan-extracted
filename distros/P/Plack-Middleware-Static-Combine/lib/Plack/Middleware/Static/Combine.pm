package Plack::Middleware::Static::Combine;
{
  $Plack::Middleware::Static::Combine::VERSION = '0.01';
}
#ABSTRACT: Serve multiple static files combined

use strict;
use parent qw(Plack::Middleware::Static);

use Plack::Util;
use Plack::Util::Accessor qw(files);

sub _handle_static {
    my ($self, $env) = @_;

    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO};

    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_) : $_ =~ $path_match;
        return unless $matched;
    }

    $self->{file} ||= Plack::App::File->new({ root => $self->root || '.', encoding => $self->encoding });

    # copied from Plack::Middleware::Static up to this line

    my ($res, $type, $lastmod);
    my $length = 0;

    foreach my $file ( @{ $self->files || [] } ) {

        local $env->{PATH_INFO} = $file;
        my $got = $self->{file}->call($env);
        Plack::Util::response_cb($got, sub { $got = shift; });

        return $got unless $got->[0] eq '200';

        if ($res) {
            if ( $type ne Plack::Util::header_get($got->[1],'Content-Type') ) {
                $res = [500,['Content-Type'=>'text/plain'],['files must have same type']];
                $length = length $res->[2]->[0];
                last;
            }

            # TODO: better combine by sub?
            my $body = $res->[2];
            if (ref $body ne 'ARRAY') {
                $res->[2] = [ ];
                Plack::Util::foreach($body,sub { push @{$res->[2]}, shift; });
            }
            Plack::Util::foreach($got->[2],sub { push @{$res->[2]}, shift; });

            # TODO: Adjust Last-Modified
            
        } else {
            $type    = Plack::Util::header_get($got->[1],'Content-Type');
            $lastmod = Plack::Util::header_get($got->[1],'Last-Modified');
            $res = $got;
        }

        $length += Plack::Util::header_get($got->[1],'Content-Length');
    } 

    Plack::Util::header_set($res->[1],'Content-Length',$length) if $res;

    return $res;
}

1;



__END__
=pod

=head1 NAME

Plack::Middleware::Static::Combine - Serve multiple static files combined

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'Static::Combine', 
            path  => qr{^/javascript\.js$},
            files => [ 'foo.js', 'bar.js', 'doz.js' ],
            root  => './htdocs';
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::Static::Combine combines multiple static files, as served
via L<Plack::App::File>. Files must have same content type or HTTP 500 is
returned.

=head1 CONFIGURATION

=over 4

=item path, root, encoding

URL pattern or callback, document root, and text file encoding, as passed to
L<Plack::App::Static>.

=item files

A list of files.

=item pass_through

When this option is set to a true value, then this middleware will never return
an error response. Instead, it will simply pass the request on to the
application it is wrapping.

=back

=head1 SEE ALSO

L<Plack::Middleware::Static>, L<Plack::Middleware::File>,
L<Plack::Middleware::Static::Minifier>.

=encoding utf8

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

