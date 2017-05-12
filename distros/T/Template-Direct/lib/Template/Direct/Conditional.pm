package Template::Direct::Conditional;

use base Template::Direct::Base;

use strict;
use warnings;

=head1 NAME

Template::Direct::Conditional - Handle a conditonal in a template

=head1 DESCRIPTION

  Provide support for conditionals in templates

=cut

use Carp;

=head2 I<$class>->new( $index, $line )

  Create a new instance object.

=cut
sub new {
	my ($class, $index, $data) = @_;
	my $self = $class->SUPER::new();
	$self->{'startTag'}    = $index;
	$self->{'conditional'} = $data;
	return $self;
}

=head2 I<$if>->tagName( )

  Returns 'if'

=cut
sub tagName { 'if' }

=head2 I<$if>->subTags( )

  Returns a list of expected sub tags: [else, elif]

=cut
sub subTags {
	{
		'else' => 1,
		'elif' => 1,
	}
}

=head2 I<$if>->conditional( )

  Returns the conditional statement fromt he template.

=cut
sub conditional { $_[0]->{'conditional'} }

=head2 I<$if>->compile( )

  Modifies a template with the data listed correctly.

=cut
sub compile {
	my ($self, $data, $template, %p) = @_;
	return if ref($template) ne 'SCALAR';

	# Do conditional here
	my $section = $self->getFullSection( $template );

	#print "Found Section '$section'\n";
	if($section) {
		my $cnd    = $self->conditional();
		my $result = $section;

		# Make sure we always deal with an else
		if(not $self->hasSubTag('else')) {
			$self->addSubTag('else', 'FAKEELSE', '');
			$result .= '{{TAGFAKEELSE}}';
		}

		# Conditional has content
		foreach (@{$self->allSubTags()}) {
			my ($name, $index, $newcond) = @{$_};
			my ($prime, $second) = split(/\{\{TAG$index\}\}/, $result);
			#print "LOOKING AT $cnd with $prime or $second\n";
			$self->{'condForWarn'} = $cnd;
			my $cond = $self->parseConditional($cnd, $data);
			#warn "Full Conditional: '$cnd' returns '$cond'\n";
			if($cond) {
				$result = $prime;
				last;
			} else {
				$result = $second;
				$cnd    = $newcond;
			}
		}
		$section = $result;
	}

	$self->setSection($template, $section);

	# Prcoess any children (and only children)
	$self->SUPER::compileChildren( $data, $template, %p );
}


=head2 I<$if>->parseConditional($tokenString, $dataStructure)

  Reduce a string conditional into a boolean

=cut
sub parseConditional
{
	my ($self, $string, $data) = @_;
	#Special dispensation for clean else
	return 1 if $string eq 'else';

	#Split into raw tokens
	my @raws = split(/(?<!\\)\s+/, $string);

	#Record all stages
	my @depths;
	my @tokens;
	my $current = Template::Direct::Conditional::Tokens->new(\@tokens);

	foreach my $raw (@raws) {
		if($raw =~ s/^\(//) {
			# New level
			$current->append(Template::Direct::Conditional::Tokens->new());
			push @depths, $current if $current;
			$current = $current->lastItem();
		} elsif($raw =~ s/^\{//) {
			# Static Array
			my $array = Template::Direct::Conditional::Array->new();
			$current->append($array);
			push @depths, $current if $current;
			$current = $array;
		}

		if(ref($current) eq 'Template::Direct::Conditional::Array') {
			my $end = 1 if $raw =~ s/\}$//;
			push @{$current}, $raw;
			$current = pop @depths if $end and @depths;
		} else {
			if($raw eq 'and' or $raw eq 'or') {
				# Logical Statements are treated later.
				$current->append(\$raw);
			} else {
				# Add sane tokens only, remove all unexpected charicters.
				my $sane = $raw;
				$sane =~ s/[^\w\$_\{\}\<\>\|\&\=\!\@]//g;
	
				# Get datum if required, replace this token with real value
				if($sane =~ /^\$(.+)$/) {
					$sane = $data->getDatum($1);
				}
				if(UNIVERSAL::isa($sane, 'ARRAY') and not UNIVERSAL::isa($sane, 'HASH')) {
					$sane = Template::Direct::Conditional::Array->new( $sane );
				}

				# Push this token onto the current stack.
				$current->append($sane) if defined($sane) and scalar($sane.'') ne '';

				if($raw =~ /\)$/) {
					$current = pop @depths if @depths;
				}
			}
		}
	}

	return $self->parseLogical(\@tokens);
}


=head2 I<$if>->parseLogical( $tokens )

    Take tokens and group logical statements by and/or

=cut
sub parseLogical
{
	my ($self, $tokens) = @_;
	my @tokens;

	my @stack;
	for my $token ($tokens->iterator()) {
		if(ref($token) eq 'SCALAR') {
			warn "Variable or operand to logically compare: ".$self->{'condForWarn'} if @stack == 0;
			push @tokens, Template::Direct::Conditional::Tokens->new( [ @stack ] ), ${$token};
			@stack = ();
		} elsif(ref($token) eq 'Template::Direct::Conditional::Tokens') {
			# Processes and logicals in brackets
			push @stack, $self->parseLogical( $token );
		} else {
			# Push each static variable or operand to the stack.
			push @stack, $token;
		}
	}

	warn "Expected variables or operands in conditional: ".$self->{'condForWarn'} if @stack == 0 and @tokens != 0;
	push @tokens, ((@tokens == 0) ? @stack : Template::Direct::Conditional::Tokens->new( \@stack ));

	return Template::Direct::Conditional::Tokens->new(\@tokens)->execute($self->{'startTag'});
}


