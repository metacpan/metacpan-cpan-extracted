use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker 6.30;

if ($^O =~ /linux/) {
    ; # OK
} elsif ($^O =~ /freebsd/) {
    my($osver) = (qx(uname -r) =~ /^([0-9.]+)/);
    if (defined $osver && $osver >= 8.3) {
        ; # OK
    } else {
        print "Only support FreeBSD >= 8.3 because of lack of posix_fadvise(2)\n";
        exit 0;
    }
} else {
    print "No support for your OS\n";
    exit 0;
}

my %WriteMakefileArgs = (
    "ABSTRACT_FROM" => "lib/Sys/PageCache.pm",
    "AUTHOR" => "HIROSE Masaaki",
    "BUILD_REQUIRES" => {},
    "CONFIGURE_REQUIRES" => {
        "ExtUtils::MakeMaker" => "6.30"
    },
    "DISTNAME" => "Sys-PageCache",
    "EXE_FILES" => [
        "bin/pagecache-check.pl",
        "bin/pagecache-clear.pl",
    ],
    "LICENSE" => "perl",
    "NAME" => "Sys::PageCache",
    "PREREQ_PM" => {
        "Pod::Usage" => "1.36",
    },
    "TEST_REQUIRES" => {
        "File::Temp"   => 0,
        "Test::More"   => 0,
        "Test::Output" => 0,
    },
    "VERSION_FROM" => "lib/Sys/PageCache.pm",
    "test" => {
        "TESTS" => "t/*.t"
    },
    LIBS   => [''],
    DEFINE => '',
    INC    => '-I.',
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
    my $br = $WriteMakefileArgs{BUILD_REQUIRES};
    for my $mod ( keys %$tr ) {
        if ( exists $br->{$mod} ) {
            $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
        } else {
            $br->{$mod} = $tr->{$mod};
        }
    }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
    my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
    my $pp = $WriteMakefileArgs{PREREQ_PM};
    for my $mod ( keys %$br ) {
        if ( exists $pp->{$mod} ) {
            $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
        } else {
            $pp->{$mod} = $br->{$mod};
        }
    }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
