use 5.010;
use warnings;
use Test::More 'no_plan';

my $parser = do{
    use Regexp::Grammars;
    qr{
        <num=(\d++)>
      | <_pat='".*"'> <str=(??{ $MATCH{_pat} })>
      | <bool=(?{'true or false'})>
    }xms
};

my $WARNINGS;
my $lookbehind = do {
    use Regexp::Grammars;
    BEGIN {
        close *Regexp::Grammars::LOGFILE;
        open *Regexp::Grammars::LOGFILE, '>', \$WARNINGS;
    }
    qr{
          <foo=( (?<!bar) (?<=ar) foo )>
    }xms;
};

if ($] < 5.018 || $] >= 5.020) {
    ok !defined $WARNINGS => "No warnings found '$WARNINGS'";
}

ok +('"abc"' =~ $parser) => 'Matched <str>';
is $/{str}, '"abc"'      => 'Captured correctly';

ok +(42 =~ $parser) => 'Matched <num>';
is $/{num}, 42      => 'Captured correctly';

ok +('true' =~ $parser)      => 'Matched <bool>';
is $/{bool}, 'true or false' => 'Pseudo-captured correctly';

ok +('barfoo' !~ $lookbehind)      => 'Neg lookbehind worked';
ok +('foo'    !~ $lookbehind)      => 'Pos lookbehind worked';

ok +('carfoo' =~ $lookbehind)     => 'Both lookbehinds worked';
is $/{foo}, 'foo' => 'Pseudo-captured correctly';
