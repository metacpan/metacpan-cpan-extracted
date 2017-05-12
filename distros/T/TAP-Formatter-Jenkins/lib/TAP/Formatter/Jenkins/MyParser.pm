package TAP::Formatter::Jenkins::MyParser;

use Modern::Perl;
use TAP::Parser;

BEGIN {
    no strict 'refs';
    for my $name ( qw/ is_test is_unknown is_comment as_string ok / ) {
        *{ "TAP::Formatter::Jenkins::MyParser::$name" } =
            sub {
                my $self = shift;
                return $self->{current} && $self->{current}->$name(@_);
            };
    }
    use strict 'refs';
}

my $TIME_STAMP              = qr{ \[\d+:\d+:\d+\]                               }ix;
my $TIME_TEST               = qr{ ok\s\d+\s(?:ms|s)                             }ix;

my $RETURN_CODE             = qr{ dubious,\s+test\s+returned\s+\d+              }ix;
my $TODO                    = qr{ \d+\s+todo\s+test\s+unexpectedly\s+succeeded  }ix;
my $SKIP                    = qr{ less\s+\d+\s+skipped\s+subtest                }ix;
my $FAILED_SUBTESTS_COUNT   = qr{ failed\s+\d+\/\d+\s+subtests                  }ix;
my $PASSED_SUBTESTS         = qr{ all\s+\d+\s+subtests\s+passed                 }ix;
my $NO_SUBTESTS_RUN         = qr{ no\ssubtests\srun                             }ix;
my $TEST_REPORT             = qr{ $FAILED_SUBTESTS_COUNT |
                                  $PASSED_SUBTESTS       |
                                  $TODO                  |
                                  $SKIP                  |
                                  $RETURN_CODE           |
                                  $NO_SUBTESTS_RUN
                                }ix;

my $TEST_NAME               = qr{ t\/lib\/( (?:.+\/)*.+ ).t\s\.{2,}             }ix;
my $SUBTEST                 = qr{ ok\s\d{1,3}\s-\s.*                            }ix;
my $TEST_FAILURE            = qr{ not\sok\s\d{1,3}\s-\s.*                       }ix;
my $SUMMARY_REPORT          = qr{ test\s+summary\s+report |
                                  all\s+tests\s+successful
                                }ix;

my $ALLOW_UNKNOWN_STRS      = qr{ $TIME_STAMP  |
                                  $TEST_REPORT |
                                  $SUBTEST     |
                                  $TEST_FAILURE
                                }ix;

my $SUBTEST_PLAN            = qr{ ^\s+\d+\.\.\d+                                }ix;
my $NO_PLAN                 = qr{ no\splan\swas\sdeclared                       }ix;
my $FAILED_PLAN             = qr{ you\splanned\s\d+\stests\sbut\sran\s\d+       }ix;
my $EXIT_BEFORE_OUTPUT      = qr{ looks\slike\syour\stest\sexited\swith\s\d+\sbefore\sit\scould\soutput\sanything }ix;
my $PLAN_REPORT             = qr{ $NO_PLAN | $FAILED_PLAN | $EXIT_BEFORE_OUTPUT }ix;

my $YAMLISH_START           = qr{ (\#\s*)?\s---                                 }ix;
my $YAMLISH_END             = qr{ (\#\s*)?\s\.\.\.                              }ix;
my $YAMLISH                 = qr{ $YAMLISH_START [\s\S]+ $YAMLISH_END           }ix;

sub new {
    my ( $class, $tap ) = @_;

    return  unless $tap;

    my $self = bless {}, $class;

    $self->{parser } = TAP::Parser->new({ tap => $tap });
    $self->{current} = $self->{parser}->next;

    return $self;
}

sub next {
    my ( $self ) = @_;

    $self->{current} = $self->{parser}->next;
}

sub fail {
    my ( $self ) = @_;

    return  $self->{current}
             &&
            (
                ( $self->is_test
                   &&
                  $self->ok eq "not ok"
                )
                ||
                $self->as_string =~ / $TEST_FAILURE /ix
            );
}

sub is_time_test {
    my ( $self ) = @_;

    return $self->{current}
            &&
           $self->as_string =~ / $TIME_TEST /ix;
}

sub is_test_name {
    my ( $self ) = @_;

    my $res = $self->{current}
               &&
              $self->is_unknown
               &&
              $self->as_string =~ / $TEST_NAME /ix;

    return $1;
}

sub is_plan_report {
    my ( $self ) = @_;

    return $self->{current}
            &&
           $self->is_unknown
            &&
           $self->as_string =~ /$PLAN_REPORT/ix;
}

sub is_return_code {
    my ( $self ) = @_;

    return $self->{current}
            &&
           $self->is_unknown
            &&
           $self->as_string =~ /$RETURN_CODE/ix;
}

sub is_yamlish_start {
    my ( $self ) = @_;

    return $self->{current}
            &&
           $self->as_string =~ /^$YAMLISH_START/ix;
}

sub is_yamlish_end {
    my ( $self ) = @_;

    return $self->{current}
            &&
           $self->as_string =~ /^$YAMLISH_END/ix;
}

sub is_subtest_plan {
    my ( $self ) = @_;

    return $self->{current}
            &&
           $self->as_string =~ /$SUBTEST_PLAN/ix;
}

sub like_die {
    my ( $self ) = @_;

    return $self->{current}
            &&
           $self->is_unknown
            &&
           $self->as_string !~ /$ALLOW_UNKNOWN_STRS/ix;
}

sub has_ended {
    my ( $self ) = @_;

    return ! defined $self->{current};
}

1;
