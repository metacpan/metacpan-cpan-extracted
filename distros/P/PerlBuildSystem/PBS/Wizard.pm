
package PBS::Wizard ;
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
our @EXPORT = qw() ;
our $VERSION = '0.02' ;

use PBS::Output ;

#-------------------------------------------------------------------------------

sub RunWizard
{
# run the passed wizard or starts the menu wizard, which will look for all wizards
# in the PBSLib directories and display a menu for them (see menu.pl)

# made available to called wizard
our $lib_paths    = shift ; 
our $menu_command = shift ;

my  $wizard       = shift ;

# made available to called wizard
our $display_wizard_info = shift ;
our $display_wizard_help = shift ;

if($wizard ne '')
	{
	if($wizard =~ /\.pl$/)
		{
		my $located_source_name  ;
		
		if(-e $wizard)
			{
			$located_source_name = $wizard ;
			}
		else
			{
			for my $lib_path (@{$lib_paths})
				{
				$lib_path .= '/' unless $lib_path =~ /\/$/ ;
				
				if(-e $lib_path . 'Wizards/' . $wizard)
					{
					$located_source_name = $lib_path . 'Wizards/' . $wizard ;
					
					last ;
					}
				}
			}
			
		unless(defined $located_source_name)
			{
			my $paths = join ', ', @{$lib_paths} ;
			
			die ERROR("Can't locate '$wizard' in PBS libs [$paths]\n")  ;
			}
			
		our $wizard_location = $located_source_name ;
		
		unless (my $return = do $located_source_name) 
			{
			warn "couldn't parse '$located_source_name': $@" if $@;
			warn "couldn't do '$located_source_name': $!"    unless defined $return;
			warn "couldn't run '$located_source_name' (forgot to return '1'?)."       unless $return;
			}
		}
	else
		{
		$menu_command = $wizard ;
		RunWizard($lib_paths, $menu_command, 'menu.pl', $display_wizard_info, $display_wizard_help) ;
		}
	}
else
	{
	RunWizard($lib_paths, $menu_command, 'menu.pl', $display_wizard_info, $display_wizard_help) ;
	}
}

#----------------------------------------------------------------------
1 ;

__END__
=head1 NAME

PBS::Wizard  -

=head1 SYNOPSIS

	$> pbs -w

=head1 DESCRIPTION

wizard are little pel script that (might interract with the user) are mainly used to produce boilerplate Pbsfiles.

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut
