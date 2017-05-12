
use strict;
use ExtUtils::MakeMaker;
use Data::Dumper;

# this is to catch values from previous perl Makefile.PL run
use lib 'testconfig';

# we try to load the previous config values
eval 'use MyConText::TestConfig';

# if we got some values and we are not forced to run the dialog again
# with -s or -setup option, just use those defaults, but say it
if (defined $MyConText::TestConfig::Config{'dsn'}
	and not (@ARGV and ($ARGV[0] eq '-s' or $ARGV[0] eq '-setup'))) {
	print <<'EOF';
	For the test suite, we use the database and user info specified
	during the previous run. If you want to change the values, run
	perl Makefile.PL -s.
EOF
	}
# we will ask the questions
else {
	print <<'EOF';
	We will ask you for the database info to run the test. To enter
	undefined value, accept empty string or say undef.
EOF
	if (not defined $MyConText::TestConfig::Config{'dsn'}) {
		$MyConText::TestConfig::Config{'dsn'} = 'dbi:mysql:test';
		}
	$MyConText::TestConfig::Config{'dsn'}
		= prompt 'The dsn for tests:', $MyConText::TestConfig::Config{'dsn'};
	$MyConText::TestConfig::Config{'user'}
		= prompt 'The username:', $MyConText::TestConfig::Config{'user'};
	$MyConText::TestConfig::Config{'password'}
		= prompt 'The password:', $MyConText::TestConfig::Config{'password'};

	for (qw! dsn user password !) {
		if ($MyConText::TestConfig::Config{$_} eq ''
			or $MyConText::TestConfig::Config{$_} eq 'undef') {
			$MyConText::TestConfig::Config{$_} = undef;
			}
		}
	}

# create the testconfig directory for the MyConText::TestConfig.pm file
mkdir 'testconfig', 0700;
mkdir 'testconfig/MyConText', 0700;

# write out the TestConfig file, to be used either for next perl
# Makefile.PL in this session, or (after install) even for further
# versions of this module
open OUT, '> testconfig/MyConText/TestConfig.pm' or die "Error writing the TestConfig\n";
print OUT Data::Dumper->new([ \%MyConText::TestConfig::Config ],
	[ '*MyConText::TestConfig::Config' ])->Dump,
	"1;\n";
close OUT;

WriteMakefile(
	NAME =>		'MyConText',
	VERSION_FROM =>	'MyConText.pm',
	PM =>		{ 'MyConText.pm' => '$(INST_LIBDIR)/MyConText.pm',
			'String.pm' => '$(INST_LIBDIR)/MyConText/String.pm',
			'File.pm' => '$(INST_LIBDIR)/MyConText/File.pm',
			'URL.pm' => '$(INST_LIBDIR)/MyConText/URL.pm',
			'Blob.pm' => '$(INST_LIBDIR)/MyConText/Blob.pm',
			'Column.pm' => '$(INST_LIBDIR)/MyConText/Column.pm',
			'Phrase.pm' => '$(INST_LIBDIR)/MyConText/Phrase.pm',
			'Table.pm' => '$(INST_LIBDIR)/MyConText/Table.pm',
			'testconfig/MyConText/TestConfig.pm' => '$(INST_LIBDIR)/MyConText/TestConfig.pm',
			},
	MAN1PODS =>	{ 'mycontextadmin' => '$(INST_MAN1DIR)/mycontextadmin.1' },
	dist =>		{ COMPRESS => 'gzip -9f', SUFFIX => 'gz',
			POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	macro =>	{ BENCH_FILES => 'bench/*.t' },
	depend =>	{ bench => q!pure_all
		for i in $(BENCH_FILES) ; do echo $$i ; $(FULLPERL) -I$(INST_ARCHLIB) -I$(INST_LIB) $$i ; done
		! },
	);

