# Copyright (C) 2003-2007, 2013 by the gtk2-perl team (see the file AUTHORS
# for the full list)
#
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.
#
# See the LICENSE file in the top-level directory of this distribution for the
# full license terms.

BEGIN { require 5.008; }

use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Spec;
use Cwd;

# minimum required version of dependencies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.300',
	'perl-ExtUtils-PkgConfig' => '1.030',
	'perl-Glib'               => '1.220',
	'perl-Cairo'              => '1.000',
	'pango'                   => '1.0.0',
);

our %PREREQ_PM = (
	'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
	'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
	'Glib'                => $build_reqs{'perl-Glib'},
);


#
# look for our prerequisites.  if they can't be found, warn and exit with
# status 0 to indicate to CPAN testers that their system isn't supported.
#
unless (eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
           . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Glib::CodeGen;"
           . "use Glib::MakeHelper;"
           . "1") {
	warn <<"__EOW__";
Pre-requisites not found:
$@
Please install them manually.
__EOW__
	exit 0;
}

# all the generated stuff will go into this subdir...
mkdir 'build', 0777;

#
# look for our packages.  if they can't be found, warn and exit with status 0
# to indicate to CPAN testers that their system isn't supported.
#
my %pango_pkgcfg;
unless (eval { %pango_pkgcfg = ExtUtils::PkgConfig->find ('pango'); 1; }) {
	warn $@;
	exit 0;
}

#
# retrieve pango's version
#
my @pango_version = split /\./, $pango_pkgcfg{modversion};

#
# decide what files to use in the build based on the version we found.
#
my @xs_files = ();
my @xs_lists =
	Glib::MakeHelper->select_files_by_version ("xs_files", @pango_version);
foreach my $filename (@xs_lists) {
	my @names = Glib::MakeHelper->read_source_list_file ($filename);
	push @xs_files, @names;
}

#
# if pango >= 1.10, we depend on Cairo
#
my $have_cairo = 0;
my %pangocairo_pkgcfg;
if ($pango_version[0] > 1 || ($pango_version[0] == 1 && $pango_version[1] >= 10)) {
	$PREREQ_PM{Cairo} = $build_reqs{'perl-Cairo'};
	unless (eval "use Cairo '$build_reqs{'perl-Cairo'}'; 1;") {
		warn <<"__EOW__";
Pre-requisites not found:
$@
Please install them manually.
__EOW__
		exit 0;
	}

	unless (eval { %pangocairo_pkgcfg = ExtUtils::PkgConfig->find ('pangocairo'); 1; }) {
		warn $@;
		exit 0;
	}

	$have_cairo = 1;
}

#
# create version macros
#
ExtUtils::PkgConfig->write_version_macros(
	"build/pango-perl-versions.h",
	pango => "PANGO",
);

#
# since we've started down the dark path of breaking from standard MakeMaker,
# forever will it dominate our destiny; we must specify install paths for the
# modules and man files by hand.
#
our %pm_files = (
	'lib/Pango.pm' => '$(INST_LIBDIR)/Pango.pm',
);
our %pod_files = (
	'lib/Pango.pm' => '$(INST_MAN3DIR)/Pango.$(MAN3EXT)',
	Glib::MakeHelper->do_pod_files (@xs_files),
);

#
# autogeneration
#
# we have a whole lot of types which need cast macros, typemap entries,
# and package mapping registration; instead of writing this by hand, we
# use a set of map files which define how things are laid out, and then use
# some boilerplate code to convert those mappings into a header, typemap,
# and xsh file.  see the docs for Glib::CodeGen for more info.
#
# all possible maps must be available at xsubpp time, as xsubpp processes
# all code, even inside #ifdefs.
Glib::CodeGen->parse_maps ('pango-perl', input => [<maps-[0-9]\.[0-9]*>]);

# one more command generates code to boot all the various extra XS modules.
# we need this because we have lots of XS files without corresponding PMs to
# bootstrap them.
Glib::CodeGen->write_boot (xs_files => \@xs_files);

#
# now we're ready to start creating the makefile... finally.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.
#

my @deps = qw/Glib/;
my $inc = $pango_pkgcfg{cflags} . ' -I./build ';
my $libs = $pango_pkgcfg{libs};
if ($have_cairo) {
	push @deps, qw/Cairo/;
	$inc .= $pangocairo_pkgcfg{cflags};
	$libs .= ' ' . $pangocairo_pkgcfg{libs};
}

my @typemaps = map { File::Spec->catfile(cwd(), $_) }
                   qw(build/pango-perl.typemap pango.typemap);

my $pango = ExtUtils::Depends->new ('Pango', @deps);
$pango->set_inc ($inc);
$pango->set_libs ($libs);
$pango->add_pm (%pm_files);
$pango->add_xs (@xs_files);
$pango->add_typemaps (@typemaps);

$pango->install (qw(pango-perl.h
                    build/pango-perl-autogen.h
                    build/pango-perl-versions.h
                    doctypes));
$pango->save_config ('build/IFiles.pm');

# exports list needed for win32, unused on others
my @exports = Glib::MakeHelper->read_source_list_file ('pango.exports');

my %meta_merge = (
        q(meta-spec)          => {
            version => '2',
            url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        },
        author              =>
            ['gtk2-perl Team <gtk-perl-list at gnome dot org>'],
        release_status      => 'stable',
        # valid values: https://metacpan.org/module/CPAN::Meta::Spec#license
        license             => 'lgpl_2_1',
        resources => {
            license     => 'http://www.gnu.org/licenses/lgpl-2.1.html',
            homepage    => 'http://gtk2-perl.sourceforge.net',
            x_MailingList =>
                'https://mail.gnome.org/mailman/listinfo/gtk-perl-list',
            x_twitter   => 'https://twitter.com/GTKPerl',
            bugtracker  => {
                    web     =>
                    'http://rt.cpan.org/Public/Dist/Display.html?Name=Pango',
                    mailto  => 'bug-Pango [at] rt.cpan.org',
            },
            repository  => {
                    url     => 'git://git.gnome.org/perl-Pango',
                    type    => 'git',
                    web     => 'http://git.gnome.org/browse/perl-Pango',
            },
        },
        prereqs => {
            configure => {
                requires => {%PREREQ_PM}, # no direct ref for 5.14 compatibility
            },
        },
        no_index           => {
            file => \@xs_files,
        },
);

WriteMakefile(
    NAME          => 'Pango',
    VERSION_FROM  => 'lib/Pango.pm',
    ABSTRACT_FROM => 'lib/Pango.pm',
    PREREQ_PM     => \%PREREQ_PM,
    XSPROTOARG    => '-noprototypes',
    MAN3PODS      => \%pod_files,
    FUNCLIST      => \@exports,
    DL_FUNCS      => { Pango => [] },
    META_MERGE    => \%meta_merge,
    $pango->get_makefile_vars,
);

#
# extra makefile override stuff
#
sub MY::postamble
{
	return Glib::MakeHelper->postamble_precompiled_headers (qw/pango-perl.h/)
	     . Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs_full (
			DEPENDS => $pango,
			DOCTYPES => 'doctypes',
			COPYRIGHT_FROM => 'copyright.pod');

}
