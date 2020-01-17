use 5.014;
use strict;
use warnings;
use B ();
use Carp ();
use Import::Into ();
use MooX::Press ();
use MooX::Press::Keywords ();

package MooX::Pression;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use Keyword::Declare;
use B::Hooks::EndOfScope;
use Exporter::Shiny our @EXPORT = qw( version authority );

BEGIN {
	package MooX::Pression::_Gather;
	my %gather;
	my %stack;
	sub import {
		my ($me, $action, $caller) = (shift, shift, scalar caller);
		if ($action eq -gather) {
			while (@_) {
				my ($k, $v) = splice @_, 0, 2;
				if (my ($kind,$pkg) = ($k =~ /^(class|role|class_generator|role_generator):(.+)$/)) {
					if ( my @stack = @{ $stack{$me}{$caller}||[] } ) {
						pop @stack if $stack[-1] eq $pkg;
						if (@stack) {
							$v->{_stack} = \@stack;
							$kind = '_defer_'.$kind;
						}
					}
					push @{ $gather{$me}{$caller}{$kind}||=[] }, $pkg, $v;
				}
				else {
					$gather{$me}{$caller}{$k} = $v;
				}
			}
		}
		elsif ($action eq -go) {
			if ($gather{$me}{$caller}{'_defer_role'}) {
				die 'nested roles not currently supported';
			}
			if ($gather{$me}{$caller}{'_defer_role_generator'}) {
				die 'nested role generators not currently supported';
			}
			if ($gather{$me}{$caller}{'_defer_class_generator'}) {
				die 'nested class generators not currently supported';
			}
			if ($gather{$me}{$caller}{'_defer_class'}) {
				$me->_undefer_classes($gather{$me}{$caller}{'class'}, delete $gather{$me}{$caller}{'_defer_class'});
			}
			
			if ($gather{$me}{$caller}{debug}) {
				require Data::Dumper;
				warn Data::Dumper::Dumper($gather{$me}{$caller});
			}
			
			@_ = ('MooX::Press' => $gather{$me}{$caller});
			goto \&MooX::Press::import;
		}
		elsif ($action eq -parent) {
			push @{ $stack{$me}{$caller}||=[] }, $_[0];
		}
		elsif ($action eq -unparent) {
			pop @{ $stack{$me}{$caller} };
		}
		else {
			die;
		}
	}
	sub _undefer_classes {
		my ($me, $classes, $d) = @_;
		my %class_hash = @$classes;
		my @deferred;
		my $max_depth = 0;
		while (@$d) {
			my ($class, $spec) = splice(@$d, 0, 2);
			$spec->{_class_name} = $class;
			$spec->{_depth}      = @{ $spec->{_stack} };
			push @deferred, $spec;
			$max_depth = $spec->{_depth} if $spec->{_depth} > $max_depth;
		}
		DEPTH: for my $depth (1 .. $max_depth) {
			SPEC: for my $spec (@deferred) {
				next SPEC unless $spec->{_depth} == $depth;
				my $parent_key = join('|', @{$spec->{_stack}});
				my $my_key     = join('|', @{$spec->{_stack}}, $spec->{_class_name});
				push @{ $class_hash{$parent_key}{subclass} ||=[] }, $spec->{_class_name}, $spec;
				$class_hash{$my_key} = $spec;
			}
		}
		for my $spec (@deferred) {
			delete $spec->{_stack};
			delete $spec->{_class_name};
			delete $spec->{_depth};
		}
	}
	
	$INC{'MooX/Pression/_Gather.pm'} = __FILE__;
};

#
# HELPERS
#

keytype SignatureList is /
	(
		(?&PerlBlock) | ([^\W0-9]\S*)
	)?
	\s*
	(
		(?&PerlVariable) | (\*(?&PerlIdentifier))
	)
	(
		\? | (\s*=\s*(?&PerlTerm))
	)?
	(
		\s*
		,
		\s*
		(
			(?&PerlBlock) | ([^\W0-9]\S*)
		)?
		\s*
		(
			(?&PerlVariable) | (\*(?&PerlIdentifier))
		)
		(
			\? | (\s*=\s*(?&PerlTerm))
		)?
	)*
/xs;  # fix for highlighting /

my $handle_signature_list = sub {
	my $sig = $_[0];
	my $seen_named = 0;
	my $seen_pos   = 0;
	my @parsed;
	
	while ($sig) {
		$sig =~ s/^\s+//xs;
		last if !$sig;
		
		push @parsed, {};
		
		if ($sig =~ /^((?&PerlBlock)) $PPR::GRAMMAR/xso) {
			my $type = $1;
			$parsed[-1]{type}          = $type;
			$parsed[-1]{type_is_block} = 1;
			$sig =~ s/^\Q$type//xs;
			$sig =~ s/^\s+//xs;
		}
		elsif ($sig =~ /^([^\W0-9]\S*)/) {
			my $type = $1;
			$parsed[-1]{type}          = $type;
			$parsed[-1]{type_is_block} = 0;
			$sig =~ s/^\Q$type//xs;
			$sig =~ s/^\s+//xs;
		}
		else {
			$parsed[-1]{type} = 'Any';
			$parsed[-1]{type_is_block} = 0;
		}
		
		if ($sig =~ /^\*((?&PerlIdentifier)) $PPR::GRAMMAR/xso) {
			my $name = $1;
			$parsed[-1]{name} = $name;
			++$seen_named;
			$sig =~ s/^\*\Q$name//xs;
			$sig =~ s/^\s+//xs;
		}
		elsif ($sig =~ /^((?&PerlVariable)) $PPR::GRAMMAR/xso) {
			my $name = $1;
			$parsed[-1]{name} = $name;
			++$seen_pos;
			$sig =~ s/^\Q$name//xs;
			$sig =~ s/^\s+//xs;
		}
		
		if ($sig =~ /^\?/) {
			$parsed[-1]{optional} = 1;
			$sig =~ s/^\?\s*//xs;
		}
		elsif ($sig =~ /^=\s*((?&PerlTerm)) $PPR::GRAMMAR/xso) {
			my $default = $1;
			$parsed[-1]{default} = $default;
			$sig =~ s/^=\s*\Q$default//xs;
			$sig =~ s/^\s+//xs;
		}
		
		if ($sig) {
			$sig =~ /^,/ or die "WEIRD SIGNATURE??? $sig";
			$sig =~ s/,\s*//xs;
		}
	}
	
	my @signature_var_list;
	my $type_params_stuff = '[';
	
	require B;
	die "cannot mix named and positional (yet?)" if $seen_pos && $seen_named;

	while (my $p = shift @parsed) {
		push @signature_var_list, $p->{name};
		$type_params_stuff .= B::perlstring($p->{name}) . ',' if $seen_named;
		if (@parsed and $p->{name} =~ /^[\@\%]/) {
			die "Cannot have slurpy in non-final position";
		}
		if ($p->{type_is_block}) {
			$type_params_stuff .= sprintf('scalar(do %s)', $p->{type}) . ',';
		}
		else {
			$type_params_stuff .= B::perlstring($p->{type}) . ',';
		}
		if (exists $p->{optional} or exists $p->{default}) {
			$type_params_stuff .= '{';
			$type_params_stuff .= sprintf('optional=>%d,', !!$p->{optional}) if exists $p->{optional};
			$type_params_stuff .= sprintf('default=>scalar(%s),', $p->{default}) if exists $p->{default};
			$type_params_stuff .= '},';
		}
	}
	
	# TODO: slurpy still needs thought!
	
	@signature_var_list = '$arg' if $seen_named;
	$type_params_stuff .= ']';
	
	return (
		$seen_named,
		join(',', @signature_var_list),
		$type_params_stuff,
	);
};

