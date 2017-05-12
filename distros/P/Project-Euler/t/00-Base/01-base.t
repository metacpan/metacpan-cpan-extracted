use strict;
use warnings;


package base_test_input;
use Moose;
use Carp;
with 'Project::Euler::Problem::Base';
sub _build_problem_number { return 1                 }
sub _build_problem_name   { return q{test input}  }
sub _build_problem_date   { return q{2012-12-21}     }
sub _build_problem_desc   { return q{Blah blah blah} }
sub _build_default_input  { return q{42}             }
sub _build_default_answer { return '21'              }
sub _build_help_message   { return q{Help me}        }
sub _check_input          {
    my ($blah, $self, $new) = @_;
    if ($new =~ /\D/) {
        croak q{Input must be all digits};
    }
}
#has '+has_input' => (default => 0);

sub _solve_problem {
    my ($self, $arg) = @_;
    $self->_set_more_info( $self->problem_name );

    if ($self->use_defaults) {
        return $self->default_input / 2;
    }
    else {
        return $arg / 2;
    }
}
no Moose;
__PACKAGE__->meta->make_immutable;



package base_test_noinput;
use Moose;
with 'Project::Euler::Problem::Base';
sub _build_problem_number { return 1                 }
sub _build_problem_name   { return q{test noinput}  }
sub _build_problem_date   { return q{2012-12-21}     }
sub _build_problem_desc   { return q{Blah blah blah} }
sub _build_default_input  { return q{}               }
sub _build_default_answer { return '42'              }
sub _build_help_message   { return q{Help me}        }
sub _check_input          { return 1                 }
has '+has_input' => (default => 0);

sub _solve_problem {
    my ($self, $arg) = @_;
    $self->_set_more_info( $self->problem_name );
    return $self->default_answer;
}
no Moose;
__PACKAGE__->meta->make_immutable;



package base_test_bad;
use Moose;
with 'Project::Euler::Problem::Base';
sub _build_problem_number { return 'a'               }
sub _build_problem_name   { return q{123456789}      }
sub _build_problem_date   { return q{2001-23-43}     }
sub _build_problem_desc   { return undef             }
sub _build_default_input  { return undef             }
sub _build_default_answer { return undef             }
sub _build_help_message   { return undef             }
sub _check_input          { return 0                 }

sub _solve_problem {
    return 1;
}
no Moose;
__PACKAGE__->meta->make_immutable;




package test;

use strict;
use warnings;
use Test::Most;
use Test::Exception;

use Readonly;

Readonly::Scalar my $BASE_URL => q{http://projecteuler.net/index.php?section=problems&id=};
Readonly::Scalar my $CUSTOM_INPUT  => 54;
Readonly::Scalar my $CUSTOM_ANSWER => $CUSTOM_INPUT / 2;


plan tests => 7 + (7 * 2) + (3 * 7) + 2 + 5;

die_on_fail;

# TESTS -> 7
my $t_in  = new_ok( 'base_test_input'   );
my $t_nin = new_ok( 'base_test_noinput' );
my $t_inc = new_ok( 'base_test_input'   );
my $t_bad = new_ok( 'base_test_bad'     );

dies_ok{ $t_inc->custom_input( '1a' ) } 'Only accept digits as custom input';
ok( $t_inc->custom_input(  $CUSTOM_INPUT  ), 'Assign custom input'  );
ok( $t_inc->custom_answer( $CUSTOM_ANSWER ), 'Assign custom answer' );

 $t_in->use_defaults( 1 );
$t_inc->use_defaults( 0 );
$t_nin->use_defaults( 1 );


# TESTS -> 7
is( $t_in->problem_name     , q{test input}    , 'problem_name is set correctly'   );
is( $t_in->problem_date->ymd, q{2012-12-21}    , 'problem_date is set correctly'   );
is( $t_in->problem_desc     , q{Blah blah blah}, 'problem_desc is set correctly'   );
is( $t_in->problem_link     , $BASE_URL . '1'  , 'problem_link is set correctly'   );
is( $t_in->default_input    , q{42}            , 'default_input is set correctly'  );
is( $t_in->default_answer   , q{21}            , 'default_answer is set correctly' );
is( $t_in->help_message     , q{Help me}       , 'help_message is set correctly'   );

# TESTS -> 7
dies_ok { $t_bad->problem_name   }  'problem_name is set correctly';
dies_ok { $t_bad->problem_date   }  'problem_date is set correctly';
dies_ok { $t_bad->problem_desc   }  'problem_desc is set correctly';
dies_ok { $t_bad->problem_link   }  'problem_link is set correctly';
dies_ok { $t_bad->default_input  }  'default_input is set correctly';
dies_ok { $t_bad->default_answer }  'default_answer is set correctly';
dies_ok { $t_bad->help_message   }  'help_message is set correctly';

# TESTS -> *3
for  my $module  ($t_in, $t_inc, $t_nin) {
    my ($status, $answer, $wanted) = $module->solve;
    my $short_answer               = $module->solve;

    my $last_answer = $module->solved_answer;
    my $last_wanted = $module->solved_wanted;
    my $last_status = $module->solved_status;
    my $more_info   = $module->more_info;

    # TESTS -> 7
    is( $status   , $last_status         , 'Status returned and object status should be equal'            );
    is( $wanted   , $last_wanted         , 'Status returned and object status should be equal'            );
    is( $answer   , $last_answer         , 'Answer returned and object answer should be equal'            );
    is( $answer   , $short_answer        , 'The answer returned in scalar and array context should match' );
    is( $answer   , $wanted              , 'Answer returned and required answer should be equal'          );
    is( $more_info, $module->problem_name, 'Correct "more_info" text'                                     );
    ok( $status   ,                        'The status should be true'                                    );
}


# TESTS -> 2
{
    my ($status, $answer, $wanted) = $t_inc->solve;

    isnt( $answer, $t_inc->default_answer, 'Answer and required should not be equal for the custom input' );
    is  ( $wanted, $CUSTOM_ANSWER,         'The wanted and CUSTOM_ANSWER should be the same'              );
}


# TESTS -> 5
{
    $t_inc->custom_answer( $CUSTOM_INPUT );

    my ($status, $answer, $wanted) = $t_inc->solve;

    my $last_answer = $t_inc->solved_answer;
    my $last_wanted = $t_inc->solved_wanted;
    my $last_status = $t_inc->solved_status;

    is  ( $status, $last_status,  'Status returned and object status should be equal'       );
    is  ( $wanted, $last_wanted,  'Status returned and object status should be equal'       );
    is  ( $answer, $last_answer,  'Answer returned and object answer should be equal'       );
    isnt( $answer, $wanted,       'Answer returned and required answer should not be equal' );
    ok  ( !$status,               'The status should not be true'                           );
}
