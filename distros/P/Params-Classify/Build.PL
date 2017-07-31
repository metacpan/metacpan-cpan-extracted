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
		return {} unless $self->have_c_compiler &&
			eval {
				require ExtUtils::ParseXS;
				ExtUtils::ParseXS->VERSION(3.30);
				1;
			};
		return $self->SUPER::find_xs_files;
	}
	sub compile_xs {
		my($self, $file, %args) = @_;
		require ExtUtils::ParseXS;
		ExtUtils::ParseXS->VERSION(3.30);
		return $self->SUPER::compile_xs($file, %args);
	}
	sub compile_c {
		my($self, $file, %args) = @_;
		my $cc0_h =
			$self->localize_file_path("lib/Params/callchecker0.h");
		unless(-f $cc0_h) {
			my $content = eval {
				local $SIG{__DIE__};
				require Devel::CallChecker;
				Devel::CallChecker->VERSION(0.003);
				&Devel::CallChecker::callchecker0_h();
			} || "";
			$self->add_to_cleanup($cc0_h);
			require IO::File;
			my $fh = IO::File->new($cc0_h, "w") or die $!;
			$fh->printflush($content) or die $!;
			$fh->close or die $!;
		}
		return $self->SUPER::compile_c($file, %args);
	}
	sub link_c {
		no strict "refs";
		my($self, $spec) = @_;
		my $cb = $self->cbuilder;
		my $cbclass = ref($cb);
		my $orig_cb_link = $cb->can("link");
		local *{"${cbclass}::link"} = sub {
			my($self, %args) = @_;
			if($args{module_name} eq "Params::Classify") {
				my $cc_linkables = eval {
				    local $SIG{__DIE__};
				    require Devel::CallChecker;
				    Devel::CallChecker->VERSION(0.003);
				    [&Devel::CallChecker::callchecker_linkable];
				} || [];
				$args{objects} = [
				    @{$args{objects}},
				    @$cc_linkables,
				];
			}
			@_ = ($self, %args);
			goto &$orig_cb_link;
		};
		$self->SUPER::link_c($spec);
	}
})->new(
	module_name => "Params::Classify",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006001",
		"strict" => 0,
		"warnings" => 0,
	},
	configure_recommends => {
		"ExtUtils::CBuilder" => "0.15",
	},
	build_requires => {
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006001",
		"strict" => 0,
		"warnings" => 0,
	},
	build_recommends => {
		"Devel::CallChecker" => "0.003",
		"ExtUtils::CBuilder" => "0.15",
		"ExtUtils::ParseXS" => "3.30",
	},
	requires => {
		"Exporter" => 0,
		"Scalar::Util" => "1.01",
		"parent" => 0,
		"perl" => "5.006001",
		"strict" => 0,
		"warnings" => 0,
	},
	recommends => {
		"Devel::CallChecker" => "0.003",
		"XSLoader" => 0,
	},
	needs_compiler => 0,
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	meta_merge => {
		"meta-spec" => { version => "2" },
		resources => {
			bugtracker => {
				mailto => "bug-Params-Classify\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=Params-Classify",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
