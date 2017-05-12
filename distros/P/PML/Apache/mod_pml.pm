################################################################################
#
# mod_pml.pm (Apache Content Handler for PML Files)
#
################################################################################
#
# Package
#
################################################################################
package Apache::mod_pml;
################################################################################
#
# Includes
#
################################################################################
use PML;
use strict;
use Apache::Constants qw(:common);
use Apache::ModuleConfig ();
use DynaLoader ();
################################################################################
#
# Constants
#
################################################################################
use constant VERSION		=> '0.1.1';
################################################################################
#
# Global Variables and Default Settings
#
################################################################################
use vars qw($VERSION $DATE $ID);
$VERSION	= VERSION;
$DATE		= 'Thu Jun  1 13:08:48 2000';
$ID		= '$Id: mod_pml.pm,v 1.3 2000/07/31 17:13:46 pjones Exp $';
################################################################################
#
# Code start
#
################################################################################
if ($ENV{MOD_PERL}) {
	no strict;
	@ISA = qw( DynaLoader );
	#__PACKAGE__->bootstap($VERSION);
}
################################################################################
#
# ==== handler ==== ############################################################
#
#   Arguments:
#	1) Apache::Request Object
#
#     Returns:
#	1) Apache Return Code
#
# Description:
#	This is the main entry point for mod_pml
#
################################################################################
sub handler
{
	my $r = shift;
	my ($file, $pml, $data);
	
	# make sure the content type is text/html
	unless ($r->content_type eq 'text/html') {
		return DECLINED;
	}
	
	# get the file we are talking about here
	$file = $r->filename;
	
	# check to make sure that the file exists
	unless (-e $r->finfo) {
		$r->log_error("no such file '$file'");
		return NOT_FOUND;
	}
	
	# make sure that the web user can read the file
	unless (-r _) {
		$r->log_error("webserver can't read file '$file': Permission denied");
		return FORBIDDEN;
	}
	
	# create the PML object
	$pml = new PML;
	
	# parse the file
	eval {$pml->parse($file)};
	
	# check for parse errors
	if ($@) {return SERVER_ERROR}
	
	# let pml code see the request object
	$pml->v('mod_pml::r', $r);
	
	# execute the pml
	$data = $pml->execute;
	
	# send the http header unless it was sent from PML
	unless ($pml->v('headers::sent')) {
		$r->send_http_header;
	}
	
	# son't return the data if this is a HEAD
	return OK if $r->header_only;
	
	# finaly return the data
	$r->print($data);
	
	return OK;
} # <-- End handler -->
################################################################################
#
# ==== apache_config_callback_pmlstore ==== ####################################
#
#   Arguments:
#	1) Cfg
#	2) parms
#	3) state (On|Off)
#
#     Returns:
#	None
#
# Description:
#	Remembers what the config is
#
################################################################################
sub apache_config_callback_pmlstore ($$$)
{
	my ($cfg, $parms, $state) = @_;
	
	unless ($state =~ /^On|Off$/i) {
		die "PMLStore On|Off\n";
	}
	
	$state = lc $state;
	$cfg->{'PMLStore'} = $state eq 'on' ? 1 : 0;
} # <-- End apache_config_callback_pmlstore -->
################################################################################
#                              END-OF-SCRIPT                                   #
################################################################################
=head1 NAME

mod_pml.pm

=head1 SYNOPSIS

Quick Usage

=head1 DESCRIPTION

What does it do?

=head1 OPTIONS

Long Usage

=head1 EXAMPLES

Example usage

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Peter J Jones
pjones@cpan.org

=cut

1;
