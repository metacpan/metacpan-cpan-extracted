use Test2::V0;

use Sub::Meta::Returns;
use Sub::Meta::Test qw(test_error_message);

subtest "{ scalar => 'Str' }" => sub {
    my $meta = Sub::Meta::Returns->new({ scalar => 'Str' });
    my @tests = (
        fail       => undef,                                             qr/^must be Sub::Meta::Returns. got: /,
        fail       => (bless {} => 'Some'),                              qr/^must be Sub::Meta::Returns. got: Some/,
        fail       => { scalar => 'Int' },                               qr/^invalid scalar return. got: Int, expected: Str/,
        relax_pass => { scalar => 'Str', list => 'Str' },                qr/^should not have list return/,
        relax_pass => { scalar => 'Str', void => 'Str' },                qr/^should not have void return/,
        pass       => { scalar => 'Str' },                               qr//,
        pass       => { scalar => 'Str', list => undef, void => undef }, qr//,
    );
    test_error_message($meta, @tests);
};

subtest "{ list => 'Str' }" => sub {
    my $meta = Sub::Meta::Returns->new({ list => 'Str' });
    my @tests = (
        fail       => { list => 'Int' },                                 qr/^invalid list return. got: Int, expected: Str/,
        relax_pass => { list => 'Str', scalar => 'Str' },                qr/^should not have scalar return/,
        relax_pass => { list => 'Str', void => 'Str' },                  qr/^should not have void return/,
        pass       => { list => 'Str' },                                 qr//,
        pass       => { list => 'Str', scalar => undef, void => undef }, qr//,
    );
    test_error_message($meta, @tests);
};

subtest "{ void => 'Str' }" => sub {
    my $meta = Sub::Meta::Returns->new({ void => 'Str' });
    my @tests = (
        fail       => { void => 'Int' },                                 qr/^invalid void return. got: Int, expected: Str/,
        relax_pass => { void => 'Str', scalar => 'Str' },                qr/^should not have scalar return/,
        relax_pass => { void => 'Str', list => 'Str' },                  qr/^should not have list return/,
        pass       => { void => 'Str' },                                 qr//,
        pass       => { void => 'Str', list => undef, scalar => undef }, qr//,
    );
    test_error_message($meta, @tests);
};

done_testing;
