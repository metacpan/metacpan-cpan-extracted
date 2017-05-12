package Plack::App::ImageMagick;
BEGIN {
  $Plack::App::ImageMagick::AUTHORITY = 'cpan:AJGB';
}
BEGIN {
  $Plack::App::ImageMagick::VERSION = '1.110990';
}
# ABSTRACT: Create and manipulate images with Image::Magick

use strict;
use warnings;

use parent qw( Plack::Component );

use Image::Magick;
use Plack::App::File;
use File::Spec ();
use JSON::XS ();
use Digest::MD5 ();
use Plack::Request;
use HTTP::Date ();
use Plack::Util ();
use String::Bash ();
use Try::Tiny;

use Plack::Util::Accessor qw(
    handler
    pre_process
    post_process
    apply
    with_query
    root
    cache_dir
);

my %replace_img_methods = map { $_ => 1 } qw(
    FlattenImage
);

my %push2stack_img_methods = map { $_ => 1 } qw(
    Clone
    EvaluateImages
    Fx
    Smush
    Transform
);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    my $apply = $self->apply;
    my $handler = $self->handler;

    die "handler or apply is required"
        unless defined $handler || defined $apply;

    die "handler and apply are mutually exclusive"
        if defined $handler && defined $apply;

    die "with_query requires apply"
        if defined $self->with_query && ! defined $apply;

    die "pre/post processing methods are allowed only for apply option"
        if ! defined $apply && (
                defined $self->pre_process
                ||
                defined $self->post_process
            );

    die "apply should be non-empty array reference"
        if defined $apply && (
            ref $apply ne 'ARRAY'
            ||
            scalar @$apply == 0
        );


    return $self;
}

sub call {
    my ($self, $env) = @_;

    my $request_uri = $env->{REQUEST_URI};

    # try loading from cache
    if ( $self->cache_dir ) {
        my $cached_file = File::Spec->catfile(
            $self->cache_dir,
            Digest::MD5::md5_hex( $request_uri )
        );

        if ( -r $cached_file ) {
            return $self->_create_response_from_cache( $env, $cached_file );
        }
    }

    my $handler;
    my $img = Image::Magick->new;

    if ( my $commands = $self->apply ) {

        # expand options from query string
        if ( my $with_query = $self->with_query ) {
            my $req = Plack::Request->new($env);
            my $encoded = JSON::XS::encode_json( $commands );

            my $query_params = $req->query_parameters;
            my $params = {};

            for my $param ( $query_params->keys ) {
                # use last value
                my $val = ($query_params->get_all($param))[-1];

                if ( $val ) {
                    # special chars forbidden
                    return http_response_403() unless $val =~ /\A[\w ]+\z/s;

                    $params->{ $param } = $val;
                };
            };

            # params expanded
            try {
                $commands = JSON::XS::decode_json( String::Bash::bash($encoded, $params) );
            } catch {
                warn "Parsing query failed: $_";
                return http_response_500();
            };
        }

        # create handler from commands
        $handler = sub {
            my ($app, $env, $img) = @_;

            unless ( ref $img eq 'Image::Magick' ) {
                warn "Invalid object $img, required Image::Magick";
                return http_response_500();
            }

            # working on existing image
            if ( my $img_root = $self->root ) {
                my $path = File::Spec->catfile( $img_root, $env->{PATH_INFO} );
                my $err = $img->Read( $path );
                if ( "$err" ) {
                    warn "Read($path) failed: $err";
                    return http_response_404();
                }
            }

            for (my $i = 0; $i < @$commands; $i += 2 ) {
                my ($method, $args) = @{ $commands }[ $i .. $i + 1 ];

                my @opts;
                if ( ref $args eq 'HASH' ) {
                    @opts = %$args;
                } elsif ( ref $args eq 'ARRAY' ) {
                    @opts = @$args;
                }

                unless ( $method ) {
                    warn "Undefined method at index: $i";
                    return http_response_500();
                }
                my $x = $img->$method( @opts );

                if ( exists $push2stack_img_methods{ $method } ) {
                    unless ( ref $x ) {
                        warn "$method(@opts) failed: $x";
                        return http_response_500();
                    };
                    push @$img, $x;
                } elsif ( exists $replace_img_methods{ $method } ) {
                    unless ( ref $x ) {
                        warn "$method(@opts) failed: $x";
                        return http_response_500();
                    };

                    $img = $x;
                } elsif ( "$x" ) {
                    warn "$method(@opts) failed: $x";
                    return http_response_500();
                }
            }
            return $img;
        };
    } else {
        $handler = $self->handler;
    };

    if ( defined $handler ) {

        if ( my $pre_process = $self->pre_process ) {
            $img = $pre_process->($self, $env, $img);

            unless ( ref $img eq 'Image::Magick' ) {
                warn "Invalid object $img, required Image::Magick";
                return http_response_500();
            }
        }

        if ( my $out = $handler->($self, $env, $img) ) {
            if ( ref $out ne 'Image::Magick' ) {
                return $out;
            }

            if ( my $post_process = $self->post_process ) {
                $out = $post_process->($self, $env, $out);

                unless ( ref $out eq 'Image::Magick' ) {
                    warn "Invalid object $out, required Image::Magick";
                    return http_response_500();
                }

            }

            # flatten image before rendering
            if ( @$out > 1 ) {
                $out = $out->FlattenImage();
                unless ( ref $out ) {
                    warn "FlattenImage() failed: $out";
                    return http_response_500();
                };
            }

            my $res;
            if ( $self->cache_dir ) {
                my $cached_file = File::Spec->catfile(
                    $self->cache_dir,
                    Digest::MD5::md5_hex( $request_uri )
                );

                my $x = $out->Write( filename => $cached_file );
                if ( "$x" ) {
                    warn "Write($cached_file) failed: $x";
                    return http_response_500();
                };

                # serve via Plack::App::File, so middleware like XSendfile
                # can be used
                $res = $self->_create_response_from_cache(
                    $env, $cached_file, $out->Get('mime')
                );
            } else {
                # use image blob as body
                $res = $self->_create_response_from_img( $out );
            }

            undef $out;
            return $res;
        }
    }

    # we are supposed to do something
    return http_response_500();
}

