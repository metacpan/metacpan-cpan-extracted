
package PBS::Triggers ;
use PBS::Debug ;

use 5.006 ;

use strict ;
use warnings ;
use Carp ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(AddTrigger ImportTriggers) ;
our $VERSION = '0.01' ;

use File::Basename ;
use Text::Balanced qw(extract_codeblock) ;
use File::Spec::Functions qw(:ALL) ;

use PBS::Output ;
use PBS::Constants ;
use PBS::Rules ;
use PBS::Plugin ;
use PBS::PBSConfig ;

use Data::TreeDumper ;
#-------------------------------------------------------------------------------

# Triggers let the user insert dependency trees within the current 
# dependency tree, PBS might then have multiple roots to handle

#-------------------------------------------------------------------------------

my %triggers ;

#-------------------------------------------------------------------------------

sub GetTriggerRules
{
my $package = shift ;
my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;

PrintInfo("Get all triggers rules for package: '$package'\n") if defined $pbs_config->{DEBUG_DISPLAY_TRIGGER_RULES} ;

return(@{$triggers{$package}}) if(exists $triggers{$package}) ;
return() ;
}

#-------------------------------------------------------------------------------

sub AddTrigger
{
my ($package, $file_name, $line) = caller() ;
$file_name =~ s/^'// ;
$file_name =~ s/'$// ;

my(@trigger_definition) = @_ ;
my $trigger_definition = \@trigger_definition ;

my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;

my ($name, $triggered_and_triggering) = RunUniquePluginSub($pbs_config, 'AddTrigger', $file_name, $line, $trigger_definition) ;

# the trigger definition is either
#1/ the name of the triggered tree followed by simplified dependency regexes
#2/ a sub that returns (1, 'trigged_node_name') on success or (0, 'error message')

RegisterTrigger
	(
	  $file_name, $line
	, $package
	, $name
	, $triggered_and_triggering
	) ;
}

#-------------------------------------------------------------------------------

