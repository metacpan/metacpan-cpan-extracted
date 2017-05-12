#####################################################################

# This package used from package main to emulate user
# as well as cache output from Term::Interact.
package TestINOUT;
use Carp;

use strict;
sub TIEHANDLE {
    my $class = shift;
    bless [] => $class;
}

sub PRINT {
    my $self = shift;
    my $frog = join '' => @_;
    # let's remove any line formatting introduced by Text::Autoformat
    $frog =~ s/\n//g;
    $frog =~ s/\s+//g;
    unshift @$self, $frog;
}

sub READLINE {
    my $self = shift;
    pop @$self;
}


#####################################################################

# Before `make install' is performed this script should be
# runnable with `make test'. After `make install' it should
# work as `perl test.pl'
package main;
use strict;
use Test;
use Date::Manip;

BEGIN {
    my $plan_tests;

    eval { require DBI };
    if ($@) {
        print STDERR "Could not require DBI...   will skip sql check tests\n";
        $plan_tests = 38;
    } else {
        $plan_tests = 43;
    }
    plan tests => $plan_tests;
 };

use Term::Interact;
ok(1); # ok so far...

# set up object
my $ti = Term::Interact->new(
    date_format_display  =>  '%d-%b-%Y',
    date_format_return   =>  '%d-%b-%Y',
    FH_IN                =>  \*STDIN,
    FH_OUT               =>  \*STDOUT,
);
ok( ref $ti ? 1 : 0 );


### test parameters method
# get a href of all parm info
my $parm = $ti->parameters;
ok( ref $parm eq 'HASH' ? 1 : 0 );

# get list or parm names
my @parameters = $ti->parameters;

# number of hash keys should equal number of parameters 
ok( keys %{$parm} == @parameters ? 1 : 0 );

### test checks 
# set all values to fail except the last for testing
# also any some '' may be included to meet the needs
# of confirmation prompts
my @tries;

tie *STDIN  => "TestINOUT" or die "Couldn't tie STDIN!";
tie *STDOUT => "TestINOUT" or die "Couldn't tie STDOUT!";

# set up simulated user input, based on knowledge
# of what Term::Interact will prompt with when
# working properly.
@tries = qw/ w 23 2 /;
print STDIN "$_\n" for @tries;

my $num1 = $ti->get(
    msg         => 'Enter a single digit number.',
    prompt      => 'Go ahead, make my day: ',
    re_prompt   => 'Try Again Here: ',
    check       => [
                       qr/^\d$/,
                       '%s is not a single digit number!'
                   ]
);

# let's collect the outout of Term::Interact so
# we can confirm it conforms to what it should be
# when the module is working properly.
my @stdout;
push @stdout, $_ while (<STDOUT>);
untie *STDOUT or die "Couldn't untie STDOUT!";

# While it would be nice to abstract the following
# tests into a generic test subroutine for use in
# confirming all our calls to $ti->get(), it doesn't
# seem possible.  The output of a call to get() is
# extremely variable based on the parameters passed
# to it.  It is much easier to write specific tests
# based on known output from a properly working
# Term::Interact.  :-(  If someone more talented
# than I wants to come up with a generic test
# routine, you are welcome to!

# There should be 6 lines of output
if ( scalar @stdout == 6 ) {
    ok(  $stdout[0] eq "Enterasingledigitnumber."       ? 1 : 0  );
    ok(  $stdout[1] eq 'Goahead,makemyday:'             ? 1 : 0  );
    ok(  $stdout[2] eq "'w'isnotasingledigitnumber!"    ? 1 : 0  );
    ok(  $stdout[3] eq 'TryAgainHere:'                  ? 1 : 0  );
    ok(  $stdout[4] eq "'23'isnotasingledigitnumber!"   ? 1 : 0  );
    ok(  $stdout[5] eq 'TryAgainHere:'                  ? 1 : 0  );
} else {
    ok(0);
}

# we should have recieved back the value 2
ok(  $num1 == 2  ? 1 : 0  );


tie *STDOUT => "TestINOUT" or die "Couldn't tie STDOUT!";
undef @stdout;
push @stdout, $_ while (<STDOUT>);

