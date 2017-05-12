###############

use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::Regexp qw(:split);
$loaded = 1;
print "ok 1\n";

###############

my %table = (
 'Å@', ' ', 'Å^', '/', qw/
 ÇO 0 ÇP 1 ÇQ 2 ÇR 3 ÇS 4 ÇT 5 ÇU 6 ÇV 7 ÇW 8 ÇX 9
 Ç` A Ça B Çb C Çc D Çd E Çe F Çf G Çg H Çh I Çi J Çj K Çk L Çl M
 Çm N Çn O Ço P Çp Q Çq R Çr S Çs T Çt U Çu V Çv W Çw X Çx Y Çy Z
 ÇÅ a ÇÇ b ÇÉ c ÇÑ d ÇÖ e ÇÜ f Çá g Çà h Çâ i Çä j Çã k Çå l Çç m
 Çé n Çè o Çê p Çë q Çí r Çì s Çî t Çï u Çñ v Çó w Çò x Çô y Çö z
 ÅÅ = Å{ + Å| - ÅH ? ÅI ! Åî /, '#', qw/ Åê $ Åì % Åï & Åó @ Åñ *
 ÅÉ < ÅÑ > Åi ( Åj ) Åm [ Ån ] Åo { Åp } /,
);

my $char = '(?:[\x00-\x7F\xA1-\xDF]|[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC])';

sub printZ2H {
  my $str = shift;
  $str =~ s/($char)/exists $table{$1} ? $table{$1} : $1/geo;
  $str;
}

sub listtostr {
  my @a = @_;
  return @a ? join('', map "<$_>", @a) : '';
}

{
  my $str = '  This  is   a  TEST =@ ';
  my $zen = 'Å@ TÇàiÇìÅ@ isÅ@ Å@a  ÇsÇdSTÅ@ÅÅ@ ';

  my($n, $NG);

# splitchar in scalar context
  $NG = 0;
  for $n (-1..20){
    my $core  = @{[ split(//, $str, $n) ]};
    my $jspl  = jsplit('',$zen,$n);
    my $spch  = splitchar($zen,$n);

    ++$NG unless $core == $jspl && $core == $spch;
  }
  print !$NG ? "ok" : "not ok", " 2\n";

# splitchar in list context
  $NG = 0;
  for $n (-1..20){
    my $core = join ':', split //, $str, $n;
    my $jspl = join ':', jsplit('',$zen,$n);
    my $spch = join ':', splitchar($zen,$n);
    ++$NG unless $core eq printZ2H($jspl) && $core eq printZ2H($spch);
  }
  print !$NG ? "ok" : "not ok", " 3\n";

# splitspace in scalar context
  $NG = 0;
  for $n (-1..5){
    my $core = @{[ split ' ', $str, $n ]};
    my $jspl = jsplit(undef,$zen,$n);
    my $spsp = splitspace($zen,$n);
    ++$NG unless $core eq printZ2H($jspl) && $core eq printZ2H($spsp);
  }
  print !$NG ? "ok" : "not ok", " 4\n";

# splitspace in list context
  $NG = 0;
  for $n (-1..5) {
    my $core = join ':', split(' ', $str, $n);
    my $jspl = join ':', jsplit(undef,$zen,$n);
    my $spsp = join ':', splitspace($zen,$n);
    ++$NG unless $core eq printZ2H($jspl) && $core eq printZ2H($spsp);
  }
  print !$NG ? "ok" : "not ok", " 5\n";

# split / / in list context
  $NG = 0;
  for $n (-1..5) {
    my $core = join ':', split(/ /, $str, $n);
    my $jspl = join ':', jsplit(' ',$str,$n);
    ++$NG unless $core eq $jspl;
  }
  print !$NG ? "ok" : "not ok", " 6\n";

# split /\\s+/ in list context
  $NG = 0;
  for $n (-1..5) {
    my $core = join ':', split(/\s+/, $str, $n);
    my $jspl = join ':', jsplit('\p{IsSpace}+',$zen,$n);
    ++$NG unless $core eq printZ2H($jspl);
  }
  print !$NG ? "ok" : "not ok", " 7\n";

# split /\s*,\s*/ in list context
  $NG = 0;
  for $n (-1..5) {
    my $core = join ":", split /\s*,\s*/, " , abc, efg , hij, , , ", $n;
    my $jspl = join ":", jsplit('\s*,\s*', " , abc, efg , hij, , , ", $n);
    ++$NG unless $core eq $jspl;
  }
  print !$NG ? "ok" : "not ok", " 8\n";
}

print join('Å[', jsplit ['Ç†', 'j'], '01234Ç†Ç¢Ç§Ç¶Ç®ÉAÉCÉEÉGÉI')
	eq '01234Å[Ç¢Ç§Ç¶Ç®Å[ÉCÉEÉGÉI'
   && join('Å[', jsplit ['(Ç†)', 'j'], '01234Ç†Ç¢Ç§Ç¶Ç®ÉAÉCÉEÉGÉI')
	eq '01234Å[Ç†Å[Ç¢Ç§Ç¶Ç®Å[ÉAÅ[ÉCÉEÉGÉI'
 ? "ok" : "not ok", " 9\n";


{ # split of empty string
  my($NG, $n);

# splitchar in scalar context
  $NG = 0;
  for $n (-1..20) {
    my $core = @{[ split(//, '', $n) ]};
    my $jspl = jsplit('','',$n);
    my $spch = splitchar('',$n);
    ++$NG unless $core == $jspl && $core == $spch;
  }
  print !$NG ? "ok" : "not ok", " 10\n";

# splitchar in list context
  $NG = 0;
  for $n (-1..20) {
    my $core = listtostr( split //, '', $n);
    my $jspl = listtostr( jsplit('','',$n));
    my $spch = listtostr( splitchar('',$n));
    ++$NG unless $core eq $jspl && $core eq $spch;
  }
  print !$NG ? "ok" : "not ok", " 11\n";

# split(/ /, '') in list context
  $NG = 0;
  for $n (-1..5) {
    my $core = listtostr( split(/ /, '', $n) );
    my $jspl = listtostr( jsplit(' ', '', $n) );
    ++$NG unless $core eq $jspl;
  }
  print !$NG ? "ok" : "not ok", " 12\n";

# splitspace('') in list context
  $NG = 0;
  for $n (-1..5) {
    my $core = listtostr( split(' ', '', $n) );
    my $jspl = listtostr( jsplit(undef, '', $n) );
    my $spsp = listtostr( splitspace('', $n) );
    ++$NG unless $core eq $jspl && $core eq $spsp;
  }
  print !$NG ? "ok" : "not ok", " 13\n";
}

print 'This/is/perl.' eq join('/', jsplit(undef, ' Å@ This  is Å@ perl.'))
    ? "ok" : "not ok", " 14\n";
print 'This/is/perl.' eq join('/', splitspace(' Å@ This  is Å@ perl.'))
    ? "ok" : "not ok", " 15\n";
print 'perl/-wc/mine.pl' eq join('/', splitspace('Å@perlÅ@-wcÅ@Å@mine.plÅ@'))
    ? "ok" : "not ok", " 16\n";
print 'This/is/perl.' eq join('/', jsplit(undef,
	" \x81\x40 This  is \x81\x40 perl."))
    ? "ok" : "not ok", " 17\n";
print 'This/is/perl.' eq join('/',
	splitspace(" \x81\x40 This  is \x81\x40 perl."))
    ? "ok" : "not ok", " 18\n";


