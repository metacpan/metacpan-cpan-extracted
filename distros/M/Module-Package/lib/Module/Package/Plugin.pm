##
# name:      Module::Package::Plugin
# abstract:  Base class for Module::Package author-side plugins
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - Module::Package
# - Module::Package::Tutorial

use 5.008003;
use utf8;

package Module::Package::Plugin;
use Moo 0.009008;

our $VERSION = '0.30';

use Cwd 0 ();
use File::Find 0 ();
use Module::Install 1.01 ();
use Module::Install::AuthorRequires 0.02 ();
use Module::Install::ManifestSkip 0.19 ();
use IO::All 0.41;

has mi => (is => 'rw');
has options => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        $self->mi->package_options;
    },
);

#-----------------------------------------------------------------------------#
# These 3 functions (initial, main and final) make up the Module::Package
# plugin API. Subclasses MUST override 'main', and should rarely override
# 'initial' and 'final'.
#-----------------------------------------------------------------------------#
sub initial {
    my ($self) = @_;
    # Load pkg/conf.yaml if it exists
    $self->eval_deps_list;
}

sub main {
    my ($self) = @_;
    my $class = ref($self);
    die "$class cannot be used as a Module::Package plugin. Use a subclass"
        if $class eq __PACKAGE__;
    die "$class needs to provide a method called 'main()'";
}

sub final {
    my ($self) = @_;

    $self->manifest_skip;

    # NOTE These must match Module::Install::Package::_final.
    $self->all_from;
    $self->requires_from;
    $self->install_bin;
    $self->install_share;
    $self->WriteAll;

    $self->write_deps_list;
}

#-----------------------------------------------------------------------------#
# This is where the useful methods (that author plugins can invoke) live.
#-----------------------------------------------------------------------------#
sub pm_file { return "$main::PM" }
sub pod_file { return "$main::POD" }
sub pod_or_pm_file { return "$main::POD" || "$main::PM" }

my $deps_list_file = 'pkg/deps_list.pl';
sub eval_deps_list {
    my ($self) = @_;
    return if not $self->options->{deps_list};
    my $data = '';
    if (-e 'Makefile.PL') {
        my $text = io('Makefile.PL')->all;
        if ($text =~ /.*\n__(?:DATA|END)__\r?\n(.*)/s) {
            $data = $1;
        }
    }
    if (-e $deps_list_file and -s $deps_list_file) {
        package main;
        require $deps_list_file;
    }
    elsif ($data) {
        package main;
        eval $data;
        die $@ if $@;
    }
}

sub write_deps_list {
    my ($self) = @_;
    return if not $self->options->{deps_list};
    my $text = $self->generate_deps_list;
    if (-e $deps_list_file) {
        my $old_text = io($deps_list_file)->all;
        $text .= "\n1;\n" if $text;
        if ($text ne $old_text) {
            warn "Updating $deps_list_file\n";
            io($deps_list_file)->print($text);
        }
        $text = '';
    }
    if (
        -e 'Makefile.PL' and
        io('Makefile.PL')->all =~ /^__(?:DATA|END)__$/m
    ) {
        my $perl = io('Makefile.PL')->all;
        my $old_perl = $perl;
        $perl =~ s/(.*\n__(?:DATA|END)__\r?\n).*/$1/s or die $perl;
        if (-e $deps_list_file) {
            io('Makefile.PL')->print($perl);
            return;
        }
        $perl .= "\n" . $text if $text;
        if ($perl ne $old_perl) {
            warn "Updating deps_list in Makefile.PL\n";
            io('Makefile.PL')->print($perl);
            if (-e 'Makefile') {
                sleep 1;
                io('Makefile')->touch;
            }
        }
    }
    elsif ($text) {
        warn <<"...";
Note: Can't find a place to write deps list, and deps_list option is true.
      touch $deps_list_file or add __END__ to Makefile.PL.
      See 'deps_list' in Module::Package::Plugin documentation.
Deps List:
${$_ = $text; chomp; s/^/    /mg; \$_}
...
    }
}

sub generate_deps_list {
    my ($self) = @_;
    my $base = Cwd::cwd();
    my %skip = map {($_, 1)}
        qw(Module::Package Module::Install),
        $self->skip_deps(ref($self)),
        (map "Module::Install::$_", qw(
            Admin AuthorRequires AutoInstall Base Bundle Can Compiler
            Deprecated DSL External Fetch Include Inline Makefile MakeMaker
            ManifestSkip Metadata Package PAR Run Scripts Share Win32 With
            WriteAll 
        ));
    my @skip;
    for my $module (keys %skip) {
        if ($skip{"Module::Install::$module"}) {
            push @skip, "${module}::";
        }
    }
    my @inc = ();
    File::Find::find(sub {
        return unless -f $_ and $_ =~ /\.pm$/;
        my $module = $File::Find::name;
        $module =~ s!inc[\/\\](.*)\.pm$!$1!;
        return if -e "$base/lib/$module.pm";
        $module =~ s!/+!::!g;
        return if $skip{$module};
        for my $prefix (@skip) {
            return if $module =~ /^\Q$prefix\E/;
        }
        push @inc, $module;
    }, 'inc');
    if (grep /^Module::Install::TestBase$/, @inc) {
        @inc = grep not(/^(Test::|Spiffy)/), @inc; 
    }
    if (not $Module::Package::plugin_version) {
        my $module = ref($self);
        $module =~ s/::[a-z].*//;
        unshift @inc, $module;
    };
    my $text = '';
    no strict 'refs';
    $text .= join '', map {
        my $version = ${"${_}::VERSION"} || '';
        if ($version) {
            "author_requires '$_' => '$version';\n";
        }
        else {
            "author_requires '$_';\n";
        }
    } @inc;
    $text = <<"..." . $text if $text;
# Deps list generated by:
author_requires 'Module::Package' => '$Module::Package::VERSION';

...
    return $text;
}

