use strict;
use warnings;
use Test::More tests => 6;
use POE qw(Component::SmokeBox::Uploads::NNTP);
use Test::POE::Server::TCP;

my @msg;
while (<DATA>) {
  chomp;
  push @msg, $_;
}

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start 
			_upload 
			testd_registered
			testd_connected
			testd_disconnected
			testd_client_input
			testd_client_flushed
		  )],
  ],
  heap => { message => \@msg, },
);

$poe_kernel->run();
exit 0;

sub _start {
  $_[HEAP]->{server} = Test::POE::Server::TCP->spawn(
        address => '127.0.0.1',
        port => 0,
  );
  $_[HEAP]->{group_responses} = [ '0 0 0 perl.cpan.uploads', '1 0 1 perl.cpan.uploads' ];
  return;
}

sub testd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  $heap->{port} = $object->port();
  POE::Component::SmokeBox::Uploads::NNTP->spawn(
	event => '_upload',
	nntp  => '127.0.0.1',
	nntp_port => $heap->{port},
	poll => 10,
	options => { trace => 0 },
  );
  return;
}

sub testd_connected {
  my ($heap,$state,$id) = @_[HEAP,STATE,ARG0];
  pass($state);
  $heap->{server}->send_to_client( $id, "200 server ready - posting allowed" );
  return;
}

sub testd_disconnected {
  my $heap = $_[HEAP];
  pass("Client disconnected");
  $heap->{server}->shutdown();
  return;
}

sub testd_client_input {
  my ($kernel,$heap,$id,$input) = @_[KERNEL,HEAP,ARG0,ARG1];
  SWITCH: {
    if ( $input =~ /^GROUP /i ) {
	my ($cmd,$grp) = split /\s+/, $input;
	ok( $grp eq 'perl.cpan.uploads', 'group perl.cpan.uploads' );
	$heap->{server}->send_to_client( $id, '211 ' . shift @{ $heap->{group_responses} } );
	last SWITCH;
    }
    if ( $input =~ /^ARTICLE /i ) {
	my ($cmd,$num) = split /\s+/, $input;
	ok( $num eq '1', 'article 1' );
	$heap->{server}->send_to_client( $id, '220 1 <200809191347.m8JDldeX023652@pause.perl.org> article retrieved - head and body follow' );
	$heap->{send_article} = 1;
	last SWITCH;
    }
  }
  return;
}

sub testd_client_flushed {
  my ($kernel,$heap,$id) = @_[KERNEL,HEAP,ARG0];
  return unless $heap->{send_article};
  my $line = shift @{ $heap->{message} };
  if ( $line ) {
     $heap->{server}->send_to_client( $id, $line );
  }
  else {
     delete $heap->{send_article};
     $heap->{server}->send_to_client( $id, '.' );
  }
  return;
}

sub _upload {
  my ($sender,$heap,$upload) = @_[SENDER,HEAP,ARG0];
  ok( $upload eq 'B/BI/BINGOS/Task-POE-IRC-1.10.tar.gz', 'B/BI/BINGOS/Task-POE-IRC-1.10.tar.gz' );
  $poe_kernel->post( $sender, 'shutdown' );
  return;
}

__END__
Newsgroups: perl.cpan.testers,perl.cpan.uploads
Path: nntp.perl.org
Xref: nntp.perl.org perl.cpan.testers:2247083 perl.cpan.uploads:11387
Return-Path: <root@pause.perl.org>
Mailing-List: contact cpan-uploads-help@perl.org; run by ezmlm
Delivered-To: mailing list cpan-uploads@perl.org
Received: (qmail 2844 invoked from network); 19 Sep 2008 13:47:46 -0000
Received: from x1a.develooper.com (HELO x1.develooper.com) (216.52.237.111)
  by x6.develooper.com with SMTP; 19 Sep 2008 13:47:46 -0000
Received: (qmail 13406 invoked by uid 225); 19 Sep 2008 13:47:46 -0000
Delivered-To: cpan-uploads@perl.org
Received: (qmail 13397 invoked by alias); 19 Sep 2008 13:47:46 -0000
X-Spam-Status: No, hits=-2.6 required=8.0
	tests=BAYES_00
X-Spam-Check-By: la.mx.develooper.com
Received: from pause.fiz-chemie.de (HELO pause.perl.org) (195.149.117.110)
    by la.mx.develooper.com (qpsmtpd/0.28) with ESMTP; Fri, 19 Sep 2008 06:47:43 -0700
Received: from pause.perl.org (localhost.localdomain [127.0.0.1])
	by pause.perl.org (8.13.8/8.13.8/Debian-3) with ESMTP id m8JDld68023653;
	Fri, 19 Sep 2008 15:47:39 +0200
Received: (from root@localhost)
	by pause.perl.org (8.13.8/8.13.8/Submit) id m8JDldeX023652;
	Fri, 19 Sep 2008 15:47:39 +0200
Date: Fri, 19 Sep 2008 15:47:39 +0200
Message-ID: <200809191347.m8JDldeX023652@pause.perl.org>
MIME-Version: 1.0
Subject: CPAN Upload: B/BI/BINGOS/Task-POE-IRC-1.10.tar.gz
Content-Type: Text/Plain; Charset=UTF-8
Reply-To: cpan-uploads@perl.org
To: cpan-testers@perl.org, cpan-uploads@perl.org
Content-Transfer-Encoding: 8bit
From: upload@pause.perl.org (PAUSE)

The uploaded file

    Task-POE-IRC-1.10.tar.gz

has entered CPAN as

  file: $CPAN/authors/id/B/BI/BINGOS/Task-POE-IRC-1.10.tar.gz
  size: 13710 bytes
   md5: cfc777a180355eb74db7c264d5ebdd72

No action is required on your part
Request entered by: BINGOS (Chris Williams)
Request entered on: Fri, 19 Sep 2008 13:46:25 GMT
Request completed:  Fri, 19 Sep 2008 13:47:38 GMT

Thanks,
-- 
paused, v1047
