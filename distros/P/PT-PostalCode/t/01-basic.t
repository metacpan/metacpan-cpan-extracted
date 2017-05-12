# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 40;
BEGIN { use_ok('PT::PostalCode') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(code_is_from_area(9700,'Ilha Terceira'));
ok(code_is_from_area(9701,'Ilha Terceira'));
ok(not(code_is_from_area(9702,'Ilha Terceira')));

is(code_is_from_area(),undef);
is(code_is_from_area(9700),undef);
is(code_is_from_area(9700,'Cascos de Rolha'),undef);

ok(code_is_from_subarea(9700,'Angra do Heroísmo'));
is(code_is_from_subarea(),undef);
is(code_is_from_subarea(9700),undef);
is(code_is_from_subarea(9700,'Ilha Terceira'),undef);
is(code_is_from_subarea(9702,'Angra do Heroísmo'),0);

ok(code_is_from(9700,'Angra do Heroísmo','Ilha Terceira'));
ok(not(code_is_from()));
ok(not(code_is_from(9700)));
ok(not(code_is_from(9700,'Angra do Heroísmo')));
ok(not(code_is_from(9700,'Ilha Terceira','Angra do Heroísmo')));

$range = range_from_subarea('Angra do Heroísmo');
@range = @$range;
is($range[0],9700);
is($range[1],9701);

ok(code_is_valid(4900));
ok(not(code_is_valid(9999)));
is(code_is_valid(),undef);

@areas = areas_of_code(4900);
is($areas[0],'Évora');
is($areas[1],'Viana do Castelo');
is($areas[2],'Viseu');
is($areas[3],'Coimbra');
is($areas[4],'Braga');
is($areas[5],'Porto');
is($areas[6],'Guarda');
is($areas[7],undef);

@areas = areas_of_code(9999);
is($areas[0],undef);

@subareas = subareas_of_code(4900);
is($subareas[0],'Vendas Novas');
is($subareas[1],'Viana do Castelo');
is($subareas[2],'Penalva do Castelo');
is($subareas[3],'Arganil');
is($subareas[4],'Barcelos');
is($subareas[5],'Baião');
is($subareas[6],'Trancoso');
is($subareas[7],undef);

@subareas = subareas_of_code(9999);
is($subareas[0],undef);
