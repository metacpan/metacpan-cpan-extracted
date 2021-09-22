use Test2::V0;

use Sub::Meta::Creator;
use Sub::Meta::Finder::Default;

sub hello {}

subtest 'find_materials' => sub {
    is Sub::Meta::Finder::Default::find_materials('hello'), undef, 'not sub';
    is Sub::Meta::Finder::Default::find_materials(\&hello), { sub => \&hello };
};

subtest 'create' => sub {
    my $creator = Sub::Meta::Creator->new(
        finders => [ \&Sub::Meta::Finder::Default::find_materials ],
    );

    is $creator->create('hello'), undef, 'not sub';
    my $meta = $creator->create(\&hello);
    is $meta->sub, \&hello;
    is $meta->subname, 'hello';
};

done_testing;
