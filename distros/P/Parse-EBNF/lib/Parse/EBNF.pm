package Parse::EBNF;

use strict;
use Parse::EBNF::Rule;

our $VERSION = 1.04;

sub new {
	my ($class) = @_;
	my $self = bless {}, $class;
	$self->{verbose} = 0;
	$self->{rules} = {};
	return $self;
}

sub parse_lines {
	my ($self, $lines) = @_;

	#
	# split into rules
	#

	my @rules;
	my $current;
	while(my $line = shift @{$lines}){
		if ($line =~ /^\s*\[\d+\]/){
			push @rules, $current;
			$current = '';
		}
		$line =~ s![\r\n\t]! !g;
		$line =~ s!\s{2,}! !g;
		$current .= $line;
	}
	push @rules, $current;


	#
	# create rules
	#

	for my $rule(@rules){
		if (defined($rule)){
			my $rule_obj = Parse::EBNF::Rule->new($rule);
			$self->{rules}->{$rule_obj->{name}} = $rule_obj;
		}
	}
}

sub rules {
	my ($self) = @_;
	return $self->{rules};
}

sub dump_rule {
	my ($self, $rule) = @_;

	unless ( defined $self->{rules}->{$rule} ){

		print "rule $rule not found\n";

	}else{

		use Data::Dumper;

		my $obj = $self->{rules}->{$rule};

		my $d = Data::Dumper->new([$obj]);

		print $d->Dump();
	}
}

sub dump_rules {
	my ($self) = @_;

	use Data::Dumper;

	my $d = Data::Dumper->new([$self->{rules}]);

	print $d->Dump();
}

1;

__END__

=head1 NAME

Parse::EBNF - Parse W3C-Style EBNF Grammars

=head1 SYNOPSIS

  use Parse::EBNF;

  my $parser = Parse::EBNF->new();


  # parse lines into rules
  $parser->parse_lines(\@lines);


  # fetch all compiled rules
  my $rules = $parser->rules();


  # print all rules using Data::Dumper
  $parser->dump_rules();


  # print a named rule using Data::Dumper
  $parser->dump_rule('MyProductionName');


=head1 DESCRIPTION

This module takes W3C-Style EBNF Grammar rules and converts them into an array
of Parse::EBNF::Rule objects, which contain token trees. These trees are then
trivial to convert into other grammar formats (like P:RD).

=head1 METHODS

=over 4

=item C<new()>

Creates a new parser.

=item C<parse_lines( $arrayref )>

Parses a number of rule lines.

=item C<rules()>

Returns a hashref of Parse::EBNF::Rule objects.

=item C<dump_rules()>

Prints a Data::Dumper view of all compiled rules.

=item C<dump_rule( $rule_name )>

Prints a Data::Dumper view of a single named rule.

=back

=head1 BUGS

Multiline comments aren't handled correctly.
Production negation isn't implemented.
Only W3C style numbered rules are parsed (This could be easily fixed).

=head1 AUTHOR

Copyright (C) 2005, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<Parse::EBNF::Rule>, L<Parse::EBNF::Token>

=cut
