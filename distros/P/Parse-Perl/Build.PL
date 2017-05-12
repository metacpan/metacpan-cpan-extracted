{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	unless(__PACKAGE__->can("cbuilder")) {
		*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
	}
	sub compile_c {
		my($self, $file, %args) = @_;
		my $cc0_h =
			$self->localize_file_path("lib/Parse/callchecker0.h");
		unless(-f $cc0_h) {
			require Devel::CallChecker;
			Devel::CallChecker->VERSION(0.001);
			my $content = &Devel::CallChecker::callchecker0_h();
			$self->add_to_cleanup($cc0_h);
			require IO::File;
			my $fh = IO::File->new($cc0_h, "w") or die $!;
			$fh->printflush($content) or die $!;
			$fh->close or die $!;
		}
		if("$]" < 5.013007) {
			# need PERL_CORE for working HINTS_REFCNT_LOCK,
			# GRAMPROG constant, and working SAVEHINTS()
			$args{defines} = { %{$args{defines} || {}},
				PERL_CORE => 1,
			};
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
			if($args{module_name} eq "Parse::Perl") {
				require Devel::CallChecker;
				Devel::CallChecker->VERSION(0.002);
				$args{objects} = [
				    @{$args{objects}},
				    Devel::CallChecker::callchecker_linkable(),
				];
			}
			@_ = ($self, %args);
			goto &$orig_cb_link;
		};
		$self->SUPER::link_c($spec);
	}
})->new(
	module_name => "Parse::Perl",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.008004",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Devel::CallChecker" => "0.003",
		"ExtUtils::CBuilder" => "0.15",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.008004",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Devel::CallChecker" => "0.003",
		"Exporter" => 0,
		"XSLoader" => 0,
		"parent" => 0,
		"perl" => "5.008004",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
