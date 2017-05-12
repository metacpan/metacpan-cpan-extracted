use 5.006;
use ExtUtils::MakeMaker;
use Config;

# Grab out any custom cmdline args
my %args = (
	pkg_name => 'eidetic',
	name     => 'eidetic',
	DESTDIR  => undef,
);

my @pass_args;
while (my $arg = shift @ARGV) {
    my ($key, $value) = split /=/, $arg;
    if (exists $args{$key}) {
        $args{$key} = $value;
    } else {
        push @pass_args, $arg;
    }
}
@ARGV = @pass_args;

my %opts=(
    INSTALLDIRS       => 'site',
    NAME              => 'SystemManagement::GSP',
    VERSION_FROM      => 'lib/SystemManagement/GSP.pm', # finds $VERSION
    PREREQ_PM         => {
				'Test::More' => 0,
				'Expect'     => 0,
				'IO::Socket::INET' => 0,
			 },
    # retrieve abstract from module
    ABSTRACT_FROM  => 'lib/SystemManagement/GSP.pm',
    AUTHOR         => 'Kees Cook, OSDL <kees@osdl.org>',
);

if ($ExtUtils::MakeMaker::VERSION > 5.45) {
        $opts{'PREREQ_FATAL'} = 1,
}

# I hate perl's MakeMaker so much.
# This puts us in the site_perl directory, not dependant on any version
# of perl.
if (defined($Config{'sitelib_stem'}) && $Config{'sitelib_stem'} ne "") {
        print "stem is: $Config{'sitelib_stem'}\n";
        $opts{'INSTALLSITELIB'} = "";
        $opts{'INSTALLSITELIB'} = $args{'DESTDIR'}
                if ($] >= 5.008 ||
                    $ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/);
        $opts{'INSTALLSITELIB'} .= $Config{'sitelib_stem'};
}

WriteMakefile(%opts);
