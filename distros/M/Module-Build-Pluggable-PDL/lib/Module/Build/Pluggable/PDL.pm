package Module::Build::Pluggable::PDL;

# ABSTRACT: Plugin to Module::Build to build PDL projets

use strict;
use warnings;
our $VERSION = '0.23';
use parent qw(Module::Build::Pluggable::Base);

use PDL::Core::Dev;
use List::MoreUtils qw(first_index);
use Config;
use Pod::Perldoc;

sub HOOK_build {
    my ($self) = @_;

    $self->add_before_action_modifier( 'distdir', \&HOOK_distdir );
    $self->add_action( 'forcepdlpp', \&ACTION_forcepdlpp );

    $self->process_pd_files;

    return 1;
}

sub HOOK_configure {
    my ($self) = @_;

    $self->_add_include_dirs( PDL::Core::Dev::whereami_any() . '/Core' );

    $self->_add_extra_linker_flags( $PDL::Config{MALLOCDBG}->{libs} )
      if $PDL::Config{MALLOCDBG}->{libs};

    $self->requires( 'PDL' => '2.006' );
    $self->build_requires( 'PDL'                => '2.006' );
    $self->build_requires( 'ExtUtils::CBuilder' => '0.23' );

    return 1;
}

sub _add_include_dirs {
    my ( $self, @dirs ) = @_;

    my $include_dirs = $self->builder->include_dirs;
    push @$include_dirs, @dirs;
    $self->builder->include_dirs($include_dirs);
}

sub _add_extra_linker_flags {
    my ( $self, @new_flags ) = @_;

    my $linker_flags = $self->builder->extra_linker_flags;
    push @$linker_flags, @new_flags;
    $self->builder->extra_linker_flags($linker_flags);
}

# Allow the person installing to force a PDL::PP rebuild
sub ACTION_forcepdlpp {
    my $self = shift;
    warn "self is " . ref $self;
    $self->log_info("Forcing PDL::PP build\n");
    $self->{FORCE_PDL_PP_BUILD} = 1;
    $self->ACTION_build();
}

# largely based on process_PL_files and process_xs_files in M::B::Base
sub process_pd_files {
    my $self    = shift;
    my $builder = $self->builder;

    warn "# process_pd_files\n";

    # Get all the .pd files in lib
    my $files = $builder->rscan_dir( 'lib', qr/\.pd$/ );

    # process each in turn
    for my $file (@$files) {
        my ( $build_prefix, $prefix, $mod_name ) = $self->_filename2info($file);

        $self->_convert_to_pm( $file, $build_prefix, $prefix, $mod_name );

        $self->_add_to_provides( {
            mod_name => $mod_name,
            file     => $file,
            version  => $builder->dist_version
        } );

        $builder->add_to_cleanup( "$build_prefix.pm", "$build_prefix.xs" );

        # Add the newly created .pm and .xs files to the list of such files?
        # No, because the current build process looks for all such files and
        # processes them, and it doesn't create that list until it's actually
        # processing the .pm and .xs files.
    }
}

sub _convert_to_pm {
    my ( $self, $file, $build_prefix, $prefix, $mod_name ) = @_;
    my $builder = $self->builder;

    # see sub run_perl_command (yet undocumented)
    # PDL::PP's import argument are, in order:
    # Module name -> for example, PDL::Graphics::PLplot
    # Package name -> used in package line of the .pm file; for our purposes,
    #     this is identical to Module name.
    # Prefix -> the extensionless file name, PDL/Graphics/PLplot
    #    .pm and .xs extensions will be added to this when the files are
    #    produced, so this should include a lib/ prefix
    # Callpack -> an optional argument used for the XS PACKAGE keyword;
    #    if left blank, it will be identical to the module name
    my $PDL_arg = "-MPDL::PP qw[$mod_name $mod_name $build_prefix]";

    # Both $self->up_to_date and $self->run_perl_command are undocumented
    # so they could change in the future:
    my $up_to_date =
      $builder->up_to_date( $file, [ "$build_prefix.pm", "$build_prefix.xs" ] );

    if ( $builder->{FORCE_PDL_PP_BUILD} or not $up_to_date ) {
        $builder->run_perl_command( [ $PDL_arg, $file ] );
    }
}

sub _add_to_provides {
    my ( $self, $info ) = @_;

    warn "# provides....$info->{file}\n";
    $self->builder->meta_merge(
        'provides',
        {
            $info->{mod_name} =>
              { file => $info->{file}, version => $info->{version} },
        } );
}

