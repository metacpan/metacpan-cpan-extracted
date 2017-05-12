package Gx;
=pod

Gx - shortcut to Regex::Genex strings, regex, rx_string, str_count

Import the functions here and re-exports them for good measure

perl -MGx -le 'print strings(qr/^a(b|c){2,4}/);

NOTE: This file is not installed by default.  
It can only be installed manually as a convenience to
local users so don't it in anything other than throw
away code.  Most importantly, only use the Regexp::Genex
name space in public (I don't have any claim to Gx...)

=cut

use strict; use warnings;
require Exporter;
our @ISA = qw(Exporter);
our $VERSION = 0.06;

# I can do this b/c we're close friends:
use Regexp::Genex qw(:all);  # We want it all
our @EXPORT = @Regexp::Genex::EXPORT_OK; # So do you

1;
