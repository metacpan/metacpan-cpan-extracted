#!perl
use v5.20;
use warnings;
use experimental 'signatures';
use Test::More;

my @classes = qw(
  String::Obfuscate
  String::Obfuscate::Base64
  String::Obfuscate::Base64::URL
);

do_test($_) for @classes;
done_testing();

#######################################################################

sub do_test ($class) {
  say "Testing $class...";
  require_ok($class);

  foreach my $str (qw(a abcd ABCXYZ 1 123 456789 aeiou! lmnop? AbCdEfG?!)) {
    # Check new() successfully returns object
    my $obj = $class->new();
    is(ref $obj => $class, "new $class object without seed");

    # Get auto seed
    ok($obj->seed, 'new object has seed ' . $obj->seed);
    #ok($obj->seed =~ m/^\d+$/, 'seed is a number');
    ok(ref $obj->seed eq 'ARRAY', 'seed is an arrayref');

    # Obfuscate and deobfuscate a string
    my $obf_str = $obj->obfuscate($str); #say $obf_str;
    ok(length $obf_str, 'obfuscated string has length');
    ok($obf_str ne $str, "obfuscated string is different from the original") if length $str > 1;
    is($obj->deobfuscate($obf_str) => $str, 'obfuscated string can be reversed');
  }

  # Canned seed
  foreach my $seed (123456, $$, time()) {
    my $in   = 'abcdefgABCDEFG12345';
    my $out  = $class->new(seed => $seed)->obfuscate($in);
    my $obj  = $class->new(seed => $seed);

    ok(ref $obj,                         'create object with specified seed');

    # Get seed
    is_deeply($obj->seed              => [$seed], 'seed is equal to given seed');

    # Obfuscate and deobfiscate a string
    ok($obj->obfuscate($in),             'specified seed obfuscate');
    is($obj->obfuscate($in)    => $out,  'specified seed obfuscated string is repeatable');
    is($obj->deobfuscate($out) => $in,   'specified seed obfuscated string is reversed');
  }

  # Passphrase
  {
    my $sob = String::Obfuscate->new(passphrase => "Hello World");
    is_deeply($sob->seed => [11, 1819043144, 1867980911], "Passphrase converted to seed");
  } 

  # XS vs pure-perl
  if ($List::Util::XS::VERSION) {
    my $ver = $List::Util::XS::VERSION;
    my $str = 'aeiou_and_sometimes_y_123456789';

    $List::Util::XS::VERSION = undef;
    my $ob1 = $class->new(seed => 1234567)->obfuscate($str);

    $List::Util::XS::VERSION = $ver;
    my $ob2 = $class->new(seed => 1234567)->obfuscate($str);

    is($ob1 => $ob2, 'XS and pure perl give same output');
  }

  # Custom charset
  unless ($class =~ m/Base64/) {
    my $obj = $class->new(chars => ['a'..'f']);
    ok($obj->obfuscate('zxy123') eq 'zxy123', 'characters not in charset not scrambled');
    ok($obj->obfuscate('abcdef') ne 'abcdef', 'characters in charset are scrambled');

    # Try to break it
    my $pass = 1;
    for my $seed (0..100) {
      my $obj = $class->new(chars => ['\\', 'Q', 'E'], seed => $seed);
      my $str = '\Q\E';
      unless ($obj->deobfuscate($obj->obfuscate($str)) eq $str) {
        $pass = 0;
        last;
      }
    }
    ok($pass, 'try to break quoting');
  }

  # Crazy characters
  unless ($class =~ m/Base64/) {
    my $pass  = 1;
    my @chars = map { chr($_) } 0..255;
    my $str   = join '', @chars; # q{~!@#$%^&*()_+`1234567890-={}|[]\;',./:"<>?]abcdefg123456};
    for my $i (0..1_000) {
      my $obj = $class->new(seed => $i, chars => \@chars);
      my $enc = $obj->obfuscate($str);
      my $dec = $obj->deobfuscate($enc);
      unless ($dec eq $str) {
        $pass = 0;
        last;
      }
    }
    ok($pass, "nonprintable string and charset test");
  }

  # Chaining for one liner
  unless ($class =~ m/Base64/) {
    my $str = $class->new(seed => 0)->obfuscate('Hello, there!');
    ok($str, 'one liner test');
    ok($str =~ m/^\w\w\w\w\w,\s\w\w\w\w\w!$/, 'punctuation not changed in standard mode');
  }
}
