use Parse::RecDescent;

my $grammar = q {
    nolcap : <leftop: id /\+|-/   id>
    lcap   : <leftop: id /(\+|-)/ id>

    norcap : <rightop: id /\+|-/   id>
    rcap   : <rightop: id /(\+|-)/ id>

    nolcappos: start <leftop: id /\+|-/   id> end
	        { # force @itempos to be included
              &::make_itempos_text(\@item, \@itempos); }
    lcappos: start <leftop: id /(\+|-)/   id> end
	        { &::make_itempos_text(\@item, \@itempos); }
    norcappos: start <rightop: id /\+|-/   id> end
	        { &::make_itempos_text(\@item, \@itempos); }
    rcappos: start <rightop: id /(\+|-)/   id> end
	        { &::make_itempos_text(\@item, \@itempos); }

    start: /start/i
    end: /end/i

    id : /[a-zA-Z][a-zA-Z_0-9\.]*/
};

my $parser = new Parse::RecDescent($grammar) or die "Bad Grammar";

use Test::More tests=>8;
require './t/util.pl';

my $text = "a + b - c + d";

is_deeply $parser->nolcap($text), [qw<a b c d>]       => 'Noncapturing leftop';
is_deeply $parser->lcap($text),   [qw<a + b - c + d>] => 'Capturing leftop';
is_deeply $parser->norcap($text), [qw<a b c d>]       => 'Noncapturing rightop';
is_deeply $parser->rcap($text),   [qw<a + b - c + d>] => 'Capturing rightop';

my $postext = "START a +
 bb -
ccccccccc +
  d
END";
my $message = '';
my $expected = '
START      offset.from=  0 offset.to=  4 line.from=  1 line.to=  1 column.from=  1 column.to=  5
_REF_      offset.from=  6 offset.to= 30 line.from=  1 line.to=  4 column.from=  7 column.to=  3
END        offset.from= 32 offset.to= 34 line.from=  5 line.to=  5 column.from=  1 column.to=  3
';
is $parser->nolcappos($postext), $expected => "Position capturing leftop$message";
is $parser->lcappos($postext),   $expected => "Position noncapturing leftop$message";
is $parser->norcappos($postext), $expected => "Position capturing rightop$message";
is $parser->rcappos($postext),   $expected => "Position noncapturing rightop$message";
