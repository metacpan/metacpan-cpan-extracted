=head1 NAME

Module::Starter::Plugin::CGIApp - template based module starter for CGI apps.

=head1 SYNOPSIS

    use Module::Starter qw(
        Module::Starter::Plugin::CGIApp
    );

    Module::Starter->create_distro(%args);

=head1 ABSTRACT

This is a plugin for L<Module::Starter|Module::Starter> that builds you a skeleton 
L<CGI::Application|CGI::Application> module with all the extra files needed to package it for 
CPAN. You can customize the output using L<HTML::Template|HTML::Template>.

=cut

package Module::Starter::Plugin::CGIApp;

use base 'Module::Starter::Simple';
use warnings;
use strict;
use Carp qw( croak );
use English qw( -no_match_vars );
use File::Basename;
use File::Path qw( mkpath );
use File::Spec ();
use Module::Starter::BuilderSet;
use HTML::Template;

=head1 VERSION

This document describes version 0.44

=cut

our $VERSION = '0.44';

=head1 DESCRIPTION

This module subclasses L<Module::Starter::Simple|Module::Starter::Simple> and
includes functionality similar to L<Module::Starter::Plugin::Template|Module::Starter::Plugin::Template>.
This document only describes the methods which are overridden from those modules or are new.

Only developers looking to extend this module need to read this. If you just 
want to use L<Module::Starter::Plugin::CGIApp|Module::Starter::Plugin::CGIApp>, read the docs for 
L<cgiapp-starter|cgiapp-starter> or L<titanium-starter|titanium-starter> instead.

=head1 METHODS

=head2 new ( %args )

This method calls the C<new> supermethod from 
L<Module::Starter::Plugin::Simple|Module::Starter::Plugin::Simple> and then
initializes the template store. (See C<templates>.)

=cut

sub new {
    my ( $proto, %opts ) = @_;
    my $class = ref $proto || $proto;

    my $self = $class->SUPER::new(%opts);
    $self->{templates} = { $self->templates };

    return bless $self => $class;
}

=head2 create_distro ( %args ) 

This method works as advertised in L<Module::Starter|Module::Starter>.

=cut

sub create_distro {
    my ( $either, %opts ) = @_;
    ( ref $either ) or $either = $either->new(%opts);
    my $self = $either;

    # Supposedly the *-starter scripts can handle multiple --builder options
    # but this doesn't work (and IMO doesn't make sense anyway.) So in the
    # case multiple builders were specified, we just pick the first one.
    if ( ref $self->{builder} eq 'ARRAY' ) {
        $self->{builder} = $self->{builder}->[0];
    }

    my @modules;
    foreach my $arg ( @{ $self->{modules} } ) {
        push @modules, ( split /[,]/msx, $arg );
    }
    if ( !@modules ) {
        croak "No modules specified.\n";
    }
    for (@modules) {
        if ( !/\A [[:alpha:]_] \w* (?: [:] [:] [\w]+ )* \Z /imsx ) {
            croak "Invalid module name: $_";
        }
    }
    $self->{modules} = \@modules;

    if ( !$self->{author} ) {
        croak "Must specify an author\n";
    }
    if ( !$self->{email} ) {
        croak "Must specify an email address\n";
    }
    ( $self->{email_obfuscated} = $self->{email} ) =~ s/@/ at /msx;

    $self->{license} ||= 'perl';

    $self->{main_module} = $self->{modules}->[0];
    if ( !$self->{distro} ) {
        $self->{distro} = $self->{main_module};
        $self->{distro} =~ s/::/-/gmsx;
    }

    $self->{basedir} = $self->{dir} || $self->{distro};
    $self->create_basedir;

    my @files;
    push @files, $self->create_modules( @{ $self->{modules} } );

    push @files, $self->create_t( @{ $self->{modules} } );
    push @files, $self->create_xt( @{ $self->{modules} } );
    push @files, $self->create_tmpl();
    my %build_results = $self->create_build();
    push @files, @{ $build_results{files} };

    push @files, $self->create_Changes;
    push @files, $self->create_LICENSE;
    push @files, $self->create_README( $build_results{instructions} );
    push @files, $self->create_MANIFEST_SKIP;
    push @files, $self->create_perlcriticrc;
    push @files, $self->create_server_pl;
    push @files, 'MANIFEST';
    $self->create_MANIFEST( sub { _create_manifest( $self, @files ) } );

    return;
}

