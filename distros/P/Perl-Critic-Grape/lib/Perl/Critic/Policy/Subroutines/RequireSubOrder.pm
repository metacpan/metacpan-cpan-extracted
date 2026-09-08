package Perl::Critic::Policy::Subroutines::RequireSubOrder;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw/:severities :classification/;
use base 'Perl::Critic::Policy';

our $VERSION = '0.1.0';

Readonly::Scalar my $DESC  => q{Place subroutines in dependency order};
Readonly::Scalar my $EXPL  => undef;

#-----------------------------------------------------------------------------

sub supported_parameters {
	return (
		{
			name           => 'all',
			description    => 'Report all names a subroutine must appear after.',
			default_string => '0',
			behavior       => 'boolean',
		},
		{
			name           => 'backwards',
			description    => 'Expect dependencies to follow their callers.',
			default_string => '0',
			behavior       => 'boolean',
		},
	);
}

sub applies_to           { return qw/PPI::Statement::Sub/ }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw/cosmetic/ }

#-----------------------------------------------------------------------------

sub invalid {
	my ($self,$elem,$note)=@_;
	$note//='';
	if($note) { $note=" ($note)" }
	return $self->violation(sprintf("%s%s",$DESC,$note),$EXPL,$elem);
}

sub _loc { my ($node)=@_; return join(' ',map {$_//'U'} @{$node->location()}) }

sub _blockcalls {
	my ($self,$package,$doc)=@_;
	if(!$doc) { return }
	my %res;
	foreach my $word (grep {is_function_call($_)&&!is_perl_builtin($_)} @{$doc->find('PPI::Token::Word')||[]}) {
		my $name=$word->content();
		if($name=~/^(.*)::([^:]+)$/) {
			if($1 eq $package) { $res{$2}=undef }
		}
		elsif($name!~/::/) { $res{$name}=undef }
	}
	return keys(%res);
}

# The Perl compiler fully scans the document for subroutine names, permitting out-of-order
# dependencies, so it's necessary here to fully map all subroutine names, and their packages, to
# determine if dependencies are declared within the document.  Anything encountered but not
# declared is imported, via 'use' or 'do', and assumed declared prior to use.  If the author
# calls 'do' too late, that's a runtime error not detected here.  Likewise, anonymous subs are
# ignored since standard variable scoping controls their availability.

my $cachekey;
sub initialize_if_enabled {
	my ($self,$config)=@_;
	my $name='__REQUIRESUBORDER__';
	my $suffix=int(rand(1e9));
	my $retry=3;
	while($retry&&exists($$self{"$name$suffix"})) { $suffix=int(rand(1e9)); $retry-- }
	if(exists($$self{"$name$suffix"})) { warn 'RequireSubOrder unable to build subroutine cache' }
	else {
		$cachekey="$name$suffix";
		$$self{$cachekey}={cache=>{},recent=>[]};
	}
	return 1;
}

sub builder {
	my ($self,$doc,$package)=@_;
	$package//='main';
	foreach my $node ($doc->children()) {
		if($node->isa('PPI::Statement::Package')) {
			if(my $block=$node->find_first('PPI::Structure::Block')) { $self->builder($block,$node->namespace()) }
			else { $package=$node->namespace() }
		}
		elsif($node->isa('PPI::Statement::Sub')) {
			my $loc=_loc($node);
			$$self{$cachekey}{sub}{$node->name()}//={};
			my $csub=$$self{$cachekey}{sub}{$node->name()};
			if(exists($$csub{$loc})) { warn "A declaration of subroutine @{[$node->name()]} has already been encountered at this location" }
			$$csub{$loc}={
				package=>$package,
				node=>$node,
				name=>$node->name(),
				loc=>$node->location(),
				calls=>[$self->_blockcalls($package,$node->block())],
			};
			$$self{$cachekey}{package}{$package}{$node->name()}{$loc}=$$csub{$loc};
		}
		elsif($node->isa('PPI::Statement::Compound')||$node->isa('PPI::Structure::Block')) { $self->builder($node,$package) }
		elsif($node->isa('PPI::Statement')) {
			$$self{$cachekey}{outer}{"${package}::"}//={package=>$package,node=>$doc,calls=>{}};
			my $calls=$$self{$cachekey}{outer}{"${package}::"}{calls};
			foreach my $call ($self->_blockcalls($package,$node)) { push @{$$calls{$call}},{loc=>$node->location(),call=>$call} }
		}
		# else do nothing
	}
	return 1;
}

sub prepare_to_scan_document {
	my ($self,$doc,$package)=@_;
	if(!$cachekey) { return 0 }
	%{$$self{$cachekey}}=();
	return $self->builder($doc,$package);
}

sub _cmploc {
	my ($X,$Y)=@_;
	if($$X[0]<$$Y[0]) { return -1 }
	if($$X[0]>$$Y[0]) { return +1 }
	if($$X[1]<$$Y[1]) { return -1 }
	if($$X[1]>$$Y[1]) { return +1 }
	return 0;
}

sub _sortloc {
	my (@items)=@_;
	return sort {_cmploc($$a{loc},$$b{loc})} @items;
}

sub _depends {
	my ($self,$pkg,$name,$dep)=@_;
	foreach my $definition (values %{$$self{$cachekey}{package}{$pkg}{$name}}) {
		foreach my $name (@{$$definition{calls}}) {
			if($name eq $dep) { return 1 }
		}
	}
	return 0;
}

sub violates {
	my ($self,$elem,undef)=@_;
	my $sub=$$self{$cachekey}{sub}{$elem->name()}{_loc($elem)};
	if(!$sub) { return }
	#
	my @dependencies;
	foreach my $dep (@{$$sub{calls}}) {
		my @deps=_sortloc(values(%{$$self{$cachekey}{package}{$$sub{package}}{$dep}}));
		if(@deps) {
			if   ( $$self{_backwards} && (_cmploc($deps[-1]{loc},$elem->location())<0)){ push @dependencies,$deps[0] }
			elsif(!$$self{_backwards} && (_cmploc($deps[0]{loc}, $elem->location())>0)){ push @dependencies,$deps[-1] }
		}
	}
	if(@dependencies) {
		@dependencies=map {+{cyclic=>($self->_depends(@$_{qw/package name/},$$sub{name})?' (cyclic)':''),
			package=>$$_{package},name=>$$_{name}}} _sortloc(@dependencies);
		if(!$$self{_all}) { @dependencies=$dependencies[-1] }
		@dependencies=join(q{, },map {sprintf("'%s::%s'%s",@$_{qw/package name cyclic/})} @dependencies);
		if($$self{_backwards}) { return $self->invalid($elem,sprintf("move %s after '%s::%s'",$dependencies[0],$$sub{package},$elem->name())) }
		else                   { return $self->invalid($elem,sprintf("move '%s::%s' after %s",$$sub{package},$elem->name(),$dependencies[0])) }
	}
	#
	@dependencies=();
	if(defined($$self{$cachekey}{outer}{"$$sub{package}::"})) {
		my @deps=_sortloc(@{$$self{$cachekey}{outer}{"$$sub{package}::"}{calls}{$$sub{name}}});
		if(@deps) {
			if   ( $$self{_backwards}&&(_cmploc($deps[-1]{loc},$elem->location())>0)) { push @dependencies,$deps[-1] }
			elsif(!$$self{_backwards}&&(_cmploc($deps[0]{loc}, $elem->location())<0))  { push @dependencies,$deps[0] }
		}
		if(@dependencies) {
			@dependencies=_sortloc(@dependencies);
			if($$self{_backwards}) { return $self->invalid($elem,sprintf("move '%s::%s' after caller on line %d",@$sub{qw/package name/},$dependencies[-1]{loc}[0])) }
			else                   { return $self->invalid($elem,sprintf("move '%s::%s' before caller on line %d",@$sub{qw/package name/},$dependencies[0]{loc}[0])) }
		}
	}
	return;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::RequireSubOrder - Place subroutines in dependency order

=head1 DESCRIPTION

Subroutine dependencies are easier to manage when they are defined before they are called.  By organizing subroutines with the lower-level helpers appearing first (at the top), and the calling subroutines after (at the bottom), the code will be easier to understand and maintain.  This follows the common pattern of indicating module and helper imports first:

  use Helpers qw/some functions/;
  sub one { return some()+functions() }
  sub two { return one() }
  ... script that calls two()
  exit();

The reverse order, referred to here as I<backwards>, does function because Perl's compile step can (usually) find the subroutine definitions:

  ... script that calls two()
  exit();
  sub two { return one() }
  sub one { return some()+functions() }
  use Helpers qw/some functions/;

The inside-out order may, therefore, be the most confusing but is commonly encountered:

  use Helpers qw/some functions/;
  ... script that calls two()
  exit();
  sub two { return one() }
  sub one { return some()+functions() }

This policy enforces the first form, similar to a topological sort, with dependency groups appearing first and their calling subroutines appearing later.

=head2 Motivation

=head3 State and Globals

A common pattern is to declare an outer C<my> variable as a file or package-level state variable that adheres to the subroutine(s) where it's used:

  my $value=1;
  sub one { return $value }

  sub main { return one() }

  print main(),"\n";
  exit();

Suppose, however, that the "main program" is given priority at the top of the script:

  print main(),"\n";
  exit();

  my $value=1;
  sub one { return $value }

  sub main { return one() }

This compiles but gives a runtime warning, "Use of uninitialized value".  C<RequireSubOrder> will report that these subroutines (eg C<main>) need to be moved before their callers.

Note that in scripts with large support functions, related failures can be difficult to identify when not following the packages-dependencies-script pattern.

=head3 Optional parentheses

As noted in L<perlsub>, parentheses are optional "if predeclared/imported".  This works:

  sub one { return $_[0]+$_[1] }
  sub two { return one 2,3 }

This does not, however:

  sub two { return one 2,3 }
  sub one { return $_[0]+$_[1] }

As noted in L<perldiag>, the compiler can guess the intent and suggests "Do you need to predeclare one?", but the issue may depend on a missing import instead of a declaration or definition.  C<RequireSubOrder> catches this issue early by insisting on the first form.

=head3 Prototypes

Subroutine calls can enforce declared prototypes:

  sub one($$) { return $_[0]+$_[1] }
  sub two { return one(2,3,4) }

  -> Too many arguments for main::one

Backwards declaration cannot, however:

  sub two { return one(2,3,4) }
  sub one($$) { return $_[0]+$_[1] }
  print two(),"\n";

  -> 5

=head3 Inlining

Declared subroutines may be inlined:

  sub one() {1}
  sub two { return one() }
  print two(),"\n"

This may be inspected with L<B::Deparse>:

  sub one () {
    1;
  }
  sub two {
    return 1;
  }
  print two(), "\n";

With backwards definitions:

  sub two { return one() }
  sub one() {1}
  print two(),"\n"

The code still runs and prints "1", but it is not inlined:

  sub two {
    return &one();
  }
  print two(), "\n";
  sub one () { 1 }

=head2 Supported behaviors

* Supports forward declarations.

* Supports inline C<package Pkg; ...; package main; ...> declarations.

* Supports C<{package Pkg; ...}> declarations inside blocks.

* Supports C<package Pkg {...}> block declarations.

* Supports package-prefixed calls.

* Reports cycles.

* Reports definition-after-use in scripts.

* Ignores undeclared functions, which are assumed to be imported.

=head1 CONFIGURATION

=head2 All dependencies

By default, only the latest dependency is given for a misplaced subroutine to appear after.  To report all names a subroutine must appear after:

  [Subroutines::RequireSubOrder]
  all = 1

=head2 Backwards ordering

The default ordering is topological for the reasons provided above.  To instead apply a model where "all the dependent calls made by the subroutine appear I<after>", with the expectation that "I shall responsibly forward declare all functions+prototypes":

  [Subroutines::RequireSubOrder]
  backwards = 1

=head2 Todo

* Consider sorting of C<_private> versus C<public> names.

* Consider alphabetical ordering within the same group.

=head1 BUGS

* Obviously!

* Lexical subroutines may misreport.  Needs investigation.

=cut
