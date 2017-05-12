# -*- perl -*-

use Test::Most;

use Test::DBIx::Class::Factory;
use Test::DBIx::Class {
            schema_class => 'Test::DBIx::Class::Example::Schema',
};

BEGIN { use_ok( 'Test::DBIx::Class::Factory' ); }

my $schema = Schema;
my $factory = Test::DBIx::Class::Factory->new ( schema => $schema );


my $word = $factory->random_word;

like($word,qr/^[a-z]+$/i);
ok(length($word) < 11,"All words should be less than 11 length");

my $string = $factory->random_string;
like($string,qr/^[a-z ]+$/i);
my $string2 = $factory->random_string(-1);
like($string2,qr/^[a-z ]+$/i);
my $string3 = $factory->random_string(0);
like($string3,qr/^[a-z ]+$/i);
my $string4 = $factory->random_string(5);
like($string4,qr/^[a-z]+ [a-z]+ [a-z]+ [a-z]+ [a-z]+$/i);


done_testing;

