package PBS::Rules::Dependers::Subpbs ;

use PBS::Debug ;

use 5.006 ;

use strict ;
use warnings ;
use Data::TreeDumper ;
use Carp ;
use File::Spec::Functions qw(:ALL) ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(GenerateSubpbsDepender) ;
our $VERSION = '0.01' ;

use File::Basename ;

use PBS::PBSConfig ;
use PBS::Output ;
use PBS::Constants ;
use PBS::Rules ;

#-------------------------------------------------------------------------------

sub GenerateSubpbsDepender
{
my ($file_name, $line, $package, $class, $rule_types, $name, $depender_definition, $builder_sub) = @_ ;

# sub pbs definition
for my $key (keys %$depender_definition)
	{
	if($key !~ /^[A-Z_]+$/)
		{
		Carp::carp ERROR("Invalid sub Pbs rule at: '$name'. Keys must be upper case. '$key' is not at $file_name:$line.\n") ;
		PbsDisplayErrorWithContext($file_name, $line) ;
		die ;
		}
	}
	
unless(exists $depender_definition->{NODE_REGEX})
	{
	Carp::carp ERROR("No 'NODE_REGEX' for '$name' at $file_name:$line.\n") ;
	PbsDisplayErrorWithContext($file_name, $line) ;
	die ;
	}
	
unless(exists $depender_definition->{PBSFILE})
	{
	Carp::carp ERROR("No 'PBSFILE' for '$name' at $file_name:$line.\n") ;
	PbsDisplayErrorWithContext($file_name, $line) ;
	die ;
	}
	
unless
	(
	   exists $depender_definition->{PACKAGE}
	&& defined $depender_definition->{PACKAGE} 
	&& '' eq ref $depender_definition->{PACKAGE}
	&& '' ne $depender_definition->{PACKAGE}
	)
	{
	Carp::carp ERROR("Invalid or missing 'PACKAGE' for '$name' at $file_name:$line.\n") ;
	PbsDisplayErrorWithContext($file_name, $line) ;
	die ;
	}
	
if(exists $depender_definition->{ALIAS})
	{
	if($depender_definition->{ALIAS} eq '')
		{
		Carp::carp ERROR("Empty alias for '$name' at $file_name:$line.\n") ;
		PbsDisplayErrorWithContext($file_name, $line) ;
		die ;
		}
	
	unless(file_name_is_absolute($depender_definition->{ALIAS}) || $depender_definition->{ALIAS} =~ /^\.\//)
		{
		$depender_definition->{ALIAS} = './' . $depender_definition->{ALIAS} ;
		}
	}
	
my $pbs_config = GetPbsConfig($package) ;

if(exists $depender_definition->{BUILD_DIRECTORY} && !file_name_is_absolute($depender_definition->{BUILD_DIRECTORY}))
	{
	$depender_definition->{BUILD_DIRECTORY} =~ s/^\.\/// ;
	$depender_definition->{BUILD_DIRECTORY} = $pbs_config->{BUILD_DIRECTORY} . '/' . $depender_definition->{BUILD_DIRECTORY} ;
	}
	
#~ unless(file_name_is_absolute($depender_definition->{PBSFILE}))
	#~ {
	#~ # make pbsfile full path
	#~ $depender_definition->{PBSFILE} =~ s/^\.\/// ;
	#~ my ($basename, $path, $ext) = File::Basename::fileparse($pbs_config->{PBSFILE}, ('\..*')) ;
	#~ $depender_definition->{PBSFILE} = $path. '/' . $depender_definition->{PBSFILE} ;
	#~ $depender_definition->{PBSFILE} =~ s/\/\//\//g ;
	#~ }
	
my $sub_pbs_dependent_regex ;

if(ref $depender_definition->{NODE_REGEX} eq 'Regexp')
	{
	$sub_pbs_dependent_regex = $depender_definition->{NODE_REGEX} ;
	}
else
	{
	PrintError "NODE_REGEX in rule '$name' @ '$file_name:$line' is not a perl regex.\n" ;
	PbsDisplayErrorWithContext($file_name,$line) ;
	die ;
	}

PBS::PBSConfig::CheckPackageDirectories($depender_definition) ;

return
	(
	sub 
		{
		my $dependent_to_check = shift ; 
		my $config             = shift ;
		my $tree               = shift ;
		
		# not used
		#~ my $inserted_nodes = shift ;
		#~ my $depender_definition = shift ; #usefull to display error messages
		
		if(defined $tree->{__PBS_CONFIG}{DEBUG_DISPLAY_DEPENDENCY_REGEX})
			{
			PrintInfo2("   $dependent_to_check =~ $depender_definition->{NODE_REGEX} [$sub_pbs_dependent_regex]. Subpbs rule '$name' @ $file_name:$line.\n") ;
			}
		
		$dependent_to_check =~ /^$sub_pbs_dependent_regex$/ && return ([1, $depender_definition]) ;
		
		return([0, "$dependent_to_check didn't match subpbs regex '$sub_pbs_dependent_regex'."]) ;
		}
	) ;
}

#-------------------------------------------------------------------------------
1 ;

__END__
=head1 NAME

PBS::Rules::Dependers::Subpbs -

=head1 DESCRIPTION

This package provides support function for B<PBS::Rules::Rules>

=head2 EXPORT

Nothing.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual.

=cut
