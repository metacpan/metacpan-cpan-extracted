#!perl
use utf8;

use lib qw(../lib/);

use Test::More;

my $class = 'Taxon::Parse';

use_ok($class);

can_ok($class,
  qw/
    new
    init
    pattern
    patterns
    match
    pick
    check
  /); 

my $object = new_ok($class);

my $p = $object->{pattern_parts};

$p->{NAME_LETTERS} = qr/[A-ZÏËÖÜÄÉÈČÁÀÆŒ]/xms;
$p->{name_letters} = qr/[a-zïëöüäåéèčáàæœſú]/xms;
   $p->{word}     = qr/
    \b
    [\p{Latin}]+
    \b
  /xms;
  $p->{compound} = qr/
    $p->{word}
    [-]
    $p->{word}
  /xms;
  $p->{group}    = qr/
    \b
    $p->{NAME_LETTERS}
    $p->{name_letters}+
    \b
  /xms;
  $p->{namecaptured}     = qr/
    (?<group> $p->{group} )
      (?:
        \s+
        (?<compound> $p->{compound} )
      )?
  /xms;
  my $patterns = $object->{patterns};
  my @patterns = qw< word group compound namecaptured>;
  map { $patterns->{$_} = $p->{$_} } @patterns;
  $object->{order}->{namecaptured} = [qw< group compound >];  



ok($object->patterns(),'patterns');

ok($object->pattern('group'),'pattern(epithet)');

### epithet
ok($object->match('word','mann'), 'match word mann');
ok($object->match('group','Mann'), 'match group Mann');
ok($object->match('compound','Mann-Frau'), 'match compound Mann-Frau');


ok($object->check('word','mann'), 'check word mann');
ok($object->check('group','Mann'), 'check group Mann');
ok($object->check('compound','Mann-Frau'), 'check compound Mann-Frau');

ok($object->order('namecaptured'), 'order namecaptured');

ok($object->check_parts('word','mann'), 'check_parts word mann');
ok($object->check_parts('group','Mann'), 'check_parts group Mann');
ok($object->check_parts('compound','Mann-Frau'), 'check_parts compound Mann-Frau');

ok($object->pick('word','mann'), 'pick word mann');
ok($object->pick('group','Mann'), 'pick group Mann');
ok($object->pick('compound','Mann-Frau'), 'pick compound Mann-Frau');

ok($object->ast('namecaptured','Familie Mann-Frau'), 'ast Familie Mann-Frau');




done_testing();
