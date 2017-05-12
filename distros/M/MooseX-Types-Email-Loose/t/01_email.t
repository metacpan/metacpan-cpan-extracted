use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

{
    package MyClass;
    use Moose;
    use MooseX::Types::Email::Loose qw/EmailAddressLoose EmailAddress/;
    use namespace::autoclean;
    has email       => ( isa => EmailAddress, is => 'rw' );
    has email_loose => ( isa => EmailAddressLoose, is => 'rw' );
}
my $myclass = MyClass->new;

subtest 'valid_rfc822' => sub {
    my $address = 'valid@example.com';
    lives_ok { $myclass->email($address) };
    lives_ok { $myclass->email_loose($address) };
};

subtest 'loose_rfc822' => sub {
    my $address = 'loose..@example.com';
    dies_ok  { $myclass->email($address) };
    lives_ok { $myclass->email_loose($address) };
};

subtest 'invalid_rfc822' => sub {
    my $address = 'invalid';
    dies_ok { $myclass->email($address) };
    dies_ok { $myclass->email_loose($address) };
};