sub RegisterTrigger
{
my ($file_name, $line, $package, $name, $trigger_definition) = @_ ;
#~ print "RegisterTrigger $name in package $package.\n" ;

my $depender_sub ;
my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;

# verify we don't use the same trigger name twice
if(exists $triggers{$package})
	{
	for my $trigger (@{$triggers{$package}})
		{
		if
			(
			$trigger->{NAME} eq $name
			&& 
				(
				   $trigger->{FILE} ne $file_name
				|| $trigger->{LINE} ne $line
				)
			)
			{
			PrintError("'$name' name is already used for for trigger defined at $trigger->{FILE}:$trigger->{LINE}\n") ;
			PbsDisplayErrorWithContext($file_name,$line) ;
			PbsDisplayErrorWithContext($trigger->{FILE},$trigger->{LINE}) ;
			die ;
			}
		}
	}
	
my $trigger_sub ;
	
if('ARRAY' eq ref $trigger_definition)
	{
	unless(@$trigger_definition)
	{
	PrintError("Nothing defined in rule '$name' defined @ '$file_name,$line'.\n") ;
	PbsDisplayErrorWithContext($file_name,$line) ;
	die ;
	}

	my($triggered_node, @triggers) = @$trigger_definition;
	
	my @trigger_regexes ;
	
	unless(file_name_is_absolute($triggered_node) || $triggered_node =~ /^\.\//)
		{
		$triggered_node = "./$triggered_node" ;
		}
		
	$trigger_sub = sub 
			{
			my $trigger_to_check = shift ; 
			
			for my $trigger_regex (@triggers)
				{
				if($trigger_to_check =~ $trigger_regex)
					{
					return(1, $triggered_node) ;
					}
				}
				
			return(0, "'$trigger_to_check' didn't match any trigger definition") ;
			}
	}
else
	{
	if('CODE' eq ref $trigger_definition)
		{
		$trigger_sub = $trigger_definition ;
		}
	else
		{
		PrintError("Invalid triger definition @ '$file_name:$line'. Expecting an array ref or a code ref.\n") ;
		PbsDisplayErrorWithContext($file_name,$line) ;
		die ;
		}
	}
	
my $origin = '' ;
if($pbs_config->{ADD_ORIGIN})
	{
	$origin = ":$package:$file_name:$line" ;
	}
	
my $trigger_rule = 
	{
	  NAME                => $name
	, ORIGIN              => $origin
	, FILE                => $file_name
	, LINE                => $line
	, DEPENDER            => $trigger_sub
	, TEXTUAL_DESCRIPTION => $trigger_definition # keep a visual on how the rule was defined
	} ;

if(defined $pbs_config->{DEBUG_DISPLAY_TRIGGER_RULES})
	{
	PrintInfo("Registering trigger: $name$origin\n")  ;
	PrintInfo(DumpTree($trigger_rule, 'trigger rule:')) if defined $pbs_config->{DEBUG_DISPLAY_TRIGGER_RULE_DEFINITION} ;
	}

push @{$triggers{$package}}, $trigger_rule ;
}

#-------------------------------------------------------------------------------

sub DisplayAllTriggers
{
warn DumpTree(\%triggers, 'All triggers:') ;
}

#-------------------------------------------------------------------------------

my %imported_triggers ; # used to not re-import the same triggers

sub ImportTriggers
{
# this will import the triggers defined in another Pbsfile,
# it allows us to define the rules and the triggers in the same file
# sub defining the triggers must be called 'sub ExportTriggers'

my ($package, $file_name, $line) = caller() ;

$file_name =~ s/^'// ;
$file_name =~ s/'$// ;

for my $Pbsfile (@_)
	{
	if(exists $imported_triggers{"$package=>$Pbsfile"})
		{
		PrintWarning
			(
			"At $file_name:$line: Triggers from '$Pbsfile' have already been imported in package '$package'"
			. "at "
			. $imported_triggers{"$package=>$Pbsfile"}{FILE}
			. ':'
			. $imported_triggers{"$package=>$Pbsfile"}{LINE}
			. ". Ignoring.\n"
			) ;
			
		PbsDisplayErrorWithContext($file_name, $line) ;
		PbsDisplayErrorWithContext($imported_triggers{"$package=>$Pbsfile"}{FILE}, $imported_triggers{"$package=>$Pbsfile"}{LINE}) ;
		}
	else
		{
		open TRIGGERS, '<', $Pbsfile or die ERROR "Can't open '$Pbsfile' for Triggers import at $file_name:$line: $!\n" ;
		local $/ = undef ;
		my $pbsfile_code = <TRIGGERS> ;
		
		my ($trigger_exports_definition, undef, $skipped) = extract_codeblock($pbsfile_code,"{", '(?s).*?sub\s+ExportTriggers\s*(?={)');
		
		my $definition_line = $skipped =~ tr[\n][\n];
		
		close(TRIGGERS) ;
	
		if($trigger_exports_definition  eq '')
			{
			PrintWarning("No 'ExportTriggers' sub in '$Pbsfile' at $file_name:$line.\n") ;
			}
		else
			{
			my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;
			unless(defined $pbs_config->{NO_TRIGGER_IMPORT_INFO})
				{
				PrintInfo("Importing Triggers from '$Pbsfile:$definition_line' into package '$package' at $file_name:$line.\n") ;
			   }
			   
			$trigger_exports_definition =~ s/sub\s+ExportTriggers// ;
			
			$definition_line-- ; # reserve room for #line ...
			$trigger_exports_definition = "#line $definition_line $Pbsfile\npackage $package ;\n" . $trigger_exports_definition ;
			
			#~ PrintInfo("$trigger_exports_definition\n") ;
			
			eval $trigger_exports_definition ;
			die $@ if $@ ;
			
			$imported_triggers{"$package=>$Pbsfile"} = {FILE => $file_name, LINE => $line} ;
			}
		}
	}
}

#-------------------------------------------------------------------------------
1 ;

__END__
=head1 NAME

PBS::Triggers  -

=head1 SYNOPSIS

	# within a Pbsfile
	AddTrigger 'trigger_name', ['node_to_be triggered' => 'triggering_node_1', 'triggering_node_2'] ;
	
	ImportTriggers('/.../Pbsfile.pl') ; #import triggers from given file

=head1 DESCRIPTION

=head2 EXPORT

	AddTrigger ImportTriggers

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual.

=cut
