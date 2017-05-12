
package PBS::Warp::Warp0 ;
use PBS::Debug ;

use strict ;
use warnings ;

use 5.006 ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

use PBS::Output ;
use PBS::Log ;
use PBS::Digest ;
use PBS::Constants ;
use PBS::Plugin;
use PBS::Warp;

use Cwd ;
use File::Path;
use Data::Dumper ;
use Data::Compare ;
use Data::TreeDumper ;
use Digest::MD5 qw(md5_hex) ;
use Time::HiRes qw(gettimeofday tv_interval) ;

#-------------------------------------------------------------------------------

sub WarpPbs
{
my ($targets, $pbs_config, $parent_config) = @_ ;
	
my ($build_result, $build_message, $dependency_tree, $inserted_nodes) ;
eval
	{
	($build_result, $build_message, $dependency_tree, $inserted_nodes)
		= PBS::PBS::Pbs
			(
			$pbs_config->{PBSFILE}
			, ''    # parent package
			, $pbs_config
			, $parent_config
			, $targets
			, undef # inserted files
			, "root_NO_WARP_pbs_$pbs_config->{PBSFILE}" # tree name
			, DEPEND_CHECK_AND_BUILD
			) ;
	} ;

die $@ if $@ ;

return($build_result, $build_message, $dependency_tree, $inserted_nodes) ;
}

#-----------------------------------------------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Warp::Warp0  -

=head1 DESCRIPTION

Run PBS without Warp.

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

=cut
