use strict;
use warnings;
use Test::More;

use lib 'lib';

# Numeric values for each constant — these are the documented status codes
# and they must NEVER change without a major-version bump, since the daemon
# wire format and the qpsmtpd plugin both depend on the exact integers.
my %expected = (
    QD_NOT_DELIVERABLE         => 0x00,
    QD_UNKNOWN_PERM_DENIED     => 0x11,
    QD_UNKNOWN_PIPE            => 0x12,
    QD_UNKNOWN_BOUNCESAYING    => 0x13,
    QD_EZMLM                   => 0x14,
    QD_TEMPFAIL_GROUP_WRITABLE => 0x21,
    QD_TEMPFAIL_STICKY         => 0x22,
    QD_CLIENT_FAILURE          => 0x2f,
    QD_DELIVERABLE             => 0xf1,
    QD_VPOPMAIL_DIR            => 0xf2,
    QD_VPOPMAIL_VALIAS         => 0xf3,
    QD_VPOPMAIL_CATCHALL       => 0xf4,
    QD_VPOPMAIL_VUSER          => 0xf5,
    QD_VPOPMAIL_QMAIL_EXT      => 0xf6,
    QD_VPOPMAIL_NO_DOMAIN      => 0xfe,
    QD_NOT_LOCAL               => 0xff,
);

subtest 'Qmail::Deliverable::Status defines and exports the documented constants' => sub {
    require Qmail::Deliverable::Status;
    Qmail::Deliverable::Status->import(':all');
    for my $name ( sort keys %expected ) {
        no strict 'refs';
        is __PACKAGE__->can($name)->(),
            $expected{$name},
            "$name = " . sprintf( '0x%02x', $expected{$name} );
    }
};

subtest 'Qmail::Deliverable re-exports under :status' => sub {

    package T1;
    use Test::More;
    use Qmail::Deliverable qw(:status);

    for my $name ( sort keys %expected ) {
        no strict 'refs';
        is __PACKAGE__->can($name)->(),
            $expected{$name},
            "$name imported from Qmail::Deliverable :status";
    }
};

subtest 'Qmail::Deliverable :all includes the status constants' => sub {

    package T2;
    use Test::More;
    use Qmail::Deliverable qw(:all);

    is QD_DELIVERABLE(), 0xf1, ':all imports QD_DELIVERABLE';
    is QD_NOT_LOCAL(),   0xff, ':all imports QD_NOT_LOCAL';

    # And the original functions are still exported
    ok __PACKAGE__->can('deliverable'), ':all still exports deliverable()';
    ok __PACKAGE__->can('qmail_local'), ':all still exports qmail_local()';
};

subtest 'Qmail::Deliverable::Client re-exports under :status' => sub {

    package T3;
    use Test::More;
    use Qmail::Deliverable::Client qw(:status);

    is QD_CLIENT_FAILURE(), 0x2f, 'Client exports QD_CLIENT_FAILURE';
    is QD_NOT_LOCAL(),      0xff, 'Client exports QD_NOT_LOCAL';
};

subtest 'Loading ::Status is side-effect free' => sub {

    # If Qmail::Deliverable::Status accidentally pulled in
    # Qmail::Deliverable, the latter would try to reread_config() against
    # /var/qmail at load time. Verify that doesn't happen by checking %INC.
    delete $INC{'Qmail/Deliverable.pm'};
    delete $INC{'Qmail/Deliverable/Status.pm'};

    require Qmail::Deliverable::Status;
    ok exists $INC{'Qmail/Deliverable/Status.pm'}, 'Status module loaded';
    ok !exists $INC{'Qmail/Deliverable.pm'}, 'Loading Status did not drag in Qmail::Deliverable';
};

done_testing();
