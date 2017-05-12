
BEGIN
{
for my $path (@{ GetPbsConfig()->{LIB_PATH} })
	{
	push @INC, $path;
	}
}

use File::Basename;
use Utils::VisualStudioProjectFile;

=head1 NAME

VisualStudioProject

=head1 SYNOPSIS

 PbsUse('VisualStudioProject') ;
 
 my $pbsfile_content = GeneratePbsfileForVisualStudioProjectComponent($component_name) ;
 AddVisualStudioProjectRule($node, $project_name, $pbsfile_content) ;

=head1 DESCRIPTION

This PBS module reads visual studio project files and generates virtual pbsfile. This
effectively allows us to use '.vcproj' files as pbsfiles.

=cut

#----------------------------------------------------------------------------------------------------

sub AddVisualStudioProjectRule
{
my ($node, $project_name, $pbsfile_content) = @_;

AddRule $project_name,
	{
	NODE_REGEX      => $node,
	PBSFILE         => "./$project_name.vcproj",
	PACKAGE         => $project_name,
	PBSFILE_CONTENT => $pbsfile_content
	};
}

#----------------------------------------------------------------------------------------------------

sub GeneratePbsfileForVisualStudioProjectComponent
{
my ($component_name) = @_;

#---------------------------------- vcproj file ----------------------------------

my $component = GetConfig('THEBIGO_COMPONENTS')->{$component_name};

my $project_file = File::Spec->catfile($component->{PATH}, $component->{PROJECT_FILE});
$project_file =~ s|\\|/|g;

my ($located_project_file) = PBS::Check::LocateSource
				(
				$project_file,
				GetPbsConfig()->{BUILD_DIRECTORY},
				GetPbsConfig()->{SOURCE_DIRECTORIES}
				);

my $project_file_path = dirname($project_file);
my $base_dir = File::Spec->rel2abs($project_file_path, $ENV{THEBIGO_ROOT});

PrintUser("Reading Visual Studio project file '$project_file'.\n");

my ($config, $files) = VisualStudioProjectFile::Read
			(
			$located_project_file,
			$base_dir,
			GetConfig('COMPILER_DEBUG'),
			);

#----------------------------------- Libraries -----------------------------------

# Libraries are normal dependencies. People! stop handling libraries in a silly way!
for my $lib ( @{$config->{LIBRARIES}})
	{
	my ($located_lib) = PBS::Check::LocateSource($lib, '', $config->{LIBRARIES_SEARCH_PATHS}) ;
	$files->{$located_lib} = {} ; # no special config
	}

#--------------------------------- pbsfile section ---------------------------------

my $rc_defines_section = GenerateDefinesSection('RC_DEFINES', $config->{RC_DEFINES} || []);

#--------------------------------- pbsfile section ---------------------------------

#~ my $rc_flags_section = '' ;
#~ if (exists $config->{RC_CULTURE})
	#~ {
	#~ my $language = sprintf("%x", $config->{RC_CULTURE});
	#~ $rc_flags_section= "AddConfigTo('BuiltIn', 'RC_FLAGS:LOCAL' => '/l$language');\n";
	#~ }
	
my $rc_flags_section =  exists $config->{RC_CULTURE} 
			? sprintf("AddConfigTo('BuiltIn', 'RC_FLAGS:LOCAL' => '/l%x');\n", $config->{RC_CULTURE})
			: '' ;

#--------------------------------- pbsfile section ---------------------------------

my $rc_flags_include_section = GenerateIncludePathsSection
				(
				'RC_FLAGS_INCLUDE',
				$config->{RC_INCLUDE_PATHS} || []
				);
				
#--------------------------------- pbsfile section ---------------------------------

my $cdefines_section = GenerateDefinesSection('CDEFINES', $config->{DEFINES} || []);

#--------------------------------- pbsfile section ---------------------------------

my $cflags_include_section = GenerateIncludePathsSection
				(
				'CFLAGS_INCLUDE',
				$config->{INCLUDE_PATHS} || [],
				$component->{EXTRA_INCLUDE_PATHS} || [],
				$component->{INCLUDE_PATHS_TO_IGNORE} || []
				);
#--------------------------------- pbsfile section ---------------------------------

my $cflags_section = $config->{CFLAGS} ? 
    "AddConfig('CFLAGS:OVERRIDE_PARENT:SILENT_OVERRIDE' => '" .
    $config->{CFLAGS} .  "');\n\n" : '';

#--------------------------------- pbsfile section ---------------------------------

my $object_files_section = GenerateObjectFilesSection
				(
				$component_name,
				$files,
				$component->{EXTRA_FILES} || [],
				$component->{FILES_TO_IGNORE} || []
				);

#--------------------------------- pbsfile section ---------------------------------

my $library_search_paths = join(', ',  map {"'$_'"} @{$config->{LIBRARIES_SEARCH_PATHS}}) ;
my $library_search_paths_sections = "AddConfig(LIBRARIES_SEARCH_PATHS => [$library_search_paths]) ;\n" ;

#------------------------------------ Pbsfile ---------------------------------------

my $pbsfile = <<EOP;


PbsUse('Configs/ConfigureProject') ;

ExcludeFromDigestGeneration('Not generated files', qr/\\.(?!(o|res|objects))[^\\.]*\$/);

AddRule '${component_name}_vcproj', ['*/$component_name.objects' => '$project_file' ] ;

$rc_defines_section 
$rc_flags_section
$rc_flags_include_section

$cdefines_section
$cflags_include_section
$cflags_section

$object_files_section

$library_search_paths_sections

EOP

return $pbsfile;

}

