#!perl
use lib 't/lib';
use Test::Sietima;

package Sietima::Role::ForTesting {
    use Moo::Role;
    use Sietima::Policy;
    use Sietima::Types qw(AddressFromStr);

    around list_addresses => sub($orig,$self) {
        return {
            $self->$orig->%*,
            test1 => AddressFromStr->coerce('name <someone@example.com>'),
            'test+2' => 'http://test.example.com',
            test3 => ['name (comment) <other@example.com>','mailto:thing@example.com' ],
        };
    };
};

package Sietima::Role::ForTesting2 {
    use Moo::Role;
    use Sietima::Policy;
    use Sietima::Types qw(AddressFromStr);

    around list_addresses => sub($orig,$self) {
        return {
            $self->$orig->%*,
            post => 0,
        };
    };
};

subtest 'list headers should be added' => sub {
    my $s = make_sietima(
        with_traits => ['Headers','WithOwner','ForTesting'],
        name => 'test-list',
        owner => 'owner@example.com',
        subscribers => [
            'one@users.example.com',
            'two@users.example.com',
        ],
    );

    test_sending(
        sietima => $s,
        mails => [
            object {
                call sub { +{ shift->header_raw_pairs } } => hash {
                    field 'List-Id' => 'test-list <sietima-test.list.example.com>';
                    field 'List-Owner' => '<mailto:owner@example.com>';
                    field 'List-Post' => '<mailto:sietima-test@list.example.com>';
                    field 'List-Test1' => '<mailto:someone@example.com>';
                    field 'List-Test-2' => '<http://test.example.com>';
                    field 'List-Test3' => '<mailto:other@example.com> (comment), <mailto:thing@example.com>';

                    field 'Date' => D();
                    field 'MIME-Version' => D();
                    field 'Content-Type' => D();
                    field 'Content-Transfer-Encoding' => D();
                    field 'From' => 'someone@users.example.com';
                    field 'To' => 'sietima-test@list.example.com';
                    field 'Subject' => 'Test Message';

                    end;
                };
            },
        ],
    );
};

subtest 'no-post list' => sub {
    my $s = make_sietima(
        with_traits => ['Headers','WithOwner','ForTesting2'],
        name => 'test-list',
        owner => 'owner@example.com',
        subscribers => [
            'one@users.example.com',
            'two@users.example.com',
        ],
    );

    test_sending(
        sietima => $s,
        mails => [
            object {
                call sub { +{ shift->header_raw_pairs } } => hash {
                    field 'List-Post' => 'NO';

                    etc;
                };
            },
        ],
    );
};

done_testing;
