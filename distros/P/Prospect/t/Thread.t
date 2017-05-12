#-------------------------------------------------------------------------------
# NAME: Thread.t
# PURPOSE: test script for the Prospect::File and Prospect::Thread objects.
#          used in conjunction with Makefile.PL to test installation
#
# $Id: Thread.t,v 1.1 2003/11/07 00:14:49 cavs Exp $
#-------------------------------------------------------------------------------

use Prospect::File;
use Prospect::Thread;
use Prospect::ThreadSummary;
use Test::More;
use warnings;
use strict;

plan tests => 102;

my $fn = 't/SOMA_HUMAN.xml';
ok( -f $fn, "$fn valid" );

my @tnames = qw( 1alu 1bgc 1lki 1huw 1f6fa 1cnt3 1ax8 1evsa 1f45b );

my $pf = new Prospect::File;
ok( defined $pf && ref($pf) && $pf->isa('Prospect::File'), 'Prospect::File::new()' );
ok( $pf->open( "<$fn" ), "open $fn" );
my $cnt=0;
while( my $t = $pf->next_thread() ) {
	# test Thread
	ok( defined $t && ref($t) && $t->isa('Prospect::Thread'), 'Prospect::Thread::new' );
	ok( $t->qname eq 'SOMA_HUMAN.fa', 'Prospect::Thread::qname' );
	ok( $t->tname eq $tnames[$cnt], "Prospect::Thread::tname eq $tnames[$cnt]" );

	# get ThreadSummary from Thread
	my $ts = new Prospect::ThreadSummary( $t );
	ok( defined $ts && ref($ts) && $ts->isa('Prospect::ThreadSummary'), 'Prospect::ThreadSummary::new' );
	ok( $ts->qname eq 'SOMA_HUMAN.fa', 'Prospect::ThreadSummary::qname' );
	ok( $ts->tname eq $tnames[$cnt], "Prospect::ThreadSummary::tname eq $tnames[$cnt]" );

	# check some other values
	ok( $t->tname eq $ts->tname, 'Prospect::Thread::tname eq Prospect::ThreadSummary::tname' );
	ok( $t->target_start eq $ts->target_start, 'Prospect::Thread::target_start eq Prospect::ThreadSummary::target_start' );
	ok( $t->align_len eq $ts->align_len, 'Prospect::Thread::align_len eq Prospect::ThreadSummary::align_len' );
	ok( $t->svm_score eq $ts->svm_score, 'Prospect::Thread::svm_score eq Prospect::ThreadSummary::svm_score' );
	ok( $t->raw_score eq $ts->raw_score, 'Prospect::Thread::raw_score eq Prospect::ThreadSummary::raw_score' );

	$cnt++;
}