@tries = ( '2002-03-12', '', 'foo', '2001-02-13', '' );
print STDIN "$_" for @tries;
my $date = $ti->get (
    type          => 'date',
    name          => 'Date from 2001',
    confirm       => 1,
    check         => [
                       ['<= 12-31-2001', '%s is not %s.'],
                       ['>= 01/01/2001', '%s is not %s.'],
                     ]
);
undef @stdout;
push @stdout, $_ while (<STDOUT>);
untie *STDOUT or die "Couldn't untie STDOUT!";
if ( scalar @stdout == 8 ) {
    ok(  $stdout[0] eq "Datefrom2001:Enteravalue."                      ? 1 : 0  );
    ok(  $stdout[1] eq '>'                                              ? 1 : 0  );
    ok(  $stdout[2] eq "Youentered:'12-Mar-2002'.Isthiscorrect?(Y|n)"   ? 1 : 0  );
    ok(  $stdout[3] eq "'12-Mar-2002'isnot<=31-Dec-2001."               ? 1 : 0  );
    ok(  $stdout[4] eq '>'                                              ? 1 : 0  );
    ok(  $stdout[5] eq "'foo'isnotavaliddate"                           ? 1 : 0  );
    ok(  $stdout[6] eq '>'                                              ? 1 : 0  );
    ok(  $stdout[7] eq "Youentered:'13-Feb-2001'.Isthiscorrect?(Y|n)"   ? 1 : 0  );
} else {
    ok(0);
}
ok(  $date eq '13-Feb-2001'  ? 1 : 0  );

eval { require DBI };
unless ($@) {
    my $dbh;
    eval { $dbh = DBI->connect('','','',{RaiseError=>1}); };
    if ($@) {
        print STDERR "Could not connect to a database using DBI.  Perhaps\n";
        print STDERR "you have not yet edited the connect parameters in\n";
        print STDERR "this test script to allow sql_check testing...\n";
        print STDERR "Failing sql_check tests 21 - 25.\n";
        ok(0);
        ok(0);
        ok(0);
        ok(0);
        ok(0);
    } else {
        tie *STDOUT => "TestINOUT" or die "Couldn't tie STDOUT!";
        @tries = ( 'FOO', 'az' );
        print STDIN "$_" for @tries;
        my $state = $ti->get (
            msg       => 'Please enter a valid state.',
            prompt    => 'State: ',
            re_prompt => 'Try Again: ',
            case      => 'uc',
            dbh       => $dbh,
            check     => [
                             "SELECT 'AZ' FROM dual",
                             '%s is not a valid state code.  Valid codes are: %s'
                         ]
        );
        undef @stdout;
        push @stdout, $_ while (<STDOUT>);
        untie *STDOUT or die "Couldn't untie STDOUT!";
        if ( scalar @stdout == 4 ) {
            ok(  $stdout[0] eq "Pleaseenteravalidstate."                        ? 1 : 0  );
            ok(  $stdout[1] eq 'State:'                                         ? 1 : 0  );
            ok(  $stdout[2] eq "'FOO'isnotavalidstatecode.Validcodesare:AZ"     ? 1 : 0  );
            ok(  $stdout[3] eq 'TryAgain:'                                      ? 1 : 0  );
        } else {
            ok(0);
            ok(0);
            ok(0);
            ok(0);
        }
        ok(  $state eq 'AZ'  ? 1 : 0  );
    }

}


tie *STDOUT => "TestINOUT" or die "Couldn't tie STDOUT!";
@tries = ( 'f', 1, -1, 14, 5 );
print STDIN "$_" for @tries;
my $num2 = $ti->get (
    name          => 'Number Less Than 10 and More than 3',
    check         => [
                       [' < 10', '%s is not less than 10.'],
                       ['> 3', '%s is not %s.']
                     ]
);
undef @stdout;
push @stdout, $_ while (<STDOUT>);
untie *STDOUT or die "Couldn't untie STDOUT!";
if ( scalar @stdout == 10 ) {
    ok(  $stdout[0] eq "NumberLessThan10andMorethan3:Enteravalue."      ? 1 : 0  );
    ok(  $stdout[1] eq '>'                                              ? 1 : 0  );
    ok(  $stdout[2] eq "'f'isnotnumeric."                               ? 1 : 0  );
    ok(  $stdout[3] eq '>'                                              ? 1 : 0  );
    ok(  $stdout[4] eq "'1'isnot>3."                                    ? 1 : 0  );
    ok(  $stdout[5] eq '>'                                              ? 1 : 0  );
    ok(  $stdout[6] eq "'-1'isnot>3."                                   ? 1 : 0  );
    ok(  $stdout[7] eq '>'                                              ? 1 : 0  );
    ok(  $stdout[8] eq "'14'isnotlessthan10."                           ? 1 : 0  );
    ok(  $stdout[9] eq '>'                                              ? 1 : 0  );
} else {
    ok(0);
}
ok(  $date eq '13-Feb-2001'  ? 1 : 0  );


