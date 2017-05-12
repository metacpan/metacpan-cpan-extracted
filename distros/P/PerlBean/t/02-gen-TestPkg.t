# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use PerlBean;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use IO::File;
use PerlBean::Attribute::Factory;

my @attribute_class = (
    {
        method_factory_name => 'b1',
        type => 'BOOLEAN',
    },
    {
        method_factory_name => 'b2',
        type => 'BOOLEAN',
        default_value => 1,
    },
    {
        method_factory_name => 'b3',
        type => 'BOOLEAN',
        mandatory => 1,
    },
    {
        method_factory_name => 'b4',
        type => 'BOOLEAN',
        default_value => 1,
        mandatory => 1,
    },

    {
        method_factory_name => 's1',
        type => 'SINGLE',
    },
    {
        method_factory_name => 's2',
        type => 'SINGLE',
        allow_empty => 0,
    },
    {
        method_factory_name => 's3',
        type => 'SINGLE',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
    },
    {
        method_factory_name => 's4',
        type => 'SINGLE',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
    },
    {
        method_factory_name => 's5',
        type => 'SINGLE',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
        allow_value => [qw (valueFoo valueBar)],
    },
    {
        method_factory_name => 's6',
        type => 'SINGLE',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
        allow_value => [qw (valueFoo valueBar)],
        mandatory => 1,
    },

    {
        method_factory_name => 'm1',
        type => 'MULTI',
    },
    {
        method_factory_name => 'm2',
        type => 'MULTI',
        allow_empty => 0,
    },
    {
        method_factory_name => 'm3',
        type => 'MULTI',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
    },
    {
        method_factory_name => 'm4',
        type => 'MULTI',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
    },
    {
        method_factory_name => 'm5',
        type => 'MULTI',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
        allow_value => [qw (valueFoo valueBar)],
    },
    {
        method_factory_name => 'm6',
        type => 'MULTI',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
        allow_value => [qw (valueFoo valueBar)],
        mandatory => 1,
    },
    {
        method_factory_name => 'm7',
        type => 'MULTI',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
        allow_value => [qw (valueFoo valueBar)],
        mandatory => 1,
        ordered => 1,
    },
    {
        method_factory_name => 'm8',
        type => 'MULTI',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
        allow_value => [qw (valueFoo valueBar)],
        mandatory => 1,
        unique => 1,
    },
    {
        method_factory_name => 'm9',
        type => 'MULTI',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
        allow_value => [qw (valueFoo valueBar)],
        mandatory => 1,
        ordered => 1,
        unique => 1,
    },
    {
        method_factory_name => 'm10',
        type => 'MULTI',
        allow_empty => 0,
        allow_isa => [qw (isaFoo isaBar)],
        allow_ref => [qw (refFoo refBar)],
        allow_rx => [qw (^\d+$ ^\S+$)],
        allow_value => [qw (valueFoo valueBar)],
        mandatory => 1,
        associative => 1,
        unique => 1,
    },
);
my @constr_opt = (
    {
        method_name => 'new_by_foo',
        parameter_description => 'FOO',
        description => <<EOF,
Constructs a new object using foo. C<FOO> must be a C<FOO> reference. On error an exception C<Error::Simple> is thrown.
EOF
    },
);
my @meth_opt = (
    {
        method_name => 'do_foo',
        parameter_description => 'BAR',
        description => <<EOF,
Does foo. C<BAR> must be a C<BAR> reference. On error an exception C<Error::Simple> is thrown.
EOF
    },
);

my $bean = PerlBean->new ({
    package => 'tmp::TestPkg',
    autoloaded => 0,
});
my $factory = PerlBean::Attribute::Factory->new ();

foreach my $attribute_class (@attribute_class) {
    $attribute_class->{perl_bean} = $bean;
    my $attribute = $factory->create_attribute ($attribute_class);
    $attribute->{short_description} = $attribute->{method_factory_name};
    $bean->add_method_factory($attribute);
}
foreach my $meth_opt (@meth_opt) {
    require PerlBean::Method;
    my $meth = PerlBean::Method->new ($meth_opt);
    $bean->add_method($meth);
}
foreach my $meth_opt (@constr_opt) {
    require PerlBean::Method::Constructor;
    my $meth = PerlBean::Method::Constructor->new ($meth_opt);
    $bean->add_method ($meth);
}

my $fh = IO::File->new ('> tmp/TestPkg.pm');
$bean->write ($fh);
$fh->close ();

system ("$^X -c tmp/TestPkg.pm > /dev/null 2>&1");
if ($?>>8) {
    ok (0);
} else {
    ok (1);
}
