#!perl -T

# Testing should be friendly and nice looking, not dull ugly text.

use strict;
use warnings FATAL => 'all';

use Term::ANSIScreen qw( :cursor :screen );
use Term::ANSIColor;
use List::Util qw(max);
use utf8;
use Data::Dumper;

use Test::More tests => 2096;
# use Test::More 'no_plan';

BEGIN {
    $ENV{'PATH'} .= ';/usr/bin';
    use_ok('Term::ANSIEncode') || BAIL_OUT('Cannot load Term::ANSIEncode!');
}

# utf8 must be enabled
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

diag("\r" . colored(['magenta'], '=' x 65));
diag("\r" . colored(['cyan on_black'], q{ 888888888888                         88                         }));
diag("\r" . colored(['cyan on_black'], q{      88                        ,d    ""                         }));
diag("\r" . colored(['cyan on_black'], q{      88                        88                               }));
diag("\r" . colored(['cyan on_black'], q{      88  ,adPPYba, ,adPPYba, MM88MMM 88 8b,dPPYba,   ,adPPYb,d8 }));
diag("\r" . colored(['cyan on_black'], q{      88 a8P_____88 I8[    ""   88    88 88P'   `"8a a8"    `Y88 }));
diag("\r" . colored(['cyan on_black'], q{      88 8PP"""""""  `"Y8ba,    88    88 88       88 8b       88 }));
diag("\r" . colored(['cyan on_black'], q{      88 "8b,   ,aa aa    ]8I   88,   88 88       88 "8a,   ,d88 }));
diag("\r" . colored(['cyan on_black'], q{      88  `"Ybbd8"' `"YbbdP"'   "Y888 88 88       88  `"YbbdP"Y8 }));
diag("\r" . colored(['cyan on_black'], q{                                                      aa,    ,88 }));
diag("\r" . colored(['yellow on_black'], q{  Term::ANSIEncode}) . colored(['cyan on_black'], q{                                     "Y8bbdP"  }));
diag("\r" . colored(['magenta'], '=' x 65));
diag("\r  \n\r" x 12 . "\e[13A");
diag("\r  \n\r" . colored(['bright_yellow on_magenta'],sprintf('%-41s',' Testing object creation ')));
my $ansi = Term::ANSIEncode->new('columns' => 80);
isa_ok($ansi,'Term::ANSIEncode');
diag("\e[1A\r" . colored(['bright_yellow on_magenta'],sprintf('%-41s',' Tested object creation ')) . colored(['bright_green'], ' OK'));

my $max = 1;
diag("\r" . colored(['bright_yellow on_blue'],sprintf('%-41s',' Testing tokens ')) . colored(['yellow'],' ...'));
foreach my $code (keys %{$ansi->{'ansi_meta'}}) {
    foreach my $t (keys %{$ansi->{'ansi_meta'}->{$code}}) {
        $max = max(length($t),$max);
    }
}
$max += 6;
my @colors = ('red','yellow','green','cyan','magenta','bright_blue');
foreach my $code (sort(keys %{$ansi->{'ansi_meta'}})) {
    my $color = shift(@colors);
    foreach my $token (sort(keys %{$ansi->{'ansi_meta'}->{$code}})) {
        next if ($token =~ /NEWLINE|LINEFEED|RETURN|HORIZONTAL/);
        my $text   = '[% ' . $token . ' %]';
        diag("\r" . clline .
            colored(['white'], sprintf('%28s', 'Testing')) .
            colored([$color], ' ' . uc($code) . ' ') .
            colored(['white'], 'tokens -> ') .
            colored(['bright_yellow'], $text) . clline . "\r\e[1A"
        );
		my $output = $ansi->ansi_decode($text);

		$output =~ s/\e/\\e/gs;
		$output =~ s/\r/\\r/gs;

		my $test = $ansi->{'ansi_meta'}->{$code}->{$token}->{'out'};

		# If 24-bit is not supported, downsample the expected string to match
		if (! $ansi->{'CAPS'}->{'24 BIT'} && $test =~ /^\e\[(38|48);2;(\d+);(\d+);(\d+)m$/) {
			$test = $ansi->_rgb_to_ansi($2, $3, $4, ($1 eq '48' ? 1 : 0));
		}

		$test =~ s/\e/\\e/gs;
		$test =~ s/\[\% RETURN \%\]/\\r/gs;

		cmp_ok($output,'eq', $test, $text);
    }
    diag("\r" . clline .
        colored(['white'], sprintf('%29s','Tested ')) .
        colored([$color], sprintf('%-12s %s',' ' . uc($code) . ' ', colored(['bright_green'],'OK'))) .
        clline
    );
}
diag("\r" . ' ' x 79 . "\r\e[7A" . colored(['bright_yellow on_blue'],sprintf('%-41s',' Tested tokens ')) . colored(['bright_green'],' OK ') . clline . "\n\r " x 6);

diag("\r" . clline . colored(['bright_yellow on_cyan'],  sprintf('%-41s', ' Testing extended attributes ')) . colored(['bright_yellow'],' ...'));

{
    my $text = q{[% JUSTIFIED %]There are many more background colors available than the sixteen below.  However, the ones below should work on any color terminal.  Other colors may require 256 and 16 million color support.  Most Linux X-Windows and Wayland terminal software should support the extra colors.  Some Windows terminal software should have 'Term256' features.  You can used the '-t' option for all of the color tokens available or use the 'B_RGB' token for access to 16 million colors.[% ENDJUSTIFIED %]};
    my $expected = qq{There are many  more  background  colors  available  than  the  sixteen  below.\nHowever, the ones below should work on any color terminal.   Other  colors  may\nrequire 256 and 16 million color support.  Most  Linux  X-Windows  and  Wayland\nterminal software should support  the  extra  colors.   Some  Windows  terminal\nsoftware should have 'Term256' features.  You can used the '-t' option for  all\nof the color tokens available or use the 'B_RGB' token for access to 16 million\ncolors.};
    diag("\r" . clline .
        colored(['bright_white on_black'], sprintf('%41s', ' JUSTIFIED ')) .
        colored(['bright_yellow'], ' [% JUSTIFIED %]...[% ENDJUSTIFIED %]') . "\r\e[1A"
    );
    if (cmp_ok($ansi->ansi_decode($text), 'eq', $expected, "JUSTIFIED")) {
		diag("\r" . clline . 
			colored(['bright_white on_black'], sprintf('%41s', ' JUSTIFIED ')) .
			colored(['bright_green'], ' OK')
		);
	} else {
		diag("\r" . clline . 
			colored(['bright_white on_black'], sprintf('%41s', ' JUSTIFIED ')) .
			colored(['bright_red'], ' FAILED')
		);
	}
}

{
    my $text = q{[% UNDERLINE COLOR RED %]};
    my $expected = $ansi->{'CAPS'}->{'24 BIT'} || $ansi->{'CAPS'}->{'8 BIT'} ? "\e[58;5;1m" : '';

    diag("\r" . clline .
        colored(['bright_white on_black'], sprintf('%41s', ' UNDERLINE COLOR color ')) .
        colored(['bright_yellow'], " $text") . clline . "\r\e[1A"
    );

    cmp_ok($ansi->ansi_decode($text), 'eq', $expected, $text);
    diag("\r" . clline . 
        colored(['bright_white on_black'], sprintf('%41s', ' UNDERLINE COLOR color ')) .
        colored(['bright_green'], ' OK')
    );
}

{
    my $text = q{[% UNDERLINE COLOR RGB 255,0,0 %]};
    my $expected;
    if ($ansi->{'CAPS'}->{'24 BIT'}) {
        $expected = "\e[58;2;255;0;0m";
    } elsif ($ansi->{'CAPS'}->{'8 BIT'}) {
        my $code = $ansi->_rgb_to_256(255, 0, 0);
        $expected = "\e[58;5;${code}m";
    } else {
        $expected = '';
    }

    diag("\r" . clline .
        colored(['bright_white on_black'], sprintf('%41s', ' UNDERLINE COLOR RGB r,g,b ')) .
        colored(['bright_yellow'], " $text") . clline . "\r\e[1A"
    );

    cmp_ok($ansi->ansi_decode($text), 'eq', $expected, $text);
    diag("\r" . clline . 
        colored(['bright_white on_black'], sprintf('%41s', ' UNDERLINE COLOR RGB r,g,b ')) .
        colored(['bright_green'], ' OK')
    );
}

{
    my $text = q{[% WRAP %]There are many more background colors available than the sixteen below.  However, the ones below should work on any color terminal.  Other colors may require 256 and 16 million color support.  Most Linux X-Windows and Wayland terminal software should support the extra colors.  Some Windows terminal software should have 'Term256' features.  You can used the '-t' option for all of the color tokens available or use the 'B_RGB' token for access to 16 million colors.[% ENDWRAP %]};
    my $expected = qq{There are many more background colors available than the sixteen below.\nHowever, the ones below should work on any color terminal.  Other colors may\nrequire 256 and 16 million color support.  Most Linux X-Windows and Wayland\nterminal software should support the extra colors.  Some Windows terminal\nsoftware should have 'Term256' features.  You can used the '-t' option for all\nof the color tokens available or use the 'B_RGB' token for access to 16 million\ncolors.};
    diag("\r" . clline .
        colored(['bright_white on_black'], sprintf('%41s', ' WRAP ')) .
        colored(['bright_yellow'], ' [% WRAP %]...[% ENDWRAP %]') . "\r\e[1A"
    );
    if (cmp_ok($ansi->ansi_decode($text), 'eq', $expected, 'WRAP')) {
		diag("\r" . clline . 
			colored(['bright_white on_black'], sprintf('%41s', ' WRAP ')) .
			colored(['bright_green'], ' OK')
		);
	} else {
		diag("\r" . clline . 
			colored(['bright_white on_black'], sprintf('%41s', ' WRAP ')) .
			colored(['bright_red'], ' FAILED')
		);
	}
}

diag("\r" . ' ' x 79 . "\r\e[5A" . colored(['bright_yellow on_cyan'],sprintf('%-41s',' Tested extended attributes ')) . colored(['bright_green'],' OK ') . clline . "\n\r " x 4);

diag("\r" . clline . colored(['bright_yellow on_blue'],  sprintf('%-41s', ' Testing macros ')) . colored(['bright_yellow'],' ...'));
{
    my $text = q{[% BLOCK 3 %]Duplicate this[% ENDBLOCK %]};
    my $expected = 'Duplicate thisDuplicate thisDuplicate this';
    diag("\r" . clline .
        colored(['bright_white on_black'], sprintf('%41s', ' BLOCK count ')) .
        colored(['bright_yellow'], " $text") . clline . "\r\e[1A"
    );
    cmp_ok($ansi->ansi_decode($text), 'eq', "$expected", $text);
    diag("\r" . clline . 
        colored(['bright_white on_black'], sprintf('%41s', ' BLOCK count ')) .
        colored(['bright_green'], ' OK')
    );
}

{
	my $text = q{[% BOX BLUE,10,10,40,4,DOUBLE %]Text that will be wrapped inside the box[% ENDBOX %]};

	# Construct the exact expected byte sequence emitted by ansi_box():
	# Top border (row 10, col 10, w=40)
	# Middle rows (rows 11..12)
	# Bottom border (row 13) + Save Cursor (\e[s)
	# Target coordinate prefix before formatting: \e[11;11H
	# Text lines (width = 40 - 3 = 37) positioned at 11;11 and 12;11
	# Restore Cursor (\e[u)
	my $expected = 
	  "\e[10;10H\e[34m╔" . ('═' x 38) . "╗\e[0m" .
	  "\e[11;10H\e[34m║\e[0m" . (' ' x 38) . "\e[34m║\e[0m" .
	  "\e[12;10H\e[34m║\e[0m" . (' ' x 38) . "\e[34m║\e[0m" .
	  "\e[13;10H\e[34m╚" . ('═' x 38) . "╝\e[0m\e[s" .
	  "\e[11;11H" .
	  "\e[11;11HText that will be wrapped inside the\e[12;11Hbox" .
	  "\e[u";

	diag("\r" . clline .
		colored(['bright_white on_black'], sprintf('%41s', ' BOX color,column,row,width,height,type ')) .
		colored(['bright_yellow'], " $text") . clline . "\r\e[1A"
	);

	my $got = $ansi->ansi_decode($text);

	if (cmp_ok($got, 'eq', $expected, ' [% BOX ... %] ')) {
		diag("\r" . clline .
			colored(['bright_white on_black'], sprintf('%41s', ' BOX color,column,row,width,height,type ')) .
			colored(['bright_green'], ' OK')
		);
	} else {
		diag("\r" . clline .
			colored(['bright_white on_black'], sprintf('%41s', ' BOX color,column,row,width,height,type ')) .
			colored(['bright_red'], ' FAILED')
		);
	}
}

{
    my $text = q{[% CHAR X,20 %]};
    my $expected = 'X' x 20;
    diag("\r" . clline .
        colored(['bright_white on_black'], sprintf('%41s', ' CHAR char,count ')) .
        colored(['bright_yellow'], " $text") . clline . "\r\e[1A"
    );
    cmp_ok($ansi->ansi_decode($text), 'eq', $expected, $text);
    diag("\r" . clline . 
        colored(['bright_white on_black'], sprintf('%41s', ' CHAR char,count ')) .
        colored(['bright_green'], ' OK')
    );
}

{
    my $text = q{[% SPACES 20 %]};
    my $expected = ' ' x 20;
    diag("\r" . clline .
        colored(['bright_white on_black'], sprintf('%41s', ' SPACES count ')) .
        colored(['bright_yellow'], " $text") . clline . "\r\e[1A"
    );
    cmp_ok($ansi->ansi_decode($text), 'eq', $expected, $text);
    diag("\r" . clline . 
        colored(['bright_white on_black'], sprintf('%41s', ' SPACES count ')) .
        colored(['bright_green'], ' OK')
    );
}

{
    my $text = q{[% CANVAS 5, 2, 40, 20 %]pixel 0,0[% ENDCANVAS %]};

    diag("\r" . clline .
        colored(['bright_white on_black'], sprintf('%41s', ' CANVAS col,row,width,height ')) .
        colored(['bright_yellow'], " $text") . clline . "\r\e[1A"
    );

    my $got = $ansi->ansi_decode($text);

    # Verify cursor save, coordinate positioning at column 5, row 2, and cursor restore
    if ($got =~ /\e\[s/ && $got =~ /\e\[2;5H/ && $got =~ /\e\[u/) {
        pass(' [% CANVAS ... %] ');
        diag("\r" . clline .
            colored(['bright_white on_black'], sprintf('%41s', ' CANVAS col,row,width,height ')) .
            colored(['bright_green'], ' OK')
        );
    } else {
        fail(' [% CANVAS ... %] ');
        diag("\r" . clline .
            colored(['bright_white on_black'], sprintf('%41s', ' CANVAS col,row,width,height ')) .
            colored(['bright_red'], ' FAILED')
        );
    }
}

diag("\r" . ' ' x 79 . "\r\e[6A" . colored(['bright_yellow on_red'],sprintf('%-41s',' Tested macros ')) . colored(['bright_green'],' OK ') . clline . "\n\r " x 5);

exit(0);

__END__
