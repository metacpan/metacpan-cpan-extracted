package PLP::Backend::CGI;

use strict;
use warnings;

our $VERSION = '1.03';

use PLP;

# CGI initializer: opens SCRIPT_FILENAME
sub init {
	$PLP::print = 'print';
	$PLP::read = \&read;

	if (defined $ENV{PATH_TRANSLATED}) {
		# SCRIPT_* points to handler script (Apache CGI)
		# Run backwards through PATH_TRANSLATED to find target filename,
		# then get file (relative) by stripping PATH_INFO.
		my ($path, $rel) = (delete $ENV{PATH_TRANSLATED}, delete $ENV{PATH_INFO});
		my $path_info = '';
		while (not -f $path) {
			if (not $path =~ s/(\/+[^\/]*)$//) {
				warn "PLP: Not found: $path$path_info ($ENV{REQUEST_URI})\n";
				PLP::error(undef, 404);
				return;
			}
			# move last path element onto PATH_INFO
			$path_info = $1 . $path_info;
		}
		if ($path_info ne '') {
			$rel =~ s/\Q$path_info\E$//;
			$ENV{PATH_INFO} = $path_info;
		}
		$ENV{SCRIPT_FILENAME} = $path;
		$ENV{SCRIPT_NAME} = $rel;
	}
	elsif (not -f $ENV{SCRIPT_FILENAME}) {
		warn "PLP: Not found: $ENV{SCRIPT_FILENAME} ($ENV{REQUEST_URI})\n";
		PLP::error(undef, 404);
		return;
	}

	$ENV{"PLP_$_"} = $ENV{"SCRIPT_$_"} for qw/NAME FILENAME/;

	if (not -r $ENV{PLP_FILENAME}) {
		warn "PLP: Can't read: $ENV{PLP_FILENAME} ($ENV{REQUEST_URI})\n";
		PLP::error(undef, 403);
		return;
	}

	delete @ENV{
		grep /^REDIRECT_/, keys %ENV
	};

	my ($file, $dir) = File::Basename::fileparse($ENV{PLP_FILENAME});
	chdir $dir;

	$PLP::code = PLP::source($file, 0, undef, $ENV{PLP_FILENAME});
	return 1;
}

sub read ($) {
	my ($bytes) = @_;
	read *STDIN, my ($data), $bytes;
	return $data;
}

sub everything {
	PLP::clean();
	$_[0]->init() and PLP::start();
}

# This is run by the CGI script. (#!perl \n use PLP::Backend::CGI;)
sub import {
	$PLP::interface = $_[0];
	$_[0]->everything();
}

1;

=head1 NAME

PLP::Backend::CGI - CGI interface for PLP

=head1 SYNOPSIS

For most servers you'll need a script executable.
Example F</foo/bar/plp.cgi>:

    #!/usr/bin/perl
    use PLP::Backend::CGI;

Or install the C<plp.cgi> included with PLP.

=head2 Lighttpd

Add this to your configuration file (usually F</etc/lighttpd/lighttpd.conf>):

    server.modules += ("mod_cgi")
    cgi.assign += (".plp" => "/foo/bar/plp.cgi")
    server.indexfiles += ("index.plp")
    static-file.exclude-extensions += (".plp")

=head2 Apache

Enable I<mod_actions> and
setup F<httpd.conf> (in new installs just create F</etc/apache/conf.d/plp>) with:

    <IfModule mod_actions.c>
        ScriptAlias /PLP_COMMON/ /foo/bar/
        <Directory /foo/bar/>
            Options +ExecCGI
            Order allow,deny
            Allow from all
        </Directory>
        AddHandler plp-document plp
        Action plp-document /PLP_COMMON/plp.cgi
    </IfModule>

=head1 AUTHOR

Mischa POSLAWSKY <perl@shiar.org>

=head1 SEE ALSO

L<PLP>, L<PLP::Backend::FastCGI>

