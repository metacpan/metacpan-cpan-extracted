package SAL::WebApplication;

# This module is licensed under the FDL (Free Document License)
# The complete license text can be found at http://www.gnu.org/copyleft/fdl.html
# Contains excerpts from various man pages, tutorials and books on perl
# UNDER CONSTRUCTION

use strict;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use SAL::DBI;
use SAL::Web;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = '3.03';
	@ISA = qw(Exporter);
	@EXPORT = qw();
	%EXPORT_TAGS = ();
	@EXPORT_OK = qw();
}
our @EXPORT_OK;

END { }

our %WebApplication = (
######################################
	'dbi_factory'	=> '',
	'cgi'		=> '',
	'gui'		=> '',
	'canvas'	=> '',
	'modes'		=> (),
	'default_mode'	=> '',
	'build_toolbar'	=> '',
	'build_html_header'	=> '',
######################################
);

# Setup accessors via closure (from perltooc manpage)
sub _classobj {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;
	no strict "refs";
	return \%$class;
}

for my $datum (keys %{ _classobj() }) {
	no strict "refs";
	*$datum = sub {
		my $self = shift->_classobj();
		$self->{$datum} = shift if @_;
		return $self->{$datum};
	}
}

##########################################################################################################################
# Constructors (Public)
sub new {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;
	my $self = {};

	bless($self, $class);

	# Set default object properties

	$self->{cgi} = new CGI;
	$self->{dbo_factory} = new SAL::DBI;
	$self->{gui} = new SAL::Web;
#	$self->{default_mode} = \&throw_error;

	# Send the mime header
	print "Content-type: text/html\n\n";

	return $self;
}

##########################################################################################################################
# Destructor (Public)
sub destruct {
	my $self = shift;

}

##########################################################################################################################
# Public Methods
sub register_default {
	my $self = shift;
	my $address = shift;

	if (! $address) { return 0; }

	$self->{default_mode} = $address;

	return 1;
}

sub register_mode {
	my $self = shift;
	my $mode = shift;
	my $address = shift;

	if (! $mode) { return 0; }
	if (! $address) { return 0; }

	$self->{modes}{$mode} = $address;

	return 1;
}

sub register_toolbar {
	my $self = shift;
	my $address = shift;

	if (! $address) { return 0; }

	$self->{build_toolbar} = $address;

	return 1;
}

sub register_html_header {
	my $self = shift;
	my $address = shift;

	if (! $address) { return 0; }

	$self->{build_html_header} = $address;

	return 1;
}

sub run {
	my $self = shift;
	my $mode = $self->{cgi}->param('mode') || '(unknown)';
	my $address;

	if ($mode ne '(unknown)') {
		$address = $self->{modes}{$mode};
	} else {
		$address = $self->{default_mode};
	}
	&$address();
}

sub throw_error {
	my $self = shift;
	my $message = shift || 'An unknown error has occurred.';
	print qq[<h2>Error:</h2>\n<p align=left>$message</p>];
	exit;
}

sub write {
	my $self = shift;
	my $data = shift;
	$self->{canvas} .= $data;
}

sub paint {
	my $self = shift;
	my $title = shift;
	my $canvas = $self->{canvas};
	my $toolbar = ' ';
	my $html_header = '<!-- HTML HEADER -->';

	if ($self->{build_toolbar} ne '') {
		my $toolbar_constructor = $self->{build_toolbar};
		$toolbar = &$toolbar_constructor();
	}

	if ($self->{build_html_header} ne '') {
		my $html_header_constructor = $self->{build_html_header};
		$html_header = &$html_header_constructor();
	}

	print qq[
<html>
<head>
<title>$title</title>
$html_header
</head>
<body>
<table border=0 width=100% cellspacing=0 cellpadding=2>
<tr>
<td valign=top align=left style="border-bottom: 3px double #000;">$title</td>
<td valign=top align=right style="border-bottom: 3px double #000;">$toolbar</td>
</tr>
</table>
$canvas
</body>
</html>
];
}

##########################################################################################################################
# Private Methods

1;
