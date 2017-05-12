package Parse::EBNF::Rule;

use Parse::EBNF::Token;

sub new {
 	my ($class, $rule) = @_;
	my $self = bless {}, $class;
	$self->{error} = 0;

	$self->parse($rule) if defined $rule;

	return $self;
}

sub parse {
	my ($self, $rule) = @_;

	$self->{error} = 0;

	# strip comments
	$rule =~ s!/\*([^\*]|\*[^\/])*\*\/!!g;

	unless ($rule =~ m!^\s*\[(\d+)\]\s*([A-Z][a-zA-Z]*)\s*\:\:=!){

		$self->{error} = "can't parse rule $rule";
		return;
	}

	$self->{index} = $1;
	$self->{name} = $2;

	$rule =~ s!^(.*?)\:\:=!!;

	$self->{rule} = $rule;


	# now try and tokenise the rule
	# we first tokenise it, and *then* split it into alternations,
	# since finding the pipes will be tricky if they occur inside
	# literals or character classes

	my $tokens = [];

	$rule =~ s/^\s+//;

	while($rule){
		my $token = undef;

		if ($rule =~ m!^'([^']+)'!){

			$token = Parse::EBNF::Token->new();
			$token->{content} = $1;
			$token->{type} = 'literal';
			$rule = substr $rule, 2 + length $1;

		}elsif ($rule =~ m!^"([^"]+)"!){

			$token = Parse::EBNF::Token->new();
			$token->{content} = $1;
			$token->{type} = 'literal';
			$rule = substr $rule, 2 + length $1;

		}elsif ($rule =~ m!^\|!){

			$token = Parse::EBNF::Token->new();
			$token->{type} = 'alt';
			$rule = substr $rule, 1;

		}elsif ($rule =~ m!^([A-Z][a-zA-Z]*)!){

			$token = Parse::EBNF::Token->new();
			$token->{content} = $1;
			$token->{type} = 'subrule';
			$rule = substr $rule, length $1;

		}elsif ($rule =~ m!^\[(\^?)(([^\]]|\\\])+)\]!){

			# some sort of class - sub-parse it

			my $neg = $1;
			my $inner = $2;

			$rule = substr $rule, 2 + length($neg) + length($inner);

			my $rx = '['.$neg;
			while(length $inner){

				if ($inner =~ m!^#x([0-9a-f]+)-#x([0-9a-f]+)!i){

					$inner = substr $inner, 5 + length($1) + length($2);
					$rx .= $self->hexchar($1).'-'.$self->hexchar($2);

				}elsif ($inner =~ m!^#x([0-9a-f]+)!i){

					$inner = substr $inner, 2 + length($1);
					$rx .= $self->hexchar($1);

				}elsif ($inner =~ m!^([^-])-([^-])!i){

					$inner = substr $inner, 3;
					$rx .= quotemeta($1).'-'.quotemeta($2);

				}elsif ($inner =~ m!^([^-])!i){

					$inner = substr $inner, 1;
					$rx .= quotemeta($1);

				}else{

					$self->{error} =  "couldn't parse class rx at $inner";
					exit;
				}
			}
			$rx .= ']';

			$token = Parse::EBNF::Token->new();
			$token->{content} = $rx;
			$token->{type} = 'rx';


		}elsif ($rule =~ m!^\[(([^\]]|\\\])+)\]!){

			$token = Parse::EBNF::Token->new();
			$token->{content} = $1;
			$token->{type} = 'class';
			$rule = substr $rule, 2 + length $1;

		}elsif ($rule =~ m!^\*!){

			$token = Parse::EBNF::Token->new();
			$token->{type} = 'rep star';
			$rule = substr $rule, 1;

		}elsif ($rule =~ m!^\+!){

			$token = Parse::EBNF::Token->new();
			$token->{type} = 'rep plus';
			$rule = substr $rule, 1;

		}elsif ($rule =~ m!^\?!){

			$token = Parse::EBNF::Token->new();
			$token->{type} = 'rep quest';
			$rule = substr $rule, 1;

		}elsif ($rule =~ m!^\(!){

			$token = Parse::EBNF::Token->new();
			$token->{type} = 'group start';
			$rule = substr $rule, 1;

		}elsif ($rule =~ m!^\)!){

			$token = Parse::EBNF::Token->new();
			$token->{type} = 'group end';
			$rule = substr $rule, 1;


		}elsif ($rule =~ m!^\-!){

			$token = Parse::EBNF::Token->new();
			$token->{type} = 'dash';
			$rule = substr $rule, 1;

		}elsif ($rule =~ m!^#x([0-9a-f]+)!i){

			$token = Parse::EBNF::Token->new();
			$token->{content} = $self->hexchar($1);
			$token->{type} = 'rx';
			$rule = substr $rule, 2 + length $1;

		}else{

			$self->{error} = "couldn't parse token at start of $rule";
			return;
		}

		push @{$tokens}, $token;

		$rule =~ s/^\s+//;
	}

	#
	# first we create a base token (of type list)
	# which will represent a list of tokens for this rule
	#

	my $base = Parse::EBNF::Token->new();
	$base->{type} = 'list';
	$base->{tokens} = $tokens;
	$self->{base} = $base;


	#
	# now we create a node tree from the flat list
	#

	return unless $self->produce_groups($base);


	#
	# and perform recursive cleanups
	#

	unless ($base->reduce_alternations()){
		$self->{error} = $base->{error};
		return;
	}

	unless ($base->reduce_repetition()){
		$self->{error} = $base->{error};
		return;
	}

	# TODO: negations

	unless ($base->reduce_empty()){
		$self->{error} = $base->{error};
		return;
	}

	unless ($base->reduce_rx()){
		$self->{error} = $base->{error};
		return;
	} 
}

