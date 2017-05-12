package Test::Debugger;

require 5.005_03;
use strict;

require Exporter;
use vars qw(@ISA @EXPORT_OK @EXPORT $VERSION
$TESTOUT $ntest $object_handle %param_order %todo $ONFAIL $separate_todo);
# in case you don't have Devel::Messenger installed, I 'require' instead of 'use' it.
BEGIN {
    eval { require Devel::Messenger; };
    if ($@) {
	sub note;
	sub note {};
    } else {
	undef &note;
	import Devel::Messenger qw(note);
    }
    eval { require Test::Harness };
    if (!$@ and Test::Harness->VERSION >= 1.21) {
        $separate_todo = 1;
    }
}

@ISA = qw(Exporter);
@EXPORT_OK = qw($TESTOUT &param_order);
@EXPORT = qw(&plan &ok &skip &todo);
$VERSION = 0.14;
$TESTOUT = *STDOUT{IO};
%todo = ();
$separate_todo ||= 0;

#use constant PARAM_ORDER => ['self', 'expected', 'actual', 'message', 'error', 'operator'];
use constant PARAM_ORDER => ['actual', 'expected', 'message', 'error', 'operator'];
# 'actual', 'expected', 'message' # Test.pm
# self, expected, actual, message, error, operator # Test::Debugger (pre-CPAN)

%param_order = (
    # ok, skip, todo
    'skip' => ['skip'],
);

# current supported relational operators
use constant OPERATOR => {
    'eq' => {
        'desc' => '',
	'code' => sub { shift() eq shift() },
    },
    'ne' => {
        'desc' => 'Not Equal to (alpha) ',
	'code' => sub { shift() ne shift(); },
    },
    'gt' => {
        'desc' => 'Greater Than (alpha) ',
	'code' => sub { my $expected = shift; shift() gt $expected; },
    },
    'ge' => {
        'desc' => 'Greater Than or Equal to (alpha) ',
	'code' => sub { my $expected = shift; shift() ge $expected; },
    },
    'lt' => {
        'desc' => 'Less Than (alpha) ',
	'code' => sub { my $expected = shift; shift() lt $expected; },
    },
    'le' => {
        'desc' => 'Less Than or Equal to (alpha) ',
	'code' => sub { my $expected = shift; shift() le $expected; },
    },
    're' => {
        'desc' => 'to Match Pattern ',
        'code' => sub { my $expected = shift; shift =~ /$expected/; },
    },
    '=~' => {
        'desc' => 'to Match Pattern ',
        'code' => sub { my $expected = shift; shift =~ /$expected/; },
    },
    '==' => {
        'desc' => '',
	'code' => sub { my $expected = shift; shift() == $expected; },
    },
    '!=' => {
        'desc' => 'Not Equal to ',
	'code' => sub { my $expected = shift; shift() != $expected; },
    },
    '>'  => {
        'desc' => 'Greater Than ',
	'code' => sub { my $expected = shift; shift()  > $expected; },
    },
    '>=' => {
        'desc' => 'Greater Than or Equal to ',
	'code' => sub { my $expected = shift; shift() >= $expected; },
    },
    '<'  => {
        'desc' => 'Less Than ',
	'code' => sub { my $expected = shift; shift()  < $expected; },
    },
    '<=' => {
        'desc' => 'Less Than or Equal to ',
	'code' => sub { my $expected = shift; shift() <= $expected; },
    },
};

#sub Test::Debugger::tied::TIESCALAR {
#    my $var = $_[1];
#    bless \$var, 'Test::Debugger::tied';
#}
#sub Test::Debugger::tied::FETCH { return ${$_[0]} }
#sub Test::Debugger::tied::STORE { ${$_[0]} = $_[1] }

sub new {
    # returns a test object handle
    my $class = shift;
    my $is_new = (!defined($object_handle));
    $object_handle ||= bless {}, $class;
    my $self = $object_handle;
    #tie($self->{current}, 'Test::Debugger::tied', $ntest) if ($is_new);
    $self->plan(@_) if (@_);
    if ($is_new) {
	my @caller = caller();
	$self->{test_file} = ($caller[0] eq 'Test::Debugger') ? (caller(1))[1] : $caller[1];
	$self->{last}      = 0; # will be 0 in Test.pm
	$self->{current} ||= 0; # Test.pm
	#$self->{current}   = 1 unless (defined($self->{current}));
	$self->{final}   ||= 0;
	note "[$self->{test_file} #", $self->next_test_number, "]\n";
    }
    return $self;
}

