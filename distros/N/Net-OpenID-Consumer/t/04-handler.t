#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 180;

# use lib '/home/rfc/src/git/Net-OpenID-Consumer/lib';
# use lib '/home/rfc/src/git/Net-OpenID-Common/lib';
use lib 't/lib';

use Net::OpenID::Consumer;
print $INC{'Net/OpenID/Consumer.pm'},"\n";
sub fake_verified_identity {
    # extremely simplified version that only looks at .mode and .identity
    # and does not do any discovery/check_authentication callouts
    my $csr = shift;
    return $csr->_fail("bad_mode") unless $csr->_message_mode_is("id_res");
    return $csr->_fail("no_identity")
      unless my $id = $csr->message('identity');

    # pretend everything worked
    my $v = Net::OpenID::VerifiedIdentity->new(consumer => $csr, signed_fields => {});
    $v->{'identity'} = $csr->message('identity');
    return $v;
}

{
    no warnings 'redefine';
    *Net::OpenID::Consumer::verified_identity = \&fake_verified_identity;
}

my $the_log = '';

my @common_callbacks = (
      not_openid => sub { $the_log .= '!NOT'; },
      cancelled  => sub { $the_log .= '!CAN'; },
      verified   => sub { my $url = $_[0]->url; $the_log .= "!VER($url)"; },
      error      => sub { $the_log .= "!ERR($_[0]: $_[1])"; },
  );
my $the_csr;
my @handlers = (
   broken_hsr1 => sub {
      $the_csr->handle_server_response(
         @common_callbacks,
         setup_needed => sub { 'dontcare'; },
         setup_required => sub { 'dontcare'; },
        );
 },
   broken_hsr2 => sub {
      $the_csr->handle_server_response(
         @common_callbacks,
        );
 },
   broken_hsr3 => sub {
      $the_csr->handle_server_response(
         @common_callbacks,
         setup_needed => sub { 'dontcare'; },
         biteme => sub { 'dontcare'; },
        );
 },
   broken_hsr4 => sub {
      $the_csr->handle_server_response(
         @common_callbacks,
         setup_required => sub { 'dontcare'; },
         biteme => sub { 'dontcare'; },
        );
 },
   hsr => sub {
      $the_csr->handle_server_response(
         @common_callbacks,
         setup_needed => sub { my $u = $the_csr->user_setup_url || ''; $the_log .= "!IMM($u)"; },
        );
 },
   hsr_old => sub {
      $the_csr->handle_server_response(
         @common_callbacks,
         setup_required => sub { my $u = shift || ''; $the_log .= "!IMM($u)"; },
        );
 },
   diy => sub {
      # current DIY code
      unless ($the_csr->is_server_response) {
         $the_log .= "!NOT";
    }
      elsif ($the_csr->setup_needed) {
         my $u = $the_csr->user_setup_url || ''; 
         $the_log .= "!IMM($u)";
    }
      elsif ($the_csr->user_cancel) {
         # restore web app state to prior to check_url
         $the_log .= "!CAN";
    }
      elsif (my $vident = $the_csr->verified_identity) {
         my $url = $vident->url;
         $the_log .= "!VER($url)";
    }         
      else {
         my $e = $the_csr->err;
         $the_log .= "!ERR($e)";
    }
 },
   diy_old => sub {
      # DIY code from 1.03 synopsis
      if (my $url = $the_csr->user_setup_url) {
         $the_log .= "!IMM($url)";
    }
      elsif ($the_csr->user_cancel) {
         # restore web app state to prior to check_url
         $the_log .= "!CAN";
    }
      elsif (my $vident = $the_csr->verified_identity) {
         my $url = $vident->url;
         $the_log .= "!VER($url)";
    }         
      else {
         my $e = $the_csr->err;
         $the_log .= "!ERR($e)";
    }
 },
);

