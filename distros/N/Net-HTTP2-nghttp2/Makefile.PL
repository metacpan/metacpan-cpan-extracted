use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Try to find nghttp2 via pkg-config
my ($cflags, $libs) = find_nghttp2();

WriteMakefile(
    NAME             => 'Net::HTTP2::nghttp2',
    VERSION_FROM     => 'lib/Net/HTTP2/nghttp2.pm',
    ABSTRACT         => 'Perl XS bindings for nghttp2 HTTP/2 library',
    AUTHOR           => 'John Napiorkowski <jjnapiork@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.016',

    PREREQ_PM => {
        'XSLoader'     => 0,
        'Scalar::Util' => 0,
        'Carp'         => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.52',
        'Alien::nghttp2'      => 0,
    },

    # XS configuration
    OBJECT  => '$(O_FILES)',
    CCFLAGS => "$Config{ccflags} $cflags",
    LIBS    => [$libs],
    INC     => '-I.',

    # Metadata
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jjn1056/Net-HTTP2-nghttp2.git',
                web  => 'https://github.com/jjn1056/Net-HTTP2-nghttp2',
            },
            bugtracker => {
                web => 'https://github.com/jjn1056/Net-HTTP2-nghttp2/issues',
            },
        },
    },
);

sub find_nghttp2 {
    my ($cflags, $libs);

    # Try pkg-config first
    if (my $pc = find_pkg_config()) {
        $cflags = `$pc --cflags libnghttp2 2>/dev/null`;
        $libs   = `$pc --libs libnghttp2 2>/dev/null`;

        if ($? == 0 && $libs) {
            chomp($cflags, $libs);
            print "Found nghttp2 via pkg-config:\n";
            print "  CFLAGS: $cflags\n";
            print "  LIBS:   $libs\n";
            return ($cflags, $libs);
        }
    }

    # Try Alien::nghttp2 if available
    eval {
        require Alien::nghttp2;
        $cflags = Alien::nghttp2->cflags;
        $libs   = Alien::nghttp2->libs;
        print "Found nghttp2 via Alien::nghttp2:\n";
        print "  CFLAGS: $cflags\n";
        print "  LIBS:   $libs\n";
    };
    return ($cflags, $libs) if $libs;

    # Try common locations
    for my $prefix (qw(/opt/homebrew /usr/local /usr)) {
        if (-f "$prefix/include/nghttp2/nghttp2.h") {
            $cflags = "-I$prefix/include";
            $libs   = "-L$prefix/lib -lnghttp2";
            print "Found nghttp2 at $prefix:\n";
            print "  CFLAGS: $cflags\n";
            print "  LIBS:   $libs\n";
            return ($cflags, $libs);
        }
    }

    # Not found
    die <<'ERROR';

ERROR: nghttp2 library not found!

Please install nghttp2 development files:
  - macOS:   brew install nghttp2
  - Debian:  apt-get install libnghttp2-dev
  - RHEL:    yum install libnghttp2-devel

Alternatively, install Alien::nghttp2 from CPAN:
  cpanm Alien::nghttp2

ERROR
}

sub find_pkg_config {
    for my $cmd (qw(pkg-config pkgconf)) {
        my $out = `$cmd --version 2>/dev/null`;
        return $cmd if $? == 0;
    }
    return;
}
