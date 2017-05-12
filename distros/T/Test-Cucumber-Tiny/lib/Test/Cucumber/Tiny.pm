package Test::Cucumber::Tiny;
{
  $Test::Cucumber::Tiny::VERSION = '0.64';
}
use Mo qw( default );
use Try::Tiny;
use Carp qw( confess );
use YAML ();
use Readonly;
require Test::More;

=head1 NAME

Test::Cucumber::Tiny - Cucumber-style testing in perl

=head1 SYNOPSIS

Cucumber is a tool that executes plain-text functional
descriptions as automated tests. The language that Cucumber
understands is called Gherkin.

While Cucumber can be thought of as a "testing" tool, 
the intent of the tool is to support BDD. This means that
the "tests" are typically written before anything else and
verified by business analysts, domain experts, etc. non technical
stakeholders. The production code is then written outside-in,
to make the stories pass.

=head1 USAGE

If you need to shared the scenarios with the business analysts.

Write the scenarios in YAML 

 use Test::More tests => 1;
 use Test::Cucumber::Tiny;

subtest "Feature Test - Calculator" => sub {
    ## In order to avoid silly mistake
    ## As a math idiot
    ## I want to be told a sum of 2 numbers

    ## Here is an example using YAML file:

    my $cucumber = Test::Cucumber::Tiny->ScenariosFromYAML(
        "t/test_functions/something_something.yml");

    ## Here is an example using a list:

    my $cucumber = Test::Cucumber::Tiny->Scenarios(
        {
            Scenario => "Add 2 numbers",
            Given    => [
                "first, I entered 50 into the calculator",
                "second, I entered 70 into the calculator",
            ],
            When => [ "I press add", ],
            Then => [ "The result should be 120 on the screen", ]
        },
        {
            Scenario => "Add numbers in examples",
            Given    => [
                "first, I entered <1st> into the calculator",
                "second, I entered <2nd> into the calculator",
            ],
            When     => [ "I press add", ],
            Then     => [ "The result should be <answer> on the screen", ],
            Examples => [
                {
                    '1st'  => 5,
                    '2nd'  => 6,
                    answer => 11,
                },
                {
                    '1st'  => 100,
                    '2nd'  => 200,
                    answer => 300,
                }
            ],
        },
        {
            Scenario => "Add numbers using data",
            Given    => [
                {
                    condition => "first, I entered number of",
                    data      => 45,
                },
                {
                    condition => "second, I entered number of",
                    data      => 77,
                }
            ],
            When => [ "I press add", ],
            Then => [
                {
                    condition => "The result is",
                    data      => 122,
                }
            ],
        }
    );

    $cucumber->Given(
        qr/^(.+),.+entered (\d+)/ => sub {
            my $c       = shift;
            my $subject = shift;
            my $key     = $1;
            my $num     = $2;
            $c->{$key} = $num;
            $c->Log($subject);
        }
      )->Given(
        qr/^(.+),.+entered number of/ => sub {
            my $c       = shift;
            my $subject = shift;
            my $key     = $1;
            $c->{$key} = $c->{data};
        }
      )->When(
        qr/press add/ => sub {
            my $c       = shift;
            my $subject = shift;
            $c->{answer} = $c->{first} + $c->{second};
        }
      )->Then(
        qr/result.+should be (\d+)/ => sub {
            my $c        = shift;
            my $subject  = shift;
            my $expected = $1;
            is $c->{answer}, $expected, $subject;
        }
      )->Then(
        qr/result is/ => sub {
            my $c       = shift;
            my $subject = shift;
            is $c->{data}, $c->{answer}, $subject;
        }
      )->Test;
};

=cut

has scenarios => (
    required => 1,
    is       => "ro",
    isa      => "ArrayRef[HashRef]",
);

=head1 METHODS

=head2 new

Create a cucumber for test

 Test::Cucumber::Tiny->new(
    scenarios => [
        {
            ....
        }
    ]
 )

 ->Given(...)
 
 ->Then(...)

 ->Test;

