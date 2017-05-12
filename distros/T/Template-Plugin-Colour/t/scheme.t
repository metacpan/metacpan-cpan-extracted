#============================================================= -*-perl-*-
#
# t/scheme.t
#
# Test the Template::Colour modules.  Run with -h option for help.
#
# Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use Badger::Test
    debug => 'Template::Colour Template::Colour::RGB Template::Colour::HSV',
    args  => \@ARGV,
    tests => 5;
    
use Template::Colour;
use constant Col => 'Template::Colour';

my $orange = Template::Colour->new('#ff7f00');
ok( $orange, 'orange' );
is( $orange->darker, '#7F3F00', 'darker orange' );
is( $orange->lighter, '#FFBF7F', 'lighter orange' );
is( $orange->darker->darker, '#3F1F00', 'darker darker orange' );
is( $orange->lighter->lighter, '#FFDFBF', 'lighter lighter orange' );
