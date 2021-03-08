use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warnings;

use Protocol::FIX::Field;
use Protocol::FIX::Group;
use Protocol::FIX::Component;
use Protocol::FIX::TagsAccessor;

subtest "flat accessor" => sub {
    my $f1 = Protocol::FIX::Field->new(1, 'Username', 'STRING');
    my $f2 = Protocol::FIX::Field->new(2, 'Password', 'STRING');

    my $ta = Protocol::FIX::TagsAccessor->new([
        $f1 => 'my-login',
        $f2 => 'my-secret-pass',
    ]);

    is $ta->value('Username'), 'my-login';
    is $ta->value('Password'), 'my-secret-pass';

    is $ta->value('not-available'), undef;
};

subtest "component accessor" => sub {
    my $f1 = Protocol::FIX::Field->new(1, 'Username', 'STRING');
    my $f2 = Protocol::FIX::Field->new(2, 'Password', 'STRING');

    my $c = Protocol::FIX::Component->new(
        'Credentials',
        [
            $f1 => 0,
            $f2 => 0
        ]);

    my $ta_inner = Protocol::FIX::TagsAccessor->new([
        $f1 => 'my-login',
        $f2 => 'my-secret-pass',
    ]);

    my $ta_outer = Protocol::FIX::TagsAccessor->new([$c => $ta_inner]);

    is $ta_outer->value('Credentials')->value('Username'), 'my-login';
    is $ta_outer->value('Credentials')->value('Password'), 'my-secret-pass';
};

subtest "group accessor" => sub {
    my $f0 = Protocol::FIX::Field->new(3, 'NoCredentials', 'NUMINGROUP');
    my $f1 = Protocol::FIX::Field->new(1, 'Username',      'STRING');
    my $f2 = Protocol::FIX::Field->new(2, 'Password',      'STRING');

    my $g = Protocol::FIX::Group->new(
        $f0,
        [
            $f1 => 0,
            $f2 => 0
        ]);
    my @tag_accessors =
        map { Protocol::FIX::TagsAccessor->new([$f1 => $_->[0], $f2 => $_->[1],]); } ([qw/my-login my-secret/], [qw/your-login your-secret/]);
    my $group_accessor = Protocol::FIX::TagsAccessor->new([$g => \@tag_accessors]);

    my $c  = Protocol::FIX::Component->new('CredentialGroups', [$g => 0]);
    my $ta = Protocol::FIX::TagsAccessor->new([$c => $group_accessor]);

    is $ta->value('CredentialGroups')->value('NoCredentials')->[0]->value('Username'), 'my-login';
    is $ta->value('CredentialGroups')->value('NoCredentials')->[0]->value('Password'), 'my-secret';
    is $ta->value('CredentialGroups')->value('NoCredentials')->[1]->value('Username'), 'your-login';
    is $ta->value('CredentialGroups')->value('NoCredentials')->[1]->value('Password'), 'your-secret';
};

done_testing;
