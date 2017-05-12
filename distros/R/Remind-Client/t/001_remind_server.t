use warnings;
use strict;

use Test::More tests => 20;
use Test::NoWarnings;

{
    package Remind::Client::Test001;

    use POSIX qw(:signal_h);
    use Test::More;
    use Test::Warn;

    BEGIN {
        use_ok 'Remind::Client'
            or BAIL_OUT("Failed to use Remind::Client");
    }

    use base 'Remind::Client';

    sub reminder {
        my ($self, %args) = @_;

        is_deeply [sort keys %args], [sort qw(message due_time reminder_time tag)],
            'reminder(): Got the right named parameters';
        like($args{message}, qr/^It's Time now$/, 'Got the right reminder');
        like($args{due_time}, qr/^\d+:\d+[ap]m$/, 'Got a valid due time');
        like($args{reminder_time}, qr/^\d+:\d+[ap]m$/, 'Got a valid reminder time');
        is $args{tag}, '*', 'Got a valid tag';

        ok $self->send(command => 'STATUS'), 'Sent a STATUS command';
    }

    sub queued {
        my ($self, %args) = @_;

        is_deeply [keys %args], [qw(count)],
            'queued() Got the right named parameters';
        is($args{count}, 0, "nothing queued");

        {
            no warnings 'redefine';
            *reminder = sub {}; # stop an infinite loop
        }

        my $r;
        warning_is {$r = $self->send()} "Missing required argument 'command'",
            'send with no arguments';
        ok !$r, 'returned false';
        warning_is {$r = $self->send(command => 'not_a_valid command')} "Invalid command: NOT_A_VALID COMMAND",
            'send with invalid command';
        ok !$r, 'returned false';

        ok kill(SIGHUP, $$), 'Go HUP yourself';
    }

    sub reread {
        my ($self, %args) = @_;

        is_deeply [keys %args], [],
            'reload() Got the right named parameters';
        ok $self->send(command => 'EXIT'), 'Sent a EXIT command';
    }
}

use File::Temp;
use POSIX qw(strftime locale_h);

my $TEST_REMINDERS = File::Temp->new(TEMPLATE => 'reminders-XXXXXX');
# fire off a reminder in about one minute
note "Writing temporary reminder config: $TEST_REMINDERS";

# Older versions of remind don't support ISO 8601-style dates
# (%Y-%m-%d), so we have to do this:
my $old_lc_time = setlocale(LC_TIME);
note "Old LC_TIME: $old_lc_time";
note "Set LC_TIME to: ".setlocale(LC_TIME, 'C');
my $reminder = strftime("REM %d %b %Y AT %H:%M MSG %%\"It's Time%%\" %%1%%", localtime(time));
note "Setting reminder: $reminder";
$TEST_REMINDERS->printflush("$reminder\n");
note "Set LC_TIME to: ".setlocale(LC_TIME, $old_lc_time);

ok my $rc = Remind::Client::Test001->new(filename => $TEST_REMINDERS->filename()),
    'Made a new Remind::Client::Test001 object';
isa_ok $rc, 'Remind::Client::Test001';
isa_ok $rc, 'Remind::Client';

note 'Setting 15 second alarm';
local $SIG{ALRM} = sub { die "Took too long to receive a reminder"; };
alarm 15;
note 'Running $rc->run()';
$rc->run();

