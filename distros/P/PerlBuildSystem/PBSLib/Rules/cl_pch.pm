# Create and use precompiled headers with cl.

PbsUse('Dependers/Matchers');


sub Add_CL_PrecompiledHeaderObjectfilesRule
{
	# Adds a rule to build a number of object files, and additionally,
	# adds rules for generation and usage of a precompiled header pchfile.pch
	# via stdafx.h/stdafx.cpp. It is possible to control which object files
	# should use the precompiled header and which should not.

	# $object_files_with[out]_pch are references to lists with the object
	# files that should respectively should not use precompiled headers.

    my ($thisdir,
		$object_files_with_pch,
		$object_files_without_pch) = @_ ;

	# Also add stdafx.o
    AddObjectfilesRule($thisdir, @$object_files_with_pch, @$object_files_without_pch, 'stdafx.o');

	# Quote the file names for the matching, and put them inside */ and $
    map(s|(.*)|\Q/$1\E\$|, @$object_files_with_pch);

	# The object files are dependent on the precompiled header
	AddRule 'object to precompiled header', [ AnyMatch(@$object_files_with_pch) => '$path/pchfile.pch' ]
		=> undef # Use default builder
		=> AddFlagsToUse_CL_PrecompiledHeader();

	# pchfile.pch and stdafx.o will be built two times, one time with
	# this rule, and one with the rule for stdafx.o
	AddRule 'precompiled header', [ '*/pchfile.pch' => 'stdafx.cpp' ]
		=> "%CXX %CXXFLAGS /Zi /Fd%BUILD_DIRECTORY/ %CDEFINES %CFLAGS_INCLUDE -I%PBS_REPOSITORIES /Fo%BUILD_DIRECTORY/stdafx.o /c %DEPENDENCY_LIST"
		=> AddFlagsToCreate_CL_PrecompiledHeader();

	AddRule 'stdafx', [ '*/stdafx.o' ]
		=> undef # Use default builder
		=> AddFlagsToCreate_CL_PrecompiledHeader();
}


use constant CREATE => 'c';
use constant USE => 'u';

sub GeneratePrecompiledFlags
{
    my $flag = shift or die;
    return sub
	{
		my
			(
			 $dependent_to_check
			 , $config
			 , $tree
			 , $inserted_nodes
			) = @_ ;

		$tree->{__CONFIG} = {%{$tree->{__CONFIG}}} ; # config is share get our own copy (note! this is not deep)
		my $build_directory       = $tree->{__PBS_CONFIG}{BUILD_DIRECTORY} ;
		my $source_directories    = $tree->{__PBS_CONFIG}{SOURCE_DIRECTORIES} ;
		my ($dependent_full_name) = PBS::Check::LocateSource($dependent_to_check, $build_directory, $source_directories) ;
		my ($volume, $directories, $file) = File::Spec->splitpath($dependent_full_name);
		my $pchfile_path          = File::Spec->catpath( $volume, $directories, 'pchfile.pch');

		$tree->{__CONFIG}{CXXFLAGS} .= ' /Y' . $flag . '"stdafx.h" /Fp"' . $pchfile_path . '"' ;
	} ;
}

my $CreatePrecompiledHeader = GeneratePrecompiledFlags(CREATE);
my $UsePrecompiledHeader = GeneratePrecompiledFlags(USE);

sub AddFlagsToCreate_CL_PrecompiledHeader { return $CreatePrecompiledHeader };
sub AddFlagsToUse_CL_PrecompiledHeader { return $UsePrecompiledHeader };


1 ;
