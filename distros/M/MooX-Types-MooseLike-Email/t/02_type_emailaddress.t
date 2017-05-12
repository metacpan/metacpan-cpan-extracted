use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

{
  package MyClass;
  use Moo;
  use MooX::Types::MooseLike::Email qw/EmailAddress/;
  has 'email' => ( isa => EmailAddress, is => 'ro', required => 1 );
}

lives_ok { MyClass->new( email => 'foo@example.com') }
    'foo@example.com is an ok email';
throws_ok { MyClass->new( email => 'bar..@example.com' ) }
    qr/a valid e-mail/, 'Throws as "bar..@example.com" is not a valid email';
throws_ok { MyClass->new( email => 'buz' ) }
    qr/a valid e-mail/, 'Throws as "buz" is not a valid email';
