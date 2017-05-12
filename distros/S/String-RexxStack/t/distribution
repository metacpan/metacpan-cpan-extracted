use POSIX;

BEGIN {
	if ($ENV{PWD} =~ m#/t$#) {
		warn "run this test from top-distribution directory\n";
		POSIX::_exit(0) ;
	};
}

eval 'require Test::Distribution';
($@)  ?  plan (skip_all => 'Test::Distribution not installed')
      :  import Test::Distribution;
