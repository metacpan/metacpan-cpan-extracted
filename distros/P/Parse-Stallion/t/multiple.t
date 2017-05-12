#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
use Test::More tests => 84;
BEGIN { use_ok('Parse::Stallion') };

my $result;

my %y_rules = (
 start_expression => M(qr/y/),
);

my $y_parser = new Parse::Stallion(
  \%y_rules,
  {start_rule => 'start_expression',
});


$result = $y_parser->parse_and_evaluate('');
is (defined $result,1, 'empty y');

$result = $y_parser->parse_and_evaluate('y');
is (defined $result,1, 'single y');

$result = $y_parser->parse_and_evaluate('yy');
is (defined $result,1, 'double y');

$result = $y_parser->parse_and_evaluate('yyy');
is (defined $result,1, 'triple y');

$result = $y_parser->parse_and_evaluate('yyyy');
is (defined $result,1, 'quadruple y');



my %x_rules = (
 start_expression => M(qr/x/,0,1),
);

my $x_parser = new Parse::Stallion(
  \%x_rules,
  {
  start_rule => 'start_expression',
});

$result = $x_parser->parse_and_evaluate('');
is (defined $result,1, 'empty x');

$result = $x_parser->parse_and_evaluate('x');
is (defined $result,1, 'single x');

$result = $x_parser->parse_and_evaluate('xx');
is (defined $result,'', 'double x');

$result = $x_parser->parse_and_evaluate('xxx');
is (defined $result,'', 'triple x');

$result = $x_parser->parse_and_evaluate('xxxx');
is (defined $result,'', 'quadruple x');


my %w_rules = (
 start_expression => M(qr/w/,1,1),
);

my $w_parser = new Parse::Stallion(
  \%w_rules,
  {
  start_rule => 'start_expression',
});

$result = $w_parser->parse_and_evaluate('');
is (defined $result,'', 'empty w');

$result = $w_parser->parse_and_evaluate('w');
is (defined $result,1, 'single w');

$result = $w_parser->parse_and_evaluate('ww');
is (defined $result,'', 'double w');

$result = $w_parser->parse_and_evaluate('www');
is (defined $result,'', 'triple w');

$result = $w_parser->parse_and_evaluate('wwww');
is (defined $result,'', 'quadruple w');


my %v_rules = (
 start_expression => M(qr/v/,2,3),
);

my $v_parser = new Parse::Stallion(
  \%v_rules,
  {
  start_rule => 'start_expression',
});

$result = $v_parser->parse_and_evaluate('');
is (defined $result,'', 'empty v');

$result = $v_parser->parse_and_evaluate('v');
is (defined $result,'', 'single v');

$result = $v_parser->parse_and_evaluate('vv');
is (defined $result,1, 'double v');

$result = $v_parser->parse_and_evaluate('vvv');
is (defined $result,1, 'triple v');

$result = $v_parser->parse_and_evaluate('vvvv');
is (defined $result,'', 'quadruple v');


my %u_rules = (
 start_expression => M(qr/u/,3,0),
);

my $u_parser = new Parse::Stallion(
  \%u_rules,
  {start_rule => 'start_expression',
});

$result = $u_parser->parse_and_evaluate('');
is (defined $result,'', 'empty u');

$result = $u_parser->parse_and_evaluate('u');
is (defined $result,'', 'single u');

$result = $u_parser->parse_and_evaluate('uu');
is (defined $result,'', 'double u');

$result = $u_parser->parse_and_evaluate('uuu');
is (defined $result,1, 'triple u');

$result = $u_parser->parse_and_evaluate('uuuu');
is (defined $result,1, 'quadruple u');


my %t_rules = (
 start_expression => Z(qr/t/),
);

my $t_parser = new Parse::Stallion(
  \%t_rules,
  {start_rule => 'start_expression',
});

$result = $t_parser->parse_and_evaluate('');
is (defined $result,1, 'empty t');

$result = $t_parser->parse_and_evaluate('t');
is (defined $result,1, 'single t');

