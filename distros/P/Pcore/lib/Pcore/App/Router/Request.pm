package Pcore::App::Router::Request;

use Pcore -class;
use Pcore::App::API::Auth;

extends qw[Pcore::HTTP::Server::Request];

has app  => ( required => 1 );    # Pcore::App
has host => ( required => 1 );
has path => ( required => 1 );

has _auth => ( init_arg => undef );    # request authentication result

sub authenticate ( $self ) {

    # request is already authenticated
    if ( exists $self->{_auth} ) {
        return $self->{_auth};
    }

    # return empty authenticator
    elsif ( !$self->{app}->{api} ) {
        return $self->{_auth} = bless { api => undef }, 'Pcore::App::API::Auth';
    }
    else {
        my $env = $self->{env};

        my $token;

        # get token from query string: access_token=<token>
        if ( $env->{QUERY_STRING} && $env->{QUERY_STRING} =~ /\baccess_token=([^&]+)/sm ) {
            $token = $1;
        }

        # get token from HTTP header: Authorization: Token <token>
        elsif ( $env->{HTTP_AUTHORIZATION} && $env->{HTTP_AUTHORIZATION} =~ /Token\s+(.+)\b/smi ) {
            $token = $1;
        }

        # get token from HTTP Basic authoriation header
        elsif ( $env->{HTTP_AUTHORIZATION} && $env->{HTTP_AUTHORIZATION} =~ /Basic\s+(.+)\b/smi ) {
            $token = eval { from_b64 $1};

            $token = [ split /:/sm, $token ] if $token;

            undef $token if !defined $token->[0];
        }

        # get token from HTTP cookie "token"
        elsif ( $env->{HTTP_COOKIE} && $env->{HTTP_COOKIE} =~ /\btoken=([^;]+)\b/sm ) {
            $token = $1;
        }

        return $self->{_auth} = $self->{app}->{api}->authenticate($token);
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Router::Request

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
