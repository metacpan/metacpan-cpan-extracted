use strict;
use POE qw(Component::Server::NNTP);

my %groups;

while(<DATA>) {
  chomp;
  push @{ $groups{'perl.cpan.testers'}->{'<perl.cpan.testers-381062@nntp.perl.org>'} }, $_;
}

my $nntpd = POE::Component::Server::NNTP->spawn( 
		alias   => 'nntpd', 
		posting => 0, 
		port    => 10119,
);

POE::Session->create(
  package_states => [
	'main' => [ qw(
			_start
			nntpd_connection
			nntpd_disconnected
			nntpd_cmd_post
			nntpd_cmd_ihave
			nntpd_cmd_slave
			nntpd_cmd_newnews
			nntpd_cmd_newgroups
			nntpd_cmd_list
			nntpd_cmd_group
			nntpd_cmd_article
	) ],
  ],
  options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{clients} = { };
  $kernel->post( 'nntpd', 'register', 'all' );
  return;
}

sub nntpd_connection {
  my ($kernel,$heap,$client_id) = @_[KERNEL,HEAP,ARG0];
  $heap->{clients}->{ $client_id } = { };
  return;
}

sub nntpd_disconnected {
  my ($kernel,$heap,$client_id) = @_[KERNEL,HEAP,ARG0];
  delete $heap->{clients}->{ $client_id };
  return;
}

sub nntpd_cmd_slave {
  my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
  $kernel->post( $sender, 'send_to_client', $client_id, '202 slave status noted' );
  return;
}

sub nntpd_cmd_post {
  my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
  $kernel->post( $sender, 'send_to_client', $client_id, '440 posting not allowed' );
  return;
}

sub nntpd_cmd_ihave {
  my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
  $kernel->post( $sender, 'send_to_client', $client_id, '435 article not wanted' );
  return;
}

sub nntpd_cmd_newnews {
  my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
  $kernel->post( $sender, 'send_to_client', $client_id, '230 list of new articles follows' );
  $kernel->post( $sender, 'send_to_client', $client_id, '.' );
  return;
}

sub nntpd_cmd_newgroups {
  my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
  $kernel->post( $sender, 'send_to_client', $client_id, '231 list of new newsgroups follows' );
  $kernel->post( $sender, 'send_to_client', $client_id, '.' );
  return;
}

sub nntpd_cmd_list {
  my ($kernel,$sender,$client_id) = @_[KERNEL,SENDER,ARG0];
  $kernel->post( $sender, 'send_to_client', $client_id, '215 list of newsgroups follows' );
  foreach my $group ( keys %groups ) {
	my $reply = join ' ', $group, scalar keys %{ $groups{$group} }, 1, 'n';
	$kernel->post( $sender, 'send_to_client', $client_id, $reply );
  }
  $kernel->post( $sender, 'send_to_client', $client_id, '.' );
  return;
}

sub nntpd_cmd_group {
  my ($kernel,$sender,$client_id,$group) = @_[KERNEL,SENDER,ARG0,ARG1];
  unless ( $group or exists $groups{lc $group} ) { 
     $kernel->post( $sender, 'send_to_client', $client_id, '411 no such news group' );
     return;
  }
  $group = lc $group;
  $kernel->post( $sender, 'send_to_client', $client_id, "211 1 1 1 $group selected" );
  $_[HEAP]->{clients}->{ $client_id } = { group => $group };
  return;
}

sub nntpd_cmd_article {
  my ($kernel,$sender,$client_id,$article) = @_[KERNEL,SENDER,ARG0,ARG1];
  my $group = 'perl.cpan.testers';
  if ( !$article and !defined $_[HEAP]->{clients}->{ $client_id}->{group} ) {
     $kernel->post( $sender, 'send_to_client', $client_id, '412 no newsgroup selected' );
     return;
  }
  $article = 1 unless $article;
  if ( $article !~ /^<.*>$/ and $article ne '1' ) {
     $kernel->post( $sender, 'send_to_client', $client_id, '423 no such article number' );
     return;
  }
  if ( $article =~ /^<.*>$/ and !defined $groups{$group}->{$article} ) {
     $kernel->post( $sender, 'send_to_client', $client_id, '430 no such article found' );
     return;
  }
  foreach my $msg_id ( keys %{ $groups{$group} } ) {
    $kernel->post( $sender, 'send_to_client', $client_id, "220 1 $msg_id article retrieved - head and body follow" );
    $kernel->post( $sender, 'send_to_client', $client_id, $_ ) for @{ $groups{$group}->{$msg_id } };
    $kernel->post( $sender, 'send_to_client', $client_id, '.' );
  }
  return;
}

__END__
Newsgroups: perl.cpan.testers
Path: nntp.perl.org
Date: Fri,  1 Dec 2006 09:27:56 +0000
Subject: PASS POE-Component-IRC-5.14 cygwin-thread-multi-64int 1.5.21(0.15642)
From: chris@bingosnet.co.uk
Message-ID: <perl.cpan.testers-381062@nntp.perl.org>

This distribution has been tested as part of the cpan-testers
effort to test as many new uploads to CPAN as possible.  See
http://testers.cpan.org/

