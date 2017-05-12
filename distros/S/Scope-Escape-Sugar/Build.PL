{ use 5.011002; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	unless(__PACKAGE__->can("cbuilder")) {
		*cbuilder = sub { $_[0]->_cbuilder or die "no C support" };
	}
	sub compile_c {
		my($self, $file, %args) = @_;
		my $cc0_h = $self->localize_file_path(
				"lib/Scope/Escape/callchecker0.h");
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
		my $cp_h = $self->localize_file_path(
				"lib/Scope/Escape/callparser.h");
		unless(-f $cp_h) {
			require Devel::CallParser;
			Devel::CallParser->VERSION(0.000);
			my $content = eval { local $SIG{__DIE__};
				&Devel::CallParser::callparser1_h()
			} || &Devel::CallParser::callparser0_h();
			$self->add_to_cleanup($cp_h);
			require IO::File;
			my $fh = IO::File->new($cp_h, "w") or die $!;
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
			if($args{module_name} eq "Scope::Escape::Sugar") {
				require Devel::CallChecker;
				Devel::CallChecker->VERSION(0.002);
				require Devel::CallParser;
				Devel::CallParser->VERSION(0.001);
				$args{objects} = [
				    @{$args{objects}},
				    Devel::CallChecker::callchecker_linkable(),
				    Devel::CallParser::callparser_linkable(),
				];
			}
			@_ = ($self, %args);
			goto &$orig_cb_link;
		};
		$self->SUPER::link_c($spec);
	}
})->new(
	module_name => "Scope::Escape::Sugar",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.011002",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Devel::CallChecker" => "0.003",
		"Devel::CallParser" => "0.001",
		"ExtUtils::CBuilder" => "0.15",
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.011002",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"B::Hooks::EndOfScope" => "0.05",
		"Devel::CallChecker" => "0.003",
		"Devel::CallParser" => "0.001",
		"Exporter" => 0,
		"Scope::Escape" => "0.004",
		"XSLoader" => 0,
		"parent" => 0,
		"perl" => "5.011002",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
