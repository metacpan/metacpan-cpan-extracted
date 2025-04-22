use Test2::V0 qw(is done_testing);
use Test2::Require::Module 'Type::Tiny' => '2.000000';
use Test2::Require::Module 'kura';
use feature qw( state );

use Result::Simple qw( ok err result_for chain pipeline);
use Types::Standard -types;

use kura Error   => Dict[message => Str];
use kura Request => Dict[name => Str, age => Int];

result_for validate_name => Request, Error;

sub validate_name {
    my $req = shift;
    my $name = $req->{name};
    return err({ message => 'No name'}) unless defined $name;
    return err({ message => 'Empty name'}) unless length $name;
    return err({ message => 'Reserved name'}) if $name eq 'root';
    return ok($req);
}

result_for validate_age => Request, Error;

sub validate_age {
    my $req = shift;
    my $age = $req->{age};
    return err({ message => 'No age'}) unless defined $age;
    return err({ message => 'Invalid age'}) unless $age =~ /\A\d+\z/;
    return err({ message => 'Too young age'}) if $age < 18;
    return ok($req);
}

result_for validate_req => Request, Error;

sub validate_req {
    my $req = shift;
    my $err;

    ($req, $err) = validate_name($req);
    return err($err) if $err;

    ($req, $err) = validate_age($req);
    return err($err) if $err;

    return ok($req);
}

# my $req = validate_req({ name => 'taro', age => 42 });
# => Throw an exception, because `validate_req` requires calling in a list context to handle an error.

my ($req1, $err1) = validate_req({ name => 'taro', age => 42 });
is $req1, { name => 'taro', age => 42 };
is $err1, undef;

my ($req2, $err2) = validate_req({ name => 'root', age => 20 });
is $req2, undef;
is $err2, { message => 'Reserved name' };

# Following are the same as above but using `chain` and `pipeline` functions.

sub validate_req_with_chain {
    my $req = shift;

    my @r = ok($req);
    @r = chain(validate_name => @r);
    @r = chain(validate_age => @r);
    return @r;
}

sub validate_req_with_pipeline {
    my $req = shift;

    state $code = pipeline qw( validate_name validate_age );
    $code->(ok($req));
}

done_testing
