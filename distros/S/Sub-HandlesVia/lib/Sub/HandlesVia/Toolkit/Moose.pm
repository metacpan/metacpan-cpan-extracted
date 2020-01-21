use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Moose;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	
	require Moose::Util;
	my $meta = Moose::Util::find_meta($target);
	Role::Tiny->apply_roles_to_object($meta, $me->package_trait);
}

sub package_trait {
	__PACKAGE__ . "::PackageTrait";
}

package Sub::HandlesVia::Toolkit::Moose::PackageTrait;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Role::Tiny;

around add_attribute => sub {
	my ($next, $self, $name, @args) = (shift, shift, @_);
	my $spec = (@args == 1) ? $args[0] : { @args };
	$self->_shv_munge_spec($name, $spec);
	my $attr = $self->$next($name, $spec);
	if ($spec->{'definition_context'}{'shv'}{'_sub_handlesvia_handles'} and $self->isa('Moose::Meta::Class')) {
		$self->_shv_install_methods($name, $spec);
	}
	return $attr;
};

my %native = qw(
	Array           1
	Bool            1
	Code            1
	Counter         1
	Hash            1
	Number          1
	String          1
);

sub _shv_munge_spec {
	my ($self, $name, $spec) = @_;
	
	# Easier to do this here than in the test cases.
	delete $spec->{no_inline};
	
	# Clean our stuff out of traits list...
	if (ref $spec->{traits} and not $spec->{handles_via}) {
		my @keep = grep !$native{$_}, @{$spec->{traits}};
		my @cull = grep  $native{$_}, @{$spec->{traits}};
		delete $spec->{traits};
		if (@keep) {
			$spec->{traits} = \@keep;
		}
		if (@cull) {
			$spec->{handles_via} = \@cull;
		}
	}
	
	# We don't really need to do anything else differently from Moo...
	require Sub::HandlesVia::Toolkit::Moo;
	Sub::HandlesVia::Toolkit::Moo::process_spec(__PACKAGE__, $self->name, $name, $spec);
	
	# Moose::Meta::Attribute complains about unknown options passed to
	# constructor, so let's stash them somewhere safe!
	$spec->{'definition_context'}{'shv'} = {
		'handles_via'                  => delete($spec->{'handles_via'}),
		'_sub_handlesvia_handles'      => delete($spec->{'_sub_handlesvia_handles'}),
		'_sub_handlesvia_orig_handles' => delete($spec->{'_sub_handlesvia_orig_handles'}),
	}
		if $spec->{'handles_via'}
		|| $spec->{'_sub_handlesvia_handles'}
		|| $spec->{'_sub_handlesvia_orig_handles'};
}

sub _shv_install_methods {
	my ($self, $name, $spec) = @_;
	if (my $handles = $spec->{'definition_context'}{'shv'}{'_sub_handlesvia_handles'}) {
		my %callbacks = $self->_shv_callbacks($name, $spec);
#		use Data::Dumper;
#		warn Dumper($callbacks{env});
		foreach my $method_name (sort keys %$handles) {
#			warn $handles->{$method_name}->code_as_string(
#				%callbacks,
#				target      => $self->name,
#				method_name => $method_name,
#			);
			my $coderef = $handles->{$method_name}->coderef(
				%callbacks,
				target      => $self->name,
				method_name => $method_name,
			);
			$self->add_method($method_name => $coderef);
		}
	}
}

my %standard_callbacks = (
	args => sub {
		'@_[1..$#_]';
	},
	arg => sub {
		@_==1 or die;
		my $n = shift;
		"\$_[$n]";
	},
	argc => sub {
		'(@_-1)';
	},
	curry => sub {
		@_==1 or die;
		my $arr = shift;
		"splice(\@_,1,0,$arr);";
	},
	usage_string => sub {
		@_==2 or die;
		my $method_name = shift;
		my $guts = shift;
		"\$instance->$method_name($guts)";
	},
	self => sub {
		'$_[0]';
	},
);

sub _shv_callbacks {
	my ($self, $name, $spec) = @_;
	my $attr = $self->get_attribute($name);
	
	my $captures = {};
	
	my ($get, $set, $get_is_lvalue, $set_checks_isa);
	if (!$spec->{lazy} and !$spec->{traits} and !$spec->{auto_deref}) {
		require B;
		my $slot = B::perlstring($attr->name);
		$get = sub { "\$_[0]{$slot}" };
		++$get_is_lvalue;
	}
	elsif ($attr->has_read_method) {
		my $read_method = $attr->get_read_method;
		$get = sub { "scalar(\$_[0]->$read_method)" };
	}
	else {
		my $read_method = $attr->get_read_method_ref;
		eval { $read_method = $read_method->{body} };  # Moose docs lie!
		$captures->{'$shv_read_method'} = \$read_method;
		$get = sub { 'scalar($_[0]->$shv_read_method)' };
	}
	
	if ($attr->has_write_method) {
		my $write_method = $attr->get_write_method;
		$set = sub { my $val = shift; "\$_[0]->$write_method\($val)" };
		++$set_checks_isa;
	}
	else {
		$captures->{'$shv_write_method'} = \(sub { $attr->set_value(@_) });
		$set = sub { my $val = shift; '$_[0]->$shv_write_method('.$val.')' };
		++$set_checks_isa;
	}

	my $default;
	if (exists $spec->{default}) {
		$default = [ default => $spec->{default} ];
	}
	elsif (exists $spec->{builder}) {
		$default = [ builder => $spec->{builder} ];
	}

	if (ref $default->[1] eq 'CODE') {
		$captures->{'$shv_default_for_reset'} = \$default->[1];
	}

	return (
		%standard_callbacks,
		is_method      => !!1,
		get            => $get,
		get_is_lvalue  => $get_is_lvalue,
		set            => $set,
		set_checks_isa => $set_checks_isa,
		isa            => Types::TypeTiny::to_TypeTiny($attr->type_constraint),
		coerce         => !!$spec->{coerce},
		env            => $captures,
		be_strict      => !!1,
		default_for_reset => sub {
			my ($handler, $callbacks) = @_ or die;
			if (!$default) {
				return $handler->default_for_reset->();
			}
			elsif ($default->[0] eq 'builder') {
				return sprintf('(%s)->%s', $callbacks->{self}->(), $default->[1]);
			}
			elsif ($default->[0] eq 'default' and ref $default->[1] eq 'CODE') {
				return sprintf('(%s)->$shv_default_for_reset', $callbacks->{self}->());
			}
			elsif ($default->[0] eq 'default' and !defined $default->[1]) {
				return 'undef';
			}
			elsif ($default->[0] eq 'default' and !ref $default->[1]) {
				require B;
				return B::perlstring($default->[1]);
			}
			else {
				die 'lolwut?';
			}
		},
	);
}

1;