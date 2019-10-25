use 5.008008;
use strict;
use warnings;

package MooX::Press;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use Exporter::Tiny qw(mkopt);
use Scalar::Util qw(blessed);
use namespace::autoclean;

my $_expand = sub {
	return unless defined $_[0];
	return %{$_[0]} if ref $_[0] eq 'HASH';
	return map @$_, @{mkopt $_[0]} if ref $_[0] eq 'ARRAY';
	goto $_[0];
};

my $_merge = sub {
	map defined($_)&&!ref($_) ? $_ : $_expand->($_), @_;
};

my $_expand_simple = sub {
	return unless defined $_[0];
	return %{$_[0]} if ref $_[0] eq 'HASH';
	return @{$_[0]} if ref $_[0] eq 'ARRAY';
	goto $_[0];
};

# Options not to carry up into subclasses;
# mostly because subclasses inherit behaviour anyway.
my @delete_keys = qw(
	subclass
	has
	with
	extends
	factory
	coerce
	around
	before
	after
	type_name
);

sub import {
	my $builder = shift;
	my $caller  = caller;
	my %opts    = @_==1 ? $_expand->(shift) : @_;
	$opts{caller}  ||= $caller;
	$opts{prefix} = $opts{caller} unless exists $opts{prefix};
	$opts{toolkit} ||= $ENV{'PERL_MOOX_PRESS_TOOLKIT'} || 'Moo';
	
	$opts{version} = $opts{caller}->VERSION
		unless exists $opts{version};
	$opts{authority} = do { no strict 'refs'; no warnings 'once'; ${$opts{caller}."::AUTHORITY"} }
		unless exists $opts{authority};
	
	# Sucks that we need to go through the lists thrice, but we really need to
	# pre-build the type library so it can be used in `isa` for classes/roles.
	#
	my @roles   = @{ mkopt $opts{role} };
	my @classes = @{ mkopt $opts{class} };
	
	unless (exists $opts{type_library}) {
		$opts{type_library} = 'Types';
		$opts{type_library} = $builder->qualify_name($opts{type_library}, $opts{prefix});
	}
	
	if ($opts{type_library}) {
		$builder->prepare_type_library($opts{type_library}, $opts{version}, $opts{authority});
	}
	
	for my $role (@roles) {
		my ($rolename, $roleopts) = @$role;
		$builder->make_type_for_role($rolename, $_expand_simple->($roleopts), %opts);
	}
	for my $class (@classes) {
		my ($classname, $classopts) = @$class;
		$builder->make_type_for_class($classname, $_expand_simple->($classopts), %opts);
	}
	
	for my $role (@roles) {
		my ($rolename, $roleopts) = @$role;
		$builder->do_coercions_for_role($rolename, $_expand_simple->($roleopts), %opts);
	}
	for my $class (@classes) {
		my ($classname, $classopts) = @$class;
		$builder->do_coercions_for_class($classname, $_expand_simple->($classopts), %opts);
	}
	
	for my $role (@roles) {
		my ($rolename, $roleopts) = @$role;
		$builder->make_role($rolename, $_expand_simple->($roleopts), %opts);
	}
	for my $class (@classes) {
		my ($classname, $classopts) = @$class;
		$builder->make_class($classname, $_expand_simple->($classopts), %opts);
	}
}

sub qualify_name {
	shift;
	my ($name, $prefix, $parent) = @_;
	return join("::", $parent, $1) if (defined $parent and $name =~ /^\+(.+)/);
	return $1 if $name =~ /^::(.+)$/;
	$prefix ? join("::", $prefix, $name) : $name;
}

sub type_name {
	shift;
	my ($name, $prefix) = @_;
	my $stub = $name;
	if (lc substr($name, 0, length $prefix) eq lc $prefix) {
		$stub = substr($name, 2 + length $prefix);
	}
	$stub =~ s/::/_/g;
	$stub;
}

sub croak {
	shift;
	require Carp;
	goto \&Carp::croak;
}

my $none;
sub prepare_type_library {
	my $builder = shift;
	my ($lib, $version, $authority) = @_;
	my %types_hash;
	require Type::Tiny::Role;
	require Type::Tiny::Class;
	eval "package $lib; use Type::Library -base; 1"
		or $builder->croak("Could not prepare type library $lib: $@");
	require Module::Runtime;
	$INC{ Module::Runtime::module_notional_filename($lib) } = __FILE__;
	my $adder = sub {
		my $me = shift;
		my ($name, $kind, $target, $coercions) = @_;
		my $tc_class = 'Type::Tiny::' . ucfirst($kind);
		my $tc_obj   = $tc_class->new(
			name     => $name,
			library  => $me,
			$kind    => $target,
		);
		$types_hash{$kind}{$target} = $tc_obj;
		$me->add_type($tc_obj);
		if ($coercions) {
			$none ||= do { require Types::Standard; ~Types::Standard::Any() };
			$tc_obj->coercion->add_type_coercions($none, 'die()');
		}
	};
	my $getter = sub {
		my $me = shift;
		my ($kind, $target) = @_;
		$types_hash{$kind}{$target};
	};
	no strict 'refs';
	no warnings 'once';
	*{"$lib\::_mooxpress_add_type"} = $adder;
	*{"$lib\::get_type_for_package"} = $getter;
	${"$lib\::VERSION"} = $version if defined $version;
	${"$lib\::AUTHORITY"} = $authority if defined $authority;
}

sub make_type_for_role {
	my $builder = shift;
	my ($name, %opts) = @_;
	return unless $opts{'type_library'};
	$builder->croak("Roles ($name) cannnot extend things") if $opts{extends};
	$builder->_make_type($name, %opts, is_role => 1);
}

sub make_type_for_class {
	my $builder = shift;
	my ($name, %opts) = @_;
	return unless $opts{'type_library'};
	$builder->_make_type($name, %opts, is_role => 0);
}

sub _make_type {
	my $builder = shift;
	my ($name, %opts) = @_;
	my @isa = map $builder->qualify_name($_, $opts{prefix}),
		grep $_,
		$_merge->(@opts{qw/extends/});
	my $qname = $builder->qualify_name($name, $opts{prefix}, @isa);
	
	my $type_name = $opts{'type_name'} || $builder->type_name($qname, $opts{'prefix'});
	if ($opts{'type_library'}->can('_mooxpress_add_type')) {
		$opts{'type_library'}->_mooxpress_add_type(
			$type_name,
			$opts{is_role} ? 'role' : 'class',
			$qname,
			!!$opts{coerce},
		);
	}
	
	if (defined $opts{'subclass'} and not $opts{'is_role'}) {
		my @subclasses = $_expand->($opts{'subclass'});
		while (@subclasses) {
			my ($sc_name, $sc_opts) = splice @subclasses, 0, 2;
			my %opts_clone = %opts;
			delete $opts_clone{$_} for @delete_keys;
			$builder->make_type_for_class($sc_name, %opts_clone, extends => "::$qname", $_expand_simple->($sc_opts));
		}
	}
}

sub do_coercions_for_role {
	my $builder = shift;
	my ($name, %opts) = @_;
	$builder->_do_coercions($name, %opts, is_role => 1);
}

sub do_coercions_for_class {
	my $builder = shift;
	my ($name, %opts) = @_;
	$builder->_do_coercions($name, %opts, is_role => 0);
}

sub _do_coercions {
	my $builder = shift;
	my ($name, %opts) = @_;
	
	my @isa = map $builder->qualify_name($_, $opts{prefix}),
		grep $_,
		$_merge->(@opts{qw/extends/});
	my $qname = $builder->qualify_name($name, $opts{prefix}, @isa);
	
	if ($opts{coerce}) {
		my $method_installer = $opts{toolkit_install_methods} || ("install_methods");
		my @coercions = @{$opts{'coerce'} || []};
		
		while (@coercions) {
			my $type = shift @coercions;
			if (!ref $type and $opts{type_library}) {
				my $target = $builder->qualify_name($type, $opts{prefix});
				my $tc = $opts{type_library}->get_type_for_package(class => $target)
					|| $opts{type_library}->get_type_for_package(role => $target);
				$type = $tc if $tc;
			}
			if (!ref $type) {
				my $target = $builder->qualify_name($type, $opts{prefix});
				require Types::Standard;
				$type = Types::Standard::InstanceOf()->of($target);
			}
			my $method_name = shift @coercions;
			defined($method_name) && !ref($method_name)
				or $builder->croak("No method name found for coercion to $qname from $type");
			
			my $coderef;
			$coderef = shift @coercions if ref($coercions[0]) eq 'CODE';

			my $mytype;
			if ($opts{type_library}) {
				$mytype = $opts{type_library}->get_type_for_package($opts{'is_role'} ? 'role' : 'class', $qname);
			}
			
			if ($coderef) {
				$builder->$method_installer($qname, { $method_name => $coderef });
			}
			
			if ($mytype) {
				require B;
				$mytype->coercion->add_type_coercions($type, sprintf('%s->%s($_)', B::perlstring($qname), $method_name));
			}
		}
	}
	
	if (defined $opts{'subclass'} and not $opts{'is_role'}) {
		my @subclasses = $_expand->($opts{'subclass'});
		while (@subclasses) {
			my ($sc_name, $sc_opts) = splice @subclasses, 0, 2;
			my %opts_clone = %opts;
			delete $opts_clone{$_} for @delete_keys;
			$builder->do_coercions_for_class($sc_name, %opts_clone, extends => "::$qname", $_expand_simple->($sc_opts));
		}
	}
}

sub make_role {
	my $builder = shift;
	my ($name, %opts) = @_;
	$builder->_make_package($name, %opts, is_role => 1);
}

sub make_class {
	my $builder = shift;
	my ($name, %opts) = @_;
	$builder->_make_package($name, %opts, is_role => 0);
}

sub _make_package {
	my $builder = shift;
	my ($name, %opts) = @_;
	
	my @isa = map $builder->qualify_name($_, $opts{prefix}),
		grep $_,
		$_merge->(@opts{qw/extends/});
	my $qname = $builder->qualify_name($name, $opts{prefix}, @isa);
	
	if (!exists $opts{factory}) {
		my $tn = $builder->type_name($qname, $opts{prefix});
		$opts{factory} = 'new_' . lc $tn;
	}
	
	my $toolkit = {
		moo    => 'Moo',
		moose  => 'Moose',
		mouse  => 'Mouse',
	}->{lc $opts{toolkit}} || $opts{toolkit};
	
	if ($opts{is_role}) {
		eval "package $qname; use $toolkit\::Role; use namespace::autoclean; 1"
			or $builder->croak("Could not create package $qname: $@");
	}
	else {
		my $optthing = '';
		if ($toolkit eq 'Moo' and $INC{'Type/Tiny.pm'} and eval { require MooX::TypeTiny; 1 }) {
			$optthing = ' use MooX::TypeTiny;';
		}
		elsif ($toolkit eq 'Moose' and eval { require MooseX::XSAccessor; 1 }) {
			$optthing = ' use MooseX::XSAccessor;';
		}
		eval "package $qname; use $toolkit;$optthing use namespace::autoclean; 1"
			or $builder->croak("Could not create package $qname: $@");
	
		my $method  = $opts{toolkit_extend_class} || ("extend_class_".lc $toolkit);
		if (@isa) {
			$builder->$method($qname, \@isa);
		}
	}

	for my $var (qw/VERSION AUTHORITY/) {
		if (defined $opts{lc $var}) {
			no strict 'refs';
			no warnings 'once';
			${"$qname\::$var"} = $opts{lc $var};
		}
	}
	
	{
		my $method = $opts{toolkit_apply_roles} || ("apply_roles_".lc $toolkit);
		my @roles = map $builder->qualify_name($_, $opts{prefix}),
			grep $_,
			$_merge->(@opts{qw/with/});
		if (@roles) {
			$builder->$method($qname, \@roles);
		}
	}
	
	my $method_installer = $opts{toolkit_install_methods} || ("install_methods");
	{
		my %methods = map $_expand_simple->($_),
			grep $_,
			@opts{qw/can/};
		if (keys %methods) {
			$builder->$method_installer($qname, \%methods);
		}
	}
	
	{
		my $method = $opts{toolkit_install_methods} || ("install_constants");
		my %methods = map $_expand_simple->($_),
			grep $_,
			@opts{qw/constant/};
		if (keys %methods) {
			$builder->$method($qname, \%methods);
		}
	}
	
	{
		my $method = $opts{toolkit_make_attribute} || ("make_attribute_".lc $toolkit);
		my @attrs = $_merge->(@opts{qw/has/});
		while (@attrs) {
			my ($attrname, $attrspec) = splice @attrs, 0, 2;
			
			my %spec_hints;
			if ($attrname =~ /^(\+?)(\$|\%|\@)(.+)$/) {
				require Types::Standard;
				require Types::TypeTiny;
				$spec_hints{isa} ||= {
					'$' => ~(Types::Standard::ArrayRef()|Types::Standard::HashRef()),
					'@' => Types::TypeTiny::ArrayLike(),
					'%' => Types::TypeTiny::HashLike(),
				}->{$2};
				no warnings 'uninitialized';
				$attrname = $1.$3; # allow plus before sigil
			}
			if ($attrname =~ /^(.+)\!$/) {
				$spec_hints{required} = 1;
				$attrname = $1;
			}
			
			(my $buildername = "_build_$attrname") =~ s/\+//;
			(my $clearername = ($attrname =~ /^_/ ? "_clear$attrname" : "clear_$attrname")) =~ s/\+//;
			
			my %spec =
				ref($attrspec) eq 'CODE' ? (is => 'rw', lazy => 1, builder => $attrspec, clearer => $clearername) :
				blessed($attrspec) && $attrspec->can('check') ? (is => 'rw', isa => $attrspec) :
				$_expand_simple->($attrspec);
			if (ref $spec{builder} eq 'CODE') {
				my $code = delete $spec{builder};
				$spec{builder} = $buildername;
				$builder->$method_installer($qname, { $buildername => $code });
			}
			
			%spec = (%spec_hints, %spec);
			$spec{is} ||= 'rw';
			
			if ($spec{does}) {
				my $target = $builder->qualify_name(delete($spec{does}), $opts{prefix});
				$spec{isa} ||= do {
					$opts{type_library}
						? $opts{type_library}->get_type_for_package(role => $target)
						: undef;
				};
				$spec{isa} ||= do {
					require Types::Standard;
					Types::Standard::ConsumerOf()->of($target);
				};
			}
			if ($spec{isa} && !ref $spec{isa}) {
				my $target = $builder->qualify_name(delete($spec{isa}), $opts{prefix});
				$spec{isa} ||= do {
					$opts{type_library}
						? $opts{type_library}->get_type_for_package(class => $target)
						: undef;
				};
				$spec{isa} ||= do {
					require Types::Standard;
					Types::Standard::InstanceOf()->of($target);
				};
			}
			if ($spec{enum}) {
				require Types::Standard;
				$spec{isa} = Types::Standard::Enum()->of(@{delete $spec{enum}});
			}
			
			if (ref $spec{isa} && !exists $spec{coerce} && $spec{isa}->has_coercion) {
				$spec{coerce} = 1;
			}
			
			$builder->$method($qname, $attrname, \%spec);
		}
	}
	
	for my $modifier (qw(before after around)) {
		my $method = $opts{toolkit_modify_methods} || ("modify_method_".lc $toolkit);
		my @methods = map $_expand->($_), grep $_, $opts{$modifier};
		while (@methods) {
			my ($method_name, $coderef) = splice(@methods, 0, 2);
			$builder->$method($qname, $modifier, $method_name, $coderef);
		}
	}
	
	unless ($opts{is_role}) {
		
		if ($toolkit eq 'Moose' && !$opts{'mutable'}) {
			require Moose::Util;
			Moose::Util::find_meta($qname)->make_immutable;
		}
		
		if (defined $opts{'factory'}) {
			if (defined $opts{'factory_package'} or not exists $opts{'factory_package'}) {
				my $factoryname = $builder->qualify_name($opts{'factory'}, $opts{'factory_package'}||$opts{'caller'});
				eval "sub $factoryname { shift; '$qname'->new(\@_) }; 1"
					or $builder->croak("Couldn't create factory $factoryname: $@");
			}
		}
		
		if (defined $opts{'subclass'}) {
			my @subclasses = $_expand->($opts{'subclass'});
			while (@subclasses) {
				my ($sc_name, $sc_opts) = splice @subclasses, 0, 2;
				my %opts_clone = %opts;
				delete $opts_clone{$_} for @delete_keys;
				$builder->make_class($sc_name, %opts_clone, extends => "::$qname", $_expand_simple->($sc_opts));
			}
		}
	}
	
	if (ref $opts{'end'}) {
		$opts{'end'}->($qname, $opts{is_role} ? 'role' : 'class');
	}
	
	if ($opts{type_library}) {
		my $mytype = $opts{type_library}->get_type_for_package($opts{'is_role'} ? 'role' : 'class', $qname);
		$mytype->coercion->freeze if $mytype;
	}
	
	return $qname;
}

my %_cached_moo_helper;
sub _get_moo_helper {
	my $builder = shift;
	my ($package, $helpername) = @_;
	return $_cached_moo_helper{"$package\::$helpername"}
		if $_cached_moo_helper{"$package\::$helpername"};
	die unless $helpername =~ /^(has|with|extends|around|before|after)$/;
	my $tracker = ($INC{'Moo/Role.pm'} && 'Moo::Role'->is_role($package))
		? $Moo::Role::INFO{$package}{exports}
		: $Moo::MAKERS{$package}{exports};
	if (ref $tracker) {
		return ($_cached_moo_helper{"$package\::$helpername"} = $tracker->{$helpername});
	}
	# I hate this...
	$_cached_moo_helper{"$package\::$helpername"} =
		eval sprintf('do { package %s; use Moo; my $coderef = \&%s; no Moo; $coderef };', $package, $helpername);
}

sub make_attribute_moo {
	my $builder = shift;
	my ($class, $attribute, $spec) = @_;
	my $helper = $builder->_get_moo_helper($class, 'has');
	$helper->($attribute, %$spec);
}

sub make_attribute_moose {
	my $builder = shift;
	my ($class, $attribute, $spec) = @_;
	require Moose::Util;
	(Moose::Util::find_meta($class) or $class->meta)->add_attribute($attribute, $spec);
}

sub make_attribute_mouse {
	my $builder = shift;
	my ($class, $attribute, $spec) = @_;
	require Mouse::Util;
	(Mouse::Util::find_meta($class) or $class->meta)->add_attribute($attribute, $spec);
}

sub extend_class_moo {
	my $builder = shift;
	my ($class, $isa) = @_;
	my $helper = $builder->_get_moo_helper($class, 'extends');
	$helper->(@$isa);
}

sub extend_class_moose {
	my $builder = shift;
	my ($class, $isa) = @_;
	require Moose::Util;
	(Moose::Util::find_meta($class) or $class->meta)->superclasses(@$isa);
}

sub extend_class_mouse {
	my $builder = shift;
	my ($class, $isa) = @_;
	require Mouse::Util;
	(Mouse::Util::find_meta($class) or $class->meta)->superclasses(@$isa);
}

sub apply_roles_moo {
	my $builder = shift;
	my ($class, $roles) = @_;
	my $helper = $builder->_get_moo_helper($class, 'with');
	$helper->(@$roles);
}

sub apply_roles_moose {
	my $builder = shift;
	my ($class, $roles) = @_;
	require Moose::Util;
	Moose::Util::ensure_all_roles($class, @$roles);
}

sub apply_roles_mouse {
	my $builder = shift;
	my ($class, $roles) = @_;
	require Mouse::Util;
	# this can double-apply roles? :(
	Mouse::Util::apply_all_roles($class, @$roles);
}

sub install_methods {
	my $builder = shift;
	my ($class, $methods) = @_;
	for my $name (sort keys %$methods) {
		no strict 'refs';
		my $coderef = $methods->{$name};
		eval "package $class; sub $name :method { goto \$coderef }; 1"
			or $builder->croak("Could not create method $name in package $class: $@");
	}
}

sub install_constants {
	my $builder = shift;
	my ($class, $methods) = @_;
	for my $name (sort keys %$methods) {
		no strict 'refs';
		my $value = $methods->{$name};
		if (defined $value && !ref $value) {
			require B;
			my $stringy = B::perlstring($value);
			eval "package $class; sub $name () { $stringy }; 1"
				or $builder->croak("Could not create constant $name in package $class: $@");
		}
		else {
			eval "package $class; sub $name () { \$value }; 1"
				or $builder->croak("Could not create constant $name in package $class: $@");
		}
	}
}

sub modify_method_moo {
	my $builder = shift;
	my ($class, $modifier, $method_name, $coderef) = @_;
	my $helper = $builder->_get_moo_helper($class, $modifier);
	$helper->($method_name, $coderef);
}

sub modify_method_moose {
	my $builder = shift;
	my ($class, $modifier, $method_name, $coderef) = @_;
	my $m = "add_$modifier\_method_modifier";
	require Moose::Util;
	(Moose::Util::find_meta($class) or $class->meta)->$m($method_name, $coderef);
}

sub modify_method_mouse {
	my $builder = shift;
	my ($class, $modifier, $method_name, $coderef) = @_;
	my $m = "add_$modifier\_method_modifier";
	require Mouse::Util;
	(Mouse::Util::find_meta($class) or $class->meta)->$m($method_name, $coderef);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooX::Press - quickly create a bunch of Moo/Moose/Mouse classes and roles

=head1 SYNOPSIS

  package MyApp;
  use Types::Standard qw(Str Num);
  use MooX::Press (
    role => [
      'Livestock',
      'Pet',
      'Milkable' => {
        can => [
          'milk' => sub { print "giving milk\n"; },
        ],
      },
    ],
    class => [
      'Animal' => {
        has => [
          'name'   => Str,
          'colour',
          'age'    => Num,
          'status' => { enum => ['alive', 'dead'], default => 'alive' },
        ],
        subclass => [
          'Panda',
          'Cat'  => { with => ['Pet'] },
          'Dog'  => { with => ['Pet'] },
          'Cow'  => { with => ['Livestock', 'Milkable'] },
          'Pig'  => { with => ['Livestock'] },
        ],
      },
    ],
  );

Using your classes:

  use MyApp;
  
  my $kitty = MyApp->new_cat(name => "Grey", status => "alive");
  # or:       MyApp::Cat->new(name => "Grey", status => "alive");
  
  MyApp->new_cow(name => "Daisy")->milk();

I realize this is a longer synopsis than most CPAN modules give, but
considering it sets up six classes and three roles with some attributes
and methods, applies the roles to the classes, and creates a type library
with nine types in it, it's pretty concise.

=head1 DESCRIPTION

L<MooX::Press> (pronounced "Moo Express") is a quick way of creating a bunch
of simple Moo classes and roles at once without needing to create separate
Perl modules for each class and each role, and without needing to add a bunch
of boilerplate to each file.

It also supports Moose and Mouse, though Moo classes and roles play nicely
with Moose (and to a certain extent with Mouse) anyway.

=head2 Import Options

MooX::Press is called like:

  use MooX::Press %import_opts;

The following options are supported. To make these easier to remember, options
follow the convention of using lower-case singular, and reusing keywords from
Perl and Moo/Moose/Mouse when possible.

=over

=item C<< class >> I<< (OptList) >>

This is the list of classes to create as an optlist. An optlist is an arrayref
of strings, where each string is optionally followed by a reference.

  [ "A", "B", "C", \%opt_for_C, "D", "E", \%opts_for_E, "F" ]

In particular, for the class optlist the references should be hashrefs of
class options (see L</Class Options>), though key-value pair arrayrefs are
also accepted.

=item C<< role >> I<< (OptList) >>

This is the list of roles to create, structured almost the same as the optlist
for classes, but see L</Role Options>.

=item C<< toolkit >> I<< (Str) >>

The strings "Moo", "Moose", or "Mouse" are accepted and instruct MooX::Press
to use your favourite OO toolkit. "Moo" is the default.

=item C<< version >> I<< (Num) >>

This has nothing to do with the version of MooX::Press you are using.
It sets the C<< our $VERSION >> variable for the classes and roles being
generated.

=item C<< authority >> I<< (Str) >>

This sets the C<< our $AUTHORITY >> variable for the classes and roles being
generated.

C<version> and C<authority> will be copied from the caller if they are not set,
but you can set them to undef explicitly if you want to avoid that.

=item C<< prefix >> I<< (Str|Undef) >>

A namespace prefix for MooX::Press to put all your classes into. If MooX::Press
is told to create a class "Animal" and C<prefix> is set to "MyApp::OO", then
it will create a class called "MyApp::OO::Animal".

This is optional and defaults to the caller. If you wish to have no prefix,
then pass an explicit C<< prefix => undef >> option.

You can bypass the prefix for a specific class or a specific role using a
leading double colon, like "::Animal".

=item C<< factory_package >> I<< (Str|Undef) >>

A package name to install methods like the C<new_cat> and C<new_cow> methods
in L</SYNOPSIS>.

This defaults to caller, but may be explicitly set to undef to suppress the
creation of such methods.

=item C<< type_library >> I<< (Str|Undef) >>

MooX::Press will automatically create a L<Type::Library>-based type library
with type constraints for all your classes and roles. It will be named using
your prefix followed by "::Types".

You can specify a new name or explicitly set to undef to suppress this
behaviour, but a lot of the coercion features of MooX::Press rely on there
being a type library.

MooX::Press will create a get_type_for_package method that allows you to
do this:

  MyApp::Types->get_type_for_package(class => "MyApp::Animal");

MooX::Press will mark "MyApp/Types.pm" as loaded in %INC, so you can do
things like:

  use MyApp::Types qw(Animal);

And it won't complain about "MyApp/Types.pm" not being found.

=item C<< caller >> I<< (Str) >>

MooX::Press determines some things based on which package called it. If you
are wrapping MooX::Press, you can fake the caller by passing it as an option.

=item C<< end >> I<< (CodeRef) >>

After creating each class or role, this coderef will be called. It will be
passed two parameters; the fully-qualified package name of the class or role,
plus the string "class" or "role" as appropriate.

Optional; defaults to nothing.

=item C<< mutable >> I<< (Bool) >>

Boolean to indicate that classes should be left mutable after creating them
rather than making them immutable. Constructors for mutable classes are
considerably slower than for immutable classes, so this is usually a bad
idea.

Only supported for Moose. Unnecessary for Moo anyway. Defaults to false.

=back

=head3 Class Options

Each class in the list of classes can be followed by a hashref of
options:

  use MooX::Press (
    class => [
      'Foo' => \%options_for_foo,
      'Bar' => \%options_for_bar,
    ],
  );

The following class options are supported.

=over

=item C<< extends >> I<< (Str|ArrayRef[Str]) >>

The parent class for this class.

The prefix is automatically added. Include a leading "::" if you
don't want the prefix to be added.

Multiple inheritance is supported.

=item C<< with >> I<< (ArrayRef[Str]) >>

Roles for this class to consume.

The prefix is automatically added. Include a leading "::" if you don't
want the prefix to be added.

=item C<< has >> I<< (OptList) >>

The list of attributes to add to the class as an optlist.

The strings are the names of the attributes, but these strings may be
"decorated" with sigils and suffixes:

=over

=item C<< $foo >>

Creates an attribute "foo" intended to hold a single value.
This adds a type constraint forbidding arrayrefs and hashrefs
but allowing any other value, including undef, strings, numbers,
and any other reference.

=item C<< @foo >>

Creates an attribute "foo" intended to hold a list of values.
This adds a type constraint allowing arrayrefs or objects
overloading C<< @{} >>.

=item C<< %foo >>

Creates an attribute "foo" intended to hold a collection of key-value
pairs. This adds a type constraint allowing hashrefs or objects
overloading C<< %{} >>.

=item C<< foo! >>

Creates an attribute "foo" which will be required by the constructor.

=back

An attribute can have both a sigil and a suffix.

The references in the optlist may be attribute specification hashrefs,
type constraint objects, or builder coderefs.

  # These mean the same thing...
  "name!" => Str,
  "name"  => { is => "rw", required => 1, isa => Str },

  # These mean the same thing...
  "age"   => sub { return 0 },
  "age"   => {
    is         => "rw",
    lazy       => 1,
    builder    => sub { return 0 },
    clearer    => "clear_age",
  },

Type constraints can be any blessed object supported by the toolkit. For
Moo, use L<Type::Tiny>. For Moose, use L<Type::Tiny>, L<MooseX::Types>,
or L<Specio>. For Mouse, use L<Type::Tiny> or L<MouseX::Types>.

Builder coderefs are automatically installed as methods like
"YourPrefix::YourClass::_build_age()".

For details of the hashrefs, see L</Attribute Specifications>.

=item C<< can >> I<< (HashRef[CodeRef]) >>

A hashref of coderefs to install into the package.

  package MyApp;
  use MooX::Press (
    class => [
      'Foo' => {
         can => {
           'bar' => sub { print "in bar" },
         },
       },
    ],
  );
  
  package main;
  MyApp->new_foo()->bar();

As an alternative, you can do this to prevent your import from getting
cluttered with coderefs. Which you choose depends a lot on stylistic
preference.

  package MyApp;
  use MooX::Press (
    class => ['Foo'],
  );
  
  package MyApp::Foo;
  sub bar { print "in bar" },
  
  package main;
  MyApp->new_foo()->bar();

=item C<< constant >> I<< (HashRef[Item]) >>

A hashref of scalar constants to define in the package.

  package MyApp;
  use MooX::Press (
    class => [
      'Foo' => {
         constant => {
           'BAR' => 42,
         },
       },
    ],
  );
  
  package main;
  print MyApp::Foo::BAR, "\n";
  print MyApp->new_foo->BAR, "\n";

=item C<< around >> I<< (ArrayRef|HashRef) >>

=item C<< before >> I<< (ArrayRef|HashRef) >>

=item C<< after >> I<< (ArrayRef|HashRef) >>

Installs method modifiers.

  package MyApp;
  use MooX::Press (
    role => [
      'Loud' => {
        around => [
          'greeting' => sub {
            my $orig = shift;
            my $self = shift;
            return uc( $self->$orig(@_) );
          },
        ],
      }
    ],
    class => [
      'Person' => {
        can => {
          'greeting' => sub { "hello" },
        }
        subclass => [
          'LoudPerson' => { with => 'Loud' },
        ],
      },
    ],
  );
  
  package main;
  print MyApp::LoudPerson->new->greeting, "\n";  # prints "HELLO"

=item C<< coerce >> I<< (ArrayRef) >>

When creating a class or role "Foo", MooX::Press will also create a
L<Type::Tiny::Class> or L<Type::Tiny::Role> called "Foo". The C<coerce>
option allows you to add coercions to that type constraint. Coercions
are called as methods on the class or role. This is perhaps best
explained with an example:

  package MyApp;
  use Types::Standard qw(Str);
  use MooX::Press (
    class => [
      'Person' => {
        has    => [ 'name!' => Str ],
        can    => {
          'from_name' => sub {
            my ($class, $name) = @_;
            return $class->new(name => $name);
          },
        },
        coerce => [
          Str, 'from_name',
        ],
      },
      'Company' => {
        has    => [ 'name!' => Str, 'owner!' => { isa => 'Person' } ],
      },
    ],
  );

This looks simple but it's like the swan, graceful above the surface of the
water, legs paddling frantically below.

It creates a class called "MyApp::Person" with a "name" attribute, so you can
do this kind of thing:

  my $bob = MyApp::Person->new(name => "Bob");
  my $bob = MyApp->new_person(name => "Bob");

As you can see from the C<can> option, it also creates a method "from_name"
which can be used like this:

  my $bob = MyApp::Person->from_name("Bob");

But here's where coercions come in. It also creates a type constraint
called "Person" in "MyApp::Types" and adds a coercion from the C<Str> type.
The coercion will just call the "from_name" method.

Then when the "MyApp::Company" class is created and the "owner" attribute
is being set up, MooX::Press knows about the coercion from Str, and will
set up coercion for that attribute.

  # So this should just work...
  my $acme = MyApp->new_company(name => "Acme Inc", owner => "Bob");
  print $acme->owner->name, "\n";

Now that's out of the way, the exact structure for the arrayref of coercions
can be explained. It is essentially a list of type-method pairs.

The type may be either a blessed type constraint object (L<Type::Tiny>, etc)
or it may be a class or role name that is being set up by MooX::Press, in
which case it will have the prefix added, etc.

The method is a string containing the method name to perform the coercion.

This may optionally be followed by coderef to install as the method. The
following two examples are equivalent:

  use MooX::Press (
    class => [
      'Person' => {
        has    => [ 'name!' => Str ],
        can    => {
          'from_name' => sub {
            my ($class, $name) = @_;
            return $class->new(name => $name);
          },
        },
        coerce => [
          Str, 'from_name',
        ],
      },
    ],
  );

  use MooX::Press (
    class => [
      'Person' => {
        has    => [ 'name!' => Str ],
        coerce => [
          Str, 'from_name' => sub {
            my ($class, $name) = @_;
            return $class->new(name => $name);
          },
        ],
      },
    ],
  );

In the second example, you can see the C<can> option to install the "from_name"
method has been dropped and the coderef put into C<coerce> instead.

In case it's not obvious, I suppose it's worth explicitly stating that it's
possible to have coercions from many different types.

  use MooX::Press (
    class => [
      'Foo::Bar' => {
        coerce => [
          Str,        'from_string', sub { ... },
          ArrayRef,   'from_array',  sub { ... },
          HashRef,    'from_hash',   sub { ... },
          'Foo::Baz', 'from_foobaz', sub { ... },
        ],
      },
      'Foo::Baz',
    ],
  );

You should generally order the coercions from most specific to least
specific. If you list "Num" before "Int", "Int" will never be used
because all integers are numbers.

There is no automatic inheritance for coercions because that does not make
sense. If C<< Mammal->from_string($str) >> is a coercion returning a
"Mammal" object, and "Person" is a subclass of "Mammal", then there's
no way for MooX::Press to ensure that when C<< Person->from_string($str) >>
is called, it will return a "Person" object and not some other kind of
mammal. If you want "Person" to have a coercion, define the coercion in the
"Person" class and don't rely on it being inherited from "Mammal".

=item C<< subclass >> I<< (OptList) >>

Set up subclasses of this class. This accepts an optlist like the class list.
It allows subclasses to be nested as deep as you like:

  package MyApp;
  use MooX::Press (
    class => [
      'Animal' => {
         has      => ['name!'],
         subclass => [
           'Fish',
           'Bird',
           'Mammal' => {
              can      => { 'lactate' => sub { ... } },
              subclass => [
                'Cat',
                'Dog',
                'Primate' => {
                  subclass => ['Monkey', 'Gorilla', 'Human'],
                },
              ],
           },
         ],
       },
    ];
  );
  
  package main;
  my $uncle = MyApp->new_human(name => "Bob");
  $uncle->isa('MyApp::Human');    # true
  $uncle->isa('MyApp::Primate');  # true
  $uncle->isa('MyApp::Mammal');   # true
  $uncle->isa('MyApp::Animal');   # true
  $uncle->isa('MyApp::Bird');     # false
  $uncle->can('lactate');         # eww, but true

We just defined a nested heirarchy with ten classes there!

Subclasses can be named with a leading "+" to tell them to use their parent
class name as a prefix. So, in the example above, if you'd called your
subclasses "+Mammal", "+Dog", etc, you'd end up with packages like
"MyApp::Animal::Mammal::Dog". (In cases of multiple inheritance, it uses
C<< $ISA[0] >>.)

=item C<< factory >> I<< (Str) >>

This is the name for the method installed into the factory package.
So for class "Cat", it might be "new_cat".

The default is the class name (excluding the prefix), lowercased,
with double colons replaced by single underscores, and
with "new_" added in front. To suppress the creation
of this method, set C<factory> to an explicit undef.

=item C<< type_name >> I<< (Str) >>

The name for the type being installed into the type library.

The default is the class name (excluding the prefix), with
double colons replaced by single underscores.

This:

  use MooX::Press prefix => "ABC::XYZ", class => ["Foo::Bar"];

Will create class "ABC::XYZ::Foo::Bar", a factory method
C<< ABC::XYZ->new_foo_bar() >>, and a type constraint
"Foo_Bar" in type library "ABC::XYZ::Types".

=item C<< toolkit >> I<< (Str) >>

Override toolkit choice for this class and any child classes.

=item C<< version >> I<< (Num) >>

Override version number for this class and any child classes.

=item C<< authority >> I<< (Str) >>

Override authority for this class and any child classes.

See L</Import Options>.

=item C<< prefix >> I<< (Str) >>

Override namespace prefix for this class and any child classes.

See L</Import Options>.

=item C<< factory_package >> I<< (Str) >>

Override factory_package for this class and any child classes.

See L</Import Options>.

=item C<< mutable >> I<< (Bool) >>

Override mutability for this class and any child classes.

See L</Import Options>.

=item C<< end >> I<< (CodeRef) >>

Override C<end> for this class and any child classes.

See L</Import Options>.

=back

=head3 Role Options

Options for roles are largely the same as for classes with the following
exceptions:

=over

=item C<< extends >> I<< (Any) >>

This option is disallowed.

=item C<< can >> I<< (HashRef[CodeRef]) >>

The alternative style for defining methods may cause problems with the order
in which things happen. Because C<< use MooX::Press >> happens at compile time,
the following might not do what you expect:

  package MyApp;
  use MooX::Press (
    role   => ["MyRole"],
    class  => ["MyClass" => { with => "MyRole" }],
  );
  
  package MyApp::MyRole;
  sub my_function { ... }

The "my_function" will not be copied into "MyApp::MyClass" because at the
time the class is constructed, "my_function" doesn't yet exist within the
role "MyApp::MyRole".

You can combat this by changing the order you define things in:

  package MyApp::MyRole;
  sub my_function { ... }
  
  package MyApp;
  use MooX::Press (
    role   => ["MyRole"],
    class  => ["MyClass" => { with => "MyRole" }],
  );

If you don't like having method definitions "above" MooX::Press in your file,
then you can move them out into a module.

  # MyApp/Methods.pm
  #
  package MyApp::MyRole;
  sub my_function { ... }

  # MyApp.pm
  #
  package MyApp;
  use MyApp::Methods (); # load extra methods
  use MooX::Press (
    role   => ["MyRole"],
    class  => ["MyClass" => { with => "MyRole" }],
  );

Or force MooX::Press to happen at runtime instead of compile time.

  package MyApp;
  require MooX::Press;
  import MooX::Press (
    role   => ["MyRole"],
    class  => ["MyClass" => { with => "MyRole" }],
  );
  
  package MyApp::MyRole;
  sub my_function { ... }
  
=item C<< subclass >> I<< (Any) >>

This option is silently ignored.

=item C<< factory >> I<< (Any) >>

This option is silently ignored.

=item C<< mutable >> I<< (Any) >>

This option is silently ignored.

=back

=head3 Attribute Specifications

Attribute specifications are mostly just passed to the OO toolkit unchanged,
somewhat like:

  has $attribute_name => %attribute_spec;

So whatever specifications (C<required>, C<trigger>, C<coerce>, etc) the
underlying toolkit supports should be supported.

The following are exceptions:

=over

=item C<< is >> I<< (Str) >>

This is optional rather than being required, and defaults to "rw".
(Yes, I prefer "ro" generally, but whatever.)

=item C<< isa >> I<< (Str|Object) >>

When the type constraint is a string, it is B<always> assumed to be a class
name and your application's namespace prefix is added. So
C<< isa => "HashRef" >> doesn't mean what you think it means. It means
an object blessed into the "YourApp::HashRef" class.

Use blessed type constraint objects, such as those from L<Types::Standard>.

=item C<< coerce >> I<< (Bool) >>

MooX::Press automatically implies C<< coerce => 1 >> when you give a
type constraint that has a coercion. If you don't want coercion then
explicitly provide C<< coerce => 0 >>.

=item C<< does >> I<< (Str) >>

Similarly, these will be given your namespace prefix.

=item C<< enum >> I<< (ArrayRef[Str]) >>

This is a cute shortcut for an enum type constraint.

  # These mean the same...
  enum => ['foo', 'bar'],
  isa  => Types::Standard::Enum['foo', 'bar'],

=back

=head2 Optimization Features

MooX::Press will automatically load L<MooX::TypeTiny> if it's installed,
which optimizes how Type::Tiny constraints and coercions are inlined into
Moo constructors. This is only used for Moo classes.

MooX::Press will automatically load L<MooseX::XSAccessor> if it's installed,
which speeds up some Moose accessors. This is only used for Moose classes.

=head2 Subclassing MooX::Press

All the internals of MooX::Press are called as methods, which should make
subclassing it possible.

  package MyX::Press;
  use parent 'MooX::Press';
  use Class::Method::Modifiers;
  
  around make_class => sub {
    my $orig = shift;
    my $self = shift;
    my ($name, %opts) = @_;
    ## Alter %opts here
    my $qname = $self->$orig($name, %opts);
    ## Maybe do something to the returned class
    return $qname;
  };

It is beyond the scope of this documentation to fully describe all the methods
you could potentially override, but here is a quick summary of some that may
be useful.

=over

=item C<< import(%opts|\%opts) >>

=item C<< qualify_name($name, $prefix) >>

=item C<< croak($error) >>

=item C<< prepare_type_library($qualified_name) >>

=item C<< make_type_for_role($name, %opts) >>

=item C<< make_type_for_class($name, %opts) >>

=item C<< make_role($name, %opts) >>

=item C<< make_class($name, %opts) >>

=item C<< install_methods($qualified_name, \%methods) >>

=item C<< install_constants($qualified_name, \%values) >>

=back

=head1 FAQ

This is a new module so I haven't had any questions about it yet, let alone
any frequently asked ones, but I will anticipate some.

=head2 Why doesn't MooX::Press automatically import strict and warnings for me?

Your MooX::Press import will typically contain a lot of strings, maybe some
as barewords, some coderefs, etc. You should manually import strict and
warnings B<before> importing MooX::Press to ensure all of that is covered
by strictures.

=head2 Are you insane?

Quite possibly.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Press>.

=head1 SEE ALSO

L<Moo>, L<MooX::Struct>, L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

