use Test::More tests => 20;

{
  package TestPlugin;
  use strict;
  use Test::More;
  
  sub new {
    my $package = shift;
    return bless { @_ }, $package;
  }

  sub plugin_register {
    my ($self,$nntpd) = @_;
    $nntpd->plugin_register( $self, 'NNTPD', qw(all) );
    $nntpd->plugin_register( $self, 'NNTPC', qw(all) );
    pass('plugin_register');
    return 1;
  }

  sub plugin_unregister {
    pass('plugin_unregister');
    return 1;
  }

  sub NNTPD_connection {
    my ($self,$nntpd) = splice @_, 0, 2;
    my $id = ${ $_[0] };
    pass('NNTPD_connection');
    $nntpd->send_to_client( $id, '200 localhost - poe-nntpd 1.0 ready - (posting ok).' );
    return 1;
  }

  sub NNTPD_disconnected {
    pass('NNTPD_disconnected');
    return 1;
  }

  sub NNTPC_response {
    my ($self,$nntpd) = splice @_, 0, 2;
    my $text = ${ $_[1] };
    pass('Plugin: ' . $text);
    return 1;
  }

  sub NNTPD_posting {
    my ($self,$nntpd) = splice @_, 0, 2;
    my $id = ${ $_[0] };
    pass('nntpd_posting');
    $nntpd->send_to_client( $id, '235 article transferred ok' );
    return 1;
  }

  sub NNTPD_cmd_ihave {
    my ($self,$nntpd) = splice @_, 0, 2;
    my $id = ${ $_[0] };
    my $msg_id = ${ $_[1] };
    ok( $msg_id eq '<perl.cpan.testers-380197@nntp.perl.org>', 'msg_id' );
    $nntpd->send_to_client( $id, '335 send article to be transferred.  End with <CR-LF>.<CR-LF>' );
    return 1;
  }
}

my @msg;

while(<DATA>) {
  push @msg, $_;
}

use strict;
use POE qw(Wheel::SocketFactory Component::Client::NNTP);
use Socket;

require_ok('POE::Component::Server::NNTP');

POE::Session->create(
	inline_states => { _start => \&test_start, },
	package_states => [
		'main' => [qw(_failure 
			      _config_nntpd 
			      _shutdown 
			      nntpd_plugin_add
			      nntpd_plugin_del
			      nntpd_connection
			      nntpd_disconnected
			      nntp_connected
			      nntp_200
			      nntp_335
			      nntp_235
			      nntpd_registered)],
	],
	options => { trace => 0 },
	heap => { msg => \@msg, },
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  my $wheel = POE::Wheel::SocketFactory->new(
	BindAddress => '127.0.0.1',
	BindPort => 0,
	SuccessEvent => '_fake_success',
	FailureEvent => '_failure',
  );

  if ( $wheel ) {
	my $port = ( unpack_sockaddr_in( $wheel->getsockname ) )[0];
	$kernel->yield( '_config_nntpd' => $port );
	$wheel = undef;
	$kernel->delay( '_shutdown' => 60 );
	return;
  }
  return;
}

sub _failure {
  die "Couldn\'t allocate a listening port, giving up\n";
  return;
}

sub _shutdown {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->alarm_remove_all();
  $kernel->post( 'nntpd', 'shutdown' );
  $kernel->post( 'nntp-client', 'shutdown' );
  return;
}

sub _config_nntpd {
  my ($kernel,$heap,$port) = @_[KERNEL,HEAP,ARG0];
  my $poco = POE::Component::Server::NNTP->spawn( 
	alias => 'nntpd', 
	address => '127.0.0.1',
	port => $port,
	handle_connects => 0,
	options => { trace => 0 },
  );
  isa_ok( $poco, 'POE::Component::Server::NNTP' );
  isa_ok( $poco, 'POE::Component::Pluggable' );
  $heap->{port} = $port;
  return;
}

sub nntpd_registered {
  my ($kernel,$heap,$poco) = @_[KERNEL,HEAP,ARG0];
  isa_ok( $poco, 'POE::Component::Server::NNTP' );
  isa_ok( $poco, 'POE::Component::Pluggable' );
  ok( $poco->plugin_add( 'TestPlugin', TestPlugin->new() ), 'Plugin add TestPlugin' );
  POE::Component::Client::NNTP->spawn( 'nntp-client', { NNTPServer => '127.0.0.1', Port => $heap->{port} } );
  $kernel->post( 'nntp-client', 'register', 'all' );
  $kernel->post( 'nntp-client', 'connect' );
  return;
}

sub nntpd_plugin_add {
  isa_ok( $_[ARG1], 'TestPlugin' );
  return;
}

sub nntpd_plugin_del {
  isa_ok( $_[ARG1], 'TestPlugin' );
  return;
}

sub nntpd_connection {
  pass("Client connected");
  return;
}

sub nntpd_disconnected {
  pass("Client disconnected");
  $poe_kernel->yield( '_shutdown' );
  return;
}

sub nntp_connected {
  pass('nntp-client connected');
  return;
}

sub nntp_200 {
  my ($kernel,$sender,$text) = @_[KERNEL,SENDER,ARG0];
  warn "# 200 $text\n";
  pass($_[STATE]);
  $kernel->post( 'nntp-client', 'ihave', '<perl.cpan.testers-380197@nntp.perl.org>' );
  return;
}

sub nntp_335 {
  my ($kernel,$sender) = @_[KERNEL,SENDER];
  pass($_[STATE]);
  $kernel->post( 'nntp-client', 'send_post', $_[HEAP]->{msg} );
  return;
}

sub nntp_235 {
  pass($_[STATE]);
  $poe_kernel->yield( '_shutdown' );
  return;
}

