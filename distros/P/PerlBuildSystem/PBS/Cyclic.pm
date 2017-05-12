
package PBS::Cyclic ;
use PBS::Debug ;

use 5.006 ;

use strict ;
use warnings ;
use Data::Dumper ;
#~ use Carp ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.03' ;

use PBS::Output ;
use Devel::Cycle ;

#-------------------------------------------------------------------------------

sub GetUserCyclicText
{
my $cyclic_tree_root = shift ;
my $inserted_nodes   = shift ;
my $pbs_config       = shift ;

my $number_of_cycles = 0 ;
my $all_cycles = '' ;

my $cycle_display_sub = sub
	{
	my $cycles = shift ;
	
	my $indent = '' ;
	my $cycle = '' ;
	
	for my $node (@$cycles)
		{
		if($node->[0] eq 'HASH' && exists $node->[2]{__NAME})
			{
			my $name = $node->[2]{__NAME} ;
			
			$cycle .= "$indent'$name' " ;
			
			if($pbs_config->{ADD_ORIGIN})
				{
				$cycle .= "inserted at rule: '$inserted_nodes->{$name}{__INSERTED_AT}{INSERTION_RULE}'" ;
				}
				
			$cycle .= "\n" ;
			$indent .= ' ' ;
			}
		else
			{
			return ; # unintresting
			}
		}
		
	$all_cycles .= $cycle . "\n" ;
	$number_of_cycles++ ;
	} ;
	
find_cycle($cyclic_tree_root, $cycle_display_sub);

return($number_of_cycles, $all_cycles) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Cyclic  -

=head1 SYNOPSIS

  use PBS::Cyclic ;
  my $description_text = GetUserCyclicText($cyclic_tree, $inserted_nodes) ;

=head1 DESCRIPTION

Given a cyclic tree, GetUserCyclicText returns a description text:

	Cyclic dependency detected on './cyclic', induced by './cyclic3'.
	'./cyclic' inserted at rule: 'all:PBS::Runs::PBS_1:User:./cyclic_legend.pl:4'.
	  './cyclic2' inserted at rule: 'cyclic:PBS::Runs::PBS_1:User:./cyclic_legend.pl:6'.
	    './cyclic3' inserted at rule: 'cyclic2:PBS::Runs::PBS_1:User:./cyclic_legend.pl:7'.

=head2 EXPORT

Nothing.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

I<--origin> switch in B<PBS> reference manual.

=cut
