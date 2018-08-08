package Net::SPID;
$Net::SPID::VERSION = '0.15';
# ABSTRACT: SPID implementation for Perl
use strict;
use warnings;

use Net::SPID::OpenID;
use Net::SPID::SAML;
use Net::SPID::Session;

sub new {
    my ($class, %args) = @_;
    
    my $protocol = exists $args{protocol}
        ? lc delete $args{protocol}
        : 'saml';
    
    return $protocol eq 'openid'
        ? Net::SPID::OpenID->new(%args)
        : Net::SPID::SAML->new(%args);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID - SPID implementation for Perl

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Net::SPID;
    
    my $spid = Net::SPID->new(
        sp_entityid     => 'https://www.prova.it/',
        sp_key_file     => 'sp.key',
        sp_cert_file    => 'sp.pem',
    );
    
    # load Identity Providers
    $spid->load_idp_metadata('idp_metadata/');
    # or:
    $spid->load_idp_from_xml_file('idp_metadata/prova.xml');
    # or:
    $spid->load_idp_from_xml($metadata_xml);
    
    # get an IdP
    my $idp = $spid->get_idp('https://www.prova.it/');
    
    # generate an AuthnRequest
    my $authnreq = $idp->authnrequest(
        acs_index   => 0,   # index of AssertionConsumerService as per our SP metadata
        attr_index  => 1,   # index of AttributeConsumingService as per our SP metadata
        level       => 1,   # SPID level
    );
    
    # prepare a HTTP-Redirect binding
    my $url = $authnreq->redirect_url;

=head1 ABSTRACT

This Perl module is aimed at implementing SPID Service Providers and Attribute Authorities. L<SPID|https://www.spid.gov.it/> is the Italian digital identity system, which enables citizens to access all public services with single set of credentials. This module provides a layer of abstraction over the SAML protocol by exposing just the subset required in order to implement SPID authentication in a web application. In addition, it will be able to generate the HTML code of the SPID login button and enable developers to implement an Attribute Authority.

This module is not bound to any particular web framework, so you'll have to do some plumbing yourself in order to route protocol messages over HTTP (see the F<example/> directory for a full working example).
On top of this module, plugins for web frameworks can be developed in order to achieve even more API abstraction.

See F<README.md> for a full feature list with details about SPID compliance.

=head1 CONSTRUCTOR

=head2 new

A C<protocol> argument may be supplied to C<new>, with the C<saml> (default) or C<openid> value. According to this argument, a L<Net::SPID::SAML> or a L<Net::SPID::OpenID> object will be returned. See their documentation for the other arguments which can be supplied to C<new>.

=head1 SEE ALSO

=over

=item L<Dancer2::Plugin::SPID>

=item L<https://developers.italia.it/en/spid>

=back

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