sub plan {
    my $self = (ref($_[0])) ? shift : (Test::Debugger->new(@_) and return);
    #note \7, "planning\n";
    my %opts = @_;
    if (exists($opts{todo}) and ref($opts{todo}) eq 'ARRAY') {
	%todo = map { $_ => 1 } @{$opts{todo}};
    }
    if (exists($opts{onfail}) and ref($opts{onfail}) eq 'CODE') {
	$ONFAIL = $opts{onfail};
    }
    if (exists($opts{log_file})) {
	$self->{log_file} = $opts{log_file};
    }
    if (exists($opts{next_test_number})) {
	$self->next_test_number($opts{next_test_number});
    } elsif (exists($opts{start})) {
        $self->next_test_number($opts{start});
    }
    if (exists($opts{tests}) or exists($opts{skip})) {
	my $tests = $opts{tests} || 0;
	my $skip  = $opts{skip}  || 0;
	my $message = $opts{skip_message} || '';
	$self->_write_header($tests, $skip, $message);
	$self->{final} = $tests;
	#note \7, "final test shall be number $tests\n";
    }
    if (exists($opts{param_order})) {
	my $p_order = $opts{param_order} || {};
	foreach my $key (keys %$p_order) {
	    my $order = $p_order->{$key} || next;
	    $self->param_order($key => $order);
	}
    }
}

sub next_test_number {
    # set or return the next test number
    my $self = (ref($_[0])) ? shift : Test::Debugger->new();
    my $current = shift;
    if (defined($current)) {
	#note \7, "setting next_test_number to $current\n";
	$self->{current} = $current - 1
    }
    return $self->{current} + 1;
}

sub param_order {
    my $self = (ref($_[0])) ? shift : Test::Debugger->new();
    my $method = shift || 'ok';
    if (@_) {
	$self->{param_order}{$method} = shift;
    } elsif (exists($self->{param_order}{$method})) {
	return @{$self->{param_order}{$method}};
    } elsif (exists($param_order{$method})) {
	if (exists($self->{param_order}{ok})) {
	    return _unshift_self(@{$param_order{$method}}, @{$self->{param_order}{ok}});
	} else {
	    return _unshift_self(@{$param_order{$method}}, @{PARAM_ORDER()});
	}
    } elsif (exists($self->{param_order}{ok})) {
	return @{$self->{param_order}{ok}};
    } else {
	return @{PARAM_ORDER()};
    }
}

sub _unshift_self {
    my @array = @_;
    my $c = 0;
    while ($c < @array) {
	if ($array[$c] eq 'self') {
	    unshift(@array, splice(@array, $c, 1));
	    last;
	}
	$c++;
    }
    return @array;
}

sub ok {
    my $num_opts = scalar(@_);
    my $first    = $_[0];
    my $second   = $_[1];
    my $opts = &_read_opts('ok', @_);
    if ($num_opts == 1 or (ref($first) eq 'Test::Debugger' and $num_opts == 2)) {
	$opts->{single} = 1;
	$opts->{actual} = ($num_opts == 1) ? $first : $second;
    }
    $opts->{self}->_ok_($opts, '==', 'eq');
}

sub todo {
    my $opts = &_read_opts('todo', @_);
    #$opts->{skip} = 1;
    $opts->{todo} = 1;
    $opts->{self}->_ok_($opts, '==', 'eq');
}

sub skip {
    my $opts = &_read_opts('skip', @_);
    $opts->{self}->_ok_($opts, '==', 'eq');
}

# XXX deprecated - please use 'todo' method instead
sub ok_skip {
    my $num_opts = scalar(@_);
    my $first    = $_[0];
    my $second   = $_[1];
    my $opts = &_read_opts('ok_skip', @_);
    if ($num_opts == 1 or (ref($first) eq 'Test::Debugger' and $num_opts == 2)) {
	$opts->{single} = 1;
	$opts->{actual} = ($num_opts == 1) ? $first : $second;
    }
    $opts->{skip} = 1;
    $opts->{self}->_ok_($opts, '==', 'eq');
}

sub ok_ne {
    my $opts = &_read_opts('ok_ne', @_);
    $opts->{self}->_ok_($opts, '!=', 'ne');
}

sub ok_gt {
    my $opts = &_read_opts('ok_gt', @_);
    $opts->{self}->_ok_($opts, '>', 'gt');
}

sub ok_ge {
    my $opts = &_read_opts('ok_ge', @_);
    $opts->{self}->_ok_($opts, '>=', 'ge');
}

sub ok_lt {
    my $opts = &_read_opts('ok_lt', @_);
    $opts->{self}->_ok_($opts, '<', 'lt');
}

