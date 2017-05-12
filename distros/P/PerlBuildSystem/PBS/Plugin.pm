
package PBS::Plugin;

use 5.006 ;

use strict ;
use warnings ;
use Carp ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(ScanForPlugins RunPluginSubs RunUniquePluginSub) ;
our $VERSION = '0.04' ;

use File::Basename ;
use Getopt::Long ;
use Cwd ;

use PBS::Constants ;
use PBS::PBSConfig ;
use PBS::Output ;

#-------------------------------------------------------------------------------

my $plugin_load_package = 0 ;
my %loaded_plugins ;

if($^O eq "MSWin32")
	{
	# remove an annoying warning
	local $SIG{'__WARN__'} = sub {print STDERR $_[0] unless $_[0] =~ /^Subroutine CORE::GLOBAL::glob/} ;

	# the normal 'glob' handles ~ as the home directory even if it is not at the begining of the path
	eval "use File::DosGlob 'GLOBAL_glob';" ;
	die $@ if $@ ;
	}

#-------------------------------------------------------------------------------

sub GetLoadedPlugins
{
return(keys %loaded_plugins) ;
}

#-------------------------------------------------------------------------------

sub LoadPlugin
{
my ($config, $plugin) = @_;

if(exists $loaded_plugins{$plugin})
	{
	PrintInfo "   Ignoring Already loaded '$plugin'.\n" if $config->{DISPLAY_PLUGIN_LOAD_INFO} ;
	return ;
	}
	
if($config->{DISPLAY_PLUGIN_LOAD_INFO})
	{
	my ($basename, $path, $ext) = File::Basename::fileparse($plugin, ('\..*')) ;
	PrintInfo "   $basename$ext\n" ;
	}
	
$loaded_plugins{$plugin} = $plugin_load_package ;

eval
	{
	PBS::PBS::LoadFileInPackage
		(
		''
		, $plugin
		, "PBS::PLUGIN_$plugin_load_package"
		, {}
		, "use strict ;\nuse warnings ;\n"
		  . "use PBS::Output ;\n"
		) ;
	} ;
	
die ERROR("Couldn't load plugin from '$plugin':\n   $@") if $@ ;
$plugin_load_package++ ;
}

#-------------------------------------------------------------------------------

sub LoadPluginFromSubRefs
{
my ($config, $plugin, %subs) = @_;

my ($package, $file_name, $line) = caller() ;

if(exists $loaded_plugins{$plugin})
	{
	PrintInfo "Plugin '$plugin' from '$file_name:$line' already loaded, Ignoring!\n" if $config->{DISPLAY_PLUGIN_LOAD_INFO} ;
	}
else
	{
	PrintInfo "Plugin '$plugin' from '$file_name:$line':\n" if $config->{DISPLAY_PLUGIN_LOAD_INFO} ;
	
	$loaded_plugins{$plugin} = $plugin_load_package ;
	
	while (my($sub_name, $sub_ref) = each %subs)
		{
		if($config->{DISPLAY_PLUGIN_LOAD_INFO})
			{
			PrintInfo "   sub ref '$sub_name'\n" ;
			}
			
		eval "* PBS::PLUGIN_${plugin_load_package}::$sub_name = \$sub_ref ;" ;
		}
	
	$plugin_load_package++ ;
	}
}

#-------------------------------------------------------------------------------

sub ScanForPlugins
{
my ($config, $plugin_paths) = @_ ;

for my $plugin_path (@$plugin_paths)
	{
	PrintInfo "Plugin directory '$plugin_path':\n" if $config->{DISPLAY_PLUGIN_LOAD_INFO} ;
	
	for my $plugin (glob("$plugin_path/*.pm"))
		{
		LoadPlugin($config, $plugin) ;
		}
	}
}

#-------------------------------------------------------------------------------

