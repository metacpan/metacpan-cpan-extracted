package Module::Install::Rust;

use 5.006;
use strict;
use warnings;

use Module::Install::Base;
use TOML 0.97 ();
use Config ();

our @ISA = qw( Module::Install::Base );

=head1 NAME

Module::Install::Rust - Helpers to build Perl extensions written in Rust

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

    # In Makefile.PL
    use inc::Module::Install;

    # ...

    rust_requires libc => "0.2";
    rust_write;

    WriteAll;

=head1 DESCRIPTION

This package allows L<Module::Install> to build Perl extensions written in Rust.

=head1 COMMANDS

=head2 rust_requires

    rust_requires libc => "0.2";
    rust_requires internal_crate => { path => "../internal_crate" };

This command is used to specify Rust dependencies. First argument should be a
crate name, second - either a version string, or a hashref with keys per Cargo
manifest spec.

=cut

sub rust_requires {
    my ($self, $name, $spec) = @_;
    $self->{rust_requires}{$name} = $spec;
}

=head2 rust_feature

    rust_feature default => [ "some_feature" ];
    rust_feature some_feature => [ "some-crate/feature" ];

This command adds items to C<[features]> section of the generated C<Cargo.toml>.

=cut

sub rust_feature {
    my ($self, $name, $spec) = @_;
    die "Feature $name is already defined" if $self->{rust_features}{$name};
    $self->{rust_features}{$name} = $spec;
}

=head2 rust_profile

    rust_profile debug => { "opt-level" => 1 };
    rust_profile release => { lto => 1 };

This command configures a C<[profile]> section to the generated C<Cargo.toml>.

=cut

sub rust_profile {
    my ($self, $name, $spec) = @_;
    die "Profile $name is already configured" if $self->{rust_profile}{$name};

    $self->{rust_profile}{$name} = $spec;
}

=head2 rust_use_perl_xs

    rust_use_perl_xs;

Configure crate to use C<perl-xs> bindings.

=cut

sub rust_use_perl_xs {
    my ($self, $spec) = @_;

    $spec //= { version => "0" };

    $self->rust_requires("perl-xs", $spec);
    $self->rust_clean_on_rebuild("perl-sys");
}

=head2 rust_clean_on_rebuild

    rust_clean_on_rebuild;
    # or
    rust_clean_on_rebuild qw/crate_name/;

If Makefile changed since last build, force C<cargo clean> run. If crate names
are specified, force clean only for those packages (C<cargo clean -p>).

=cut

sub rust_clean_on_rebuild {
    my ($self, @args) = @_;

    my $crates = $self->{cargo_clean} //= [];
    push @$crates, @args;
}

=head2 rust_write

    rust_write;

Writes C<Cargo.toml> and sets up Makefile options as needed.

=cut

sub rust_write {
    my $self = shift;

    $self->_rust_write_cargo;
    $self->_rust_setup_makefile;
}

sub _rust_crate_name {
    lc shift->name
}

sub _rust_target_name {
    shift->_rust_crate_name =~ s/-/_/gr
}

sub _rust_write_cargo {
    my $self = shift;

    my $crate_spec = {
        package => {
            name => $self->_rust_crate_name,
            description => $self->abstract,
            version => "1.0.0", # FIXME
        },

        lib => {
            "crate-type" => [ "cdylib" ],
        },
    };

    $crate_spec->{dependencies} = $self->{rust_requires}
        if $self->{rust_requires};

    $crate_spec->{features} = $self->{rust_features}
        if $self->{rust_features};

    $crate_spec->{profile} = $self->{rust_profile}
        if $self->{rust_profile};

    open my $f, ">", "Cargo.toml" or die $!;
    $f->print("# This file is autogenerated\n\n");
    $f->print(TOML::to_toml($crate_spec));
    close $f or die $!;
}

sub _rust_setup_makefile {
    my $self = shift;
    my $class = ref $self;

    # FIXME: don't assume libraries have "lib" prefix
    my $libname = "lib" . $self->_rust_target_name;

    my $rustc_opts = "";
    my $postproc;
    if ($^O eq "darwin") {
        # Linker flag to allow bundle to use symbols from the parent process.
        $rustc_opts = "-C link-args='-undefined dynamic_lookup'";

        # On darwin, Perl uses special darwin-specific format for loadable
        # modules. Normally it is produced by passing "-bundle" flag to the
        # linker, but Rust as of 1.12 does not support that.
        #
        # "-C link-args=-bundle" doesn't work, because then "-bundle" conflicts
        # with "-dylib" option used by rustc.
        #
        # However, it seems possible to produce correct ".bundle" file by
        # running linker with correct options on the shared library that was
        # created by rustc.
        $postproc = <<MAKE;
	\$(LD) \$(LDDLFLAGS) -o \$@ \$<
MAKE
    } else {
        $postproc = <<MAKE;
	\$(CP) \$< \$@
MAKE
    }



    $self->postamble(<<MAKE);
# --- $class section:

INST_RUSTDYLIB = \$(INST_ARCHAUTODIR)/\$(DLBASE).\$(DLEXT)
RUST_TARGETDIR = target/release
RUST_DYLIB = \$(RUST_TARGETDIR)/$libname.\$(SO)
CARGO = cargo
CARGO_OPTS = --release
RUSTC_OPTS = $rustc_opts

dynamic :: \$(INST_RUSTDYLIB)

MAKE

    if ($self->{cargo_clean}) {
        my @opts = map qq{-p "$_"}, @{$self->{cargo_clean}};

        $self->postamble(<<MAKE);
\$(RUST_DYLIB) ::
	test \$(FIRST_MAKEFILE) -ot \$@ || \$(CARGO) clean \$(CARGO_OPTS) @opts

MAKE
    }

    $self->postamble(<<MAKE);
\$(RUST_DYLIB) ::
	PERL=\$(FULLPERL) \$(CARGO) rustc \$(CARGO_OPTS) -- \$(RUSTC_OPTS)

\$(INST_RUSTDYLIB): \$(RUST_DYLIB)
$postproc

clean ::
	\$(CARGO) clean
	\$(RM) Cargo.toml Cargo.lock
MAKE
}

=head1 AUTHOR

Vickenty Fesunov, C<< <kent at setattr.net> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/vickenty/mi-rust>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Vickenty Fesunov.

This module may be used, modified, and distributed under the same terms as Perl
itself. Please see the license that came with your Perl distribution for
details.

=cut

1;