tie *STDOUT => "TestINOUT" or die "Couldn't tie STDOUT!";
@tries = ( 1, 's', 'X', 'a, b', 'A, B, C' );
print STDIN "$_" for @tries;
my $grades = $ti->get (
    name       => 'Letter grade',
    delimiter  => ',',
    check      => [ 'A', 'B', 'C', 'D', 'F' ]
);
undef @stdout;
push @stdout, $_ while (<STDOUT>);
untie *STDOUT or die "Couldn't untie STDOUT!";
if ( scalar @stdout == 6 ) {
    ok(  $stdout[0] eq "Lettergrade:Enteravalueorlistofvaluesdelimitedwithcommas."      ? 1 : 0  );
    ok(  $stdout[1] eq '>'                                                              ? 1 : 0  );
    ok(  $stdout[2] eq '>'                                                              ? 1 : 0  );
    ok(  $stdout[3] eq '>'                                                              ? 1 : 0  );
    ok(  $stdout[4] eq '>'                                                              ? 1 : 0  );
    ok(  $stdout[5] eq '>'                                                              ? 1 : 0  );
} else {
    ok(0);
}
if
(
  ref $grades eq 'ARRAY'
   and
  scalar @$grades == 3
   and
  $grades->[0] eq 'A'
   and
  $grades->[1] eq 'B'
   and
  $grades->[2] eq 'C'
)
{
    ok(1);
}
else
{
    ok(0);
}

tie *STDOUT => "TestINOUT" or die "Couldn't tie STDOUT!";
@tries = ( '', 'no', 'nope', 'yes' );
print STDIN "$_" for @tries;
my $yes = $ti->get (
    succinct      => 1,
    name          => 'yes',
    default       => 'foo',
    check_default => 1,
    echo          => 1,
    check         => [
                       sub{shift() eq 'yes' ? 1 : 0},
                       "%s is not 'yes'."
                     ]
);
undef @stdout;
push @stdout, $_ while (<STDOUT>);
untie *STDOUT or die "Couldn't untie STDOUT!";
if ( scalar @stdout == 10 ) {
    ok(  $stdout[0] eq ""                   ? 1 : 0  );
    ok(  $stdout[1] eq "yes"                ? 1 : 0  );
    ok(  $stdout[2] eq '[foo]>'             ? 1 : 0  );
    ok(  $stdout[3] eq "'foo'isnot'yes'."   ? 1 : 0  );
    ok(  $stdout[4] eq '[foo]>'             ? 1 : 0  );
    ok(  $stdout[5] eq "'no'isnot'yes'."     ? 1 : 0  );
    ok(  $stdout[6] eq '[foo]>'             ? 1 : 0  );
    ok(  $stdout[7] eq "'nope'isnot'yes'."  ? 1 : 0  );
    ok(  $stdout[8] eq '[foo]>'             ? 1 : 0  );
    ok(  $stdout[9] eq "yessetto:'yes'"     ? 1 : 0  );
} else {
    ok(0);
}
ok(  $yes eq 'yes'  ? 1 : 0  );

tie *STDOUT => "TestINOUT" or die "Couldn't tie STDOUT!";
@tries = ( '' );
print STDIN "$_" for @tries;
my $date = $ti->get (
    name          => 'Order date',
    default       => 'today',
    type          => 'date',
);
undef @stdout;
push @stdout, $_ while (<STDOUT>);
untie *STDOUT or die "Couldn't untie STDOUT!";
my $expected_default_date = UnixDate('today', '%d-%b-%Y');
my $expected_first_stdout = "Orderdate:Thedefaultvalueis"
                          . $expected_default_date
                          . ".PressENTERtoacceptthedefault,orenteravalue.";
if ( scalar @stdout == 2 ) {
    ok(  $stdout[0] eq $expected_first_stdout ? 1 : 0  );
    ok(  $stdout[1] eq '>'                    ? 1 : 0  );
} else {
    ok(0);
}
ok(  $date eq $expected_default_date  ? 1 : 0  );

