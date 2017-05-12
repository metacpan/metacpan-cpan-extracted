# perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POOF-Properties.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
# 1
BEGIN { use_ok('POOF::Properties::Array', 'Module failed to load') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use POOF::DataType;

our $errors = {};

my $self = 'main';
my $ExceptionHandler = \&Errors;
my $c1;
my $def =
{
    'class'   => 'main',
    'name'    => 'Engines',
    'access'  => 'Public',
    'otype'   => 'POOF::Example::Engine',
};

tie @{$c1}, 'POOF::Properties::Array', $def, $self, $ExceptionHandler;


# 2
ok( (defined $c1 && ref($c1) ? 1 : 0), 'Making sure the object is valid' );

use POOF::Example::Engine;

my $t1 = [
    POOF::Example::Engine->new,
    POOF::Example::Engine->new,
    POOF::Example::Engine->new,
    POOF::Example::Engine->new,
];

@{$c1} = @{$t1};

# 3
is_deeply(
    $t1,
    $c1,
    'Problems with fetch or store'
); 

# 3
ok((
    @{$t1} eq @{$c1}
    ),'Problems with fetchsize'
);

ok((
    $#{$t1} eq $#{$c1}
    ),'Problems with fetchsize'
); 

delete $c1->[0];
delete $t1->[0];

ok((
    @{$t1} eq @{$c1}
    ),'Problems with delete'
);

ok((
    exists $t1->[0] eq exists $c1->[0]
    ),'Problems with exists'
);


## 4
$c1->[4] = 'something bad';

ok((
    Errors() == 1 && exists &GetErrors->{ 'Engines' }
        ? 1
        : 0 ), 'Checking the exception mechanism'); 




our $ERRORS = {};
sub Errors
{
    my ($obj,$k,$e) = @_;
    return scalar keys %{$ERRORS} if scalar @_ <= 1;
    return delete $ERRORS->{ $k } if scalar @_ == 2;
    return $ERRORS->{ $k } = $e   if scalar @_ == 3;
    return;
}

sub GetErrors
{
    return
        ref $ERRORS
            ? $ERRORS
            : {};
}
