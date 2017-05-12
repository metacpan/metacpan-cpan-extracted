# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 36 };
use Petrophysics::Units;
ok(1); # If we made it this far, we're ok.

#########################

require UNIVERSAL;

my $ft = Petrophysics::Units->lookup ('ft');
ok (defined $ft);

my $m = Petrophysics::Units->lookup_annotation ('m');
ok (defined $m);

ok ($m->is_compatible ($m));
ok ($ft->is_compatible ($m));
ok ($m->is_compatible ($ft));

my $speed = Petrophysics::Units->lookup_annotation ('m/s');
ok (defined $speed);
ok (!$m->is_compatible ($speed));

ok ($m->name eq 'metre');
ok ($m->annotation eq 'm');
ok ($m->quantity_type eq 'length');
ok ($m->catalog_name eq 'EPSG abbreviation');
ok ($m->catalog_symbol eq 'm');
ok (!defined $m->display);
ok ($m->is_base_unit);

ok ($ft->name eq 'foot');
ok ($ft->annotation eq 'ft');
ok ($ft->quantity_type eq 'length');
ok ($ft->catalog_name eq 'EPSG abbreviation');
ok ($ft->catalog_symbol eq 'ft');
ok (!defined $m->display);
ok (!$ft->is_base_unit);
ok ($ft->A == 0);
ok ($ft->B == 0.3048);
ok ($ft->C == 1);
ok ($ft->D == 0);

my $val = 1234.567;
ok (abs ($ft->scalar_convert ($m, 1) - 0.3048) < 0.000001);
ok (abs ($ft->scalar_convert ($m, $m->scalar_convert ($ft, $val)) - $val) < 0.00001);

my $data = [ 1, 2, 3, 4 ];
my $mdata = [ 0.3048, 0.6096, 0.9144, 1.2192 ];
my $mdata2 = $ft->vector_convert ($m, $data);
for (my $i = 0; $i < scalar @$data; $i++) {
  ok (abs ($mdata2->[$i] - $mdata->[$i]) < 0.000001);
}

my $degC = Petrophysics::Units->lookup ('degC');
ok (defined $degC);
my $degF = Petrophysics::Units->lookup ('degF');
ok (defined $degF);
$val = 36.9;
ok (abs ($degF->scalar_convert ($degC, $degC->scalar_convert ($degF, $val)) - $val) < 0.00001);

ok (!defined $degF->scalar_convert ($ft, 15));