sub _create_manifest {
    my ( $self, @files ) = @_;

    my $file = File::Spec->catfile( $self->{basedir}, 'MANIFEST' );
    open my $fh, '>', $file or croak "Can't open file $file: $OS_ERROR\n";
    foreach my $file ( sort @files ) {
        print {$fh} "$file\n" or croak "$OS_ERROR\n";
    }
    close $fh or croak "Can't close file $file: $OS_ERROR\n";

    return;
}

=head2 create_LICENSE( )

This method creates a C<LICENSE> file in the distribution's directory which
can hold the distribution's license terms.

=cut

sub create_LICENSE {    ## no critic 'NamingConventions::Capitalization'
    my $self = shift;

    my $fname = File::Spec->catfile( $self->{basedir}, 'LICENSE' );
    $self->create_file( $fname, $self->LICENSE_guts() );
    $self->progress("Created $fname");

    return 'LICENSE';
}

=head2 create_MANIFEST_SKIP( )

This method creates a C<MANIFEST.SKIP> file in the distribution's directory so 
that unneeded files can be skipped from inclusion in the distribution.

=cut

sub create_MANIFEST_SKIP {    ## no critic 'NamingConventions::Capitalization'
    my $self = shift;

    my $fname = File::Spec->catfile( $self->{basedir}, 'MANIFEST.SKIP' );
    $self->create_file( $fname, $self->MANIFEST_SKIP_guts() );
    $self->progress("Created $fname");

    return 'MANIFEST.SKIP';
}

=head2 create_modules( @modules )

This method will create a starter module file for each module named in 
I<@modules>.  It is only subclassed from L<Module::Starter::Simple|Module::Starter::Simple> here 
so we can change the I<rtname> tmpl_var to be the distro name instead of 
the module name.

=cut

sub create_modules {
    my ( $self, @modules ) = @_;

    my @files;

    my $rtname = lc $self->{distro};
    for my $module (@modules) {
        push @files, $self->_create_module( $module, $rtname );
    }

    return @files;
}

=head2 create_perlcriticrc( )

This method creates a C<perlcriticrc> in the distribution's author test
directory so that the behavior of C<perl-critic.t> can be modified.

=cut

sub create_perlcriticrc {
    my $self = shift;

    my @dirparts = ( $self->{basedir}, 'xt' );
    my $tdir = File::Spec->catdir(@dirparts);
    if ( not -d $tdir ) {
        mkpath($tdir);
        $self->progress("Created $tdir");
    }

    my $fname = File::Spec->catfile( @dirparts, 'perlcriticrc' );
    $self->create_file( $fname, $self->perlcriticrc_guts() );
    $self->progress("Created $fname");

    return 'xt/perlcriticrc';
}

=head2 create_server_pl( )

This method creates C<server.pl> in the distribution's root directory.

=cut

sub create_server_pl {
    my $self = shift;

    my $fname = File::Spec->catfile( $self->{basedir}, 'server.pl' );
    $self->create_file( $fname, $self->server_pl_guts() );
    $self->progress("Created $fname");

    return 'server.pl';
}

=head2 create_t( @modules )

This method creates a bunch of *.t files.  I<@modules> is a list of all modules
in the distribution.

=cut

sub create_t {
    my ( $self, @modules ) = @_;

    my %t_files = $self->t_guts(@modules);

    my @files = map { $self->_create_t( 't',  $_, $t_files{$_} ) }  keys %t_files;

    # This next part is for the static files dir t/www
    my @dirparts = ( $self->{basedir}, 't', 'www' );
    my $twdir = File::Spec->catdir(@dirparts);
    if ( not -d $twdir ) {
        mkpath($twdir);
        $self->progress("Created $twdir");
    }
    my $placeholder =
      File::Spec->catfile( @dirparts, 'PUT.STATIC.CONTENT.HERE' );
    $self->create_file( $placeholder, q{ } );
    $self->progress("Created $placeholder");
    push @files, 't/www/PUT.STATIC.CONTENT.HERE';

    return @files;
}

