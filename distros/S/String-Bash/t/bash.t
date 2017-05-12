
use strict;
use warnings;

use Test::More tests => 226;
use Test::NoWarnings;

use String::Bash qw( bash );

my @tests = (
    '%{param_name}' => 'parram_name',
    '%{param_name:-not used}' => 'parram_name',
    '%{not_set:+replace_not_set}' => '',
    '%{param_name:+replace_param_name}' => 'replace_param_name',
    '%{not_set:-default}' => 'default',
    '%{param_name:2}' => 'rram_name',
    '%{param_name:2:2}' => 'rr',
    '%{nested1:-%{nested2:-%{nested3}}}' => 'nested2',
    '%{param_name#par}' => 'ram_name',
    '%{param_name#par*}' => 'ram_name',
    '%{param_name#pa*r}' => 'ram_name',
    '%{param_name##pa*r}' => 'am_name',
    '%{param_name%r*e}' => 'par',
    '%{param_name%%r*e}' => 'pa',
    '%{param_name/r/l}' => 'palram_name',
    '%{param_name//r/l}' => 'pallam_name',
    '%{param_name/#r/l}' => 'parram_name',
    '%{param_name/#p/l}' => 'larram_name',
    '%{param_name/%r/l}' => 'parram_name',
    '%{param_name/%e/l}' => 'parram_naml',
    '%{param_name/r/}' => 'param_name',
    '%{param_name/r}' => 'param_name',

    '%{#param_name}' => 11,
    '%{param_name#parram_}' => 'name',
    '%{param_name:7}' => 'name',
    '%{#nested2}' => 7,
    '%{param_name:%{#nested2}}' => 'name',
    '%{not_set:-was not set} %{not_set:=is now set} %{not_set}'
        => 'was not set is now set is now set',
    '%{param_name^}' => 'Parram_name',
    '%{param_name^^}' => 'PARRAM_NAME',
    '%{param_name^?}' => 'Parram_name',
    '%{param_name^^?}' => 'PARRAM_NAME',
    '%{param_name^[pa]}' => 'Parram_name',
    '%{param_name^^[pa]}' => 'PArrAm_nAme',
    '%{param_name^p}' => 'Parram_name',
    '%{param_name^^a}' => 'pArrAm_nAme',

    '%{param_name_uc,}' => 'pARRAM_NAME',
    '%{param_name_uc,,}' => 'parram_name',
    '%{param_name_uc,?}' => 'pARRAM_NAME',
    '%{param_name_uc,,?}' => 'parram_name',
    '%{param_name_uc,[PA]}' => 'pARRAM_NAME',
    '%{param_name_uc,,[PA]}' => 'paRRaM_NaME',
    '%{param_name_uc,P}' => 'pARRAM_NAME',
    '%{param_name_uc,,A}' => 'PaRRaM_NaME',

);

{
    my $param_name = 'parram_name';
    my $param_name_uc = 'PARRAM_NAME';
    my $not_set;
    my $with_offset = 'with_offset';
    my $nested1;
    my $nested2 = 'nested2';
    my $nested3 = 'nested3';

    for ( my $i = 0; $i < @tests ; $i+=2 ) {
        my ($format, $expected) = @tests[ $i .. $i+1];
        my $result = bash $format;
        is $result, $expected, "$format as expected ($expected)";
    }

    is $not_set, 'is now set', "not_set set by :=word";

};

{
    package Test::String::Bash::Scope;

    use Test::More;
    use String::Bash qw( bash );

    my $param_name = 'outer param_name';

    sub outer_sub {
        my $param_name = 'outer parram_name';
        my $param_name_uc = 'outer PARRAM_NAME';
        my $not_set = 'outer not_set';
        my $with_offset = 'outer with_offset';
        my $nested1 = 'outer nested1';
        my $nested2 = 'outer nested2';
        my $nested3 = 'outer nested3';

        inside_sub();
    }

    sub inside_sub {
        my $param_name = 'parram_name';
        my $param_name_uc = 'PARRAM_NAME';
        my $not_set;
        my $with_offset = 'with_offset';
        my $nested1;
        my $nested2 = 'nested2';
        my $nested3 = 'nested3';

        for ( my $i = 0; $i < @tests ; $i+=2 ) {
            my ($format, $expected) = @tests[ $i .. $i+1];
            my $result = bash($format);
            is $result, $expected, "$format as expected ($expected)";

        }

        is $not_set, 'is now set', "not_set set by :=word";
    };
    outer_sub();
};

{
    package Test::String::Bash::Object;

    sub new {
        return bless {
            param_name => 'parram_name',
            param_name_uc => 'PARRAM_NAME',
            not_set => undef,
            with_offset => 'with_offset',
            nested1 => undef,
            nested2 => 'nested2',
            nested3 => 'nested3',
        }, shift
    };

    for my $m ( qw( param_name param_name_uc not_set with_offset nested1
        nested2 nested3 ) ) {

        no strict 'refs';
        *{"Test::String::Bash::Object::$m"} = sub {
            my $self = shift;

            if ( @_ ) { $self->{$m} = shift; }
            return $self->{$m};
        }
    }

    package Test::String::Bash::Object::Bash;

    use Test::More;
    use String::Bash qw( bash );

    my $obj = Test::String::Bash::Object->new;

    for ( my $i = 0; $i < @tests ; $i+=2 ) {
        my ($format, $expected) = @tests[ $i .. $i+1];
        my $result = bash($format, $obj);
        is $result, $expected, "$format as expected ($expected)";

    }

    is $obj->not_set, 'is now set', "not_set set by :=word";
}

{
    package Test::String::Bash::HashRef;

    use Test::More;
    use String::Bash qw( bash );

    my $hashref = {
        param_name => 'parram_name',
        param_name_uc => 'PARRAM_NAME',
        not_set => undef,
        with_offset => 'with_offset',
        nested1 => undef,
        nested2 => 'nested2',
        nested3 => 'nested3',
    };

    for ( my $i = 0; $i < @tests ; $i+=2 ) {
        my ($format, $expected) = @tests[ $i .. $i+1];
        my $result = bash($format, $hashref);
        is $result, $expected, "$format as expected ($expected)";

    }

    is $hashref->{not_set}, 'is now set', "not_set set by :=word";
}

{
    package Test::String::Bash::Hash;

    use Test::More;
    use String::Bash qw( bash );

    my %hash = (
        param_name => 'parram_name',
        param_name_uc => 'PARRAM_NAME',
        not_set => undef,
        with_offset => 'with_offset',
        nested1 => undef,
        nested2 => 'nested2',
        nested3 => 'nested3',
    );

    for ( my $i = 0; $i < @tests ; $i+=2 ) {
        my ($format, $expected) = @tests[ $i .. $i+1];
        my $result = bash($format, %hash);
        is $result, $expected, "$format as expected ($expected)";

    }

    isnt $hash{not_set}, 'is now set', "not_set set by :=word discarded";
}

