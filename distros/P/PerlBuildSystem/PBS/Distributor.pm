
package PBS::Distributor ;

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
our @EXPORT = qw() ;
our $VERSION = '0.01' ;

use PBS::Output ;

#-------------------------------------------------------------------------------

sub new
{
my $class = shift ;

my $distributor_data = shift ;
my $distributor_definition = shift ;

unless(ref $distributor_data eq 'ARRAY')
	{
	die ERROR "PBS::Distributor only accepts an array of shells. File: '$distributor_definition'.\n" ;
	}

return
	(
	bless 
		{
		  DATA => $distributor_data
		, DEFINITION => $distributor_definition
		}
		, $class
	) ;
}

#-----------------------------------------------------------------------------

sub Setup
{
# the distributor initiolisation is two folded because PBS can:
# 1/ get an already build distributor that needs to be setup
# 2/ get a standard file to create a PBS::Distributor

my ($this, $pbs_config, $build_sequence) = @_ ;

if(@{$this->{DATA}} == 0)
	{
	my $jobs = $pbs_config->{JOBS} || 1 ;
	
	for (1 .. $jobs)	
		{
		push @{$this->{DATA}}, new PBS::Shell() ;
		}
	}
}

#-----------------------------------------------------------------------------

sub GetNumberOfShells
{
my $this = shift ;
return(+ @{$this->{DATA}}) ;
}

#-----------------------------------------------------------------------------

sub GetShell
{
my ($this, $shell_number) = @_ ;

if($shell_number > @{$this->{DATA}} || $shell_number < 0)
	{
	use Carp ;
	
	confess ERROR "Requesting unexistant shell from distributor." ;
	}

return($this->{DATA}[$shell_number]) ;
}

#-----------------------------------------------------------------------------

sub GetInfo
{
return(__PACKAGE__) ;
}

#-------------------------------------------------------------------------------

sub CreateDistributor
{
my $pbs_config = shift ;
my $build_sequence = shift ;

my $distributor_definition= $pbs_config->{DISTRIBUTE} ;

my $distributor ;

if(defined $distributor_definition)
	{
	PrintInfo("Distributed build, using settings from '$distributor_definition'.\n") ;
	
	my $file_body  = <<EOT ;
use strict ;
use warnings ;
use PBS::Constants ;
use PBS::Shell ;
use PBS::Output ;
use PBS::Rules ;
use PBS::Triggers ;
use PBS::PostBuild ;
use PBS::PBSConfig ;
use PBS::Config ;
use PBS::Check ;
use PBS::PBS ;
use PBS::Digest;

#line 0 '$distributor_definition'
EOT
	{
	open(FILE, '<', $distributor_definition) or confess "Error opening '$distributor_definition': $!\n" ;
	local $/ = undef ;
	$file_body .= <FILE> ;
	close(FILE) ;
	}
	
	$distributor = eval $file_body ;
	
	die ERROR $@ if $@ ;
	
	if(ref($distributor) !~ /^PBS::Distributor/)
		{
		$distributor = new PBS::Distributor($distributor, $distributor_definition) ;
		}
	# else
		# we can get a distributor directely from the distributor file
	}
else
	{
	$distributor = new PBS::Distributor([], '') ;
	}
	
$distributor->Setup($pbs_config, $build_sequence) ;

return($distributor) ;
}

#-------------------------------------------------------------------------------

1 ;


__END__
=head1 NAME

PBS::Distributor  - distributes PBS builder

=head1 SYNOPSIS

None

=head1 DESCRIPTION

used internaly by PBS::Build::Forked.

=head2 EXPORT

None

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual.

=cut

