package Plack::Middleware::Static::Minifier;
use strict;
use warnings;
use Plack::Util;
use Plack::Util::Accessor qw/cache/;
use parent 'Plack::Middleware::Static';
use CSS::Minifier::XS qw//;
use JavaScript::Minifier::XS qw//;
use Digest::MD5 qw/md5_hex/;

our $VERSION = '0.08';

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->_handle_static($env);

    if ($res && $res->[0] == 200) {
        my $h = Plack::Util::headers($res->[1]);
        if ( !defined $h->get('Content-Encoding')
                && $h->get('Content-Type')
                && $h->get('Content-Type') =~ m!/(css|javascript)! ) {
            my $ct = $1;
            my $body; Plack::Util::foreach($res->[2], sub { $body .= $_[0] });
            my $minified_body;
            if ($self->cache) {
                my $key = md5_hex($env->{PATH_INFO});
                unless ( my $cache = $self->cache->get($key) ) {
                    $minified_body = _minify($ct, \$body);
                    $self->cache->set($key, @{$minified_body}[0]);
                }
                else {
                    $minified_body = [$cache];
                }
            }
            else {
                $minified_body = _minify($ct, \$body);
            }
            $res->[2] = $minified_body;
            $h->set('Content-Length', length $res->[2][0]);
        }
    }

    if ($res && not ($self->pass_through and $res->[0] == 404)) {
        return $res;
    }

    return $self->app->($env);
}

sub _minify {
    my ($ct, $body_ref) = @_;
    return ($ct =~ m!^css!)
            ? [CSS::Minifier::XS::minify($$body_ref)]
            : [JavaScript::Minifier::XS::minify($$body_ref)];
}

1;

__END__

=head1 NAME

Plack::Middleware::Static::Minifier - serves static files and minify CSS and JavaScript


=head1 SYNOPSIS

    use Plack::Builder;
    builder {
        enable "Plack::Middleware::Static::Minifier",
            path => qr{^/(js|css|images)/},
            root => './htdocs/';
        $app;
    };

or you can cache minified content

    use Plack::Builder;
    use Cache::FileCache;

    my $cache = Cache::FileCache->new(+{
        cache_root         => '/tmp/foo',
        namespace          => 'namespace',
        default_expires_in => 60*60*24*7,
    });

    builder {
        enable "Plack::Middleware::Static::Minifier",
            path  => qr{^/(js|css|images)/},
            root  => './htdocs/',
            cache => $cache;
        $app;
    };


=head1 DESCRIPTION

Plack::Middleware::Static::Minifier serves static files with Plack and minify CSS and JavaScript. This module is the subclass of Plack::Middleware::Static.

See L<Plack::Middleware::Static> for more detail.


=head1 METHOD

=over 4

=item call

=back


=head1 REPOSITORY

Plack::Middleware::Static::Minifier is hosted on github
<http://github.com/bayashi/Plack-Middleware-Static-Minifier>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Plack::Middleware::Static>, L<CSS::Minifier::XS>, L<JavaScript::Minifier::XS>
L<Plack::Middleware>, L<Plack>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
