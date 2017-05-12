use strict; use warnings;

use Scalar::Util qw(isweak);

use Test::More;
use Test::Fatal;

{ package Foo;

    use Moose;
    use MooseX::OmniTrigger;

    has bar => (is => 'rw', isa => 'Maybe[Bar]', omnitrigger => sub {

        my ($self, $attr_name, $new, $old) = @_;

        $new->[0]->foo($self) if defined($new->[0]);
    });

    has baz => (isa => 'Baz', reader => 'get_baz', writer => 'set_baz', omnitrigger => sub {

        my ($self, $attr_name, $new, $old) = @_;

        $new->[0]->foo($self);
    });
}

{ package Bar; use Moose; has foo => (is => 'rw', isa => 'Foo', weak_ref => 1); }
{ package Baz; use Moose; has foo => (is => 'rw', isa => 'Foo', weak_ref => 1); }

{
    my $foo = Foo->new; isa_ok($foo, 'Foo');
    my $bar = Bar->new; isa_ok($bar, 'Bar');
    my $baz = Baz->new; isa_ok($baz, 'Baz');

    is(exception { $foo->bar($bar) }, undef, '... did not die setting bar' );

    is($foo->bar, $bar, '... set the value foo.bar correctly'              );
    is($bar->foo, $foo, '... which in turn set the value bar.foo correctly');

    ok(isweak($bar->{foo}), '... bar.foo is a weak reference');

    is(exception { $foo->bar(undef) }, undef, '... did not die un-setting bar');

    is($foo->bar, undef, '... set the value foo.bar correctly'              );
    is($bar->foo, $foo , '... which in turn set the value bar.foo correctly');

    # test the writer

    is(exception { $foo->set_baz($baz) }, undef, '... did not die setting baz');

    is($foo->get_baz, $baz, '... set the value foo.baz correctly'              );
    is($baz->    foo, $foo, '... which in turn set the value baz.foo correctly');

    ok(isweak($baz->{foo}), '... baz.foo is a weak reference');
}

{
    my $bar = Bar->new                          ; isa_ok($bar, 'Bar');
    my $baz = Baz->new                          ; isa_ok($baz, 'Baz');
    my $foo = Foo->new(bar => $bar, baz => $baz); isa_ok($foo, 'Foo');

    is($foo->bar, $bar, '... set the value foo.bar correctly'              );
    is($bar->foo, $foo, '... which in turn set the value bar.foo correctly');

    ok(isweak($bar->{foo}), '... bar.foo is a weak reference');

    is($foo->get_baz, $baz, '... set the value foo.baz correctly'              );
    is($baz->    foo, $foo, '... which in turn set the value baz.foo correctly');

    ok(isweak($baz->{foo}), '... baz.foo is a weak reference');
}

# some errors

{ package Bling;

    use Moose;
    use MooseX::OmniTrigger;

    ::isnt(::exception { has('bling' => (is => 'rw', omnitrigger => 'Fail'   )) }, undef, '...an omnitrigger must be a CODE ref' );
    ::isnt(::exception { has('bling' => (is => 'rw', omnitrigger =>        [])) }, undef, '...an omnitrigger must be a CODE ref' );
}

# Triggers do not fire on built values -- BUT OMNITRIGGERS DO.

{ package Blarg; use Moose; use MooseX::OmniTrigger;

    has foo => (is => 'rw', omnitrigger => \&_capture_changes, default => sub { 'default foo value' }                                        );
    has bar => (is => 'rw', omnitrigger => \&_capture_changes,                                        lazy_build => 1                        );
    has baz => (is => 'rw', omnitrigger => \&_capture_changes,                                                        builder => '_build_baz');

    sub _build_bar { 'default bar value' }
    sub _build_baz { 'default baz value' }

    our (%trigger_calls, %trigger_vals);

    sub _capture_changes {

        my ($self, $attr_name, $new, $old) = @_;

        $trigger_calls{$attr_name}++;

        $trigger_vals{$attr_name} = $new->[0];
    }
}

{
    my $blarg; is(exception { $blarg = Blarg->new }, undef, 'Blarg->new() lives');

    ok($blarg, 'Have a $blarg');

    is($blarg->$_, "default $_ value", "$_ has default value") for qw(foo bar baz);

    is_deeply(\%Blarg::trigger_calls, {foo => 1, bar => 1, baz => 1}, 'all omnitriggers fired');

    $blarg->$_("Different $_ value") for qw(foo bar baz);

    is_deeply(\%Blarg::trigger_calls, { map({ $_ => 2 } qw/foo bar baz/) }, 'all omnitriggers fired on assign');

    is_deeply(\%Blarg::trigger_vals, { map({ $_ => "Different $_ value" } qw/foo bar baz/) }, 'all omnitriggers given assigned values');

    is(exception { $blarg = Blarg->new( map({ $_ => "Yet another $_ value" } qw/foo bar baz/)) }, undef, '->new() with parameters');

    is_deeply(\%Blarg::trigger_calls, { map({ $_ => 3 } qw/foo bar baz/) }, 'all omnitriggers fired once on construct');

    is_deeply(\%Blarg::trigger_vals, { map({ $_ => "Yet another $_ value" } qw/foo bar baz/) }, 'All triggers given assigned values');
}

# Triggers do not receive the meta-attribute as an argument, but do
# receive the old value -- BUT OMNITRIGGERS DO RECEIVE THE ATTRIBUTE NAME.

{ package Foo;

    use Moose;
    use MooseX::OmniTrigger;

    our @calls;

    has foo => (is => 'rw', omnitrigger => sub { push(@calls, [@_]) });
}

{
    my $attr = Foo->meta->get_attribute('foo');

    my $foo = Foo->new;

    $attr->set_value($foo, 2);

    is_deeply(\@Foo::calls, [[$foo, 'foo', [2], []]], 'omnitrigger called correctly on initial set via meta-API');

    @Foo::calls = ();

    $attr->set_value($foo, 3);

    is_deeply(\@Foo::calls, [[$foo, 'foo', [3], [2]]], 'omnitrigger called correctly on second set via meta-API');

    @Foo::calls = ();

    $attr->set_raw_value($foo, 4);

    is_deeply(\@Foo::calls, [], 'omnitrigger not called using set_raw_value method');

    @Foo::calls = ();
}

{
    my $foo = Foo->new(foo => 2);

    is_deeply(\@Foo::calls, [[$foo, 'foo', [2], []]], 'omnitrigger called correctly on construction');

    @Foo::calls = ();

    $foo->foo(3);

    is_deeply(\@Foo::calls, [[$foo, 'foo', [3], [2]]], 'omnitrigger called correctly on set (with old value)');

    @Foo::calls = ();

    Foo->meta->make_immutable, redo if Foo->meta->is_mutable;
}

done_testing;
