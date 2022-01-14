use Test::More;
use warnings;
use strict;
use Fcntl;
use FindBin qw($Bin);
BEGIN { use_ok('PDL') };
BEGIN { use_ok('PDL::NetCDF') };
BEGIN { use_ok('PDL::Char') };
BEGIN { note( "Removing test file $_\n" ), unlink foreach grep -e, qw/ foo.nc foo1.nc do_not_create.nc / }
END   { note( "Removing test file $_\n" ), unlink foreach grep -e, qw/ bogus.nc foo.nc foo1.nc / }

sub vnorm2 { sumover(shift()**2.)->sqrt } # Euclidean vector norm

#
## Test object-oriented interface
#

# Test whether PDL::NetCDF honours `O_RDONLY' when trying to open a nonexistent file
eval { PDL::NetCDF->new( 'do_not_create.nc', { MODE => O_RDONLY } ) };
like( $@, qr/Cannot open readonly! No such file/, 'PDL::NetCDF should complain when opening nonexistent file when O_RDONLY is in effect' );
ok( ! -f 'do_not_create.nc', 'PDL::NetCDF must not create new file when O_RDONLY is in effect' );

# Test starting with new file
my $obj = PDL::NetCDF->new ('foo.nc');
my $in1 = pdl [[1,2,3], [4,5,6]];
$obj->put ('var1', ['dim1', 'dim2'], $in1);
my $out1 = $obj->get ('var1');

# Test record putting
$obj->put ('recvar1', ['dim2'], double ([1,2,3]));
$obj->put ('recvar2', ['dim2'], long   ([1,2,3]));
$obj->put ('recvart', ['dim2', 'chardim'], PDL::Char->new (['abc', 'def', 'hij']));
my $rec_id = $obj->setrec('recvar1', 'recvar2', 'recvart');
$obj->putrec($rec_id, 1, [9, 8, 'foo']);
my @rec = $obj->getrec($rec_id, 1);
is_deeply \@rec, [9, 8, 'foo'], "setrec/recput/recget OK";

eval { $obj->putrec($rec_id, 9, [9, 8, 'bar']) };
like $@, qr/NetCDF: Index exceeds dimension bound/, "Correctly failed to put record with illegal index";

$obj->put ('recvar3', ['dim2long'], float ([1,2,3,4]));
my $rec_id_bad = eval { $obj->setrec('recvar1', 'recvar2', 'recvar3') };
like $@, qr/All variables in a record must have the same dimension/, "Correctly failed to create record with mis-matched variable sizes";

my $str = "Station1  Station2  Station3  ";
$obj->puttext('textvar', ['n_station', 'n_string'], [3,10], $str);
my $outstr = $obj->gettext('textvar');
ok($str eq $outstr, "puttext 1");

ok ( ($in1 == $out1)->sum == $in1->nelem, "puttext 2");

my $in3 = pdl 1;
$obj->put ('zeroDim', [], $in3);
my $out3 = $obj->get ('zeroDim');
ok($in3 == $out3, "zeroDim");

my $dims  = pdl $in1->dims;
my $dims1 = pdl $out1->dims;
ok( ($dims == $dims1)->sum == $dims->nelem, "puttext 3");

my $in2 = pdl [[1,2,3,4], [5,6,7,8]]; # dim1 is already 3, not 4
eval { $obj->put ('var2', ['dim1', 'dim2'], $in2); }; # Dimension error
like $@, qr/Attempt to redefine length of dimension/, "Dimension redefinition error";

my $pdlchar = PDL::Char->new ([['abc', 'def', 'hij'],['aaa', 'bbb', 'ccc']]);
$obj->put ('varchar', ['dimc1', 'dimc2', 'dimc3'], $pdlchar);
my $charout = $obj->get('varchar');
ok(sum($pdlchar - $charout) == 0, "PDL::Char 1");

my $pdlchar1 = PDL::Char->new ("abcdefghiklm");
$obj->put ('varchar1', ['dimc4'], $pdlchar1);
$charout = $obj->get('varchar1');
ok(sum($pdlchar1 - $charout) == 0, "PDL::Char 2");

