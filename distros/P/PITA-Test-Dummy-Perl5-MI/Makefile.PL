use inc::Module::Install 0.77;

# Instrumentation for exercising the Module::Install::With commands
sub yn { $_[0] ? 'Yes' : 'No' }
print "Compiling diagnostics...\n";
my %rv = (
	'cpanplus_available' => yn(cpanplus_available),
	'cpanpm'             => yn(cpanpm),
	'cpanplus'           => yn(cpanplus),
	'automated_testing'  => yn(automated_testing),
	'eumm'               => yn(eumm),
	'mb'                 => yn(mb),
#	'user_mode'          => yn(user_mode),
#	'author_mode'        => yn(author_mode),
	);
print <<"END_MESSAGE";
# BEGIN DIAGNOSTICS
#   CPANPLUS is installed and available   : $rv{cpanplus_available}
#   MI is running under CPAN.pm           : $rv{cpanpm}
#   MI is running under CPANPLUS          : $rv{cpanplus}
#   MI is running under AUTOMATED_TESTING : $rv{automated_testing}
#   MI is targetting ExtUtils::MakeMaker  : $rv{eumm}
#   MI is targetting Module::Build        : $rv{mb}
# END DIAGNOSTICS
END_MESSAGE

# The regular MI installation stuff
all_from 'lib/PITA/Test/Dummy/Perl5/MI.pm';

WriteAll;
