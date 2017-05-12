#!/usr/bin/perl
# © 2011 David Leadbeater; https://dgl.cx/licence
#
# A simple email gateway script using SMS::Send (in particular
# SMS::Send::UK::AA, but it should work with others provided no A&A specific
# features are used).
#
# Some features assume qmail/postfix (looking for $LOCAL for multiple user
# support), but it will work without (just the default number will work).
#
# Setup:
#
# 1. Put this script somewhere, chmod +x, check you have required modules by
#    running: perl -c sms.pl
#
# 2. Write a ~/.sms-mail-config (as the user this will run as, or put in the
#    same directory as the script) containing:
#
#    [sms]
#      login = 0123456789x
#      password = somethingratherlong
#      # Change to true if A&A have allowed custom originators for you
#      # (required for SIM).
#      custom_originator = false
#
#    [user]
#      # default is used if no other users listed match the local part of the
#      # email address.
#      default = 07xxxxxxxxx
#      user-sms = 1234567890123456789
#
# (The longer number is a ICCID, see A&A's site for details about their SIMs.)
#
# 3. Configure your mail server to deliver to this script, e.g. with qmail:
#
#    echo '|/path/to/sms.pl' > ~/.qmail-sms
#
# 4. Send mail to user-sms@example.com to test.

use strict;
use Config::GitLike;
use Email::Address;
use Mail::SpamAssassin::Message;
use SMS::Send;

# Will look at /etc/sms-mail-config, ~/.sms-mail-config, ./.sms-mail-config
my $c = Config::GitLike->new(confname => "sms-mail-config");

my $sms = SMS::Send->new($c->get(key => "sms.driver") || "UK::AA",
  _login    => $c->get(key => "sms.login"),
  _password => $c->get(key => "sms.password"));

my $email = Mail::SpamAssassin::Message->new;

my $from = (Email::Address->parse($email->header("From")))[0];
if(defined $from && ref $from) {
  $from = $from->name;
} else {
  $from = $email->header("From") || $email->header("Return-Path");
}

my $subject = $email->header("Subject");
my $first_part = ($email->find_parts('text/plain', 1))[0];
my $body = substr $first_part->decode, 0, 100;

my $to = $c->get(key => "user.$ENV{LOCAL}") || $c->get(key => "user.default");

my $sent = $sms->send_sms(
  to => $to,
  text => "$subject\n$body",
  ($c->get(key => "sms.custom_originator", as => "bool")
    ? (_oa => $from) : ()));

print ref $sent ? $sent->status_line : $sent, "\n";
# Fail so the MDA will queue it if it didn't get forwarded on
exit !$sent;
