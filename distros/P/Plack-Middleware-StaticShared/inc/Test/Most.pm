#line 1
package Test::Most;

use warnings;
use strict;

use Test::Most::Exception 'throw_failure';

# XXX don't use 'base' as it can override signal handlers
use Test::Builder::Module;
our ( @ISA, @EXPORT, $DATA_DUMPER_NAMES_INSTALLED );
my $HAVE_TIME_HIRES;

BEGIN {

    # There's some strange fiddling around with import(), so this allows us to
    # be nicely backwards compatible to earlier versions of Test::More.
    require Test::More;
    @Test::More::EXPORT = grep { $_ ne 'explain' } @Test::More::EXPORT;
    Test::More->import;
    eval "use Time::HiRes";
    $HAVE_TIME_HIRES = 1 unless $@;
}

use Test::Builder;
my $OK_FUNC;
BEGIN {
    $OK_FUNC = \&Test::Builder::ok;
}

#line 38

our $VERSION = '0.06';
$VERSION = eval $VERSION;

#line 437

BEGIN {
    @ISA    = qw(Test::Builder::Module);
    @EXPORT = (
        @Test::More::EXPORT, 
        qw<
            all_done
            bail_on_fail
            die_on_fail
            explain
            always_explain
            last_test_failed
            restore_fail
            set_failure_handler
            show
            always_show
        >
    );
}

sub import {
    my $bail_set = 0;

    my %modules_to_load = map { $_ => 1 } qw/
        Test::Differences
        Test::Exception
        Test::Deep
        Test::Warn
    /;
    warnings->import;
    strict->import;
    eval "use Data::Dumper::Names 0.03";
    $DATA_DUMPER_NAMES_INSTALLED = !$@;

    if ( $ENV{BAIL_ON_FAIL} ) {
        $bail_set = 1;
        bail_on_fail();
    }
    if ( !$bail_set and $ENV{DIE_ON_FAIL} ) {
        die_on_fail();
    }
    for my $i ( 0 .. $#_ ) {
        if ( 'bail' eq $_[$i] ) {
            splice @_, $i, 1;
            bail_on_fail();
            $bail_set = 1;
            last;
        }
    }
    my $caller = caller;
    for my $i ( 0 .. $#_ ) {
        if ( 'timeit' eq $_[$i] ) {
            splice @_, $i, 1;
            no strict;
            *{"${caller}::timeit"} = \&timeit;
            last;
        }
    }

    my %exclude_symbol;
    my $i = 0;

    if ( grep { $_ eq 'blessed' } @_ ) {
        @_ = grep { $_ ne 'blessed' } @_;
    }
    else {
        $exclude_symbol{blessed} = 1;
    }
    while ($i < @_) {
        if ( !$bail_set and ( 'die' eq $_[$i] ) ) {
            splice @_, $i, 1;
            die_on_fail();
            $i = 0;
            next;
        }
        if ( $_[$i] =~ /^-(.*)/ ) {
            my $module = $1;
            splice @_, $i, 1;
            unless (exists $modules_to_load{$module}) {
                require Carp;
                Carp::croak("Cannot remove non-existent Test::Module ($module)");
            }
            delete $modules_to_load{$module};
            $i = 0;
            next;
        }
        if ( $_[$i] =~ /^!(.*)/ ) {
            splice @_, $i, 1;
            $exclude_symbol{$1} = 1;
            $i = 0;
            next;
        }
        if ( 'defer_plan' eq $_[$i] ) {
            splice @_, $i, 1;

            my $builder = Test::Builder->new;
            $builder->{Have_Plan} = 1
              ; # don't like setting this directly, but Test::Builder::has_plan doe
            $builder->{TEST_MOST_deferred_plan} = 1;
            $builder->{TEST_MOST_all_done}      = 0;
            $i = 0;
            next;
        }
        $i++;
    }
    foreach my $module (keys %modules_to_load) {
        eval "use $module";

        if ( my $error = $@) {
            require Carp;
            Carp::croak($error);
        }
        no strict 'refs';
        # Note: export_to_level would be better here.
        push @EXPORT => grep { !$exclude_symbol{$_} } @{"${module}::EXPORT"};
    }

    # 'magic' goto to avoid updating the callstack
    goto &Test::Builder::Module::import;
}

