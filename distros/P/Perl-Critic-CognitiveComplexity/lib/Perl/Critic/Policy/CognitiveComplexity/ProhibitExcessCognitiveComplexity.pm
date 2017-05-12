package Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity;
use strict;
use warnings;

use Readonly;
use Readonly qw (Scalar);
use Perl::Critic::Utils qw{ :severities :classification :ppi };
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.5';

Scalar my $EXPL => q{Avoid code that is nested, and thus difficult to grasp.};
Readonly my %BOOLEAN_OPS => map { $_ => 1 } qw( && || and or );

sub supported_parameters {
    return ( {
            name            => 'warn_level',
            description     => 'The complexity score allowed before warning starts.',
            default_string  => '10',
            behavior        => 'integer',
            integer_minimum => 1,
        },
        {
            name            => 'info_level',
            description     => 'The complexity score allowed before informational reporting starts.',
            default_string  => '1',
            behavior        => 'integer',
            integer_minimum => 1,
        }
    );
}

sub default_severity {
    return $SEVERITY_MEDIUM;
}

sub default_themes {
    return qw( complexity maintenance );
}

sub applies_to {
    return 'PPI::Statement::Sub';
}

sub violates {
    my ( $self, $elem, undef ) = @_;

    # only report complexity for named subs.
    my $name = $elem->name() or return;

    # start with complexity of 0
    my $score = 0;
    my $block = $elem->find_first('PPI::Structure::Block');

    $score += $self->_structure_score($block , 0);
    $score += $self->_operator_score($block);
    $score += $self->_recursion_score($block, $name);

    # return no violation
    return if($score < $self->{'_info_level'});
    # return violation
    return ($self->_new_violation($elem, $score));
}

sub _new_violation {
    my $self = shift;
    my ($elem, $score) = @_;
    my $name = $elem->name();
    my $desc = qq<Subroutine '$name' with complexity score of '$score'>;

    return Perl::Critic::Violation->new( $desc, $EXPL, $elem,
        ($score >= $self->{'_warn_level'} ? $self->get_severity() : $SEVERITY_LOWEST ));
}

sub _structure_score {
    my $self = shift;
    my ( $elem, $nesting ) = @_;

    return 0 unless ( $elem->can('schildren') );

    my $complexity = 0;

    for my $child ( $elem->schildren() ) {
        #my $inc = 0;
        if (   $child->isa('PPI::Structure::Given')
            || $child->isa('PPI::Structure::Condition')
            || $child->isa('PPI::Structure::For')
            || $self->_is_foreach_statement($child)
            )
        {
            if($self->_nesting_increase($child->parent)) {
                $complexity += $nesting;
            } else {
                # missing compound statement / increment on postfix operator_score
                $complexity += $nesting + 1;
            }
        }
        # 'return' is a break-statement, but does not count in terms of cognitive complexity.
        elsif ( $child->isa('PPI::Statement::Break') && ! $self->_is_return_statement($child)) {
            $complexity++;
        }
        $complexity += $self->_structure_score( $child, $nesting + $self->_nesting_increase($child) );
    }
    return $complexity;
}

sub _operator_score {
    my $self = shift;
    my ($sub) = @_;
    my $by_parent = {};
    my $elems = $sub->find('PPI::Token::Operator');
    my $sum = 0;
    if($elems) {
        map { push @{$by_parent->{$_->parent}}, $_->content }
            grep { exists $BOOLEAN_OPS{$_->content} } @$elems;
        for my $parent (keys %{$by_parent}) {
            my @ops = @{$by_parent->{$parent}};
            OP: for(my $i = 0; $i < scalar @ops; ++$i) {
                if($i > 0 && $ops[$i-1] eq $ops[$i]) {
                    next OP;
                }
                $sum++;
            }
        }
    }
    return $sum;
}

sub _recursion_score {
    my $self = shift;
    my ($sub, $method_name) = @_;
    if($sub->find(sub {
        # TODO: check for false positives..
        $_[1]->isa( 'PPI::Token::Word' ) && $_[1]->content eq $method_name
    })) {
        return 1;
    }
    return 0;
}

