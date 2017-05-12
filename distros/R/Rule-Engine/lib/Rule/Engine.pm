package Rule::Engine;
use Moose;

=head1 NAME

Rule::Engine - A Rule Engine

=cut

our $VERSION = '0.06';

=head1 DESCRIPTION

Rule::Engine is a system for creating sets of rules (RuleSets) and executing
them against a list of objects.

=head1 SYNOPSIS

    use Rule::Engine::Filter;
    use Rule::Engine::Rule;
    use Rule::Engine::RuleSet;
    use Rule::Engine::Session;

    my $sess = Rule::Engine::Session->new;
    $sess->set_environment('temperature', 65);

    # Make a ruleset
    my $rs = Rule::Engine::RuleSet->new(
        name => 'some-ruleset',
        filter => Rule::Engine::Filter->new(
            condition => sub {
                # Check something here.  Any object that returns true will
                # be kept. Args are $self, $session and the object
                my ($self, $sess, $obj);
                $obj->happy ? 1 : 0
            }
        )
    );

    # Make a rule to add to the set.  This rule's condition will be executed
    # for each object.  If it returns a true value then the action will be
    # executed for each object.
    my $rule = Rule::Engine::Rule->new(
        name => 'temperature',
        condition => sub {
            my ($self, $sess, $obj) = @_;
            return $obj->favorite_temp == $sess->get_environment('temperature');
        },
        action => sub {
            my ($self, $sess, $obj) = @_;
            $obj->happy(1);
        }
    );

    # Add the rule
    $rs->add_rule($rule);

    # Add the ruleset to the session
    $sess->add_ruleset($rs->name, $rs);

    # Execute the rule, getting back an arrayref of objects that passed the
    # filter after running through all the rules whose conditions were met
    my $results = $sess->execute('some-ruleset', \@list_of_objects);

=head1 CONCEPTS

=head2 Rules

Rules are made of a B<condition> and an B<action>.  If the condition evaluates
to true for a given object, then the action is executed.

	my $rule = Rule::Engine::Rule->new(
	    name => 'check_score',
	    condition => sub {
	        my ($self, $sess, $obj) = @_;
			# Test the score
	        return $obj->score >= 59;
	    },
	    action => sub {
	        my ($self, $sess, $obj) = @_;
			# Passing score!
        	$obj->pass(1);
	    }
	);

Conditions and actions are executed individually for each object that is
passed into the RuleSet.

=head2 RuleSets

RuleSets are collections of rules – executed in order – with an optional
filter that removes objects that match (or don't match) a certain criteria
after all the rules have been evaluated.

	my $rs = Rule::Engine::RuleSet->new(
	    name => 'some-ruleset',
		# Completely optional filter
	    filter => Rule::Engine::Filter->new(
	        condition => sub {
	            # Check something here.  Any object that returns true will
	            # be kept.
	            $_[1]->is_something ? 1 : 0
	        }
	    )
	);

	$rs->add_rule(...);
	$rs->add_rule(...);

	my $results = $rs->execute(\@objects);

The above example has two rules and a filter.  The filter removes any objects
from the results B<after> the rules have been executed.  Since each rule
might alter the object, the filter has a chance at the end to limit the returned
objects to just those that have met certain criteria.  This might be useful to
determine which students have passed an example, which items in a cart need
to be removed or which customers have the appropriate attributes for a
promotion.

=head2 Session

A session is a period of interaction with Rule::Engine.  The environment
provides a collection of possible RuleSets and an environment hash.

=head1 NOTES

=head2 Filtered and Unfiltered

There are two common use-cases for a RuleSet: filtered and unfiltered. Filtered
RuleSets are primarily used for binary problem.  If you need to evaluate some
rules and then eliminate some items, this is how you do it.  This seems (to me
at least) fairly obvious.  The other option, less so.

Unfiltered RuleSets don't eliminate anyone and in my uses are often not used
with multiple input objects.  A great example of this is calculating a credit
limit for a credit application.  There's nothing to eliminate, in this case.
We want to first decide if the customer is eligible for credit and then, based
on various attributes, decide how much credit to give them.  A single Application
object may be passed in and attributes tested and set.  If the credit score is
too low, then the limit may be set to 0.  Afterward, there's no reason for a
filter.  We just want to know what the value of C<Account->limit> turned out
to be.

The point of this documentation blurb is to illustrate that Rule::Engine is
useful in terms of deciding I<how> to do something, not just I<which> objects
to do something to.

=back

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

no Moose;

1;
