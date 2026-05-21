use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib 't/lib';

# Pretend qpsmtpd is loaded so the plugin's BEGIN guard passes.
# Import constants and load the plugin at compile time so bareword
# DECLINED/DENY references in this file resolve.
BEGIN {
    $INC{'Qpsmtpd.pm'} = 1;
    require Qpsmtpd::Constants;
    Qpsmtpd::Constants->import;
    do './qpsmtpd-plugin/qmail_deliverable';
    die "do plugin failed: $@" if $@;
}

# Minimal fakes -----------------------------------------------------------

{

    package FakeLog;
    sub new        { bless { entries => [] }, shift }
    sub push_entry { push @{ $_[0]{entries} }, [ @_[ 1, 2 ] ] }
    sub entries    { @{ $_[0]{entries} } }
    sub clear      { $_[0]{entries} = [] }
}

{

    package FakeSelf;

    sub new {
        my ( $class, $log ) = @_;
        bless { log => $log }, $class;
    }
    sub log           { my ( $self, $level, $msg ) = @_; $self->{log}->push_entry( $level, $msg ) }
    sub register_hook { }    # no-op
}

{

    package FakeAddr;
    sub new     { my ( $class, $addr ) = @_; bless { addr => $addr }, $class }
    sub address { $_[0]->{addr} }
}

{

    package FakeTxn;
    sub new    { my ( $class, $sender ) = @_; bless { sender => $sender }, $class }
    sub sender { $_[0]->{sender} }
}

{

    package FakeRcpt;

    sub new {
        my ( $class, $addr, $host ) = @_;
        bless { addr => $addr, host => $host }, $class;
    }
    sub address { $_[0]->{addr} }
    sub host    { $_[0]->{host} }
}

# Plugin setup ------------------------------------------------------------

my $log  = FakeLog->new;
my $self = FakeSelf->new($log);
register( $self, undef, server => "127.0.0.1:9999" );

# The plugin's `use Qmail::Deliverable::Client qw(deliverable)` aliased
# &main::deliverable at compile time, so localize that symbol directly.

sub run_rcpt {
    my (%opts)      = @_;
    my $sender_addr = exists $opts{sender} ? $opts{sender} : 'sender@example.com';
    my $txn         = FakeTxn->new( FakeAddr->new($sender_addr) );
    my $rcpt        = FakeRcpt->new( 'recipient@example.com', 'example.com' );
    $log->clear;
    no warnings 'redefine';
    local *main::deliverable = sub { $opts{rv} };
    return rcpt_handler( $self, $txn, $rcpt );
}

# Tests -------------------------------------------------------------------

subtest '0x00 -> DENY with "no mailbox" message' => sub {
    my ( $code, $msg ) = run_rcpt( rv => 0x00 );
    is $code, DENY, 'returns DENY';
    like $msg, qr/no mailbox/i, 'has the canonical reject message';
};

subtest '0x11/0x12/0x13 -> DECLINED, logged' => sub {
    for my $rv ( 0x11, 0x12, 0x13 ) {
        my $code = run_rcpt( rv => $rv );
        is $code, DECLINED, sprintf( '0x%02x -> DECLINED', $rv );
        ok scalar( $log->entries ), sprintf( '0x%02x: log emitted', $rv );
    }
};

subtest '0x14 (ezmlm) accepts normal sender, denies null sender' => sub {
    my $code = run_rcpt( rv => 0x14, sender => 'someone@example.org' );
    is $code, DECLINED, 'normal sender -> DECLINED (accept)';

    my ( $denycode, $msg ) = run_rcpt( rv => 0x14, sender => '' );
    is $denycode, DENY, 'empty sender (null) -> DENY';
    like $msg, qr/mailing lists do not accept null senders/i, 'mentions null senders';

    ( $denycode, $msg ) = run_rcpt( rv => 0x14, sender => '<>' );
    is $denycode, DENY, 'literal "<>" sender -> DENY';
};

subtest '0x21/0x22 -> DECLINED, logged as temp undeliverable' => sub {
    for my $rv ( 0x21, 0x22 ) {
        my $code = run_rcpt( rv => $rv );
        is $code, DECLINED, sprintf( '0x%02x -> DECLINED', $rv );
    }
};

subtest '0x2f -> DECLINED, transport error logged' => sub {
    local $Qmail::Deliverable::Client::ERROR = "test failure";
    my $code = run_rcpt( rv => 0x2f );
    is $code, DECLINED, 'communication failure does not block delivery';
};

subtest 'all 0xfX pass codes -> DECLINED' => sub {
    for my $rv ( 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6 ) {
        my $code = run_rcpt( rv => $rv );
        is $code, DECLINED, sprintf( '0x%02x -> DECLINED', $rv );
    }
};

subtest '0xfe -> DECLINED, logged as SHOULD NOT HAPPEN' => sub {
    my $code = run_rcpt( rv => 0xfe );
    is $code, DECLINED, '0xfe -> DECLINED';
    ok( ( grep { $_->[1] =~ /SHOULD NOT HAPPEN/i } $log->entries ),
        'log entry mentions SHOULD NOT HAPPEN' );
};

subtest '0xff -> DECLINED, "not local" logged' => sub {
    my $code = run_rcpt( rv => 0xff );
    is $code, DECLINED, '0xff -> DECLINED';
    ok( ( grep { $_->[1] =~ /not local/i } $log->entries ), 'log entry mentions not local' );
};

subtest 'unknown nonzero status -> DECLINED, "unknown" logged' => sub {
    my $code = run_rcpt( rv => 0x77 );
    is $code, DECLINED, 'unknown status -> DECLINED';
    ok( ( grep { $_->[1] =~ /unknown/i } $log->entries ), 'log entry mentions unknown' );
};

subtest 'undef return -> DECLINED, error logged' => sub {
    my $code = run_rcpt( rv => undef );
    is $code, DECLINED, 'undef -> DECLINED';
    ok( ( grep { $_->[1] =~ /error \(unknown\)/i } $log->entries ),
        'log entry mentions error (unknown)' );
};

done_testing();