sub skip_deps {
    my ($self, $file) = @_;
    $file =~ s/^(.*)::[^A-Z].*$/$1/
        or die "Can't grok paackage '$file'";
    $file =~ s!::!/!g;
    $file .= '.pm';
    $file = $INC{$file} or return ();
    my $content = Module::Install::_readperl($file);
    return ($content =~ m/^use\s+([^\W\d]\w*(?:::\w+)*)\s+(?:[\d\.]+)/mg);
}

# We generate a MANIFEST.SKIP and add things to it.
# We add pkg/, because that should only contain author stuff.
# We add author only M::I plugins, so they don't get distributed.
sub manifest_skip {
    my ($self) = @_;
    return unless $self->options->{manifest_skip};
    $self->mi->manifest_skip;

    $self->set_author_only_defaults;
    my @skips = (
        "^pkg/\n",
        "^inc/.*\\.pod\n",
    );
    for (sort keys %INC) {
        my $path = $_;
        s!/!::!g;
        s!\.pm$!!;
        next unless /^Module::Install::/;
        no strict 'refs';
        push @skips, "^inc/$path\$\n"
            if ${"${_}::AUTHOR_ONLY"}
    }

    io('MANIFEST.SKIP')->append(join '', @skips);
    if (-e 'pkg/manifest.skip') {
        io('MANIFEST.SKIP')->append(io('pkg/manifest.skip')->all);
    }

    $self->mi->clean_files('MANIFEST MANIFEST.SKIP');
}

sub check_use_test_base {
    my ($self) = @_;
    my @files;
    File::Find::find(sub {
        return unless -f $_ and $_ =~ /\.(pm|t)$/;
        push @files, $File::Find::name;
    }, 't');
    for my $file (@files) {
        if (io($file)->all =~ /\bTest::Base\b/) {
            $self->mi->use_test_base;
            return;
        }
    }
}

sub check_use_testml {
    my ($self) = @_;
    my $found = 0;
    File::Find::find(sub {
        return unless -f $_ and $_ =~ /\.t$/;
        return unless io($_)->all =~ /\buse TestML\b/;
        $found = 1;
    }, 't');
    if ($found or -e 't/testml') {
        $self->mi->use_testml;
    }
}

sub check_test_common {
    my ($self) = @_;
    if (-e 't/common.yaml') {
        $self->mi->test_common_update;
    }
}

sub check_use_gloom {
    my ($self) = @_;
    my @files;
    File::Find::find(sub {
        return unless -f $_ and $_ =~ /\.pm$/;
        return if $File::Find::name eq 'lib/Gloom.pm';
        return if $File::Find::name eq 'lib/Module/Install/Gloom.pm';
        return unless io($_)->getline =~ /\bGloom\b/;
        push @files, $File::Find::name;
    }, 'lib');
    for my $file (@files) {
        $file =~ s/^lib\/(.*)\.pm$/$1/ or die;
        $file =~ s/\//::/g;
        $self->mi->use_gloom($file);
    }
}

sub strip_extra_comments {
    # TODO later
}

#-----------------------------------------------------------------------------#
# These functions are wrappers around Module::Install functions of the same
# names. They are generally safer (and simpler) to call than the real ones.
# They should almost always be chosen by Module::Package::Plugin subclasses.
#-----------------------------------------------------------------------------#
sub post_all_from {
    my $self = shift;
    push @{$self->{post_all_from} ||= []}, @_;
}
sub all_from {
    my $self = shift;
    $self->mi->_all_from(@_);
    $_->() for @{$self->{post_all_from} || []};
}
sub post_WriteAll {
    my $self = shift;
    push @{$self->{post_WriteAll} ||= []}, @_;
}
sub WriteAll {
    my $self = shift;
    $self->mi->_WriteAll(@_);
    $_->() for @{$self->{post_WriteAll} || []};
}
sub requires_from { my $self = shift; $self->mi->_requires_from(@_) }
sub install_bin { my $self = shift; $self->mi->_install_bin(@_) }
sub install_share { my $self = shift; $self->mi->_install_share(@_) }