# Test compressed put and get
my $tol = 1e-6;
my $pi = 4*atan2(1,1);
my $pdlc = PDL->new ($pi, $pi/2, $pi/4, $pi/8);
$obj->put ('cpi', ['dimnew'], $pdlc, {COMPRESS => 1});
my $pdlout = $obj->get('cpi');
cmp_ok(vnorm2($pdlc - $pdlout), '<', $tol, "Compressed put/get 1");

# try fetching compressed PDL
my $pdlcomp = $obj->get('cpi', {NOCOMPRESS => 1});
my $correct = pdl (2147483646, -306783379, -1533916891, -2147483648);
cmp_ok(vnorm2($pdlcomp - $correct), '<', $tol, "Compressed put/get 2");

ok(!$obj->close, "Compressed put/get 3");

# try a fast open
my $nc1 = PDL::NetCDF->new('foo.nc', {TEMPLATE => $obj});
my $varnames = $nc1->getvariablenames;
ok(grep(/^var1$/,@$varnames) + grep(/^textvar$/,@$varnames), "Fast open 1");
ok(!$nc1->close, "Fast open 2");

# Try rewriting an existing file
my $obj1 = PDL::NetCDF->new ('>foo.nc', {PERL_SCALAR => 1, PDL_BAD => 1});
$varnames = $obj1->getvariablenames;
ok(grep(/^var1$/,@$varnames) + grep(/^textvar$/,@$varnames), "Re-writing 1");

my $dimnames = $obj1->getdimensionnames;
ok (grep(/^dim1$/,@$dimnames) + grep(/^dim2$/,@$dimnames) + grep(/^n_string$/,@$dimnames) + grep(/^n_station$/,@$dimnames), "Re-writing 2");

my $pdl = pdl [[1,2,3], [4,5,6]];
$obj1->put ('var1', ['dim1', 'dim2'], $pdl);
my $pdl1 = $obj1->get ('var1');

ok(($pdl1 == $pdl)->sum == $pdl->nelem, "2D put/get 1");

$dims  = pdl $pdl->dims;
$dims1 = pdl $pdl1->dims;
ok(($dims == $dims1)->sum == $dims->nelem, "2D put/get 2");

my $attin = pdl [1,2,3];
ok(!$obj1->putatt ($attin, 'double_attribute', 'var1'), "Putatt 1");

my $attin2 = long [4,5];
ok(!$obj1->putatt ($attin2, 'long_attribute', 'var1'), "Putatt 2");

my $attin3 = long [4];
ok (!$obj1->putatt ($attin3, 'long_attribute1', 'var1'), "Putatt 3");

my $attout = $obj1->getatt ('long_attribute1', 'var1');
ok ( (!ref($attout) and $attout == 4), "Getatt 1");

$attout = $obj1->getatt ('double_attribute', 'var1');
ok ( ($attin == $attout)->sum == $attin->nelem, "Getatt 2");

ok (!$obj1->putatt ('Text Attribute', 'text_attribute'), "Putatt text");

$attout = $obj1->getatt ('text_attribute');


# test PDL_BAD option

 SKIP: {
   skip "Bad values not enabled", 2 unless ($PDL::Bad::Status == 1);

   $pdl = pdl [[1,2,3], [4,5,-999]];
   $obj1->put ('var2', ['dim1', 'dim2'], $pdl);
   $attin = double([-999]);
   ok (!$obj1->putatt ($attin, '_FillValue', 'var2'), "Badvals 1");
   $pdl1 = $obj1->get ('var2');
   ok ($pdl1->nbad == 1, "Badvals 2");
 };

# Put Slices
#
# First slice needs dimids and values to define variable, subsequent slices do not.
#
my $out2 = $obj1->putslice('var2', ['dim1','dim2','dim3'],[2,3,2],[0,0,0],[2,3,1],$pdl1);

my $pdl2 = pdl [[7,8,9], [10,11,12]];
ok (! $obj1->putslice('var2',[] ,[] ,[0,0,1],[2,3,1],$pdl2), "Putslice 1");

$pdlchar = PDL::Char->new (['a  ','def','ghi']);
ok ( ! $obj1->putslice('tvar', ['recNum','strlen'],[PDL::NetCDF::NC_UNLIMITED(),10],[0,0],[3,3],$pdlchar), "Putslice PDL::Char 1");

