use strict;
use warnings;

package Module::Starter::Plugin::RTx;
use base 'Module::Starter::Simple';
use Carp;
our $VERSION = '0.02';

sub create_MI_RTx_Makefile_PL {
    my $self        = shift;
    my $main_module = shift || $self->{main_module};
    my $fname       = File::Spec->catfile( $self->{basedir}, 'Makefile.PL' );
    $self->{main_module_file} = join( '/', 'lib', split /::/, $main_module ) . '.pm';

    $self->create_file(
        $fname,
        <<EOF
use inc::Module::Install;
RTx('$self->{distro}');
all_from('$self->{main_module_file}');
&WriteAll;
EOF
    );

    $self->progress("Created $fname");

    return 'Makefile.PL';
}

sub create_build {
    my $self = shift;

    # get the builders
    my @builders    = @{ $self->get_builders };
    my $builder_set = Module::Starter::BuilderSet->new();

    # Remove mutually exclusive and unsupported builders
    @builders = $builder_set->check_compatibility(@builders);

    # compile some build instructions, create a list of files generated
    # by the builders' create_* methods, and call said methods

    return (
        files           => [ $self->create_MI_RTx_Makefile_PL ],
        instructions    => join( "\n\n", $self->build_instructions ),
        manifest_method => 'create_MI_MANIFEST',
    );
}

sub build_instructions {
    my $self = shift;
    my $module = shift || $self->{main_module};

    my @out;

    push @out, 'To install this module, run the following commands:';

    my @commands = (
        'perl Makefile.PL',
        'make',
        'make install',
        "make initdb # only if there is etc/initialdata and it hasn't been run before",
    );

    push @out, join( "\n", map { "    $_" } @commands );
    push @out,
      "add $module to \@Plugins in RT's etc/RT_SiteConfig.pm:",
      "    Set( \@Plugins, qw(... $module) );";
    return @out;

}

sub create_distro {
    my $either = shift;

    ( ref $either ) or $either = $either->new(@_);
    my $self    = $either;
    my $modules = $self->{modules} || [];
    my @modules = map { split /,/ } @{$modules};
    croak "No modules specified.\n" unless @modules;
    for (@modules) {
        croak "Invalid module name: $_" unless /\A[a-z_]\w*(?:::[\w]+)*\Z/i;
    }

    croak "Must specify an author\n"        unless $self->{author};
    croak "Must specify an email address\n" unless $self->{email};
    ( $self->{email_obfuscated} = $self->{email} ) =~ s/@/ at /;

    $self->{license}      ||= 'perl';
    $self->{ignores_type} ||= 'generic';

    $self->{main_module} = $modules[0];
    if ( not $self->{distro} ) {
        $self->{distro} = $self->{main_module};
        $self->{distro} =~ s/::/-/g;
    }

    $self->{basedir} = $self->{dir} || $self->{distro};
    $self->create_basedir;

    $self->create_modules(@modules);
    $self->create_ignores;
    my %build_results = $self->create_build();
    $self->create_Changes;
    $self->create_README;

    $self->create_MANIFEST( $build_results{'manifest_method'} );

    return;

}

sub create_README {
    my $self = shift;
    chdir $self->{basedir};
    symlink( $self->{main_module_file}, 'README.pod' );
    chdir '..';
}

sub _module_header {
    my $self    = shift;
    my $module  = shift;
    my $rtname  = shift;
    my $content = <<EOF;
use warnings;
use strict;

package $module;

our \$VERSION = "0.01";

EOF
    return $content;
}

sub module_guts {
    my $self   = shift;
    my $module = shift;
    my $rtname = shift;

    # Sub-templates
    my $header = $self->_module_header( $module, $rtname );
    my $install = join "\n\n", $self->build_instructions;
    my $license = $self->_module_license( $module, $rtname );

    my $content = <<"HERE";
$header

1;
__END__

\=head1 NAME

$module - The great new $module!

\=head1 VERSION

Version 0.01

\=head1 INSTALLATION

$install

\=head1 AUTHOR

$self->{author}, <$self->{email_obfuscated}>

$license

HERE
    return $content;
}

1;

__END__

=head1 NAME

Module::Starter::Plugin::RTx - Module::Starter for RT extensions

=head1 SYNOPSIS

    use Module::Starter 'Module::Starter::Plugin::RTx';
    Module::Starter->create_distro(%args);

=head1 DESCRIPTION

This is a plugin for Module::Starter that builds you a skeleton
RTx module.

=head1 SEE ALSO

L<Module::Starter>

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


