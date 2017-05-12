use Test::More tests => 18;

{
    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'word_histogram' => (
        metaclass => 'Collection::Bag',
        provides  => {
            add    => 'add_word',
            delete => 'delete_word',
            reset  => 'reset_word',
            get    => 'get_count_for',
            empty  => 'has_any_words',
            count  => 'num_words',
        }
    );
}

my $obj = MyClass->new;

my @providers = qw(
    add_word delete_word reset_word
    get_count_for has_any_words num_words
);
for my $method (@providers) {
    can_ok $obj => $method;
}

ok !$obj->has_any_words, 'provides empty ok, have no words';
is $obj->num_words => 0, 'provides count ok, have no words';

$obj->add_word('bar');
ok $obj->has_any_words, 'provides add ok, have words';
is $obj->num_words => 1, 'provides add ok, have 1 word';
is $obj->get_count_for('bar') => 1, 'provides get ok';

$obj->add_word('foo');
$obj->add_word('bar') for 1..4;
$obj->add_word('baz') for 1..10;
is $obj->num_words => 3, 'have 3 words';
is $obj->get_count_for('foo') => 1, 'count foo is 1';
is $obj->get_count_for('bar') => 5, 'count bar is 5';
is $obj->get_count_for('baz') => 10, 'count baz is 10';

$obj->reset_word('bar');
is $obj->get_count_for('bar') => 0, 'provides reset ok, count bar is 0';
is $obj->num_words => 3, 'still have 3 words';

$obj->delete_word('bar');
is $obj->num_words => 2, 'provides delete ok, have 2 words';
