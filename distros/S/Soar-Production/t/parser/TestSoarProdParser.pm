#
# This file is part of Soar-Production
#
# This software is copyright (c) 2012 by Nathan Glenn.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::parser::TestSoarProdParser;
use Test::Base -Base;
use Soar::Production::Parser;

1;

package t::parser::TestSoarProdParser::Filter;
use Test::Base::Filter -base;
use Soar::Production::Parser qw(no_comment);
use Data::Dumper;

my $parser = Soar::Production::Parser->new();

#return the parse of the text
sub parse {
	# print "parse " . $_[0] . "\n";
	$parser->parse_text($_[0]);
}

#return 0 if the parse was unsuccessful, 1 if it was.
sub parse_success {
	return 1 if defined $parser->parse_text($_[0]);
	return 0;
}

#an argument like LHS,stateImpCond,attrValueTests,0 will return
# $root->{LHS}->{stateImpCond}->{attrValueTests}->[0]
sub dive {
	my ($root) = shift @_;
	my @path = split ',', Test::Base::Filter::current_arguments();
	use Data::Diver qw (Dive);
	return Dive($root,@path);
}

#returns the number of productions found in a string
sub split_prods {
	my ($prods) = shift @_;
	my $productions = $parser->productions(text => $prods, parse => 0);
	# print $productions;
	return scalar @$productions;
}

#returns productions found in a string
sub get_prods {
	my ($prods) = shift @_;
	# print 'Getting prods from ' . $prods . "\n";
	my $args = Test::Base::Filter::current_arguments();
	my $productions = $parser->productions(text => $prods, parse => 0);
	# print "found $#$productions productions\n";
	return $productions
		unless defined $args;

	return $$productions[$args];
}

sub remove_comments {
	my ($text) = @_;
	$text = no_comment($text);
	return $text;
}

1;
