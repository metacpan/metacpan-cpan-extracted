package POE::Component::IRC::Common;
BEGIN {
  $POE::Component::IRC::Common::AUTHORITY = 'cpan:HINRIK';
}
$POE::Component::IRC::Common::VERSION = '6.88';
use strict;
use warnings FATAL => 'all';

use IRC::Utils;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(
    u_irc l_irc parse_mode_line parse_ban_mask matches_mask matches_mask_array
    parse_user has_color has_formatting strip_color strip_formatting NORMAL
    BOLD UNDERLINE REVERSE WHITE BLACK DARK_BLUE DARK_GREEN RED BROWN PURPLE
    ORANGE YELLOW LIGHT_GREEN TEAL CYAN LIGHT_BLUE MAGENTA DARK_GREY
    LIGHT_GREY irc_to_utf8
);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

no warnings 'once'; ## no critic (TestingAndDebugging::ProhibitNoWarnings)
*NORMAL      = *IRC::Utils::NORMAL;
*BOLD        = *IRC::Utils::BOLD;
*UNDERLINE   = *IRC::Utils::UNDERLINE;
*REVERSE     = *IRC::Utils::REVERSE;
*ITALIC      = *IRC::Utils::ITALIC;
*FIXED       = *IRC::Utils::FIXED;
*WHITE       = *IRC::Utils::WHITE;
*BLACK       = *IRC::Utils::BLACK;
*DARK_BLUE   = *IRC::Utils::BLUE;
*DARK_GREEN  = *IRC::Utils::GREEN;
*RED         = *IRC::Utils::RED;
*BROWN       = *IRC::Utils::BROWN;
*PURPLE      = *IRC::Utils::PURPLE;
*ORANGE      = *IRC::Utils::ORANGE;
*YELLOW      = *IRC::Utils::YELLOW;
*LIGHT_GREEN = *IRC::Utils::LIGHT_GREEN;
*TEAL        = *IRC::Utils::TEAL;
*CYAN        = *IRC::Utils::LIGHT_CYAN;
*LIGHT_BLUE  = *IRC::Utils::LIGHT_BLUE;
*MAGENTA     = *IRC::Utils::PINK;
*DARK_GREY   = *IRC::Utils::GREY;
*LIGHT_GREY  = *IRC::Utils::LIGHT_GREY;

*u_irc              = *IRC::Utils::uc_irc;
*l_irc              = *IRC::Utils::lc_irc;
*parse_mode_line    = *IRC::Utils::parse_mode_line;
*parse_ban_mask     = *IRC::Utils::normalize_mask;
*parse_user         = *IRC::Utils::parse_user;
*matches_mask       = *IRC::Utils::matches_mask;
*matches_mask_array = *IRC::Utils::matches_mask_array;
*has_color          = *IRC::Utils::has_color;
*has_formatting     = *IRC::Utils::has_formatting;
*strip_color        = *IRC::Utils::strip_color;
*strip_formatting   = *IRC::Utils::strip_formatting;
*irc_to_utf8        = *IRC::Utils::decode_irc;

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Common - Provides a set of common functions for the
L<POE::Component::IRC|POE::Component::IRC> suite

=head1 SYNOPSIS

 use IRC::Utils;

=head1 DESCRIPTION

B<'ATTENTION'>: Most of this module's functionality has been moved into
L<IRC::Utils|IRC::Utils>. Take a look at it.

This module still exports the old functions (as wrappers around equivalents
from L<IRC::Utils|IRC::Utils>), but new ones won't be added.

=head1 AUTHOR

Chris 'BinGOs' Williams

=head1 SEE ALSO

L<IRC::Utils|IRC::Utils>

L<POE::Component::IRC|POE::Component::IRC>

=cut
