package PBS::Rules::Metarules ;

use PBS::Debug ;

use 5.006 ;

use strict ;
use warnings ;
use Data::TreeDumper ;
use Carp ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(GenerateMetaRule) ;
our $VERSION = '0.01' ;

use File::Basename ;

use PBS::Shell ;
use PBS::PBSConfig ;
use PBS::Output ;
use PBS::Constants ;
use PBS::Rules ;

#-------------------------------------------------------------------------------

sub GenerateMetaRule
{
my ($file_name, $line, $package, $class, $rule_types, $name, $depender_definition) = @_ ;

if('ARRAY' eq ref $depender_definition && 'CODE' eq ref $depender_definition->[0] && 'ARRAY' eq ref $depender_definition->[1] && '' eq ref $depender_definition->[2])
	{
	# argument types fine
	}
else
	{
	Carp::carp ERROR("Meta rules take an array argument. The first element is a function reference, the second element is a list of existing rule names and the third argument is the default rule name.\n") ;
	PbsDisplayErrorWithContext($file_name,$line) ;
	die ;
	}

my $meta_rule         = $depender_definition->[0] ; 
my @needed_rule_names = @{$depender_definition->[1]} ;
my $default_rule_name = $depender_definition->[2] ;

my $default_rule_is_part_of_the_rules = 0 ;

if(exists $PBS::Rules::package_rules{$package}{$class})
	{
	# Check if all the needed rules exist in the package
	my %existing_rules ;
	
	for my $rule (@{$PBS::Rules::package_rules{$package}{$class}})
		{
		$existing_rules{$rule->{NAME}} = $rule ;
		}
		
	my @rule_references ;
	for my $needed_rule_name (@needed_rule_names)
		{
		if($needed_rule_name eq $default_rule_name)
			{
			$default_rule_is_part_of_the_rules++ ;
			}

		unless(exists $existing_rules{$needed_rule_name})
			{
			Carp::carp ERROR("'$needed_rule_name', needed by rule '$name', doesn't exist.\n") ;
			PbsDisplayErrorWithContext($file_name,$line) ;
			die ;
			}
			
		push @rule_references, $existing_rules{$needed_rule_name} ;
		
		my $rule_already_tagged_as_slave = 0 ;
		for my $rule_type (@{$existing_rules{$needed_rule_name}{TYPE}})
			{
			$rule_already_tagged_as_slave = 1 if($rule_type eq META_SLAVE) ;
			}
			
		unless($rule_already_tagged_as_slave)
			{
			push @{$existing_rules{$needed_rule_name}{TYPE}}, META_SLAVE ;
			
			my $pbs_config = GetPbsConfig($package) ;

			if(defined $pbs_config->{DEBUG_DISPLAY_RULES})
				{
				PrintInfo "Rule '$name' is making rule '$needed_rule_name' META_SLAVE.\n" ;
				}
			}
		}
		
	unless($default_rule_is_part_of_the_rules)
		{
		Carp::carp ERROR("Default rule '$default_rule_name' is not part of the slave rules!\n") ;
		PbsDisplayErrorWithContext($file_name,$line) ;
		die ;
		}
		
	unless(exists $existing_rules{$default_rule_name})
		{
		Carp::carp ERROR("Default rule '$default_rule_name', needed by rule '$name', doesn't exist.\n") ;
		PbsDisplayErrorWithContext($file_name,$line) ;
		die ;
		}
		
	my @node_subs_from_meta_rule_generator ;
	
	my $meta_sub = # this is a depender
		sub
		{
		my $dependent      = shift ;
		my $config         = shift ;
		my $tree           = shift ;
		my $inserted_nodes = shift ;
		
		# call the meta rule sub passed as argument
		return
			(
			$meta_rule->($dependent, $config, $tree, $inserted_nodes, \@rule_references, $default_rule_name)
			) ;
		} ;
		
	return($meta_sub, \@node_subs_from_meta_rule_generator) ;
	}
else
	{
	Carp::carp ERROR("No rules to slave in [$package::$class] at: '$name'.") ;
	PbsDisplayErrorWithContext($file_name,$line) ;
	die ;
	}
	
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Rules::Metarules -

=head1 DESCRIPTION

This package provides support function for B<PBS::Rules::Rules>

=head2 EXPORT

Nothing.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual.

=cut
