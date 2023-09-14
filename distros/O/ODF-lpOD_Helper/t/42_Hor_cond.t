#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug $debug/;

use Test2::Plugin::BailOnFail;

use ODF::lpOD;
use ODF::lpOD_Helper qw/:DEFAULT
                        TEXTLEAF_FILTER PARA_FILTER TEXTCONTAINER_FILTER
                        TEXTLEAF_OR_PARA_FILTER/;


is (Hor_cond(qr/^foo$/), "foo", 'Hor_cond optmized qr/^foo$/');

is (Hor_cond(qr/^(foo|bar)$/), "foo|bar", 'Hor_cond optmized qr/^(foo|bar)$/');

is (Hor_cond(qr/^foo:[sh]$/), "foo:s|foo:h", 'Hor_cond optimized ^foo[...]$');

is (Hor_cond(undef), undef, 'Hor_cond(undef)');
is (Hor_cond("A",undef,"B"), undef, 'Hor_cond("A",undef,"B")');

is (join('|', sort split(/\|/, Hor_cond(qr/^foo$/, qr/^bar$/, "CCC|DDD"))),
    join('|', sort qw/foo bar CCC DDD/), "Hor_cond combo strings");

my $cond = Hor_cond qr/^text:[sh]$/,
                    qr/^AAA|BBB$/,   # Note ONE-SIDED anchoring!
                    qr/xxBBB/,
                    "foo",
                    "CCC",
                    sub{ $_[0] =~ /^DDD$/ }
                    ;

say "got ",visnew->Deparse(1)->cond($cond) if $debug;

my @good = ("AAA", "AAAxx", "BBB", "xxBBB", "foo", "CCC", "DDD",
            "text:h", "text:s",
           );

my @bad  = ("xAAA", "BBBx", " foo", "CCC ", "DDDDD", " DDD", " DDD ",
            "text:X", "text:hX",
            " text:h", " text:s",
           );

sub test_if_passes($$) {
  my ($cond, $input) = @_;
  ref($cond) eq "CODE" ? $cond->($input) :
  ref($cond) eq "Regexp" ? $input =~ $cond :
  ref($cond) ? oops :
  $input =~ /^(?:${cond})$/;
}

foreach my $input (@good) {
  fail("Hor_cond result failed to match $input",
       "\ncond=".visnew->Deparse(1)->vis($cond))
    unless test_if_passes($cond, $input);
}
ok(1, "combined cond passing when it should");

foreach my $input (@bad) {
  fail("Hor_cond result matched UNEXPECTEDTLY $input",
       "\ncond=".visnew->Deparse(1)->vis($cond))
    if test_if_passes($cond, $input);
}
ok(1, "combined cond failing when it should");

is (join('|', sort split(/\|/, PARA_FILTER)),
    join('|', sort qw/text:h text:p/), "PARA_FILTER");

is (join('|', sort split(/\|/, TEXTLEAF_FILTER)),
    join('|', sort ('#TEXT',qw/text:s text:tab text:line-break/)),
    "TEXTLEAF_FILTER");

is (join('|', sort split(/\|/, TEXTCONTAINER_FILTER)),
    join('|', sort qw/text:h text:p text:span/), "TEXTCONTAINER_FILTER");

is (join('|', sort split(/\|/, TEXTLEAF_OR_PARA_FILTER)),
    join('|', sort ('#TEXT',qw/text:p text:h text:s text:tab text:line-break/)),
    "TEXTLEAF_OR_PARA_FILTER");

done_testing;
