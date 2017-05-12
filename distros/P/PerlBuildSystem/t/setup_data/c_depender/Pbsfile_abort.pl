PbsUse('Configs/Compilers/gcc');
PbsUse('Rules/C');

AddRule 'test-c', [ 'test-c.exe' => '1.o' ]
	=> '%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST';

AddRule 'o', [ '1.o' => '1.c' ]
	=> sub {
	    my $config = shift;
	    my $file_to_build = shift;
	    my $dependencies = shift;
		
		if ($ENV{'PBS_TEST_ABORT'}) {
			return 0, 'Aborting';
		}
		
	    PBS::Shell::RunShellCommands(
			$config->{'CC'} . ' ' .
			$config->{'CFLAGS'} .
			" -o $file_to_build -c @$dependencies"
		);
		
	    return 1, 'Builder sub message';
	};