sub _filename2info {
    my ( $self, $file ) = @_;

    # Remove the .pd extension to get the build file prefix, which
    # says where the .xs and .pm files should be placed when we run
    # PDL::PP on the .pd file
    ( my $build_prefix = $file ) =~ s/\.[^.]+$//;

    # Figure out the file's lib-less prefix, which tells perl where it
    # will be installed _within_ lib:
    ( my $prefix = $build_prefix ) =~ s|.*lib/||;

    # Build the module name (Surely there's a M::B function for this?)
    ( my $mod_name = $prefix ) =~ s|/|::|g;

    return ( $build_prefix, $prefix, $mod_name );
}

sub HOOK_distdir {
    my ($self) = @_;    # $self is MyModuleBuilder (not MBP::PDL)

    my $files = $self->rscan_dir( 'lib', qr/\.pd$/ );
    for my $file (@$files) {
        ( my $build_prefix = $file ) =~ s{\.pd$}{};
        ( my $prefix       = $build_prefix ) =~ s{/?lib/}{};
        ( my $package      = $build_prefix ) =~ s{/}{::}g;

        # Process .pd into a .pm file with embedded POD
        # perl -MPDL::PP=PDL::Opt::QP,PDL::Opt::QP,lib/PDL/Opt/QP lib/PDL/Opt/QP.pd
        my $cmd = sprintf "%s -MPDL::PP=%s,%s,%s %s",
          $Config{perlpath}, $package, $package, $build_prefix, $file;
        $self->do_system($cmd) or die "Error running PDL::PP : $@";

        # Process .pm into .pod using perldoc as an object
        # && perldoc -u lib/PDL/Opt/QP.pm > lib/PDL/Opt/QP.pod
        my $poddoc =
          Pod::Perldoc->new(
            args => ['-u', '-d', "$build_prefix.pod", "$build_prefix.pm"] );
        $poddoc->process();

        $self->add_to_cleanup("$build_prefix.pod");
    }

    return 1;
}

1;

__END__

=pod

=head1 NAME

Module::Build::Pluggable::PDL - Plugin to Module::Build to build PDL projets

=head1 VERSION

version 0.23

=head1 SYNOPSIS

    # Build.PL
    use strict;
    use warnings;
    use Module::Build::Pluggable ('PDL');

    my $builder = Module::Build::Pluggable->new(
        dist_name  => 'PDL::My::Module',
        license    => 'perl',
        requires   => { },
    );
    $builder->create_build_script();

=head1 DESCRIPTION

This is a plugin for L<Module::Build> (using L<Module::Build::Pluggable>)
that will assist in building L<PDL> distributions. Please see the
L<Module::Build::Authoring> documentation if you are not familiar with it.

=over 4

=item Add Prerequisites

    requires => { 'PDL' => '2.000' },
    build_requires => {
        'PDL'                => '2.000',
        'ExtUtils::CBuilder' => '0.23',
    },

You can, or course, require your own versions of these modules by adding them
to C<requires => {}> as usual. 

=item Process C<.pd> files

The C<lib> directory of your distribution will be searched for C<.pd> files
and, immediately prior to the build phase, these will be processed by
C<PDL::PP> into C<.xs> and C<.pm>. files as required to continue the build
process.  These will then be processed by C<Ext::CBuilder> as normal. These
files are also added to the list of file to be cleaned up.

In addition, an entry will be made into C<provides> for the C<.pm> file of the
C<META.json/yml> files. This will assist PAUSE, search.cpan.org and metacpan.org
in properly indexing the distribution and 

=item Generate C<.pod> file from the C<.pd>

When building the distribution (C<./Build dist> or C<./Build distdir>), any
C<.pd> file found in the C<lib> directory will converted into C<.pod> files.
This produces a standalone version of the documentation which can be viewed
on search.cpan.org, metacpan.org, etc. When these sites attempt to display 
the pod in the C<.pd> files directly, there is often formatting and processing
issues.

This is accomplished by first processing the files with C<PDL::PP> and then
C<perldoc -u>.

=item Add Include Dirs

    include_dirs => PDL::Core::Dev::whereami_any() . '/Core';

The C<PDL/Core> directory is added to the C<include_dirs> flag.

=item Add Extra Linker Flags

    extra_linker_flags =>  $PDL::Config{MALLOCDBG}->{libs}
      if $PDL::Config{MALLOCDBG}->{libs};

If needed, the MALLOCDBG libs will be added to the C<extra_linker_flags>.

=back

=head1 SEE ALSO

This is essentially a rewrite of David Mertens' L<Module::Build::PDL> to use
L<Module::Build::Pluggable>. The conversion to L<Module::Build::Pluggable>
fixes multiple inheritance issues with subclassing L<Module::Build>. In
particular, I needed to be able use the L<Module::Build::Pluggable::Fortran>
in my PDL projects.

Thank you David++ for L<Module::Build::PDL>.

Of course, all of this just tweaks the L<Module::Build> setup.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
