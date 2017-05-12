use Test::More;
use lib qw( ./lib ../lib );
use Net::Domain::TldMozilla;
eval{ use File::Temp qw/ tempdir / };

if (my $error= $@) { plan skip_all=> 'File::Temp is not installed.' } else {
	if (my $source= LWP::Simple::get($Net::Domain::TldMozilla::SOURCE_URL)) {
		$ENV{TLD_MOZILLA_TEMP}= tempdir( CLEANUP => 1 );
		my @tld;
		for (split /\n/, $source) {
			next if (! $_ or /^\s*(?:\/|\#)/);
			my $icode= Jcode::getcode(\$_) || next;
			next if $icode ne 'ascii';
			s/^\s*\*\.?//;
			s/^\s*\!\s*\.?//;
			push @tld, $_;
		}
		my $temp= "$ENV{TLD_MOZILLA_TEMP}/mozilla_tld.cache";
		File::Slurp::write_file($temp, ( join("\n", @tld) || '' ));
		warn __PACKAGE__. " - data save. [$temp]";
		my $num= $ENV{SPAMER_ARGS} ? 10 : do {
			warn "I want information on SPAMer in SPAMER_ARGS of the environment variable.";
			8;
		  };
		&main_test($num);
	} else {
		plan skip_all=> 'HTTP_PROXY of the environment variable might be necessary.';
	}
}

sub main_test {
	my($test)= @_;
	plan tests=> $test;

	can_ok 'Net::Domain::TldMozilla', 'get_tld';
	  ok my @list= Net::Domain::TldMozilla->get_tld;
	  ok scalar(@list)> 0;

	require_ok 'Net::SPAMerLookup';
	ok my $spam= Net::SPAMerLookup->new, q{Constructor.};
	can_ok $spam, 'import';
	can_ok $spam, 'check_rbl';
	can_ok $spam, 'is_spamer';
	if (my $target= $ENV{SPAMER_ARGS}) {
		ok $spam->check_rbl($target);
		ok $spam->is_spamer($target);
	}
}
