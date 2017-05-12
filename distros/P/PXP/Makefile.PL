use 5.008005;
use ExtUtils::MakeMaker;

my $tla_tree_version = `tla tree-version`;
my $tla_version = `tla parse-package-name -v $tla_tree_version`;
chomp $tla_version;
my $tla_patchlevel = `tla logs | tail -1 | cut -d '-' -f2`;
$VERSION = $tla_version . '.' . $tla_patchlevel;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PXP',
    clean             => { FILES => "pxp.log" },
    VERSION           => $VERSION,
    PREREQ_PM         => {
			  Log::Log4perl => 0.40,
			  XML::Simple => 2.09,
			  I18N::LangTags => 0.33,
			  XML::XPath => 1.13,
			 },
    ($] >= 5.008 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PXP.pm', # retrieve abstract from module
       AUTHOR         => 'David Barth <dbarth@idealx.com>') : ()),
);

open MANIFEST, "<MANIFEST";
my @old_lines = grep !/^META.yml/, <MANIFEST>;
close MANIFEST;
my @new_lines = map { "$_\n" } (
	qw(
                Changes
		Makefile.PL
		MANIFEST
		README
	),
	"lib/PXP.pm",
	glob("lib/PXP/*.pm"),
	glob("t/[0-9]*.t"),
);

if (join(',', @old_lines) ne join(',', @new_lines)) {
	print "Creating MANIFEST file\n";
	open MANIFEST, ">MANIFEST" or die "Can't write MANIFEST: $!\n";
	print MANIFEST @new_lines;
	close MANIFEST;
}
package MY;

sub depend {
    return <<MAKE

Makefile: {arch}

MAKE
}
