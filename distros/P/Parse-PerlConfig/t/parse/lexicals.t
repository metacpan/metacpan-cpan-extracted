# parse() test for lexicals
# $Id: lexicals.t,v 1.3 2000/07/19 23:43:25 mfowler Exp $

# This script verifies that the lexical variables that parse() introduces
# into the configuration file do indeed exist.  This test is currently
# incomplete, as it only tests the default lexicals inserted, and not any
# user-specified ones.


use Parse::PerlConfig;
use Data::Dumper;

use lib qw(t);
use parse::testconfig qw(ok);

use strict;
use vars qw($tconf %lexicals);


%lexicals = (
    'scalar'        =>      'bar',
    'hash'          =>      {qw(foo bar blah doo)},
    'array'         =>      [qw(qux quux quuux quuuux)],
);


$tconf = parse::testconfig->new('lex-test.conf');

$tconf->ok_object;
$tconf->tests(keys(%lexicals) * 2 + $tconf->verify_parsed_default_lexicals());


{
    my $parsed = Parse::PerlConfig::parse(
        File        =>  $tconf->file_path,
        Lexicals    =>  \%lexicals,
    );

    $tconf->verify_parsed_default_lexicals($parsed);

    while (my($varname, $value) = each(%lexicals)) {
        my $parsed_varname = "lexical_$varname";

        ok(defined $$parsed{$parsed_varname});

        my $odump = Data::Dumper->Dump([$value], ["*$varname"]);
        my $pdump = Data::Dumper->Dump(
            [$$parsed{$parsed_varname}], ["*$varname"]
        );

        ok($odump eq $pdump, qq{lexical "$varname" check -- $odump eq $pdump});
    }
}
