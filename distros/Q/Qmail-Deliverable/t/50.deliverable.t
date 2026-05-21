use strict;
use warnings;
use Test::More;
use File::Path qw(make_path remove_tree);

use lib 'lib';
use lib 't/lib';

use Qmail::Deliverable ':all';
use QDTest qw(setup_perm_dirs);

$Qmail::Deliverable::qmail_dir = 't/fixtures';
Qmail::Deliverable::reread_config();

# Set up the special-permission homedirs referenced from t/fixtures/users/assign.
setup_perm_dirs('t/fixtures');

END {
    chmod 0700, "t/fixtures/domains/$_"
        for qw(perms775 permssticky noread);
    remove_tree("t/fixtures/domains/$_")
        for qw(perms775 permssticky noread);
}

{
    no warnings 'redefine';
    local *Qmail::Deliverable::valias = sub {0};
    local *Qmail::Deliverable::vuser  = sub {0};

    subtest '0xff - non-local domain' => sub {
        is sprintf( '0x%02x', deliverable('user@nowhere.test') ), '0xff', 'unknown domain';
    };

    subtest '0x21 - group-writable homedir' => sub {
        is sprintf( '0x%02x', deliverable('group775@sub.example.com') ),
            '0x21',
            'homedir mode 0775 yields 0x21';
    };

    subtest '0x22 - sticky homedir' => sub {
        is sprintf( '0x%02x', deliverable('sticky@sub.example.com') ),
            '0x22',
            'mode 1755 homedir yields 0x22 (sticky bit detected)';
    };

SKIP: {
        skip "running as root; -r ignores the 0000 mode", 1 if $> == 0;
        subtest '0x11 - unreadable homedir' => sub {
            is sprintf( '0x%02x', deliverable('noread@sub.example.com') ),
                '0x11',
                'homedir mode 0000 yields 0x11';
        };
    }

    subtest '0xf1 - normal delivery via bare .qmail' => sub {
        is sprintf( '0x%02x', deliverable('alice@sub.example.com') ),
            '0xf1',
            'forward line in bare .qmail';
    };

    subtest '0xf1 - empty .qmail-EXT' => sub {
        is sprintf( '0x%02x', deliverable('luser-empty@example.com') ),
            '0xf1',
            'empty file => defaultdelivery';
    };

    subtest '0xf1 - forwarding .qmail-EXT' => sub {
        is sprintf( '0x%02x', deliverable('luser-direct@example.com') ),
            '0xf1',
            'non-pipe first line is treated as normal delivery';
    };

    subtest '0x14 - ezmlm' => sub {
        is sprintf( '0x%02x', deliverable('luser-list@example.com') ), '0x14', '|ezmlm-* line';
    };

    subtest '0x12 - generic pipe' => sub {
        is sprintf( '0x%02x', deliverable('luser-pipe@example.com') ),
            '0x12',
            '|/path/to/handler line';
    };

    subtest '0x13 - bouncesaying with extra args' => sub {
        is sprintf( '0x%02x', deliverable('luser-bsay2@example.com') ),
            '0x13',
            'multi-token bouncesaying => 0x13';
    };

    subtest '0x00 - bouncesaying with single arg' => sub {
        is sprintf( '0x%02x', deliverable('luser-bsay1@example.com') ),
            '0x00',
            'single-token bouncesaying => 0x00';
    };

    subtest '0x00 - vdelivermail bounce-no-mailbox, nothing matches' => sub {

        # valias and vuser both stubbed to 0, no directory, VPOPMAIL_EXT=0.
        is sprintf( '0x%02x', deliverable('luser-nobox@example.com') ),
            '0x00',
            'falls through every probe and returns not-deliverable';
    };

    subtest '0xf2 - vdelivermail + local-part directory exists' => sub {
        is sprintf( '0x%02x', deliverable('luser-existsdir@example.com') ),
            '0xf2',
            'directory by that name exists in the domain root';
    };

    subtest '0xf3 - vdelivermail + valias matches' => sub {
        local *Qmail::Deliverable::valias = sub {1};
        is sprintf( '0x%02x', deliverable('luser-valiased@example.com') ),
            '0xf3',
            'valias returns true';
    };

    subtest '0xf4 - catch-all vdelivermail (no bounce-no-mailbox)' => sub {
        is sprintf( '0x%02x', deliverable('catchall-anything@catchall.example') ),
            '0xf4',
            'vdelivermail line without bounce-no-mailbox => catch-all';
    };

    subtest '0xf5 - vdelivermail + vuser matches' => sub {
        local *Qmail::Deliverable::vuser = sub {1};
        is sprintf( '0x%02x', deliverable('luser-vusered@example.com') ),
            '0xf5',
            'vuser returns true';
    };

    subtest '0xf6 - vdelivermail + VPOPMAIL_EXT qmail-ext probe' => sub {

        # qmail_local maps 'luser-vextfoo@example.com' through the
        # 'example.com' virtualdomain to 'example.com-luser-vextfoo'. The
        # +example.com- wildcard (12 chars) wins over +luser-, so the
        # assign-user field is 'example.com'. The chunk loop then probes
        # vuser('luser@example.com') and vuser('vextfoo@example.com').
        local *Qmail::Deliverable::vuser = sub {
            my ($addr) = @_;
            return $addr eq 'luser@example.com' ? 1 : 0;
        };
        local $Qmail::Deliverable::VPOPMAIL_EXT = 1;
        is sprintf( '0x%02x', deliverable('luser-vextfoo@example.com') ),
            '0xf6',
            'qmail-ext chunk match';
    };

    subtest '0xfe - vdelivermail in dot-qmail but no @ in address' => sub {

        # deliverable() emits a carp on this code path; swallow it so the
        # test output stays clean. The behavior we're pinning is the 0xfe.
        my $rv;
        {
            local $SIG{__WARN__} = sub { };
            $rv = deliverable('bare');
        }
        is sprintf( '0x%02x', $rv ), '0xfe', 'bare local with vdelivermail .qmail => 0xfe';
    };

    done_testing();
}