sub _create_response_from_cache {
    my ($self, $env, $file_path, $content_type) = @_;

    # discover content type from cached file
    unless ( $content_type ) {
        my $img = Image::Magick->new;
        my $format = ($img->Ping( $file_path ))[3];
        $content_type = $img->MagickToMime( $format );
    };


    my $file_app = Plack::App::File->new(
        file => $file_path,
        content_type => $content_type,
    );

    local $env->{PATH_INFO} = $file_path;
    return $file_app->call( $env );
};

sub _create_response_from_img {
    my ($self, $img) = @_;

    my $data = join('', $img->ImageToBlob);

    return [
        200,
        [
            'Content-Type' => $img->Get('mime'),
            'Content-Length' => length $data,
            # be proxy friendly
            'Last-Modified'  => HTTP::Date::time2str( time ),
        ],
        [ $data ]
    ];
}


# in case someone wants pretty error messages in subclasses those are public
sub http_response_403 {
    my $self = shift;

    return [ 403,
        [
            'Content-Type' => 'text/plain',
            'Content-Length' => 12,
        ],
        [ '403 Forbidden' ]
    ]
}

sub http_response_404 {
    my $self = shift;

    return [ 404,
        [
            'Content-Type' => 'text/plain',
            'Content-Length' => 12,
        ],
        [ '404 Not Found' ]
    ]
}