my @messages =
  qw(
    immed_fail_1
      openid.mode=id_res&openid.user_setup_url=http://setup.com
    immed_fail_2
      openid.mode=setup_needed
    immed_fail_2s
      openid.mode=setup_needed&openid.user_setup_url=http://setup.com
    cancel
      openid.mode=cancel&openid.user_setup_url=http://setup.com
    badverify
      openid.mode=id_res
    verify
      openid.mode=id_res&openid.identity=http://io.com/rufus
    real_bad_mode
      openid.mode=only_slightly_biffle_dinked
    provider_error
      openid.mode=error&openid.error=We%20are%20out%20of%20spoons.
  );
my $i;
my %messages = @messages;
@messages = do { $i=0; grep {++$i % 2} @messages };

my %handlers = @handlers;
@handlers = do { $i=0; grep {++$i % 2} @handlers };


# Nonsense combinations
my %nonsense = map {($_,1)} qw(1immed_fail_2 1immed_fail_2s 1provider_error 2immed_fail_1);


sub try {
    my ($hkey,$msg,$vm,$v2c) = @_;
    $the_csr = Net::OpenID::Consumer->new
      (
       $v2c ? (minimum_version => 2) : (),
       args => { (!$vm ? () : ("openid.ns", ($vm >= 2 ? "http://specs.openid.net/auth/$vm" : "http://openid.net/signon/$vm"))),
                 map {s/%20/ /g; split '='} split '&',$messages{$msg}
               },
      );
    $the_log = '';
    $handlers{$hkey}->();
    return $the_log;
}

sub trydie {
   return eval { try(@_) or 'hmm'; } || $@;
}
# for my $m (@messages) {
#     for my $vm (undef,'1.0','1.1','2.0') {
#         for my $v2c (undef, 2) {
#             for my $h (@handlers) {
#                 # next unless $h eq 'diy' || $h eq 'hsr';
#                 print 
#                   ($nonsense{($vm  ? substr($vm,0,1) : '1') . $m} ? '# ' : ''),
#                   "is(try(", 
#                   sprintf('%9s,%16s,%5s,%5s',map {defined($_) ? "'$_'" : 'undef'} $h,$m,$vm,$v2c),
#                   "),'",
#                   try($h,$m,$vm,$v2c),"');\n";
#             }
#         }
#     }
# }

like(trydie('broken_hsr1','immed_fail_1',undef,undef),qr/^Cannot have both setup_needed and setup_required/);
like(trydie('broken_hsr2','immed_fail_1',undef,undef),qr/^No setup_needed callback/);
like(trydie('broken_hsr3','immed_fail_1',undef,undef),qr/^Unknown callbacks: *biteme/,'with setup_needed');
like(trydie('broken_hsr4','immed_fail_1',undef,undef),qr/^Unknown callbacks: *biteme/,'with setup_required');

