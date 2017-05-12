use Test::More tests => 84;
no locale;
no utf8;
use_ok('String::CodiceFiscale');

my $obj = String::CodiceFiscale->new();

ok(ref($obj) eq 'String::CodiceFiscale', "Object creation");

$obj->sn('Motta');
cmp_ok($obj->sn_c, 'eq', 'MTT', "Surname coding 1");
$obj->sn('zAnI');
cmp_ok($obj->sn_c, 'eq', 'ZNA', "Surname coding 2");
$obj->sn('Abba');
cmp_ok($obj->sn_c, 'eq', 'BBA', "Surname coding 3");
$obj->sn('Lo`');
cmp_ok($obj->sn_c, 'eq', 'LOX', "Surname coding 4");

$obj->fn('Giulio');
cmp_ok($obj->fn_c, 'eq', 'GLI', "Name coding 1");
$obj->fn('Christian');
cmp_ok($obj->fn_c, 'eq', 'CRS', "Name coding 2");
$obj->fn('Cristian');
cmp_ok($obj->fn_c, 'eq', 'CST', "Name coding 3");
$obj->fn('Ada');
cmp_ok($obj->fn_c, 'eq', 'DAA', "Name coding 4");
$obj->fn('Al');
cmp_ok($obj->fn_c, 'eq', 'LAX', "Name coding 5");

ok($obj->sn_c('MTT'), "Surname setting 1");
ok($obj->sn_c('AXX'), "Surname setting 2");
ok($obj->sn_c('BBA'), "Surname setting 3");
ok($obj->sn_c('XXX'), "Surname setting 4");
ok($obj->sn_c('XEX'), "Surname setting 5");
ok($obj->sn_c('SEX'), "Surname setting 6");
ok(!$obj->sn_c('AEUO'), "Surname setting 7");
ok(!$obj->sn_c('AMI'), "Surname setting 8");
ok(!$obj->sn_c('XO'), "Surname setting 9");

ok($obj->fn_c('GLI'), "Name setting 1");
ok($obj->fn_c('AXX'), "Name setting 2");
ok($obj->fn_c('BBA'), "Name setting 3");
ok($obj->fn_c('XXX'), "Name setting 4");
ok($obj->fn_c('XEX'), "Name setting 5");
ok($obj->fn_c('SEX'), "Name setting 6");
ok(!$obj->fn_c('AEUO'), "Name setting 7");
ok(!$obj->fn_c('AMI'), "Name setting 8");
ok(!$obj->fn_c('XO'), "Name setting 9");

is($obj->year(1977), 1977, "Year 1");
ok(!$obj->year('1999ad'), "Year 2");
is($obj->year_c(77), 77, "Year 3");
is($obj->year, 1977, "Year 4");
ok(!$obj->year_c(1977), "Year 5");

is($obj->month(12), 12, "Month 1");
cmp_ok($obj->month_c, 'eq', 'T' , "Month 2");
ok(!$obj->month(13), "Month 3");
cmp_ok($obj->month_c('S'), 'eq', 'S', "Month 4");
is($obj->month, 11, "Month 5");
ok(!$obj->month('F'), "Month 6");

ok($obj->day(30), "Day/Sex 1");
ok($obj->sex('F'), "Day/Sex 2");
is($obj->day_c, 70, "Day/Sex 3");
ok($obj->sex('M'), "Day/Sex 4");
is($obj->day_c, 30, "Day/Sex 5");
ok(!$obj->day(32), "Day/Sex 6");
ok(!$obj->day_c(32), "Day/Sex 7");
ok($obj->day_c(56), "Day/Sex 8");
is($obj->day, 16, "Day/Sex 9");
cmp_ok($obj->sex, 'eq', 'F', "Day/Sex 10");

ok($obj->bp('G149'), "Birthplace code 1");
cmp_ok($obj->bp, 'eq', 'G149', "Birthplace code 2");
ok($obj->bp_c('E003'), "Birthplace code 3");
cmp_ok($obj->bp, 'eq', 'E003', "Birthplace code 4");
ok(!$obj->bp('G1Z9'), "Birthplace code 5");
ok(!$obj->bp_c('G1498'), "Birthplace code 6");
ok(!$obj->bp('G14V'), "Birthplace code 7");
ok($obj->bp_c('G14V'), "Birthplace code 8");
cmp_ok($obj->bp(), 'eq', 'G149', "Birthplace code 9");

ok($obj->date('1999-02-29'), "Date 1");     #strptime fixes this
ok(!$obj->date('1999-02-32'), "Date 2");    #but not this
ok($obj->date('2004-02-29'), "Date 3");

undef $obj;

$obj = String::CodiceFiscale->parse('MTTGLI77A18G149P');
ok($obj, "Parse 1");
$obj = String::CodiceFiscale->parse('MTTGLI77A18G149R');
ok(!$obj, "Parse 2");
$obj = String::CodiceFiscale->parse('ZNAGPP64R28E884T');
ok($obj, "Parse 3");
cmp_ok($obj->date, 'eq', '1964-10-28', "Parse 3/1");
cmp_ok($obj->sex, 'eq', 'M', "Parse 3/2");
ok(my $pat = $obj->sn_re, "Pattern Creation 1");
ok('Zani' =~ $pat, "Pattern Match 1");
ok($pat = $obj->fn_re, "Pattern Creation 2");
ok('Giuseppe' =~ $pat, "Pattern Match 2");
$obj->fn_c('LRY');
ok($obj->fn_match('Larry'), "Pattern Match 3");

$obj = String::CodiceFiscale->new(
    sn      =>  'Motta',
    fn      =>  'Giulio',
    date    =>  '1977-01-18',
    sex     =>  'M',
    bp      =>  'G149',
);

ok($obj, "New 1");
cmp_ok($obj->cf, 'eq', 'MTTGLI77A18G149P');

ok(String::CodiceFiscale->validate('MTTGLI77A18G149P'), "Validate 1");
ok(!String::CodiceFiscale->validate('MTTGLI77A18G149S'), "Validate 2");
ok(!String::CodiceFiscale->validate('MTTGLI77A18G149PI'), "Validate 3");
ok(String::CodiceFiscale->validate('FFRGPP24A41L03TP'), "Validate 4");
$obj = String::CodiceFiscale->parse('RVSLCU61L27A79QS');
cmp_ok($obj->cf, 'eq', 'RVSLCU61L27A79QS', "Reproduce 1");

$obj = String::CodiceFiscale->new();
$obj->sn_c('LOX');
ok($obj->sn_match("Lo`"), "Surname match 1");
ok($obj->sn_match("Lò"), "Surname match 2");
$obj->fn_c('CRS');
ok($obj->fn_match('Christian'), "Name match 1");
ok(!$obj->fn_match('Cristian'), "Name match 2");
$obj->fn_c('NMR');
ok($obj->fn_match('Anna Maria'), "Name match 3");

