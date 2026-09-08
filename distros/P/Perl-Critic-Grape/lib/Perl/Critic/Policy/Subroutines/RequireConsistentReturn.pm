package Perl::Critic::Policy::Subroutines::RequireConsistentReturn;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/:severities :classification/;
use base 'Perl::Critic::Policy';

our $VERSION = '0.1.0';

Readonly::Scalar my $DESC=>q{Don't use an implicit return in a subroutine with explicit returns.};
Readonly::Scalar my $EXPL=>undef;

Readonly::Hash my %postconditional=>map {$_=>1} qw/for foreach if unless until when while/;
Readonly::Hash my %nonreturning   =>map {$_=>1} qw/while foreach for/;
Readonly::Hash my %terminators    =>map {$_=>1} qw/
	confess
	croak
	die
	exec
	exit
	goto
	return
	throw
	...
/;

#-----------------------------------------------------------------------------

sub supported_parameters {
	return (
		{
			name           => 'bare',
			description    => 'Include bare "return;" statements.',
			default_string => '0',
			behavior       => 'boolean',
		},
	);
}
sub applies_to           { return qw/PPI::Statement/ }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw/cosmetic/ }

#-----------------------------------------------------------------------------

sub invalid {
	my ($self,$elem,$note)=@_;
	$note//='';
	if($note) { $note=" ($note)" }
	return $self->violation(sprintf("%s%s",$DESC,$note),$EXPL,$elem);
}

# Create a subroutine cache inside the policy instance.  While unlikely, this permits
# parallel scans launched by perlcritic, and prevents bleed across scanned documents.
my $cachekey;
sub initialize_if_enabled {
	my ($self,$config)=@_;
	my $name='__REQUIRECRETURN';
	my $suffix=int(rand(1e9));
	my $retry=3;
	while($retry&&exists($$self{"$name$suffix"})) { $suffix=int(rand(1e9)); $retry-- }
	if(exists($$self{"$name$suffix"})) { warn 'RequireConsistentReturn unable to build subroutine cache' }
	else {
		$cachekey="$name$suffix";
		$$self{$cachekey}={cache=>{},recent=>[]};
	}
	return 1;
}

sub hasReturn {
	my ($bare,$block)=@_;
	if($block->find_first(sub {
		my (undef,$e)=@_;
		if($e->isa('PPI::Statement::Sub')) { return undef }
		if($e->isa('PPI::Structure::Block')) {
			my $prev=$e->sprevious_sibling();
			if($prev && $prev->isa('PPI::Token::Word') && ($prev->content() eq 'sub')) { return undef }
			return 0;
		}
		if($e->isa('PPI::Statement::Break')) { return $bare }
		if($e->isa('PPI::Token::Word') && is_function_call($e) && ($e->content() eq 'return')) {
			if($bare) { return 1 }
			my $next=$e->snext_sibling();
			if(!$next) { return 0 }
			if($next->isa('PPI::Token::Structure')&&($next->content() eq ';'))     { return 0 }
			if($next->isa('PPI::Token::Word')&&$postconditional{$next->content()}) { return 0 }
			return 1;
		}
		return 0;
	})) { return 1 }
	return;
}

sub finals {
	my ($block)=@_;
	my @res;
	my $final=($block->schildren())[-1];
	if(!$final) { return }
	if($final->isa('PPI::Statement::Compound')) {
		my $type=$final->type(); # maybe not needed
		if($nonreturning{$type}) { return }
		if($type eq 'continue') {
			my $inner=($final->schildren())[-1];
			if($inner->isa('PPI::Structure::Block')) { return finals($inner) }
			die "RequireConsistentReturn encountered a 'continue' with no inner block";
		}
		return map {finals($_)} grep {$_->isa('PPI::Structure::Block')} $final->schildren();
	}
	return $final;
}

