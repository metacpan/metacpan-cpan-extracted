package Plack::Middleware::QRCode;
use strict;
use warnings;
our $VERSION = '0.02';
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(render config image_type);
use Imager;
use Imager::QRCode;
use Plack::Response;
use Plack::Request;
use feature qw(say);

sub prepare_app {
    my $self = shift;
    my $default_config = { 
        size          => 4,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(255, 255, 255),
        darkcolor     => Imager::Color->new(0, 0, 0),
    };
    my $config = { 
        %$default_config , 
        %{ $self->render || { } } };
    $self->config( $config );
    $self->image_type( 'png' ) unless $self->image_type;
}

sub call {
    my ($self,$env) = @_;
    my $req = Plack::Request->new( $env );
    my $params = $req->parameters->mixed;
    my %config = %{ $self->config };

    $config{size} = $params->{s} if exists $params->{s};
    $config{margin} = $params->{m};

    my $pathinfo = substr $env->{'PATH_INFO'},1;
    say STDERR "Generating QRCode for '" , $pathinfo , "'";

    my @error = ( 500 , [ 'Content-type' => 'text/plain' ] );

    return [ @error , [ 'Please enter text for QRCode' ] ] unless $pathinfo;

    unless ( $config{size} > 0 ) {
        return [ @error, [ 'Please enter an integer for size param' ] ];
    }

    my $qrcode = Imager::QRCode->new( %config );
    my $img = $qrcode->plot( $pathinfo );

    my $data = '';
    $img->write( data => \$data , type => $self->image_type );

    return [ 200 , [ 'Content-type' => 'image/' . $self->image_type ] , [ $data ] ];
}

1;
__END__

=head1 NAME

Plack::Middleware::QRCode - Mount QRCode Image service on your Plack application.

=head1 SYNOPSIS

basic configuration:

    use Plack::Middleware::QRCode;
    builder {
        mount '/qrcode' => builder {
            enable 'QRCode';
            sub {  };
        };
    }

provide default options:

    use Plack::Middleware::QRCode;
    builder {
        mount '/qrcode' => builder {
        enable 'QRCode' , 
            render => {
                size          => 2,
                margin        => 2,
                version       => 1,
                level         => 'M',
                casesensitive => 1,
            };
        }
    }

=head1 DESCRIPTION

Plack::Middleware::QRCode is

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