sub explain {
    _explain(\&Test::More::note, @_);
}


sub timeit(&;$) {
    my ( $code, $message ) = @_;
    unless($HAVE_TIME_HIRES) {
        Test::Most::diag("timeit: Time::HiRes not installed");
        $code->();
    }
    if ( !$message ) {
        my ( $package, $filename, $line ) = caller;
        $message = "$filename line $line";
    }
    my $start = [Time::HiRes::gettimeofday()];
    $code->();
    explain(
        sprintf "$message: took %s seconds" => Time::HiRes::tv_interval($start) );
}

sub always_explain {
    _explain(\&Test::More::diag, @_);
}

sub _explain {
    my $diag = shift;
    no warnings 'once';
    $diag->(
        map {
            ref $_
              ? do {
                require Data::Dumper;
                local $Data::Dumper::Indent   = 1;
                local $Data::Dumper::Sortkeys = 1;
                local $Data::Dumper::Terse    = 1;
                Data::Dumper::Dumper($_);
              }
              : $_
          } @_
    );
}

sub show {
    _show(\&Test::More::note, @_);
}

sub always_show {
    _show(\&Test::More::diag, @_);
}

sub _show {
    unless ( $DATA_DUMPER_NAMES_INSTALLED ) {
        require Carp;
	Carp::carp("Data::Dumper::Names 0.03 not found.  Use explain() instead of show()");
        goto &_explain;
    }
    my $diag = shift;
    no warnings 'once';
    local $Data::Dumper::Indent         = 1;
    local $Data::Dumper::Sortkeys       = 1;
    local $Data::Dumper::Names::UpLevel = $Data::Dumper::Names::UpLevel + 2;
    $diag->(Data::Dumper::Names::Dumper(@_));
}

sub die_on_fail {
    set_failure_handler( sub { throw_failure } );
}

sub bail_on_fail {
    set_failure_handler(
        sub { Test::More::BAIL_OUT("Test failed.  BAIL OUT!.\n") } );
}

sub restore_fail {
    no warnings 'redefine';
    *Test::Builder::ok = $OK_FUNC;
}

sub all_done {
   my $builder = Test::Builder->new;
   if ($builder->{TEST_MOST_deferred_plan}) {
       $builder->{TEST_MOST_all_done} = 1;
       $builder->expected_tests(@_ ? $_[0] : $builder->current_test);
   }
}


sub set_failure_handler {
    my $action = shift;
    no warnings 'redefine';
    Test::Builder->new->{TEST_MOST_failure_action} = $action; # for DESTROY
    *Test::Builder::ok = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $builder = $_[0];
        if ( $builder->{TEST_MOST_test_failed} ) {
            $builder->{TEST_MOST_test_failed} = 0;
            $action->($builder);
        }
        $builder->{TEST_MOST_test_failed} = 0;
        my $result = $OK_FUNC->(@_);
        $builder->{TEST_MOST_test_failed} = !( $builder->summary )[-1];
        return $result;
    };
}

{
    no warnings 'redefine';

    # we need this because if the failure is on the final test, we won't have
    # a subsequent test triggering the behavior.
    sub Test::Builder::DESTROY {
        my $builder = $_[0];
        if ( $builder->{TEST_MOST_test_failed} ) {
            ( $builder->{TEST_MOST_failure_action} || sub {} )->();
        }
    }
}

sub _deferred_plan_handler {
   my $builder = Test::Builder->new;
   if ($builder->{TEST_MOST_deferred_plan} and !$builder->{TEST_MOST_all_done})
   {
       $builder->expected_tests($builder->current_test + 1);
   }
}

# This should work because the END block defined by Test::Builder should be
# guaranteed to be run before t one, since we use'd Test::Builder way up top.
# The other two alternatives would be either to replace Test::Builder::_ending
# similar to how we did Test::Builder::ok, or to call Test::Builder::no_ending
# and basically rewrite _ending in our own image.  Neither is very palatable,
# considering _ending's initial underscore.

END {
   _deferred_plan_handler();
}

1;

#line 806

1;
