################################################################################
#
# LWP.pm (LWP.pm Access for PML)
#
################################################################################
#
# Package
#
################################################################################
package PML::LWP;
################################################################################
#
# Includes
#
################################################################################
use LWP;
use LWP::UserAgent;
use strict;
################################################################################
#
# Global Variables and Default Settings
#
################################################################################
use vars qw($VERSION $DATE);
$VERSION	= '0.01';
$DATE		= 'Tue Dec  7 14:19:05 1999';

my $pkg = 'lwp::';
################################################################################
#
# Code Start
#
################################################################################
PML->register(name=>"${pkg}insert", token=>\&insert);
################################################################################
#
# ==== insert ==== #############################################################
#
#   Arguments:
#	See PML Docs for a auto_parse callback
#
#     Returns:
#	HTML
#
# Description:
#	Gets a page from a url and inserts the html into the currrent pml
#
################################################################################
sub insert
{
	my ($self, $token) = @_;
	my ($name, $a, $b) = @{$token->data};
	my ($ua, $res, $req, $url, @urls, $rv, $trv);
	
	@urls = $self->tokens_execute($a);
	@urls or return undef;
	
	$ua = new LWP::UserAgent;
	$ua->agent("PML LWP Access/$VERSION");
	$rv = '';
	
	foreach $url (@urls)
	{
		$req = new HTTP::Request GET => $url;
		$res = $ua->request($req);
		next unless $res->is_success;
		
		$trv = $res->content;
		$rv .= $trv;
	}

	return $rv;
} # <-- End insert -->