=head2 Scenarios

Create a cucumber with a plain array list of scenarios

 Test::Cucumber::Tiny->Scenarios(
    { ... }
 )
 ->Given(...)
 ->When(...)
 ->Then(...)
 ->Test;

=cut

sub Scenarios {
    my $class = shift;
    return $class->new( scenarios => \@_ )
        if !ref $class;
    my $self = $class;
    push @{ $self->scenarios }, @_;
    return $self;
}

=head2 ScenariosFromYML

Create a cucumber from a YAML file.

YMAL Example:

 - Scenario: Add 2 numbers
   Given:
     - first, I entered 50 into the calculator
     - second, I entered 70 into the calculator
   When: I press add
   Then: The result should be 120 on the screen

 - Scenario: Add 3 numbers
   Given:
     - first, I entered 50 into the calculator
     - second, I entered 70 into the calculator
     - third, I entered 10 into the calculator
   When: I press add
   Then: The result should be 130 on the screen

In Code:

 my $cuc = Test::Cucumber::Tiny->ScenariosFromYML( "feature-1.yml" )
 ->ScenariosFromYML( "feature-2.yml" )
 ->ScenariosFromYML( "feature-3.yml" )
 ->ScenariosFromYML( "feature-4.yml" )
 ->Given(...)
 ->Whn(...)
 ->Then(...)
 ->Test;

=cut

sub ScenariosFromYML {
    goto &ScenariosFromYAML;
}

sub ScenariosFromYAML {
    my $class = shift;
    my @scenarios = _decode_yml(@_)
        or return $class;
    return $class->Scenarios( @scenarios );
}

=head2 Before

@param regexp

@code ref

=cut

sub Before {
    my $self      = shift;
    my $condition = shift
      or die "Missing regexp or coderef";
    my $definition = shift;

    if ( ref $condition eq "CODE" ) {
        $definition = $condition;
        $condition  = qr/.+/;
    }

    push @{ $self->_befores },
      {
        condition  => $condition,
        definition => $definition,
      };

    return $self;
}

has _befores => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 Given

@param regexp

@param code ref

=cut

sub Given {
    my $self      = shift;
    my $condition = shift
      or die "Missing 'Given' condition";
    my $definition = shift
      or die "Missing 'Given' definition coderef";
    push @{ $self->_givens },
      {
        condition  => $condition,
        definition => $definition,
      };
    return $self;
}

has _givens => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 When

@param regexp / hashref { regexp, data }

@param code ref

=cut

sub When {
    my $self      = shift;
    my $condition = shift
      or die "Missing 'When' condition";
    my $definition = shift
      or die "Missing 'When' definition coderef";
    push @{ $self->_whens },
      {
        condition  => $condition,
        definition => $definition,
      };
    return $self;
}

has _whens => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 Then

@param regexp / hashref { regexp, data }

@param code ref

=cut

sub Then {
    my $self      = shift;
    my $condition = shift
      or die "Missing 'Then' condition";
    my $definition = shift
      or die "Missing 'Then' definition coderef";
    push @{ $self->_thens },
      {
        condition  => $condition,
        definition => $definition,
      };
    return $self;
}

has _thens => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 Any

Use any to set all 3 like below

 ->Any( qr/.+/ => sub { return 1 } );

Same as

 ->Before( qr/.+/ => sub { return 1 } );
 ->Given(  qr/.+/ => sub { return 1 } );
 ->When(   qr/.+/ => sub { return 1 } );
 ->Then(   qr/.+/ => sub { return 1 } );
 ->After(  qr/.+/ => sub { return 1 } );

=cut

sub Any {
    my $self = shift;
    $self->Before(@_);
    $self->Given(@_);
    $self->When(@_);
    $self->Then(@_);
    $self->After(@_);
    return $self;
}

=head2 After

@param regexp

@code ref

=cut