sub RunPluginSubs
{
# run multiple subs, don't return anything

my ($config, $plugin_sub_name, @plugin_arguments) = @_ ;

my ($package, $file_name, $line) = caller() ;
$file_name =~ s/^'// ;
$file_name =~ s/'$// ;

PrintInfo "Calling '$plugin_sub_name' from '$file_name:$line':\n" if $config->{DISPLAY_PLUGIN_RUNS} ;

for my $plugin_path (sort keys %loaded_plugins)
	{
	no warnings ;

	my $plugin_load_package = $loaded_plugins{$plugin_path} ;
	
	my $plugin_sub ;
	
	eval "\$plugin_sub = *PBS::PLUGIN_${plugin_load_package}::${plugin_sub_name}{CODE} ;" ;
	
	if($plugin_sub)
		{
		PrintInfo "Running '$plugin_sub_name' in plugin '$plugin_path'\n" if $config->{DISPLAY_PLUGIN_RUNS} ;
		
		eval {$plugin_sub->(@plugin_arguments)} ;
		die ERROR "Error Running plugin sub '$plugin_sub_name':\n$@" if $@ ;
		}
	else
		{
		PrintWarning "Couldn't find '$plugin_sub_name' in plugin '$plugin_path'\n" if $config->{DISPLAY_PLUGIN_RUNS} ;
		}
	}
}

#-------------------------------------------------------------------------------

sub RunUniquePluginSub
{
# run a single sub and returns

my ($config, $plugin_sub_name, @plugin_arguments) = @_ ;

my ($package, $file_name, $line) = caller() ;
$file_name =~ s/^'// ;
$file_name =~ s/'$// ;

PrintInfo "Calling unique '$plugin_sub_name' from '$file_name:$line':\n" if $config->{DISPLAY_PLUGIN_RUNS} ;

my (@found_plugin, $plugin_path, $plugin_sub) ;
my ($plugin_sub_to_run, $plugin_to_run_path) ;

for $plugin_path (sort keys %loaded_plugins)
	{
	no warnings ;

	my $plugin_load_package = $loaded_plugins{$plugin_path} ;
	
	eval "\$plugin_sub = *PBS::PLUGIN_${plugin_load_package}::${plugin_sub_name}{CODE} ;" ;
	push @found_plugin, $plugin_path if($plugin_sub) ;

	if($plugin_sub)
		{
		$plugin_sub_to_run = $plugin_sub ;
		$plugin_to_run_path = $plugin_path ;
		PrintInfo "Found unique '$plugin_sub_name' in plugin '$plugin_path'\n" if $config->{DISPLAY_PLUGIN_RUNS} ;
		}
	else
		{
		PrintWarning "Couldn't find unique '$plugin_sub_name' in plugin '$plugin_path'\n" if $config->{DISPLAY_PLUGIN_RUNS} ;
		}
	}
	
if(@found_plugin > 1)
	{
	die ERROR "Error: Found more than one plugin for unique '$plugin_sub_name'\n" . join("\n", @found_plugin) . "\n" ;
	}

if($plugin_sub_to_run)
	{
	PrintInfo "Running unique '$plugin_sub_name' in plugin '$plugin_to_run_path'\n" if $config->{DISPLAY_PLUGIN_RUNS} ;
	
	if(! defined wantarray)
		{
		eval {$plugin_sub_to_run->(@plugin_arguments)} ;
		die ERROR "Error Running unique plugin sub '$plugin_sub_name':\n$@" if $@ ;
		}
	else
		{
		if(wantarray)
			{
			my @results ;
			eval {@results = $plugin_sub_to_run->(@plugin_arguments)} ;
			die ERROR "Error Running unique plugin sub '$plugin_sub_name':\n$@" if $@ ;
			
			return(@results) ;
			}
		else
			{
			my $result ;
			eval {$result = $plugin_sub_to_run->(@plugin_arguments)} ;
			die ERROR "Error Running unique plugin sub '$plugin_sub_name':\n$@" if $@ ;
			
			return($result) ;
			}
		}
	}
else
	{
	PrintWarning "Couldn't find unique Plugin '$plugin_sub_name'.\n" if $config->{DISPLAY_PLUGIN_RUNS} ;
	return ;
	}
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Plugin  - Handle Plugins in PBS

=head1 SYNOPSIS


=head1 DESCRIPTION

=head2 LIMITATIONS

plugins can't hadle the same switch (switch registred by a plugin, pbs switches OK when passed to plugin)

=head2 EXPORT

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual.

=cut