$result = $t_parser->parse_and_evaluate('tt');
is (defined $result,'', 'double t');

$result = $t_parser->parse_and_evaluate('ttt');
is (defined $result,'', 'triple t');

$result = $t_parser->parse_and_evaluate('tttt');
is (defined $result,'', 'quadruple t');


my %s_rules = (
 start_expression => M(qr/s/,0,2),
);

my $s_parser = new Parse::Stallion(
  \%s_rules,
  {start_rule => 'start_expression',
});

$result = $s_parser->parse_and_evaluate('');
is (defined $result,1, 'empty s');

$result = $s_parser->parse_and_evaluate('s');
is (defined $result,1, 'single s');

$result = $s_parser->parse_and_evaluate('ss');
is (defined $result,1, 'double s');

$result = $s_parser->parse_and_evaluate('sss');
is (defined $result,'', 'triple s');

$result = $s_parser->parse_and_evaluate('ssss');
is (defined $result,'', 'quadruple s');



my %r_rules = (
 start_expression => M(qr/r/,1,0),
);

my $r_parser = new Parse::Stallion(
  \%r_rules,
  {start_rule => 'start_expression',
});

$result = $r_parser->parse_and_evaluate('');
is (defined $result,'', 'empty r');

$result = $r_parser->parse_and_evaluate('r');
is (defined $result,1, 'single r');

$result = $r_parser->parse_and_evaluate('rr');
is (defined $result,1, 'double r');

$result = $r_parser->parse_and_evaluate('rrr');
is (defined $result,1, 'triple r');

$result = $r_parser->parse_and_evaluate('rrrr');
is (defined $result,1, 'quadruple r');



my %b_rules = (
 start_expression => M(qr/b/,MATCH_MIN_FIRST()),
);

my $b_parser = new Parse::Stallion(
  \%b_rules,
  {start_rule => 'start_expression',
});


$result = $b_parser->parse_and_evaluate('');
is (defined $result,1, 'empty b');


$result = $b_parser->parse_and_evaluate('b');
is (defined $result,1, 'single b');

$result = $b_parser->parse_and_evaluate('bb');
is (defined $result,1, 'double b');

$result = $b_parser->parse_and_evaluate('bbb');
is (defined $result,1, 'triple b');

$result = $b_parser->parse_and_evaluate('bbbb');
is (defined $result,1, 'quadruple b');



my %c_rules = (
 start_expression => M(qr/c/,0,1,MATCH_MIN_FIRST),
);

my $c_parser = new Parse::Stallion(
  \%c_rules,
  {start_rule => 'start_expression',
});

$result = $c_parser->parse_and_evaluate('');
is (defined $result,1, 'empty c');

$result = $c_parser->parse_and_evaluate('c');
is (defined $result,1, 'single c');

$result = $c_parser->parse_and_evaluate('cc');
is (defined $result,'', 'double c');

$result = $c_parser->parse_and_evaluate('ccc');
is (defined $result,'', 'triple c');

$result = $c_parser->parse_and_evaluate('cccc');
is (defined $result,'', 'quadruple c');


my %d_rules = (
 start_expression => M(qr/d/,1,1,MATCH_MIN_FIRST()),
);

my $d_parser = new Parse::Stallion(
  \%d_rules,
  {start_rule => 'start_expression',
});

$result = $d_parser->parse_and_evaluate('');
is (defined $result,'', 'empty d');

$result = $d_parser->parse_and_evaluate('d');
is (defined $result,1, 'single d');

$result = $d_parser->parse_and_evaluate('dd');
is (defined $result,'', 'double d');

$result = $d_parser->parse_and_evaluate('ddd');
is (defined $result,'', 'triple d');

$result = $d_parser->parse_and_evaluate('dddd');
is (defined $result,'', 'quadruple d');


my %e_rules = (
 start_expression => M(qr/e/,2,3,MATCH_MIN_FIRST()),
);

my $e_parser = new Parse::Stallion(
  \%e_rules,
  {start_rule => 'start_expression',
});