sub After {
    my $self      = shift;
    my $condition = shift
      or die "Missing regexp or coderef";
    my $definition = shift;

    if ( ref $condition eq "CODE" ) {
        $definition = $condition;
        $condition  = qr/.+/;
    }

    push @{ $self->_afters },
      {
        condition  => $condition,
        definition => $definition,
      };

    return $self;
}

has _afters => (
    is      => "ro",
    isa     => "ArrayRef[HashRef]",
    default => sub { [] },
);

=head2 NextStep

When you are the functions of Given

Call NextStep will jump to When

When you are the functions of When

Call NextStep will jump to Then

When you are the functions of Then

Call NextStep will finish the current scenario.

=cut

Readonly my $NEXT_STEP => "Next Step";

sub NextStep {
    die { intercept => $NEXT_STEP };
}

=head2 NextExample

When you are the functions of Given, When or Then

Call NextExample will finish the current cycle and 
use the next example data in the current scenario.

=cut

Readonly my $NEXT_EXAMPLE => "Nex Example";

sub NextExample {
    die { intercept => $NEXT_EXAMPLE };
}

=head2 NextScenario

Just jump to the next scenario.

=cut

Readonly my $NEXT_SCENARIO => "Next Scenario";

sub NextScenario {
    die { intercept => $NEXT_SCENARIO };
}

=head2 Test

Start Cucumber to run through the scenario.

=cut

Readonly my @STEPS => qw(
  Before
  Given
  When
  Then
  After
);

sub Test {
    my $self = shift;
    my @run_through = ( "Before", @STEPS, "After" );

    $self->Any(
        qr/^debugger$/ => sub {
            my $c            = shift;
            my $subject      = shift;
            my $Scenario     = $c->{Scenario};
            my $Step         = $c->{Step};
            my $Data         = $c->{data};
            my $Example      = $c->{Example};
            my $Examples     = $c->{Examples};
            my $FEATURE_WIDE = $c->{FEATURE_WIDE};
            $self->Log("! DEBUG: $Scenario - $Step");
            $DB::single = 1;
            $DB::single = 2;    ## Avoid warnings use only once
            print q{};
        }
    );

  SCENARIO:
    foreach my $scenario ( @{ $self->scenarios } ) {

        _check_scenario_steps($scenario);

        my $subject = $scenario->{Scenario}
          or die "Missing the name of Scenario";

        my @examples = @{ $scenario->{Examples} || [ {} ] };

        my %stash = ();
        my $stash_ref = bless \%stash, ref $self;

        Readonly $stash{Scenario}     => $subject;
        Readonly $stash{Examples}     => \@examples;
        Readonly $stash{FEATURE_WIDE} => $self->FEATURE_WIDE_VAR;

        my %triggers = ();

        $triggers{Before} = sub {
            $self->_trigger_before_running_step(
                Before => ( $subject, $scenario ) );
        };

        $triggers{After} = sub {
            $self->_trigger_before_running_step(
                After => ( $subject, $scenario ) );
        };

      EXAMPLE:
        foreach my $example (@examples) {
            $stash{Example} = $example;

            my $subject = _apply_example( $subject => %$example );

            $self->Log("\n--> Scenario: $subject\n");

          STEP:
            foreach my $step (@run_through) {
                $stash{Step} = $step;
                my $intercept =
                  $self->_run_step( $step, $scenario, $example, $stash_ref,
                    $triggers{$step} )
                  or next STEP;
                next STEP     if $intercept eq $NEXT_STEP;
                next EXAMPLE  if $intercept eq $NEXT_EXAMPLE;
                next SCENARIO if $intercept eq $NEXT_SCENARIO;
            }
        }
    }
}

sub _trigger_before_running_step {
    my $self       = shift;
    my $big_name   = shift;
    my $subject    = shift;
    my $scenario   = shift;
    my $small_name = lcfirst $big_name;
    my $array_name = "_$small_name" . 's';
    if ( !@{ $self->$array_name } ) {
        $self->NextStep;
    }
    if ( !$scenario->{$big_name} ) {
        $scenario->{$big_name} = $subject;
    }
}

