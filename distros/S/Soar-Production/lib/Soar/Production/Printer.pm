#
# This file is part of Soar-Production
#
# This software is copyright (c) 2012 by Nathan Glenn.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Soar::Production::Printer;
# ABSTRACT: Print Soar productions
use strict;
use warnings;

our $VERSION = '0.03'; # VERSION

use Soar::Production::Parser;
use Carp;
use Exporter::Easy (
	OK => [qw(tree_to_text)]
);

#default behavior is to read the input Soar file and output another one; worthless except for testing
_run(shift) unless caller;

#pass in a Soar grammar file name. Parse the file, then reconstruct it and print to STDOUT.
sub _run {
	my ($file) = @_;

    my $parser = Soar::Production::Parser->new();
    my $trees   = $parser->productions(file => $file, parse => 1);
    croak "parse failure\n" if ( $#$trees == -1 );

    my $text = tree_to_text($$trees[0]);
	my $tree = $parser->parse_text($text)
		or croak 'illegal production printed';

	print $text;
	return;
}

sub tree_to_text{
	my ($tree) = @_;

    #traverse tree and construct the Soar production text
    my $text = 'sp {';

    $text .= _name( $tree->{name} );
    $text .= _doc( $tree->{doc} );
    $text .= _flags( $tree->{flags} );

    $text .= _LHS( $tree->{LHS} );
	$text .= "\n-->\n\t";
    $text .= _RHS( $tree->{RHS} );
	$text .= "\n}";

	return $text;
}

sub _name {
	my $name = shift;
	return $name . "\n\t";;
}

sub _doc {
	my $doc = shift;
	if(defined $doc){
		return '"' . $doc . '"' . "\n\t";
	}
	return '';
}

sub _flags {
	my $flags = shift;
	my $text = '';
	for my $flag (@$flags){
		$text .= ':' . $flag . "\n\t";
	}
	return $text;
}

sub _LHS {
	my $LHS = shift;
	return join "\n\t",
		map { _condition($_) } @{ $LHS->{conditions} };
}

sub _condition {
	my $condition = shift;
	my $text = '';

	$text .= '-'
		if($condition->{negative} eq 'yes');

	$text .= _positive_condition( $condition->{condition} );

	return $text;
}

sub _positive_condition {
	my $condition = shift;

	return _conjunction( $condition->{conjunction} )
		if($condition->{conjunction});

	return _condsForOneId($condition);
}

sub _condsForOneId {
	my $condsForOneId = shift;
	my $text = '(';
	my ($type, $idTest, $attrValueTests) =
		(
			$condsForOneId->{condType},
			$condsForOneId->{idTest},
			$condsForOneId->{attrValueTests}
		);

	$text .= $type
		if(defined $type);

	$text .= ' ' . _test($idTest)
		if(defined $idTest);

	if($#$attrValueTests != -1){
		$text .= ' ';
		$text .= join ' ', map { _attrValueTests($_) } @$attrValueTests;
	}

	$text .= ')';
	return $text;
}

sub _test {
	my $test = shift;

	if(exists $test->{conjunctiveTest}){
		return _conjunctiveTest(
			$test->{conjunctiveTest} );
	}

	return _simpleTest( $test->{simpleTest} );
}

sub _conjunctiveTest {
	my $conjTest = shift;
	my $text = '{';
	$text .= join ' ',
		map { _simpleTest($_) } @$conjTest;
	$text .= '}';
	return $text;
}

sub _simpleTest {
	my $test = shift;
	return _disjunctionTest($test->{disjunctionTest})
		if( exists $test->{disjunctionTest} );
	return _relationalTest($test->{relationTest} )
		if( exists $test->{relationTest} );
	return _singleTest($test);
}

sub _disjunctionTest {
	my $test = shift;
	my $text = '<< ';
	$text .= join ' ', map { _constant($_) } @$test;
	$text .= ' >>';
	return $text;
}

sub _relationalTest {
	my $test = shift;

	my $text = _relation( $test->{relation} );
	$text .= ' ';
	$text .= _singleTest( $test->{test} );

	return $text;
}

sub _relation {
	my $relation = shift;
	return $relation;
}

sub _singleTest {
	my $test = shift;
	return _variable($test->{variable})
		if( exists $test->{variable} );
	return _constant($test);
}

sub _attrValueTests {
	my $attrValuetests = shift;
	my ($negative, $attrs, $values) =
		(
			$attrValuetests->{negative},
			$attrValuetests->{attrs},
			$attrValuetests->{values}
		);
	my $text = '';
	$text .= '-'
		if($negative eq 'yes');
	$text .= _attTest($attrs);

	if($#$values != -1){
		$text .= ' ';
		$text .= join ' ', map { _valueTest($_) } @$values;
	}
	return $text;
}

sub _attTest {
	my $attTest = shift;
	my $text = '^';
	$text .= join '.', map { _test($_) } @$attTest;
	return $text;
}

sub _valueTest {
	my $valueTest = shift;
	my $text = '';

	if(exists $valueTest->{test}){
		$text = _test( $valueTest->{test} );
	}else{
		#condsForOneId
		$text = _condsForOneId($valueTest->{conds});
	}

	$text .= '+'
		if($valueTest->{'+'} eq 'yes');

	return $text
}

sub _conjunction {
	my $conjunction = shift;
	my $text = '{';
	$text .= join "\n\t", map { _condition($_) } @$conjunction;
	$text .= '}';
	return $text;
}

sub _RHS {
	my $RHS = shift;
	my $text = '';
	for my $action (@$RHS){
		$text .= _action($action);
		$text .= "\n\t";
	}
	return $text;
}

sub _action {
	my $action = shift;
	if(exists $action->{funcCall}){
		return _funcCall($action->{funcCall});
	}

	my $text = '(';
	$text .= _variable($action->{variable});
	$text .= ' ';
	$text .= join ' ',
		map {_attrValueMake($_)} @{ $action->{attrValueMake} };
	$text .= ')';
	return $text;
}

sub _attrValueMake {
	my $attrValueMake = shift;
	my ($attr, $valueMake) =
		($attrValueMake->{attr}, $attrValueMake->{valueMake});

	my $text = _attr($$attr[0]);
	if($#$attr != 0){
		$text .= '.';
		$text .= join '.',
			map { _variableOrSymConstant($_) } @$attr[1..$#$attr];
	}

	$text .= ' ';
	$text .= join ' ', map{_valueMake($_)} @$valueMake;

	return $text;
}

sub _attr {
	my $attr = shift;
	return '^' . _variableOrSymConstant($attr);
}

sub _variableOrSymConstant {
	my $vOs = shift;
	return _variable($vOs->{variable})
		if(exists $vOs->{variable});
	return _symConstant($vOs);

}

sub _valueMake {
	my $valueMake = shift;
	my ($rhsValue, $preferences) =
		($valueMake->{rhsValue}, $valueMake->{preferences});
	my $text = _rhsValue($rhsValue);
	#there will always be at least one preference; '+' is default
	$text .= ' ';
	$text .= join ',', map { _preference($_) } @$preferences;
	return $text;
}

sub _preference {
	my $preference = shift;
	my $text = $preference->{value};
	if($preference->{type} eq 'binary'){
		$text .= ' ' . _rhsValue( $preference->{compareTo} );
	}
	return $text;
}

#variable | constant | "(crlf)" | funcCall
sub _rhsValue {
	my $rhsValue = shift;

	return '(crlf)'
		if($rhsValue eq '(crlf)');

	if(exists $rhsValue->{variable}){
		return _variable($rhsValue->{variable});
	}
	if(exists $rhsValue->{constant}){
		return _constant($rhsValue);
	}
	if(exists $rhsValue->{function}){
		return _funcCall($rhsValue);
	}
	return $rhsValue;
}

#(write |Hello World| |hello again|)
sub _funcCall {
	my $funcCall = shift;

	my ($name, $args) =
		(_funcName($funcCall->{function}), $funcCall->{args});
	my $text = '(' . $name;
	if($#$args != -1){
		$text .= ' ';
		$text .= join ' ', map {_rhsValue($_)} @$args;
	}
	return $text . ')';
}

# arithmetic operator (+ - * /) or a symConstant, being the name of some function
sub _funcName {
	my $funcName = shift;

	if(ref $funcName eq 'HASH'){
		return _symConstant($funcName);
	}
	return $funcName;
}

sub _variable {
	my $variable = shift;
	return '<' . $variable . '>'
}

sub _constant {
	my $constant = shift;
	my ($type, $value) = ($constant->{type}, $constant->{constant});

	return _symConstant($value) if($type eq 'sym');
	return _int($value) if($type eq 'int');
	return _float($value);#only other type is 'float'
}

sub _float {
	my $float = shift;
	return $float;
}

sub _int {
	my $int = shift;
	return $int;
}

#either string or quoted
sub _symConstant {
	my $symConstant = shift;
	my ($type, $value) = ($symConstant->{type}, $symConstant->{value});
	return _string($value) if($type eq 'string');
	return _quoted($value);
}

sub _string {
	return shift;
}

sub _quoted {
	my $text = shift;

	#escape vertical bars
	$text =~ s/\|/\\|/g;
	return '|' . $text . '|';
}

1;

__END__

=pod

=head1 NAME

Soar::Production::Printer - Print Soar productions

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Soar::Production::Parser;
  use Soar::Production::Printer qw(tree_to_text);

  #read in a series of productions from a file
  my $parser = Soar::Production::Parser->new;
  my @trees=$parser->parse_file("foo.soar");

  #print each of the productions to standard out
  for my $prod(@trees){
	print tree_to_text($prod);
  }

=head1 DESCRIPTION

This module can be used to print production parse trees produced by Soar::Production::parser. Use the function C<tree_to_text> to accomplish this.

Printing is accomplished by traversing the input structure exactly as it is specified by the grammar used by Soar::Production::Parser.

=head1 NAME

Soar::Production::pRINT - Perl extension for printing Soar productions

=head1 EXPORTED FUNCTIONS

The following may be exported to the caller's namespace.

=head2 C<tree_to_text>

Argument: parse tree structured as those returned by Soar::Production::Parser.
Returns a text representation of the production which can be sourced by Soar.

=head2 TODO

Pretty printing is not yet possible, which is too bad because it means the output can be pretty disgusting looking.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nathan Glenn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
