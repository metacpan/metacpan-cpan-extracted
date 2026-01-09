package Perl::Critic::Policy::References::ProhibitRefChecks;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/:severities :classification precedence_of/;
use base 'Perl::Critic::Policy';

our $VERSION = '0.0.6';

Readonly::Scalar my $DESC  => q{Do not perform manual ref checks};
Readonly::Scalar my $EXPL  => undef; # [ ];
Readonly::Scalar my $UPREC => precedence_of('-e'); # named unary function precedence

####-----------------------------------------------------------------------------

sub supported_parameters {
	return (
		{
			name           => 'eq',
			description    => 'Reference types that may be checked via string equality.',
			default_string => '',
			behavior       => 'string list',
		},
		{
			name           => 'ne',
			description    => 'Reference types that may be checked via string inequality.',
			default_string => '',
			behavior       => 'string list',
		},
		{
			name           => 'regexp',
			description    => 'Permit regular expression comparisons.',
			default_string => '0',
			behavior       => 'boolean',
		},
		{
			name           => 'bareref',
			description    => 'Permit a bare if(ref) style check.',
			default_string => '0',
			behavior       => 'boolean',
		},
	);
}

sub applies_to           { return 'PPI::Token::Word' }
sub default_severity     { return $SEVERITY_MEDIUM   }
sub default_themes       { return qw/cosmetic maintenance performance/ }

#-----------------------------------------------------------------------------

sub invalid {
	my ($self,$elem,$note)=@_;
	$note//='';
	if($note) { $note=" ($note)" }
	return $self->violation(sprintf("%s%s",$DESC,$note),$EXPL,$elem);
}

sub eqne {
	my ($node)=@_;
	if(!$node) { return }
	if(!$node->isa('PPI::Token::Operator')) { return }
	my $op=$node->content();
	if(($op eq 'eq')||($op eq 'ne')) { return 1 }
	return;
}

sub decompose {
	my ($elem)=@_;
	my %operator=map {$_=>undef} (qw/eq ne !~ =~ cmp/);
	my ($node,$operator,$rhs)=($elem,undef,undef);
	while($node) {
		if($node->isa('PPI::Token::Operator') && exists($operator{$node->content()})) {
			$operator=$node->content();
			$rhs=$node->snext_sibling();
			$node=0;
		}
		elsif($node->isa('PPI::Token::Operator') && (precedence_of($node)>$UPREC)) { $node=0 }
		else { $node=$node->snext_sibling() }
	}
	if(!$rhs) { return ($operator) }
	if($rhs->isa('PPI::Token::Quote')) { return ($operator,lc($rhs->string())) }
	if($rhs->isa('PPI::Token::Word') && ($rhs->content() eq 'ref')) { return ($operator,'ref') }
	return ($operator,$rhs->content());
}

sub violates {
	my ($self,$elem,undef)=@_;
	if(!$elem->isa('PPI::Token::Word')) { return }
	if(!is_perl_builtin($elem))         { return }
	if(!is_function_call($elem))        { return }
	if($elem->content() ne 'ref')       { return }

	# Already handled.
	# No support for ('quoted' eq ref($x)) at this time.
	if(eqne($elem->sprevious_sibling())){ return }

	$$self{_eq}     //={};
	$$self{_ne}     //={};
	$$self{_regexp} //=0;
	$$self{_bareref}//=0;

	# Without options, 'ref' should never be called.
	if(!%{$$self{_eq}} && !%{$$self{_ne}} && !$$self{_regexp} && !$$self{_bareref}) { return $self->invalid($elem) }

	my ($operator,$rhs)=decompose($elem);

	if(!$operator) {
		if(!$$self{_bareref}) { return $self->invalid($elem,'bare ref check') }
		return;
	}
	elsif($operator eq 'eq') {
		$$self{_eqfold}//={map {lc($_)=>undef} keys(%{$$self{_eq}//{}})};
		if(!exists($$self{_eqfold}{$rhs})) { return $self->invalid($elem,$rhs) }
		return;
	}
	elsif($operator eq 'ne') {
		$$self{_nefold}//={map {lc($_)=>undef} keys(%{$$self{_ne}//{}})};
		if(!exists($$self{_nefold}{$rhs})) { return $self->invalid($elem,$rhs) }
		return;
	}
	elsif(($operator eq '=~')||($operator eq '!~')) {
		if(!$$self{_regexp}) { return $self->invalid($elem,$rhs) }
		return;
	}
	else {
		return $self->invalid($elem,$rhs);
	}
	return;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::References::ProhibitRefChecks - Write C<is_arrayref($var)> instead of C<ref($var) eq 'ARRAY'>.

=head1 DESCRIPTION

Checking references manually is less efficient that using L<Ref::Util> and prone to typos.

	if(ref($var) eq 'ARRYA') # oops!
	if(is_arrayref($var))    # ok

	if(ref($var) ne 'HASH')  # no
	if(!is_hashref($var))    # ok

	if(ref($var))            # no
	if(is_ref($var))         # ok

=head1 CONFIGURATION

Explicit strings may be permitted for checks of the form C<ref(...) eq 'string'>, or C<ref(...) ne 'string'>.  Entries are case insensitive and can be the core types or custom modules.

	[References::ProhibitRefChecks]
	eq = code
	ne = code my::module

As a special scenario, checks of the form C<ref(...) eq ref(...)> can be permitted with C<eq = ref>.  The same works for C<ne = ref>.

Regular expression matches are violations by default.  To permit checks of the form C<ref(...) =~ /pattern/> or C<!~>:

	[References::ProhibitRefChecks]
	regexp = 1

Since L<Ref::Util> provides C<is_ref>, in the default configuration the bare C<ref> call is rarely needed.  To specifically permit using direct C<ref(...)> calls:

	[References::ProhibitRefChecks]
	bareref = 1

=head1 NOTES

Comparisons to stored values or constants are not supported:  C<ref(...) eq $thing> and C<ref(...) eq HASH()> are violations.

Lexicographic comparison via C<ref(...) cmp "string"> is a violation.

In/equality checks are not bidirectional:  C<'HASH' eq ref(...)> will not be considered a violation.

=head1 BUGS

Named unary functions are not separately considered.  A call of C<lc(ref $x) eq "array"> is considered a "bare ref check", whereas C<lc ref($x) eq "array"> is considered an "eq ref check".

=cut
