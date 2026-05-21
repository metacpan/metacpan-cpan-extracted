use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use lib 'lib';
use lib 't/lib';

use Qmail::Deliverable ':all';
$Qmail::Deliverable::qmail_dir = 't/fixtures';
Qmail::Deliverable::reread_config();

subtest 'exact = match' => sub {
    my @r = qmail_user('alice');
    is_deeply \@r,
        [ 'alice', '1001', '1001', 't/fixtures/domains/realhome', '', '', '' ],
        'exact =alice returns full 7-field tuple';

    @r = qmail_user('bare');
    is_deeply \@r,
        [ 'bare', '1010', '1010', 't/fixtures/domains/bare-vpop', '', '', '' ],
        'second exact entry resolves separately';
};

subtest 'wildcard + match' => sub {
    my @r = qmail_user('luser-ext');
    is_deeply \@r,
        [ 'vpopmail', '89', '89', 't/fixtures/domains/example.com', '-', 'luser-ext' ],
        'wildcard +luser- appends the remainder to field 5';

    @r = qmail_user('luser-');
    is_deeply \@r,
        [ 'vpopmail', '89', '89', 't/fixtures/domains/example.com', '-', 'luser-' ],
        'wildcard with no suffix keeps the bare prefix';

    @r = qmail_user('example.com-bob');
    is_deeply \@r,
        [ 'example.com', '89', '89', 't/fixtures/domains/example.com', '-', 'bob', '' ],
        'longest matching prefix wins (12 chars before 6); '
        . 'trailing 7th field present because the assign line ended with "::"';
};

subtest 'fallback when qmail_dir is t/fixtures' => sub {
    is qmail_user('unknown-user'), 'unknown-user',
        'unmatched local returns the bare local under the t/fixtures shortcut';
};

subtest 'exact beats wildcard; comments ignored' => sub {
    my $tmp = tempdir( CLEANUP => 1 );
    make_path( "$tmp/control", "$tmp/users" );
    open my $vd, '>', "$tmp/control/virtualdomains" or die $!;
    close $vd;
    open my $lo, '>', "$tmp/control/locals" or die $!;
    close $lo;
    open my $as, '>', "$tmp/users/assign" or die $!;
    print {$as} <<'EOF';
# this is a comment and must not parse as a wildcard
=foo-bar:exact-user:5:5:/exact/home:::
+foo-:wild-user:6:6:/wild/home:-:foo-
.
EOF
    close $as;

    local $Qmail::Deliverable::qmail_dir = $tmp;
    Qmail::Deliverable::reread_config();

    my @r = qmail_user('foo-bar');
    is_deeply \@r,
        [ 'exact-user', '5', '5', '/exact/home', '', '', '' ],
        'exact =foo-bar wins over the +foo- wildcard';

    @r = qmail_user('foo-quux');
    is_deeply \@r,
        [ 'wild-user', '6', '6', '/wild/home', '-', 'foo-quux' ],
        'wildcard catches when there is no exact match';

    # Restore default fixture state
    $Qmail::Deliverable::qmail_dir = 't/fixtures';
    Qmail::Deliverable::reread_config();
};

done_testing();