$result = $e_parser->parse_and_evaluate('');
is (defined $result,'', 'empty e');

$result = $e_parser->parse_and_evaluate('e');
is (defined $result,'', 'single e');

$result = $e_parser->parse_and_evaluate('ee');
is (defined $result,1, 'double e');

$result = $e_parser->parse_and_evaluate('eee');
is (defined $result,1, 'triple e');

$result = $e_parser->parse_and_evaluate('eeee');
is (defined $result,'', 'quadruple e');


my %f_rules = (
 start_expression => M(qr/f/,3,0,MATCH_MIN_FIRST()),
);

my $f_parser = new Parse::Stallion(
  \%f_rules,
  {start_rule => 'start_expression',
});

$result = $f_parser->parse_and_evaluate('');
is (defined $result,'', 'empty f');

$result = $f_parser->parse_and_evaluate('f');
is (defined $result,'', 'single f');

$result = $f_parser->parse_and_evaluate('ff');
is (defined $result,'', 'double f');

$result = $f_parser->parse_and_evaluate('fff');
is (defined $result,1, 'triple f');

$result = $f_parser->parse_and_evaluate('ffff');
is (defined $result,1, 'quadruple f');



my %h_rules = (
 start_expression => M(qr/h/,0,2,MATCH_MIN_FIRST()),
);

my $h_parser = new Parse::Stallion(
  \%h_rules,
  {start_rule => 'start_expression',
});

$result = $h_parser->parse_and_evaluate('');
is (defined $result,1, 'empty h');

$result = $h_parser->parse_and_evaluate('h');
is (defined $result,1, 'single h');

$result = $h_parser->parse_and_evaluate('hh');
is (defined $result,1, 'double h');

$result = $h_parser->parse_and_evaluate('hhh');
is (defined $result,'', 'triple h');

$result = $h_parser->parse_and_evaluate('hhhh');
is (defined $result,'', 'quadruple h');



my %i_rules = (
 start_expression => M(qr/i/,1,0,MATCH_MIN_FIRST()),
);

my $i_parser = new Parse::Stallion(
  \%i_rules,
  {start_rule => 'start_expression',
});

$result = $i_parser->parse_and_evaluate('');
is (defined $result,'', 'empty i');

$result = $i_parser->parse_and_evaluate('i');
is (defined $result,1, 'single i');

$result = $i_parser->parse_and_evaluate('ii');
is (defined $result,1, 'double i');

$result = $i_parser->parse_and_evaluate('iii');
is (defined $result,1, 'triple i');

$result = $i_parser->parse_and_evaluate('iiii');
is (defined $result,1, 'quadruple i');

my %mmf_rules = (
 start_expression => A(M(qr/i/,1,0,MATCH_MIN_FIRST()),{rest=>qr/.*/},
  E(sub {return $_[0]->{rest}}))
);

my $mmf_parser = new Parse::Stallion(
  \%mmf_rules
);

$result = $mmf_parser->parse_and_evaluate('');
is ($result,undef, 'mmf 1');

$result = $mmf_parser->parse_and_evaluate('i');
is ($result,'', 'mmf 2');

$result = $mmf_parser->parse_and_evaluate('ii');
is ($result,'i', 'mmf 3');

$result = $mmf_parser->parse_and_evaluate('iiij');
is ($result,'iij', 'mmf 4');

my %nmmf_rules = (
 start_expression => A(M(qr/i/,1,0),{rest=>qr/.*/},
  E(sub {return $_[0]->{rest}}))
);

my $nmmf_parser = new Parse::Stallion(
  \%nmmf_rules
);

$result = $nmmf_parser->parse_and_evaluate('');
is ($result,undef, 'nmmf 1');

$result = $nmmf_parser->parse_and_evaluate('i');
is ($result,'', 'nmmf 2');

$result = $nmmf_parser->parse_and_evaluate('ii');
is ($result,'', 'nmmf 3');

$result = $nmmf_parser->parse_and_evaluate('iiij');
is ($result,'j', 'nmmf 4');


print "\nAll done\n";


