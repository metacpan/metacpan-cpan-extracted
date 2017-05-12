#!/usr/bin/perl

package MooseX::Compile::CLI::Command::compile;
use Moose;

use Path::Class;

extends qw(
    MooseX::Compile::Base
    MooseX::Compile::CLI::Base
);

has compiler_class => (
    documentation => "The compiler class to use",
    isa => "Str",
    is  => "rw",
    default => "MooseX::Compile::Compiler",
);

has compiler_args => (
    documentation => "Additional arguments for the compiler",
    isa => "ArrayRef",
    is  => "rw",
    auto_deref => 1,
    default    => sub { [] },
);

has compiler => (
    metaclass => "NoGetopt",
    isa => "Object",
    is  => "rw",
    lazy_build => 1,
);

has target_lib => (
    documentation => "If supplied .pmcs will be written to this lib directory, instead of next to where the original .pm files are",
    metaclass     => "Getopt",
    cmd_aliases   => ["C"],
    isa => "Str",
    is  => "rw",
);

sub _build_compiler {
    my $self = shift;

    my $class = $self->compiler_class;

    $self->load_classes( $class );

    $class->new( $self->compiler_args );
};

augment run => sub {
    my ( $self, $opts, $args ) = @_;

    $self->compile_all_classes;
};

augment build_from_opts => sub {
};

sub compile_all_classes {
    my $self = shift;

    $self->compile_classes( $self->all_files );
}

sub compile_classes {
    my ( $self, @files ) = @_;

    my %seen_out;
    
    file: foreach my $file ( @files ) {
        if ( my $seen = $seen_out{$file->{pmc_file}} ) {
            warn "Class '$file->{class}' found in '$seen->{dir}' was already compiled into '$file->{pmc_file}', skipping the version in '$file->{dir}'\n" if $self->verbose;
            next file;
        } else {
            $seen_out{$file->{pmc_file}} = $file;
        }

        $self->compile_class($file);
    }
}

sub compile_class {
    my ( $self, $file ) = @_;

    # FIXME use $^X and a simpler compilation command?
    if ( my $pid = fork ) { # clean env to load the module in
        waitpid $pid, 0;
    } else {
        warn "Compiling class '$file->{class}'\n" if $self->verbose;

        if ( eval {
            local @INC = ( "$file->{dir}", @INC );
            require $file->{rel};
        } ) {
            if ( eval { $file->{class}->meta->isa("Moose::Meta::Class") } ) {
                $self->compiler->compile_class( %$file );
                warn "Compiled '$file->{class}' from '$file->{dir}' into " . $file->{pmc_file}->relative($file->{dir}) . "\n";
            } else {
                warn "Skipping $file->{class}, it's not a Moose class\n" if $self->verbose;
            }
        } else {
            my $f = quotemeta(__FILE__);
            ( my $e = $@ ) =~ s/ at $f line \d+\.\n$/./s;
            warn "Loading of file '$file->{rel}' from '$file->{dir}' failed: $e\n";
        }

        exit;
    }
}

sub filter_file {
    my ( $self, $file ) = @_;

    return $file if $file->basename =~ m/\.pm$/ and -f $file;

    return;
}

override file_in_dir => sub {
    my ( $self, %args ) = @_;

    my $entry = super();

    my ( $rel, $dir ) = @{ $entry }{qw(rel dir)};

    $entry->{pmc_file} = file( "${rel}c" )->absolute( dir( $self->target_lib || $dir ) );

    return $entry;
};

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::Compile::CLI::Command::compile - Compile Moose classes using MooseX::Compile::Compiler.

=head1 SYNOPSIS
    
    # compile My::Class in lib/

    > mxcompile compile -l My::Class

=head1 DESCRIPTION

This command is used to compile classes using L<MooseX::Compile::Compiler>.

=cut
