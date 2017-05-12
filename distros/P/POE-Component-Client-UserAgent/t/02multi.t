#!/usr/bin/perl -w

# 02multi.t -- Send multiple requests and get responses.

# uncomment to get POE's debug output
# sub POE::Kernel::ASSERT_DEFAULT() { 1 }
# sub POE::Kernel::TRACE_DEFAULT() { 1 }

use strict;
use POE;
use POE::Component::Client::UserAgent;
use Test;

my $debuglevel = shift || 0;

POE::Component::Client::UserAgent::debug $debuglevel => '02multi.log' if $debuglevel;

my @urls = qw(
	http://www.hotmail.com/
	http://ar.clarin.com/diario/hoy/index_diario.html
	http://ar.clarin.com/ultimo_momento/notas/2001-03-01/m-254829.htm
	http://ar.clarin.com/ultimo_momento/notas/2001-03-01/m-254831.htm
	http://ar.clarin.com/ultimo_momento/notas/2001-03-01/m-254832.htm
	http://ar.clarin.com/ultimo_momento/canal_G1.html
	http://ar.clarin.com/diario/hoy/deportes.htm
	http://ar.clarin.com/diario/hoy/sociedad.htm
	http://ar.clarin.com/diario/hoy/internac.htm
	http://ar.clarin.com/diario/hoy/opinion.htm
	http://ar.clarin.com/diario/hoy/economia.htm
	http://ar.clarin.com/diario/hoy/politica.htm
	http://www.php.net/
	http://www.php.net/docs.php
	http://www.php.net/quickref.php
	http://www.php.net/support.php
	http://www.php.net/news.php
	http://www.php.net/projects.php
	http://www.php.net/links.php
	http://www.php.net/mirrors.php
	http://www.php.net/FAQ.php
	http://www.cs.washington.edu/
	http://www.cs.washington.edu/research/ahoy/
	http://www.cs.washington.edu/research/ahoy/doc/paper.html
	http://metacrawler.cs.washington.edu:6060/
	http://www.foobar.foo/research/ahoy/
	http://www.foobar.foo/foobar/foo/
	http://www.foobar.foo/baz/buzz.html
	http://www.cs.washington.edu/foobar/bar/baz.html
);

plan tests => @urls + 3;

POE::Session -> create (
	inline_states => {
		_start => \&_start,
		_stop => \&_stop,
		response => \&response,
	},
);

$poe_kernel -> run;

warn "%%% Kernel::run returned.\n" if $debuglevel >= 3;

ok 1;

exit 0;

sub _start
{
	warn "%%% Start event arrived.\n" if $debuglevel >= 3;
	warn "%%% Starting POE::Component::Client::UserAgent...\n" if $debuglevel >= 3;
	POE::Component::Client::UserAgent -> new(env_proxy => 1);
	warn "%%% Sending test requests...\n" if $debuglevel >= 3;
	my $postback = $_[SESSION] -> postback ('response');
	$_[KERNEL] -> post (useragent => request =>
		request => HTTP::Request -> new (GET => $_),
		response => $postback
	) foreach @urls;
	warn "%%% Shutting down POE::Component::Client::UserAgent...\n"
		if $debuglevel >= 3;
	$_[KERNEL] -> post (useragent => 'shutdown');
	ok 1;
}

sub _stop
{
	warn "%%% Stop event arrived.\n" if $debuglevel >= 3;
	ok 1;
}

sub response
{
	my ($request, $response, $entry) = @{$_[ARG1]};
	LWP::Debug::trace ("\n\t$request\n\t$response\n\t$entry");
	warn "%%% Response returned.\n" if $debuglevel >= 3;
	warn $request -> url -> as_string . "\n\t" .
		$response -> code . ' ' . $response -> message . "\n" if $debuglevel >= 1;
	ok 1 unless $response -> is_redirect;
}