sub _run_step {
    my $self        = shift;
    my $step        = shift;
    my $scenario    = shift;
    my $example     = shift;
    my $stash_ref   = shift;
    my $before_step = shift || sub { };
    try {
        my $small_step = lc $step;
        my $big_step   = ucfirst $step;
        my $array_name = "_$small_step" . 's';
        $before_step->();
        _run_test(
            $big_step => $scenario->{$big_step},
            $example, $self->$array_name, $stash_ref
        );
    }
    catch {
        my $int = _intercept();
        return $int
          ? $int
          : confess($_);
    };
}

has FEATURE_WIDE_VAR => (
    is      => "ro",
    isa     => "HashRef",
    default => sub { {} },
);

sub _run_test {
    my $step          = shift;
    my $preconditions = shift
      or die "Missing '$step' in scenario";
    my $example_ref = shift;
    my $items_ref   = shift;
    my $stash_ref   = shift;

    my @preconditions =
      ref $preconditions eq "ARRAY"
      ? @$preconditions
      : ($preconditions);

    foreach my $precondition (@preconditions) {

        return if !$precondition;
        return if ref $precondition && !%$precondition;

        foreach my $item (@$items_ref) {
            my $condition = $item->{condition};
            $precondition = _apply_example( $precondition => %$example_ref );
            if ( ref $precondition ) {
                my %checks = _check_hash_has_the_only_keys(
                    [qw(condition data)] => %$precondition );
                if ( $checks{missing} ) {
                    die sprintf "\nFIXME: missing setting of %s $step\n\n",
                      join( ", ", map { qq{"$_"} } @{ $checks{missing} } );
                }
                $stash_ref->{data}            = $precondition->{data};
                $stash_ref->{"_${step}_data"} = $precondition->{data};
                $precondition                 = $precondition->{condition};
            }
            if ( $precondition =~ /$condition/ ) {
                $item->{definition}->( $stash_ref, "$step $precondition" );
            }
        }
    }
}

sub _apply_example {
    my $pre_cond = shift;
    my %example  = @_
      or return $pre_cond;
    foreach my $key ( keys %example ) {
        if ( ref $pre_cond ) {
            $pre_cond->{condition} =~ s/<\Q$key\E>/$example{$key}/g;
        }
        else {
            $pre_cond =~ s/<\Q$key\E>/$example{$key}/g;
        }
    }
    return $pre_cond;
}

sub _intercept {
    my $error = $_
      or return q{};
    return q{} if !ref $error;
    return q{} if ref $error ne "HASH";
    my $intercept = $error->{intercept}
      or return q{};
    return $intercept;
}

Readonly my @HEADS => qw(
  Scenario
  Examples
);

sub _check_scenario_steps {
    my $scenario      = shift;
    my %scenario_hash = ();
    if ( ref $scenario eq "ARRAY" ) {
        %scenario_hash = @$scenario;
    }
    if ( ref $scenario eq "HASH" ) {
        %scenario_hash = %$scenario;
    }

    my %known = map { $_ => 1 } ( @HEADS, @STEPS );

    my %result =
      _check_hash_has_the_only_keys( [ @HEADS, @STEPS ], %scenario_hash )
      or return;

    return if !@{ $result{invalid} };

    my $subject =
      $scenario_hash{Scenario} ? " at '$scenario_hash{Scenario}'" : q{};

    die sprintf "\nFIXME: unrecognized steps %s$subject\n\n",
      join( ", ", map { qq{"$_"} } @{ $result{invalid} } );
}

sub _check_hash_has_the_only_keys {
    my $keys_ref = shift;
    my %hash     = @_;

    my %needed  = map  { $_ => 1 } @$keys_ref;
    my @invalid = grep { !$needed{$_} } keys %hash;
    my @missing = grep { !exists $hash{$_} } keys %needed;

    return if !@invalid && !@missing;

    return (
        invalid => \@invalid,
        missing => \@missing,
    );
}

