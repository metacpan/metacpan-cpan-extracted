
BEGIN { 
    use FindBin qw($Bin);
    require "$Bin/../../t/test.pl";
    plan(tests => 2);
}

use Regexp::Fields;

ok tied %{&}, 'tied %{&}';
is ref tied %{&}, "Regexp::Fields::tie", 'ref tied %{&}';

