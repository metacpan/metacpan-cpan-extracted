package Perl::Critic::Policy::Variables::ProhibitUselessInitialization;

use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils ':severities';

our $VERSION = '0.02';

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitUselessInitialization - prohibit superfluous initializations

=head1 DESCRIPTION

Don't clutter your code with unnecessary variable initialization:

    my $scalar = undef;     # don't do this
    my @array  = ();        # or this
    my %hash   = ();        # or this

Instead, do this:

    my $scalar;             # equivalent
    my @array;              # ditto
    my %hash;               # isn't that better?

=head1 AUTHOR

John Trammell <johntrammell -at- gmail -dot- com>

=head1 COPYRIGHT

Copyright (c) John Joseph Trammell.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

=head2 desc()

Returns a string containing a sort description of this policy.

=cut

sub desc {
    'Useless variable initialization';
}


=head2 expl()

Returns a string containing an explanation of this policy.

=cut

sub expl {
    q{Don't clutter your code with unnecessary variable initializations};
}

=head2 supported_parameters

Define parameters supported by this policy.  There are none.

=cut

sub supported_parameters {
    return ();
}

=head2 default_severity

Returns a numeric constant defining the severity of violating this policy.

=cut

sub default_severity {
    return $SEVERITY_LOW;
}

=head2 default_themes

Returns a list of strings defining the themes for this policy.

=cut

sub default_themes {
    return qw(petpeeves JTRAMMELL);
}

=head2 applies_to

Returns a string describing the elements to which this policy applies.

=cut

sub applies_to {
    return 'PPI::Statement::Variable';
}

=head2 violates

Method to determine if the element currently under scrutiny violates this
policy.  If it does, return a properly constructed C<Perl::Critic::Violation>
object.  Otherwise, return C<undef>.

=cut

sub violates {
    my ($self, $elem, undef) = @_;
    if ($elem->type() eq 'my') {
        if (violates_scalar($elem) || violates_list($elem)) {
            return $self->violation(desc(), expl(), $elem);
        }
    }
    return;
}

=head2 violates_scalar($elem)

Returns true if C<$elem> contains an assignment of the form

    my $foo = undef;

See L<http://search.cpan.org/dist/PPI/lib/PPI/Statement/Variable.pm> for
details on how this function works.

=cut

sub violates_scalar {
    my $elem = shift;
    my @c = $elem->schildren;   # "significant" children

    # e.g. (my $x = undef)
    return unless $c[1]->isa('PPI::Token::Symbol') && $c[1]->raw_type eq q{$};
    return unless $c[2] && $c[2]->isa('PPI::Token::Operator') && $c[2] eq q{=};
    return unless $c[3]->isa('PPI::Token::Word') && $c[3] eq q{undef};
    #return unless $c[4]->isa('PPI::Token::Structure') && $c[4] eq q{;};
    return 1;
}

=head2 violates_list($elem)

Returns true if C<$elem> contains an assignment of the forms:

    my @foo = ();   # useless array init
    my %bar = ();   # useless hash init

=cut

sub violates_list {
    my $elem = shift;
    my @c = $elem->schildren;   # "significant" children
    return unless $c[1]->isa('PPI::Token::Symbol')    && $c[1]->raw_type =~ /^[@%]$/;
    return unless $c[2] && $c[2]->isa('PPI::Token::Operator')  && $c[2] eq q{=};
    return unless $c[3]->isa('PPI::Structure::List')  && $c[3] eq q{()};
    #return unless $c[4]->isa('PPI::Token::Structure') && $c[4] eq q{;};
    return 1;
}

1;