=head2 create_tmpl( )

This method takes all the template files ending in .html (representing 
L<HTML::Template|HTML::Template>'s and installs them into a directory under the distro tree.  
For instance if the distro was called C<Foo-Bar>, the templates would be 
installed in C<lib/Foo/Bar/templates>.

Note the files will just be copied over not rendered.

=cut

sub create_tmpl {
    my $self = shift;

    return $self->tmpl_guts();
}

=head2 create_xt( @modules )

This method creates a bunch of *.t files for author tests.  I<@modules> is a
list of all modules in the distribution.

=cut

sub create_xt {
    my ( $self, @modules ) = @_;

    my %xt_files = $self->xt_guts(@modules);

    my @files = map { $self->_create_t( 'xt', $_, $xt_files{$_} ) } keys %xt_files;

    return @files;
}

=head2 render( $template, \%options )

This method is given an L<HTML::Template|HTML::Template> and options and
returns the resulting document.

Data in the C<Module::Starter> object which represents a reference to an array 
@foo is transformed into an array of hashes with one key called 
C<$foo_item> in order to make it usable in an L<HTML::Template|HTML::Template> C<TMPL_LOOP>.
For example:

    $data = ['a'. 'b', 'c'];

would become:

    $data = [
        { data_item => 'a' },
        { data_item => 'b' },
        { data_item => 'c' },
    ];
    
so that in the template you could say:

    <tmpl_loop data>
        <tmpl_var data_item>
    </tmpl_loop>
    
=cut

sub render {
    my ( $self, $template, $options ) = @_;

    # we need a local copy of $options otherwise we get recursion in loops
    # because of [1]
    my %opts = %{$options};

    $opts{nummodules}    = scalar @{ $self->{modules} };
    $opts{year}          = $self->_thisyear();
    $opts{license_blurb} = $self->_license_blurb();
    $opts{datetime}      = scalar localtime;
    $opts{buildscript} =
      Module::Starter::BuilderSet->new()->file_for_builder( $self->{builder} );

    foreach my $key ( keys %{$self} ) {
        next if defined $opts{$key};
        $opts{$key} = $self->{$key};
    }

    # [1] HTML::Templates wants loops to be arrays of hashes not plain arrays
    foreach my $key ( keys %opts ) {
        if ( ref $opts{$key} eq 'ARRAY' ) {
            my @temp = ();
            for my $option ( @{ $opts{$key} } ) {
                push @temp, { "${key}_item" => $option };
            }
            $opts{$key} = [@temp];
        }
    }
    my $t = HTML::Template->new(
        die_on_bad_params => 0,
        scalarref         => \$template,
    ) or croak "Can't create template $template";
    $t->param( \%opts );
    return $t->output;
}

=head2 templates ( )

This method reads in the template files and populates the object's templates
attribute. The module template directory is found by checking the 
C<MODULE_TEMPLATE_DIR> environment variable and then the config option 
C<template_dir>.

=cut

sub templates {
    my ($self) = @_;
    my %template;

    my $template_dir = ( $ENV{MODULE_TEMPLATE_DIR} || $self->{template_dir} )
      or croak 'template dir not defined';
    if ( !-d $template_dir ) {
        croak "template dir does not exist: $template_dir";
    }

    foreach ( glob "$template_dir/*" ) {
        my $basename = basename $_;
        next if ( not -f $_ ) or ( $basename =~ /\A [.]/msx );
        open my $template_file, '<', $_
          or croak "couldn't open template: $_";
        $template{$basename} = do {
            local $RS = undef;
            <$template_file>;
        };
        close $template_file or croak "couldn't close template: $_";
    }

    return %template;
}

=head2 Build_PL_guts($main_module, $main_pm_file)

This method is called by L<create_Build_PL|create_Build_PL> and returns text used to populate
Build.PL when the builder is L<Module::Build|Module::Build>; I<$main_pm_file>
is the filename of the distribution's main module, I<$main_module>.

=cut

sub Build_PL_guts {    ## no critic 'NamingConventions::Capitalization'
    my ( $self, $main_module, $main_pm_file ) = @_;
    my %options;
    $options{main_module}  = $main_module;
    $options{main_pm_file} = $main_pm_file;

    my $template = $self->{templates}{'Build.PL'};
    return $self->render( $template, \%options );
}

=head2 Changes_guts

Implements the creation of a C<Changes> file.

=cut

sub Changes_guts {    ## no critic 'NamingConventions::Capitalization'
    my $self = shift;
    my %options;

    my $template = $self->{templates}{Changes};
    return $self->render( $template, \%options );
}

=head2 LICENSE_guts

Implements the creation of a C<LICENSE> file.

=cut

sub LICENSE_guts {    ## no critic 'NamingConventions::Capitalization'
    my $self = shift;
    my %options;

    my $template = $self->{templates}{LICENSE};
    return $self->render( $template, \%options );
}

sub _license_blurb {
    my $self = shift;
    my $license_blurb;
    my $license_record = $self->_license_record();

    if ( defined $license_record ) {
        if ( $license_record->{license} eq 'perl' ) {
            $license_blurb = <<'EOT';
This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version, or

b) the Artistic License version 1.0 or a later version.
EOT
        }
        else {
            $license_blurb = $license_record->{blurb};
        }
    }
    else {
        $license_blurb = <<"EOT";
This program is released under the following license: $self->{license}
EOT
    }
    chomp $license_blurb;
    return $license_blurb;
}

