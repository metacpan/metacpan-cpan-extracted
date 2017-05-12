sub ConvertDSPFilesForTheBigOComponents
{
	my @dsp_files;

	while (my ($name, $component) = each %{ GetConfig('THEBIGO_COMPONENTS') })
	{
		next unless exists $component->{DSP_FILE};

		$component->{PROJECT_FILE} = $component->{DSP_FILE};
		$component->{PROJECT_FILE} =~ s/\.dsp$/.vcproj/;
	
		my $dsp_file = File::Spec->catfile($component->{PATH}, $component->{DSP_FILE});
		$dsp_file =~ s|\\|/|g;

		push @dsp_files, $dsp_file;
	}

	my $pbsfile_content = GeneratePbsfileToConvertDSPFiles(@dsp_files);

	my ($success, $message) = PBS::FrontEnd::Pbs(
		COMMAND_LINE_ARGUMENTS => [qw(-p virtual_pbsfile2 all)],
		PBS_CONFIG => { },
		PBSFILE_CONTENT => $pbsfile_content
	);

	unless ($success)
	{
		PrintError($message);
		exit(!$success);
	}
}


sub GeneratePbsfileToConvertDSPFiles
{
	my @dsp_files = @_;

	my $pbsfile_content = <<'EOF';
use File::Spec;
use Cwd;

PbsUse('Rules/Install');

AddRule [VIRTUAL], 'all', [ 'all'
EOF

	my @project_files = @dsp_files; map s/\.dsp$/.vcproj/, @project_files;

	$pbsfile_content .= join('', map ", '$_'", @project_files);

	$pbsfile_content .= <<'EOF';
 ]
   => BuildOk("All finished.");
   
EOF

	$pbsfile_content .= join('', map "AddInstallRule('$_');\n", @dsp_files);

	$pbsfile_content .= <<'EOF';

#AddRule 'vcproj', [ '*/*.vcproj' => '*.dsp' ]
AddRule 'vcproj', [ qr|\.vcproj$| => '$path/$basename.dsp' ]
   => \&BuildProjectFile;
   
sub BuildProjectFile
{
	my ($config,
		$file_to_build,
		$dependencies) = @_;

	my $dsp_file = $dependencies->[0];
	
	# ConvertToVC71.exe refuses to overwrite an existing .vcproj file,
	# therefore, remove the out-of-date .vcproj-file, if any.
	unlink $file_to_build;

	# Then, run ConvertToVC71.exe from the directory .dsp file
	my ($volume, $directories, $file) = File::Spec->splitpath($dsp_file);
	my $dsp_dir = File::Spec->catpath($volume, $directories, '');
	print $dsp_dir, "\n";

	my $old_wd = cwd();
	chdir $dsp_dir;

	eval { PBS::Shell::RunShellCommands('ConvertToVC71.exe'); };
	my $exception = $@;
	
	# The old working directory must be restored even if the shell command
	# failed.
	chdir $old_wd;
	
	if ($exception) { die $exception; }

	return (0, $exception) if $exception;
	return (1, "File converted successfully");
}

EOF

	return $pbsfile_content;
}


1;