__END__
Newsgroups: perl.cpan.testers
Path: nntp.perl.org
Xref: nntp.perl.org perl.cpan.testers:380197
Return-Path: <chris@bingosnet.co.uk>
Mailing-List: contact cpan-testers-help@perl.org; run by ezmlm
Delivered-To: mailing list cpan-testers@perl.org
Received: (qmail 6683 invoked from network); 29 Nov 2006 08:11:31 -0000
Received: from x1a.develooper.com (HELO x1.develooper.com) (216.52.237.111)
  by lists.develooper.com with SMTP; 29 Nov 2006 08:11:31 -0000
Received: (qmail 25090 invoked by uid 225); 29 Nov 2006 08:11:31 -0000
Delivered-To: cpan-testers@perl.org
Received: (qmail 25084 invoked by alias); 29 Nov 2006 08:11:30 -0000
X-Spam-Status: No, hits=-5.5 required=8.0
	tests=BAYES_00,FORGED_RCVD_HELO,NO_REAL_NAME,PERLBUG_CONF
X-Spam-Check-By: la.mx.develooper.com
Received-SPF: neutral (x1.develooper.com: local policy)
Received: from kidney-bingos.demon.co.uk (HELO canker.bingosnet.co.uk) (62.49.18.107)
    by la.mx.develooper.com (qpsmtpd/0.28) with ESMTP; Wed, 29 Nov 2006 00:11:26 -0800
Date: Wed, 29 Nov 2006 08:10:57 +0000
Subject: PASS POE-Component-Client-NNTP-1.05 i386-netbsd-thread-multi-64int 3.0
To: cpan-testers@perl.org
X-Reported-Via: Test::Reporter 1.27, via CPANPLUS 0.076
From: chris@bingosnet.co.uk
Message-ID: <perl.cpan.testers-380197@nntp.perl.org>

This distribution has been tested as part of the cpan-testers
effort to test as many new uploads to CPAN as possible.  See
http://testers.cpan.org/

Please cc any replies to cpan-testers@perl.org to keep other
test volunteers informed and to prevent any duplicate effort.
	
--

This report was machine-generated by CPAN::YACSmoke 0.0307.

------------------------------
ENVIRONMENT AND OTHER CONTEXT
------------------------------

Environment variables:

    AUTOMATED_TESTING = 1
    PATH = /usr/bin:/bin:/usr/pkg/bin:/usr/local/bin:/usr/X11R6/bin
    PERL5LIB = :/home/chris/.cpanplus/5.8.8/build/POE-0.9500/blib/lib:/home/chris/.cpanplus/5.8.8/build/POE-0.9500/blib/arch:/home/chris/.cpanplus/5.8.8/build/POE-0.9500/blib:/home/chris/.cpanplus/5.8.8/build/POE-0.9500/blib/lib:/home/chris/.cpanplus/5.8.8/build/POE-0.9500/blib/arch:/home/chris/.cpanplus/5.8.8/build/POE-0.9500/blib:/home/chris/.cpanplus/5.8.8/build/POE-Component-Client-NNTP-1.05/blib/lib:/home/chris/.cpanplus/5.8.8/build/POE-Component-Client-NNTP-1.05/blib/arch:/home/chris/.cpanplus/5.8.8/build/POE-Component-Client-NNTP-1.05/blib
    PERL5_CPANPLUS_IS_RUNNING = 8480
    PERL_MM_USE_DEFAULT = 1
    SHELL = /usr/pkg/bin/bash
    TERM = screen

Perl special variables (and OS-specific diagnostics, for MSWin32):

    Perl: $^X = /home/chris/dev/perl588/bin/perl
    UID:  $<  = 1001
    EUID: $>  = 1001
    GID:  $(  = 0 0
    EGID: $)  = 0 0


-------------------------------


--

Summary of my perl5 (revision 5 version 8 subversion 8) configuration:
  Platform:
    osname=netbsd, osvers=3.0, archname=i386-netbsd-thread-multi-64int
    uname='netbsd canker.bingosnet.co.uk 3.0 netbsd 3.0 (generic_laptop) #0: mon dec 19 01:08:52 utc 2005 builds@works.netbsd.org:homebuildsabnetbsd-3-0-releasei386200512182024z-objhomebuildsabnetbsd-3-0-releasesrcsysarchi386compilegeneric_laptop i386 '
    config_args=''
    hint=recommended, useposix=true, d_sigaction=define
    usethreads=define use5005threads=undef useithreads=define usemultiplicity=define
    useperlio=define d_sfio=undef uselargefiles=define usesocks=undef
    use64bitint=define use64bitall=undef uselongdouble=undef
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-fno-strict-aliasing -pipe -I/usr/pkg/include',
    optimize='-O',
    cppflags='-fno-strict-aliasing -pipe -I/usr/pkg/include'
    ccversion='', gccversion='3.3.3 (NetBSD nb3 20040520)', gccosandvers=''
    intsize=4, longsize=4, ptrsize=4, doublesize=8, byteorder=12345678
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=12
    ivtype='long long', ivsize=8, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=4, prototype=define
  Linker and Libraries:
    ld='cc', ldflags =' -Wl,-rpath,/usr/pkg/lib -Wl,-rpath,/usr/local/lib -L/usr/pkg/lib'
    libpth=/usr/pkg/lib /lib /usr/lib
    libs=-lgdbm -lm -lcrypt -lutil -lc -lposix -lpthread
    perllibs=-lm -lcrypt -lutil -lc -lposix -lpthread
    libc=/lib/libc.so, so=so, useshrplib=false, libperl=libperl.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=so, d_dlsymun=undef, ccdlflags='-Wl,-E '
    cccdlflags='-DPIC -fPIC ', lddlflags='--whole-archive -shared  -L/usr/pkg/lib'
