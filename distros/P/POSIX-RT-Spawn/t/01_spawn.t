use strict;
use warnings;
use Test::More;

use Config;
use Fcntl qw(F_SETFD);
use POSIX::RT::Spawn;

my $Perl = $Config{perlpath};
plan skip_all => "$Perl is not a usable Perl interpreter"
    unless -x $Perl;

my @cmd = (
    $Perl,  '-e',
    q(open my $out, qq{>&=$ARGV[0]}; printf $out qq{$$\n%s\n$^X}, getppid),
);
my $fake_cmd_name = 'lskdjfalksdjfdjfkls';

sub spawn_cmd {
    my ($real, @cmd) = @_;

    pipe my($in, $out) or die "pipe: $!";

    # Disable close-on-exec.
    fcntl $out, F_SETFD, 0;

    my $fd = fileno $out;
    if (1 == @cmd) { $cmd[0] .= " $fd"; }
    else           { push @cmd, $fd; }

    my $pid;
    if ($real) {
        my $cmd = qq(spawn $real ) . join ',',  map { qq('$_') } @cmd;
        note 'command: ', $cmd;
        $pid = eval $cmd;
        die $@ if $@;
    }
    else {
        note 'command: ', explain \@cmd;
        $pid = spawn @cmd;
    }
    return unless $pid;

    close $out;
    waitpid $pid, 0;

    chomp(my @out = <$in>);
    close $in;

    return $pid, @out;
}

subtest 'non-existant program' => sub {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    note "command: $fake_cmd_name";
    my $pid = spawn($fake_cmd_name);
    if ($pid) {
        waitpid $pid, 0;
        isnt $?>>8, 0, 'child has non-zero status';
    }
    else {
        isnt $!+0, 0, 'errno';
        like $warning, qr/^Can't spawn/, 'warning';
    }
};

subtest 'single scalar with no shell metacharacters' => sub {
    my $cmd = join ' ', @cmd[0 .. 1], qq('$cmd[2]');
    my ($pid, $xpid, $ppid) = spawn_cmd '', $cmd;
    cmp_ok $_, '>', 0,  'valid looking pid' for ($pid, $xpid, $ppid);
    ok $pid eq $xpid || $pid eq $ppid, 'pid is expected value';
};

subtest 'single scalar with shell metacharacters' => sub {
    my $cmd = join ' ', @cmd[0 .. 1], qq('$cmd[2]');
    my ($pid, $xpid, $ppid) = spawn_cmd '', 'true && ' . $cmd;
    cmp_ok $_, '>', 0,  'valid looking pid' for ($pid, $xpid, $ppid);
    ok $pid eq $xpid || $pid eq $ppid, 'pid is expected value';
};

subtest 'multivalued list' => sub {
    my ($pid, $xpid, $ppid) = spawn_cmd '', @cmd;
    cmp_ok $_, '>', 0,  'valid looking pid' for ($pid, $xpid, $ppid);
    ok $pid eq $xpid || $pid eq $ppid, 'pid is expected value';
};

subtest 'modify process name with indirect object syntax' => sub {
    local $TODO = 'unimplemented';

    # plan skip_all => "Modifying process name requires Perl >= 5.13.08"
    #     if $^V lt '5.13.8';

    eval {
        my @cmd = @cmd;
        unshift @cmd,  qq({ '$cmd[0]' });
        $cmd[1] = $fake_cmd_name;
        my ($pid, $xpid, $ppid, $cmd_name) = spawn_cmd @cmd;

        cmp_ok $_, '>', 0,  'valid looking pid' for ($pid, $xpid, $ppid);
        ok $pid eq $xpid || $pid eq $ppid, 'pid is expected value';
        is $cmd_name, $fake_cmd_name, 'modified process name'
    };
    is $@, '', 'indirect object syntax using block';

    eval {
        my @cmd = @cmd;
        unshift @cmd, q($real);
        $cmd[1] = $fake_cmd_name;
        my ($pid, $xpid, $ppid, $cmd_name) = spawn_cmd @cmd;

        cmp_ok $_, '>', 0,  'valid looking pid' for ($pid, $xpid, $ppid);
        ok $pid eq $xpid || $pid eq $ppid, 'pid is expected value';
        is $cmd_name, $fake_cmd_name, 'modified process name'
    };
    is $@, '', 'indirect object syntax using scalar variable';
};

done_testing;