keytype RoleList is /
	\+?\s*
	(
		(?&PerlBlock) | (?&PerlQualifiedIdentifier)
	)
	(
		(?:\s*\?) | (?&PerlList)
	)?
	(
		\s*
		,
		\s*
		\+?\s*
		(
			(?&PerlBlock) | (?&PerlQualifiedIdentifier)
		)
		(
			(?:\s*\?) | (?&PerlList)
		)?
	)*
/xs;  #/*

my $handle_rolelist = sub {
	my ($rolelist, $kind) = @_;
	my @return;
	
	while (length $rolelist) {
		$rolelist =~ s/^\s+//xs;
		
		my $prefix = '';
		my $role = undef;
		my $role_is_block = 0;
		my $suffix = '';
		my $role_params   = undef;
		
		if ($rolelist =~ /^\+/xs) {
			die 'unexpected plus sign' if $kind eq 'role';
			$prefix = '+';
			$rolelist =~ s/^\+\s*//xs;
		}
		
		if ($rolelist =~ /^((?&PerlBlock)) $PPR::GRAMMAR/xso) {
			$role = $1;
			$role_is_block = 1;
			$rolelist =~ s/^\Q$role//xs;
			$rolelist =~ s/^\s+//xs;
		}
		elsif ($rolelist =~ /^((?&PerlQualifiedIdentifier)) $PPR::GRAMMAR/xso) {
			$role = $1;
			$rolelist =~ s/^\Q$role//xs;
			$rolelist =~ s/^\s+//xs;
		}
		else {
			die "expected role name, got $rolelist";
		}
		
		if ($rolelist =~ /^\?/xs) {
			die 'unexpected question mark' if $kind eq 'class';
			$suffix = '?';
			$rolelist =~ s/^\?\s*//xs;
		}
		elsif ($rolelist =~ /^((?&PerlList)) $PPR::GRAMMAR/xso) {
			$role_params = $1;
			$rolelist =~ s/^\Q$role_params//xs;
			$rolelist =~ s/^\s+//xs;
		}
		
		if ($role_is_block) {
			push @return, sprintf('sprintf(q(%s%%s%s), scalar(do %s))', $prefix, $suffix, $role);
		}
		else {
			push @return, B::perlstring("$prefix$role$suffix");
		}
		if ($role_params) {
			push @return, sprintf('[%s]', $role_params);
		}
		
		$rolelist =~ s/^\s+//xs;
		if (length $rolelist) {
			$rolelist =~ /^,/ or die "expected comma, got $rolelist";
			$rolelist =~ s/^\,\s*//;
		}
	}
	
	return join(",", @return);
};

