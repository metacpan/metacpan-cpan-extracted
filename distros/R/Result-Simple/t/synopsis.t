use Test2::V0;
use Test2::Require::Module 'Type::Tiny' => '2.000000';
use Test2::Require::Module 'kura';

# Enable type check. The default is false.
BEGIN { $ENV{RESULT_SIMPLE_CHECK_ENABLED} = 1 }

use Result::Simple;
use Types::Common -types;

use kura ErrorMessage => StrLength[3,];
use kura ValidName    => sub { my (undef, $e) = validate_name($_); !$e };
use kura ValidAge     => sub { my (undef, $e) = validate_age($_); !$e };
use kura ValidUser    => Dict[name => ValidName, age => ValidAge];

sub validate_name {
    my $name = shift;
    return Err('No name') unless defined $name;
    return Err('Empty name') unless length $name;
    return Err('Reserved name') if $name eq 'root';
    return Ok($name);
}

sub validate_age {
    my $age = shift;
    return Err('No age') unless defined $age;
    return Err('Invalid age') unless $age =~ /\A\d+\z/;
    return Err('Too young age') if $age < 18;
    return Ok($age);
}

sub new_user :Result(ValidUser, ArrayRef[ErrorMessage]) {
    my $args = shift;
    my @errors;

    my ($name, $name_err) = validate_name($args->{name});
    push @errors, $name_err if $name_err;

    my ($age, $age_err) = validate_age($args->{age});
    push @errors, $age_err if $age_err;

    return Err(\@errors) if @errors;
    return Ok({ name => $name, age => $age });
}

my ($user1, $err1) = new_user({ name => 'taro', age => 42 });
is $user1, { name => 'taro', age => 42 };
is $err1, undef;

my ($user2, $err2) = new_user({ name => 'root', age => 1 });
is $user2, undef;
is $err2, ['Reserved name', 'Too young age'];

done_testing
