use Test::More tests => 1;

$ENV{PERL5LIB} = 'lib';

my $xt = -e 'xt' ? 'xt' : 'test/devel';
system("./bin/pegex compile --to=perl $xt/foo.pgx > $xt/foo.pl");

my $diff = `diff -u $xt/foo.pl*`;

ok not($diff), 'pegex compile worked';

if ($diff) {
    diag $diff
}

unlink "$xt/foo.pl";