=head2 Makefile_PL_guts($main_module, $main_pm_file)

This method is called by L<create_Makefile_PL|create_Makefile_PL> and returns text used to populate
Makefile.PL when the builder is L<ExtUtils::MakeMaker|ExtUtils::MakeMaker>;
I<$main_pm_file> is the filename of the distribution's main module,
I<$main_module>.

=cut

sub Makefile_PL_guts {    ## no critic 'NamingConventions::Capitalization'
    my ( $self, $main_module, $main_pm_file ) = @_;
    my %options;
    $options{main_module}  = $main_module;
    $options{main_pm_file} = $main_pm_file;

    my $template = $self->{templates}{'Makefile.PL'};
    return $self->render( $template, \%options );
}

=head2 MANIFEST_SKIP_guts

Implements the creation of a C<MANIFEST.SKIP> file.

=cut

sub MANIFEST_SKIP_guts {    ## no critic 'NamingConventions::Capitalization'
    my $self = shift;
    my %options;

    my $template = $self->{templates}{'MANIFEST.SKIP'};
    return $self->render( $template, \%options );
}

=head2 MI_Makefile_PL_guts($main_module, $main_pm_file)

This method is called by L<create_MI_Makefile_PL|create_MI_Makefile_PL> and returns text used to populate
Makefile.PL when the builder is L<Module::Install|Module::Install>;
I<$main_pm_file> is the filename of the distribution's main module,
I<$main_module>.

=cut

sub MI_Makefile_PL_guts {    ## no critic 'NamingConventions::Capitalization'
    my ( $self, $main_module, $main_pm_file ) = @_;
    my %options;
    $options{main_module}  = $main_module;
    $options{main_pm_file} = $main_pm_file;

    my $template = $self->{templates}{'MI_Makefile.PL'};
    return $self->render( $template, \%options );
}

=head2 module_guts($module, $rtname)

Implements the creation of a C<README> file.

=cut

sub module_guts {
    my ( $self, $module, $rtname ) = @_;
    my %options;
    $options{module} = $module;
    $options{rtname} = $rtname;

    my $template = $self->{templates}{'Module.pm'};
    return $self->render( $template, \%options );
}

=head2 README_guts($build_instructions)

