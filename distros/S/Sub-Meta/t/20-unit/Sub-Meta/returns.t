use Test2::V0;

use Sub::Meta;
use Sub::Meta::Test qw(sub_meta);

subtest 'set Sub::Meta::Returns' => sub {
    my $returns = Sub::Meta::Returns->new('Int');

    my $meta = Sub::Meta->new;
    is $meta->set_returns($returns), $meta, 'set_returns';

    is $meta, sub_meta({
        returns => $returns,
    });
};

subtest 'set object' => sub {
    my $meta = Sub::Meta->new;
    my $obj = bless {}, 'Foo';

    $meta->set_returns($obj);

    note '$obj will be treated as type';
    is $meta, sub_meta({
        returns => Sub::Meta::Returns->new($obj),
    });
};

done_testing;
