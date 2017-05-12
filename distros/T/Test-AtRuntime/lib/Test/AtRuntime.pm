package Test::AtRuntime;

=head1 NAME

Test::AtRuntime - Put tests in your code and run them as your program runs


=head1 SYNOPSIS

  use Test::AtRuntime 'logfile';
  use Test::More;

  sub foo {
      # This test runs.
      TEST { pass('foo ran'); }
  }

  no Test::AtRuntime;

  sub bar {
      # This test is not run.
      TEST { pass('bar ran') }
  }

  foo();
  bar();

=head1 DESCRIPTION

Test::AtRuntime lets you use Test::More and other Test::Builder based modules
directly in your source code providing a way to test your program as it
runs.  Similar to the concept of an assertion, except instead of dying
when it fails, normal "not ok" output will be seen.

=head2 Compiling out

Like assertions, they can be turned on or off as needed.  Tests are put
inside of a TEST block like so:

    TEST { like( $totally, qr/rad/ ) }

C<use Test::AtRuntime> runs these tests.  C<no Test::AtRuntime> means these
tests will not be run.  In fact, they will be completely removed from the
program so that performance will not be effected (except some startup
performance for the filtering).

=head2 Logfile

C<use Test::AtRuntime> takes an argument, a logfile to append your tests to.
If no logfile is given, tests will be outputed like normal.


=head1 CAVEATS

Due to what appears to be a bug in Filter::Simple, this won't work as
expected:

    use Test::AtRuntime;

    ...run tests...


    no Test::AtRuntime;

    ...don't run tests...

    use Test::AtRuntime;

    ...run tests...  <--- BUG

Once you stop running tests, they can't be made to run again.


=head1 TODO

=over 4

=item * suppress ok

It'll probably be useful to suppress the 'ok' messages so only
failures are seen.  Then again, "tail -f logfile | grep '^ok '" does a
good job of that.  Also, Test::Builder doesn't support that yet.

=item * honor environment variables

Test::AtRuntime should honor the same NDEBUG and PERL_NDEBUG
environment variables as Carp::Assert and possibly an additional one
just for Test::AtRuntime.

=item * stack trace on failure

Failing test should be accompanied by a stack trace to help figure out
what's going wrong.

=back


=head1 SEE ALSO

Test::More, Carp::Assert, Carp::Assert::More, Test::Inline, Test::Class

=cut


$VERSION = 0.02;

use Filter::Simple;
use File::Spec;
use Regexp::Common;
use Test::Builder;


my $TB = Test::Builder->new;
$TB->plan('no_plan');
$TB->use_numbers(0);
$TB->no_header(0);

sub import {
    my($class, $logfile) = @_;
    $Testing = $Not_Testing ? 0 : 1;
#    print STDERR "import: NT $Not_Testing  T $Testing\n";
    set_log($logfile);
    $Not_Testing = 0;
}

sub not_testing {
    my($class, $logfile) = @_;
    $Not_Testing = 1;
#    print STDERR "not_testing\n";
    goto &import;
}

sub set_log {
    my($logfile) = @_;

    if( defined $logfile ) {
        open(LOGFILE, ">>$logfile") || die $!;
        my $oldfh = select LOGFILE;
        $| = 1;
        select $oldfh;

        $TB->output(\*LOGFILE);
        $TB->failure_output(\*LOGFILE);
        $TB->todo_output(File::Spec->devnull);
    }
}


FILTER_ONLY(
    executable  => sub { 
        $Testing ? s[ \bTEST \s+ ($RE{balanced}{-parens=>'{}'}) ][$1]xg
                 : s[ \bTEST \s+  $RE{balanced}{-parens=>'{}'}  ][]xg
    },
#    all => sub { print },
#    qr/^\s*(?:use|no)\s+Test::AtRuntime\b/
);

no warnings 'redefine';
(*unimport, *import) = (\&not_testing, \&import);

1;


