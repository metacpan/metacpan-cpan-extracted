use Test::More;

BEGIN {
	plan skip_all => "set RELEASE_TESTING to test"
		unless $ENV{RELEASE_TESTING};

	subtest validity => sub {
		eval { require Test::CPAN::Changes };
		plan skip_all => "$@" if $@;
		Test::CPAN::Changes::changes_ok();
	} and subtest correctness => sub {
		eval { require CPAN::Changes };
		if ($@) {
			plan skip_all => "$@" if $@;
		} else {
			use Parse::DNS::Zone;
			my $ch = CPAN::Changes->load('Changes');
			my $latest = (reverse $ch->releases())[0];

			my $version = $Parse::DNS::Zone::VERSION;
			is $latest->version, $version,
			   "Module version is $version, changelog is in sync?";
		}
		done_testing();
	};
}

done_testing();