sub ok_le {
    my $opts = &_read_opts('ok_le', @_);
    $opts->{self}->_ok_($opts, '<=', 'le');
}

sub ok_re {
    my $opts = &_read_opts('ok_re', @_);
    $opts->{self}->_ok_($opts, '=~', 're');
}

sub _ok_ {
    my $self = shift;
    my $opts = shift;
    my $numeric = shift;
    my $alpha   = shift;
    unless ($opts->{single} or $opts->{operator}) {
	my $expect = (defined($opts->{expected}) ? $opts->{expected} : undef);
	my $actual = (defined($opts->{actual}) ? $opts->{actual} : undef);
	my $op;
	if (defined($expect) and defined($actual)) {
	    $op = ($expect =~ /\D/ or $actual =~ /\D/ or $expect eq '' or $actual eq '') ? $alpha : $numeric;
	} else {
	    $op = $alpha;
	}
	$opts->{operator} = $op;
    }
    $self->_test(@{$opts}{'expected', 'actual', 'single', 'operator', 'skip', 'todo', 'message', 'error'});
}

sub _read_opts {
    my $method = shift;
    my $self = Test::Debugger->new();
    my %opts = ();
    $opts{single} = 1;
    foreach my $key ($self->param_order($method)) {
	$opts{$key} = shift;
	#note \7, "method $method reading param $key: " . (defined($opts{$key}) ? $opts{$key} : 'undef') . "\n";
	if ($key eq 'expected') {
	    $opts{single} = 0;
	}
    }
    $opts{self} ||= $self;
    $opts{operator} ||= '';
    return \%opts;
}

sub _test {
    my $self = shift;
    my $expect   = shift;
    my $actual   = shift;
    my $single   = shift || 0;
    my $operator = shift || 'eq';
    my $skip     = shift || 0;
    my $todo     = shift || 0;
    my $message  = shift || '';
    my $error    = shift || '';
    my $true = 0;
    #note "self $self\n";
    #note "expect $expect\n";
    #note "actual $actual\n";
    #note \7, "single $single\n";
    #note "operator $operator\n";
    #note "skip $skip\n";
    #note "message $message\n";
    #note "error $error\n";
    $self->{current}++;
    if ($single) {
	#note "determining truth\n";
	$true = $self->_truth(defined($actual) ? $actual : undef());
	$expect = 'true';
    } else {
	#note "comparing values\n";
	$true = $self->_compare_values(
            $operator,
	    defined($expect) ? $expect : undef(),
	    defined($actual) ? $actual : undef(),
	);
    }
    #note \7, "true $true\n";
    if (exists($todo{$self->{current}})) {
	$todo = 1;
    }
    if (!$separate_todo and $todo) {
	$skip = 1;
    }
    $self->_write_result($true, $skip, $todo, $message);
    if ($self->{log_file} and !$true) {
	$self->_write_log(
            $operator,
            defined($expect) ? $expect : undef(),
	    defined($actual) ? $actual : undef(),
	    $skip,
	    $todo,
            $message,
            $error,
	);
    }
    $self->{last} = $self->{current};
    if ($self->{final} and $self->{current} >= $self->{final}) {
	note "[$self->{test_file} #complete#]\n";
    } else {
	note "[$self->{test_file} #", $self->next_test_number, "]\n";
    }
    return ($skip ? 1 : $true);
}

sub _truth {
    my $self = shift;
    my $actual = shift || 0;
    return $actual ? 1 : 0;
}

sub _compare_values {
    my $self = shift;
    my $operator = shift;
    my $expect   = shift;
    my $actual   = shift;
    my $true     = 0;
    if (defined($expect) and defined($actual)) {
        if (ref($expect) eq 'Regexp') {
            $operator = 're';
        }
        if (exists(OPERATOR->{$operator})) {
            $true = (OPERATOR->{$operator}{code}->($expect, $actual) ? 1 : 0);
        } else {
            $true = 0;
            warn "Test::Debugger encountered an unknown operator ($operator)\n";
        }
    } elsif (defined($expect) eq defined($actual)) {
	$true = 1;
    }
    return $true;
}

sub _write_header {
    my $self = shift;
    my $tests = shift || 0;
    my $skip  = shift || 0;
    my $message = shift || '';
    my $todo = %todo;
    my $TODO = $todo ? ' todo ' . join(' ', keys %todo) : '';
    substr($message, 0, 0, ': ') if ($message);
    print $TESTOUT "1.." . ($skip ? '0 # Skipped' . $message : $tests) . "$TODO\n";
    exit if ($skip);
}

