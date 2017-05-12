use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}


#== TESTS =====================================================================

require_ok ('TM::Utils');

{
    my $t = {
	aaa => 111,
	bbb => 222,
	ccc => {
	    ddd => 444,
	    eee => 555
	    },
	fff => 666
    };

    my $d = TM::Utils::xmlify_hash ($t);
    ok (TM::Utils::is_xml ($d), 'tree is XML');
}
