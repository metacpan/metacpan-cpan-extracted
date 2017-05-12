package VisualStudioProjectFile;

use strict;
use warnings;

use File::Spec;
use XML::LibXML;

=head1 NAME

VisualStudioProjectFile

=head1 SYNOPSIS

 
=head1 DESCRIPTION

=cut

#----------------------------------------------------------------------------------------------------
sub Read
{
	my ($vsproj_file, $base_dir, $is_debug) = @_;

	my $configuration_name = $is_debug ? 'Debug|Win32' : 'Release|Win32';
	my $config_expr = '@Name=\'' . $configuration_name . '\'';
	
	my $doc = XML::LibXML->new()->parse_file($vsproj_file);

	my $config = FindConfig(
		$doc->findnodes('//Configuration[' . $config_expr . ']')->[0],
		$base_dir
	);

	my %files = map {
		my $file = FixPath($_->findvalue('@RelativePath'), $base_dir);

		my @config_nodes = $_->findnodes('FileConfiguration[' . $config_expr . ']');
		my $file_config = @config_nodes ? FindConfig($config_nodes[0], $base_dir) : {};
		
		$file => $file_config;
	} $doc->findnodes('//File[not(FileConfiguration[' . $config_expr . ' and @ExcludedFromBuild=\'TRUE\'])] ');

	return $config, \%files;
}

#----------------------------------------------------------------------------------------------------

sub FindConfig
{
	my ($node, $base_dir) = @_;

	my %config;
	
	if (my @cl = $node->findnodes('Tool[@Name=\'VCCLCompilerTool\']'))
	{
		my $cl = $cl[0];
		
		if (my $defines = $cl->findvalue('@PreprocessorDefinitions'))
		{
			$config{DEFINES} = [ SplitList($defines) ];
		}
	
		if (my $include_paths = $cl->findvalue('@AdditionalIncludeDirectories'))
		{
		        $config{INCLUDE_PATHS} = [ FixPathList($include_paths, $base_dir) ];
		}

		if (my $cflags = $cl->findvalue('@AdditionalOptions'))
		{
		    $config{CFLAGS} = $cflags;
		}
	}
	
	if (my @rc = $node->findnodes('Tool[@Name=\'VCResourceCompilerTool\']'))
	{
		my $rc = $rc[0];
		
		if (my $defines = $rc->findvalue('@PreprocessorDefinitions'))
		{
			$config{RC_DEFINES} = [ SplitList($defines) ];
		}
	
		if (my $include_paths = $rc->findvalue('@AdditionalIncludeDirectories'))
		{
			$config{RC_INCLUDE_PATHS} = [ FixPathList($include_paths, $base_dir) ];
		}

		if (my $culture = $rc->findvalue('@Culture'))
		{
			$config{RC_CULTURE} = $culture;
		}
	}

	if (my @lib = $node->findnodes('Tool[@Name=\'VCLibrarianTool\' and @AdditionalDependencies]'))
	{
		my $lib = $lib[0];
		
		$config{LIBRARIES} = [ SplitList($lib->findvalue('@AdditionalDependencies')) ];

		my $libraries_search_paths = $lib->findvalue('@AdditionalLibraryDirectories');
		$config{LIBRARIES_SEARCH_PATHS} = [ FixPathList($libraries_search_paths, $base_dir) ];
	}

	return \%config;
}

#----------------------------------------------------------------------------------------------------

sub FixPathList
{
	my ($path_list, $base_dir) = @_;
	
	return map FixPath($_, $base_dir), SplitList($path_list);
}

#----------------------------------------------------------------------------------------------------

sub SplitList
{
	my ($list) = @_;
	
	return grep($_, split('[,;]', $list));
}

#----------------------------------------------------------------------------------------------------

sub FixPath
{
	my ($path, $base_dir) = @_;

	$path = File::Spec->rel2abs($path, $base_dir);
	$path =~ s|\\|/|g;
	return $path;
}

#----------------------------------------------------------------------------------------------------
1;

=head1 AUTHORS

Emil Jonsson

Khemir Nadim ibn Hamouda. nadim@khemir.net

Haakan Kvist

=cut



