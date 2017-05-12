package Net::Launchpad::Client;
BEGIN {
  $Net::Launchpad::Client::AUTHORITY = 'cpan:ADAMJS';
}
# ABSTRACT: Launchpad.net Client
$Net::Launchpad::Client::VERSION = '2.101';
# TODO:
# <wgrant> stokachu: A GET to the API root with an Accept header of
# "application/vd.sun.wadl+xml". This is documented on
# https://help.launchpad.net/API/Hacking, fwiw.
# <wgrant> Also, a GET to the application root itself will give you the root collects as JSON.
# <wgrant> eg. https://api.launchpad.net/1.0//?ws.accept=application/json
# <wgrant> (ws.accept overrides the Accepts header, for easy poking in a browser)
# <wgrant> The HTML docs are generated from the machine-readable
# WADL. You don't need to parse the WADL unless you want something
# like launchpadlib, where objects know about their methods, and check
# arguments automatically, etc.


use Moose;
use Function::Parameters;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::JSON qw(decode_json);
use Mojo::Parameters;
use namespace::autoclean;

has consumer_key        => (is => 'ro', isa => 'Str');
has access_token        => (is => 'ro', isa => 'Str');
has access_token_secret => (is => 'ro', isa => 'Str');
has staging             => (is => 'ro', isa => 'Int', default => 0);

has 'ua' => (
    is      => 'ro',
    isa     => 'Mojo::UserAgent',
    default => method {
        my $ua = Mojo::UserAgent->new;
        $ua->transactor->name("Net::Launchpad");
        return $ua;
    }
);

has 'nonce' => (
    is      => 'ro',
    isa     => 'Str',
    default => method {
        my @a = ('A' .. 'Z', 'a' .. 'z', 0 .. 9);
        my $nonce = '';
        for (0 .. 31) {
            $nonce .= $a[rand(scalar(@a))];
        }
        return $nonce;
    }
);

has 'authorization_header' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_auth_header',
    documentation =>
      "Composed authorization string for accessing priveledged data"
);

method _build_auth_header {
    return join(",",
        'OAuth realm="https://api.launchpad.net"',
        'oauth_consumer_key=' . $self->consumer_key,
        'oauth_version=1.0',
        'oauth_signature_method=PLAINTEXT',
        'oauth_signature=' . '&' . $self->access_token_secret,
        'oauth_token=' . $self->access_token,
        'oauth_token_secret=' . $self->access_token_secret,
        'oauth_timestamp=' . time,
        'oauth_nonce=' . $self->nonce);
}

method api_url {
    return Mojo::URL->new('https://api.launchpad.net/1.0/')
      unless $self->staging;
    return Mojo::URL->new('https://api.staging.launchpad.net/1.0/');
}

method __path_cons($path) {
    if ($path =~ /^http.*api/) {
        return Mojo::URL->new($path);
    }
    return $self->api_url->path($path);
}

method post (Str $resource, HashRef $params) {
    my $params_hash = Mojo::Parameters->new($params);
    my $uri         = $self->__path_cons($resource);
    my $tx =
      $self->ua->post($uri->to_string =>
          {'Authorization' => $self->authorization_header} => form =>
          $params_hash->to_string);
    die $tx->res->message unless $tx->success;
}

method get (Str $resource) {
    my $uri = $self->__path_cons($resource);
    my $tx =
      $self->ua->get(
        $uri->to_string => {'Authorization' => $self->authorization_header});
    if ($tx->success) {
      return decode_json($tx->res->body);
    } else {
      my $err = $tx->error;
      die "$err->{code} response: $err->{message}" if $err->{code};
    }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Client - Launchpad.net Client

=head1 VERSION

version 2.101

=head1 SYNOPSIS

    use Net::Launchpad::Client;
    my $lp = Net::Launchpad::Client->new(
        access_token        => '32432432432',
        access_token_secret => '32432432423432423432423232',
        consumer_key        => 'a-named-key'
    );

=head1 ATTRIBUTES

=head2 consumer_key

OAuth Consumer key

=head2 access_token

OAuth access token

=head2 access_token_secret

OAuth access_token_secret

=head2 staging

Staging or Production boolean

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
