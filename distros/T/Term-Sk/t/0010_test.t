use strict;
use warnings;

use Test::More tests => 78;

use_ok('Term::Sk');

{
    my $ctr = Term::Sk->new('%2d Elapsed: %8t %21b %4p %2d (%8c of %11m) %P', { test => 1 } );
    ok(defined($ctr),                         'Test-0010: standard counter works ok');
}

{
    my $ctr = eval{ Term::Sk->new('%', { test => 1 } )};
    ok($@,                                    'Test-0020: invalid id aborts ok');
    like($@, qr{\AError-0*100},               'Test-0030: with errorcode 100');
    like($@, qr{Can't parse},                 'Test-0040: and error message Can\'t parse');
}

{
    my $ctr = eval{ Term::Sk->new('%z', { test => 1 } )};
    ok($@,                                    'Test-0050: unknown id aborts ok');
    like($@, qr{\AError-0*110},               'Test-0060: with errorcode 110');
    like($@, qr{invalid display-code},        'Test-0070: and error message invalid display-code');
}

{
    my $ctr = Term::Sk->new('Test %d', { test => 1 } );
    ok(defined($ctr),                         'Test-0080: %d works ok');
    is(content($ctr->get_line), 'Test -',     'Test-0090: first displays -');
    $ctr->up;
    is(content($ctr->get_line), 'Test \\',    'Test-0100: then  displays \\');
    $ctr->up;
    is(content($ctr->get_line), 'Test |',     'Test-0110: then  displays |');
    $ctr->up;
    is(content($ctr->get_line), 'Test /',     'Test-0120: then  displays /');
}

{
    my $ctr = Term::Sk->new('Elapsed %8t', { test => 1 } );
    ok(defined($ctr),                         'Test-0125: %t works ok');
    like(content($ctr->get_line), qr{^Elapsed \d{2}:\d{2}:\d{2}$},
                                              'Test-0130: and displays the time elapsed');
}

{
    my $ctr = Term::Sk->new('Bar %10b', { test => 1, target => 20, pdisp => '!' } );
    ok(defined($ctr),                         'Test-0140: %b works ok');
    $ctr->up for 1..11;
    is(content($ctr->get_line), 'Bar ######____',
                                              'Test-0150: always use hash for progress bar');
}

{
    my $ctr = Term::Sk->new('Percent %4p', { test => 1, target => 20 } );
    ok(defined($ctr),                         'Test-0160: %p works ok');
    $ctr->up for 1..5;
    is(content($ctr->get_line), 'Percent  25%',
                                              'Test-0170: and displays 25% after a quarter of it\'s way');
}

{
    my $ctr = Term::Sk->new('%P', { test => 1 } );
    ok(defined($ctr),                         'Test-0180: %P (in captital letters) works ok');
    is(content($ctr->get_line), '%',          'Test-0190: and displays a percent symbol');
}

{
    my $ctr = Term::Sk->new('Ctr %5c', { test => 1, base => 1000 } );
    ok(defined($ctr),                         'Test-0200: %c works ok');
    $ctr->up for 1..8;
    is(content($ctr->get_line), 'Ctr 1_008',  'Test-0210: and displays the correct counter value');
}

{
    my $ctr = Term::Sk->new('Tgt %5m', { test => 1, target => 9876 } );
    ok(defined($ctr),                         'Test-0220: %m works ok');
    is(content($ctr->get_line), 'Tgt 9_876',  'Test-0230: and displays the correct target value');
}

{
    my $ctr = Term::Sk->new('Test', { test => 1 } );
    ok(defined($ctr),                         'Test-0240: Simple fixed text works ok');
    $ctr->whisper('abc');
    is(content($ctr->get_line), 'abcTest',    'Test-0250: and whisper() works as expected');
}

{
    my $ctr = Term::Sk->new('Dummy', { test => 1 } );
    ok(defined($ctr),                         'Test-0260: Simple fixed text works ok');
    $ctr->close;
    is(content($ctr->get_line), '',           'Test-0270: and close() works as expected');
}

{
    my $ctr = Term::Sk->new('Dummy', { test => 1 } );
    ok(defined($ctr),                         'Test-0280: %c works ok');
    $ctr->up for 1..27;
    is($ctr->ticks, 27,                       'Test-0290: number of ticks are correct');
}

{
    my $ctr = Term::Sk->new('num %2c of %2m', { test => 1, base => 3, target => 45678 } );
    ok(defined($ctr),                                           'Test-0300: %2c of %2m works ok');
    is(content($ctr->get_line), 'num  3 of 45_678',             'Test-0310: first number %2c of %2m displayed correctly');
    $ctr->up(10);
    is(content($ctr->get_line), 'num 13 of 45_678',             'Test-0320: second number %2c of %2m displayed correctly');
    $ctr->up(85612);
    is(content($ctr->get_line), 'num 85_625 of 45_678',         'Test-0330: third number %2c of %2m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9,999} } );
    ok(defined($ctr),                                           'Test-0340: %c of %m works ok');
    is(content($ctr->get_line), 'num 1,234,567 of 2,345,678',   'Test-0350: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9 999} } );
    ok(defined($ctr),                                           'Test-0360: %c of %m works ok');
    is(content($ctr->get_line), 'num 1 234 567 of 2 345 678',   'Test-0370: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9_999} } );
    ok(defined($ctr),                                           'Test-0380: %c of %m works ok');
    is(content($ctr->get_line), 'num 1_234_567 of 2_345_678',   'Test-0390: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9_99} } );
    ok(defined($ctr),                                           'Test-0400: %c of %m works ok');
    is(content($ctr->get_line), 'num 1_23_45_67 of 2_34_56_78', 'Test-0410: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9} } );
    ok(defined($ctr),                                           'Test-0420: %c of %m works ok');
    is(content($ctr->get_line), 'num 1234567 of 2345678',       'Test-0430: first number %c of %m displayed correctly');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{9'999} } );
    ok(defined($ctr),                                           'Test-0440: %c of %m works ok');
    is(content($ctr->get_line), q{num 1'234'567 of 2'345'678},  'Test-0450: first number %c of %m displayed correctly');
}

{
    my $ctr = eval{Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, num => q{8'888} } )};
    ok($@,                                                      'Test-0460: fails ok');
    like($@, qr{Can't [ ] parse [ ] num}xms,                    'Test-0470: error message');
}

{
    my $flatfile = "Test hijabc\010\010\010xyzklm";

    Term::Sk::rem_backspace(\$flatfile);

    is($flatfile, 'Test hijxyzklm',                             'Test-0480: backspaces have been removed');
}

{
    my $flatfile = ('abcde' x 37).("\010" x 28).'fghij';

    Term::Sk::rem_backspace(\$flatfile);

    is(length($flatfile), 162,                                  'Test-0540: length abcde (200,15)');
    is(substr($flatfile, -10), 'cdeabfghij',                    'Test-0560: trailing characters for abcde (200,15)');
}

{
    my $ctr = Term::Sk->new('num %c of %m', { test => 1, base => 1234567, target => 2345678, commify => sub{ join '!', split m{}xms, $_[0]; } });
    ok(defined($ctr),                                           'Test-0590: commify sub works ok');
    is(content($ctr->get_line), 'num 1!2!3!4!5!6!7 of 2!3!4!5!6!7!8',
                                                                'Test-0600: show commified numbers');
}

{
    my $ctr = Term::Sk->new('Token %6k Ctr %c', { test => 1, base => 1, token => 'Spain' } );
    ok(defined($ctr),                                           'Test-0610: %6k %c works ok');
    is(content($ctr->get_line), q{Token Spain  Ctr 1},          'Test-0620: first Token displayed correctly');
    $ctr->token('USA');
    is(content($ctr->get_line), q{Token USA    Ctr 1},          'Test-0630: second Token displayed correctly');
    $ctr->tok_maybe('China');
    is(content($ctr->get_line), q{Token China  Ctr 1},          'Test-0632: third Token displayed correctly');
}

{
    # mock-time = Tue Jun 21 14:21:02-28 2011
    my $ctr = Term::Sk->new('Time %8t Ctr %c', { test => 1, base => 3, mock_tm => 1308658862.287032} );
    ok(defined($ctr),                                           'Test-0640: %8t %c works ok');
    is(content($ctr->get_line), q{Time 00:00:00 Ctr 3},         'Test-0650: first Time displayed correctly');
    # mock-time = Tue Jun 21 14:29:37-53 2011
    $ctr->mock_time(1308659377.534502);
    $ctr->up;
    is(content($ctr->get_line), q{Time 00:08:35 Ctr 4},         'Test-0660: second Time displayed correctly');
}

{
    # mock-time = Tue Jun 21 14:21:02-28 2011
    my $ctr = Term::Sk->new('Time %8t %d Ctr %c', { test => 1, base => 2, mock_tm => 1308658862.287032} );
    ok(defined($ctr),                                           'Test-0670: %8t %d %c works ok');
    is(content($ctr->get_line), q{Time 00:00:00 - Ctr 2},       'Test-0680: first Time displayed correctly');
    # mock-time = Tue Jun 21 14:21:02-29 2011
    $ctr->mock_time(1308658862.291483);
    $ctr->up;
    is(content($ctr->get_line), q{Time 00:00:00 \ Ctr 3},       'Test-0690: second Time displayed, dash has not changed');
    # mock-time = Tue Jun 21 14:21:02-32 2011
    $ctr->mock_time(1308658862.323717);
    $ctr->up;
    is(content($ctr->get_line), q{Time 00:00:00 | Ctr 4},       'Test-0700: third Time displayed, dash has changed');
    # mock-time = Tue Jun 21 14:21:03-29 2011
    $ctr->mock_time(1308658863.2911543);
    $ctr->up;
    is(content($ctr->get_line), q{Time 00:00:01 / Ctr 5},       'Test-0710: fourth Time displayed, Time and dash have changed');
}

{
  my $flatfile = "Test hijabc\010\010\010xyzklmttt\010\010yzz";

  (my $disp_before = $flatfile) =~ s{\010}'<'xmsg;
  is($disp_before, q{Test hijabc<<<xyzklmttt<<yzz},             'Test-0720: before rem_backspace');

  Term::Sk::rem_backspace(\$flatfile);

  (my $disp_after = $flatfile) =~ s{\010}'<'xmsg;
  is($disp_after,  q{Test hijxyzklmtyzz},                       'Test-0730: after rem_backspace');
}

{
    my $ctr = Term::Sk->new('Token1 %6k Token2 %6k Ctr %c', { test => 1, base => 1, token => ['abc', 'def'] } );
    ok(defined($ctr),                                                 'Test-0740: %6k %6k %c works ok');
    is(content($ctr->get_line), q{Token1 abc    Token2 def    Ctr 1}, 'Test-0750: first double Token displayed correctly');
    $ctr->token(['ghi', 'jkl']);
    is(content($ctr->get_line), q{Token1 ghi    Token2 jkl    Ctr 1}, 'Test-0760: second double Token displayed correctly');
}

# Test for version 0.15:
# **********************

{
    # mock-time = Tue Jun 21 14:21:02-28 2011
    my $ctr = Term::Sk->new('T(%5t)', { test => 1, base => 1, mock_tm => 1308658862.287032} );
    ok(defined($ctr),                                                 'Test-0770: %t works ok');
    is(content($ctr->get_line), q{T(00:00)},                          'Test-0780: first time displays "00:00"');
    # mock-time = Tue Jun 21 14:21:26-29 2011
    $ctr->mock_time(1308658885.4382647);
    $ctr->up;
    is(content($ctr->get_line), q{T(00:23)},                          'Test-0790: second time displays "00:23"');
}

# Test for version 0.18:
# **********************

{
    my $ctr = Term::Sk->new('Ctr %c', { test => 1, base => 1 } );
    ok(defined($ctr),                                           'Test-0800: %c works ok');
    ok(do { eval{$ctr->mute_on};  !$@ },                        'Test-0810: mute_on works ok');
    ok(do { eval{$ctr->mute_off}; !$@ },                        'Test-0820: mute_off works ok');
    ok(do { eval{$ctr->mute_zzz}; !!$@ },                       'Test-0830: mute_zzz fails');
}

sub content {
    my ($text) = @_;

    $text =~ s{^ \010+ \s+ \010+}{}xmsg;
    return $text;
}