## method name in Test::More
## e.g. diag, explain, note, etc...
has verbose => (
    is      => "ro",
    isa     => "Str",
    default => "explain",
);

=head2 Log

To use different Test verbose methods like diag, note or explain

To set the method by

export CUCUMBER_VERBOSE=diag

or

$ENV{CUCUMBER_VERBOSE} = "diag";

or

...::Tiny->new( verbose => "diag" );

By default the method is "explain"

=head3 usage

 $cucumber->Log( "here" );

 $cucumber->Given(qr/.+/ => sub {
    my $c = shift;
    $c->Log( "Test" );
 });

=cut

sub Log {
    my $self    = shift;
    my $message = shift
      or return;
    my $mode = $ENV{CUCUMBER_VERBOSE} || $self->verbose
      or return;
    my $code = Test::More->can($mode)
      or confess(
        "FIXME: Invalid verbose mode $mode. Try any method in Test::More");
    $code->($message);
}

=head1 BUILTIN STEPS

=head2 debugger

Use debugger in any steps with perl -d 

that will stop to the point when reached.

e.g.

 Test::Cucumber::Tiny->Scenarios(
    {
        Given => "a child found a book in library",
        When  => "he finished reading",
        Then  => [
            "debugger", ## <---- STOP here when run with perl -d test.t
            "he will return it",
        ]
    }
 );

=head1 BUILTIN DATA POINTS

=head2 $c

Scenario wide stash, each scenario has it own one.

any step subref the first arguments will be a hashref

e.g.

 $cucumber->Given( qr/.+/ => sub {
     my $c       = shift; ## it is a hashref
     my $subject = shift; ## The subject of the step
     $c->Log( $subject );
 });

=head2 $c->{FEATURE_WIDE}

Feature wide stash, all scenarios shared the same one.

you can reach it inside the scenario stash by 
FEATURE_WIDE key

e.g.

 $cucumber->Given( qr/.+/ => sub {
     my $c       = shift;
     my $subject = shift;
     my $f       = $c->{FEATURE_WIDE}; ## A readonly HashRef
     $f->{something_here} = 1;
     $c->Log( $subject );
 });

=head2 $c->{Scenario}

The subject you set for that scenario

e.g.

 $cucumber->Given( qr/.+/ => sub {
     my $c = shift;
     $c->Log( $c->{Scenario} );
 });

=head2 $c->{Step}

The subject you set for the current step

e.g.

 $cucumber->Given( qr/.+/ => sub {
     my $c = shift;
     $c->Log( $c->{Step} );
 });

=head2 $c->{data}

The current running step sample data

e.g.

 ...::Tiny->Scenarios(
    {
        Given  => {
            condition => "...",
            data      => "ANYTHING HERE",
        }, ...
    }
 )
 ->Given( qr/.+/ => sub {
     my $c = shift;
     my $anything_here = $c->{data};
 });

=head2 $c->{Example}

The current running example

=head2 $c->{Examples}

All the examples in the current scenario

e.g.

 ...::Tiny->Scenarios(
    {
        Given  => "... <placeholder>",
        Examples => [
            {
                placeholder => "foobar",
            },
            {
                placeholder => "sample",
            }
        ]
    }
 )
 ->Given( qr/.+/ => sub {
     my $c = shift;
     my $examples = $c->{data};
 });

=cut

=head1 SEE ALSO

L<http://cukes.info/>

L<https://github.com/cucumber/cucumber/wiki/Scenario-outlines>

=cut

sub _decode_yml {
    my $yml_file = shift
      or die "Missing YAML file\n";

    if ( !-f $yml_file ) {
        die "YAML file is not found\n";
    }

    my $scenarios_ref = YAML::LoadFile($yml_file)
      or die "YAML file has no scenarios";

    if ( ref $scenarios_ref ne "ARRAY" ) {
        die "Invalid sceanrio in yml file. It is expecting array list\n";
    }

    return @$scenarios_ref;
}

no Mo;
no Carp;
no YAML;
no Try::Tiny;

1;
