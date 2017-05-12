use strict;
use warnings FATAL => 'all';

# ABSTRACT: formatting MAC addresses with colon separated hex values

package NetObj::MacAddress::Formatter::Colons;
$NetObj::MacAddress::Formatter::Colons::VERSION = '1.0.2';
sub format {
    my ($mac) = @_;
    return join(':', unpack('H2' x 6, $mac->binary()));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NetObj::MacAddress::Formatter::Colons - formatting MAC addresses with colon separated hex values

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  use NetObj::MacAddress::Formatter::Colons;
  my $mac = NetObj::MacAddress->new('080020abcdef');
  $mac->to_string('colons'); # '08:00:20:ab:cd:ef'

=head1 DESCRIPTION

Helper module to format a MAC address as a string in hex colon delimeted
format.

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
