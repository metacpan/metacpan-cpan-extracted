use strict;
use warnings;
use Test::More;
use Module::CoreList::DBSchema;

my %tests = (
  corelist => [ 'select cl_perls.perl_ver, mod_vers, released, deprecated from cl_versions,cl_perls where cl_perls.perl_ver = cl_versions.perl_ver and mod_name = ? order by cl_versions.perl_ver', 1 ],
);

plan tests => ( scalar keys %tests ) * 4 + 1;

my $mcdbs = Module::CoreList::DBSchema->new();

my @origs = sort keys %tests;
my @types = sort $mcdbs->queries();

is_deeply( \@origs, \@types, 'We got the right types back' );

foreach my $test ( sort keys %tests ) {
  my ($tsql,$tflag) = @{ $tests{$test} };
  my ($sql,$flag) = $mcdbs->query($test);
  my $aref = $mcdbs->query($test);
  is( $sql, $tsql, "The SQL was okay for '$test'" );
  is( $flag, $tflag, "The flag was okay for '$test'");
  is( $aref->[0], $tsql, "The SQL was okay for '$test'" );
  is( $aref->[1], $tflag, "The flag was okay for '$test'");
}
