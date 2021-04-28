use Test2::V0;

use Sub::Meta;
use Sub::Meta::Test qw(sub_meta);

use Sub::Identify ();
use Sub::Util ();
use attributes ();

sub test_sub {
    my ($sub, $expected) = @_;
    $expected //= {};

    my $ctx = context;
    is [ Sub::Identify::get_code_info($sub) ], $expected->{subinfo}, 'code subinfo';
    is Sub::Util::prototype($sub), $expected->{prototype}, 'code prototype';
    is [ attributes::get($sub) ], $expected->{attribute}, 'code attribute';
    $ctx->release;
    return;
}

subtest 'apply_subname' => sub {
    sub hello_subname {}
    my $meta = Sub::Meta->new(sub => \&hello_subname);
    is $meta->apply_subname('good_subname'), $meta, 'apply_subname';

    is $meta, sub_meta({
        sub         => \&hello_subname,
        subname     => 'good_subname',
        stashname   => 'main',
        fullname    => 'main::good_subname',
        subinfo     => ['main', 'good_subname'],
        file        => __FILE__,
        line        => 23,
        prototype   => undef,
        attribute   => [],
    });

    test_sub(\&hello_subname, {
        subinfo   => ['main', 'good_subname'],
        prototype => undef,
        attribute => [],
    });
};

subtest 'apply_prototype' => sub {
    sub hello_prototype {}
    my $meta = Sub::Meta->new(sub => \&hello_prototype);
    is $meta->apply_prototype('$$'), $meta, 'apply_prototype';

    is $meta, sub_meta({
        sub         => \&hello_prototype,
        subname     => 'hello_prototype',
        stashname   => 'main',
        fullname    => 'main::hello_prototype',
        subinfo     => ['main', 'hello_prototype'],
        file        => __FILE__,
        line        => 47,
        prototype   => '$$',
        attribute   => [],
    });

    test_sub(\&hello_prototype, {
        subinfo   => ['main', 'hello_prototype'],
        prototype => '$$',
        attribute => [],
    });
};

subtest 'apply_attribute' => sub {
    sub hello_attribute {}
    my $meta = Sub::Meta->new(sub => \&hello_attribute);
    is $meta->apply_attribute('method'), $meta, 'apply_attribute';

    is $meta, sub_meta({
        sub         => \&hello_attribute,
        subname     => 'hello_attribute',
        stashname   => 'main',
        fullname    => 'main::hello_attribute',
        subinfo     => ['main', 'hello_attribute'],
        file        => __FILE__,
        line        => 71,
        prototype   => undef,
        attribute   => ['method'],
    });

    test_sub(\&hello_attribute, {
        subinfo   => ['main', 'hello_attribute'],
        prototype => undef,
        attribute => ['method'],
    });
};

subtest 'apply_meta' => sub {
    sub hello_meta {}
    my $meta = Sub::Meta->new(sub => \&hello_meta);
    my $other = Sub::Meta->new(
        subname   => 'other_meta',
        prototype => '$',
        attribute => ['lvalue', 'method'],
    );

    is $meta->apply_meta($other), $meta, 'apply_meta';

    is $meta, sub_meta({
        sub         => \&hello_meta,
        subname     => 'other_meta',
        stashname   => 'main',
        fullname    => 'main::other_meta',
        subinfo     => ['main', 'other_meta'],
        file        => __FILE__,
        line        => 95,
        prototype   => '$',
        attribute   => ['lvalue','method'],
    });

    test_sub(\&hello_meta, {
        subinfo   => ['main', 'other_meta'],
        prototype => '$',
        attribute => ['lvalue', 'method'],
    });
};

subtest 'exceptions' => sub {
    sub hello_exceptions {}

    my $meta = Sub::Meta->new(sub => \&hello_exceptions);
    like dies { $meta->apply_attribute('foo') },
        qr/Invalid CODE attribute: foo/,
        'invalid attribute';

    like dies { Sub::Meta->new->apply_subname('hello') },
        qr/apply_subname requires subroutine reference/,
        'apply_subname requires subroutine reference';

    like dies { Sub::Meta->new->apply_prototype('$$') },
        qr/apply_prototype requires subroutine reference/,
        'apply_prototype requires subroutine reference';

    like dies { Sub::Meta->new->apply_attribute('lvalue') },
        qr/apply_attribute requires subroutine reference/,
        'apply_attribute requires subroutine reference';
};


done_testing;
