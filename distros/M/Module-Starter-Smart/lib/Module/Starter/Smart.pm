package Module::Starter::Smart;

use warnings;
use strict;

=encoding utf8

=head1 NAME

Module::Starter::Smart - A Module::Starter plugin for adding new modules into
an existing distribution

=head1 VERSION

version 0.0.8

=cut

our $VERSION = '0.0.8';

=head1 SYNOPSIS

    use Module::Starter qw/Module::Starter::Smart/;
    Module::Starter->create_distro(%args);

    # or in ~/.module-starter/config
    plugin: Module::Starter::Smart

    # create a new distribution named 'Foo-Bar'
    $ module-starter --module=Foo::Bar

    # ... then add a new module
    $ module-starter --module=Foo::Bar::Me --distro=Foo-Bar

=head1 DESCRIPTION

Module::Starter::Smart is a simple helper plugin for L<Module::Starter>.  It
subclasses L<Module::Starter::Simple> and provides its own implementation for
several file creation subroutines, such as C<create_distro>, C<create_modules>,
C<create_t>, and so on.  These new implementations were designed to work
with existing distributions.

When invoked, the plugin checks if the distribution is already created.  If so,
the plugin would bypass C<create_basedir>) and go ahead pull in all the
existing modules and test files; these information would be used later in the
corresponding file creation subroutines for skipping already-created files.

B<UPDATE>: This plugin only covers the simplest use cases.  For advanced usage,
check out L<Module::Starter::AddModule>.


=head2 Example

Say you have an existing distro, Goof-Ball, and you want to add a new module,
Goof::Troop.

    % ls -R Goof-Ball
    Build.PL  Changes   MANIFEST  README    lib/      t/

    Goof-Ball/lib:
    Goof/

    Goof-Ball/lib/Goof:
    Ball.pm

    Goof-Ball/t:
    00.load.t       perlcritic.t    pod-coverage.t  pod.t

Go to the directory containing your existing distribution and run
module-starter, giving it the names of the existing distribution and the new
module:

    % module-starter --distro=Goof-Ball --module=Goof::Troop
    Created starter directories and files

    % ls -R Goof-Ball
    Build.PL  Changes   MANIFEST  README    lib/      t/

    Goof-Ball/lib:
    Goof/

    Goof-Ball/lib/Goof:
    Ball.pm   Troop.pm

    Goof-Ball/t:
    00.load.t       perlcritic.t    pod-coverage.t  pod.t

Troop.pm has been added to Goof-Ball/lib/Goof.

=cut

use parent qw(Module::Starter::Simple);

use ExtUtils::Command qw/mkpath/;
use File::Spec;

# Module implementation here
use subs qw/_unique_sort _pull_modules _list_modules _pull_t _list_t/;

=head1 INTERFACE

No public methods.  The module works by subclassing Module::Starter::Simple and
rewiring its internal behaviors.

=cut

sub create_distro {
    my $class = shift;
    my $self = ref $class? $class: $class->new(@_);

    my $basedir =
        $self->{dir} ||
        $self->{distro} ||
        do {
            (my $first = $self->{modules}[0]) =~ s/::/-/g;
            $first;
        };

    $self->{modules} = [ _unique_sort _pull_modules($basedir), @{$self->{modules}} ];
    $self->SUPER::create_distro;
}

sub create_basedir {
    my $self = shift;
    return $self->SUPER::create_basedir(@_) unless -e $self->{basedir} && !$self->{force};
    $self->progress( "Found $self->{basedir}.  Use --force if you want to stomp on it." );
}

sub create_modules {
    my $self = shift;
    $self->SUPER::create_modules(@_);
}

sub _create_module {
    my $self = shift;
    my $module = shift;
    my $rtname = shift;

    my @parts = split( /::/, $module );
    my $filepart = (pop @parts) . ".pm";
    my @dirparts = ( $self->{basedir}, 'lib', @parts );
    my $manifest_file = join( "/", "lib", @parts, $filepart );
    if ( @dirparts ) {
        my $dir = File::Spec->catdir( @dirparts );
        if ( not -d $dir ) {
            local @ARGV = $dir;
            mkpath @ARGV;
            $self->progress( "Created $dir" );
        }
    }

    my $module_file = File::Spec->catfile( @dirparts,  $filepart );

    $self->{module_file}{$module} =
        File::Spec->catfile('lib', @parts, $filepart);

    if (-e $module_file) {
        $self->progress( "Skipped $module_file" );
    } else {
        open( my $fh, ">", $module_file ) or die "Can't create $module_file: $!\n";
        print $fh $self->module_guts( $module, $rtname );
        close $fh;
        $self->progress( "Created $module_file" );
    }

    return $manifest_file;
}

sub create_t {
    my $self = shift;
    _unique_sort $self->SUPER::create_t(@_), _pull_t $self->{basedir};
}

