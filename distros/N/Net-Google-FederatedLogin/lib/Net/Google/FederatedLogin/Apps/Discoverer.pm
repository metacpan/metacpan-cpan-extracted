package Net::Google::FederatedLogin::Apps::Discoverer;
{
  $Net::Google::FederatedLogin::Apps::Discoverer::VERSION = '0.8.0';
}
# ABSTRACT: Find the OpenID endpoint for apps domain accounts

use Moose;

with 'Net::Google::FederatedLogin::Role::Discoverer';

use Carp;
use URI::Escape;

has app_domain  => (
    is  => 'rw',
    isa => 'Str',
    required    => 1,
);

has claimed_id  => (
    is  => 'rw',
    isa => 'Str',
);


sub perform_discovery {
    my $self = shift;
    
    require XML::Twig;
    
    my $ua = $self->ua;
    my $response = $ua->get($self->_get_discovery_url,
        Accept => 'application/xrds+xml');
    
    my $open_id_endpoint;
    
    my $xt = XML::Twig->new(
        twig_handlers => {URI => sub {$open_id_endpoint = $_->text}},
    );
    $xt->parse($response->decoded_content);
    
    return $open_id_endpoint;
}

sub _get_discovery_url {
    my $self = shift;
    
    if($self->claimed_id) {
        return $self->_get_user_discovery_url;
    } else {
        return $self->_get_idp_discovery_url;
    }
    
}

sub _get_idp_discovery_url {
    my $self = shift;
    
    my $app_domain = $self->app_domain;
    
    #Check google hosted
    my $host_meta_url = 'https://www.google.com/accounts/o8/.well-known/host-meta?hd=' . $app_domain;
    my $ua = $self->ua;
    my $response = $ua->get($host_meta_url);
    unless($response->is_success) { #fallback to the domain specific location
        $host_meta_url = sprintf 'http://%s/.well-known/host-meta', $app_domain;
        $response = $ua->get($host_meta_url);
    }
    unless($response->is_success) {
        croak 'Unable to find a host-meta page.';
    }
    if($response->decoded_content =~ m{Link: <(.+)>; \Qrel="describedby http://reltype.google.com/openid/xrd-op"; type="application/xrds+xml"\E}) {
        return $1;
    } else {
        croak 'Unable to perform discovery - host-meta page is not as expected.'
    }
}

sub _get_user_discovery_url {
    my $self = shift;
    
    my $claimed_id = $self->claimed_id;
    my $escaped_id = uri_escape($claimed_id);
    
    my $intermediate_url = $self->_get_idp_discovery_url;
    
    my $ua = $self->ua;
    my $response = $ua->get($intermediate_url,
        Accept => 'application/xrds+xml');
    
    my $discovery_url;
    my $xt = XML::Twig->new(
        twig_handlers => { Service => sub {
            if($_->first_child_text('Type') eq 'http://www.iana.org/assignments/relation/describedby') {
                $discovery_url = $_->first_child_text('openid:URITemplate');
                $discovery_url =~ s/{%uri}/$escaped_id/;
            }
        }},
    );
    $xt->parse($response->decoded_content);
    return $discovery_url;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Google::FederatedLogin::Apps::Discoverer - Find the OpenID endpoint for apps domain accounts

=head1 VERSION

version 0.8.0

=head1 METHODS

=head2 perform_discovery

Perform OpenID endpoint discovery for hosted domains - see
http://groups.google.com/group/google-federated-login-api/web/openid-discovery-for-hosted-domains?pli=1
for more details.

=head1 AUTHOR

Glenn Fowler <cebjyre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Glenn Fowler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
