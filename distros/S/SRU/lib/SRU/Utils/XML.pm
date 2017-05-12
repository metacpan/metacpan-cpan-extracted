package SRU::Utils::XML;
{
  $SRU::Utils::XML::VERSION = '1.01';
}
#ABSTRACT: XML utility functions for SRU

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( element elementNoEscape escape stylesheet );


sub element {
    my ($tag, $text) = @_;
    return '' if ! defined $text;
    return "<$tag>" . escape($text) . "</$tag>";
}


sub elementNoEscape {
    my ($tag, $text) = @_;
    return '' if ! defined $text;
    return "<$tag>$text</$tag>";
}


sub escape {
    my $text = shift || '';
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/&/&amp;/g;
    return $text;
}


sub stylesheet {
    my $uri = shift;
    return qq(<?xml-stylesheet type='text/xsl' href="$uri" ?>);
}

1;

__END__

=pod

=head1 NAME

SRU::Utils::XML - XML utility functions for SRU

=head1 SYNOPSIS

    use SRU::Utils::XML qw( escape );
    return escape( $text );

=head1 DESCRIPTION

This is a set of utility functions for use with XML data.

=head1 METHODS

=head2 element( $tag, $text )

Creates an xml element named C<$tag> containing escaped data (C<$text>).

=cut

=head2 elementNoEscape( $tag, $text )

Similar to C<element>, except that C<$text> is not escaped.

=cut

=head2 escape( $text )

Does minimal escaping on C<$text>.

=cut

=head2 stylesheet( $uri )

A shortcut method to create an xml-stylesheet declaration. 

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