#-----------------------------------------------------------------------------#
# Other housekeeping stuffs
#-----------------------------------------------------------------------------#
# This gets called very last on the author side.
sub replicate_module_package {
    my $target_file = 'inc/Module/Package.pm';
    if (-e 'inc/.author' and not -e $target_file) {
        my $source_file = $INC{'Module/Package.pm'}
            or die "Can't bootstrap inc::Module::Package";
        Module::Install::Admin->copy($source_file, $target_file);
    }
}

# TODO Check all versions possible here.
sub version_check {
    my ($self, $version) = @_;
    die <<"..."

Error! Something has gone awry:
    inc::Module::Package version=$inc::Module::Package::VERSION
    Module::Package version=$::Module::Package::VERSION
    Module::Install::Package version=$version
    Module::Package::Plugin version=$VERSION
Try upgrading Module::Package.

...
    unless $version == $VERSION and
        $version == $Module::Package::VERSION and
        $version == $inc::Module::Package::VERSION;
}

# This is a set of known AUTHOR_ONLY plugins. Until authors set this variable
# themselves, do it here to make sure these get added to the MANIFEST.SKIP and
# thus do not end up in the distributions, causing bloat.
sub set_author_only_defaults {
    my @known_author_only = qw(
        AckXXX
        AuthorRequires
        AutoLicense
        GitHubMeta
        ManifestSkip
        ReadmeFromPod
        ReadmeMarkdownFromPod
        Repository
        Stardoc
        TestBase
        TestML
        VersionCheck
    );
    for (@known_author_only) {
        no strict 'refs';
        ${"Module::Install::${_}::AUTHOR_ONLY"} = 1
            unless defined ${"Module::Install::${_}::AUTHOR_ONLY"};
    }
}

#-----------------------------------------------------------------------------#
# These are the usable subclasses that this module provides.  Currently there
# is only one, ':basic'. It does the minimum amount possible.  Even though it
# seems to do nothing, there is plenty of functionality that happens in the
# final() method.
#-----------------------------------------------------------------------------#
package Module::Package::Plugin::basic;
use Moo;
extends 'Module::Package::Plugin';

sub main {
    my ($self) = @_;
}

1;

=head1 SYNOPSIS

    package Module::Package::Name;

    package Module::Package::Name::flavor;
    use Moo;
    extends 'Module::Package::Plugin';

    sub main {
        my ($self) = @_;
        $self->mi->some_module_install_author_plugin;
        $self->mi->other_author_plugin;
    }

    1;

=head1 DESCRIPTION

This module is the base class for Module::Package plugins. 

=head1 EXAMPLE

Take a look at the L<Module::Package::Ingy> module, for a decent starting
point example. That plugin module is actually used to package Module::Package
itself.

=head1 API

To create a Module::Package plugin you need to subclass
Module::Package::Plugin and override the C<main> method, and possibly other
things. This section describes how that works.

Makefile.PL processing happens in the following order:

    - 'use inc::Module::Package...' is invoked
    - $plugin->initial is called
    - BEGIN blocks in Makefile.PL are run
    - $plugin->main is called
    - The body of Makefile.PL is run
    - $plugin->final is called

=head2 initial

This method is call during the processing of 'use inc::Module::Package'. You
probably don't need to subclass it. If you do you probably want to call the
SUPER method.

It runs the deps_list, if any and guesses the primary modules file path.

=head2 main

This is the method you must override. Do all the things you want. You can call
C<all_from>, if you need to get sequencing right, otherwise it gets called by
final(). Don't call C<WriteAll>, it get's called automatically in final().

=head2 final

This does all the things after the entire Makefile.PL body has run. You
probably don't need to override it.

=head1 OPTIONS

The following options are available for use from the Makefile.PL:

    use Module::Package 'Foo:bar',
        deps_list => 0|1,
        install_bin => 0|1,
        install_share => 0|1,
        manifest_skip => 0|1,
        requires_from => 0|1;

These options can be used by any subclass of this module.

=head2 deps_list

Default is 1.

This option tells Module::Package to generate a C<author_requires> deps list,
when you run the Makefile.PL. This list will go in the file
C<pkg/deps_list.pl> if that exists, or after a '__END__' statement in your
Makefile.PL. If neither is available, a reminder will be warned (only when the
author runs it).

This list is important if you want people to be able to collaborate on your
modules easily.

=head2 install_bin

Default is 1.

All files in a C<bin/> directory will be installed. It will call the
C<install_script> plugin for you. Set this option to 0 to disable it.

=head2 install_share

Default is 1.

All files in a C<share/> directory will be installed. It will call the
C<install_share> plugin for you. Set this option to 0 to disable it.

=head2 manifest_skip

Default is 1.

This option will generate a sane MANIFEST.SKIP for you and delete it again
when you run C<make clean>. You can add your own skips in the file called
C<pkg/manifest.skip>. You almost certainly want this option on. Set to 0 if
you are weird.

=head2 requires_from

Default is 1.

This option will attempt to find all the requirements from the primary module.
If you make any of your own requires or requires_from calls, this option will
do nothing.
