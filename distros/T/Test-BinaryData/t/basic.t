#!perl -T
use strict;
use warnings;

use Test::Tester 0.107;
use Test::More tests => 69;
use Test::BinaryData;

use Encode ();

local $ENV{COLUMNS} = 80; # for the sake of sane defaults

check_test(
  sub { is_binary('abc','abc'); },
  {
    ok   => 1,
    name => '',
    diag => '',
  },
  "successful comparison"
);

my $comparison = <<'END_COMPARISON';
have (hex)               have           want (hex)               want        
6162630a---------------- abc.         ! 6162630d0a-------------- abc..       
END_COMPARISON

check_test(
  sub { is_binary("abc\n", "abc\x0d\x0a"); },
  {
    ok   => 0,
    name => '',
    diag => $comparison,
  },
  "short, failed comparison"
);

check_test(
  sub { is_binary("abc\n", "abc\x0d\x0a", '\n vs crlf'); },
  {
    ok   => 0,
    name => '\n vs crlf',
    diag => $comparison,
  },
  "short, failed comparison"
);

my $original = do { local $/; <DATA> };
(my $crlfed = $original) =~ s/\n/\x0d\x0a/g;

my $long_comparison = <<'END_COMPARISON';
have (hex)               have           want (hex)               want        
46726f6d206d61696c2d6d69 From mail-mi = 46726f6d206d61696c2d6d69 From mail-mi
6e65722d3130353239406c6f ner-10529@lo = 6e65722d3130353239406c6f ner-10529@lo
63616c686f73742057656420 calhost Wed  = 63616c686f73742057656420 calhost Wed 
4465632031382031323a3037 Dec 18 12:07 = 4465632031382031323a3037 Dec 18 12:07
3a353520323030320a526563 :55 2002.Rec ! 3a353520323030320d0a5265 :55 2002..Re
65697665643a2066726f6d20 eived: from  ! 6365697665643a2066726f6d ceived: from
6d61696c6d616e2e6f70656e mailman.open ! 206d61696c6d616e2e6f7065  mailman.ope
67726f75702e6f726720285b group.org ([ ! 6e67726f75702e6f72672028 ngroup.org (
3139322e3135332e3136362e 192.153.166. ! 5b3139322e3135332e313636 [192.153.166
395d290a0962792064656570 9])..by deep ! 2e395d290d0a096279206465 .9])...by de
2d6461726b2d747275746866 -dark-truthf ! 65702d6461726b2d74727574 ep-dark-trut
756c2d6d6972726f722e7061 ul-mirror.pa ! 6866756c2d6d6972726f722e hful-mirror.
64207769746820736d747020 d with smtp  ! 706164207769746820736d74 pad with smt
284578696d20332e33362023 (Exim 3.36 # ! 7020284578696d20332e3336 p (Exim 3.36
31202844656269616e29290a 1 (Debian)). ! 202331202844656269616e29  #1 (Debian)
096964203138427568352d30 .id 18Buh5-0 ! 290d0a096964203138427568 )...id 18Buh
3030365a722d30300a09666f 006Zr-00..fo ! 352d303030365a722d30300d 5-0006Zr-00.
72203c706f7369784073696d r <posix@sim ! 0a09666f72203c706f736978 ..for <posix
6f6e2d636f7a656e732e6f72 on-cozens.or ! 4073696d6f6e2d636f7a656e @simon-cozen
673e3b205765642c20313320 g>; Wed, 13  ! 732e6f72673e3b205765642c s.org>; Wed,
4e6f7620323030322031303a Nov 2002 10: ! 203133204e6f762032303032  13 Nov 2002
32343a3233202b303030300a 24:23 +0000. ! 2031303a32343a3233202b30  10:24:23 +0
52656365697665643a202871 Received: (q ! 3030300d0a52656365697665 000..Receive
6d61696c203136373920696e mail 1679 in ! 643a2028716d61696c203136 d: (qmail 16
766f6b656420627920756964 voked by uid ! 373920696e766f6b65642062 79 invoked b
20353033293b203133204e6f  503); 13 No ! 792075696420353033293b20 y uid 503); 
7620323030322031303a3130 v 2002 10:10 ! 3133204e6f76203230303220 13 Nov 2002 
3a3439202d303030300a5265 :49 -0000.Re ! 31303a31303a3439202d3030 10:10:49 -00
73656e742d446174653a2031 sent-Date: 1 ! 30300d0a526573656e742d44 00..Resent-D
33204e6f7620323030322031 3 Nov 2002 1 ! 6174653a203133204e6f7620 ate: 13 Nov 
303a31303a3439202d303030 0:10:49 -000 ! 323030322031303a31303a34 2002 10:10:4
300a-------------------- 0.           ! 39202d303030300d0a------ 9 -0000..   
END_COMPARISON

