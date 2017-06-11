use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME         => 'Sort::Naturally::XS',
	VERSION_FROM => 'lib/Sort/Naturally/XS.pm', # finds $VERSION
	PREREQ_PM    => {}, # e.g., Module::Name => 1.1
	($] >= 5.005                                ? ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'lib/Sort/Naturally/XS.pm', # retrieve abstract from module
			AUTHOR     => 'Sergey Yurzin <jurzin.s@gmail.com>') : ()),
	LIBS         => [''], # e.g., '-lm'
	DEFINE       => '', # e.g., '-DHAVE_SOMETHING'
	INC          => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
	# OBJECT            => '$(O_FILES)', # link all the C files too
	MYEXTLIB     => 'src/libnsort$(LIB_EXT)',
	OPTIMIZE     => '-O3',
	META_MERGE   => {
		'meta-spec' => {
			version => 2
		},
		resources   => {
			repository => {
				type => 'git',
				url  => 'https://github.com/CaballerosTeam/Sort-Naturally-XS.git',
				web  => 'https://github.com/CaballerosTeam/Sort-Naturally-XS',
			},
			bugtracker => {
				web    => 'https://github.com/CaballerosTeam/Sort-Naturally-XS/issues',
				mailto => 'jurzin.s@gmail.com',
			},
		},
	},
);
if (eval {
	require ExtUtils::Constant;
	1
}) {
	# If you edit these definitions to change the constants used by this module,
	# you will need to use the generated const-c.inc and const-xs.inc
	# files to replace their "fallback" counterparts before distributing your
	# changes.
	my @names = (qw());
	ExtUtils::Constant::WriteConstants(
		NAME         => 'Sort::Naturally::XS',
		NAMES        => \@names,
		DEFAULT_TYPE => 'IV',
		C_FILE       => 'const-c.inc',
		XS_FILE      => 'const-xs.inc',
	);

}
else {
	use File::Copy;
	use File::Spec;
	foreach my $file ('const-c.inc', 'const-xs.inc') {
		my $fallback = File::Spec->catfile( 'fallback', $file );
		copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
	}
}
sub MY::postamble {
'
$(MYEXTLIB): src/Makefile
		cd src && $(MAKE) $(PASSTHRU)
';
}
