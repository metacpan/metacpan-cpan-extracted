package Net::Google::FederatedLogin::Gmail::Discoverer;
{
  $Net::Google::FederatedLogin::Gmail::Discoverer::VERSION = '0.8.0';
}
# ABSTRACT: Find the OpenID endpoint for standard gmail accounts

use Moose;

with 'Net::Google::FederatedLogin::Role::Discoverer';

my $DISCOVERY_URL = 'https://www.google.com/accounts/o8/id';


sub perform_discovery {
    my $self = shift;
    
    my $ua = $self->ua;
    my $response = $ua->get($DISCOVERY_URL,
        Accept => 'application/xrds+xml');
    
    my $open_id_endpoint;
    
    require XML::Twig;
    my $xt = XML::Twig->new(
        twig_handlers => { URI => sub {$open_id_endpoint = $_->text}},
    );
    $xt->parse($response->decoded_content);
    
    return $open_id_endpoint;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Net::Google::FederatedLogin::Gmail::Discoverer - Find the OpenID endpoint for standard gmail accounts

=head1 VERSION

version 0.8.0

=head1 METHODS

=head2 perform_discovery

Performs OpenID endpoint discovery for gmail accounts

=head1 AUTHOR

Glenn Fowler <cebjyre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Glenn Fowler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
