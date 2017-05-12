
use strict ;
use warnings ;

use Module::Build ;
	
my %all_modules ;
my @split_modules ;

my @pm_files = qw(
lib/Module/Text/Template//Build.pm
);

for(@pm_files)
	{
	$all_modules{$_} = $_ ;
	push @split_modules, $_ ;
	}

sub GetVersionAndRevisionFrom
{
my ($file) = @_ ;

my $version_from = File::Spec->catfile( split '/', $file );
my $version      = Module::Build->version_from_file($version_from);

if($ENV{'Module_Text_Template_Build_USE_GIT_VERSION_FOR_DIST'})
	{
	my $number_of_commits = `git log | grep -E 'commit [0-9a-f]{40}' | wc -l` ;
	chomp $number_of_commits ;
	
	if($number_of_commits)
		{
		#~ print "number of git revision $number_of_commits.\n" ;
		return("${version}.${number_of_commits}") ;
		}
	else
		{
		print "Couldn't get git revision, using version from '$file'!\n" ;
		return($version) ;
		}
	}
else
	{
	return($version) ;
	}
}

my $code = <<'EOC'

use strict ;
use warnings ;

sub GetVersionAndRevisionFrom
{
my ($file) = @_ ;

my $version_from = File::Spec->catfile( split '/', $file );
my $version      = Module::Build->version_from_file($version_from);

if($ENV{'Module_Text_Template_Build_USE_GIT_VERSION_FOR_DIST'})
	{
	my $number_of_commits = `git log | grep -E 'commit [0-9a-f]{40}' | wc -l` ;
	chomp $number_of_commits ;
	
	if($number_of_commits)
		{
		#~ print "number of git revision $number_of_commits.\n" ;
		return("${version}.${number_of_commits}") ;
		}
	else
		{
		print "Couldn't get git revision, using version from '$file'!\n" ;
		return($version) ;
		}
	}
else
	{
	return($version) ;
	}
}

sub ACTION_author_test
{
my $self = shift;
local $self->{properties}{test_files} = 'xt/author/*.t' ;
$self->SUPER::ACTION_test();
}

sub ACTION_dist
{
my $self = shift;

if($ENV{'Module_Text_Template_Build_USE_GIT_VERSION_FOR_DIST'})
	{
	my $have_git = $self->do_system('git --version');
	
	if($have_git)
		{
		print `git status`;
		
		if($self->do_system('git log  --decorate > git_Changes'))
			{
			use File::Copy;
			move('git_Changes', 'Changes') ;
			}
		else
			{
			print "Couldn't get git log, 'Changes' will not be generated from git log!\n" ;
			}
		}
	else
		{
		print "git not found, 'Changes' will not be generated from git log!\n" ;
		}
	}

$self->SUPER::ACTION_test() ;
#~ $self->ACTION_author_test() ;

$self->SUPER::ACTION_dist();
};

EOC
;

my $class = Module::Build->subclass(class => 'Module::Text::Template::Build', code => $code) ;

my $build = $class->new
	(
	module_name => 'Module::Text::Template::Build',
	
	dist_version => GetVersionAndRevisionFrom('lib/Module/Text/Template/Build.pm'),
	
	license => 'perl',
	build_requires => 
		{
		'Text::Diff' => 0,
		'Test::Block' => 0,
		'Test::Exception' => 0,
		'Test::NoWarnings' => 0,
		'Test::Warn' => 0,
		'Directory::Scratch::Structured' => 0,
		'Test::File::Contents' => 0,
		'Test::Command' => 0,
		'Sub::Exporter' => 0,
		'File::HomeDir'    => 0,
		'File::Find::Rule' => 0,
		},
	requires => 
		{
		'Sub::Exporter' => 0,
		'Readonly'         => 0,
		'Text::Template'   => 0,
		'File::Basename'   => 0,
		'File::Path'       => 0,
		'File::Slurp'      => 0,
		'Module::Util'     => 0,
		'Data::TreeDumper' => 0,
		},
		
	pm_files     => \%all_modules,
	autosplit    => \@split_modules,
	
	script_files => 'script/create_module',
	dist_author  => 'Khemir Nadim ibn Hamouda. <nadim@khemir.net>',
	dist_abstract => 'Create a module based on a template to use with Module::Build',
	);

#-----------------------------------------------------------------------------------------------------------

use File::HomeDir ;
my $user_template = home() . '/.perl_module_template' ;

if(-e $user_template)
	{
	print "Found default template in '$user_template'! You should diff your template "
		. "with the template that comes with this version of Module::Text::Template::Build.\n\n" ;
	}
else
	{
	my $answer =  $build->y_n('Create a default template in your home directory?', 'no') ;
	
	if($answer == 1)
		{
		use File::Copy::Recursive 'rcopy' ;
		rcopy('module_template', $user_template) or die "Can't copy the default template in your home directory: $!" ;

		print "\nThe default template was installed in '$user_template'. "
			. "Before using the 'create_module' script, complete the template with your own information. " 
			. "You can grep for the 'MODIFY_ME_BEFORE_FIRST_RUN' string to find what you should complete.\n\n" ;
		}
	}

$build->create_build_script;
  