check_test(
  sub { is_binary($original, $crlfed); },
  {
    ok   => 0,
    name => '',
    diag => $long_comparison,
  },
  "long, failed comparison"
);

check_test(
  sub { is_binary($original, $crlfed, '\n vs crlf'); },
  {
    ok   => 0,
    name => '\n vs crlf',
    diag => $long_comparison,
  },
  "long, failed comparison"
);

my $max_diff_comparison = << 'END_COMPARISON';
have (hex)               have           want (hex)               want        
46726f6d206d61696c2d6d69 From mail-mi = 46726f6d206d61696c2d6d69 From mail-mi
6e65722d3130353239406c6f ner-10529@lo = 6e65722d3130353239406c6f ner-10529@lo
63616c686f73742057656420 calhost Wed  = 63616c686f73742057656420 calhost Wed 
4465632031382031323a3037 Dec 18 12:07 = 4465632031382031323a3037 Dec 18 12:07
3a353520323030320a526563 :55 2002.Rec ! 3a353520323030320d0a5265 :55 2002..Re
...
END_COMPARISON

check_test(
  sub { is_binary($original, $crlfed, '\n vs crlf, max 1', {max_diffs => 1}); },
  {
    ok   => 0,
    name => '\n vs crlf, max 1',
    diag => $max_diff_comparison,
  },
  "long comparison, max_diffs 1"
);

my $max_diff_comparison_2 = << 'END_COMPARISON';
have (hex)               have           want (hex)               want        
46726f6d206d61696c2d6d69 From mail-mi = 46726f6d206d61696c2d6d69 From mail-mi
6e65722d3130353239406c6f ner-10529@lo = 6e65722d3130353239406c6f ner-10529@lo
63616c686f73742057656420 calhost Wed  = 63616c686f73742057656420 calhost Wed 
4465632031382031323a3037 Dec 18 12:07 = 4465632031382031323a3037 Dec 18 12:07
3a353520323030320a526563 :55 2002.Rec ! 3a353520323030320d0a5265 :55 2002..Re
65697665643a2066726f6d20 eived: from  ! 6365697665643a2066726f6d ceived: from
...
END_COMPARISON

check_test(
  sub { is_binary($original, $crlfed, '\n vs crlf, max 2', {max_diffs => 2}); },
  {
    ok   => 0,
    name => '\n vs crlf, max 2',
    diag => $max_diff_comparison_2,
  },
  "long comparison, max_diffs 2"
);

my $utf_comparison = <<'END_COMPARISON';
have (hex)               have           want (hex)               want        
e188b4------------------ ...          ! e188b5------------------ ...         
END_COMPARISON

check_test(
  sub {
    is_binary(
      Encode::encode('utf-8', "\x{1234}"),
      Encode::encode('utf-8', "\x{1235}"),
      'compare two utf-8 encoded unicode glyphs'
    )
  },
  {
    ok   => 0,
    name => 'compare two utf-8 encoded unicode glyphs',
    diag => $utf_comparison,
  },
  "utf compare"
);

my $wide_diag = <<'END_COMPARISON';
value for 'have' contains wide bytes
value for 'want' contains wide bytes
END_COMPARISON

check_test(
  sub { is_binary("\x{1234}", "\x{1235}", 'two unencoded unicode glyphs') },
  {
    ok   => 0,
    name => 'two unencoded unicode glyphs',
    diag => $wide_diag,
  },
  "wide character string compare"
);

check_test(
  sub {
    is_binary(
      "Queensrÿche",
      [ qw( 5175 6565 6e73 72c3 bf63 6865 ) ],
      'encoded y-umlaut'
    )
  },
  {
    ok   => 1,
    name => 'encoded y-umlaut',
  },
  "compare encoded octets; want is arrayref"
);

__DATA__
From mail-miner-10529@localhost Wed Dec 18 12:07:55 2002
Received: from mailman.opengroup.org ([192.153.166.9])
	by deep-dark-truthful-mirror.pad with smtp (Exim 3.36 #1 (Debian))
	id 18Buh5-0006Zr-00
	for <posix@simon-cozens.org>; Wed, 13 Nov 2002 10:24:23 +0000
Received: (qmail 1679 invoked by uid 503); 13 Nov 2002 10:10:49 -0000
Resent-Date: 13 Nov 2002 10:10:49 -0000
