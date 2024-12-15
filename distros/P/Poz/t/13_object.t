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

done_testing;
