use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

$ENV{PERL5LIB} = join(
  ':', ($ENV{PERL5LIB} ? $ENV{PERL5LIB} : ()), qw(lib t/lib)
);

use Object::Remote;

my $strA = 'foo';
my $strB = 'bar';

is exception {
  my $proxy = ORTestTransfer->new::on('-', value => \$strA);
  is_deeply $proxy->value, \$strA, 'correct value after construction';
}, undef, 'scalar refs - no errors during construction';

is exception {
  my $proxy = ORTestTransfer->new::on('-');
  $proxy->value(\$strB);
  is_deeply $proxy->value, \$strB, 'correct value after construction';
}, undef, 'scalar refs - no errors during attribute set';

my $data_file = "$FindBin::Bin/data/numbers.txt";

is exception {
  my $out = '';
  open my $fh, '>', \$out or die "Unable to open in-memory file: $!\n";
  my $proxy = ORTestGlobs->new::on('-', handle => $fh);
  ok $proxy->handle, 'filehandle was set';
  ok $proxy->write('foo'), 'write was successful';
  is $out, 'foo', 'write reached target';
}, undef, 'filehandles - no error during construction';

is exception {
  my $proxy = ORTestGlobs->new::on('-');
  my $handle = $proxy->gethandle;
  print $handle 'foo';
  is $proxy->getvalue, 'foo', 'correct value written';
  $handle->autoflush(1);
}, undef, 'filehandles - no error during remote handle';

is exception {
  my $proxy = ORTestGlobs->new::on('-');
  my $rhandle = $proxy->getreadhandle($data_file);
  my @lines = <$rhandle>;
  chomp @lines;
  is_deeply \@lines, [1 .. 5], 'reading back out of the handle';
}, undef, 'filehandles - no error during remote read';

is exception {
  my $proxy = ORTestGlobs->new::on('-');
  my $rhandle = $proxy->getreadhandle($data_file);
  binmode $rhandle;
}, undef, 'filehandles - no errors during binmode';

done_testing;