sub _handle_factory_keyword {
	my ($me, $name, $via, $code, $sig) = @_;
	if ($via) {
		return sprintf(
			'q[%s]->_factory(%s, \\(%s));',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			($via  =~ /^\{/ ? "scalar(do $via)"  : B::perlstring($via)),
		);
	}
	if (!$sig) {
		return sprintf(
			'q[%s]->_factory(%s, sub { my ($factory, $class) = (@_); do %s });',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			$code,
		);
	}
	my ($signature_is_named, $signature_var_list, $type_params_stuff) = $handle_signature_list->($sig);
	my $munged_code = sprintf('sub { my($factory,$class,%s)=(shift,shift,@_); do %s }', $signature_var_list, $code);
	sprintf(
		'q[%s]->_factory(%s, { code => %s, named => %d, signature => %s });',
		$me,
		($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
		$munged_code,
		!!$signature_is_named,
		$type_params_stuff,
	);
}

sub _handle_modifier_keyword {
	my ($me, $kind, $name, $code, $sig) = @_;
	
	if ($sig) {
		my ($signature_is_named, $signature_var_list, $type_params_stuff) = $handle_signature_list->($sig);
		my $munged_code;
		if ($kind eq 'around') {
			$munged_code = sprintf('sub { my($next,$self,%s)=(shift,shift,@_); my $class = ref($self)||$self; do %s }', $signature_var_list, $code);
		}
		else {
			$munged_code = sprintf('sub { my($self,%s)=(shift,@_); my $class = ref($self)||$self; do %s }', $signature_var_list, $code);
		}
		sprintf(
			'q[%s]->_modifier(q(%s), %s, { code => %s, named => %d, signature => %s });',
			$me,
			$kind,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			$munged_code,
			!!$signature_is_named,
			$type_params_stuff,
		);
	}
	elsif ($kind eq 'around') {
		sprintf(
			'q[%s]->_modifier(q(%s), %s, sub { my ($next, $self) = @_; my $class = ref($self)||$self; do %s });',
			$me,
			$kind,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			$code,
		);
	}
	else {
		sprintf(
			'q[%s]->_modifier(q(%s), %s, sub { my $self = $_[0]; my $class = ref($self)||$self; do %s });',
			$me,
			$kind,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			$code,
		);
	}
}


#
# KEYWORDS/UTILITIES
#

sub import {
	no warnings 'closure';
	my $caller = caller;
	my ($me, %opts) = (shift, @_);
	
	# Optionally export wrapper subs for pre-declared types
	#
	if ($opts{declare}) {
		require MooX::Press;
		# Need to reproduce this logic from MooX::Press to find out
		# the name of the type library.
		$opts{caller}  ||= $caller;
		$opts{prefix}       = $opts{caller} unless exists $opts{prefix};
		$opts{type_library} = 'Types'       unless exists $opts{type_library};
		$opts{type_library} = 'MooX::Press'->qualify_name($opts{type_library}, $opts{prefix});
		my $types = $opts{type_library};
		for my $name (@{ $opts{declare} }) {
			eval qq{
				sub $caller\::$name         ()   { goto \\&$types\::$name }
				sub $caller\::is_$name      (\$) { goto \\&$types\::is_$name }
				sub $caller\::assert_$name  (\$) { goto \\&$types\::assert_$name }
				1;
			} or die($@);
		}
	}
	
	# Export utility stuff
	#
	MooX::Pression::_Gather->import::into($caller, -gather => %opts);
	MooX::Press::Keywords->import::into($caller, qw( -booleans -privacy -util -try ));
	$_->import::into($caller, qw( -types -is -assert ))
		for qw(Types::Standard Types::Common::Numeric Types::Common::String);
	
	# `class` keyword
	#
	keyword class ('+'? $plus, QualifiedIdentifier $classname, '(', SignatureList $sig, ')', Block $classdfn) {
		my ($signature_is_named, $signature_var_list, $type_params_stuff) = $handle_signature_list->($sig);
		my $munged_code = sprintf('sub { my($generator,%s)=(shift,@_); q(%s)->_package_callback(sub %s) }', $signature_var_list, $me, $classdfn);
		sprintf(
			'use MooX::Pression::_Gather -parent => %s; use MooX::Pression::_Gather -gather, %s => %s; use MooX::Pression::_Gather -unparent;',
			B::perlstring("$plus$classname"),
			B::perlstring("class_generator:$plus$classname"),
			$munged_code,
		);
	}
	keyword class ('+'? $plus, QualifiedIdentifier $classname, Block $classdfn) {
		sprintf(
			'use MooX::Pression::_Gather -parent => %s; use MooX::Pression::_Gather -gather, %s => q[%s]->_package_callback(sub %s); use MooX::Pression::_Gather -unparent;',
			B::perlstring("$plus$classname"),
			B::perlstring("class:$plus$classname"),
			$me,
			$classdfn,
		);
	}
	keyword class ('+'? $plus, QualifiedIdentifier $classname, ';') {
		sprintf(
			'use MooX::Pression::_Gather -gather, %s => {};',
			B::perlstring("class:$plus$classname"),
		);
	}
	
	# `role` keyword
	#
	keyword role (QualifiedIdentifier $classname, '(', SignatureList $sig, ')', Block $classdfn) {
		my ($signature_is_named, $signature_var_list, $type_params_stuff) = $handle_signature_list->($sig);
		my $munged_code = sprintf('sub { my($generator,%s)=(shift,@_); q(%s)->_package_callback(sub %s) }', $signature_var_list, $me, $classdfn);
		sprintf(
			'use MooX::Pression::_Gather -parent => %s; use MooX::Pression::_Gather -gather, %s => %s; use MooX::Pression::_Gather -unparent;',
			B::perlstring($classname),
			B::perlstring('role_generator:'.$classname),
			$munged_code,
		);
	}
	keyword role (QualifiedIdentifier $classname, Block $classdfn) {
		sprintf(
			'use MooX::Pression::_Gather -parent => %s; use MooX::Pression::_Gather -gather, %s => q[%s]->_package_callback(sub %s); use MooX::Pression::_Gather -unparent;',
			B::perlstring($classname),
			B::perlstring('role:'.$classname),
			$me,
			$classdfn,
		);
	}
	keyword role (QualifiedIdentifier $classname, OWS, ';') {
		sprintf(
			'use MooX::Pression::_Gather -gather, %s => {};',
			B::perlstring('role:'.$classname),
		);
	}
	
	# `begin` and `end` keywords
	#
	keyword begin (Block $code) {
		sprintf('q[%s]->_begin(sub { my ($package, $kind) = (shift, @_); do %s });', $me, $code);
	}
	keyword end (Block $code) {
		sprintf('q[%s]->_end(sub { my ($package, $kind) = (shift, @_); do %s });', $me, $code);
	}
	
	# `type_name` keyword
	#
	keyword type_name (Identifier $tn) {
		sprintf('q[%s]->_type_name(%s);', $me, B::perlstring($tn));
	}
	
	# `extends` keyword
	#
	keyword extends (RoleList $parent) {
		sprintf('q[%s]->_extends(%s);', $me, $parent->$handle_rolelist('class'));
	}
	
	# `with` keyword
	#
	keyword with (RoleList $roles) {
		sprintf('q[%s]->_with(%s);', $me, $roles->$handle_rolelist('role'));
	}
	
	# `requires` keyword
	#
	keyword requires (Identifier|Block $name, '(', SignatureList $sig, ')') {
		sprintf(
			'q[%s]->_requires(%s);',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
		);
	}
	keyword requires (Identifier|Block $name) {
		sprintf(
			'q[%s]->_requires(%s);',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
		);
	}
	
	# `has` keyword
	#
	keyword has ('+'? $plus, /[\$\@\%]/? $sigil, Identifier $name, '!'? $postfix) {
		sprintf('q[%s]->_has(%s);', $me, B::perlstring("$plus$sigil$name$postfix"));
	}
	keyword has ('+'? $plus, /[\$\@\%]/? $sigil, Identifier $name, '!'? $postfix, '(', List $spec, ')') {
		sprintf('q[%s]->_has(%s, %s);', $me, B::perlstring("$plus$sigil$name$postfix"), $spec);
	}
	keyword has (Block $name) {
		sprintf('q[%s]->_has(scalar(do %s));', $me, $name);
	}
	keyword has (Block $name, '(', List $spec, ')') {
		sprintf('q[%s]->_has(scalar(do %s), %s);', $me, $name, $spec);
	}
	
	# `constant` keyword
	keyword constant (Identifier $name, '=', Expr $value) {
		sprintf('q[%s]->_constant(%s, %s);', $me, B::perlstring($name), $value);
	}
	
	# `method` keyword
	#
	keyword method (Identifier|Block $name, '(', SignatureList $sig, ')', Block $code) {
		my ($signature_is_named, $signature_var_list, $type_params_stuff) = $handle_signature_list->($sig);
		my $munged_code = sprintf('sub { my($self,%s)=(shift,@_); my $class = ref($self)||$self; do %s }', $signature_var_list, $code);
		sprintf(
			'q[%s]->_can(%s, { code => %s, named => %d, signature => %s });',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			$munged_code,
			!!$signature_is_named,
			$type_params_stuff,
		);
	}
	keyword method (Identifier|Block $name, Block $code) {
		sprintf(
			'q[%s]->_can(%s, sub { my $self = $_[0]; my $class = ref($self)||$self; do %s });',
			$me,
			($name =~ /^\{/ ? "scalar(do $name)" : B::perlstring($name)),
			$code,
		);
	}
	
	# `before`, `after`, and `around` keywords
	#
	keyword before (Identifier|Block $name, '(', SignatureList $sig, ')', Block $code) {
		$me->_handle_modifier_keyword(before => $name, $code, $sig);
	}
	keyword before (Identifier|Block $name, Block $code) {
		$me->_handle_modifier_keyword(before => $name, $code);
	}
	keyword after (Identifier|Block $name, '(', SignatureList $sig, ')', Block $code) {
		$me->_handle_modifier_keyword(after => $name, $code, $sig);
	}
	keyword after (Identifier|Block $name, Block $code) {
		$me->_handle_modifier_keyword(after => $name, $code);
	}
	keyword around (Identifier|Block $name, '(', SignatureList $sig, ')', Block $code) {
		$me->_handle_modifier_keyword(around => $name, $code, $sig);
	}
	keyword around (Identifier|Block $name, Block $code) {
		$me->_handle_modifier_keyword(around => $name, $code);
	}
	
	# `factory` keyword
	#
	keyword factory (Identifier|Block $name, '(', SignatureList $sig, ')', Block $code) {
		$me->_handle_factory_keyword($name, undef, $code, $sig);
	}
	keyword factory (Identifier|Block $name, Block $code) {
		$me->_handle_factory_keyword($name, undef, $code, undef);
	}
	keyword factory (Identifier|Block $name, 'via', Identifier $via) {
		$me->_handle_factory_keyword($name, $via, undef, undef);
	}
	keyword factory (Identifier|Block $name, ';') {
		$me->_handle_factory_keyword($name, 'new', undef, undef);
	}
	
	# `coerce` keyword
	#
	keyword coerce ('from'?, Block|QualifiedIdentifier|String $from, 'via', Block|Identifier|String $via, Block? $code) {
		if ($from =~ /^\{/) {
			$from = "scalar(do $from)"
		}
		elsif ($from !~ /^(q\b)|(qq\b)|"|'/) {
			$from = B::perlstring($from);
		}
		
		if ($via =~ /^\{/) {
			$via = "scalar(do $via)"
		}
		elsif ($via !~ /^(q\b)|(qq\b)|"|'/) {
			$via = B::perlstring($via);
		}
		
		sprintf('q[%s]->_coerce(%s, %s, %s);', $me, $from, $via, $code ? "sub { my \$class; local \$_; (\$class, \$_) = \@_; do $code }" : '');
	}
	
	# Go!
	#
	on_scope_end {
		eval "package $caller; use MooX::Pression::_Gather -go; 1"
			or Carp::croak($@);
	};
	
	# Need this to export `authority` and `version`...
	@_ = ($me);
	goto \&Exporter::Tiny::import;
}

our %OPTS;

# `version` keyword
#
sub version {
	$OPTS{version} = shift;
}

# `authority` keyword
#
sub authority {
	$OPTS{authority} = shift;
}


#
# CALLBACKS
#
sub _package_callback {
	shift;
	my $cb = shift;
	local %OPTS = ();
	$cb->();
	return +{ %OPTS };
}
sub _has {
	shift;
	my ($attr, %spec) = @_;
	$OPTS{has}{$attr} = \%spec;
}
sub _extends {
	shift;
	@{ $OPTS{extends}||=[] } = @_;
}
sub _type_name {
	shift;
	$OPTS{type_name} = shift;
}
sub _begin {
	shift;
	$OPTS{begin} = shift;
}
sub _end {
	shift;
	$OPTS{end} = shift;
}
sub _with {
	shift;
	push @{ $OPTS{with}||=[] }, @_;
}
sub _requires {
	shift;
	push @{ $OPTS{requires}||=[] }, @_;
}
sub _coerce {
	shift;
	push @{ $OPTS{coerce}||=[] }, @_;
}
sub _factory {
	shift;
	push @{ $OPTS{factory}||=[] }, @_;
}
sub _constant {
	shift;
	my ($name, $value) = @_;
	$OPTS{constant}{$name} = $value;
}
sub _can {
	shift;
	my ($name, $code) = @_;
	$OPTS{can}{$name} = $code;
}
sub _modifier {
	shift;
	my ($kind, $name, $value) = @_;
	push @{ $OPTS{$kind} ||= [] }, $name, $value;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooX::Pression - express yourself through moo

=head1 SYNOPSIS

MyApp.pm

  use v5.18;
  use strict;
  use warnings;
  
  package MyApp {
    use MooX::Pression (
      version    => 0.1,
      authority  => 'cpan:MYPAUSEID',
    );
    
    class Person {
      has name   ( type => Str, required => true );
      has gender ( type => Str );
      
      factory new_man (Str $name) {
        return $class->new(name => $name, gender => 'male');
      }
      
      factory new_woman (Str $name) {
        return $class->new(name => $name, gender => 'female');
      }
      
      method greet (Person *friend, Str *greeting = "Hello") {
        printf("%s, %s!\n", $arg->greeting, $arg->friend->name);
      }
      
      coerce from Str via from_string {
        return $class->new(name => $_);
      }
    }
  }

my_script.pl

  use v5.18;
  use strict;
  use warnings;
  use MyApp;
  use MyApp::Types qw( is_Person );
  
  # Create a new MyApp::Person object.
  #
  my $alice  = MyApp->new_woman("Alice");
  is_Person($alice) or die;
  
  # The string "Bob" will be coerced to a MyApp::Person.
  #
  $alice->greet(friend => "Bob", greeting => 'Hi');

=head1 DESCRIPTION

L<MooX::Pression> is kind of like L<Moops>; a marrying together of L<Moo>
with L<Type::Tiny> and some keyword declaration magic. Instead of being
built on L<Kavorka>, L<Parse::Keyword>, L<Keyword::Simple> and a whole
heap of crack, it is built on L<MooX::Press> and L<Keyword::Declare>.
I'm not saying there isn't some crazy stuff going on under the hood, but
it ought to be a little more maintainable.

Some of the insane features of Moops have been dialled back, and others
have been amped up.

It's more opinionated about API design and usage than Moops is, but in
most cases, it should be fairly easy to port Moops code to MooX::Pression.

MooX::Pression requires Perl 5.18.0 or above. It may work on Perl 5.14.x
and Perl 5.16.x partly, but there are likely to be issues.

L<MooX::Press> is a less magic version of MooX::Pression and only requires
Perl 5.8.8 or above.

=head2 Important Concepts

=head3 The Factory Package and Prefix

MooX::Pression assumes that all the classes and roles you are building
with it will be defined under the same namespace B<prefix>. For example
"MyApp::Person" and "MyApp::Company" are both defined under the common
prefix of "MyApp".

It also assumes there will be a B<< factory package >> that can be used
to build new instances of your class. Rather than creating a new person
object with C<< MyApp::Person->new() >>, you should create a new person
object with C<< MyApp->new_person() >>. Calling C<< MyApp::Person->new() >>
directly is only encouraged from within the "MyApp::Person" class itself,
and from within the factory. Everywhere else, you should call
C<< MyApp->new_person() >> instead.

By default, the factory package and the prefix are the same: they are
the caller that you imported MooX::Pression into. But they can be set
to whatever:

  use MooX::Pression (
    prefix          => 'MyApp::Objects',
    factory_package => 'MyApp::Makers',
  );

MooX::Pression assumes that you are defining all the classes and roles
within this namespace prefix in a single Perl module file. This Perl
module file would normally be named based on the prefix, so in the
example above, it would be "MyApp/Objects.pm" and in the example from
the SYNOPSIS, it would be "MyApp.pm".

Of course, there is nothing to stop you from having multiple prefixes
for different logical parts of a larger codebase, but MooX::Pression
assumes that if it's been set up for a prefix, it owns that prefix and
everything under it, and it's all defined in the same Perl module.

Each object defined by MooX::Pression will have a C<FACTORY> method,
so you can do:

  $person_object->FACTORY

And it will return the string "MyApp". This allows for stuff like:

  class Person {
    method give_birth {
      return $self->FACTORY->new_person();
    }
  }

=head3 The Type Library

While building your classes and objects, MooX::Pression will also build
type constraints for each of them. So for the "MyApp::Person" class
above, it also builds a B<Person> type constraint. This can be used
in Moo/Moose attribute definitions like:

  use MyApp;
  use MyApp::Types qw( Person );
  
  use Moose;
  has boss => (is => 'rw', isa => Person);

And just anywhere a type constraint may be used generally. You should
know this stuff by now.

Note that we had to C<use MyApp> before we could C<use MyApp::Types>.
This is because there isn't a physical "MyApp/Types.pm" file on disk;
it is defined entirely by "MyApp.pm".

Your type library will be the same as your namespace prefix, with
"::Types" added at the end. But you can change that:

  use MooX::Pression (
    prefix          => 'MyApp::Objects',
    factory_package => 'MyApp::Makers',
    type_library    => 'MyApp::TypeLibrary',
  );

It can sometimes be helpful to pre-warn MooX::Pression about the
types you're going to define before you define them, just so it
is able to allow them as barewords in some places...

  use MooX::Pression (
    prefix          => 'MyApp::Objects',
    factory_package => 'MyApp::Makers',
    type_library    => 'MyApp::TypeLibrary',
    declare         => [qw( Person Company )],
  );

See also L<Type::Tiny::Manual>.

=head2 Keywords

=head3 C<< class >>

Define a very basic class:

  class Person;

Define a more complicated class:

  class Person {
    ...;
  }

Note that for the C<class> keyword without a block, it does I<not> act like
the C<package> keyword by changing the "ambient" package. It just defines a
totally empty class with no methods or attributes.

The prefix will automatically be added to the class name, so if the prefix
is MyApp, the above will create a class called MyApp::Person. It will also
create a factory method C<< MyApp->new_person >>. (The name is generated by
stripping the prefix from the class name, replacing any "::" with an
underscore, lowercasing, and prefixing it with "new_".) And it will create
a type called B<Person> in the type library. (Same rules to generate the
name apart from lowercasing and adding "new_".)

Classes can be given more complex names:

  class Person::Neanderthal {
    ...;
  }

Will create "MyApp::Person::Neanderthal" class, a factory method called
C<< MyApp->new_person_neanderthal >>, and a B<Person_Neanderthal> type.

It is possible to create a class without the prefix:

  class ::Person {
    ...;
  }

The class name will now be "Person" instead of "MyApp::Person"!

=head4 Nested classes

C<class> blocks can be nested. This establishes an inheritance heirarchy.

  class Animal {
    has name;
    class Mammal {
      class Primate {
        class Monkey;
        class Gorilla;
        class Human {
          class Superhuman;
        }
      }
    }
    class Bird;
    class Fish {
      class Shark;
    }
  }
  
  my $superman = MyApp->new_superhuman( name => 'Kal El' );

See also C<extends> as an alternative way of declaring inheritance.

It is possible to prefix a class name with a plus sign:

  package MyApp {
    use MooX::Pression;
    class Person {
      has name;
      class +Employee {
        has job_title;
      }
    }
  }

Now the employee class will be named C<MyApp::Person::Employee> instead of
the usual C<MyApp::Employee>.

=head4 Parameterizable classes

  package MyApp {
    use MooX::Pression;
    
    class Animal {
      has name;
    }
    
    class Species ( Str $common_name, Str $binomial ) {
      extends Animal;
      constant common_name  = $common_name;
      constant binomial     = $binomial;
    }
    
    class Dog {
      extends Species('dog', 'Canis familiaris');
      method bark () {
        say "woof!";
      }
    }
  }

Here, "MyApp::Species" isn't a class in the usual sense; you cannot create
instances of it. It's like a template for generating classes. Then 
"MyApp::Dog" generates a class from the template and inherits from that.

  my $Cat = MyApp->generate_species('cat', 'Felis catus');
  my $mog = $Cat->new(name => 'Mog');
  
  $mog->isa('MyApp::Animal');         # true
  $mog->isa('MyApp::Species');        # false!!!
  $mog->isa($Cat);                    # true

Because there are never any instances of "MyApp::Species", it doesn't
make sense to have a B<Species> type constraint. Instead there are
B<SpeciesClass> and B<SpeciesInstance> type constraints.

  use MyApp::Types -is;
  
  my $lassie = MyApp->new_dog;
  
  is_Animal( $lassie );               # true
  is_Dog( $lassie );                  # true
  is_SpeciesInstance( $lassie );      # true
  is_SpeciesClass( ref($lassie) );    # true

Subclasses cannot be nested inside parameterizable classes.
It should theoretically be possible to nest parameterizable classes
within regular classes, but this isn't implemented yet.

=head3 C<< role >>

Define a very basic role:

  role Person;

Define a more complicated role:

  role Person {
    ...;
  }

This is just the same as C<class> but defines a role instead of a class.

Roles cannot be nested within each other, nor can roles be nested in classes,
nor classes in roles.

=head4 Parameterizable roles

Often it makes more sense to parameterize roles than classes.

  package MyApp {
    use MooX::Pression;
    
    class Animal {
      has name;
    }
    
    role Species ( Str $common_name, Str $binomial ) {
      extends Animal;
      constant common_name  = $common_name;
      constant binomial     = $binomial;
    }
    
    class Dog {
      with Species('dog', 'Canis familiaris'), GoodBoi?;
      method bark () {
        say "woof!";
      }
    }
  }

=head3 C<< type_name >>

  class Homo::Sapiens {
    type_name Human;
  }

The class will still be called L<MyApp::Homo::Sapiens> but the type in the
type library will be called B<Human> instead of B<Homo_Sapiens>.

=head3 C<< extends >>

Defines a parent class. Only for use within C<class> blocks.

  class Person {
    extends Animal;
  }

This works:

  class Person {
    extends ::Animal;   # no prefix
  }

=head3 C<< with >>

Composes roles.

  class Person {
    with Employable, Consumer;
  }
  
  role Consumer;
  
  role Worker;
  
  role Payable;
  
  role Employable {
    with Worker, Payable;
  }

Because roles are processed before classes, you can compose roles into classes
where the role is defined later in the file. But if you compose one role into
another, you must define them in a sensible order.

It is possible to compose a role that does not exist by adding a question mark
to the end of it:

  class Person {
    with Employable, Consumer?;
  }
  
  role Employable {
    with Worker?, Payable?;
  }

This is equivalent to declaring an empty role.

=head3 C<< begin >>

This code gets run early on in the definition of a class or role.

  class Person {
    begin {
      say "Defining $package";
    }
  }

At the time the code gets run, none of the class's attributes or methods will
be defined yet.

The lexical variables C<< $package >> and C<< $kind >> are defined within the
block. C<< $kind >> will be either 'class' or 'role'.

It is possible to define a global chunk of code to run too:

  use MooX::Pression (
    ...,
    begin => sub {
      my ($package, $kind) = @_;
      ...;
    },
  );

Per-package C<begin> overrides the global C<begin>.

Unlike Perl's C<BEGIN> keyword, a package can only have one C<begin>.

If C<class> definitions are nested, C<begin> blocks will be inherited by
child classes. If a parent class is specified via C<extends>, C<begin>
blocks will not be inherited.

=head3 C<< end >>

This code gets run late in the definition of a class or role.

  class Person {
    end {
      say "Finished defining $package";
    }
  }

The lexical variables C<< $package >> and C<< $kind >> are defined within the
block. C<< $kind >> will be either 'class' or 'role'.

It is possible to define a global chunk of code to run too:

  use MooX::Pression (
    ...,
    end => sub {
      my ($package, $kind) = @_;
      ...;
    },
  );

Per-package C<end> overrides the global C<end>.

Unlike Perl's C<END> keyword, a package can only have one C<end>.

If C<class> definitions are nested, C<end> blocks will be inherited by
child classes. If a parent class is specified via C<extends>, C<end>
blocks will not be inherited.

=head3 C<< has >>

  class Person {
    has name;
    has age;
  }
  
  my $bob = MyApp->new_person(name => "Bob", age => 21);

Moo-style attribute specifications may be given:

  class Person {
    has name ( is => rw, type => Str, required => true );
    has age  ( is => rw, type => Int );
  }

Note there is no fat comma after the attribute name! It is a bareword.

Use a plus sign before an attribute name to modify an attribute defined
in a parent class.

  class Animal {
    has name ( type => Str, required => false );
    
    class Person {
      has +name ( required => true );
    }
  }

C<rw>, C<rwp>, C<ro>, C<lazy>, C<true>, and C<false> are allowed as
barewords for readability, but C<is> is optional, and defaults to C<rw>.

Note C<type> instead of C<isa>. Any type constraints from L<Types::Standard>,
L<Types::Common::Numeric>, and L<Types::Common::String> will be avaiable as
barewords. Also, any pre-declared types can be used as barewords. It's
possible to quote types as strings, in which case you don't need to have
pre-declared them.

  class Person {
    has name   ( type => Str, required => true );
    has age    ( type => Int );
    has spouse ( type => 'Person' );
    has kids   (
      is      => lazy,
      type    => 'ArrayRef[Person]',
      builder => sub { [] },
    );
  }

Note that when C<type> is a string, MooX::Pression will consult your
type library to figure out what it means.

It is also possible to use C<< isa => 'SomeClass' >> or
C<< does => 'SomeRole' >> to force strings to be treated as class names
or role names instead of type names.

  class Person {
    has name   ( type => Str, required => true );
    has age    ( type => Int );
    has spouse ( isa  => 'Person' );
    has pet    ( isa  => '::Animal' );   # no prefix
  }

For enumerations, you can define them like this:

  class Person {
    ...;
    has status ( enum => ['alive', 'dead', 'undead'] );
  }

MooX::Pression integrates support for L<MooX::Enumeration> (and
L<MooseX::Enumeration>).

  class Person {
    ...;
    has status (
      enum    => ['alive', 'dead', 'undead'],
      default => 'alive',
      handles => 1,
    );
  }
  
  my $bob = MyApp->new_person;
  if ( $bob->is_alive ) {
    ...;
  }

C<< handles => 1 >> creates methods named C<is_alive>, C<is_dead>, and
C<is_undead>, and C<< handles => 2 >> creates methods named
C<status_is_alive>, C<status_is_dead>, and C<status_is_undead>.

Checking C<< $bob->status eq 'alvie' >> is prone to typos, but
C<< $bob->status_is_alvie >> will cause a runtime error because the
method is not defined.

It is possible to add hints to the attribute name as a shortcut for common
specifications.

  class Person {
    has $name!;
    has $age;
    has @kids;
  }

Using C<< $ >>, C<< @ >> and C<< % >> sigils hints that the values should
be a scalar, an arrayref, or a hashref (and tries to be smart about
overloading). It I<< does not make the attribute available as a lexical >>!
You still access the value as C<< $self->age >> and not just C<< $age >>.

The trailing C<< ! >> indicates a required attribute.

If you need to decide an attribute name on-the-fly, you can replace the
name with a block that returns the name as a string.

  class Employee {
    extends Person;
    has {
      $ENV{LOCALE} eq 'GB'
        ? 'national_insurance_no'
        : 'social_security_no'
    } (type => Str)
  }
  
  my $bob = Employee->new(
    name               => 'Bob',
    social_security_no => 1234,
  );

This can be used to define a bunch of types from a list.

  class Person {
    my @attrs = qw( $name $age );
    for my $attr (@attrs) {
      has {$attr} ( required => true );
    }
  }

You can think of the syntax as being kind of like C<print>.

  print BAREWORD_FILEHANDLE @strings;
  print { block_returning_filehandle(); } @strings;

=head3 C<< constant >>

  class Person {
    extends Animal;
    constant latin_name = 'Homo sapiens';
  }

C<< MyApp::Person->latin_name >>, C<< MyApp::Person::latin_name >>, and
C<< $person_object->latin_name >> will return 'Homo sapiens'.

=head3 C<< method >>

  class Person {
    has $spouse;
    
    method marry {
      my ($self, $partner) = @_;
      $self->spouse($partner);
      $partner->spouse($self);
      return $self;
    }
  }

C<< sub { ... } >> will not work as a way to define methods within the
class. Use C<< method { ... } >> instead.

The variables C<< $self >> and C<< $class >> will be automatically defined
within all methods. C<< $self >> is set to C<< $_[0] >> (though the invocant
is not shifted off C<< @_ >>). C<< $class >> is set to C<< ref($self)||$self >>.
If the method is called as a class method, both C<< $self >> and C<< $class >>
will be the same thing: the full class name as a string. If the method is
called as an object method, C<< $self >> is the object and C<< $class >> is
its class.

Like with C<has>, you may use a block that returns a string instead of a
bareword name for the method.

  method {"ma"."rry"} {
    ...;
  }

MooX::Pression supports method signatures for named arguments and
positional arguments. If you need a mixture of named and positional
arguments, this is not currently supported, so instead you should
define the method with no signature at all, and unpack C<< @_ >> within
the body of the method.

=head4 Signatures for Named Arguments

  class Person {
    has $spouse;
    
    method marry ( Person *partner, Object *date = DateTime->now ) {
      $self->spouse( $arg->partner );
      $arg->partner->spouse( $self );
      return $self;
    }
  }

The syntax for each named argument is:

  Type *name = default

The type is a type name. It must start with a word character (but not a
digit) and continues until whitespace is seen. Whitespace is not
currently permitted in the type. (Parsing is a little naive right now.)

Alternatively, you can provide a block which returns a type name or
returns a blessed Type::Tiny object. (And the block can contain
whitespace!)

The asterisk indicates that the argument is named, not positional.

The name may be followed by a question mark to indicate an optional
argument.

  method marry ( Person *partner, Object *date? ) {
    ...;
  }

Or it may be followed by an equals sign to set a default value.

As with signature-free methods, C<< $self >> and C<< $class >> wll be
defined for you in the body of the method. However, when a signature
has been used C<< $self >> I<is> shifted off C<< @_ >>.

Also within the body of the method, a variable called C<< $arg >>
is provided. This is a hashref of the named arguments. So you can
access the partner argument in the above example like this:

  $arg->{partner}

But because C<< $arg >> is blessed, you can also do:

  $arg->partner

The latter style is encouraged as it looks neater, plus it helps
catch typos. (C<< $ars->{pratner} >> for example!) However, accessing
it as a plain hashref is supported and shouldn't be considered to be
breaking encapsulation.

For optional arguments you can check:

  exists($arg->{date})

Or:

  $arg->has_date

For types which have a coercion defined, the value will be automatically
coerced.

Methods with named arguments can be called with a hash or hashref.

  $alice->marry(  partner => $bob  );      # okay
  $alice->marry({ partner => $bob });      # also okay

=head4 Signatures for Positional Arguments

  method marry ( Person $partner, Object $date? ) {
    $self->spouse( $partner );
    $partner->spouse( $self );
    return $self;
  }

The dollar sign is used instead of an asterisk to indicate a positional
argument.

As with named arguments, C<< $self >> is automatically shifted off C<< @_ >>
and C<< $class >> exists. Unlike named arguments, there is no C<< $arg >>
variable, and instead a scalar variable is defined for each named argument.

Allowing a slurpy hash or array at the end of the signature is currently not
supported, but is planned.

Optional arguments and default are supported in the same way as named
arguments.

=head4 Empty Signatures

There is a difference between the following two methods:

  method foo {
    ...;
  }
  
  method foo () {
    ...;
  }

In the first, you have not provided a signature and are expected to
deal with C<< @_ >> in the body of the method. In the second, there
is a signature, but it is a signature showing that the method expects
no arguments (other than the invocant of course).

=head3 require

Indicates that a role requires classes to fulfil certain methods.

  role Payable {
    requires account;
    requires deposit (Num $amount);
  }
  
  class Employee {
    extends Person;
    with Payable;
    has account;
    method deposit (Num $amount) {
      ...;
    }
  }

Required methods have an optional signature; this is currently
ignored but may be useful for self-documenting code.

=head3 C<< before >>

  before marry {
    say "Speak now or forever hold your peace!";
  }

As with C<method>, C<< $self >> and C<< $class >> are defined.

As with C<method>, you can provide a signature:

  before marry ( Person $partner, Object $date? ) {
    say "Speak now or forever hold your peace!";
  }

Note that this will result in the argument types being checked/coerced twice;
once by the before method modifier and once by the method itself. Sometimes
this may be desirable, but at other times your before method modifier might
not care about the types of the arguments, so can omit checking them.

  before marry ( $partner, $date? ) {
    say "Speak now or forever hold your peace!";
  }

=head3 C<< after >>

There's not much to say about C<after>. It's just like C<before>.

  after marry {
    say "You may kiss the bride!";
  }
  
  after marry ( Person $partner, Object $date? ) {
    say "You may kiss the bride!";
  }
  
  after marry ( $partner, $date? ) {
    say "You may kiss the bride!";
  }

=head3 C<< around >>

The C<around> method modifier is somewhat more interesting.

  around marry ( Person $partner, Object $date? ) {
    say "Speak now or forever hold your peace!";
    my $return = $self->$next(@_);
    say "You may kiss the bride!";
    return $return;
  }

The C<< $next >> variable holds a coderef pointing to the "original" method
that is being modified. This gives your method modifier the ability to munge
the arguments seen by the "original" method, and munge any return values.
(I say "original" in quote marks because it may not really be the original
method but another wrapper!)

C<< $next >> and C<< $self >> are both shifted off C<< @_ >>.

If you use the signature-free version then C<< $next >> and C<< $self >>
are not shifted off C<< @_ >> for you, but the variables are still defined.

  around marry {
    say "Speak now or forever hold your peace!";
    my $return = $self->$next($_[2], $_[3]);
    say "You may kiss the bride!";
    return $return;
  }

=head3 C<< factory >>

The C<factory> keyword is used to define alternative constructors for
your class.

  class Person {
    has name   ( type => Str, required => true );
    has gender ( type => Str );
    
    factory new_man (Str $name) {
      return $class->new(name => $name, gender => 'male');
    }
    
    factory new_woman (Str $name) {
      return $class->new(name => $name, gender => 'female');
    }
  }

But here's the twist. These methods are defined within the factory
package, not within the class.

So you can call:

  MyApp->new_man("Bob")             # yes

But not:

  MyApp::Person->new_man("Bob")     # no

Note that if your class defines I<any> factory methods like this, then the
default factory method (in this case C<< MyApp->new_person >> will no longer
be automatically created. But you can create the default one easily:

  class Person {
    has name   ( type => Str, required => true );
    has gender ( type => Str );
    
    factory new_man (Str $name) { ... }
    factory new_woman (Str $name) { ... }
    factory new_person;   # no method signature or body!
  }

Within a factory method body, the variable C<< $class >> is defined, just
like normal methods, but C<< $self >> is not defined. There is also a
variable C<< $factory >> which is a string containing the factory
package name. This is because you sometimes need to create more than
just one object in a factory method.

  class Wheel;
  
  class Car {
    has @wheels;
    
    factory new_three_wheeler () {
      return $class->new(
        wheels => [
          $factory->new_wheel,
          $factory->new_wheel,
          $factory->new_wheel,
        ]
      );
    }
    
    factory new_four_wheeler () {
      return $class->new(
        wheels => [
          $factory->new_wheel,
          $factory->new_wheel,
          $factory->new_wheel,
          $factory->new_wheel,
        ]
      );
    }
  }

As with C<method> and the method modifiers, if you provide a signature,
C<< $factory >> and C<< $class >> will be shifted off C<< @_ >>. If you
don't provide a signature, the variables will be defined, but not shifted
off C<< @_ >>.

An alternative way to provide additional constructors is with C<method>
and then use C<factory> to proxy them.

  class Person {
    has name   ( type => Str, required => true );
    has gender ( type => Str );
    
    method new_guy (Str $name) { ... }
    method new_gal (Str $name) { ... }
    
    factory new_person;
    factory new_man via new_guy;
    factory new_woman via new_gal;
  }

Now C<< MyApp->new_man >> will call C<< MyApp::Person->new_guy >>.

C<< factory new_person >> with no C<via> or method body is basically
like saying C<< via new >>.

=head3 C<< coerce >>

  class Person {
    has name   ( type => Str, required => true );
    has gender ( type => Str );
    
    coerce from Str via from_string {
      $class->new(name => $_);
    }
  }
  
  class Company {
    has owner ( type => 'Person', required => true );
  }
  
  my $acme = MyApp->new_company( owner => "Bob" );

Note that the company owner is supposed to be a person object, not a string,
but the Person class knows how create a person object from a string.

Coercions are automatically enabled in a lot of places for types that have
a coercion. For example, types in signatures, and types in attribute
definitions.

Note that the coercion body doesn't allow signatures, and the value being
coerced will be found in C<< $_ >>. If you want to have signatures, you
can define a coercion as a normal method first:

  class Person {
    has name   ( type => Str, required => true );
    has gender ( type => Str );
    
    method from_string ( Str $name ) {
      $class->new(name => $name);
    }
    
    coerce from Str via from_string;
  }

In both cases, a C<< MyApp::Person->from_string >> method is generated
which can be called to manually coerce a string into a person object.

They keyword C<< from >> is technically optional, but does make the
statement more readable.

  coerce Str via from_string {      # this works
    $class->new(name => $_);
  }

=head3 C<< version >>

  class Person {
    version 1.0;
  }

This just sets C<< $MyApp::Person::VERSION >>.

You can set a default version for all packages like this:

  use MooX::Pression (
    ...,
    version => 1.0,
  );

If C<class> definitions are nested, C<version> will be inherited by
child classes. If a parent class is specified via C<extends>, C<version>
will not be inherited.

=head3 C<< authority >>

  class Person {
    authority 'cpan:TOBYINK';
  }

This just sets C<< $MyApp::Person::AUTHORITY >>.

It is used to indicate who is the maintainer of the package.

  use MooX::Pression (
    ...,
    version   => 1.0,
    authority => 'cpan:TOBYINK',
  );

If C<class> definitions are nested, C<authority> will be inherited by
child classes. If a parent class is specified via C<extends>, C<authority>
will not be inherited.

=head2 Utilities

MooX::Pression also exports constants C<true> and C<false> into your
namespace. These show clearer boolean intent in code than using 1 and 0.

MooX::Pression exports C<rw>, C<ro>, C<rwp>, and C<lazy> constants
which make your attribute specs a little cleaner looking.

MooX::Pression exports C<blessed> from L<Scalar::Util> because that can
be handy to have, and C<confess> from L<Carp>. MooX::Pression's copy
of C<confess> is super-powered and runs its arguments through C<sprintf>.

  before vote {
    if ($self->age < 18) {
      confess("Can't vote, only %d", $self->age);
    }
  }

And MooX::Pression exports everything from L<Try::Tiny> because it's
cool. (This might be replaced with another C<try> module in the future?)

And last but not least, it exports all the types, C<< is_* >> functions,
and C<< assert_* >> functions from L<Types::Standard>,
L<Types::Common::String>, and L<Types::Common::Numeric>.

=head2 MooseX::Pression or MouseX::Pression?

  use MooX::Pression (
    ...,
    toolkit => 'Moose',
  );

  use MooX::Pression (
    ...,
    toolkit => 'Mouse',
  );

The ability to choose a toolkit on a package-by-package basis is not
currently supported. (Though it's implemented in MooX::Press.)

The C<< handles => 1 >> and C<< handles => 2 >> features for enum
attributes are not supported with Mouse.

=head2 MooX::Pression vs Moops

MooX::Pression has fewer dependencies than Moops, and crucially doesn't
rely on L<Package::Keyword> and L<Devel::CallParser> which have... issues.
MooX::Pression uses Damian Conway's excellent L<Keyword::Declare>
(which in turn uses L<PPR>) to handle most parsing needs, so parsing should
be more predictable.

Here are a few key syntax and feature differences.

=head3 Declaring a class

Moops:

  class Foo::Bar 1.0 extends Foo with Bar {
    ...;
  }

MooX::Pression:

  class Foo::Bar {
    version 1.0;
    extends Foo;
    with Bar;
  }

Moops and MooX::Pression use different logic for determining whether a class
name is "absolute" or "relative". In Moops, classes containing a "::" are seen
as absolute class names; in MooX::Pression, only classes I<starting with> "::"
are taken to be absolute; all others are given the prefix.

Moops:

  package MyApp {
    use Moops;
    class Foo {
      class Bar {
        class Baz {
          # Nesting class blocks establishes a naming
          # heirarchy so this is MyApp::Foo::Bar::Baz!
        }
      }
    }
  }

MooX::Pression:

  package MyApp {
    use MooX::Pression;
    class Foo {
      class Bar {
        class Baz {
          # This is only MyApp::Baz, but nesting
          # establishes an @ISA chain instead.
        }
      }
    }
  }

=head3 How namespacing works

Moops:

  use feature 'say';
  package MyApp {
    use Moops;
    use List::Util qw(uniq);
    class Foo {
      say __PACKAGE__;         # MyApp::Foo
      say for uniq(1,2,1,3);   # ERROR!
      sub foo { ... }          # MyApp::Foo::foo()
    }
  }

MooX::Pression:

  use feature 'say';
  package MyApp {
    use MooX::Pression;
    use List::Util qw(uniq);
    class Foo {
      say __PACKAGE__;         # MyApp
      say for uniq(1,2,1,3);   # this works fine
      sub foo { ... }          # MyApp::foo()
    }
  }

This is why you can't use C<sub> to define methods in MooX::Pression.
You need to use the C<method> keyword. In MooX::Pression, all the code
in the class definition block is still executing in the parent
package's namespace!

=head3 Multimethods

Moops:

  class Foo {
    multi method foo (ArrayRef $x) {
      say "Fizz";
    }
    multi method foo (HashRef $x) {
      say "Buzz";
    }
  }
  
  Foo->foo( [] );  # Fizz
  Foo->foo( {} );  # Buzz

Multimethods are not currently implemented in MooX::Pression.
The workaround would be something like this:

  class Foo {
    method foo_arrayref (ArrayRef $x) {
      say "Fizz";
    }
    method foo_hashref (HashRef $x) {
      say "Buzz";
    }
    method foo (ArrayRef|HashRef $x) {
      is_ArrayRef($x)
        ? $self->foo_arrayref($x)
        : $self->foo_hashref($x)
    }
  }
  
  Foo->foo( [] );  # Fizz
  Foo->foo( {} );  # Buzz

=head3 Other crazy Kavorka features

Kavorka allows you to mark certain parameters as read-only or aliases,
allows you to specify multiple names for named parameters, allows you
to rename the invocant, allows you to give methods and parameters
attributes, allows you to specify a method's return type, etc, etc.

MooX::Pression's C<method> keyword is unlikely to ever offer as many
features as that. It is unlikely to offer many more features than it
currently offers.

If you need fine-grained control over how C<< @_ >> is handled, just
don't use a signature and unpack C<< @_ >> inside your method body
however you need to.

=head3 Lexical accessors

Moops automatically imported C<lexical_has> from L<Lexical::Accessor>
into each class. MooX::Pression does not, but thanks to how namespacing
works, it only needs to be imported once if you want to use it.

  package MyApp {
    use MooX::Pression;
    use Lexical::Accessor;
    
    class Foo {
      my $identifier = lexical_has identifier => (
        is      => rw,
        isa     => Int,
        default => sub { 0 },
      );
      
      method some_method () {
        $self->$identifier( 123 );    # set identifier
        ...;
        return $self->$identifier;    # get identifier
      }
    }
  }

Lexical accessors give you true private object attributes.

=head3 Factories

MooX::Pression puts an emphasis on having a factory package for instantiating
objects. Moops didn't have anything similar.

=head3 C<augment> and C<override>

These are L<Moose> method modifiers that are not implemented by L<Moo>.
Moops allows you to use these in Moose and Mouse classes, but not Moo
classes. MooX::Pression simply doesn't support them.

=head3 Type Libraries

Moops allowed you to declare multiple type libraries, define type
constraints in each, and specify for each class and role which type
libraries you want it to use.

MooX::Pression automatically creates a single type library for all
your classes and roles within a module to use, and automatically
populates it with the types it thinks you might want.

If you need to use other type constraints:

  package MyApp {
    use MooX::Pression;
    # Just import types into the factory package!
    use Types::Path::Tiny qw( Path );
    
    class DataSource {
      has file => ( type => Path );
      
      method set_file ( Path $file ) {
        $self->file( $file );
      }
    }
  }
  
  my $ds = MyApp->new_datasource;
  $ds->set_file('blah.txt');      # coerce Str to Path
  print $ds->file->slurp_utf8;

=head3 Constants

Moops:

  class Foo {
    define PI = 3.2;
  }

MooX::Pression:

  class Foo {
    constant PI = 3.2;
  }

=head2 Future Directions

Slurpy parameters for methods need to be integrated.

Something like MooX::HandlesVia or Moose native traits would be good.
MooX::HandlesVia doesn't work well for non-reference values though.
MooX::Enumeration proves that it's possible to do!

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Pression>.

=head1 SEE ALSO

Less magic version:
L<MooX::Press>, L<portable::loader>.

Important underlying technologies:
L<Moo>, L<Type::Tiny::Manual>.

Similar modules:
L<Moops>, L<Kavorka>, L<Dios>, L<MooseX::Declare>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