# For each document, build the cache of final statements within the subroutines.
# This ensures that each subroutine is only scanned one time for inside-return statements.
sub prepare_to_scan_document {
	my ($self,$doc)=@_;
	if(!$cachekey) { return 1 }
	$$self{$cachekey}={cache=>{}};
	my ($cache)=@{$$self{$cachekey}}{qw/cache/};
	foreach my $sub (@{ $doc->find('PPI::Statement::Sub')||[] }) {
		my $block=$sub->block();
		if(!$block) { next }
		my $returns=hasReturn($$self{_bare},$block);
		foreach my $final (finals($block)) {
			my $skey=join(',',map {$_//'U'} @{$final->location()});
			$$cache{$skey}={sub=>$sub,returns=>$returns};
		}
	}
	return 1;
}

sub violates {
	my ($self,$elem,undef)=@_;
	if(!$cachekey) { return }
	my $skey=join(',',map {$_//'U'} @{$elem->location()});
	my $cache=$$self{$cachekey}{cache}{$skey};
	if(!$cache)           { return }
	if(!$$cache{returns}) { return }
	if($elem->isa('PPI::Statement::Break'))    { return } # valid
	if($elem->isa('PPI::Statement::Compound')) { return } # ::Critic will pick up the inside statements
	#
	# everything else is an PPI::Statement via applies_to
	my ($first)=$elem->schildren();
	if($first) {
		if($first->isa('PPI::Token::Word')    &&$terminators{$first->content()}) { return }
		if($first->isa('PPI::Token::Operator')&&$terminators{$first->content()}) { return }
	}
	return $self->invalid($elem);
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireConsistentReturn - If a return statement is needed anywhere, all returns should be explicit.

=head1 DESCRIPTION

Require subroutines that return any values to terminate explicitly with one of:  C<confess>, C<croak>, C<die>, C<exec>, C<exit>, C<goto>, C<return>, C<throw>, C<...>.

The final statement of a subroutine establishes a pattern for its use, with no final C<return> interpreted as an 'action', having side effects only.  If the last statement of a subroutine is an expression, however, it is unclear if the intent is only side effects or implicit return (see L<perlsub>).  To establish consistency, any subroutine returning a value anywhere should use an explicit C<return> I<everywhere>.

Note that implicit return is a violation only when an explicit value-return appears in the subroutine.

The following subroutine definitions are all valid (note that the surrounding C<sub name {...}> is exclued for brevity):

  7;                          # implicit return only
  return 7;                   # explicit return is okay
  if($condition) {1} else {2} # both are implicit returns
  if($c) {return 1}; die "!"  # dying is an explicit statement of intent
  my %h=(return=>1); %h;      # hash key is not an early-return statement

By contrast, these are violations:

  if($condition) {return 1}; 5;
  if($condition) {return 1} else {2}
  if($condition) {1} else {return 2}

=head1 CONFIGURATION

By default, a bare C<return;> statement is considered a "block exit" not a value return.  This is not considered a violation:

  if($condition) { return }
  5;

Bare return statements can be interpreted as value returns by setting:

  [Subroutines::RequireConsistentReturn]
  bare = 1

The above example would become a violation and need resolved as:

  if($condition) { return }
  return 5;

=head1 NOTES

According to L<perlsub>, "if the last statement is a loop control structure..., the returned value is unspecified".
This is an explicit programmer choice, such as when the expected return values are declared within the loop, so these are not considered violations.
See L</"SEE ALSO"> to enforce returns after such loops.

=head1 BUGS

Possibly.

=head1 SEE ALSO

L<Subroutines::RequireFinalReturn|Perl::Critic::Policy::Subroutines::RequireFinalReturn> has similar behavior but universally requires a C<return>.  For example, it consider these violations:

  sub aa() { 5 }                  # this won't be inlined if changed to 'return 5'
  sub aa { foreach (1..3) { 1 } } # explicit unspecified return is not ignored

L<Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr>

L<Perl::Critic::Policy::Community::ConditionalImplicitReturn>

L<Perl::Critic::Policy::Community::EmptyReturn>

L<Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt>

L<Perl::Critic::Policy::ProhibitOrReturn>

L<Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef>

L<Perl::Critic::Policy::Subroutines::ProhibitReturnSort>

=cut
