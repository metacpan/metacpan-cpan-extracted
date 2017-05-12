use strict;
use warnings;

use Test::More 'tests' => 39;

package MyBase; {
    use Object::InsideOut;

    my @name :Field('Get' => 'get_name');
    my @rank :Field('Std' => 'rank');
    my @snum :Field('Get' => 'get_snum');
    my @priv :Field('get/set' => 'priv');
    my @def  :Field('Get' => 'get_default');

    my %init_args :InitArgs = (
        'name' => { 'Field' => \@name },
        'rank' => { 'Field' => \@rank },
        'SNUM' => {
            'Regexp'    => qr/^snum$/i,
            'Mandatory' => 1
        },
        'PRIV' => qr/^priv(?:ate)?$/,
        'def'  => {
            'Field'   => \@def,
            'Default' => 'MyBase::def',
        },
    );

    sub init :Init
    {
        my ($self, $args) = @_;

        Test::More::is(ref($args), 'HASH'
                            => 'Args passed to MyBase::init in hash-ref');

        $self->set(\@priv, $args->{'PRIV'});
        Test::More::is($priv[$$self], 'MyBase::priv'
                            => 'MyBase priv arg unpacked correctly');

        $self->set(\@snum, $args->{'SNUM'} . '!');
        Test::More::is($snum[$$self], 'MyBase::snum!'  => 'MyBase snum arg unpacked correctly');
    }

    sub verify :Cumulative {
        my $self = $_[0];

        Test::More::is($name[$$self], 'MyBase::name'  => 'MyBase::name initialized');
        Test::More::is($rank[$$self], 'MyBase::rank'  => 'MyBase::rank initialized');
        Test::More::is($snum[$$self], 'MyBase::snum!' => 'MyBase::snum initialized');
        Test::More::is($priv[$$self], 'MyBase::priv'  => 'MyBase::name initialized');
        Test::More::is($def[$$self],  'MyBase::def'   => 'MyBase::def initialized');
    }
}


package Der; {
    use Object::InsideOut qw(MyBase);

    my @name :Field;
    my @rank :Field;
    my @snum :Field('Get' => 'get_snum');
    my @priv :Field('Get' => 'get_priv');
    my @def  :Field('Get' => 'get_default');

    my %init_args :InitArgs = (
        'name' => { 'Field' => \@name },
        'rank' => { 'Field' => \@rank },
        'snum' => { 'Field' => \@snum },
        'priv' => { 'Field' => \@priv },
        'def'  => {
            'Field'   => \@def,
            'Default' => 'default def',
        },
    );

    sub init :Init
    {
        my ($self, $args) = @_;

        Test::More::is(ref($args), 'HASH'
                            => 'Args passed to Der::init in hash-ref');
    }

    sub verify :Cumulative {
        my $self = $_[0];

        Test::More::is($name[$$self], 'MyBase::name' => 'Der::name initialized');
        Test::More::is($rank[$$self], 'generic rank' => 'Der::rank initialized');
        Test::More::is($snum[$$self], 'Der::snum'    => 'Der::snum initialized');
        Test::More::is($priv[$$self], 'Der::priv'    => 'Der::name initialized');
        Test::More::is($def[$$self],  'Der::def'     => 'Der::def initialized');
    }
}


package main;

MAIN:
{
    my $obj = MyBase->new({
        name => 'MyBase::name',
        rank => 'generic rank',
        snum => 'MyBase::snum',
        priv => 'generic priv',
        MyBase => {
            rank => 'MyBase::rank',
            private => 'MyBase::priv',
        }
    });

    can_ok($obj, qw(new clone DESTROY CLONE get_name get_rank set_rank
                        get_snum priv get_default verify));
    $obj->verify();

    $obj->priv('Modified');
    is($obj->priv(), 'Modified' => 'MyBase combined accessor');

    my $derobj = Der->new({
        name => 'MyBase::name',
        rank => 'generic rank',
        snum => 'MyBase::snum',
        priv => 'generic priv',
        MyBase => {
            rank => 'MyBase::rank',
            priv => 'MyBase::priv',
        },
        Der => {
            snum => 'Der::snum',
            priv => 'Der::priv',
            def  => 'Der::def',
        },
    });

    can_ok($derobj, qw(new clone DESTROY CLONE get_name get_rank set_rank
                        get_snum get_priv get_default verify));
    $derobj->verify();

    is($derobj->get_name(), 'MyBase::name'  => 'Der name read accessor');
    is($derobj->get_rank(), 'MyBase::rank'  => 'Der rank read accessor');
    is($derobj->get_snum(), 'Der::snum'     => 'Der rank read accessor');
    is($derobj->get_priv(), 'Der::priv'     => 'Der priv read accessor');

    $derobj->set_rank('new rank');
    is($derobj->get_rank(), 'new rank'      => 'Der rank write accessor');

    eval { $derobj->set_name('new name') };
    ok($@->error() =~ m/^Can't locate object method "set_name" via package "Der"/
                                            => 'Read only name attribute');

    my $der2 = Der->new({
        name => undef,
        rank => 'generic rank',
        priv => '',
        MyBase => {
            rank => 'MyBase::rank',
            snum => 'MyBase::snum',
            priv => 'MyBase::priv',
        },
        Der => {
            snum => 0,
        },
    });

    my $name = $der2->get_name();
    ok(! defined($name)      => 'undef values processes as initializers');
    is($der2->get_snum(), 0  => 'False values allowable as initializers');
    is($der2->get_priv(), '' => 'False values allowable as initializers');

    eval { my $obj2 = MyBase->new(
                                    name => undef,
                                    rank => 'generic rank',
                                    priv => '',
                                    MyBase => {
                                        rank => 'MyBase::rank',
                                        priv => 'MyBase::priv',
                                    },
                                    Der => {
                                        snum => 'MyBase::snum',
                                    }
                                  );
    };
    if (my $e = OIO->caught()) {
        ok($e->error() =~ /Missing mandatory initializer/
                                => 'Missing mandatory initializer caught');
    } else {
        fail("Uncaught exception: $@");
    }
}

exit(0);

# EOF
