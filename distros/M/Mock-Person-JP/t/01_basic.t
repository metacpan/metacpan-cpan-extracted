use strict;
use warnings;
use Mock::Person::JP;
use Test::More;
use Test::Fatal;

can_ok('Mock::Person::JP',               qw/new create_person/);
can_ok('Mock::Person::JP::Person',       qw/new name/);
can_ok('Mock::Person::JP::Person::Name', qw/new first_name last_name sei mei first_name_yomi last_name_yomi sei_yomi mei_yomi/);

subtest "create person" => sub {
    my $mpj = Mock::Person::JP->new;
    isa_ok($mpj->create_person(sex => 'female'),   'Mock::Person::JP::Person');
    isa_ok($mpj->create_person({ sex => 'male' }), 'Mock::Person::JP::Person');
};

subtest "sex option required" => sub {
    my $mpj = Mock::Person::JP->new;
    my $exception = exception { $mpj->create_person; };
    like($exception, qr/sex option required/);
};

subtest "unknown option" => sub {
    my $mpj = Mock::Person::JP->new;
    my $exception = exception { $mpj->create_person(sex => 'female', age => 12) };
    like($exception, qr/Unknown option: 'age'/);
};

subtest "unknown sex" => sub {
    my $mpj = Mock::Person::JP->new;
    my $exception = exception { $mpj->create_person(sex => 'otoko') };
    like($exception, qr/'male' or 'female'/);
};

done_testing;
