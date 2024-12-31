use strict;
use utf8;
use Test::More;
use Test::Exception;
use Poz qw/z/;
use Time::Piece ();
use Data::UUID ();

my $bookSchema = z->object({
    id         => z->string->uuid->default(sub { Data::UUID->new->create_str }),
    title      => z->string,
    author     => z->string->default("Anonymous"),
    published  => z->date,
    created_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
    updated_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
})->as("My::Book");

my $book = $bookSchema->parse({
    title     => "Spidering Hacks",
    author    => "Kevin Hemenway",
    published => "2003-10-01",
}) or die "Invalid book data";
isa_ok($book, "My::Book");
is($book->{title}, "Spidering Hacks");
is($book->{author}, "Kevin Hemenway");
is($book->{published}, "2003-10-01");

throws_ok(sub {
    $bookSchema->parse({
        title => "Eric Sink on the Business of Software",
        author => "Eric Sink",
        published => "2006-0i-01",
    });
}, qr/^Not a date on key `published`/);

my ($valid, $errors) = $bookSchema->safe_parse({
    title     => "Spidering Hacks",
    author    => "Kevin Hemenway",
    published => "2003-10-01",
});
isa_ok($valid, 'My::Book');
is($valid->{title}, "Spidering Hacks");
is($valid->{author}, "Kevin Hemenway");
is($valid->{published}, "2003-10-01");
is($errors, undef);

($valid, $errors) = $bookSchema->safe_parse({
    title => "Eric Sink on the Business of Software",
    author => "Eric Sink",
    published => "2006-0i-01",
});
is($valid, undef);
is_deeply($errors, [{key => "published", error => "Not a date"}]);

subtest 'isa' => sub {
    my $object = z->object({});
    isa_ok($object, 'Poz::Types', 'Poz::Types::object');
};

subtest 'safe_parse must handle error' => sub {
    my $object = z->object({});
    throws_ok(sub { $object->safe_parse({}) }, qr/^Must handle error/, 'Must handle error');
};

subtest 'object contains undefined value, schema has optional string array' => sub {
    my $object = z->object({
        name => z->string,
        keys => z->array(z->string)->optional,
    });
    my ($valid, $errors) = $object->safe_parse({
        name => "foo",
    });
    is_deeply($valid, {name => "foo", keys => undef});
    is($errors, undef);
};

subtest 'undefined value passes to standard object schema' => sub {
    my $object = z->object({
        name => z->string,
    });
    is_deeply($object->parse({name => 'tofu'}), {name => 'tofu'});
    throws_ok(sub { $object->parse() }, qr/^Invalid data: is not hashref on key `\(root\)`/, 'Invalid data: is not hashref');
};

subtest 'instance passes to standard object schema' => sub {
    my $object = z->object({
        name => z->string,
    });
    my $instance = bless {name => 'tofu'}, 'My::Object';
    is_deeply($object->parse($instance), $instance);
};

subtest 'instance passes to standard object schema as another class' => sub {
    my $object = z->object({
        name => z->string,
    })->as('My::AnotherObject');
    my $instance = bless {name => 'tofu'}, 'My::Object';
    my $parsed = $object->parse($instance);
    is_deeply($parsed, $instance);
    isa_ok($parsed, 'My::AnotherObject');
    isnt(ref($parsed), 'My::Object');
};

subtest 'instance passes to standard object schema as another class with is' => sub {
    my $object = z->object({
        name => z->string,
    })->is('My::Object');
    my $instance = bless {name => 'tofu'}, 'My::Object';
    my $parsed = $object->parse($instance);
    is_deeply($parsed, $instance);
    isa_ok($parsed, 'My::Object');

    my $another_instance = bless {name => 'tamago'}, 'My::AnotherObject';
    throws_ok(sub { $object->parse($another_instance) }, qr/^Invalid data: is not My::Object on key `\(root\)`/, 'Invalid data: is not My::Object');
};

done_testing;
