package PLP::Backend::Apache;

use strict;
use warnings;

our $VERSION = '1.00';

use PLP;

use constant MP2 => (
	defined $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} >= 2
);

BEGIN {
	if (MP2) {
		require Apache2::Const;
		require Apache2::RequestRec;
		require Apache2::RequestUtil;
		require Apache2::RequestIO;
		Apache2::Const->import(-compile => qw(
			HTTP_NOT_FOUND HTTP_FORBIDDEN OK
		));
	} else {
		require Apache::Constants;
	}
}

our $r;

# mod_perl initializer: returns 0 on success, Apache error code on failure
sub init {
	$r = shift;

	$PLP::print = 'PLP::Backend::Apache::print';
	$PLP::read = \&read;
	
	$ENV{PLP_FILENAME} = my $filename = $r->filename;
	
	unless (-f $filename) {
		return MP2 ? Apache2::Const::HTTP_NOT_FOUND() : Apache::Constants::NOT_FOUND();
	}
	unless (-r _) {
		return MP2 ? Apache2::Const::HTTP_FORBIDDEN() : Apache::Constants::FORBIDDEN();
	}
	
	$ENV{PLP_NAME} = $r->uri;

	$PLP::use_cache = $r->dir_config('PLPcache') !~ /^off$/i;
#S	$PLP::use_safe  = $r->dir_config('PLPsafe')  =~ /^on$/i;
	my $path = $r->filename();
	my ($file, $dir) = File::Basename::fileparse($path);
	chdir $dir;

	$PLP::code = PLP::source($file, 0, undef, $path);

	return 0; # OK
}

sub read ($) {
	my ($bytes) = @_;
	$r->read(my $data, $bytes);
	return $data;
}

# FAST printing under mod_perl
sub print {
	return unless grep length, @_;
	PLP::sendheaders() unless $PLP::sentheaders;
	$r->print(@_);
}

# This is the mod_perl handler.
sub handler {
	PLP::clean();
	$PLP::interface = __PACKAGE__;
	if (my $ret = init($_[0])) {
		return $ret;
	}
	#S PLP::start($_[0]);
	PLP::start();
	no strict 'subs';
	return MP2 ? Apache2::Const::OK() : Apache::Constants::OK();
}

1;

=head1 NAME

PLP::Backend::Apache - Apache mod_perl interface for PLP

=head1 SYNOPSIS

Naturally, you'll need to enable I<mod_perl>:

    apache-modconf apache enable mod_perl

Setup F<httpd.conf> (in new installs just create F</etc/apache/conf.d/plp>) with:

    <IfModule mod_perl.c>
        <Files *.plp>
            SetHandler perl-script
            PerlHandler PLP::Backend::Apache
            PerlSendHeader On
        </Files>
    </IfModule>

=head1 DESCRIPTION

=head2 Configuration directives

PLP behaviour can be configured by B<PerlSetVar> rules.
These can be added to a F<.htaccess> file or most any scope of server
configuration.  For example, to disable caching for a specific site:

	<Directory /var/www/somesite/>
		PerlSetVar PLPcache Off
	</Directory>

=over 16

=item PLPcache

Sets caching B<On>/B<Off>.
When caching, PLP saves your script in memory and doesn't re-read
and re-parse it if it hasn't changed. PLP will use more memory,
but will also run 50% faster.

B<On> is default, anything that isn't =~ /^off$/i is considered On.

=back

=head1 BUGS

With mod_perlB<2>, any new request will change the cwd for all processes.
This means that if you're running files from multiple directories,
you I<should not use the current path> for it may change at any time.

The bug has been confirmed with at least mod_perl 2.0.2/3/4 on Apache 2.2.3/8.
Using this backend on Apache2 is extremely discouraged until this is fixed.
Instead, L<the FastCGI backend|PLP::Backend::FastCGI> is recommended.

Apache1 does not show any problems.

=head1 AUTHOR

Mischa POSLAWSKY <perl@shiar.org>

=head1 SEE ALSO

L<PLP>, L<PLP::Backend::FastCGI>, L<mod_perl>

