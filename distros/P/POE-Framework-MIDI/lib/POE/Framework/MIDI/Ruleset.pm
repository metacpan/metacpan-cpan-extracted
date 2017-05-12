# $Id: Ruleset.pm,v 1.2 2002/09/17 21:14:01 ology Exp $

# POE::Framework::MIDI::Ruleset - rulesets contain nested rules, or other nested rulesets

package POE::Framework::MIDI::Ruleset;
use strict;
use POE::Framework::MIDI::Rule;
use vars qw/@ISA/;
use constant VERSION => 0.1.1;

@ISA = qw(POE::Framework::MIDI::Rule);

# no support for partially matching rules yet...
sub test
{
	my($self,$thing_to_test) = @_
    or die __PACKAGE__. "test() needs something to test, and rule to test against";
	# we should probably start using bar and phrase objects (??) otherwise this could test a bar against a phrase-based
	# ruleset....
	#
	# eventually this should also be extended to allow for partially matching rules..
  my $matches_all;

# gb- Commented-out just to show the code below.
#
#	for(@{$self->{cfg}->{rules}})
#	{
#		my $res = $_->test($thing_to_test);
#		if($res == 1) 
#		{ $matches_all = 1 }
#		else 
#		{ $matches_all = undef }			
#	}
#	return $matches_all;

  # How about a simple average of the running tally of individual rule matchings,
  # where a rule test returns 1 for full 100% match, zero for no match at all,
  # and some decimal for partial.
	my $average = 0;
  my @matches = ();

  # Sum and keep track of the individual rule matchings.
  for (@{$self->{cfg}->{rules}}) {
    my $res = $_->test($thing_to_test);
    push @matches, $res;
    $average += $res;
  }

  # Average the combined rule matchings if there are any.
  $average /= @{$self->{cfg}->{rules}}
    if @{$self->{cfg}->{rules}};

  # Return the average number of matches in a scalar context,
  # and the actual rule matches in array context.
	return wantarray ? @matches : $average;
}

1;

=head1 NAME

POE::Framework::MIDI::Ruleset

=head1 DESCRIPTION

A Ruleset matches if all of its sub-Rules(or Rulesets) match, fails if any of 
its sub-Rules(or Rulesets) fail, and partially matches to some decimal value 
between 0 and 1 

=head1 USAGE

=head1 TODO

- extend the test() subroutine to allow for rules that only partially match
- do we need some context enforcement here? mixed context could be a pain

=head1 AUTHOR

	Steve McNabb
	CPAN ID: JUSTSOMEGUY
	steve@justsomeguy.com
	http://justsomeguy.com/code/POE/POE-Framework-MIDI 

=head1 COPYRIGHT

Copyright (c) 2002 Steve McNabb. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1). POE.  Perl-MIDI

=cut
