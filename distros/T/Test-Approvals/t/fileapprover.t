#! perl

use strict;
use warnings FATAL => qw(all);
use autodie;
use version; our $VERSION = qv('v0.0.5');

use Test::Approvals::Specs qw(describe it run_tests);
use Test::Approvals::Core::FileApprover qw(verify);
use Test::Approvals::Namers::DefaultNamer;
use Test::Approvals::Writers::TextWriter;
use Test::Approvals::Reporters::FakeReporter;
use Test::More;

describe 'A FileApprover', sub {
    my $w = Test::Approvals::Writers::TextWriter->new( result => 'Hello' );
    my $r = Test::Approvals::Reporters::FakeReporter->new();
    my $write_message_to = sub {
        my ( $message, $path ) = @_;
        open my $ah, '>', $path;
        $ah->print($message);
        $ah->close();
        return;
    };

    it 'Verifies Approved File Exists', sub {
        my ($spec) = @_;
        my $n = Test::Approvals::Namers::DefaultNamer->new( name => $spec );

        my $received = $n->get_received_file('.txt');

        ok !verify( $w, $n, $r ), $spec;
        unlink $received;
    };

    it 'Verifies Files Have Equal Size', sub {
        my ($spec) = @_;
        my $n = Test::Approvals::Namers::DefaultNamer->new( name => $spec );

        my $approved = $n->get_approved_file('.txt');
        $write_message_to->( 'Hello World', $approved );

        ok !verify( $w, $n, $r ), $spec;
        unlink $approved;
        unlink $n->get_received_file('.txt');
    };

    it 'Verifies Every Byte Is Equal', sub {
        my ($spec) = @_;
        my $n = Test::Approvals::Namers::DefaultNamer->new( name => $spec );

        my $approved = $n->get_approved_file('.txt');
        $write_message_to->( 'Helol', $approved );

        ok !verify( $w, $n, $r ), $spec;
        unlink $approved;
        unlink $n->get_received_file('txt');
    };

    it 'Launches Reporter on Failure', sub {
        my ($spec) = @_;
        my $n = Test::Approvals::Namers::DefaultNamer->new( name => $spec );
        my $s = Test::Approvals::Reporters::FakeReporter->new();

        my $approved = $n->get_approved_file('.txt');
        $write_message_to->( 'Helol', $approved );

        verify( $w, $n, $s );

        ok $s->was_called, $spec;
        unlink $approved;
        unlink $n->get_received_file('txt');
    };

    it 'Verifies matching Files', sub {
        my ($spec) = @_;
        my $n = Test::Approvals::Namers::DefaultNamer->new( name => $spec );

        my $approved = $n->get_approved_file('.txt');
        $write_message_to->( 'Hello', $approved );

        ok verify( $w, $n, $r ), $spec;
        unlink $approved;
    };

    it 'Removes received file on match', sub {
        my ($spec) = @_;
        my $n = Test::Approvals::Namers::DefaultNamer->new( name => $spec );

        my $approved = $n->get_approved_file('.txt');
        $write_message_to->( 'Hello', $approved );

        verify( $w, $n, $r );

        ok !( -e $n->get_received_file('txt') ), $spec;
        unlink $approved;
    };

    it 'Preserves approved file on match', sub {
        my ($spec) = @_;
        my $n = Test::Approvals::Namers::DefaultNamer->new( name => $spec );

        my $approved = $n->get_approved_file('.txt');
        $write_message_to->( 'Hello', $approved );

        verify( $w, $n, $r );

        ok -e $approved, $spec;
        unlink $approved;
    };
};

run_tests();
