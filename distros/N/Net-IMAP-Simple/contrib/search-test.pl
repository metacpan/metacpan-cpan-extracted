#!/usr/bin/perl

use strict;

use Net::IMAP::Simple;
my $goog = login();

$goog->select("jet");

my @id1 = $goog->search(q(SUBJECT "rt.cpan.org #55177"));                                                 print "id1: @id1\n";
my @id2 = $goog->search(q(HEADER Message-ID "<rt-3.8.HEAD-12685-1267618808-430.55177-4-0@rt.cpan.org>")); print "id2: @id2\n";

$goog->put( jet => qq(from: jettero\@cpan.org\r\nMessage-ID: test-77\r\nsubject: test-77\r\n\r\ntest-77\r\n) );
$goog->put( jet => qq(from: jettero\@cpan.org\r\nMessage-ID: <test-77>\r\nsubject: <test-77>\r\n\r\n<test-77>\r\n) );
$goog->put( jet => qq(from: jettero\@cpan.org\r\nMessage-ID: <test-77\@hrm>\r\nsubject: <test-77\@hrm>\r\n\r\n<test-77\@hrm>\r\n) );

my @id3 = $goog->search(q(HEADER Message-ID "test-77"));       print "id3: @id3\n";
my @id4 = $goog->search(q(HEADER Message-ID "<test-77>"));     print "id4: @id4\n";
my @id5 = $goog->search(q(HEADER Message-ID "<test-77@hrm>")); print "id5: @id5\n";
my @id6 = $goog->search(q(SUBJECT "test-77"));                 print "id6: @id6\n";


# login {{{
sub login {
    my $arg = ""; $arg = ".$_[0]" if $_[0];
    my $fetchmailrc; { open my $in, "$ENV{HOME}/.fetchmailrc$arg" or die $!; local $/ = undef; $fetchmailrc = <$in>; close $in; }
    my $server = $1 if $fetchmailrc =~ m/server\s+(.+)/m;
    my $user   = $1 if $fetchmailrc =~ m/user\s+(.+)/m;
    my $pass   = $1 if $fetchmailrc =~ m/pass\s+(.+)/m;

    print "$server ";
    my $debug = 1;

    my $imap = Net::IMAP::Simple->new($server, debug=>$debug, use_ssl=>1) or die "connect failed: $Net::IMAP::Simple::errstr";
       $imap->login($user=>$pass) or die "login failed: " . $imap->errstr;

    print "[in] ";

    return $imap;
}
# }}}