#----------------------------------------------------------------------------------------------------

sub GenerateDefinesSection
{
my ($variable, $defines) = @_;

return @$defines ?
	"AddConfig('$variable:OVERRIDE_PARENT:SILENT_OVERRIDE' => '" .
	join('', map " -D$_", @$defines) . "');\n\n" :
	'';
}

#----------------------------------------------------------------------------------------------------

sub GenerateIncludePathsSection
{
my ($variable, $include_paths, $extra_include_paths, $include_paths_to_ignore) = @_;

my $include_paths_to_ignore_regex = '/(' . join('|', map("\Q$_\E", @$include_paths_to_ignore)) . ')$';

my @filtered_include_paths   = grep !/$include_paths_to_ignore_regex/, @$include_paths;
my @quoted_include_paths     = map qq|"$_"|, @filtered_include_paths;
my $include_paths_directives = join('', map " -I $_", (@quoted_include_paths, @$extra_include_paths)) ;

<<EOT
{
my \$old_include_paths = GetConfig('$variable') || '';
AddConfigTo('BuiltIn', '$variable:LOCAL' => \$old_include_paths . '$include_paths_directives');
}
EOT
}

#----------------------------------------------------------------------------------------------------

sub GenerateObjectFilesSection
{
my ($component_name, $files, $extra_files, $files_to_ignore) = @_;

my $pbsfile_content = '';
my $files_to_ignore_regex = '/(' . join('|', map("\Q$_\E", @$files_to_ignore)) . ')$';

my @filtered_files = 
	grep
		(
		!/$files_to_ignore_regex/,
			grep(/\.(c|cpp|rc|lib)$/, keys %$files)
		);

push @filtered_files, @$extra_files;

my @object_files;

for my $file (@filtered_files)
	{
	my $source_file = $file;
	$source_file =~ s|^$ENV{THEBIGO_ROOT}/?||i;
	
	my $object_file = $source_file;
	$object_file =~ s/\.(c|cpp)$/.o/;
	$object_file =~ s/\.rc$/.res/;
	
	push @object_files, $object_file;
	
	my $file_config   = $files->{$file};
	my $include_paths = $file_config->{INCLUDE_PATHS};
	
	if ($include_paths)
		{
		my $include_paths_string = join('', map(" -I $_", @$include_paths));
		
		$pbsfile_content .= <<EOF;
AddRule
	'$object_file',
	[ qr|(\\Q$object_file\\E\\|\\Q$source_file\\E)\$| ],
	undef,
	AppendConfig('CFLAGS_INCLUDE' => '$include_paths_string');

EOF
		}
	}

$pbsfile_content .= "AddRule '$component_name', ['*/$component_name.objects' => " ;
$pbsfile_content .=   "'" . join("', '", @object_files) . "'], \\&CreateObjectsFile ;\n";

return $pbsfile_content;
}

#----------------------------------------------------------------------------------------------------
1;

=head1 AUTHORS

Emil Jonsson

Khemir Nadim ibn Hamouda. nadim@khemir.net

Haakan Kvist

=cut



