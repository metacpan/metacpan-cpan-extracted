package OAuth2::Box;

# ABSTRACT: Authorize with Box.com 

use strict;
use warnings;

use Carp::Assert;
use HTTP::Tiny;
use JSON;
use Moo;
use Types::Standard qw(Str InstanceOf);
use URI;

our $VERSION = 0.03;

use constant BOX_URL => 'https://www.box.com/api/oauth2/';

has url           => ( is => 'ro', isa => Str, required => 1, default => sub { BOX_URL . 'authorize' } );
has token_url     => ( is => 'ro', isa => Str, required => 1, default => sub { BOX_URL . 'token' } );
has client_id     => ( is => 'ro', isa => Str, required => 1 );
has client_secret => ( is => 'ro', isa => Str, required => 1 );
has redirect_uri  => ( is => 'ro', isa => Str, required => 1 );

has agent => ( is => 'ro', isa => InstanceOf["HTTP::Tiny"], lazy => 1, default => sub { HTTP::Tiny->new } );
has jsonp => ( is => 'lazy', isa => InstanceOf["JSON"] );

sub _build_jsonp { JSON->new->allow_nonref }

sub authorization_uri {
    my ($self, %param) = @_;

    assert( $param{state}, 'need state' );

    my $uri = URI->new( $self->url );

    $uri->query_form(
        client_id     => $self->client_id,
        response_type => 'code',
        redirect_uri  => $self->redirect_uri,
        state         => $param{state},
    );

    return $uri;
}

sub authorize {
    my ($self, %param) = @_;

    assert( $param{code}, 'need code' );

    return $self->_do_request(
        code           => $param{code},
        grant_type     => 'authorization_code',
    );
}

sub refresh_token {
    my ($self, %param) = @_;

    assert( $param{refresh_token}, 'need refresh_token' );

    return $self->_do_request(
        refresh_token  => $param{refresh_token},
        grant_type     => 'refresh_token',
    );
}

sub _do_request {
    my ($self, %param) = @_;

    my $result = $self->agent->post_form(
        $self->token_url,
        {
            client_id      => $self->client_id,
            client_secret  => $self->client_secret,
            redirect_uri   => $self->redirect_uri,
            %param,
        },
    );

    if ( $result->{success} and $result->{content} ) {
        my $data = $self->jsonp->decode( $result->{content} );

        return wantarray ?
            ( $data->{access_token}, $data ) :
            $data->{access_token};
    }

    return;
}

1;

__END__

=pod

=head1 NAME

OAuth2::Box - Authorize with Box.com 

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use OAuth2::Box;
  my $box_oauth = OAuth2::Box->new(
      client_id     => 'app_client_id', 
      client_secret => 'app_client_secret',
      redirect_uri  => 'http://your.app.tld/auth',
  );

  my $authorization_url = $box_oauth->authorization_url(
      state => 'authorized',
  );

  my $auth_token = $box_oauth->authorize(
      code => '12345',
  );

  my ($auth_token, $info) = $box_oauth->authorize(
      code => '12345',
  );
  
  my ($auth_token, $info) = $box_oauth->refresh_token(
      refresh_token => '12abc42319de1a0',
  );

=head1 METHODS

=head2 authorization_uri

=head2 authorize

=head2 refresh_token

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
