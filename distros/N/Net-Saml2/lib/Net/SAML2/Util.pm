package Net::SAML2::Util;

use strict;
use warnings;

use Crypt::OpenSSL::Random qw(random_pseudo_bytes);

# ABSTRACT: Utility functions for Net:SAML2

use Exporter qw(import);

our @EXPORT_OK = qw(
    generate_id
);

sub generate_id {
    return 'NETSAML2_' . unpack 'H*', random_pseudo_bytes(16);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Util - Utility functions for Net:SAML2

=head1 VERSION

version 0.28

=head1 SYNOPSIS

    use Net::SAML2::Util qw(generate_id);

=head1 DESCRIPTION

=head1 METHODS

=head2 sub generate_id {}

Generate a NETSAML2 Request Id

=head1 AUTHOR

Original Author: Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Andrews and Others; in detail:

  Copyright 2020       Timothy Legge, Wesley Schwengle


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