sub hexchar {
	my ($self, $char) = @_;

	$char =~ s!^0+!!;

	if (hex($char) > 255){

		return '\\x{'.lc($char).'}';
	}else{

		return '\\x'.lc($char);
	}
}

sub produce_groups {
	my ($self, $base) = @_;

	my $tokens = $base->{tokens};
	$base->{tokens} = [];
	my $current = $base;

	while(my $token = shift @{$tokens}){

		if ($token->{type} eq 'group start'){

			my $parent = Parse::EBNF::Token->new();
			$parent->{type} = 'list';
			$parent->{parent} = $current;
			$parent->{tokens} = [];

			push @{$current->{tokens}}, $parent;

			$current = $parent;

		}elsif ($token->{type} eq 'group end'){

			$current = $current->{parent};

			if (!defined($current)){
				$self->{error} = "end of group found without matching begin in rule $self->{rule}";
				return 0;
			}

		}else{
			push @{$current->{tokens}}, $token;
		}

	}

	return 1;
}

sub has_error {
	my ($self) = @_;
	return $self->{error} ? 1 : 0;
}

sub error {
	my ($self) = @_;
	return $self->{error} ? $self->{error} : '';
}

sub base_token {
	my ($self) = @_;
	return $self->{base};
}

1;

__END__

=head1 NAME

Parse::EBNF::Rule - An EBNF production rule

=head1 SYNOPSIS

  use Parse::EBNF::Rule;

  my $input = "[1] MyRule ::= 'foo' | 'bar'";


  # parse a rule

  my $rule = Parse::EBNF::Rule->new();
  $rule->parse($input);

  ..OR..

  my $rule = Parse::EBNF::Rule->new($input);


  # check if parsing succeed

  die $rule->error() if $rule->has_error();


  # get the root token for this rule

  my $token = $rule->base_token();


=head1 DESCRIPTION

This module parses a single EBNF production into a tree of Parse::EBNF::Token objects.

=head1 METHODS

=over 4

=item C<new( [$input] )> 

Creates a new rule object, and optionally parses the input.

=item C<parse( $input )>

Parses input into a token tree.

=item C<has_error()>

Returns 1 if an error occured during the last parse, 0 if not.

=item C<error()>

Returns the error string from the last parse failure.

=item C<base_token()>

Returns the root Parse::EBNF::Token object for the rule.

=back

=head1 AUTHOR

Copyright (C) 2005, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<Parse::EBNF>, L<Parse::EBNF::Token>

=cut
