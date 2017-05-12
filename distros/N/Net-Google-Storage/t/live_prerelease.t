BEGIN {
	use lib 't/lib';
	eval {require Net::Google::Storage::Test;};
	
	if($@) {
		eval "use Test::More skip_all => 'Probable missing Test::Class';";
	}
};

Test::Class->runtests;
