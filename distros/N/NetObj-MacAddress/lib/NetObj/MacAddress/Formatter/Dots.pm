use strict;
use warnings FATAL => 'all';

# ABSTRACT: formatting MAC addresses in Cisco notation

package NetObj::MacAddress::Formatter::Dots;
$NetObj::MacAddress::Formatter::Dots::VERSION = '1.0.2';
sub format {
    my ($mac) = @_;
    return join('.', unpack('H4' x 3, $_[0]->binary()));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NetObj::MacAddress::Formatter::Dots - formatting MAC addresses in Cisco notation

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  use NetObj::MacAddress::Formatter::Dots;
    my $mac = NetObj::MacAddress->new('080020abcdef');
      $mac->to_string('dots'); # '0800.20ab.cdef'

=head1 DESCRIPTION

Helper module to format a MAC address as a string in hex dot delimited format.

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
