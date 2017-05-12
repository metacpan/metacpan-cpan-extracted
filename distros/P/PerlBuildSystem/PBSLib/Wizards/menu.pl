# WIZARD_GROUP
# WIZARD_NAME Menu
# WIZARD_DESCRIPTION Display a menu with all the wizards present in the wizard directories
# WIZARD_OFF

use strict ;
use warnings ;

use File::Find ;
use PBS::Output ;

#------------------------------------------------------------------------------

# made available to this wizard
our $menu_command ;
our $lib_paths ;

# made available to called wizard
our $display_wizard_info ;
our $display_wizard_help ;
our $wizard_location ;

my (%wizards, %wizard_names) ;
File::Find::find
	(
	{wanted => \&ParseWizard, no_chdir => 1, follow => 1}
	, map {"$_/Wizards"} @$lib_paths
	) ;

RunMenu() ;

#------------------------------------------------------------------------------

sub ParseWizard
{
my $wizard = $File::Find::name ;

if($wizard =~ /\.pl$/)
	{
	open WIZARD, '<', $wizard or die "Can't open wizard '$wizard': $!\n" ;
	
	my ($wizard_group, $wizard_name, $wizard_description, $wizard_off) = ('', '', '', 0) ;
	while(<WIZARD>)
		{
		$wizard_group       = $1 if(/#\s*WIZARD_GROUP\s+(.*)/) ;
		$wizard_name        = $1 if(/#\s*WIZARD_NAME\s+(.*)/) ;
		$wizard_description = $1 if(/#\s*WIZARD_DESCRIPTION\s+(.*)/) ;
		
		if(/#\s*WIZARD_OFF/)
			{
			$wizard_off++ ;
			last
			}
		}
		
	close(WIZARD) ;
	
	unless($wizard_off)
		{
		if($wizard_name ne '')
			{
			PrintInfo "Found Wizard '$wizard_name' @ '$wizard'\n" if $display_wizard_info ;
			
			unless(exists $wizard_names{$wizard_name})
				{
				$wizards{$wizard_group}{$wizard_name} = {FILE => $wizard, DESCRIPTION => $wizard_description} ;
				$wizard_names{$wizard_name} = $wizard ;
				}
			else
				{
				PrintWarning("'$wizard' uses name '$wizard_name' which is already used in '$wizard_names{$wizard_name}'. Skipping\n") ;
				}
			}
		else
			{
			#PrintWarning("Wizard '$wizard' has no name. Skipping\n") ;
			}
		}
	}
}

sub RunMenu
{
if(keys %wizards)
	{
	my $index = 1 ;
	my $menu = '' ;	

	my $longest_name = 0 ;
	my $number_of_wizards = 0 ; 
	
	for my $group (sort keys %wizards)
		{
		for my $name (keys %{$wizards{$group}})
			{
			$number_of_wizards++ ;
			$longest_name = length($name) if length($name) > $longest_name ;
			}
			
		}
	
	my $digit_alignement = length("$number_of_wizards") ;
	
	for my $group (sort keys %wizards)
		{
		$menu .= "= $group =\n" ;
		
		for my $name (sort keys %{$wizards{$group}})
			{
			$menu .= sprintf"  <%${digit_alignement}d> %-${longest_name}s: $wizards{$group}{$name}{DESCRIPTION}\n", $index, $name ;
			
			$wizard_names{$index} = $wizard_names{$name} ;
			$index++ ;
			}
			
		$menu .= "\n" ;
		}
		
	my $wizard_name ;
	
	unless(defined $menu_command)
		{
		PrintInfo($menu) ;
		PrintInfo("Choice: ") ;
		
		$wizard_name = <STDIN> ;
		chomp($wizard_name) ;
		}
	else
		{
		$wizard_name = $menu_command ;
		}
		
	if($wizard_name ne '')
		{
		if(exists $wizard_names{$wizard_name})
			{
			PrintInfo2 "Running '$wizard_names{$wizard_name}'\n" if $display_wizard_info ;
			
			PBS::Wizard::RunWizard
				(
				  $lib_paths
				, undef  
				, $wizard_names{$wizard_name}
				, undef
				, $display_wizard_help
				) ;
			}
		else
			{
			PrintError("No such wizard '$wizard_name'.\n") ;
			$menu_command = undef ;
			RunMenu() ;
			}
		}
	}
}

#--------------------------------------------------------------------------------------------
1 ;