sub _is_return_statement {
    my $self = shift;
    my ($child) = @_;
    scalar $child->find( sub { $_[1]->content eq 'return' });
}

sub _is_foreach_statement {
    my $self = shift;
    my ($child) = @_;
    my $foreach = $child->parent()->schild(0);
    return($child->isa('PPI::Structure::List') && $foreach && $foreach->isa('PPI::Token::Word') && $foreach->content eq 'foreach');
}

sub _nesting_increase {
    my $self = shift;
    my ($child) = @_;

    # if/when/for...
    return 1 if ($child->isa('PPI::Statement::Compound'));
    return 1 if ($child->isa('PPI::Statement::Given'));
    # anonymous sub
    return 1 if ($child->isa('PPI::Statement') && $child->find( sub { $_[1]->content eq 'sub' }));

    return 0;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity - Avoid code that is nested, and thus difficult to grasp.

=head1 DESCRIPTION

Cyclomatic Complexity was initially formulated as a measurement of the "testability and
maintainability" of the control flow of a module. While it excels at measuring the former, its
underlying mathematical model is unsatisfactory at producing a value that measures the
latter. A white paper from SonarSource* describes a new metric that breaks from the use of mathematical
models to evaluate code in order to remedy Cyclomatic Complexity's shortcomings and
produce a measurement that more accurately reflects the relative difficulty of understanding,
and therefore of maintaining methods, classes, and applications.

* https://blog.sonarsource.com/cognitive-complexity-because-testability-understandability/

=head2 Basic criteria and methodology

A Cognitive Complexity score is assessed according to three basic rules:

1. Ignore structures that allow multiple statements to be readably shorthanded into one
2. Increment (add one) for each break in the linear flow of the code
3. Increment when flow-breaking structures are nested

Additionally, a complexity score is made up of three different types of increments:

A. Nesting - assessed for nesting control flow structures inside each other
B. Structural - assessed on control flow structures that are subject to a nesting
increment
C. Fundamental - assessed on statements not subject to a nesting increment

While the type of an increment makes no difference in the math - each increment adds one
to the final score - making a distinction among the categories of features being counted
makes it easier to understand where nesting increments do and do not apply.


=head1 EXAMPLES

Some examples from the whitepaper, translated to perl.

  #                                Cyclomatic Complexity    Cognitive Complexity

Most simple case: subs themselves do not increment the cognitive complexity.

  sub a {                          # +1
  }                                # =1                      =0

C<given/when> increments cognitive complexity only once.

  sub getWords {                   # +1
      my ($number) = @_;
      given ($number) {            #                         +1
        when (1)                   # +1
          { return "one"; }
        when (2)                   # +1
          { return "a couple"; }
        default                    # +1
          { return "lots"; }
      }
}                                  # =4                      =1

The deeper the nesting, the more control-structures add to the complexity.

C<goto>, C<next> and C<last> break the linear flow, which increments the
complexity by one.

  sub sumOfPrimes {
    my ($max) = @_;
    my $total = 0;
    OUT: for (my $i = 1; $i <= $max; ++$i) { #               +1
        for (my $j = 2; $j < $i; ++$j) { #                   +2
            if ($i % $j == 0) { #                            +3
                 next OUT; #                                 +1
            }
        }
        $total += $i;
    }
    return $total;
  } #                                                        =7

Anonymous functions do not increment the complexity, but the nesting.

  sub closure {
      sub { #                                                +0 (nesting=1)
          if(1) { #                                          +2 (nesting=1)
              return;                                        +0 (nesting=2)
          }
      }->();
  }                                                          =2

Cognitive Complexity does not increment for each logical operator.
Instead, it assesses a fundamental increment for each sequence of logical operators.

  sub boolMethod2 {
      if( #                                                  +1
      $a && $b && $c #                                       +1
      || #                                                   +1
      $d && $e) #                                            +1
      {
  } #                                                        =4

