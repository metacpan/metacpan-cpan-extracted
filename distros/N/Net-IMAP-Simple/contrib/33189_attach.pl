#!/usr/bin/perl

# Warning: the returned message numbers are not always correct!

use strict;
use warnings;
use Email::Simple;
use lib 'inc', "blib/lib", "blib/arch";
use rebuild_iff_necessary;
use slurp_fetchmail;
use Net::IMAP::Simple;

my $show_subjects = $ENV{SHOW_SUBJECTS};

my $imap = slurp_fetchmail->login(use_ssl=>1);
my $folder = shift || 'INBOX';

my ( $newmsg, $unseenmsg, $oldmsg, $flags );

my $nm = $imap->select($folder);

print "folder $folder: $nm total";

$newmsg = $imap->recent;
$flags  = $imap->flags;

$unseenmsg = 0;
for ( my $i = 1 ; $i <= $nm ; $i++ ) {
    $unseenmsg++ if not $imap->seen($i);
}

$oldmsg = $unseenmsg - $newmsg;

print ", $newmsg new, $unseenmsg unseen, $oldmsg old\n";

# Print the subjects of all the messages in the INBOX
if ($show_subjects) {
    for ( my $i = 1 ; $i <= $nm ; $i++ ) {
        if ( $imap->seen($i) ) {
            print "  ";
        } else {
            print "N ";
        }

        my $es = Email::Simple->new( join '', @{ $imap->top($i) } );

        printf( "[%03d] %s\n", $i, $es->header('Subject') );
    }
}

$imap->quit;

