package Plack::Middleware::Favicon;
use strict;
use warnings;
use Carp qw/croak/;
use parent 'Plack::Middleware';
use Imager;
use HTTP::Date qw/time2str/;
use Plack::Util::Accessor qw/
    src_image_file
    src_image_obj
    cache
    custom_favicons
    callback
/;

our $VERSION = '0.05';

our @DEFAULT_FAVICONS = map {
    $_->{type}      ||= 'png';
    $_->{mime_type} ||= 'image/png';
    $_;
} (
    {
        cond => sub {
            my ($self, $env) = @_;
            $env->{HTTP_USER_AGENT}
                and $env->{HTTP_USER_AGENT} =~ m!MSIE (?:[1-9]|10)\.!;
        },
        path => qr!^/favicon\.ico!, size => [16, 16],
        type => 'ico', mime_type => 'image/x-icon',
    },
    { path => qr!^/favicon\.ico!, size => [16, 16], mime_type => 'image/x-icon', },
    { path => qr!^/favicon-16x16\.png!, size => [16, 16], },
    { path => qr!^/favicon-32x32\.png!, size => [32, 32], },
    { path => qr!^/favicon-96x96\.png!, size => [96, 96], },
    { path => qr!^/favicon-160x160\.png!, size => [160, 160], },
    { path => qr!^/favicon-196x196\.png!, size => [196, 196], },
    { path => qr!^/mstile-70x70\.png!, size => [70, 70], },
    { path => qr!^/mstile-144x144\.png!, size => [144, 144], },
    { path => qr!^/mstile-150x150\.png!, size => [150, 150], },
    { path => qr!^/mstile-310x310\.png!, size => [310, 310], },
    { path => qr!^/mstile-310x150\.png!, size => [310, 150], },
    { path => qr!^/apple-touch-icon-57x57\.png!, size => [57, 57], },
    { path => qr!^/apple-touch-icon-60x60\.png!, size => [60, 60], },
    { path => qr!^/apple-touch-icon-72x72\.png!, size => [72, 72], },
    { path => qr!^/apple-touch-icon-76x76\.png!, size => [76, 76], },
    { path => qr!^/apple-touch-icon-114x114\.png!, size => [114, 114], },
    { path => qr!^/apple-touch-icon-120x120\.png!, size => [120, 120], },
    { path => qr!^/apple-touch-icon-144x144\.png!, size => [144, 144], },
    { path => qr!^/apple-touch-icon-152x152\.png!, size => [152, 152], },
    { path => qr!^/apple-touch-icon\.png!, size => [57, 57], },
    { path => qr!^/apple-touch-icon-precomposed\.png!, size => [57, 57], },
);

sub prepare_app {
    my $self = shift;

    croak "required 'src_image_file'"
        unless $self->src_image_file;
    croak "not found or not a file:". $self->src_image_file
        unless -f $self->src_image_file;

    my $imager = Imager->new(file => $self->src_image_file);
    unless ($imager) {
        croak sprintf(
            "could not create object from %s. %s",
            $self->src_image_file,
            Imager->errstr || '',
        );
    }
    $self->src_image_obj($imager);

    if ($self->cache) {
        for my $f (@{$self->custom_favicons || []}, @DEFAULT_FAVICONS) {
            $self->_generate($f);
        }
    }
}

sub call {
    my ($self, $env) = @_;

    for my $f (@{$self->custom_favicons || []}, @DEFAULT_FAVICONS) {
        next if $f->{cond} && !$f->{cond}->($self, $env);
        if ($env->{PATH_INFO} =~ m!$f->{path}!) {
            my $content = $self->_generate($f);
            return [
                200,
                [
                    'Content-Type'   => $f->{mime_type},
                    'Content-Length' => length $content,
                    'Last-Modified'  => time2str(time),
                ],
                [$content],
            ];
        }
    }

    $self->app->($env);
}

sub _generate {
    my ($self, $f) = @_;

    if ($self->cache) {
        if ( my $cache = $self->cache->get($self->_ckey($f)) ) {
            return $cache;
        }
    }

    my ($x, $y) = @{ $f->{size} };

    my $img = $self->src_image_obj->scale(
        xpixels => $x,
        ypixels => $y,
        type    => 'nonprop',
    );

    if ($self->callback) {
        $img = $self->callback->($self, $f, $img);
    }

    my $favicon = '';
    $img->write(
        data => \$favicon,
        type => $f->{type},
    );

    if ($self->cache) {
        $self->cache->set($self->_ckey($f) => $favicon);
    }

    return $favicon;
}

sub _ckey { join ':', @{$_[1]->{size}}, $_[1]->{type}; }

1;

__END__

=head1 NAME

Plack::Middleware::Favicon - deliver common favicon images


=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'Favicon',
            src_image_file => 'src_favicon.png';
    };


=head1 DESCRIPTION

You don't need to prepare favicon images any more if you use this module.


=head1 METHODS

=over 4

=item prepare_app

=item call

=back


=head1 MIDDLEWARE OPTIONS

=head2 cache

If you'd like this module to cache images for response, provide the I<cache> option with an object supporting the L<Cache> API (e.g. I<Cache::FileCache>, I<Cache::Memory::Simple>). Specifically, an object that supports C<get($key)> and C<set($key, $value, $expires)> methods.

    use Cache::Memory::Simple;

    builder {
        enable 'Favicon',
            src_image_file  => 'src_favicon.png',
            cache => Cache::Memory::Simple->new;
    };

=head2 custom_favicons

If you'd provide custom favicon images, set the I<custom_favicons> option.

    builder {
        enable 'Favicon',
            src_image_file  => 'src_favicon.png',
            custom_favicons => [
                { path => qr!^/foo\.png!, size => [32, 32],
                  type => 'png', mime_type => 'image/png' },
            ];
    };

=head2 callback

If you'd want to filter image, set the I<callback> option as code ref.

    builder {
        enable 'Favicon',
            src_image_file  => 'src_favicon.png',
            callback => sub {
                my ($self, $f, $img) = @_;
                $img->filter(type => "unsharpmask", stddev => 1, scale => 0.5);
            };
    };


=head1 REPOSITORY

Plack::Middleware::Favicon is hosted on github: L<http://github.com/bayashi/Plack-Middleware-Favicon>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<http://itexp.hateblo.jp/entry/website-needs-21-favicons>

L<http://ja.wikipedia.org/wiki/Favicon>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
