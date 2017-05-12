#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Glib::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;
use ExtUtils::MakeMaker;

mkdir 'build', 0777;

chomp(my $pm_includes = `pkg-config --variable includedir loudmouth-1.0`);
my @lm_headers = glob($pm_includes.'/loudmouth-1.0/loudmouth/*.h');

my %pkg_config = ExtUtils::PkgConfig->find('loudmouth-1.0');

system(q(glib-mkenums --fhead "#ifndef __PERLMOUTH_GTYPES_H__\n" ).
					q(--fhead "#define __PERLMOUTH_GTYPES_H__ 1\n\n" ).
					q(--fhead "#include <glib-object.h>\n\n" ).
					q(--fhead "G_BEGIN_DECLS\n\n" ).
					q(--eprod "#define PERLMOUTH_TYPE_@ENUMSHORT@ perlmouth_@enum_name@_get_type()\n" ).
					q(--eprod "GType perlmouth_@enum_name@_get_type (void) G_GNUC_CONST;\n" ).
					q(--ftail "G_END_DECLS\n\n" ).
					q(--ftail "#endif /* __PERLMOUTH_GTYPES_H__ */\n" ).
					"@lm_headers > build/perlmouth-gtypes.h");

system(q(glib-mkenums --fhead "#include <loudmouth/loudmouth.h>\n" ).
					q(--fhead "#include \"perlmouth.h\"\n\n" ).
					q(--vhead "static const G@Type@Value _perlmouth_@enum_name@_values[] = {" ).
					q(--vprod "	{ @VALUENAME@, \"@VALUENAME@\", \"@valuenick@\" }," ).
					q(--vtail "	{ 0, NULL, NULL }\n};\n\n" ).
					q(--vtail "GType\nperlmouth_@enum_name@_get_type (void) {\n" ).
					q(--vtail "	static GType t = 0;\n" ).
					q(--vtail "	if (!t)\n" ).
					q(--vtail "		t = g_@type@_register_static(\"@EnumName@\", _perlmouth_@enum_name@_values);\n" ).
					q(--vtail "	return t;\n}\n\n" ).
					"@lm_headers > build/perlmouth-gtypes.c");

Glib::CodeGen->parse_maps('loudmouth');
Glib::CodeGen->write_boot(ignore => qr/^Net::Jabber::Loudmouth$/);

our $loudmouth = ExtUtils::Depends->new('Net::Jabber::Loudmouth', 'Glib');
our @xs_files = <xs/*.xs>;

$loudmouth->add_xs(@xs_files);
$loudmouth->add_c('perlmouth.c', 'build/perlmouth-gtypes.c');
$loudmouth->add_typemaps(File::Spec->rel2abs(File::Spec->catfile('build', 'loudmouth.typemap')));
$loudmouth->set_inc($pkg_config{cflags}.' -I./build -Werror');
$loudmouth->set_libs($pkg_config{libs});
$loudmouth->install(File::Spec->catfile('build', 'loudmouth-autogen.h'));
$loudmouth->add_pm(
	'pm/Loudmouth.pm'	=> '$(INST_LIBDIR)/Loudmouth.pm'
);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME				=> 'Net::Jabber::Loudmouth',
    VERSION_FROM		=> File::Spec->catfile('pm', 'Loudmouth.pm'),
	XSPROTOARG			=> '-noprototypes',
	PREREQ_PM			=> {
		'Glib'	=> '1.093'
	},
	MAN3PODS			=> {
		'pm/Loudmouth.pm'	=> '$(INST_MAN3DIR)/Net::Jabber::Loudmouth.$(MAN3EXT)',
		Glib::MakeHelper->do_pod_files(@xs_files)
	},
	$loudmouth->get_makefile_vars()
);

package MY;

sub postamble {
	return Glib::MakeHelper->postamble_clean()
		. Glib::MakeHelper->postamble_docs_full(DEPENDS => $main::loudmouth);
}