sub http_response_500 {
    my $self = shift;

    return [ 500,
        [
            'Content-Type' => 'text/plain',
            'Content-Length' => 22,
        ],
        [ '500 Service Unavailable' ]
    ]
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Plack::App::ImageMagick - Create and manipulate images with Image::Magick

=head1 VERSION

version 1.110990

=head1 SYNOPSIS

    # app.psgi
    use Plack::App::ImageMagick;

    my $thumbnailer_app = Plack::App::ImageMagick->new(
        root => '/path/to/images',
        apply => [
            Scale => { geometry => "%{width:-200}x%{height:-120}" },
            Set => { quality => 30 },
        ],
        with_query => 1,
    );

    my $captcha_app = Plack::App::ImageMagick-new(
        apply => [
            Set => { size => "100x20" },
            ReadImage => [
                'xc:%{bgcolor:-white}',
            ],
            Set => { magick => "png" },
        ],
        post_process => sub {
            my ($app, $env, $img) = @_;

            $img->Annotate(
                text => random_text( $env->{PATH_INFO} ),
                fill => 'black',
                pointsize => 16,
                gravity => 'Center',
            );
            return $img;
        }
    );

    # and map it later
    use Plack::Builder;
    builder {
        # /thumbs/photo_1.jpg?width=640&height=480
        mount "/thumbs/" => $thumbnailer_app;

        # /captcha/623b1c9b03d4033635a545b54ffc4775.png
        mount "/captcha/" => $captcha_app;
    }

=head1 DESCRIPTION

Use L<Image::Magick> to create and manipulate images for your web applications.

=head1 CONFIGURATION

You need to supply L<"apply"> or L<"handler"> configuration options. All other
parameters are optional.

=head2 apply

    my $app = Plack::App::ImageMagick->new(
        root => '/path/to/images',
        apply => [
            Scale => { geometry => "%{width:-200}x%{height:-120}" },
            Set => { quality => 30 },
        ],
        with_query => 1,
    );

Array reference of ImageMagick's I<method_name> and its I<arguments> pairs.

The I<arguments> element could be a hash or array reference - both will be
flatten when passed as I<method_name> parameters.

If used with L<"root"> then attempt will be made to read image located there,
check L<"root"> for details.

If L<"with_query"> is specified the C<apply> block will be pre-processed to
replace placeholders with values from query string, check L<"with_query"> for
more details.

Results of the following methods will be pushed to C<@$img>:

=over 4

=item * Clone

=item * EvaluateImages

=item * Fx

=item * Smush

=item * Transform

=back

Results of the following method will replace current C<$img> object:

=over 4

=item * FlattenImage

=back

I<Note:> if the C<@$img> object contains more then one layer C<FlattenImage()> is called
before rendering.

I<Note:> L<"handler"> and L<"apply"> are mutually exclusive.

=head2 root

    my $app = Plack::App::ImageMagick->new(
        root => '/path/to/images',
        apply => [ ... ],
    );

Path to images used in conjunction with L<"apply"> to allow modifications of
existing images.

Attempt will be made to read image located there, based on
C<$env-E<gt>{PATH_INFO}>, failure to read image will result in
I<500 Internal Server Error> response.

In essence it is equal to calling C<Read()> before L<"apply"> methods:

        $img->Read( $self->root . $env->{PATH_INFO} );

=head2 with_query

    my $app = Plack::App::ImageMagick->new(
        apply => [
            '%{method:-Scale}' => { geometry => "%{width:-200}x%{height:-120}" },
            Set => { quality => '%{quality:-30}' },
        ],
        with_query => 1,
    );

Used with L<"apply"> allows to use placeholders which will be replaced with
values found in query string.

For details about syntax please see L<String::Bash>.

User supplied value (from query string) is validated with C<\A[\w ]+\z>, if
validation fails I<403 Forbidden> will be thrown.

Please note that providing default values is recommended.

=head2 cache_dir

    my $app = Plack::App::ImageMagick->new(
        cache_dir => '/path/to/cache',
        apply => [ ... ],
    );

If provided images created will be saved in this directory, with filenames
based on C<$env-E<gt>{REQUEST_URI}> MD5 checksum.

However use of reverse proxy for even better performance gain is recommended.

=head2 handler

    my $app = Plack::App::ImageMagick->new(
        handler => sub {
            my ($app, $env, $img) = @_;

            # process $img
            ...

            return $img;
        },
    );

Sub reference called with following parameters:

=over 4

=item C<$app>

Reference to current L<Plack::App::ImageMagick> object.

=item C<$env>

Reference to current C<$env>.

=item C<$img>

Reference to L<Image::Magick> object created with:

    my $img = Image::Magick->new();

=back

I<Note:> if returned C<@$img> object contains more then one layer C<FlattenImage()> is called
before rendering.

I<Note:> L<"handler"> and L<"apply"> are mutually exclusive.

=head2 pre_process

    my $app = Plack::App::ImageMagick->new(
        pre_process => sub {
            my ($app, $env, $img) = @_;

            # process $img
            ...

            return $img;
        },
        apply => [ ... ],
    );

Sub reference called before L<"apply"> methods are processed, with same
parameters as L<"handler">.

Returns C<$img> which is processed later by methods defined in L<"apply">.

=head2 post_process

    my $app = Plack::App::ImageMagick->new(
        apply => [ ... ],
        post_process => sub {
            my ($app, $env, $img) = @_;

            # process $img
            ...

            return $img;
        },
    );

Sub reference called after L<"apply"> (with C<$img> processed by its methods),
with same parameters as L<"handler">.

I<Note:> if the C<@$img> object contains more then one layer C<FlattenImage()> is called
before rendering.

=for Pod::Coverage     http_response_403
    http_response_404
    http_response_500

=head1 SEE ALSO

=over 4

=item *

L<Image::Magick>

=item *

L<Plack>

=item *

L<String::Bash>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

