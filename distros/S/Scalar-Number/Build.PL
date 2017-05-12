{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	unless(__PACKAGE__->can("cbuilder")) {
		*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
	}
	unless(__PACKAGE__->can("have_c_compiler")) {
		*have_c_compiler = sub {
			my $cb = eval { $_[0]->cbuilder };
			return $cb && $cb->have_compiler;
		};
	}
	if($Module::Build::VERSION < 0.33) {
		# Older versions of Module::Build have a bug where if the
		# cbuilder object is used at Build.PL time (which it will
		# be for this distribution due to the logic in
		# ->find_xs_files) then that object can be dumped to the
		# build_params file, and then at Build time it will
		# attempt to use the dumped blessed object without loading
		# the ExtUtils::CBuilder class that is needed to make it
		# work.
		*write_config = sub {
			delete $_[0]->{properties}->{_cbuilder};
			return $_[0]->SUPER::write_config;
		};
	}
	sub find_xs_files {
		my($self) = @_;
		return {} unless $self->have_c_compiler;
		return $self->SUPER::find_xs_files;
	}
	sub compile_c {
		require Data::Float;
		Data::Float->VERSION("0.008");
		require Data::Integer;
		Data::Integer->VERSION("0.001");
		my($self, $file, %args) = @_;
		$args{defines} = { %{$args{defines} || {}},
			Q_HAVE_SIGNED_ZERO =>
				Data::Float::have_signed_zero() ? 1 : 0,
			Q_SIGNIFICAND_BITS => Data::Float::significand_bits(),
			Q_NATINT_BITS => Data::Integer::natint_bits(),
		};
		return $self->SUPER::compile_c($file, %args);
	}
	sub ACTION_testauthor { $_[0]->generic_test(type => "author") }
})->new(
	module_name => "Scalar::Number",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	configure_recommends => {
		"ExtUtils::CBuilder" => "0.15",
	},
	build_requires => {
		"Data::Float" => "0.008",
		"Data::Integer" => "0.003",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_recommends => {
		"ExtUtils::CBuilder" => "0.15",
	},
	requires => {
		"Carp" => 0,
		"Data::Float" => "0.008",
		"Data::Integer" => "0.003",
		"Exporter" => 0,
		"constant" => 0,
		"overload" => 0,
		"parent" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	recommends => {
		"XSLoader" => 0,
	},
	needs_compiler => 0,
	dynamic_config => 1,
	meta_add => { distribution_type => "module" },
	test_types => { author => ".at" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