sub _create_t {
    my $self     = shift;
    my $testdir  = @_ == 2 ? 't' : shift;
    my $filename = shift;
    my $content  = shift;

    my @dirparts = ( $self->{basedir}, $testdir );
    my $tdir = File::Spec->catdir( @dirparts );
    if ( not -d $tdir ) {
        local @ARGV = $tdir;
        mkpath();
        $self->progress( "Created $tdir" );
    }

    my $fname = File::Spec->catfile( @dirparts, $filename );

    if (-e $fname) {
        $self->progress( "Skipped $fname" );
    } else {
        open( my $fh, ">", $fname ) or die "Can't create $fname: $!\n";
        print $fh $content;
        close $fh;
        $self->progress( "Created $fname" );
    }

    return File::Spec->catfile( $testdir, $filename );
}

sub create_Makefile_PL {
    my $self = shift;
    my $main_module = shift;

    my @parts = split( /::/, $main_module );
    my $pm = pop @parts;
    my $main_pm_file = File::Spec->catfile( "lib", @parts, "${pm}.pm" );
    $main_pm_file =~ s{\\}{/}g; # even on Win32, use forward slash

    my $fname = File::Spec->catfile( $self->{basedir}, "Makefile.PL" );

    if (-e $fname) {
        $self->progress( "Skipped $fname" );
    } else {
        open( my $fh, ">", $fname ) or die "Can't create $fname: $!\n";
        print $fh $self->Makefile_PL_guts($main_module, $main_pm_file);
        close $fh;
        $self->progress( "Created $fname" );
    }

    return "Makefile.PL";
}

sub create_Build_PL {
    my $self = shift;
    my $main_module = shift;

    my @parts = split( /::/, $main_module );
    my $pm = pop @parts;
    my $main_pm_file = File::Spec->catfile( "lib", @parts, "${pm}.pm" );
    $main_pm_file =~ s{\\}{/}g; # even on Win32, use forward slash

    my $fname = File::Spec->catfile( $self->{basedir}, "Build.PL" );

    if (-e $fname) {
        $self->progress( "Skipped $fname" );
    } else {
        open( my $fh, ">", $fname ) or die "Can't create $fname: $!\n";
        print $fh $self->Build_PL_guts($main_module, $main_pm_file);
        close $fh;
        $self->progress( "Created $fname" );
    }

    return "Build.PL";
}

sub create_Changes {
    my $self = shift;

    my $fname = File::Spec->catfile( $self->{basedir}, "Changes" );

    if (-e $fname) {
        $self->progress( "Skipped $fname" );
    } else {
        open( my $fh, ">", $fname ) or die "Can't create $fname: $!\n";
        print $fh $self->Changes_guts();
        close $fh;
        $self->progress( "Created $fname" );
    }

    return "Changes";
}

sub create_README {
    my $self = shift;
    my $build_instructions = shift;

    my $fname = File::Spec->catfile( $self->{basedir}, "README" );

    if (-e $fname) {
        $self->progress( "Skipped $fname" );
    } else {
        open( my $fh, ">", $fname ) or die "Can't create $fname: $!\n";
        print $fh $self->README_guts($build_instructions);
        close $fh;
        $self->progress( "Created $fname" );
    }

    return "README";
}

# Utility functions
sub _pull_modules {
    my $basedir = shift;
    return unless $basedir;
    my $libdir = File::Spec->catdir($basedir, "lib");
    return unless $libdir && -d $libdir;
    return _list_modules($libdir);
}

sub _list_modules {
    my $dir = shift;
    my $prefix = shift || '';

    opendir my $dh, $dir or die "Cannot opendir $dir: $!";
    my @entries = grep { !/^\.{1,2}/ } readdir $dh;
    close $dh;

    my @modules = ();
    for (@entries) {
        my $name = File::Spec->catfile($dir, $_);
        push @modules, _list_modules($name, $prefix ? "$prefix\:\:$_": $_) and next if -d $name;
        $_ =~ s/\.pm$// and push @modules, $prefix ? "$prefix\:\:$_": $_ if $name =~ /\.pm$/;
    }

    return sort @modules;
}

sub _pull_t {
    my $basedir = shift;
    return unless $basedir;
    my $tdir = File::Spec->catdir($basedir, "t");
    return unless $tdir && -d $tdir;
    return _list_t($tdir);
}

sub _list_t {
    my $dir = shift;

    opendir my $dh, $dir or die "Cannot opendir $dir: $!";
    my @entries = grep { !/^\.{1,2}/ && /\.t$/ } readdir $dh;
    close $dh;

    map { "t/$_"  } @entries;
}

# Remove duplicated entries
sub _unique_sort {
    my %bag = map { $_ => 1 } @_;
    sort keys %bag;
}

# Magic true value required at end of module
1;

__END__


=head1 DEPENDENCIES

Module::Starter::Smart subclasses L<Module::Starter::Simple>.

=head1 INCOMPATIBILITIES

The plugin works perfectly with other template plugins, i.e.
L<Module::Starter::PBP> (I started using it to develop this module)

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-module-starter-smart@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 ACKNOWLEDGEMENT

Special thanks to the following contributors:

=over 4

=item *
David Messina

=item *
David Steinbrunner

=item *
Andrew Kirkpatrick

=item *
Markus Böhme

=back

=head1 AUTHOR

Ruey-Cheng Chen  C<< <rueycheng@cpan.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, 2012, 2017 Ruey-Cheng Chen C<< <rueycheng@cpan.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
