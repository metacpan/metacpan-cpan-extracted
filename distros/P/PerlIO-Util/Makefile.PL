use strict;
use warnings;
use inc::Module::Install;
use Module::Install::XSUtil 0.21;

if($] < 5.008_008){
	my $v = sprintf '%vd', $^V;
	warn(<<"END");
**** WARNING ***

Because Perl version $v has some bugs in perlio,
Perl version 5.8.8 or later is recommended.

END
	sleep 1;
}

cc_warnings;
use_ppport 3.19;

all_from 'lib/PerlIO/Util.pm';

test_requires 'Test::More' => 0.62;

author_tests 'xt';

clean_files q{
    PerlIO-Util-*
    cover_db
    *.gcov *.gcda *.gcno
    *.stackdump
    *.out
};

WriteAll( check_nmake => 0 );
