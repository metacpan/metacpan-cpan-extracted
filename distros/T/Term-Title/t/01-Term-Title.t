# 01-Term-Title.t
# Copyright (c) 2008 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;

use Test::More;

if ( $ENV{NONINTERACTIVE_TESTING} || $ENV{AUTOMATED_TESTING} ) {
    plan skip_all => "test require user interaction";
}
else {
    plan tests => 8;
}

#--------------------------------------------------------------------------#
# y_n
#--------------------------------------------------------------------------#

sub y_n {
    my ($prompt) = @_;
    my $answer;
    while (1) {
        print STDERR "# $prompt (y/n)?\n";
        $answer = <STDIN>;
        last if $answer =~ /^[yn]/i;
        print STDERR "# Please answer 'y' or 'n'\n";
    }
    return $answer =~ /^y/i;
}

#--------------------------------------------------------------------------#
# tests start here
#--------------------------------------------------------------------------#

require_ok('Term::Title');

can_ok(
    'Term::Title', 'set_titlebar', 'set_tab_title', '_is_supported',
    '_is_supported_tabs'
);

Term::Title->import( 'set_titlebar', 'set_tab_title' );

can_ok( 'main', 'set_titlebar' );
can_ok( 'main', 'set_tab_title' );

# reclaim STDOUT from Test::More
local *STDOUT;
open STDOUT, ">>&=0" or die "Couldn't reclaim STDOUT from Test::More";

diag "Term appears to be '$ENV{TERM}'";

SKIP:
{
    skip "Automated testing not supported title bars", 2
      if $ENV{AUTOMATED_TESTING};

    skip "Term::Title (set term title) not supported on this terminal type", 2
      unless Term::Title::_is_supported();

    my $phrase = "Hello";

    set_titlebar( "[$phrase]", "# Setting title to ", "'[$phrase]'" );
    print STDERR "\n#  (y/n)\n";
    my $y_n = y_n("Do you see '[$phrase]' in the title bar of this window?");
    ok( $y_n, "Title set correctly" );

    # clear
    set_titlebar();
    $y_n = y_n("Has the title bar been cleared?");
    ok( $y_n, "Title cleared correctly" );

    set_titlebar('set_titlebar() works!');
}

SKIP:
{
    skip "Automated testing not supported for tab titles", 2
      if $ENV{AUTOMATED_TESTING};

    skip "Term::Title (set tab title) not supported on this terminal type", 2
      unless Term::Title::_is_supported_tabs();

    my $phrase = "Hello";

    set_tab_title( "[$phrase]", "# Setting title to ", "'[$phrase]'" );
    print STDERR "\n#  (y/n)\n";
    my $y_n = y_n("Do you see '[$phrase]' in the tab title of this window?");
    ok( $y_n, "Tab title set correctly" );

    # clear
    set_tab_title();
    $y_n = y_n("Has the tab title been cleared?");
    ok( $y_n, "Tab title cleared correctly" );

    set_tab_title('set_tab_title() works!');
}
