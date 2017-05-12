package Module::Build::Pluggable::Fortran;

# ABSTRACT: Plugin for Module::Build to compile Fortran C<.f> files

use strict;
use warnings;
our $VERSION = '0.26';
use parent qw{Module::Build::Pluggable::Base};

BEGIN {
    eval "use ExtUtils::F77";
    if ($@) {
        warn "ExtUtils::F77 module not found. Build not possible.\n";
        exit 0;
    }
    if ( not ExtUtils::F77->runtimeok ) {
        warn "No Fortran compiler found. Build not possible.\n";
        exit 0;
    }
    if ( not ExtUtils::F77->testcompiler ) {
        warn "No fortran compiler found. Build not possible.\n";
        exit 0;
    }
}

sub HOOK_configure {
    my ($self) = @_;

    $self->builder_class->add_property('f_source');
    ## Can't validate here b/c of HOOK_configure calling order

    $self->build_requires( 'ExtUtils::F77'      => 0 );
    $self->build_requires( 'ExtUtils::CBuilder' => '0.23' );

    my @runtime = split / /, ExtUtils::F77->runtime;
    $self->_add_extra_linker_flags( @runtime, @{ $self->_fortran_obj_files } );

    $self->builder->add_to_cleanup('f77_underscore');

    return 1;
}

sub HOOK_build {
    my ($self) = @_;
    my $builder = $self->builder;

    my $mycompiler = ExtUtils::F77->compiler();
    my $mycflags   = ExtUtils::F77->cflags();
    undef $mycflags if $mycflags =~ m{^\s*};    # Avoid empty arg in cmd

    my $f_src_files = $self->_fortran_files;
    for my $f_src_file (@$f_src_files) {
        ( my $file = $f_src_file ) =~ s{\.f$}{};

        # Both $self->up_to_date is undocumented and could change in the
        # future:
        my $up_to_date = $builder->up_to_date( $f_src_file, ["$file.o"] );
        if ( not $up_to_date ) {

            my @cmd = (
                $mycompiler, '-c', '-o', "$file.o", ( $mycflags || () ),
                "-O3", "-fPIC", "$file.f"
            );

            warn join( " ", @cmd ), "\n";
            $builder->do_system(@cmd)
              or die "error compiling $file";
        }

        $builder->add_to_cleanup("$file.o");
    }

    return 1;
}

sub _fortran_files {
    my ($self) = @_;

    # We don't seem to be able to access the property created by add_property
    # in HOOK_configure (ditto if we move that to HOOK_build), we are going to
    # have to pry our way into builder and access f_source directly.
    # my $f_source = $self->builder->f_source;
    my $f_source = $self->builder->{properties}->{f_source};
    my @f_source_dirs = ref $f_source eq 'ARRAY' ? @$f_source : ($f_source);

    my @f_source_files = ();
    for my $f_src_dir (@f_source_dirs) {
        my $f_src_files = $self->builder->rscan_dir( $f_src_dir, qr/\.f$/ );
        push @f_source_files, @$f_src_files;
    }

    return \@f_source_files;
}

sub _fortran_obj_files {
    my ($self) = @_;

    my $f_src_files = $self->_fortran_files;
    s{\.f$}{.o} for @$f_src_files;
    return $f_src_files;
}

sub _add_extra_linker_flags {
    my ( $self, @new_flags ) = @_;

    my $linker_flags = $self->builder->extra_linker_flags;
    push @$linker_flags, @new_flags;
    $self->builder->extra_linker_flags(@$linker_flags);
}

1;

__END__

=pod

=head1 NAME

Module::Build::Pluggable::Fortran - Plugin for Module::Build to compile Fortran C<.f> files

=head1 VERSION

version 0.26

=head1 SYNOPSIS

    # Build.PL
    use strict;
    use warnings;
    use Module::Build::Pluggable ('Fortran');

    my $builder = Module::Build::Pluggable->new(
        dist_name  => 'PDL::My::Module',
        license    => 'perl',
        f_source   => [ 'src' ],
        requires   => { },
        configure_requires => {
            'Module::Build'                      => '0.4004',
            'Module::Build::Pluggable'           => '0',
            'Module::Build::Pluggable::Fortran'  => '0.20',
        },

    );
    $builder->create_build_script();

=head1 DESCRIPTION

This is a plugin for L<Module::Build> (using L<Module::Build::Pluggable>) that
will assist in building distributions that require Fortran C<.f> files to be
compiled. Please see the L<Module::Build::Authoring> documentation if you are
not familiar with it.

=over 4

=item Add Prerequisites

    build_requires => {
        'ExtUtils::F77'      => '0',
        'ExtUtils::CBuilder' => '0.23',
    },

You can, or course, require your own versions of these modules by adding them
to C<requires => {}> as usual.

=item Compile C<.f> files

The directories specified by the f_source array within your distribution will
be searched for C<.f> files which are, immediately prior to the build phase,
compiled into C<.o> files.
This is accomplished (effectively) by running:

    my $mycompiler = ExtUtils::F77->compiler();
    my $mycflags   = ExtUtils::F77->cflags();
    system( "$mycompiler -c -o $file.o $mycflags -O3 -fPIC $file.f" );

=item Add Extra Linker Flags

    extra_linker_flags =>  $PDL::Config{MALLOCDBG}->{libs}
      if $PDL::Config{MALLOCDBG}->{libs};
    extra_linker_flags => ExtUtils::F77->runtime, <your fortran object files>

Adds the linker flags from C<ExtUtils::F77> and all the C<.o> object files
created from the C<.f> Fortran files.

=back

=head1 SEE ALSO

L<Module::Build::Pluggable>, L<Module::Build>

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
