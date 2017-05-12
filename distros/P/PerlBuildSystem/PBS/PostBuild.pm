
package PBS::PostBuild ;
use PBS::Debug ;

use 5.006 ;

use strict ;
use warnings ;
use Data::Dumper ;
use File::Spec::Functions qw(:ALL) ;

use Carp ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(AddPostBuildCommand) ;
our $VERSION = '0.01' ;

use File::Basename ;

use PBS::Output ;
use PBS::Constants ;
use PBS::Rules ;

#-------------------------------------------------------------------------------

my %post_build_commands;

#-------------------------------------------------------------------------------

sub GetPostBuildRules
{
my $package = shift ;
my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;

my @post_build_commands = () ;

PrintInfo("Get all post build commands for package: '$package'\n") if defined $pbs_config->{DEBUG_DISPLAY_POST_BUILD_COMMANDS_REGISTRATION} ;

if(exists $post_build_commands{$package})
	{
	push @post_build_commands, @{$post_build_commands{$package}} ;
	}

return(@post_build_commands) ;
}

#-------------------------------------------------------------------------------

sub AddPostBuildCommand
{
my($name, $switch, $builder_sub, $build_arguments) = @_ ;

my ($package, $file_name, $line) = caller() ;
$file_name =~ s/^'// ;
$file_name =~ s/'$// ;

RegisterPostBuildCommand
	(
	$file_name, $line
	, $package
	, $name
	, $switch, $builder_sub, $build_arguments
	) ;
}

sub RegisterPostBuildCommand
{
my ($file_name, $line, $package, $name, $switch, $builder_sub, $build_arguments) = @_ ;

my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;

if(exists $post_build_commands{$package})
	{
	for my $post_build_commands (@{$post_build_commands{$package}})
		{
		if
			(
			$post_build_commands->{NAME} eq $name
			&& 
				(
				   $post_build_commands->{FILE} ne $file_name
				|| $post_build_commands->{LINE} ne $line
				)
			)
			{
			Carp::carp ERROR("'$name' name is already used for for post build command defined at $post_build_commands->{FILE}:$post_build_commands->{LINE}\n") ;
			PbsDisplayErrorWithContext($file_name, $line) ;
			PbsDisplayErrorWithContext($post_build_commands->{FILE}, $post_build_commands->{LINE}) ;
			die ;
			}
		}
	}
	
if('' eq ref $switch || 'HASH' eq ref $switch)
	{
	Carp::carp ERROR("Invalid post build command definition") ;
	PbsDisplayErrorWithContext($file_name,$line) ;
	die ;
	}
	
if(defined $builder_sub && 'CODE' ne ref $builder_sub)
	{
	Carp::carp ERROR("Error: Builder must be a sub reference.\n") ;
	PbsDisplayErrorWithContext($file_name,$line) ;
	die ;
	}
	
my $post_build_depender_sub ;
	
if('ARRAY' eq ref $switch)
	{
	unless(@$switch)
		{
		Carp::carp ERROR("Nothing defined in post build definition at: $name") ;
		PbsDisplayErrorWithContext($file_name,$line) ;
		die ;
		}

	my @post_build_regexes ;
	
	for my $post_build_regex_definition (@$switch)
		{
		unless(file_name_is_absolute($post_build_regex_definition) || $post_build_regex_definition=~ /^\.\//)
			{
			$post_build_regex_definition= "./$post_build_regex_definition" ;
			}
			
		my 
			(
			  $build_ok, $build_message
			, $post_build_path_regex
			, $post_build_prefix_regex
			, $post_build_regex
			) = PBS::Rules::BuildDependentRegex($post_build_regex_definition) ;
		
		unless($build_ok)
			{
			Carp::carp ERROR($build_message) ;
			PbsDisplayErrorWithContext($file_name,$line) ;
			die ;
			}
			
		push @post_build_regexes, [$post_build_path_regex, $post_build_prefix_regex, $post_build_regex];
		}
		
	$post_build_depender_sub = sub 
						{
						my $name_to_check = shift ; 
						my $index = -1 ;
						
						for my $post_build_regex (@post_build_regexes)
							{
							$index++ ;
							my ($post_build_path_regex, $post_build_prefix_regex, $post_build_regex) = @$post_build_regex;
							
							#~ print "post build '$name' checking '$name_to_check' with regex:" ;
							#~ print "'/^$post_build_path_regex$post_build_prefix_regex$post_build_regex\$/'\n" ;
							
							if($name_to_check =~ /^$post_build_path_regex$post_build_prefix_regex$post_build_regex$/)
								{
								#~ print "matched " . Dumper($switch) . "\n" ;
								#~ print "matched \n" ;
								
								return(1, "regex index: $index matched") ;
								}
							else
								{
								#~ print "No match\n" ;
								}
							}
							
						return(0, "'$name_to_check' didn't match any post build ccommand regex") ;
						}
	}
	
if('CODE' eq ref $switch)
	{
	$post_build_depender_sub = $switch ;
	}
	
my $origin = '' ;
	
if($pbs_config->{ADD_ORIGIN})
	{
	$origin = ":$package:$file_name:$line" ;
	}
	
my $post_build_definition = 
	{
	  TYPE                => 'unused field' #unused type field
	, NAME                => $name
	, ORIGIN              => $origin
	, FILE                => $file_name
	, LINE                => $line
	, DEPENDER            => $post_build_depender_sub
	, BUILDER             => $builder_sub
	, BUILDER_ARGUMENTS   => $build_arguments
	, TEXTUAL_DESCRIPTION => $switch # keep a visual on how the rule was defined
	} ;

if(defined $pbs_config->{DEBUG_DISPLAY_POST_BUILD_COMMANDS_REGISTRATION})
	{
	PrintInfo("Registering post build command: '$name$origin'\n")  ;
	}

if(defined $pbs_config->{DEBUG_DISPLAY_POST_BUILD_COMMAND_DEFINITION})
	{
	PrintInfo(DumpTree($post_build_definition, "post build commands '$name' definition:")) ;
	}

push @{$post_build_commands{$package}}, $post_build_definition ;
}

#-------------------------------------------------------------------------------

sub DisplayAllPostBuildCommands
{
warn DumpTree(\%post_build_commands, "All post build commands:") ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::PostBuild  -

=head1 SYNOPSIS

	# in a Pbsfile
	AddRule 'a', ['a' => 'aa'], BuildOk('fake builder') ;
	AddRule 'aar', ['aa' => undef], BuildOk('fake builder') ;
	
	AddPostBuildCommand 'post build', ['a', 'b', 'c', 'aa'], \&PostBuildCommands ;
	
	AddPostBuildCommand 'post build', \&Filter, \&PostBuildCommands ;
	
	
=head1 DESCRIPTION

I<AddPostBuildCommand> allows you to AddPostBuildCommand  perl subs for run after a node has been build.

=head2 EXPORT

I<AddPostBuildCommand>.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut
