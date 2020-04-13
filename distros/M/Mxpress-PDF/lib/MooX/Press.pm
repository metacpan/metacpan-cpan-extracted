use 5.008008;
use strict;
use warnings;

package MooX::Press;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.048';

use Types::Standard 1.008003 -is, -types;
use Types::TypeTiny qw(ArrayLike HashLike);
use Exporter::Tiny qw(mkopt);
use namespace::autoclean;

# Options not to carry up into subclasses;
# mostly because subclasses inherit behaviour anyway.
my @delete_keys = qw(
	subclass
	has
	with
	extends
	overload
	factory
	coerce
	around
	before
	after
	type_name
	can
	type_library_can
	factory_package_can
	abstract
);

my $_handle_list = sub {
	my ($thing) = @_;
	return ()
		unless defined $thing;
	return $thing
		if is_Str $thing;
	return %$thing
		if is_HashRef $thing;
	return @$thing
		if is_ArrayRef $thing;
	goto $thing
		if is_CodeRef $thing;
	die "Unexepcted thing; got $thing";
};

my $_handle_list_add_nulls = sub {
	my ($thing) = @_;
	return map @$_, @{mkopt $thing}
		if is_ArrayRef $thing;
	goto $_handle_list;
};

my %_cached_moo_helper;

sub _apply_default_options {
	my $builder = shift;
	my $opts = $_[0];
	
	$opts->{toolkit} ||= $ENV{'PERL_MOOX_PRESS_TOOLKIT'} || 'Moo';
	
	$opts->{version} = $opts->{caller}->VERSION
		unless exists $opts->{version};
		
	$opts->{authority} = do { no strict 'refs'; no warnings 'once'; ${$opts->{caller}."::AUTHORITY"} }
		unless exists $opts->{authority};
	
	unless (exists $opts->{prefix}) {
		$opts->{prefix} = $opts->{caller};
		if ($opts->{prefix} eq 'main') {
			$opts->{prefix} = undef;
		}
	}
	
	my $no_warn = exists($opts->{factory_package});
	
	$opts->{factory_package} = defined($opts->{prefix}) ? $opts->{prefix} : 'Local'
		unless exists $opts->{factory_package};
	
	if (!$no_warn and defined($opts->{factory_package}) and $opts->{factory_package} eq 'Local') {
		require FindBin;
		if ($FindBin::Script ne '-e') {
			require Carp;
			Carp::carp('Using "Local" as factory; please set prefix or factory_package');
		}
	}
	
	unless (exists $opts->{type_library}) {
		$opts->{type_library} = $builder->qualify_name('Types', $opts->{prefix});
	}
}

sub import {
	my $builder = shift;
	my $caller  = caller;
	my %opts    = @_==1 ? shift->$_handle_list_add_nulls : @_;
	$opts{caller} ||= $caller;
	
	$builder->_apply_default_options(\%opts);
	$builder->munge_options(\%opts);
	
	my @role_generators  = @{ mkopt $opts{role_generator} };
	my @class_generators = @{ mkopt $opts{class_generator} };
	my @roles            = @{ mkopt $opts{role} };
	my @classes          = @{ mkopt $opts{class} };
	
	# Canonicalize these now, saves repeatedly doing it later!
	for my $pkg (@role_generators) {
		if (is_CodeRef($pkg->[1])
		or  is_HashRef($pkg->[1]) && is_CodeRef($pkg->[1]{code})) {
			$pkg->[1] = { generator => $pkg->[1] };
		}
		$pkg->[1] = { $pkg->[1]->$_handle_list };
		$builder->munge_role_generator_options($pkg->[1], \%opts);
	}
	for my $pkg (@class_generators) {
		if (is_CodeRef($pkg->[1])
		or  is_HashRef($pkg->[1]) && is_CodeRef($pkg->[1]{code})) {
			$pkg->[1] = { generator => $pkg->[1] };
		}
		$pkg->[1] = { $pkg->[1]->$_handle_list };
		$builder->munge_class_generator_options($pkg->[1], \%opts);
	}
	for my $pkg (@roles) {
		$pkg->[1] = { $pkg->[1]->$_handle_list };
		# qualify names in role list early
		$pkg->[0] = '::' . $builder->qualify_name($pkg->[0], exists($pkg->[1]{prefix})?$pkg->[1]{prefix}:$opts{prefix});
		$builder->munge_role_options($pkg->[1], \%opts);
	}
	for my $pkg (@classes) {
		$pkg->[1] = { $pkg->[1]->$_handle_list };
		if (defined $pkg->[1]{extends} and not ref $pkg->[1]{extends}) {
			$pkg->[1]{extends} = [$pkg->[1]{extends}];
		}
		$builder->munge_class_options($pkg->[1], \%opts);
	}

	if ($opts{type_library}) {
		$builder->prepare_type_library($opts{type_library}, %opts);
		# no type for role generators
		for my $pkg (@class_generators) {
			$builder->make_type_for_class_generator($pkg->[0], %opts, %{$pkg->[1]});
		}
		for my $pkg (@roles) {
			$builder->make_type_for_role($pkg->[0], %opts, %{$pkg->[1]});
		}
		for my $pkg (@classes) {
			$builder->make_type_for_class($pkg->[0], %opts, %{$pkg->[1]});
		}
	}
	
	my $reg;
	if ($opts{factory_package}) {
		require Type::Registry;
		$reg = 'Type::Registry'->for_class($opts{factory_package});
		$reg->add_types($_) for (
			$opts{type_library},
			qw( Types::Standard Types::Common::Numeric Types::Common::String Types::TypeTiny ),
		);
	}
	
	{
		my %methods;
		my $method_installer = $opts{toolkit_install_methods} || ("install_methods");
		
		%methods = delete($opts{factory_package_can})->$_handle_list_add_nulls;
		$methods{qualify} ||= sub { $builder->qualify($_[1], $opts{'prefix'}) };
		$builder->$method_installer($opts{'factory_package'}||$opts{'caller'}, \%methods) if keys %methods;
		
		%methods = delete($opts{type_library_can})->$_handle_list_add_nulls;
		$builder->$method_installer($opts{type_library}, \%methods) if keys %methods;
	}
	
	for my $pkg (@roles) {
		$builder->do_coercions_for_role($pkg->[0], %opts, reg => $reg, %{$pkg->[1]});
	}
	for my $pkg (@classes) {
		$builder->do_coercions_for_class($pkg->[0], %opts, reg => $reg, %{$pkg->[1]});
	}
	
	for my $pkg (@role_generators) {
		$builder->make_role_generator($pkg->[0], %opts, %{$pkg->[1]});
	}
	for my $pkg (@class_generators) {
		$builder->make_class_generator($pkg->[0], %opts, %{$pkg->[1]});
	}
	for my $pkg (@roles) {
		$builder->make_role($pkg->[0], _parent_opts => \%opts, _roles => \@roles, %opts, %{$pkg->[1]});
	}
	for my $pkg (@classes) {
		$builder->make_class($pkg->[0], _parent_opts => \%opts, _roles => \@roles, %opts, %{$pkg->[1]});
	}
	
	%_cached_moo_helper = ();  # cleanups
}

sub munge_options {
	my $builder = shift;
	my ($opts) = @_;
	for my $key (sort keys %$opts) {
		if ($key =~ /^(class|role|class_generator|role_generator):([^:].*)$/) {
			my ($kind, $pkg) = ($1, $2);
			my $val = delete $opts->{$key};
			if (ref $val) {
				push @{ $opts->{$kind} ||= [] }, $pkg, $val;
			}
			elsif ($val eq 1 or not defined $val) {
				push @{ $opts->{$kind} ||= [] }, $pkg;
			}
			else {
				$builder->croak("$kind\:$pkg shortcut should be '1' or reference");
			}
		}
	}
	return;
}

sub munge_role_options {
	shift;
	my ($roleopts, $opts) = @_;
	return;
}

sub munge_class_options {
	shift;
	my ($classopts, $opts) = @_;
	return;
}

sub munge_class_generator_options {
	shift;
	my ($cgenopts, $opts) = @_;
	return;
}

sub munge_role_generator_options {
	shift;
	my ($rgenopts, $opts) = @_;
	return;
}

sub qualify_name {
	shift;
	my ($name, $prefix, $parent) = @_;
	my $sigil = "";
	if ($name =~ /^[@%\$]/) {
		$sigil = substr $name, 0, 1;
		$name  = substr $name, 1;
	}
	return $sigil.join("::", $parent->$_handle_list, $1) if (defined $parent and $name =~ /^\+(.+)/);
	return $sigil.$1 if $name =~ /^::(.+)$/;
	$prefix ? $sigil.join("::", $prefix, $name) : $sigil.$name;
}

sub type_name {
	shift;
	my ($name, $prefix) = @_;
	$prefix = '' unless defined $prefix;
	my $stub = $name;
	if (length $prefix and lc substr($name, 0, length $prefix) eq lc $prefix) {
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
	my ($lib, %opts) = @_;
	my ($version, $authority) = ($opts{version}, $opts{authority});
	my %types_hash;
	require Type::Tiny::Role;
	require Type::Tiny::Class;
	require Type::Registry;
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
		Type::Registry->for_class($opts{factory_package})->add_type($tc_obj)
			if defined $opts{factory_package};
		if ($coercions) {
			$none ||= ~Any;
			$tc_obj->coercion->add_type_coercions($none, 'die()');
		}
	};
	my $getter = sub {
		my $me = shift;
		my ($kind, $target) = @_;
		if ($target =~ /^([@%])(.+)$/) {
			my $sigil = $1;
			$target = $2;
			if ($sigil eq '@') {
				return ArrayRef->of($types_hash{$kind}{$target})
					if $types_hash{$kind}{$target};
			}
			elsif ($sigil eq '%') {
				return HashRef->of($types_hash{$kind}{$target})
					if $types_hash{$kind}{$target};
			}
		}
		$types_hash{$kind}{$target};
	};
	if (defined $opts{'factory_package'} or not exists $opts{'factory_package'}) {
		require B;
		eval(
			sprintf '
				package %s;
				sub type_library { %s };
				sub get_type_for_package { shift->type_library->get_type_for_package(@_) };
				1;
			',
			$opts{'factory_package'}||$opts{'caller'},
			B::perlstring($lib),
		) or $builder->croak("Could not install type library methods into factory package: $@");
	}
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

sub make_type_for_class_generator {
	my $builder = shift;
	my ($name, %opts) = @_;
	my $qname = $builder->qualify_name($name, $opts{prefix});

	if ($opts{'type_library'}) {
		my $class_type_name = $opts{'class_type_name'}
			|| sprintf('%sClass', $builder->type_name($qname, $opts{'prefix'}));
		my $class_type = $opts{'type_library'}->add_type({
			name        => $class_type_name,
			parent      => ClassName,
			constraint  => sprintf('$_->can("GENERATOR") && ($_->GENERATOR eq %s)', B::perlstring($qname)),
		});
		
		my $instance_type_name = $opts{'instance_type_name'}
			|| sprintf('%sInstance', $builder->type_name($qname, $opts{'prefix'}));
		my $instance_type = $opts{'type_library'}->add_type({
			name        => $instance_type_name,
			parent      => Object,
			constraint  => sprintf('$_->can("GENERATOR") && ($_->GENERATOR eq %s)', B::perlstring($qname)),
		});
		
		if ($opts{'factory_package'}) {
			my $reg = Type::Registry->for_class($opts{'factory_package'});
			$reg->add_type($_) for $class_type, $instance_type;
		}
	}
}

sub _make_type {
	my $builder = shift;
	my ($name, %opts) = @_;
	my $qname = $builder->qualify_name($name, $opts{prefix}, $opts{extends});
	
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
		my @subclasses = $opts{'subclass'}->$_handle_list_add_nulls;
		while (@subclasses) {
			my ($sc_name, $sc_opts) = splice @subclasses, 0, 2;
			my %opts_clone = %opts;
			delete $opts_clone{$_} for @delete_keys;
			$builder->make_type_for_class($sc_name, %opts_clone, extends => "::$qname", $sc_opts->$_handle_list);
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
	
	my $qname = $builder->qualify_name($name, $opts{prefix}, $opts{extends});
	
	if ($opts{coerce}) {
		if ($opts{abstract}) {
			require Carp;
			Carp::croak("abstract class $qname cannot have coercions")
		}
		my $method_installer = $opts{toolkit_install_methods} || ("install_methods");
		my @coercions = @{$opts{'coerce'} || []};
		
		while (@coercions) {
			my $type = shift @coercions;
			if (!ref $type) {
				my $tc = $opts{reg}->lookup($type);
				$type = $tc if $tc;
			}
			my $method_name = shift @coercions;
			defined($method_name) && !ref($method_name)
				or $builder->croak("No method name found for coercion to $qname from $type");
			
			my $coderef;
			$coderef = shift @coercions if is_CodeRef $coercions[0];

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
		my @subclasses = $opts{'subclass'}->$_handle_list_add_nulls;
		while (@subclasses) {
			my ($sc_name, $sc_opts) = splice @subclasses, 0, 2;
			my %opts_clone = %opts;
			delete $opts_clone{$_} for @delete_keys;
			$builder->do_coercions_for_class($sc_name, %opts_clone, extends => "::$qname", $sc_opts->$_handle_list);
		}
	}
}

sub make_role {
	my $builder = shift;
	my ($name, %opts) = @_;
	
	if ($opts{interface}) {
		for my $key (qw/ can before after around has multimethod /) {
			if ($opts{$key}) {
				require Carp;
				my $qname = $builder->qualify_name($name, $opts{prefix});
				Carp::croak("interface $qname cannot have $key");
			}
		}
	}

	for my $key (qw/ abstract extends subclass factory overload /) {
		if ($opts{$key}) {
			require Carp;
			my $qname = $builder->qualify_name($name, $opts{prefix});
			my $kind  = $opts{interface} ? 'interface' : 'role';
			Carp::croak("$kind $qname cannot have $key");
		}
	}

	$builder->_make_package($name, %opts, is_role => 1);
}

sub make_class {
	my $builder = shift;
	my ($name, %opts) = @_;
	$builder->_make_package($name, %opts, is_role => 0);
}

sub make_role_generator {
	my $builder = shift;
	my ($name, %opts) = @_;
	$builder->_make_package_generator($name, %opts, is_role => 1);
}

sub make_class_generator {
	my $builder = shift;
	my ($name, %opts) = @_;
	$builder->_make_package_generator($name, %opts, is_role => 0);
}

sub _expand_isa {
	my ($builder, $pfx, $ext) = @_;
	my @raw = $ext->$_handle_list;
	my @isa;
	my $changed;
	while (@raw) {
		if (@raw > 1 and ref($raw[1])) {
			my $gen  = $builder->qualify_name(shift(@raw), $pfx);
			my @args = shift(@raw)->$_handle_list;
			push @isa, sprintf('::%s', $gen->generate_package(@args));
			$changed++;
		}
		else {
			push @isa, shift(@raw);
		}
	}
	@$ext = @isa if $changed;;
	map $builder->qualify_name($_, $pfx), @isa;
}

my $nondeep;
sub _make_package {
	my $builder = shift;
	my ($name, %opts) = @_;
	
	my @isa = $opts{extends} ? $builder->_expand_isa($opts{prefix}, $opts{extends}) : ();
	my $qname = $builder->qualify_name($name, $opts{prefix}, @isa);
	my $tn = $builder->type_name($qname, $opts{prefix});
	
	if (!exists $opts{factory}) {
		$opts{factory} = $opts{abstract} ? undef : sprintf('new_%s', lc $tn);
	}
	
	my $toolkit = {
		moo    => 'Moo',
		moose  => 'Moose',
		mouse  => 'Mouse',
	}->{lc $opts{toolkit}} || $opts{toolkit};
	
	if ($opts{is_role}) {
		no strict 'refs';
		return if ${"$qname\::BUILT"};
		
		eval "package $qname; use $toolkit\::Role; use namespace::autoclean; our \$BUILT = 1"
			or $builder->croak("Could not create package $qname: $@");
	}
	else {
		my $optthing = '';
		if ($toolkit eq 'Moo') {
			$optthing = ' use MooX::TypeTiny;'      if eval { require MooX::TypeTiny };
		}
		elsif ($toolkit eq 'Moose') {
			$optthing = ' use MooseX::XSAccessor;'  if eval { require MooseX::XSAccessor };
		}
		eval "package $qname; use $toolkit;$optthing use namespace::autoclean; 1"
			or $builder->croak("Could not create package $qname: $@");
	
		my $method  = $opts{toolkit_extend_class} || ("extend_class_".lc $toolkit);
		if (@isa) {
			$builder->$method($qname, \@isa);
		}
	}
	
	my $reg;
	if ($opts{factory_package}) {
		require Type::Registry;
		'Type::Registry'->for_class($qname)->set_parent(
			'Type::Registry'->for_class($opts{factory_package})
		);
		$reg = 'Type::Registry'->for_class($qname);
	}
	
	for my $var (qw/VERSION AUTHORITY/) {
		if (defined $opts{lc $var}) {
			no strict 'refs';
			no warnings 'once';
			${"$qname\::$var"} = $opts{lc $var};
		}
	}
	
	if (defined $opts{'import'}) {
		my @imports = $opts{'import'}->$_handle_list;
		while (@imports) {
			my $import = shift @imports;
			my @params;
			if (is_HashRef($imports[0])) {
				@params = %{ shift @imports };
			}
			elsif (is_ArrayRef($imports[0])) {
				@params = @{ shift @imports };
			}
			require Import::Into;
			eval "require $import";
			$import->import::into($qname, @params);
		}
	}
	
	if (ref $opts{'begin'}) {
		$opts{'begin'}->($qname, $opts{is_role} ? 'role' : 'class');
	}

	if ($opts{overload}) {
		my @overloads = $opts{overload}->$_handle_list;
		require overload;
		require Import::Into;
		'overload'->import::into($qname, @overloads);
	}

	my $method_installer = $opts{toolkit_install_methods} || ("install_methods");
	{
		my %methods;
		%methods = $opts{can}->$_handle_list_add_nulls;
		$builder->$method_installer($qname, \%methods) if keys %methods;
		%methods = $opts{factory_package_can}->$_handle_list_add_nulls;
		$builder->$method_installer($opts{'factory_package'}||$opts{'caller'}, \%methods) if keys %methods;
		%methods = $opts{type_library_can}->$_handle_list_add_nulls;
		$builder->$method_installer($opts{type_library}, \%methods) if keys %methods;
	}
	
	{
		my $method = $opts{toolkit_install_constants} || ("install_constants");
		my %methods = $opts{constant}->$_handle_list_add_nulls;
		if (keys %methods) {
			$builder->$method($qname, \%methods);
		}
	}
	
	{
		my $method = $opts{toolkit_make_attribute} || ("make_attribute_".lc $toolkit);
		my @attrs = $opts{has}->$_handle_list_add_nulls;
		#use Data::Dumper;
		#warn Dumper(\@attrs);
		while (@attrs) {
			my ($attrname, $attrspec) = splice @attrs, 0, 2;
			
			my %spec_hints;
			if ($attrname =~ /^(\+?)(\$|\%|\@)(.+)$/) {
				$spec_hints{isa} ||= {
					'$' => ($nondeep ||= ((~ArrayRef)&(~HashRef))),
					'@' => ArrayLike,
					'%' => HashLike,
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
				is_CodeRef($attrspec) ? (is => 'rw', lazy => 1, builder => $attrspec, clearer => $clearername) :
				is_Object($attrspec) && $attrspec->can('check') ? (is => 'rw', isa => $attrspec) :
				$attrspec->$_handle_list;
			if (is_CodeRef $spec{builder}) {
				my $code = delete $spec{builder};
				$spec{builder} = $buildername;
				$builder->$method_installer($qname, { $buildername => $code });
			}
			if (defined $spec{clearer} and !ref $spec{clearer} and $spec{clearer} eq 1) {
				$spec{clearer} = $clearername;
			}
			
			%spec = (%spec_hints, %spec);
			$spec{is} ||= 'rw';
			
			if ($spec{is} eq 'lazy') {
				$spec{is}   = 'ro';
				$spec{lazy} = !!1;
				$spec{builder} ||= $buildername;
			}
			elsif ($spec{is} eq 'private') {
				$spec{is}   = 'rw';
				$spec{lazy} = !!1;
				$spec{init_arg} = undef;
				$spec{lexical}  = !!1;
			}
			
			if ($spec{does}) {
				my $target = $builder->qualify_name(delete($spec{does}), $opts{prefix});
				$spec{isa} ||= do {
					$opts{type_library}
						? $opts{type_library}->get_type_for_package(role => $target)
						: undef;
				};
				$spec{isa} ||= do {
					ConsumerOf->of($target);
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
					InstanceOf->of($target);
				};
			}
			if ($spec{enum}) {
				$spec{isa} = Enum->of(@{delete $spec{enum}});
			}
			if (is_Object($spec{type}) and $spec{type}->can('check')) {
				$spec{isa} = delete $spec{type};
			}
			elsif ($spec{type}) {
				$spec{isa} = $reg->lookup(delete $spec{type});
			}
			
			if (ref $spec{isa} && !exists $spec{coerce} && $spec{isa}->has_coercion) {
				$spec{coerce} = 1;
			}
			
			if ($toolkit ne 'Moo') {
				if (defined $spec{trigger} and !ref $spec{trigger} and $spec{trigger} eq 1) {
					$spec{trigger} = sprintf('_trigger_%s', $attrname);
				}
				if (defined $spec{trigger} and !ref $spec{trigger}) {
					my $trigger_method = delete $spec{trigger};
					$spec{trigger} = sub { shift->$trigger_method(@_) };
				}
				if ($spec{is} eq 'rwp') {
					$spec{is} = 'ro';
					$spec{writer} = '_set_'.$attrname unless exists $spec{writer};
				}
			}
			
			if (is_CodeRef $spec{coerce}) {
				$spec{isa}    = $spec{isa}->no_coercions->plus_coercions(Types::Standard::Any, $spec{coerce});
				$spec{coerce} = !!1;
			}
			
			if ($spec{lexical}) {
				require Lexical::Accessor;
				if ($spec{traits} || $spec{handles_via}) {
					'Lexical::Accessor'->VERSION('0.010');
				}
				my $la = 'Lexical::Accessor'->new_from_has(
					$attrname,
					package => $qname,
					%spec,
				);
				$la->install_accessors;
			}
			else
			{
				my ($shv_toolkit, $shv_data);
				if ($spec{handles_via}) {
					$shv_toolkit = "Sub::HandlesVia::Toolkit::$toolkit";
					eval "require $shv_toolkit" or die($@);
					$shv_data = $shv_toolkit->clean_spec($qname, $attrname, \%spec);
				}
				$builder->$method($qname, $attrname, \%spec);
				$shv_toolkit->install_delegations($shv_data) if $shv_data;
			}
		}
	}

	if ($opts{multimethod}) {
		my $method = $opts{toolkit_install_multimethod} || 'install_multimethod';
		my @mm = $opts{multimethod}->$_handle_list_add_nulls;
		while (@mm) {
			my ($method_name, $method_spec) = splice(@mm, 0, 2);
			$builder->$method($qname, $opts{is_role}?'role':'class', $method_name, $method_spec);
		}
	}

	{
		my $method = $opts{toolkit_apply_roles} || ("apply_roles_".lc $toolkit);
		my @roles = $opts{with}->$_handle_list;
		if (@roles) {
			my @processed;
			while (@roles) {
				if (@roles > 1 and ref($roles[1])) {
					my $gen  = $builder->qualify_name(shift(@roles), $opts{prefix});
					my @args = shift(@roles)->$_handle_list;
					push @processed, $gen->generate_package(@args);
				}
				else {
					my $role_qname = $builder->qualify_name(shift(@roles), $opts{prefix});
					push @processed, $role_qname;
					no strict 'refs';
					if ( $role_qname !~ /\?$/ and not ${"$role_qname\::BUILT"} ) {
						my ($role_dfn) = grep { $_->[0] eq "::$role_qname" } @{$opts{_roles}};
						$builder->make_role(
							"::$role_qname",
							_parent_opts => $opts{_parent_opts},
							_roles       => $opts{_roles},
							%{ $opts{_parent_opts} },
							%{ $role_dfn->[1] },
						) if $role_dfn;
					}
				}
			}
			$builder->$method($qname, $opts{is_role}?'role':'class', \@processed);
		}
	}
	
	if ($opts{is_role}) {
		my $method   = $opts{toolkit_require_methods} || ("require_methods_".lc $toolkit);
		my %requires = $opts{requires}->$_handle_list_add_nulls;
		if (keys %requires) {
			$builder->$method($qname, \%requires);
		}
	}

	for my $modifier (qw(before after around)) {
		my $method = $opts{toolkit_modify_methods} || ("modify_method_".lc $toolkit);
		my @methods = $opts{$modifier}->$_handle_list;
		while (@methods) {
			my @method_names;
			push(@method_names, shift @methods)
				while (@methods and not ref $methods[0]);
			my $coderef = $builder->_prepare_method_modifier($qname, $modifier, \@method_names, shift(@methods));
			$builder->$method($qname, $modifier, \@method_names, $coderef);
		}
	}
	
	unless ($opts{is_role}) {
		
		if ($toolkit eq 'Moose' && !$opts{'mutable'}) {
			require Moose::Util;
			Moose::Util::find_meta($qname)->make_immutable;
		}
		
		if ($toolkit eq 'Moo' && eval { require MooX::XSConstructor }) {
			'MooX::XSConstructor'->setup_for($qname);
		}
		
		if ($opts{abstract}) {
			my $orig_can   = $qname->can('can');
			my $orig_BUILD = do { no strict 'refs'; exists(&{"$qname\::BUILD"}) ? \&{"$qname\::BUILD"} : sub {} };
			'namespace::clean'->clean_subroutines($qname, 'new', 'BUILD');
			$builder->install_methods($qname, {
				can   => sub {
					if ((ref($_[0])||$_[0]) eq $qname and $_[1] eq 'new') { return; };
					goto $orig_can;
				},
				BUILD => sub {
					if (ref($_[0]) eq $qname) { require Carp; Carp::croak('abstract class'); };
					goto $orig_BUILD;
				},
			});
		}
		
		if (defined $opts{'factory_package'} or not exists $opts{'factory_package'}) {
			my $fpackage = $opts{'factory_package'} || $opts{'caller'};
			if ($opts{'factory'}) {
				my @methods = $opts{'factory'}->$_handle_list;
				if ($opts{abstract} and @methods) {
					require Carp;
					Carp::croak("abstract class $qname cannot have factory");
				}
				while (@methods) {
					my @method_names;
					push(@method_names, shift @methods)
						while (@methods and not ref $methods[0]);
					my $coderef = shift(@methods) || \"new";
					for my $name (@method_names) {
						if (is_CodeRef $coderef) {
							eval "package $fpackage; sub $name :method { splice(\@_, 1, 0, '$qname'); goto \$coderef }; 1"
								or $builder->croak("Could not create factory $name in $fpackage: $@");
						}
						elsif (is_ScalarRef $coderef) {
							my $target = $$coderef;
							eval "package $fpackage; sub $name :method { shift; '$qname'->$target\(\@_) }; 1"
								or $builder->croak("Couldn't create factory $name in $fpackage: $@");
						}
						elsif (is_HashRef $coderef) {
							my %meta = %$coderef;
							$meta{curry} ||= [$qname];
							$builder->$method_installer($fpackage, { $name => \%meta });
						}
						else {
							die "lolwut?";
						}
					}
				}
			}
			eval "sub $qname\::FACTORY { q[$fpackage] }; 1"
				or $builder->croak("Couldn't create link back to factory $qname\::FACTORY: $@");
		}
		
		if (defined $opts{'subclass'}) {
			my @subclasses = $opts{'subclass'}->$_handle_list_add_nulls;
			while (@subclasses) {
				my ($sc_name, $sc_opts) = splice @subclasses, 0, 2;
				my %opts_clone = %opts;
				delete $opts_clone{$_} for @delete_keys;
				$builder->make_class($sc_name, %opts_clone, extends => "::$qname", $sc_opts->$_handle_list);
			}
		}
	}
	
	if (ref $opts{'end'}) {
		$opts{'end'}->($qname, $opts{is_role} ? 'role' : 'class');
	}
	
	if ($opts{type_library} and $opts{type_name}) {
		my $mytype = $opts{type_library}->get_type_for_package($opts{'is_role'} ? 'role' : 'class', $qname);
		$mytype->coercion->freeze if $mytype;
	}
	
	return $qname;
}

sub _make_package_generator {
	my $builder = shift;
	my ($name, %opts) = @_;
	my $gen = $opts{generator} or die 'no generator code given!';
	
	my $kind = $opts{is_role} ? 'role' : 'class';
	
	my $qname = $builder->qualify_name($name, $opts{prefix});
	my $method_installer = $opts{toolkit_install_methods} || ("install_methods");
	
	$builder->$method_installer(
		$qname,
		{
			'_generate_package_spec' => $gen,
			'generate_package' => sub {
				my ($generator_package, @args) = @_;
				$builder->generate_package(
					$kind,
					$generator_package,
					\%opts,
					$generator_package->_generate_package_spec(@args),
				);
			},
		},
	);
	
	if ($opts{factory_package}) {
		require Type::Registry;
		'Type::Registry'->for_class($qname)->set_parent(
			'Type::Registry'->for_class($opts{factory_package})
		);

		my $tn = $builder->type_name($qname, $opts{prefix});
		if (!exists $opts{factory}) {
			$opts{factory} = 'generate_' . lc $tn;
		}
		my $fp = $opts{factory_package};
		my $f  = $opts{factory};
		eval qq{
			package $fp;
			sub $f :method {
				shift;
				q($qname)->generate_package(\@_);
			}
		};
	}
	
	return $qname;
}

my %_generate_counter;
sub generate_package {
	my $builder           = shift;
	my $kind              = shift;
	my $generator_package = shift;
	my $global_opts       = shift;
	my %local_opts        = ( @_ == 1 ? $_[0] : \@_ )->$_handle_list;
	
	my %opts;
	for my $key (qw/ extends with has can constant around before after
		toolkit version authority mutable begin end requires import overload /) {
		if (exists $local_opts{$key}) {
			$opts{$key} = delete $local_opts{$key};
		}
	}
	
	if (keys %local_opts) {
		die "bad keys from generator: ".join(", ", sort keys %local_opts);
	}
	
	# must not generate types or factory methods
	$opts{factory}   = undef;
	$opts{type_name} = undef;
	
	$_generate_counter{$generator_package} = 0 unless exists $_generate_counter{$generator_package};
	my $qname = sprintf('%s::__GEN%06d__', $generator_package, ++$_generate_counter{$generator_package});
	
	require Type::Registry;
	'Type::Registry'->for_class($qname)->set_parent(
		'Type::Registry'->for_class($generator_package)
	);
	
	if ($kind eq 'class') {
		my $method = $opts{toolkit_install_constants} || ("install_constants");
		$builder->$method($qname, { GENERATOR => $generator_package });
	}
	
	if ($kind eq 'role') {
		return $builder->make_role("::$qname", %$global_opts, %opts);
	}
	else {
		return $builder->make_class("::$qname", %$global_opts, %opts);
	}
}

sub _get_moo_helper {
	my $builder = shift;
	my ($package, $helpername) = @_;
	return $_cached_moo_helper{"$package\::$helpername"}
		if $_cached_moo_helper{"$package\::$helpername"};
	die "lolwut?" unless $helpername =~ /^(has|with|extends|around|before|after|requires)$/;
	my $is_role = ($INC{'Moo/Role.pm'} && 'Moo::Role'->is_role($package));
	my $tracker = $is_role ? $Moo::Role::INFO{$package}{exports} : $Moo::MAKERS{$package}{exports};
	if (ref $tracker) {
		$_cached_moo_helper{"$package\::$helpername"} ||= $tracker->{$helpername};
	}
	# I hate this...
	$_cached_moo_helper{"$package\::$helpername"} ||= eval sprintf(
		'do { package %s; use Moo%s; my $coderef = \&%s; no Moo%s; $coderef };',
		$package,
		$is_role ? '::Role' : '',
		$helpername,
		$is_role ? '::Role' : '',
	);
	die "BADNESS: couldn't get helper '$helpername' for package '$package'" unless $_cached_moo_helper{"$package\::$helpername"};
	$_cached_moo_helper{"$package\::$helpername"};
}

sub make_attribute_moo {
	my $builder = shift;
	my ($class, $attribute, $spec) = @_;
	my $helper = $builder->_get_moo_helper($class, 'has');
	if (is_Object($spec->{isa}) and $spec->{isa}->isa('Type::Tiny::Enum') and $spec->{handles}) {
		$builder->_process_enum_moo(@_);
	}
	$helper->($attribute, %$spec);
}

sub _process_enum_moo {
	my $builder = shift;
	my ($class, $attribute, $spec) = @_;
	require MooX::Enumeration;
	my %new_spec = 'MooX::Enumeration'->process_spec($class, $attribute, %$spec);
	if (delete $new_spec{moox_enumeration_process_handles}) {
		'MooX::Enumeration'->install_delegates($class, $attribute, \%new_spec);
	}
	%$spec = %new_spec;
}

sub make_attribute_moose {
	my $builder = shift;
	my ($class, $attribute, $spec) = @_;
	if (is_Object($spec->{isa}) and $spec->{isa}->isa('Type::Tiny::Enum')||$spec->{isa}->isa('Moose::Meta::TypeConstraint::Enum') and $spec->{handles}) {
		$builder->_process_enum_moose(@_);
	}
	require Moose::Util;
	(Moose::Util::find_meta($class) or $class->meta)->add_attribute($attribute, %$spec);
}

sub _process_enum_moose {
	my $builder = shift;
	my ($class, $attribute, $spec) = @_;
	require MooseX::Enumeration;
	push @{ $spec->{traits}||=[] }, 'Enumeration';
}

sub make_attribute_mouse {
	my $builder = shift;
	my ($class, $attribute, $spec) = @_;
	if (is_Object($spec->{isa}) and $spec->{isa}->isa('Type::Tiny::Enum') and $spec->{handles}) {
		$builder->_process_enum_mouse(@_);
	}
	require Mouse::Util;
	(Mouse::Util::find_meta($class) or $class->meta)->add_attribute($attribute, %$spec);
}

sub _process_enum_mouse {
	die 'not implemented';
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

sub install_multimethod {
	my $builder = shift;
	my ($target, $kind, $method_name, $method_spec) = @_;
	
	HashRef->($method_spec);
	Ref->($method_spec->{signature});
	CodeRef->($method_spec->{code});
	
	my $new_sig = $builder->_build_method_signature_check(
		$target,
		$method_name,
		CodeRef->check($method_spec->{signature})
			? 'code'
			: ($method_spec->{named} ? 'named' : 'positional'),
		$method_spec->{signature},
		undef,
		1,
	);
	$method_spec->{signature} = $new_sig;
	
	require Sub::MultiMethod;
	'Sub::MultiMethod'->install_candidate($target, $method_name, no_dispatcher=>($kind eq 'role'), %$method_spec);
}

{
	my $_process_roles = sub {
		my ($r, $tk) = @_;
		map {
			my $role = $_;
			if ($role =~ /\?$/) {
				$role =~ s/\?$//;
				eval "require $role; 1"
					or eval "package $role; use $tk\::Role; 1";
			}
			$role;
		} @$r;
	};
	
	my $_maybe_do_multimethods = sub {
		my $tk = 'Sub::MultiMethod';
		if ($INC{'Sub/MultiMethod.pm'} and $tk->can('copy_package_candidates')) {
			my ($target, $kind, @sources) = @_;
			$tk->copy_package_candidates(@sources => $target);
			$tk->install_missing_dispatchers($target) unless $kind eq 'role';
		}
		return;
	};
	
	sub apply_roles_moo {
		my $builder = shift;
		my ($class, $kind, $roles) = @_;
		my $helper = $builder->_get_moo_helper($class, 'with');
		my @roles = $roles->$_process_roles('Moo');
		$helper->(@roles);
		$class->$_maybe_do_multimethods($kind, @roles);
	}

	sub apply_roles_moose {
		my $builder = shift;
		my ($class, $kind, $roles) = @_;
		require Moose::Util;
		my @roles = $roles->$_process_roles('Moose');
		Moose::Util::ensure_all_roles($class, @roles);
		$class->$_maybe_do_multimethods($kind, @roles);
	}

	sub apply_roles_mouse {
		my $builder = shift;
		my ($class, $kind, $roles) = @_;
		require Mouse::Util;
		my @roles = $roles->$_process_roles('Mouse');
		# this can double-apply roles? :(
		Mouse::Util::apply_all_roles($class, @roles);
		$class->$_maybe_do_multimethods($kind, @roles);
	}
}

sub require_methods_moo {
	my $builder = shift;
	my ($role, $methods) = @_;
	my $helper = $builder->_get_moo_helper($role, 'requires');
	$helper->(sort keys %$methods);
}

sub require_methods_moose {
	my $builder = shift;
	my ($role, $methods) = @_;
	require Moose::Util;
	(Moose::Util::find_meta($role) or $role->meta)->add_required_methods(sort keys %$methods);
}

sub require_methods_mouse {
	my $builder = shift;
	my ($role, $methods) = @_;
	require Mouse::Util;
	(Mouse::Util::find_meta($role) or $role->meta)->add_required_methods(sort keys %$methods);
}

sub wrap_coderef {
	my $builder = shift;
	my %method  = (@_==1) ? %{$_[0]} : @_;
	my $qname   = delete($method{package}) || caller;
	$method{lexical} = !!1;
	my $return = $builder->install_methods($qname, { '__ANON__' => \%method });
	$return->{'__ANON__'};
}

sub install_methods {
	my $builder = shift;
	my ($class, $methods) = @_;
	my %return;
	
	for my $name (sort keys %$methods) {
		no strict 'refs';
		my ($code, $signature, $signature_style, $invocant_count, $is_coderef, $caller, @curry);
		$caller = $class;
		
		if (is_CodeRef($methods->{$name})) {
			$code            = $methods->{$name};
			$signature_style = 'none';
		}
		elsif (is_HashRef($methods->{$name})) {
			$code       = $methods->{$name}{code};
			$signature  = $methods->{$name}{signature};
			@curry      = @{ $methods->{$name}{curry} || [] };
			$invocant_count  = exists($methods->{$name}{invocant_count}) ? $methods->{$name}{invocant_count} : 1;
			$signature_style = is_CodeRef($signature)
				? 'code'
				: ($methods->{$name}{named} ? 'named' : 'positional');
			$is_coderef = !!$methods->{$name}{lexical};
			$caller     = $methods->{$name}{caller};
		}
		
		if ($signature) {
			CodeRef->assert_valid($signature)  if $signature_style eq 'code';
			ArrayRef->assert_valid($signature) if $signature_style eq 'named';
			ArrayRef->assert_valid($signature) if $signature_style eq 'positional';
		};
		
		my $optimized = 0;
		my $checkcode = '&$check';
		if ($signature and $methods->{$name}{optimize}) {
			if (my $r = $builder->_optimize_signature($class, "$class\::$name", $signature_style, $signature)) {
				$checkcode = $r;
				++$optimized;
			}
		}
		
		my $callcode;
		if (is_CodeRef($code)) {
			$callcode = 'goto $code';
		}
		else {
			($callcode = $code) =~ s/sub/do/;
			$callcode = "package $caller; $callcode" if defined $caller;
		}
		
		my $subcode = sprintf(
			q{
				package %-49s  # package name
				%-49s          # my $check variable to close over
				sub %-49s      # method name
				{
					%-49s          # strip @invocants from @_ if necessary
					%-49s          # build $check
					%-49s          # reassemble @_ from @invocants, @curry, and &$check
					%-49s          # run sub code
				};
				%s
			},
			"$class;",
			(($signature && !$optimized)
				? 'my $check;'
				: ''),
			($is_coderef ? '' : "$name :method"),
			($signature
				? sprintf('my @invocants = splice(@_, 0, %d);', $invocant_count)
				: ''),
			(($signature && !$optimized)
				? sprintf('$check ||= %s->_build_method_signature_check(%s, %s, %s, $signature, \\@invocants);', map(B::perlstring($_), $builder, $class, "$class\::$name", $signature_style))
				: ''),
			($signature
				? (@curry ? sprintf('@_ = (@invocants, @curry, %s);', $checkcode) : sprintf('@_ = (@invocants, %s);', $checkcode))
				: (@curry ? sprintf('splice(@_, %d, 0, @curry);', $invocant_count) : '')),
			$callcode,
			($is_coderef ? '' : '1;'),
		);
		($return{$name} = eval($subcode))
			or $builder->croak("Could not create method $name in package $class: $@");
	}
	\%return;
}

sub _optimize_signature {
	my $builder = shift;
	my ($method_class, $method_name, $signature_style, $signature) = @_;
	
	$signature_style ||= 'none' if !$signature;
	
	return if $signature_style eq 'none';
	return if $signature_style eq 'code';
	
	my @sig = @$signature;
	require Type::Params;
	my $global_opts = {};
	$global_opts = shift(@sig) if is_HashRef($sig[0]) && !$sig[0]{slurpy};
	$global_opts->{want_details} = 1;
	
	my $details = $builder->_build_method_signature_check($method_class, $method_name, $signature_style, [$global_opts, @sig]);
	return if keys %{$details->{environment}};
	return if $details->{source} =~ /return/;
	
	$details->{source} =~ /^sub \{(.+)\};$/s or return;
	return "do { $1 }";
}

# need to partially parse stuff for Type::Params to look up type names
sub _build_method_signature_check {
	my $builder = shift;
	my ($method_class, $method_name, $signature_style, $signature, $invocants, $gimme_list) = @_;
	my $type_library;
	
	$signature_style ||= 'none' if !$signature;
	
	return sub { @_ } if $signature_style eq 'none';
	return $signature if $signature_style eq 'code';
	my @sig = @$signature;
	
	require Type::Params;
	
	my $global_opts = {};
	$global_opts = shift(@sig) if is_HashRef($sig[0]) && !$sig[0]{slurpy};
	
	$global_opts->{subname} ||= $method_name;
	
	my $is_named = ($signature_style eq 'named');
	my @params;
	
	my $reg;
	
	while (@sig) {
		if (is_HashRef($sig[0]) and $sig[0]{slurpy}) {
			push @params, shift @sig;
			die "lolwut? after slurpy? you srs?" if @sig;
		}
		
		my ($name, $type, $opts) = (undef, undef, {});
		if ($is_named) {
			($name, $type) = splice(@sig, 0, 2);
		}
		else {
			$type = shift(@sig);
		}
		if (is_HashRef($sig[0]) && !ref($sig[0]{slurpy})) {
			$opts = shift(@sig);
		}
		
		# All that work, just to do this!!!
		if (is_Str($type) and not $type =~ /^[01]$/) {
			$reg ||= do {
				require Type::Registry;
				'Type::Registry'->for_class($method_class);
			};
			
			if ($type =~ /^\%/) {
				$type = HashRef->of(
					$reg->lookup(substr($type, 1))
				);
			}
			elsif ($type =~ /^\@/) {
				$type = ArrayRef->of(
					$reg->lookup(substr($type, 1))
				);
			}
			else {
				$type = $reg->lookup($type);
			}
		}
		
		my $hide_opts = 0;
		if ($opts->{slurpy} && !ref($opts->{slurpy})) {
			delete $opts->{slurpy};
			$type = { slurpy => $type };
			$hide_opts = 1;
		}
		
		push(
			@params,
			$is_named
				? ($name, $type, $hide_opts?():($opts))
				: (       $type, $hide_opts?():($opts))
		);
	}
	
	for my $position (qw( head tail )) {
		if (ref $global_opts->{$position}) {
			require Type::Params;
			'Type::Params'->VERSION(1.009002);
			$reg ||= do {
				require Type::Registry;
				'Type::Registry'->for_class($method_class);
			};
			$global_opts->{$position} = [map {
				my $type = $_;
				if (ref $type) {
					$type;
				}
				elsif ($type =~ /^\%/) {
					HashRef->of(
						$reg->lookup(substr($type, 1))
					);
				}
				elsif ($type =~ /^\@/) {
					ArrayRef->of(
						$reg->lookup(substr($type, 1))
					);
				}
				else {
					$reg->lookup($type);
				}
			} @{$global_opts->{$position}} ];
		}
	}
	
	my $next = $is_named ? \&Type::Params::compile_named_oo : \&Type::Params::compile;
	@_ = ($global_opts, @params);
	return [@_] if $gimme_list;
	goto($next);
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

sub _prepare_method_modifier {
	my ($builder, $class, $kind, $names, $method) = @_;
	return $method if is_CodeRef $method;
	
	my $coderef   = $method->{code};
	my $signature = $method->{signature};
	my @curry     = @{ $method->{curry} || [] };
	my $signature_style = $method->{named} ? 'named' : 'positional';
	
	return $coderef unless $signature || @curry;
	$signature ||= sub { @_ };
	
	my $invocant_count = 1 + !!($kind eq 'around');
	$invocant_count  = $method->{invocant_count} if exists $method->{invocant_count};
	
	my $name = join('|', @$names)."($kind)";

	my $wrapped = eval qq{
		my \$check;
		sub {
			my \@invocants = splice(\@_, 0, $invocant_count);
			\$check ||= q($builder)->_build_method_signature_check(q($class), q($class\::$name), \$signature_style, \$signature, \\\@invocants);
			\@_ = (\@invocants, \@curry, \&\$check);
			goto \$coderef;
		};
	};
	$wrapped or die("YIKES: $@");
}

sub modify_method_moo {
	my $builder = shift;
	my ($class, $modifier, $method_names, $coderef) = @_;
	my $helper = $builder->_get_moo_helper($class, $modifier);
	$helper->(@$method_names, $coderef);
}

sub modify_method_moose {
	my $builder = shift;
	my ($class, $modifier, $method_names, $coderef) = @_;
	my $m = "add_$modifier\_method_modifier";
	require Moose::Util;
	my $meta = Moose::Util::find_meta($class) || $class->meta;
	for my $method_name (@$method_names) {
		$meta->$m($method_name, $coderef);
	}
}

sub modify_method_mouse {
	my $builder = shift;
	my ($class, $modifier, $method_names, $coderef) = @_;
	my $m = "add_$modifier\_method_modifier";
	require Mouse::Util;
	my $meta = (Mouse::Util::find_meta($class) or $class->meta);
	for my $method_name (@$method_names) {
		$meta->$m($method_name, $coderef);
	}
}

1;

__END__
