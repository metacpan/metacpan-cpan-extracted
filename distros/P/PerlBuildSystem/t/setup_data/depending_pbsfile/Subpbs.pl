use File::Slurp;

AddRule '1', [ '1' => '2' ]
	=> 'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';

AddRule '2', [ '2' ]
	=> sub
	{
		my ($config, $file_to_build) = @_;
		write_file($file_to_build, '2');
	};