is(try(    'hsr',  'immed_fail_1',undef,undef),'!IMM(http://setup.com)');
is(try('hsr_old',  'immed_fail_1',undef,undef),'!IMM(http://setup.com)');
is(try(    'diy',  'immed_fail_1',undef,undef),'!IMM(http://setup.com)');
is(try('diy_old',  'immed_fail_1',undef,undef),'!IMM(http://setup.com)');
is(try(    'hsr',  'immed_fail_1',undef,  '2'),'!NOT');
is(try('hsr_old',  'immed_fail_1',undef,  '2'),'!NOT');
is(try(    'diy',  'immed_fail_1',undef,  '2'),'!NOT');
is(try('diy_old',  'immed_fail_1',undef,  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',  'immed_fail_1','1.0',undef),'!IMM(http://setup.com)');
is(try('hsr_old',  'immed_fail_1','1.0',undef),'!IMM(http://setup.com)');
is(try(    'diy',  'immed_fail_1','1.0',undef),'!IMM(http://setup.com)');
is(try('diy_old',  'immed_fail_1','1.0',undef),'!IMM(http://setup.com)');
is(try(    'hsr',  'immed_fail_1','1.0',  '2'),'!NOT');
is(try('hsr_old',  'immed_fail_1','1.0',  '2'),'!NOT');
is(try(    'diy',  'immed_fail_1','1.0',  '2'),'!NOT');
is(try('diy_old',  'immed_fail_1','1.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',  'immed_fail_1','1.1',undef),'!IMM(http://setup.com)');
is(try('hsr_old',  'immed_fail_1','1.1',undef),'!IMM(http://setup.com)');
is(try(    'diy',  'immed_fail_1','1.1',undef),'!IMM(http://setup.com)');
is(try('diy_old',  'immed_fail_1','1.1',undef),'!IMM(http://setup.com)');
is(try(    'hsr',  'immed_fail_1','1.1',  '2'),'!NOT');
is(try('hsr_old',  'immed_fail_1','1.1',  '2'),'!NOT');
is(try(    'diy',  'immed_fail_1','1.1',  '2'),'!NOT');
is(try('diy_old',  'immed_fail_1','1.1',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr',  'immed_fail_1','2.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
# is(try('hsr_old',  'immed_fail_1','2.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
# is(try(    'diy',  'immed_fail_1','2.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
# is(try('diy_old',  'immed_fail_1','2.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
# is(try(    'hsr',  'immed_fail_1','2.0',  '2'),'!ERR(no_identity: Identity is missing from ID provider response.)');
# is(try('hsr_old',  'immed_fail_1','2.0',  '2'),'!ERR(no_identity: Identity is missing from ID provider response.)');
# is(try(    'diy',  'immed_fail_1','2.0',  '2'),'!ERR(no_identity: Identity is missing from ID provider response.)');
# is(try('diy_old',  'immed_fail_1','2.0',  '2'),'!ERR(no_identity: Identity is missing from ID provider response.)');
# is(try(    'hsr',  'immed_fail_2',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('hsr_old',  'immed_fail_2',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'diy',  'immed_fail_2',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('diy_old',  'immed_fail_2',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr',  'immed_fail_2',undef,  '2'),'!NOT');
# is(try('hsr_old',  'immed_fail_2',undef,  '2'),'!NOT');
# is(try(    'diy',  'immed_fail_2',undef,  '2'),'!NOT');
# is(try('diy_old',  'immed_fail_2',undef,  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr',  'immed_fail_2','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('hsr_old',  'immed_fail_2','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'diy',  'immed_fail_2','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('diy_old',  'immed_fail_2','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr',  'immed_fail_2','1.0',  '2'),'!NOT');
# is(try('hsr_old',  'immed_fail_2','1.0',  '2'),'!NOT');
# is(try(    'diy',  'immed_fail_2','1.0',  '2'),'!NOT');
# is(try('diy_old',  'immed_fail_2','1.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr',  'immed_fail_2','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('hsr_old',  'immed_fail_2','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'diy',  'immed_fail_2','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('diy_old',  'immed_fail_2','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr',  'immed_fail_2','1.1',  '2'),'!NOT');
# is(try('hsr_old',  'immed_fail_2','1.1',  '2'),'!NOT');
# is(try(    'diy',  'immed_fail_2','1.1',  '2'),'!NOT');
# is(try('diy_old',  'immed_fail_2','1.1',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',  'immed_fail_2','2.0',undef),'!IMM()');
is(try('hsr_old',  'immed_fail_2','2.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'diy',  'immed_fail_2','2.0',undef),'!IMM()');
is(try('diy_old',  'immed_fail_2','2.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',  'immed_fail_2','2.0',  '2'),'!IMM()');
is(try('hsr_old',  'immed_fail_2','2.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'diy',  'immed_fail_2','2.0',  '2'),'!IMM()');
is(try('diy_old',  'immed_fail_2','2.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr', 'immed_fail_2s',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('hsr_old', 'immed_fail_2s',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'diy', 'immed_fail_2s',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('diy_old', 'immed_fail_2s',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr', 'immed_fail_2s',undef,  '2'),'!NOT');
# is(try('hsr_old', 'immed_fail_2s',undef,  '2'),'!NOT');
# is(try(    'diy', 'immed_fail_2s',undef,  '2'),'!NOT');
# is(try('diy_old', 'immed_fail_2s',undef,  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr', 'immed_fail_2s','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('hsr_old', 'immed_fail_2s','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'diy', 'immed_fail_2s','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('diy_old', 'immed_fail_2s','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr', 'immed_fail_2s','1.0',  '2'),'!NOT');
# is(try('hsr_old', 'immed_fail_2s','1.0',  '2'),'!NOT');
# is(try(    'diy', 'immed_fail_2s','1.0',  '2'),'!NOT');
# is(try('diy_old', 'immed_fail_2s','1.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr', 'immed_fail_2s','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('hsr_old', 'immed_fail_2s','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'diy', 'immed_fail_2s','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('diy_old', 'immed_fail_2s','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr', 'immed_fail_2s','1.1',  '2'),'!NOT');
# is(try('hsr_old', 'immed_fail_2s','1.1',  '2'),'!NOT');
# is(try(    'diy', 'immed_fail_2s','1.1',  '2'),'!NOT');
# is(try('diy_old', 'immed_fail_2s','1.1',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr', 'immed_fail_2s','2.0',undef),'!IMM(http://setup.com)');
is(try('hsr_old', 'immed_fail_2s','2.0',undef),'!IMM(http://setup.com)');
is(try(    'diy', 'immed_fail_2s','2.0',undef),'!IMM(http://setup.com)');
is(try('diy_old', 'immed_fail_2s','2.0',undef),'!IMM(http://setup.com)');
is(try(    'hsr', 'immed_fail_2s','2.0',  '2'),'!IMM(http://setup.com)');
is(try('hsr_old', 'immed_fail_2s','2.0',  '2'),'!IMM(http://setup.com)');
is(try(    'diy', 'immed_fail_2s','2.0',  '2'),'!IMM(http://setup.com)');
is(try('diy_old', 'immed_fail_2s','2.0',  '2'),'!IMM(http://setup.com)');
is(try(    'hsr',        'cancel',undef,undef),'!CAN');
is(try('hsr_old',        'cancel',undef,undef),'!CAN');
is(try(    'diy',        'cancel',undef,undef),'!CAN');
is(try('diy_old',        'cancel',undef,undef),'!CAN');
is(try(    'hsr',        'cancel',undef,  '2'),'!NOT');
is(try('hsr_old',        'cancel',undef,  '2'),'!NOT');
is(try(    'diy',        'cancel',undef,  '2'),'!NOT');
is(try('diy_old',        'cancel',undef,  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',        'cancel','1.0',undef),'!CAN');
is(try('hsr_old',        'cancel','1.0',undef),'!CAN');
is(try(    'diy',        'cancel','1.0',undef),'!CAN');
is(try('diy_old',        'cancel','1.0',undef),'!CAN');
is(try(    'hsr',        'cancel','1.0',  '2'),'!NOT');
is(try('hsr_old',        'cancel','1.0',  '2'),'!NOT');
is(try(    'diy',        'cancel','1.0',  '2'),'!NOT');
is(try('diy_old',        'cancel','1.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',        'cancel','1.1',undef),'!CAN');
is(try('hsr_old',        'cancel','1.1',undef),'!CAN');
is(try(    'diy',        'cancel','1.1',undef),'!CAN');
is(try('diy_old',        'cancel','1.1',undef),'!CAN');
is(try(    'hsr',        'cancel','1.1',  '2'),'!NOT');
is(try('hsr_old',        'cancel','1.1',  '2'),'!NOT');
is(try(    'diy',        'cancel','1.1',  '2'),'!NOT');
is(try('diy_old',        'cancel','1.1',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',        'cancel','2.0',undef),'!CAN');
is(try('hsr_old',        'cancel','2.0',undef),'!CAN');
is(try(    'diy',        'cancel','2.0',undef),'!CAN');
is(try('diy_old',        'cancel','2.0',undef),'!CAN');
is(try(    'hsr',        'cancel','2.0',  '2'),'!CAN');
is(try('hsr_old',        'cancel','2.0',  '2'),'!CAN');
is(try(    'diy',        'cancel','2.0',  '2'),'!CAN');
is(try('diy_old',        'cancel','2.0',  '2'),'!CAN');
is(try(    'hsr',     'badverify',undef,undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('hsr_old',     'badverify',undef,undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'diy',     'badverify',undef,undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('diy_old',     'badverify',undef,undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'hsr',     'badverify',undef,  '2'),'!NOT');
is(try('hsr_old',     'badverify',undef,  '2'),'!NOT');
is(try(    'diy',     'badverify',undef,  '2'),'!NOT');
is(try('diy_old',     'badverify',undef,  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',     'badverify','1.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('hsr_old',     'badverify','1.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'diy',     'badverify','1.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('diy_old',     'badverify','1.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'hsr',     'badverify','1.0',  '2'),'!NOT');
is(try('hsr_old',     'badverify','1.0',  '2'),'!NOT');
is(try(    'diy',     'badverify','1.0',  '2'),'!NOT');
is(try('diy_old',     'badverify','1.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',     'badverify','1.1',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('hsr_old',     'badverify','1.1',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'diy',     'badverify','1.1',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('diy_old',     'badverify','1.1',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'hsr',     'badverify','1.1',  '2'),'!NOT');
is(try('hsr_old',     'badverify','1.1',  '2'),'!NOT');
is(try(    'diy',     'badverify','1.1',  '2'),'!NOT');
is(try('diy_old',     'badverify','1.1',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',     'badverify','2.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('hsr_old',     'badverify','2.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'diy',     'badverify','2.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('diy_old',     'badverify','2.0',undef),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'hsr',     'badverify','2.0',  '2'),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('hsr_old',     'badverify','2.0',  '2'),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'diy',     'badverify','2.0',  '2'),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try('diy_old',     'badverify','2.0',  '2'),'!ERR(no_identity: Identity is missing from ID provider response.)');
is(try(    'hsr',        'verify',undef,undef),'!VER(http://io.com/rufus)');
is(try('hsr_old',        'verify',undef,undef),'!VER(http://io.com/rufus)');
is(try(    'diy',        'verify',undef,undef),'!VER(http://io.com/rufus)');
is(try('diy_old',        'verify',undef,undef),'!VER(http://io.com/rufus)');
is(try(    'hsr',        'verify',undef,  '2'),'!NOT');
is(try('hsr_old',        'verify',undef,  '2'),'!NOT');
is(try(    'diy',        'verify',undef,  '2'),'!NOT');
is(try('diy_old',        'verify',undef,  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',        'verify','1.0',undef),'!VER(http://io.com/rufus)');
is(try('hsr_old',        'verify','1.0',undef),'!VER(http://io.com/rufus)');
is(try(    'diy',        'verify','1.0',undef),'!VER(http://io.com/rufus)');
is(try('diy_old',        'verify','1.0',undef),'!VER(http://io.com/rufus)');
is(try(    'hsr',        'verify','1.0',  '2'),'!NOT');
is(try('hsr_old',        'verify','1.0',  '2'),'!NOT');
is(try(    'diy',        'verify','1.0',  '2'),'!NOT');
is(try('diy_old',        'verify','1.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',        'verify','1.1',undef),'!VER(http://io.com/rufus)');
is(try('hsr_old',        'verify','1.1',undef),'!VER(http://io.com/rufus)');
is(try(    'diy',        'verify','1.1',undef),'!VER(http://io.com/rufus)');
is(try('diy_old',        'verify','1.1',undef),'!VER(http://io.com/rufus)');
is(try(    'hsr',        'verify','1.1',  '2'),'!NOT');
is(try('hsr_old',        'verify','1.1',  '2'),'!NOT');
is(try(    'diy',        'verify','1.1',  '2'),'!NOT');
is(try('diy_old',        'verify','1.1',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr',        'verify','2.0',undef),'!VER(http://io.com/rufus)');
is(try('hsr_old',        'verify','2.0',undef),'!VER(http://io.com/rufus)');
is(try(    'diy',        'verify','2.0',undef),'!VER(http://io.com/rufus)');
is(try('diy_old',        'verify','2.0',undef),'!VER(http://io.com/rufus)');
is(try(    'hsr',        'verify','2.0',  '2'),'!VER(http://io.com/rufus)');
is(try('hsr_old',        'verify','2.0',  '2'),'!VER(http://io.com/rufus)');
is(try(    'diy',        'verify','2.0',  '2'),'!VER(http://io.com/rufus)');
is(try('diy_old',        'verify','2.0',  '2'),'!VER(http://io.com/rufus)');
is(try(    'hsr', 'real_bad_mode',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('hsr_old', 'real_bad_mode',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'diy', 'real_bad_mode',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('diy_old', 'real_bad_mode',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr', 'real_bad_mode',undef,  '2'),'!NOT');
is(try('hsr_old', 'real_bad_mode',undef,  '2'),'!NOT');
is(try(    'diy', 'real_bad_mode',undef,  '2'),'!NOT');
is(try('diy_old', 'real_bad_mode',undef,  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr', 'real_bad_mode','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('hsr_old', 'real_bad_mode','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'diy', 'real_bad_mode','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('diy_old', 'real_bad_mode','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr', 'real_bad_mode','1.0',  '2'),'!NOT');
is(try('hsr_old', 'real_bad_mode','1.0',  '2'),'!NOT');
is(try(    'diy', 'real_bad_mode','1.0',  '2'),'!NOT');
is(try('diy_old', 'real_bad_mode','1.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr', 'real_bad_mode','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('hsr_old', 'real_bad_mode','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'diy', 'real_bad_mode','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('diy_old', 'real_bad_mode','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr', 'real_bad_mode','1.1',  '2'),'!NOT');
is(try('hsr_old', 'real_bad_mode','1.1',  '2'),'!NOT');
is(try(    'diy', 'real_bad_mode','1.1',  '2'),'!NOT');
is(try('diy_old', 'real_bad_mode','1.1',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr', 'real_bad_mode','2.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('hsr_old', 'real_bad_mode','2.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'diy', 'real_bad_mode','2.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('diy_old', 'real_bad_mode','2.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr', 'real_bad_mode','2.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('hsr_old', 'real_bad_mode','2.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'diy', 'real_bad_mode','2.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try('diy_old', 'real_bad_mode','2.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr','provider_error',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('hsr_old','provider_error',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'diy','provider_error',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('diy_old','provider_error',undef,undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr','provider_error',undef,  '2'),'!NOT');
# is(try('hsr_old','provider_error',undef,  '2'),'!NOT');
# is(try(    'diy','provider_error',undef,  '2'),'!NOT');
# is(try('diy_old','provider_error',undef,  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr','provider_error','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('hsr_old','provider_error','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'diy','provider_error','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('diy_old','provider_error','1.0',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr','provider_error','1.0',  '2'),'!NOT');
# is(try('hsr_old','provider_error','1.0',  '2'),'!NOT');
# is(try(    'diy','provider_error','1.0',  '2'),'!NOT');
# is(try('diy_old','provider_error','1.0',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr','provider_error','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('hsr_old','provider_error','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'diy','provider_error','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try('diy_old','provider_error','1.1',undef),'!ERR(bad_mode: The openid.mode argument is not correct)');
# is(try(    'hsr','provider_error','1.1',  '2'),'!NOT');
# is(try('hsr_old','provider_error','1.1',  '2'),'!NOT');
# is(try(    'diy','provider_error','1.1',  '2'),'!NOT');
# is(try('diy_old','provider_error','1.1',  '2'),'!ERR(bad_mode: The openid.mode argument is not correct)');
is(try(    'hsr','provider_error','2.0',undef),'!ERR(provider_error: We are out of spoons.)');
is(try('hsr_old','provider_error','2.0',undef),'!ERR(provider_error: We are out of spoons.)');
is(try(    'diy','provider_error','2.0',undef),'!ERR(provider_error: We are out of spoons.)');
is(try('diy_old','provider_error','2.0',undef),'!ERR(provider_error: We are out of spoons.)');
is(try(    'hsr','provider_error','2.0',  '2'),'!ERR(provider_error: We are out of spoons.)');
is(try('hsr_old','provider_error','2.0',  '2'),'!ERR(provider_error: We are out of spoons.)');
is(try(    'diy','provider_error','2.0',  '2'),'!ERR(provider_error: We are out of spoons.)');
is(try('diy_old','provider_error','2.0',  '2'),'!ERR(provider_error: We are out of spoons.)');


