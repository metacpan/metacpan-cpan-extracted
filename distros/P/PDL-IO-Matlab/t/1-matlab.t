use strict; use warnings;

use Test::More;

use PDL;
use PDL::IO::Matlab qw ( matlab_read matlab_write );

sub tapprox {
  my($x,$y, $eps) = @_;
  $eps ||= 1e-10;
  my $diff = abs($x-$y)->sum;
  return $diff < $eps;
}

# allows any 1.5.*
my @got_v = PDL::IO::Matlab::get_library_version;
is_deeply [@got_v[0..1]], [1,5], 'library version' or diag explain \@got_v;

# Write one pdl
my $f = 'testf.mat';
my $mat = PDL::IO::Matlab->new($f, '>', {format => 'MAT5'});
ok( $mat != 0 , 'file opened for write');
$mat->write(sequence(10));
$mat->close();

# Read the pdl
$mat = PDL::IO::Matlab->new($f, '<');
ok($mat != 0 , 'file opened for read');
ok($mat->get_version eq 'MAT5', 'file format MAT5');
ok($mat->get_header, 'read header');

my $x = $mat->read_next;
$mat->close();

ok(tapprox($x,sequence(10)), 'read data same as write data');


$mat = PDL::IO::Matlab->new($f, '>', {format => 'MAT5'});

my @types = ( double, float, long, byte, short, ushort  );
map { $mat->write(sequence($_,10)) } @types;

$mat->close;


$mat = PDL::IO::Matlab->new($f, '<');
while(1) {
    my ($err,$x) = $mat->read_next;
    last if $err;
#    last unless ref($x); #  this works as well
    my $type = shift @types;
    ok($x->type == $type, "trying type $type ");
}
$mat->close;

$mat = PDL::IO::Matlab->new($f, '<');
my @pdls = $mat->read_all;
ok( scalar(@pdls) == 6 , 'read_all');

$mat->rewind;
 @pdls = $mat->read_all;
ok( scalar(@pdls) == 6 , 'rewind');
$mat->close;

matlab_write('tst.mat',zeroes(10),ones(5));
($x,my $y) = matlab_read('tst.mat');

ok tapprox($x,zeroes(10)), 'matlab_read matlab_write 1' or diag "got:$x";
ok tapprox($y,ones(5)), 'matlab_read matlab_write 2' or diag "got:$y";

if (PDL::IO::Matlab::_have_hdf5()) {
  matlab_write('tst.mat', 'MAT73', zeroes(10));
  ($x) = matlab_read('tst.mat');
  ok( tapprox($x,zeroes(10)), 'matlab_read matlab_write, MAT73');

  matlab_write('tst.mat', sequence(5));
  $x = matlab_read('tst.mat', {onedr => 0} );
  ok( tapprox($x->shape, pdl [5, 1]), 'onedr => 0');

  matlab_write('tst.mat', sequence(5), {onedw => 2} );
  $x = matlab_read('tst.mat', {onedr => 0} );
  ok( tapprox($x->shape, pdl [1, 5]), 'onedr => 0 , onedw => 2');
} else {
  diag "no HDF5, skipping";
}

done_testing();