Implements the creation of a C<README> file.

=cut

sub README_guts {    ## no critic 'NamingConventions::Capitalization'
    my ( $self, $build_instructions ) = @_;
    my %options;
    $options{build_instructions} = $build_instructions;

    my $template = $self->{templates}{'README'};
    return $self->render( $template, \%options );
}

=head2 perlcriticrc_guts

Implements the creation of a C<perlcriticrc> file.
 
=cut

sub perlcriticrc_guts {
    my $self = shift;
    my %options;

    my $template = $self->{templates}{perlcriticrc};
    return $self->render( $template, \%options );
}

=head2 server_pl_guts

Implements the creation of a C<server.pl> file.

=cut

sub server_pl_guts {
    my $self = shift;
    my %options;
    $options{main_module} = $self->{main_module};

    my $template = $self->{templates}{'server.pl'};
    return $self->render( $template, \%options );
}

=head2 t_guts(@modules)

Implements the creation of test files. I<@modules> is a list of all the modules
in the distribution.

=cut

sub t_guts {
    my ( $self, @opts ) = @_;
    my %options;
    $options{modules}     = [@opts];
    $options{modulenames} = [];
    foreach ( @{ $options{modules} } ) {
        push @{ $options{module_pm_files} }, $self->_module_to_pm_file($_);
    }

    my %t_files;

    foreach ( grep { /[.]t\z/msx } keys %{ $self->{templates} } ) {
        my $template = $self->{templates}{$_};
        $t_files{$_} = $self->render( $template, \%options );
    }

    return %t_files;
}

=head2 tmpl_guts

Implements the creation of template files.

=cut

sub tmpl_guts {
    my ($self) = @_;
    my %options;    # unused in this function.

    my @dirparts = ( $self->{basedir}, 'share', 'templates' );
    my $tdir = File::Spec->catdir(@dirparts);
    if ( not -d $tdir ) {
        mkpath($tdir);
        $self->progress("Created $tdir");
    }

    my @t_files;
    foreach
      my $filename ( grep { /[.]html \z/msx } keys %{ $self->{templates} } )
    {
        my $template = $self->{templates}{$filename};
        my $fname = File::Spec->catfile( @dirparts, $filename );
        $self->create_file( $fname, $template );
        $self->progress("Created $fname");
        push @t_files, "share/templates/$filename";
    }

    return @t_files;
}

=head2 xt_guts(@modules)

Implements the creation of test files for author tests. I<@modules> is a list
of all the modules in the distribution.

=cut

sub xt_guts {
    my ( $self, @opts ) = @_;
    my %options;
    $options{modules}     = [@opts];
    $options{modulenames} = [];
    foreach ( @{ $options{modules} } ) {
        push @{ $options{module_pm_files} }, $self->_module_to_pm_file($_);
    }

    my %xt_files;

    foreach ( grep { /[.]xt\z/msx } keys %{ $self->{templates} } ) {
        my $template = $self->{templates}{$_};
        $_ =~ s/[.]xt\z/.t/msx;    # change *.xt back to *.t
        $xt_files{$_} = $self->render( $template, \%options );
    }

    return %xt_files;
}

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-module-starter-plugin-cgiapp at rt.cpan.org>, or through the web 
interface at L<rt.cpan.org|http://rt.cpan.org>. I will be notified, and then you'll 
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Jaldhar H. Vyas, E<lt>jaldhar at braincells.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2015, Consolidated Braincells Inc.  All Rights Reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version, or

b) the Artistic License version 1.0 or a later version.

The full text of the license can be found in the LICENSE file included
with this distribution.

=head1 SEE ALSO

L<cgiapp-starter|cgiapp-starter>, L<titanium-starter|titanium-starter>, L<Module::Starter|Module::Starter>, 
L<Module::Starter::Simple|Module::Starter::Simple>, L<Module::Starter::Plugin::Template|Module::Starter::Plugin::Template>. 
L<CGI::Application|CGI::Application>, L<Titanium|Titanium>, L<HTML::Template|HTML::Template>

=cut

1;