package Template::Direct::Conditional::Tokens;

use strict;
use Carp;

=head1 NAME

Template::Direct::Conditional::Tokens - Handle a list of conditional tokens

=head1 METHODS

=head2 I<$class>->new( $list )

  Return a list of tokens object.

=cut
sub new {
    my ($class, $list) = @_;
    $list = [] if not defined $list;
    return bless $list, $class;
}

=head2 I<$tokens>->executeConditional( $conditional )

    suck in triples and output booleans

=cut
sub execute
{
	my ($self, $cond) = @_;
	my @t = $self->iterator();

	#warn "Tokens: ".join(', ', @t)."\n";

	# Single comparisons
	return undef if @t == 0;
	return $t[0] if @t == 1;
	
	my $true = 1;
	my $false = 0;

	if($t[0] eq 'not') {
		return not $t[1] ? $true : $false if @t == 2;
		shift @t; # Remove not token
		$true  = 0;
		$false = 1;
	}

	# And / Or comparisons
	my $a = shift @t;
	$a = not shift @t if $a and $a eq 'not';
	my $o = shift @t;
	warn "Operator not found in conditional: ".join(' ', @{$self})."\n" if not $o;
	my $b = shift @t;
	$b = not shift(@t) if $b and $b eq 'not';

	$a = $a->execute($cond) if ref($a) eq 'Template::Direct::Conditional::Tokens';
	$b = $b->execute($cond) if ref($b) eq 'Template::Direct::Conditional::Tokens';

	#print $cond." Found: $a $o $b\n"; # if $o eq 'in';

	# Arathmetic Logic
	unshift @t, ($a  >  $b) if $o eq '>';
	unshift @t, ($a  <  $b) if $o eq '<';
	unshift @t, ($a  >= $b) if $o eq '>=';
	unshift @t, ($a  <= $b) if $o eq '<=';

	# Bitwise Logic
	unshift @t, ($a  |  $b) if $o eq '|';
	unshift @t, ($a  &  $b) if $o eq '&';

	# Logical Conditionals
	unshift @t, ($a and $b) ? $true : $false if $o eq 'and';
	unshift @t, ($a or  $b) ? $true : $false if $o eq 'or';
	unshift @t, ($a eq  $b) ? $true : $false if $o eq '=' or $o eq 'eq';
	unshift @t, ($a ne  $b) ? $true : $false if $o eq '!=' or $o eq 'ne';

	if($o eq "in") {
		if(ref($b) eq "Template::Direct::Conditional::Array") {
			# Array Conditional (python kidnaped!)
			unshift @t, $b->in($a) ? $true : $false;
		} else {
			croak "Invalid array used in conditional $a in $b";
		}
	}

	# Order of magnatude
	unshift @t, (($a % $b) == 0) ? $true : $false if $o eq '@';
 
	if(@t == 1) {
		return $t[0];
	} else {
		Template::Direct::Conditional::Tokens->new(\@t)->execute() ? $true : $false;
	}
}

=head2 I<$tokens>->append( $item )

  Add a token to this token list.

=cut
sub append {
	my ($self, $item) = @_;
	push @{$self}, $item;
}

=head2 I<$tokens>->lastItem( )

  Return the last item from this token list.

=cut
sub lastItem {
	my ($self) = @_;
	return $self->[$#{$self}];
}

=head2 I<$tokens>->iterator( )

  Return the token list as an array.

=cut
sub iterator { return @{$_[0]}; }



package Template::Direct::Conditional::Array;

use strict;
use Carp;

=head1 NAME

Template::Direct::Conditional::Array - Handle arrays in conditionals

=head1 METHODS

=cut

use overload
	"''" => sub { shift->count() },
	"eq" => sub { shift->count() eq shift },
	"ne" => sub { shift->count() ne shift },
	">"  => sub { shift->count() > shift },
	"<"  => sub { shift->count() < shift },
	"<=" => sub { shift->count() <= shift },
	">=" => sub { shift->count() >= shift },
	'bool' => sub { shift->count() > 0 },;

=head2 I<$class>->new( $list )

  Return an array object.

=cut
sub new {
    my ($class, $list) = @_;
    $list = [] if not defined $list;
    return bless \@{$list}, $class;
}

=head2 I<$array>->in( $var )

  Return true if var is in this array.

=cut
sub in {
	my ($self, $var) = @_;
    for my $i (@{$self}) {
        return 1 if $i eq $var;
    }
    return 0;
}

=head1 OVERLOADED

  All the kinds of overloading this object has on it.

=cut
sub count { scalar(@{ $_[0] }) }

=head1 AUTHOR

  Martin Owens - Copyright 2007, AGPL

=cut
1;
