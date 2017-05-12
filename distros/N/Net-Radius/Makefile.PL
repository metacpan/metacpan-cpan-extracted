use ExtUtils::MakeMaker;

my $version = (split(m/:/, qx{svnversion 2>/dev/null}, 2))[0];
$version = sprintf("%d", (q$Revision: 102 $ =~ /\d+/g)[0])
    unless $version;
$version /= 1000;
$version += 2;
$version = sprintf("%0.3f", $version);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Net::Radius',
    VERSION        => $version,
    'PM' => {
	     map { ("$_.pm" => "\$(INST_LIBDIR)/$_.pm") }
	         qw(Radius/Packet Radius/Dictionary)
	    },
    PREREQ_PM    => {
	'Digest::MD5' => 0,
	'Test::More' => 0,
	'Test::Warn' => 0,
	},
    'dist' => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
);
