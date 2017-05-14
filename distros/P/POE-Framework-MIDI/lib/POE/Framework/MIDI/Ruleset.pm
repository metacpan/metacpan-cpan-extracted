# $Id: Ruleset.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Ruleset;
use strict;
use vars qw($VERSION); $VERSION = '0.02';
use base 'POE::Framework::MIDI::Rule';
use POE::Framework::MIDI::Rule;

# no support for partially matching rules yet...
sub test {
    my ($self, $thing_to_test) = @_
        or die __PACKAGE__ . '::test() needs something to test, and rule to test against';

    # We should probably start using bar and phrase objects (??)
    # otherwise this could test a bar against a phrase-based
    # ruleset.
    #
    # Eventually this should also be extended to allow for partially
    # matching rules.
    my $matches_all;

# Commented-out just to show the code below.
#    for ( @{$self->{cfg}->{rules}} ) {
#        my $res = $_->test($thing_to_test);
#        $matches_all = $res == 1 ? 1 : undef;
#    }
#    return $matches_all;

    # How about a simple average of the running tally of individual
    # rule matchings, where a rule test returns 1 for full 100%
    # match, zero for no match at all, and some decimal for partial.
    my $average = 0;
    my @matches = ();

    # Sum and keep track of the individual rule matchings.
    for (@{ $self->{cfg}{rules} }) {
        my $res = $_->test($thing_to_test);
        push @matches, $res;
        $average += $res;
    }

    # Average the combined rule matchings if there are any.
    $average /= @{ $self->{cfg}{rules} }
        if @{ $self->{cfg}{rules} };

    # Return the average number of matches in a scalar context,
    # and the actual rule matches in array context.
        return wantarray ? @matches : $average;
}

sub rules {
	my $self = shift;
	wantarray ? return @{$self->{cfg}->{rules}} : return $self->{cfg}->{rules};
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Ruleset - Contain nested rules, or other
nested rulesets

=head1 ABSTRACT

=head1 DESCRIPTION

A Ruleset matches if all of its sub-Rules (or Rulesets) match, fails 
if any of its sub-Rules (or Rulesets) fail, and partially matches to 
some decimal value between 0 and 1.

=head1 SYNOPSIS

=head1 PUBLIC METHODS

=head2 test()

=head1 TO DO

Extend the test() subroutine to allow for rules that only partially 
match.

Do we need some context enforcement here?  Mixed context could be a 
pain.

=head1 SEE ALSO

L<POE>

L<POE::Framework::MIDI::Rule>

L<http://justsomeguy.com/code/POE/POE-Framework-MIDI>

=head1 AUTHOR

Primary: Steve McNabb E<lt>steve@justsomeguy.comE<gt>

CPAN ID: SMCNABB

Secondary: Gene Boggs E<lt>cpan@ology.netE<gt>

CPAN ID: GENE

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2002 Steve McNabb. All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file 
included with this module.

=cut