sub _write_result {
    my $self = shift;
    my $true = shift;
    my $skip = shift || 0;
    my $todo = shift || 0;
    my $message = shift || '';
    if ($skip) {
        print $TESTOUT "ok $self->{current} # Skip $message\n";
    } else {
	my $TODO = $todo ? ' # TODO' : '';
        print $TESTOUT ($true ? "ok $self->{current}$TODO\n" : "not ok $self->{current}$TODO $message\n");
    }
}

sub _write_log {
    my $self = shift;
    my $operator = shift;
    my $expect   = shift;
    my $actual   = shift;
    my $skip     = shift || 0;
    my $todo     = shift || 0;
    my $message  = shift || '';
    my $error    = shift || '';
    my $status;
    if ($todo) {
	$status = 'TODO';
    } elsif ($skip) {
	$status = 'SKIPPED';
    } else {
	$status = 'FAILED';
    }
    $expect  = 'undef' unless defined($expect);
    $actual  = 'undef' unless defined($actual);
    if (open(FILE,">>".$self->{log_file})) {
	print FILE "$self->{test_file} $self->{current} $status.\n";
	print FILE $message, "\n" if $message;
	print FILE $error, "\n"   if $error;
	print FILE "### Expected ".OPERATOR->{$operator}{desc}."###\n$expect\n### Actual Results ###\n$actual\n\n";
	close FILE;
    }
}

1;
__END__

=head1 NAME

Test::Debugger - Create Test Scripts which Generate Log Files

=head1 SYNOPSIS

  use Test::Debugger;
  plan(tests => 1, log_file => 'test.log');
  ok($actual, $expected, $message, $error);

  # OR Object-Oriented

  use Test::Debugger;
  my $t = Test::Debugger->new(
      tests    => 1,
      log_file => 'test.log',
  );

  # set the order of the parameters passed to 'ok'
  $t->param_order('ok' => [qw(self expected actual message error)]);

  $t->ok($expected, $actual, $description, $error_message);
  $t->todo($expected, $actual, $description, $error_message);
  $t->skip($because, $expected, $actual, $description, $error);

  $t->ok_ne($expected, $actual, $description, $error_message);
  $t->ok_gt($expected, $actual, $description, $error_message);
  $t->ok_ge($expected, $actual, $description, $error_message);
  $t->ok_lt($expected, $actual, $description, $error_message);
  $t->ok_le($expected, $actual, $description, $error_message);
  $t->ok_re($expected, $actual, $description, $error_message);

=head1 DESCRIPTION

Have you ever tried to debug a test script that is failing tests?
Without too many modifications, your test script can generate a
log file with information about each failed test.

You can take your existing test script, and with (hopefully) very
little effort, convert it to use Test::Debugger.  Then re-run your
modified test and view the log file it creates.

=head2 Object-Oriented Interface

Test::Debugger can be run using exported subroutines, or using
an object-oriented interface.

The object-oriented interface allows for easier access to some
types of functionality, such as comparision operators other than
'eq'.

You start by creating a test object.

  my $t = Test::Debugger->new(%params);

The C<new> method calls C<plan> automatically, so you can pass
your C<plan> parameters directly to C<new>.

The three most basic methods are C<ok>, C<todo> and C<skip>.
You can rearrange the order of the parameters to these methods
by running C<param_order>.  You must run C<param_order> for
the testing subroutines to work as methods.

  $t->param_order('ok' => ['self', 'actual', 'expected']);

The key here is the word I<self>.  The default param order does
not include I<self> as a valid parameter.  The example above sets
the valid parameters to pass to C<ok>, including the test object,
the value we are testing, and the value we expect it to match
against.

A parameter order need only be assigned for C<ok>.  The C<todo>
and C<skip> methods will mimic the order assigned for C<ok>, if
they are undefined.

Now we can set up our tests:

  $t->ok($actual, $expected);

An explanation of each method can be found further down in this
document.

=head2 Subroutine Interface

The interface for Test::Debugger is based loosely on the interface
for Test.pm.  You have four subroutines exported into your namespace:
C<plan>, C<ok>, C<skip>, and C<todo>.

You should C<plan>, but it is not as strictly enforced as in Test.pm.

The default order of arguments to C<ok> and C<todo> is:

  ok($actual, $expected, $message, $error, $operator);

You must supply at least an C<$actual> value, and you should supply
the first three parameters.  You can change the order of the parameters
with C<param_order>.

=head2 Log File

I generally name my test log file 'test.log', and add an entry to
my Makefile.PL to remove it on 'make clean'.

  WriteMakefile(
      ...
      'clean' => {
          'FILES' => 'test.log',
      },
  );

