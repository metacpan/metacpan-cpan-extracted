#!perl
# before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Symbol-Values.t'

# Revision: $Id: Symbol-Values.t,v 1.10 2005/08/10 08:56:57 kay Exp $

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 79;
use File::Temp ();

BEGIN { use_ok('Symbol::Values') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use Symbol ();

our $test = '123456789';            # scalar
our @test = (1, 2, 3, 4);           # array
our %test = (a => "b", c => "d");   # hsah
sub test { 1 };                     # code
*test = Symbol::geniosym();         # io
format test =
test
.

my $sym;

# Test 2
ok( $sym = Symbol::Values->new('test') );

# Test 3
ok( *{$sym->[0]} eq *{Symbol::Values->new(*test)->[0]} );

# Test 4
ok( *{$sym->[0]} eq *{Symbol::Values->new('main::test')->[0]} );

# Test 5
ok( *{$sym->[0]} eq *{Symbol::Values->new(*main::test)->[0]} );

#*********************************************************************
# Test scalar_ref
#*********************************************************************

# Test 6
ok($sym->scalar_ref eq \$test);     # *test{SCALAR} eq \$test;

# Test 7
my $scalar1 = '987654321';
$sym->scalar_ref = \$scalar1;       # *test = \$scalar1;
ok($sym->scalar_ref eq \$scalar1);  # \$test eq \$scalar1;

# Test 8
ok(\$test eq \$scalar1);            # \$test eq \$scalar1;

# Test 9
my $scalar2 = '000000000';
${$sym->scalar_ref} = $scalar2;     # $test = $scalar2;
ok($sym->scalar_ref eq \$scalar1);  # \$test eq \$scalar1

# Test 10
ok(\$test eq \$scalar1);            # \$test eq \$scalar1

# Test 11
ok($test eq '000000000');

# Test 12
eval { $sym->scalar_ref = 1 };
ok($@ =~ /^Can't assign /);

#*********************************************************************
# Test array_ref
#*********************************************************************

# Test 13
ok($sym->array_ref eq \@test);      # \@test eq \@test;

# Test 14
my @array1 = (4, 3, 2, 1);
$sym->array_ref = \@array1;         # *test = \@array1;
ok($sym->array_ref eq \@array1);    # \@test eq \@array1;

# Test 15
ok(\@test eq \@array1);             # \@test eq \@array1;

# Test 16
my @array2 = (5, 6, 7, 8);
@{$sym->array_ref} = @array2;       # @test = @array2;
ok($sym->array_ref eq \@array1);    # \@test eq \@array1

# Test 17
ok(\@test eq \@array1);             # \@test eq \@array1

# Test 18
ok($sym->array_ref->[0] == 5 &&
   $sym->array_ref->[1] == 6 &&
   $sym->array_ref->[2] == 7 &&
   $sym->array_ref->[3] == 8);

# Test 19
eval { $sym->array_ref = {1,2,3,4} };
ok($@ =~ /^Can't assign /);

#*********************************************************************
# Test hash_ref
#*********************************************************************

# Test 20
ok($sym->hash_ref eq \%test);       # \%test eq \%test;

# Test 21
my %hash1 = (a => 'b', c => 'd');
$sym->hash_ref = \%hash1;           # *test = \%hash1;
ok($sym->hash_ref eq \%hash1);      # \%test eq \%hash1;

# Test 22
my %hash2 = (e => 'f', g => 'h');
%{$sym->hash_ref} = %hash2;         # %test = %hash2;
ok($sym->hash_ref eq \%hash1);      # \%test eq \%hash1

# Test 23
ok($sym->hash_ref->{e} eq 'f' &&
   $sym->hash_ref->{g} eq 'h');

# Test 24
eval { $sym->hash_ref = [1,2,3,4] };
ok($@ =~ /^Can't assign /);

#*********************************************************************
# Test hash_ref
#*********************************************************************

# Test 25
ok($sym->code eq \&test);       # *test{CODE} eq \&test;

# Test 26
my $code1 = sub { 2 };
$sym->code = $code1;            # *test = $code;
ok($sym->code eq $code1);

# Test 27
ok($sym->code->() == 2);        # test() == 2;

# Test 28
eval { $sym->code = [1,2,3] };
ok($@ =~ /^Can't assign /);

#*********************************************************************
# Test io
#*********************************************************************

# Test 29
ok($sym->io eq *test{IO});          # *test{IO} eq *test{IO};

# Test 30
my $io1 = Symbol::geniosym;
$sym->io = $io1;                    # *test = $io1;
ok($sym->io eq $io1);               # *test{IO} eq $io;

my $template = 'tmpdirXXXXXX';
my $tmp_dir = File::Temp::tempdir( $template ,
								   DIR => File::Spec->curdir,
								   CLEANUP => 1,
								 );
my $tmp_file = File::Temp->new(
							   TEMPLATE => 'symvaltestXXXXXXX',
							   DIR => $tmp_dir,
							   SUFFIX => '.tmp',
							   UNLINK => 1,
							  );
open $io1, "$tmp_file";

SKIP: {
	skip "It seems your system failed to open tmp file($!).", 2, if $!;

	# Test 31
	my $fnum1 = fileno($sym->io);
	my $fnum2 = fileno($io1);
	close $io1;
	undef $tmp_file;
	undef $tmp_dir;
	ok($fnum1 == $fnum2);               # fileno(*test) eq fileno($io1);
	
	
	# Test 32
	eval { $sym->io = [1,2,3] };
	ok($@ =~ /^Can't assign /);
}

#*********************************************************************
# Test glob
#*********************************************************************

# Test 33
ok($sym->glob eq *test);            # *test eq *test;

# Test 34
*save = *test;                      # Save the glob "*main::test".
ok(*save eq *test);

# Test 35
our $tmp = 'tmp';
$sym->glob = *tmp;                  # *test = *tmp;
ok(*test eq *tmp);                  # *test eq *tmp

# Test 36
ok($sym->glob eq *tmp);             # *test eq *tmp;

# Test 37
ok(*save ne *test);                 # Now, *save returns *main::save
                                    # See note in below.

# Test 38
ok($test eq 'tmp');                 # $test eq 'tmp';

# Test 39
$sym->glob = *save;                 # *test = *save;

ok($sym->glob ne *save);            # *test ne *save;
                                    #
                                    # NOTE:
                                    #   *test returns *main::test,
                                    #   *save returns *main::save,
                                    #   because of egv field in glob is
                                    #   no longer holds valid value.
                        		#   (Value of egv was lost at Test 31)
									#   But they still shares same glob
									#   object.

# Test 40
ok(*test ne *save);					# *test ne *save

# Test 41
ok(${$sym->glob} eq '000000000');	# $test eq '000000000';

# Test 42
ok($test eq '000000000');			# $test eq '000000000';

# Test 43
eval { $sym->glob = [1,2,3] };
ok($@ =~ /^Can't assign /);

#*********************************************************************
# Format
#*********************************************************************

# Test 44
ok($sym->format eq *test{FORMAT});

# Test 45
format form_1 =
1
.
$sym->format = *form_1{FORMAT};
ok($sym->format eq *form_1{FORMAT});

# Test 46
eval {$sym->format = \1};
ok($@ =~ /^Can't assign /);

#*********************************************************************
# Assign glob values
#*********************************************************************
our $assign = "assign";
our @assign = (7, 8, 9);
our %assign = (f => 'g', h => 'i');
sub assign { 12 };
*assign = Symbol::geniosym;
format assign =
assign
.

# Test 47
$sym->scalar_ref = *assign;			# *test = \$assign;
ok(\$test eq \$assign);

# Test 48
$sym->array_ref = *assign;			# *test = \@assign;
ok(\@test eq \@assign);

# Test 49
$sym->hash_ref = *assign;			# *test = \%assign;
ok(\%test eq \%assign);

# Test 50
$sym->code = *assign;			# *test = \&assign;
ok(\&test eq \&assign);

# Test 51
$sym->io = *assign;					# *test = *assign{IO};
ok(*test{IO} eq *assign{IO});

# Test 52
$sym->format = *assign;
ok(*test{FORMAT} eq *assign{FORMAT});

#*********************************************************************
# Undefefine values
#*********************************************************************

# Test 53
$sym->scalar_ref = undef;			# undef $test;
ok(!defined($test));

# Test 54
$sym->array_ref = undef;			# undef @test;
ok(!defined(@test));

# Test 55
$sym->hash_ref = undef;				# undef %test;
ok(!defined(%test));

# Test 56
$sym->code = undef;				# undef &test;
ok(!defined(&test));

# Test 57
eval { $sym->io = undef };			# I dunno how can I do this...
ok($@ =~ /^Can't assign value "undef"/);

# Test 58
eval { $sym->format = undef };		# I dunno how can I do this...
ok($@ =~ /^Can't assign value "undef"/);

# Test 59
$test = '123456789';				# scalar
@test = (1, 2, 3, 4);				# array
%test = (a => "b", c => "d");		# hsah
no warnings;
eval 'sub test { "OK" }';			# code
use warnings;
*test = Symbol::geniosym();			# io

ok(${$sym->scalar_ref} eq '123456789');

# Test 60
ok($sym->array_ref->[0] == 1 &&
   $sym->array_ref->[1] == 2 &&
   $sym->array_ref->[2] == 3 &&
   $sym->array_ref->[3] == 4);

# Test 61
ok($sym->hash_ref->{a} eq "b" &&
   $sym->hash_ref->{c} eq "d");

# Test 62
ok((eval { $sym->code->() }) eq "OK");

# Test 63
ok($sym->io eq *test{IO});

$sym->glob = undef;					# undef *test;

# Test 64
ok(!defined(${$sym->scalar_ref}));

# Test 65
ok(!defined($sym->array_ref));

# Test 66
ok(!defined($sym->hash_ref));

# Test 67
ok(!defined($sym->io));

# Test 68
ok(!defined($sym->code));


#*********************************************************************
# Scalar, Array, Hash
#*********************************************************************

# Test 69
$sym->scalar = "scalar value";
ok($sym->scalar eq "scalar value");

# Test 70
{no warnings; ($sym->array) = (9, 8, 7)}
ok(($sym->array)[0] == 9 &&
   ($sym->array)[1] == 8 &&
   ($sym->array)[2] == 7);

# Test 71
eval {no warnings; $sym->array = (9, 8, 7)};
ok($@ =~ /^Can't modify list value in scalar context/);

# Test 72
{no warnings; ($sym->hash) = (v => 'w', x => 'y')}
my %h = $sym->hash;
ok($h{v} eq 'w' &&
   $h{x} eq 'y');

# Test 73
eval {no warnings; $sym->hash = (9, 8, 7, 6)};
ok($@ =~ /^Can't modify list value in scalar context/);

#*********************************************************************
# Function 'symbol'
#*********************************************************************

use Symbol::Values 'symbol';

sub test2 {
	1
}

# Test 74
ok(symbol("test2")->code eq \&test2);

#*********************************************************************
# Error Handling
#*********************************************************************

# Test 75
eval { symbol('&&') };
ok($@ =~ /^Invalid name name "&&": possible typo/);

#*********************************************************************
# Special Variable
#*********************************************************************

# Test 76
our $^W = 1;
ok( symbol('^W')->scalar == 1 );

# Test 77
symbol('^W')->scalar = 0;
ok( symbol('^W')->scalar == 0 );

# Test 78
$^W = 1;
ok( symbol(*^W)->scalar == 1 );

# Test 79
symbol(*^W)->scalar = 0;
ok( symbol(*^W)->scalar == 0 );


