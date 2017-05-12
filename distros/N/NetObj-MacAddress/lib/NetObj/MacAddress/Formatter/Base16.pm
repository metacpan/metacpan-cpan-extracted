use strict;
use warnings FATAL => 'all';

# ABSTRACT: formatting MAC addresses in base16 hex format

package NetObj::MacAddress::Formatter::Base16;
$NetObj::MacAddress::Formatter::Base16::VERSION = '1.0.2';
sub format {
    my ($mac) = @_;
    return join('', unpack('H2' x 6, $_[0]->binary()));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NetObj::MacAddress::Formatter::Base16 - formatting MAC addresses in base16 hex format

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  use NetObj::MacAddress::Formatter::Base16; # implicit for base16 format
  my $mac = NetObj::MacAddress->new('080020abcdef');
  $mac->to_string('base16'); # '080020abcdef'

=head1 DESCRIPTION

Helper module to format a MAC address as a string in hex base16 format.

=head1 METHODS

=head2 format

Method to do the actual formatting. Used by C<NetObj::MacAddress>.

=head1 AUTHOR

Elmar S. Heeb <elmar@heebs.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Elmar S. Heeb.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
