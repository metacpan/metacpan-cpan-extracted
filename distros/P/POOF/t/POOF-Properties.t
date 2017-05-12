# perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POOF-Properties.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
# 1
BEGIN { use_ok('POOF::Properties', 'Module failed to load') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use POOF::DataType;

our $errors = {};

my $self = 'main';
my $ExceptionHandler = \&pErrors;
my $RaiseException = 'trap';
my $hash = {};
my $definitions =
[
    {
        'class'   => 'main',
        'name'    => 'FirstName',
        'access'  => 'Public',
        'virtual' => 0,
        'data'    => POOF::DataType->new({'type' => 'string'})
    },
    {
        'class'   => 'main',
        'name'    => 'LastName',
        'access'  => 'Public',
        'virtual' => 0,
        'data'    => POOF::DataType->new({'type' => 'string'})
    },
    {
        'class'   => 'main',
        'name'    => 'Weight',
        'access'  => 'Public',
        'virtual' => 0,
        'data'    => POOF::DataType->new({'type' => 'float'})
    },
    {
        'class'   => 'main',
        'name'    => 'Height',
        'access'  => 'Public',
        'virtual' => 0,
        'data'    => POOF::DataType->new({'type' => 'float'})
    },
    {
        'class'   => 'main',
        'name'    => 'Gender',
        'access'  => 'Public',
        'virtual' => 0,
        'data'    => POOF::DataType->new({'type' => 'enum','options' => [qw(Male Female Other)]})
    },
];

tie %{$hash}, 'POOF::Properties', $definitions, $self, $ExceptionHandler;



# 2
ok( (defined $hash && ref($hash) ? 1 : 0), 'Making sure the object is valid' );

my $test1 = {
    'FirstName'  => 'Benny',
    'LastName'   => 'Millares',
    'Height'     => 0.0,
    'Weight'     => 0.0,
};

%{$hash} = %{$test1};

# 3
ok((
    $hash->{'FirstName'} eq $test1->{'FirstName'} &&
    $hash->{'LastName'}  eq $test1->{'LastName'}
        ? 1
        : 0 ), 'Problems with fetch'); 
# 4
ok((
    exists $hash->{'Weight'}
        ? 1
        : 0 ), 'Making sure an already defined exists');
# 5

ok((
    defined $hash->{'Weight'} && $hash->{'Weight'} == 0
        ? 1 
        : 0 ), 'Checking the default value of a property');
# 6
ok((
    exists $hash->{'Height'}
        ? 1
        : 0 ), 'Making sure an already defined exists');
# 7
ok((
    defined $hash->{'Height'} && $hash->{'Height'} == 0
        ? 1 
        : 0 ), 'Checking the default value of a property');


my $test2;
tie %{$test2}, 'POOF::Properties', $definitions, $self, $ExceptionHandler;

%{$test2} = %{$hash};

# 8
is_deeply(
    $hash,$test2,
    'Checking dereferencing'
);

my $test3;
tie %{$test3}, 'POOF::Properties', $definitions, $self, $ExceptionHandler;
@{$test3}{ keys %{$hash} } = values %{$hash};

# 9
is_deeply(
    $hash,$test3,
    'Checking slices'
);

# 10
eval
{
    delete $hash->{'Height'};
};

ok((
    $@
        ? 1
        : 0 ), 'Checking that deleting a property at runtime throws and exception');

$hash->{'Weight'} = 'some illegal value';

ok((
    pErrors() == 1 && exists &pGetErrors->{ 'Weight' }
        ? 1
        : 0 ), 'Checking the exception mechanism'); 

# first make sure the default is undef
ok((
   not defined $hash->{'Gender'}
    ? 1
    : 0 ), 'Check the default undef value');

# now set to a valid value
$hash->{'Gender'} = 'Male';

ok((
    $hash->{'Gender'} eq 'Male'
        ? 1
        : 0 ), 'Check setting value to Male');

# check make sure it does not generate an error
ok((
    not exists &pGetErrors->{ 'Gender' }
        ? 1
        : 0 ), "Check that we don't have errors when setting to a valid value"); 

# now set to Female
$hash->{'Gender'} = 'Female';

# check that value is female
ok((
    $hash->{'Gender'} eq 'Female'
        ? 1
        : 0 ), 'Check setting value to Female'); 

# now set to undef
$hash->{'Gender'} = undef;

# check that value = undef
ok((
   not defined $hash->{'Gender'}
    ? 1
    : 0 ), 'Check setting value to undef');

# now set to an invalid value
$hash->{'Gender'} = 'Invalid';

# check and make sure it generated the appropriate error
ok((
    exists &pGetErrors->{ 'Gender' }
        ? 1
        : 0 ), "Check that we have expected error when setting to an invalid value"); 


our $ERRORS = {};
sub pErrors
{
    my ($obj,$k,$e) = @_;
    return scalar keys %{$ERRORS} if scalar @_ <= 1;
    return delete $ERRORS->{ $k } if scalar @_ == 2;
    return $ERRORS->{ $k } = $e   if scalar @_ == 3;
    return;
}

sub pGetErrors
{
    return
        ref $ERRORS
            ? $ERRORS
            : {};
}
