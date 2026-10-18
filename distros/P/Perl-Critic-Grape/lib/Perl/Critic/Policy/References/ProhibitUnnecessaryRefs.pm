package Perl::Critic::Policy::References::ProhibitUnnecessaryRefs;

use 5.010001;
use strict;
use warnings;
use Readonly;
use Scalar::Util qw/refaddr/;

use Perl::Critic::Utils qw/:severities :classification/;
use base 'Perl::Critic::Policy';

our $VERSION = '0.1.3';

Readonly::Scalar my $DESC=>q{Use Perl basic types.};
Readonly::Scalar my $EXPL=>undef;

sub supported_parameters {
	return (
		{
			name           => 'self',
			description    => 'Report instances of $self.',
			default_string => '0',
			behavior       => 'boolean',
		},
	);
}

sub applies_to           { return qw/PPI::Statement::Variable PPI::Token::Operator/ }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw/cosmetic/ }

# When a subscript is encountered, what is it's sigiled type?
my %subscriptToType=(
	'[]'=>'@',
	'{}'=>'%',
	'()'=>'&',
);

# For these sigils, any subscript must be checked.
# EG $$var[] versus $$var{}
# EG @$var[] versus @$var{}
my %subscriptTypes=map {$_=>1} ('$','@');

# The following operators are considered when tracking variable assignments
my %assignmentOperator=map {$_=>1} qw{ = &&= ||= //= };

# Create a randomly-named cache inside the policy instance.
my $cachekey;
sub initialize_if_enabled {
	my ($self,$config)=@_;
	my $name='__PROHIBITUNNEEDEDREF';
	my $suffix=int(rand(1e9));
	my $retry=3;
	while($retry&&exists($$self{"$name$suffix"})) { $suffix=int(rand(1e9)); $retry-- }
	if(exists($$self{"$name$suffix"})) { warn 'RequireConsistentReturn unable to build subroutine cache' }
	else { $cachekey="$name$suffix" }
	return 1;
}

sub initCache {
	my ($self)=@_;
	if(!$cachekey) { return }
	$$self{$cachekey}={ # Note that all stacks are push/pop based, so [-1] is the top of the stack
		pending=>{
			# 'lockey'=>[{type=>'stmt var', ...}, ...]
		},
		scope=>[
			# node (Document, Statement::Block, ...)
		],
		scopes=>{
			# 'lockey of scope node'=>1 # present if we're still within self-or-descendant of that scope node
		},
		symbol=>{
			# "$symbol"=>[
			# 	{key=>"lockey $symbol", scope=>'lockey of scope node at declaration'}
			# ]
		},
		var=>{
			# 'lockey $symbol'=>{
			# 	usage=>{
			# 		'x'=>1, for x=$@%&*
			# 	}
			# 	...
			# 	decl=>{node=>node} # maybe not needed, unsure
			# }
		},
	};
}

sub fetchCache {
	my ($self)=@_;
	return %{$$self{$cachekey}//{}};
}

sub lockey { my ($node)=@_; return join(q{ },map {$_//'u'} @{$node->location()//[]}) }
sub symkey { my ($node,$symbol)=@_; return sprintf('%s %s',lockey($node),$symbol) }

sub handlePending {
	my ($self,%event)=@_;
	if($event{type} eq 'recordAssignment') { $self->recordAssignment(@event{qw/node symbol exempt/}) }
	return $self;
}

# Consider the statement node S for "$x=f(x)".
# The LHS node("$x") has parent=S, which means the scoping action to be performed occurs when S is entered (not when "$x" is left).
# This only happens when there's no next sibling, so there's no pending processing for non-terminal nodes.
# When the top of document is reached, there is no parent and the step returns undefined.
sub step {
 	my ($self,$node)=@_;
 	my $res;
 	if($node->isa('PPI::Node')&&($res=$node->schild(0))) { return $res }
 	if($node->isa('PPI::Element')) {
		my ($parent,$snext)=($node,$node->snext_sibling());
		while($parent&&!$snext) {
			$parent=$parent->parent();
			$snext=$parent?$parent->snext_sibling():undef;
			if($parent) {
				my $loc=lockey($parent);
				if(my $things=delete($$self{$cachekey}{pending}{$loc})) {
				foreach my $thing (@$things) {
					$self->handlePending(%$thing)
				} }
				while(!$$self{$cachekey}{scope}[-1]->ancestor_of($snext?$snext:$parent)) {
					my $locscope=lockey($$self{$cachekey}{scope}[-1]);
					foreach my $varscopes (values %{$$self{$cachekey}{symbol}}) {
						while(($#$varscopes>-1)&&($locscope eq $$varscopes[-1]{scope})) {
							pop(@$varscopes) } }
					delete($$self{$cachekey}{scopes}{lockey($$self{$cachekey}{scope}[-1])});
					pop @{$$self{$cachekey}{scope}};
				}
			}
		}
		if($parent) { return $snext }
		return;
 	}
	return;
}

# If the $node is a basic casting operator, return
# {
# 	type  =>one of $@%&*
# 	symbol=>'$var',
# 	node  =>$varnode,
# 	next  =>$aftervarnode, # after the var, possibly a subscript
# }
#
#	$$var
#	@$var
#	%$var
#	*$var
#	&$var
#	${$var}
#	@{$var}
#	%{$var}
#	*{$var}
#	&{$var}
#	$$var[idx]
#	@$var[idxs]
#	$$var{key}
#	@$var{keys}
#	%$var{keys}
#	${$var}[idx]
#	@{$var}[idxs]
#	${$var}{key}
#	@{$var}{keys}
#	%{$var}{keys}
#	*$globref{THING}
#	*{$globref}{THING}
#
sub isBasicCast {
	my ($node)=@_;
	if(!$node) { return }
	if(!$node->isa('PPI::Token::Cast')) { return }
	my $sigil=$node->content();
	if($sigil eq '\\') { return }
	my $next=$node->snext_sibling();
	if(!$next) { warn('Found casting operator applied to nothing'); return }
	if($next->isa('PPI::Token::Symbol')) {
		my $nnext=$next->snext_sibling();
		my $type=$sigil;
		my $symbol=$next->symbol();
		if($subscriptTypes{$sigil}&&$nnext&&$nnext->isa('PPI::Structure::Subscript')) { $type=$subscriptToType{$nnext->braces()}//'?' }
		if($sigil eq '*') { $symbol=$next->content() }
		return (type=>$type,symbol=>$symbol,node=>$next,next=>$nnext);
	}
	elsif($next->isa('PPI::Structure::Block')) {
		my @children=$next->schildren();
		if($#children>0) { return } # this is a non-simple/evaluative block
		my $nnext=$children[0];
		if(!$nnext->isa('PPI::Statement')) { return } # type guard
		@children=$nnext->schildren();
		if($#children>0) { return } # this is a compound etc.
		my $nnnext=$children[0];
		if($nnnext->isa('PPI::Token::Symbol')) {
			my $subnext=$next->snext_sibling();
			my $type=$sigil;
			if($subscriptTypes{$sigil}&&$subnext) {
				if($subnext->isa('PPI::Structure::Subscript'))   { $type=$subscriptToType{$subnext->braces()}//'?' }
				if($subnext->isa('PPI::Structure::Constructor')) { $type=$subscriptToType{$subnext->braces()}//'?' } # PPI bug?
			}
			return (type=>$type,
			symbol=>$nnnext->symbol(),
			node=>$nnnext,
			next=>$subnext,
			);
		}
		return;
	}
	else {
		return;
	}
}

# If the $node dereferences a scalar variable, return
# {
# 	type  =>one of $@%&*
# 	symbol=>'$var',
# 	node  =>$varnode,
# 	next  =>$aftervarnode,
# }
#
sub isSubscriptedSymbol {
	my ($node)=@_;
	if(!$node)                            { return }
	if(!$node->isa('PPI::Token::Symbol')) { return }
	my ($next,$prev)=($node->snext_sibling(),$node->sprevious_sibling());
	if($next&&$next->isa('PPI::Token::Operator')&&($next->content() eq '->')) {
		my $symbol=$node->symbol();
		my $nnext=$next->snext_sibling();
		# The returned 'next' node is the '->' arrow, because step() will move onward to the subscript itself, which needs to be separately checked for usages
 		if($nnext->isa('PPI::Structure::Subscript')) { return (type=>$subscriptToType{$nnext->braces()},symbol=>$symbol,node=>$node,next=>$next) }
		elsif($nnext->isa('PPI::Structure::List')) { return (type=>'&',symbol=>$symbol,node=>$node,next=>$next) }
		elsif($nnext->isa('PPI::Token::Word')) { return (type=>'B',symbol=>$symbol,node=>$node,next=>$next) }
		elsif($nnext->isa('PPI::Token::Cast')) { return; warn("Post-deref not yet supported") } # backwards=silence
	}
	# isBasicCast already performed a precheck for casting
	#
	# A PPI::Token::Symbol that is not resolvable with the above logic is not a "subscripted symbol" for the sake of this check.
	# For example, it may be the LHS of an assignment so the type cannot be established until usage.
	return;
}

sub recordUsage {
	my ($self,%data)=@_;
	my $cache=$$self{$cachekey};
	$$cache{symbol}{$data{symbol}}//=[];
	@{$$cache{symbol}{$data{symbol}}} || 
	push @{$$cache{symbol}{$data{symbol}}}, {
		key=>symkey($data{node},$data{symbol}),
		scope=>lockey($$cache{scope}[-1]) };
	my $symkey=$$cache{symbol}{$data{symbol}}[-1]{key};
	$$cache{var}{$symkey}//={};
	$$cache{var}{$symkey}{usage}{$data{type}}=1;
	return $self;
}

# node is the location of the assignment operator
# symbol is the Token::Symbol that is assigned
sub recordAssignment {
	my ($self,$node,$symbol,$exempt)=@_;
	my $cache=$$self{$cachekey};
	$$cache{symbol}{$symbol->content()}//=[];
	my $C=$$cache{symbol}{$symbol->content()};
	my $symkey=symkey($node,$symbol->content());
	push @$C,{key=>$symkey,scope=>lockey($$cache{scope}[-1])};
	my $type=$symbol->symbol_type();
	if($type ne '$') { $$cache{var}{$symkey}{usage}{$type}=1 }
	if($exempt)      { $$cache{var}{$symkey}{exempt}=1 }
	return $self;
}

# Find all bare scalar symbols on the left of a known assignment node.
sub assignedVariables {
	my ($self,$node)=@_;
	my $parent=$node->parent();
	if(!$parent) { return }
	my @res;
	$parent->find(sub {
		my (undef,$e)=@_;
		my ($p,$n)=($e->sprevious_sibling(),$e->snext_sibling());
		if($n&&$n->isa('PPI::Structure::Subscript')) { return 0 }
		if($p&&$p->isa('PPI::Token::Cast'))          { return 0 }
		if($e->isa('PPI::Token::Symbol')&&($e->symbol_type() eq '$')) { push @res,$e; return 1 }
		elsif($e->isa('PPI::Token::Operator')&&(refaddr($e)==refaddr($node))) { die 'done searching' }
		elsif($e->isa('PPI::Token::Operator')&&$assignmentOperator{$e->content()}) {
			# refaddr(e)!=refaddr(node)
			# This is an assignment to the left of our assignment, and should have been captured using assignedVariables(e).
			@res=();
		}
		return 0;
	});
	return @res;
}

sub analyze {
	my ($self,$doc)=@_;
	my $node=$doc;
	if(!$node->isa('PPI::Node')) { die "Unable to analyze node ($node)" }
	while($node) {
		if(my %cast=isBasicCast($node)) { $self->recordUsage(%cast); $node=$cast{next}||$cast{node} }
		elsif(my %subscript=isSubscriptedSymbol($node)) { $self->recordUsage(%subscript); $node=$subscript{next}||$subscript{node} }
		elsif($node->isa('PPI::Structure::Block')||$node->isa('PPI::Statement::Compound')) {
			push @{$$self{$cachekey}{scope}},$node;
			$$self{$cachekey}{scopes}{lockey($node)}=1;
		}
		elsif($node->isa('PPI::Statement::Variable')) {
			foreach my $symbol (grep {'$' eq $_->symbol_type()} $node->symbols()) {
				my %exempt; if(($symbol eq '$self')&&!$$self{_self}) { %exempt=(exempt=>1) }
				push @{$$self{$cachekey}{pending}{lockey($node)}},{type=>'recordAssignment',node=>$node,symbol=>$symbol,%exempt};
			}
			if(my $assign=$node->find_first(sub {
				my (undef,$e)=@_;
				if(!$e->isa('PPI::Token::Operator')) { return 0 }
				if($e->content() eq '=')             { return 1 }
				return 0;
			}))  { $node=$assign }
			else { $node=$node->last_element()||$node }
		}
		elsif($node->isa('PPI::Token::Operator')&&$assignmentOperator{$node->content()}) {
			foreach my $symbol ($self->assignedVariables($node)) {
				my %exempt; if(($symbol eq '$self')&&!$$self{_self}) { %exempt=(exempt=>1) }
				push @{$$self{$cachekey}{pending}{lockey($node->parent())}},{type=>'recordAssignment',node=>$node,symbol=>$symbol,%exempt};
			}
		}
		$node=$self->step($node);
	}
	return $self;
}

sub prepare_to_scan_document {
	my ($self,$doc)=@_;
	if(!$cachekey) { return 1 }
	$self->initCache();
	push @{$$self{$cachekey}{scope}},$doc;
	$$self{$cachekey}{scopes}{lockey($doc)}=1;
	$self->analyze($doc);
	return 1;
}

sub symbolUsageViolates {
	my (%var)=@_;
	if($var{exempt}) { return }
	my ($sum,$sumah)=(0,0);
	while(my ($k,$v)=each %{$var{usage}//{}}) {
		if($v) { $sum++ }
		if(($k eq '@')||($k eq '%')) { $sumah++ }
		else { return }
	}
	return ($sumah==1);
}

sub invalid {
	my ($self,$elem,$note)=@_;
	$note//='';
	if($note) { $note=" ($note)" }
	return $self->violation(sprintf("%s%s",$DESC,$note),$EXPL,$elem);
}

sub violates {
	my ($self,$elem,undef)=@_;
	if(!$cachekey) { return }
	if($elem->isa('PPI::Token::Operator') && !$assignmentOperator{$elem->content()}) { return }
	my %violations;
	my @vars;
	if($elem->isa('PPI::Statement::Variable')) { @vars=$elem->variables() }
	else                                       { @vars=$self->assignedVariables($elem) }
	foreach my $var (@vars) {
		if(my $v=symkey($elem,$var)) {
			if(symbolUsageViolates(%{$$self{$cachekey}{var}{$v}//{}})) {
				$violations{$var}=undef } } }
	if(!%violations) { return }
	return $self->invalid($elem,join(',',sort keys(%violations)));
	return;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::References::ProhibitUnnecessaryRefs - Use basic arrays and hashes.

=head1 DESCRIPTION

Perl arrays and hashes should be declared using the built-in basic data types, and functions should return basic arrays and hashes where possible.  Each basic array or hash can be passed by reference after assignment.  Scalar variables should only be used for scalar values (numbers/strings/versions), or for blessed objects.

  $scalar   =foo();    # yes
  $array[5] =foo();    # yes
  $hash{key}=foo();    # yes
  @array               # yes
  %hash                # yes
  $obj->method()       # yes
  &$coderef(...);      # yes
  *$globref{...}       # yes

  $$aref[5]   =foo();  # no
  $aref->[5]  =foo();  # no
  @$arrayref           # no
  $$href{key} =foo();  # no
  $href->{key}=foo();  # no
  %$hashref            # no

Violations occur for any declared, assigned, or auto-vivified variable, including declarations within conditional/loop statements.

Note that violations are tied to the I<scope> of the variable's declaration and usage, so a clear object reference with method calls in one scope may be a violation in another scope where it's only used as e.g. a hash.  

=head1 CONFIGURATION

=head2 Self

By default, the C<$self> variable is exempt from violations.  To enable violations for C<$self>:

  [References::ProhibitUnnecessaryRefs]
  self = 1

=head1 VIOLATIONS

Violations to this policy occur when a scalar variable (of the form C<$var>) has been assigned and the variable:

* is never cast to a non-array/hash, eg C<&$var>; and

* is never used in a method call, eg C<$var-E<gt>method()>; and

* the only non-scalar usage of the variable within its scope is as an array reference or hash reference (but not both).

=head2 Violation location

Variable usage is associated with the point of assignment to that variable.  Typically this occurs at declaration but, since variables may be reused, includes all individual assignments.  Only scalar variables, C<$var>, are considered, since any C<@array> or C<%hash> is already a plain data type.  If a variable is never declared, its first usage (see below) will be considered its point of assignment.

Note that a variable assignment may have a location I<prior> to a usage of that variable.  Because assignment occurs right-to-left, RHS evaluation may refer to a previous version of the variable despite having a later location than the LHS assignment.  For example, C<$x=f($x)> uses a version of C<$x> that exists when the expression is evaluated, but the LHS C<$x> may have changed type.

=head2 Usage details

I<Every> usage of scalar variables is considered, so a single variable may have multiple, different typed usages (such as in a class with override support).  Usage types that are tracked include:

* any casting operator, C<x$var> or C<x{$var}>, for any possible C<x> (such as C<*$var> or C<%$var>).

* any subscript, C<$$var{k}>, C<$var->[i]>, or C<$var->()>, for example.

Usage inside quotes with interpolation is not currently considered; eg C<"foo $$x{key} bar"> will not be detected.

Any detected usage is associated with the variable's violation location as described above.  That is, usage is associated with a declared variable of that name currently in scope.

For variables that are not declared, the first usage will be considered the point of assignment, but this only applies to the usage types described here.  For example, calling C<$x++> is never considered in determining type, so that statement by itself will never be the fallback point of assignment.

Usage of the form C<$x>, C<@x>, or C<%x>, is never considered since those are associated with the plain variable C<x>.

=head2 Scope mechanisms

This subsection contains technical details, but briefly:  Reused declared variable names inside a block do not affect the usage information outside that block.

The scope is tracked for all blocks as a stack so usage can be associated with the variable currently in scope, if any.  When the PPI document is walked, a C<step()> may encounter a last/leaf/terminal node and need to exit through the C<parent()>.  Exit through a block pops the scope-stack and any associated variable scope.  Moreover, since a C<step()> may proceed through several C<parent()> calls, the scope-stack may pop multiple times.

Note that the currently active scope can still have multiple assignment locations (potential violations) per variable.

Package statements don't matter because C<my> variables outside a block are still file scoped, as in C<package P; my $x; package main;>.  Package statements using curly braces, either C<{package P;...}> or C<package P {...}> have a surrounding block scope that houses any C<my> variables.

=head2 Assignment notes

During assignment, RHS evaluation must precede the actual assignment, so the LHS is not considered the new scope for those variables until after the RHS has been analyzed.  In particular, the LHS is deferred (from an analysis perspective) until the overall expression completes.

Chained assignment operations are also supported, such as with C<@B=($x,$y)=(f(),g())> .  Please note that PPI does not currently consider C<my @B=my ($x,$y)=(1,2)> to be two separate variable statements, as it only reports the second C<my> as a plain built-in.  (This is likely a bug in PPI)

=head1 Analysis Overview

The document is fully analyzed during the preparation step, so that any critic violations are determined based entirely on the assignment location and (forward-looking) usages per analyzed variable.  During initial analysis, it's necessary to identify and track:

* any pending statements, such as an assignment LHS

* the stack of nodes that establishes the current variable scope, either a PPI::Document or a Statement::Block

* for each C<$symbol>, a I<stack> of the key, which is the violation location for the symbol, and the scope, which is the location of the active scope node during symbol declaration

* and thus, a set of all active scopes, keyed by the locations of those scopes

* and finally, for each violation location and symbol (pair), the usage types associated with the symbol.

=head1 BUGS

=head2 Postfix dereference

Postfix dereferencing is not currently detected properly and will not cause a violation.

=head2 Refaliasing

The behavior of refaliasing is unknown (in this version of the policy).  Ideally refaliasing would solve the "pass by reference and immediately unpack" violations, but a separate configuration may be added in the future to support that pattern.  Note that individual unpacking can provide C<no critic> statements.

=head2 Multitype scalars

Incorrectly regarded as a bug.  Suppose a reference is returned into a scalar but the type may vary; a common pattern is:

  if(is_arrayref($thing)) { ... @$thing }
  if(is_hashref ($thing)) { ... %$thing }

Instead, this policy recommends returning proper "records" with appropriately-named identifiers with clearly defined shapes.  For example:

  my %R=get(...); # results
  if   ($R{authors}) { @authors=@{$R{authors}} }
  elsif($R{book})    { @authors=map {$$_{author}} values %{$R{book}} }

=head2 Mutation

Incorrectly regarded as a bug.  Reference assignments are often shorthand for objects to be mutated:

  my $H=$$self{thing};
  $$H{key}=f('key', ...);

Typically such code is much larger, hence the inclination toward abbreviations, however most cases are actually functional blocks of code.  Data goes in, something is computed, and the output data is reassigned:

  $$self{thing}{key}=update('key', ...);

For example, a common pattern is a loop:

  my %things=%{ $$self{thing} }; # shallow copy, fast
  foreach my $k (...) {
		$$self{thing}{$k}=update($things{$k});
  }

As larger chunks of code evolve more helpers and data shaping functions, the original abbreviations will be found lacking.  If there are actual shorthand reference variables, however, this policy recommends that they should be explicitly noted for mutation:

  my $things=$$self{thing};  ## no critic (UnnecessaryRefs):  Variable is mutated

=cut