If a test fails, is skipped, or is marked todo (and fails), an entry
is made to the log file.  Each entry looks similar to this:

  t/todo.t 1 TODO.
  should fail as TODO
  ### Expected ###
  1
  ### Actual Results ###
  0

The first part is the name of the test file.  The number is the subtest
within the test file.  The word C<TODO> means that this test was not
expected to succeed, because code it relies on is not finished.  This
word could also have been C<FAILED> or C<SKIPPED>.

On the second line, we see the C<$message> provided to the test.  We
would see the C<$error> on the third line, if that had been provided.

Then the expected value and the actual value are displayed.  An extra
newline is appended to the actual value, in the log file, so that there
is a blank line between entries.

=head2 Extra Debugging

If the test log file is not sufficient to debug your code, or your test,
you may enable the C<note> subroutine of Devel::Messenger and write
to another file, perhaps called something like 'debug.txt'.

  use Devel::Messenger qw(note);
  local *Test::Debugger::note = note { output => 'debug.txt' };

Test::Debugger will C<note> the test it is working on.  You can then
place notes in your module, and they will be grouped by test number.

=head2 Methods/Subroutines

Most methods may be called as a subroutine, rather than as a method.

=over 4

=item new

Creates a new Test::Debugger instance and returns a handle to that instance.
Accepts a HASH of parameters, which is passed to the C<plan> method.

Not available as a subroutine.

=item next_test_number

Takes a number to store internally as the next test number.

  $t->next_test_number(1);

  $next_test = $t->next_test_number();

Returns the number of the next test to be run.

=item param_order

Allows you to specify in which order you shall submit parameters.

  $t->param_order($method => \@order);

The key words allowed in the C<@order> array are:

  self      Test::Debugger object
  expected  the value you expect to get
  actual    the value you are testing
  message   description of the test
  error     an error message to log
  operator  Perl comparison operator

You may include as many or few of these items as parameters, as long
as C<actual> is always present.

=item plan

Sets up some internal variables, such as where to log errors.

  $t->plan(
      'skip'             => $because,
      'skip_message'     => $explanation,
      'tests'            => $total_number_of_tests,
      'todo'             => [@tests_to_skip],
      'log_file'         => $filename,
      'start'            => $number,
      'param_order'      => {
	  'ok' => ['actual', 'expected', 'message', 'error'],
      },
  );

If you do not include a C<tests> parameter, you must print the line:

  "1..$number\n"

Otherwise Test::Harness will not know how many tests there are.

If the C<$because> of the C<skip> parameter is true, the entire
test file will be skipped.

=item ok

Takes parameters which may include a Test::Debugger object handle, an
actual value, expected value, description of the test, error message,
and the Perl comparision operator to use.

I<See C<param_order> for information on specifying the order of parameters>.

Compares the actual and expected values (or determines the truth if only
the actual value is specified in C<param_order>).
Prints "ok $number\n" on success, or "not ok $number $message\n" on
failure.

  $t->param_order('ok' => ['self', 'expected', 'actual', 'message']);
  $t->ok('Test::Debugger',ref($t),'testing value of ref');

An expected value of C<qr/regex/> will try to match C<$actual =~ qr/regex/>.

  $t->ok(qr/help/, 'help me', 'testing regex');

Returns true if the test does not fail.

=item ok_<operator>

Takes the same arguments as C<ok>. Prints the same output as C<ok>. Allows
for the use of operators other than 'eq' to compare expected and actual
values. Available operators are:

  ne  not equal
  gt  greater than
  ge  greater than or equal to
  lt  less than
  le  less than or equal to
  re  regualar expression

Each operator is converted to the numeric equivalent if both arguments
contain nothing other than numbers.

Not available as subroutines.

=item skip

Skips a single test if a condition is met.

  $t->skip($because, $expected, $actual, $description);

Prints "ok $number skip: $description\n", if C<$because> is true.
Returns true if the test succeeds, or if it is skipped.

=item todo

Skips a single test, or marks it TODO, because you are still working
on the underlying code.

  $t->todo($expected, $actual, $description);

Output depends on the version of Test::Harness you are using.
Always returns true.

=back

=head1 AUTHOR

Nathan Gray - kolibrie@southernvirginia.edu

=head1 COPYRIGHT

Test::Debugger is Copyright (c) 2003 Nathan Gray.  All
rights reserved.

You may distribute under the terms of either the GNU
General Public License, or the Perl Artistic License.

=head1 SEE ALSO

perl(1), Test::Harness(3), Devel::Messenger(3).

=cut
