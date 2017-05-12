use strict;
use Test::More;

BEGIN {
    use_ok 'Parse::Crontab';
}

my $crontab = new_ok 'Parse::Crontab', [
    content => <<'...',
# comment
HOGE=FUGA
* * * * * perl
@daily perl
...
];

ok $crontab->is_valid;
is scalar @{$crontab->entries}, 4;
isa_ok $crontab->entries->[0], 'Parse::Crontab::Entry::Comment';
isa_ok $crontab->entries->[1], 'Parse::Crontab::Entry::Env';
isa_ok $crontab->entries->[2], 'Parse::Crontab::Entry::Job';
isa_ok $crontab->entries->[3], 'Parse::Crontab::Entry::Job';

my @jobs = $crontab->jobs;
is scalar @jobs, 2;
is $jobs[0]->command, 'perl';

$crontab = new_ok 'Parse::Crontab', [
    content => <<'...',
# comment
"HOGE=FUGA
* * * *R * perl
@daily perl
...
];

ok !$crontab->is_valid;
ok $crontab->error_messages;


$crontab = new_ok 'Parse::Crontab', [
    content => <<'...',
*/1 * * * * songmu perl
@daily    songmu perl
...
    has_user_field => 1,
];

for my $job ($crontab->jobs) {
    is $job->user, 'songmu';
    is $job->command, 'perl';
}

done_testing;
