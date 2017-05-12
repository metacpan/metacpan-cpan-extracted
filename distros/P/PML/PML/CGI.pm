################################################################################
#
# CGI.pm (CGI.pm Access for PML)
#
################################################################################
#
# Package
#
################################################################################
package PML::CGI;
################################################################################
#
# Includes
#
################################################################################
use CGI;
use strict;
################################################################################
#
# Global Variables and Default Settings
#
################################################################################
use vars qw($VERSION $DATE);
$VERSION	= '0.01';
$DATE		= 'Tue Dec  7 14:19:05 1999';

my $pkg = 'cgi::';
my $tag;
################################################################################
#
# Code Start
#
################################################################################
foreach $tag (keys %CGI::EXPORT_TAGS)
{
	foreach (@{$CGI::EXPORT_TAGS{$tag}})
	{
		next if /^(:|print|header|redirect)/;
		PML->register(name=>"$pkg$_", token=>\&autotoken)
	}
}

PML->register(name=>"${pkg}url_swap", token=>\&url_swap);
PML->register(name=>"${pkg}url_http", token=>\&url_http);
PML->register(name=>"${pkg}url_https", token=>\&url_https);
PML->register(name=>"${pkg}header", token=>\&header);
PML->register(name=>"${pkg}redirect", token=>\&redirect);
################################################################################
#
# ==== init ==== ###############################################################
#
#   Arguments:
#	1) Class
#	2) PML Object
#
#     Returns:
#	None
#
# Description:
#	Prepares the PML object
#
################################################################################
sub init
{
	my ($class, $self) = @_;
	
	$self->v("${pkg}cgi", new CGI);
	
	if ($PML::DEBUG)
	{
		print STDERR "PML::CGI::init called with class=$class and self=$self\n";
	}
} # <-- End init -->
################################################################################
#
# ==== autotoken ==== ##########################################################
#
#   Arguments:
#	See PML Docs for a auto_parse callback
#
#     Returns:
#	Whatever the CGI sub returns
#
# Description:
#	Calls the correct CGI sub
#
################################################################################
sub autotoken
{
	my ($self, $token) = @_;
	my ($name, $a, $b) = @{$token->data};
	my ($code, @rv, $cgi);
	
	$cgi = $self->v("${pkg}cgi");
	$name =~ s/^$pkg//;
	$code = "\@rv = \$cgi->$name(\$self->tokens_execute(\$a))";
	eval "$code";
	
	return @rv if $token->context == PML->CONTEXT_LIST;
	return join ' ', @rv;
} # <-- End autotoken -->
################################################################################
#
# ==== url_swap ==== ###########################################################
#
#   Arguments:
#	See PML Docs for a auto_parse callback
#
#     Returns:
#	A sting that contains a url
#
# Description:
#	removes a script from the end of the current url and replaces it
#	with the script given in the args.
#
################################################################################
sub url_swap
{
	my ($self, $token) = @_;
	my ($name, $a, $b) = @{$token->data};
	my ($url, $script, $rv, $cgi);
	
	unless (@$a)
	{
		warn 'cgi::url_swap called without a url' . "\n";
		return;
	}
	
	$cgi = $self->v("${pkg}cgi");
	$script = $self->tokens_execute($a->[0]);
	$url = $cgi->url;
	
	$url =~ s/^(.*\/).*$/$1/;
	$rv = $url . $script;
	
	return $rv;
} # <-- End url_swap -->
################################################################################
#
# ==== url_http ==== ###########################################################
#
#   Arguments:
#	See PML Docs for a auto_parse callback
#
#     Returns:
#	A url
#
# Description:
#	A http version of the current url
#
################################################################################
sub url_http
{
	my ($self, $token) = @_;
	my ($name, $a, $b) = @{$token->data};
	my ($url, $rv, $cgi);
	
	$cgi = $self->v("${pkg}cgi");
	$url = $cgi->url;
	($rv = $url) =~ s/^https/http/i;
	
	return $rv;
} # <-- End url_http -->
################################################################################
#
# ==== url_https ==== ##########################################################
#
#   Arguments:
#	See PML Docs for a auto_parse callback
#
#     Returns:
#	A url
#
# Description:
#	A https version of the current url
#
################################################################################
sub url_https
{
	my ($self, $token) = @_;
	my ($name, $a, $b) = @{$token->data};
	my ($url, $rv, $cgi);
	
	$cgi = $self->v("${pkg}cgi");
	$url = $cgi->url;
	($rv = $url) =~ s/^http(?!s)/https/i;
	
	return $rv;
} # <-- End url_https -->
################################################################################
#
# ==== header ==== #############################################################
#
#   Arguments:
#	See PML Docs for a auto_parse callback
#
#     Returns:
#	None
#
# Description:
#	sends the http header to the browser
#
################################################################################
sub header
{
	my ($self, $token) = @_;
	my ($name, $a, $b) = @{$token->data};
	my @args = $self->tokens_execute($a);
	my $cgi;
	
	$cgi = $self->v("${pkg}cgi");
	$cgi->print($cgi->header(@args));
	
	if ($PML::DEBUG)
	{
		print STDERR 'cgi::header: calling header with: (';
		print STDERR join ', ', @args;
		print STDERR ")\n";
	}
	
	return undef;
} # <-- End header -->
################################################################################
#
# ==== redirect ==== ###########################################################
#
#   Arguments:
#	See PML Docs for a auto_parse callback
#
#     Returns:
#	None
#
# Description:
#	sends a redirect to the browser
#
################################################################################
sub redirect
{
	my ($self, $token) = @_;
	my ($name, $a, $b) = @{$token->data};
	my $cgi;
	
	$cgi = $self->v("${pkg}cgi");
	$cgi->print($cgi->redirect($self->tokens_execute($a)));
	return undef;
} # <-- End redirect -->
################################################################################
#                              END-OF-MODULE                                   #
################################################################################
1;
