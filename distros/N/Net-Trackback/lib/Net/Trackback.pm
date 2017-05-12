# Copyright (c) 2003-2004 Timothy Appnel (cpan@timaoutloud.org)
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
package Net::Trackback;
use strict;
use base qw( Class::ErrorHandler Exporter );

use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( encode_xml decode_xml );

use vars qw($VERSION);
$VERSION = 1.01;

my %Map = ('&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;',
           '\'' => '&apos;');
my %Map_Decode = reverse %Map;
$Map{'\''}='&#39;';
my $RE = join '|', keys %Map;
my $RE_D = join '|', keys %Map_Decode;

sub encode_xml {
    return unless $_[1];
    (my $str = $_[1]) =~ s!($RE)!$Map{$1}!g;
    $str;
}

sub decode_xml {
    return unless $_[1];
    (my $str = $_[1]) =~ s!($RE_D)!$Map_Decode{$1}!g;
    $str;
}


#--- deprecated
sub is_message { ref($_[1]) eq 'Net::Trackback::Message' }
sub is_ping { ref($_[1]) eq 'Net::Trackback::Ping' }
sub is_data { ref($_[1]) eq 'Net::Trackback::Data' }

1;

__END__

=begin

=head1 NAME

Net::Trackback - an object-oriented interface for developing 
Trackback clients and servers,

=head1 DESCRIPTION

This package is an object-oriented interface for developing 
Trackback clients and servers. 

I take no credit for the genius of TrackBack. Initially this module's
code was derived from the standalone reference implementation release 
by Ben and Mena Trott. My motivation in developing this module is 
to make experimentation and implementation of TrackBack functions 
a bit easier.

As of version 0.99, the interface has been overhauled and refined 
from the very crude original alpha release of 0.2x and is not 
backwards compatable in the least.

=head1 METHODS

This module contains two exportable utility methods for working with
XML.

=item encode_xml($string)

A simple utility for encoding XML's five named entities from text.

=item decode_xml($string)

A simple utility for encoding XML's five named entities into text.

=head2 Deprecated

=item Net::Trackback->is_data($object)

Tests if the object is a L<Net::Trackback::Data> object. Returns a 
boolean value.

=item Net::Trackback->is_ping($object)

Tests if the object is a L<Net::Trackback::Ping> object. Returns a 
boolean value.

=item Net::Trackback->is_message($object)

Tests if the object is a L<Net::Trackback::Message> object. Returns
a boolean value.

=head1 DEPENDENCIES

L<LWP>

=head1 SEE ALSO

L<Net::Trackback::Client>, L<Net::Trackback::Server>, 
L<Net::Trackback::Ping>, L<Net::Trackback::Data>, 
L<Net::Trackback::Message>

TrackBack Technical Specification: 
L<http://www.movabletype.org/docs/mttrackback.html>

Trackback Development Weblog: 
L<http://www.movabletype.org/trackback/>

Movable Type User Manual: TRACKBACK:
L<http://movabletype.org/docs/mtmanual_trackback.html>

=head1 TO DO

=item Add functionality to using RSS/Atom to discover pingable 
resources.

=item Implement an optional XML parser option?

=head1 LICENSE

The software is released under the Artistic License. The terms of
the Artistic License are described at
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Net::Trackback is Copyright
2003-2004, Timothy Appnel, cpan@timaoutloud.org. All rights
reserved.

=cut

=end