$pdlchar = PDL::Char->new (['zzzz']);
ok (! $obj1->putslice('tvar',[],[],[5,0],[1,4],$pdlchar), "Putslice PDL::Char 2");

my $svar = short(27);
ok (! $obj1->putslice('svar', ['recNum'],[PDL::NetCDF::NC_UNLIMITED()],[0],[1],$svar), 
    "Putslice short 1");

$svar = short(13);
ok (! $obj1->putslice('svar', [],[],[8],[1],$svar), "Putslice short 2");

# Get slices
$out2 = $obj1->get ('var1', [1,1], [1,1]);
ok (($out2 == 5), "Get slice 1");

$out2 = $obj1->get ('var1', [0,1], [2,1]);
ok (($out2 == pdl[2,5])->sum == $out2->nelem, "Get slice 2");

$out2 = $obj1->get ('var1', [0,1], [1,1]);
ok ( ($out2 == 2), "Get slice 3");

# Test shuffle and deflate = 0
my ($deflate, $shuffle) = $obj1->getDeflateShuffle('var1');
is($deflate, 0, 'uncompressed variable');
is($shuffle, 0, 'unshuffled variable');


# Test with a bogus file
open (IN, ">bogus.nc");
print IN "I'm not a netCDF file\n";
close IN;
my $obj2;
eval { $obj2 = PDL::NetCDF->new ('bogus.nc'); };
like $@, qr/(Not a netCDF file|Unknown file format)/, "Read bogus file";

$obj = PDL::NetCDF->new ('foo1.nc');
# test chars with unlimited dimension
my $strlen = 5;
my $id = 0;
for ('abc', 'defg', 'hijkl') {
  my $str = PDL::Char->new([substr($_, 0, $strlen)]);
  $obj->putslice('char_unlim', ['unlimd','strlen'], [PDL::NetCDF::NC_UNLIMITED(), $strlen],
		     [$id,0], [1,$str->nelem], $str);
  $id++;
}
$charout = $obj->get('char_unlim');
$pdlchar = PDL::Char->new (['abc', 'defg', 'hijkl']);
print $charout, "\n";
ok (sum($pdlchar - $charout) == 0, "chars with unlimited dimension");

my $charout1 = $obj->get('char_unlim', [0,0], [3, $strlen]);
ok (sum($pdlchar - $charout1) == 0, "Getting a slice of a PDL::Char with unlimited dimension");
my $charout2 = $obj->get('char_unlim', [0,0], [1, $strlen]);
ok (($charout2->dims)[0] == $strlen, "Getting exactly one string from nc with unlimited dimension");

$obj->close;
unlink 'foo1.nc';

$obj = PDL::NetCDF->new ('>foo1.nc');
my $nullPdl = new PDL::Char("");
$obj->put('dimless_var', [],$nullPdl);
ok(${ $obj->getvariablenames }[0] eq 'dimless_var', 'adding dimless char variable');
$obj->put('dimless_var2', [], pdl [3]);
ok(scalar @{ $obj->getvariablenames } == 2, 'adding dimless double variable');
$obj->sync();
ok(1, 'sync working');
$obj->close;

$obj = undef;

$obj = PDL::NetCDF->new('foo.nc');
$obj->close;
$obj = PDL::NetCDF->new('foo.nc');
$obj->getatt("text_attribute");
ok(1, "close is idempotent");

# check reading of string slices
$obj = PDL::NetCDF->new("$Bin/threedimstring.nc", {MODE => O_RDONLY,
			    		           REVERSE_DIMS => 1,
                                                   SLOW_CHAR_FETCH => 1});
my $varname = 'threedimstring';
my $str1 = $obj->get ($varname, [0, 0, 0], [200, 1, 1]);
my $str2 =  $obj->get ($varname, [0, 1, 1], [200, 1, 1]);
ok($str1->string ne $str2->string, "slicing different strings");
my $strX = $obj->get($varname);
my $nsize = 1;
map {$nsize *= $_ } $strX->dims;
ok($nsize == 200*5*4, "reading 3dim strings complete");

done_testing;
