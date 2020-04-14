package Net::SAML2::XML::Util;

use strict;
use warnings;

use XML::Tidy;

# use 'our' on v5.6.0
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS $DEBUG);

$DEBUG = 0;
$VERSION = '0.20';

# We are exporting functions
use base qw/Exporter/;

# Export list - to allow fine tuning of export table
@EXPORT_OK = qw( no_comments );



sub no_comments {
    my $xml = shift;

    # Remove comments from XML to mitigate XML comment auth bypass
    my $tidy_obj = XML::Tidy->new(xml => $xml);
    $tidy_obj->prune('//comment()');
    return $tidy_obj->toString();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::XML::Util

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  my $xml = no_comments($xml);

=head1 NAME

Net::SAML2::XML::Util - XML Util class.

=head1 METHODS

=head2 no_comments( $xml )

Returns the XML passed as plain XML with the comments removed

This is to remediate CVE-2017-11427 XML Comments can allow for
authentication bypass in SAML2 implementations

=head1 AUTHOR

Original Author: Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Andrews and Others; in detail:

  Copyright 2019-2020  Timothy Legge


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
