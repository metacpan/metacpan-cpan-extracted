package SRU::Utils::XMLTest;
{
  $SRU::Utils::XMLTest::VERSION = '1.01';
}
#ABSTRACT: XML testing utility functions

use strict;
use warnings;
use XML::LibXML;
use base qw( Exporter );

our @EXPORT = qw( wellFormedXML );


sub wellFormedXML {
    my $xml_string = shift;
    eval {  
        my $parser = XML::LibXML->new;
        $parser->parse_string($xml_string);
    };
    return $@ ? 0 : 1;
}

1;

__END__

=pod

=head1 NAME

SRU::Utils::XMLTest - XML testing utility functions

=head1 SYNOPSIS

    use SRU::Utils::XMLText;
    ok( wellFormedXML($xml), '$xml is well formed' );

=head1 DESCRIPTION

This is a set of utility functions for use with testing XML data.

=head1 METHODS

=head2 wellFormedXML( $xml )

Checks if C<$xml> is welformed.

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
