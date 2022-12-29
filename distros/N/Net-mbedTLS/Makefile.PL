use strict;
use warnings;
use autodie;

use Config;
use Cwd;
use ExtUtils::CBuilder;
use ExtUtils::MakeMaker::CPANfile;
use File::Temp;

my $MBEDTLS_BASE = $ENV{'NET_MBEDTLS_MBEDTLS_BASE'};
my $STATIC = ($ENV{'NET_MBEDTLS_LINKING'} || q<>) eq 'static';

# Per mbedTLS docs, apparently the order matters:
my @MBEDTLS_LIBS = qw(tls x509 crypto);
my @dash_l = map { "-lmbed$_" } @MBEDTLS_LIBS;

my @mbedtls_writemakefile_args;

my @incdirs;

if ($MBEDTLS_BASE) {
    $MBEDTLS_BASE = Cwd::abs_path($MBEDTLS_BASE);

    print "Using mbedTLS from $MBEDTLS_BASE …$/";

    @incdirs = "$MBEDTLS_BASE/include";

    if ($STATIC) {
        #_make_mbedtls($mbedtls_build_dir);

        @mbedtls_writemakefile_args = (
            OBJECT => [
                '$(BASEEXT)$(OBJ_EXT)',
                map { "$MBEDTLS_BASE/library/libmbed$_.a" } @MBEDTLS_LIBS,
            ],
        );
    }
    else {

        # “library” is for mbedTLS’s source.
        my ($libdir) = grep { -e "$MBEDTLS_BASE/$_" } qw(lib library);
        die "No libdir under $MBEDTLS_BASE found!" if !$libdir;

        substr $libdir, 0, 0, "$MBEDTLS_BASE/";

        print "Libs look like they’re at $libdir …$/";

        @mbedtls_writemakefile_args = (
            LIBS => "-L$libdir @dash_l",
            LDDLFLAGS => "-Wl,-rpath,$libdir -L$libdir @dash_l $Config{lddlflags}",
        );
    }
}
else {
    print "Using system-installed mbedTLS …$/";

    die "Can’t build static with system mbedTLS!$/" if $STATIC;

    @mbedtls_writemakefile_args = (
        LIBS => "@dash_l",
    );
}

my @defines = _determine_defines(@incdirs);

substr($_, 0, 0, '-I') for @incdirs;

WriteMakefile(
    NAME              => 'Net::mbedTLS',
    VERSION_FROM      => 'lib/Net/mbedTLS.pm', # finds $VERSION
    ABSTRACT_FROM  => 'lib/Net/mbedTLS.pm', # retrieve abstract from module
    AUTHOR         => [
        'Felipe Gasper (FELIPE)',
    ],
    LICENSE           => "perl_5",

    CCFLAGS => join(
        q< >,
        $Config{'ccflags'},
        '-Wall',
        @defines,
    ),

    INC => "-I. @incdirs",

    @mbedtls_writemakefile_args,

    PMLIBDIRS => ['lib'],

    MIN_PERL_VERSION => 5.016,

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Net-mbedTLS.git',
                web => 'https://github.com/FGasper/p5-Net-mbedTLS',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Net-mbedTLS/issues',
            },
        },
    },
);

sub _determine_defines {
    my @include_dirs = @_;

    my $builder = ExtUtils::CBuilder->new();

    my @defines;

    my @checks = (

        # A hack to detect nonavailability of mbedTLS:
        {
            label => 'mbedTLS availability',
            required => 1,
            c => q[
                #include <mbedtls/pk.h>
                int main() {
                    return 0;
                }
            ],
        },

        {
            label => 'public net_socket.fd',
            define => 'NET_CONTEXT_FD_IS_PUBLIC',
            c => q[
                #include <mbedtls/net_sockets.h>
                int main() {
                    mbedtls_net_context foo = { .fd = 5 };
                    return 0;
                }
            ],
        },

        {
            label => 'public x509_crt.raw',
            define => 'X509_CRT_RAW_IS_PUBLIC',
            c => q[
                #include <mbedtls/x509_crt.h>
                int main() {
                    mbedtls_x509_crt foo;

                    void *ptr = &foo.raw;

                    return 0;
                }
            ],
        },

        {
            label => 'public asn1_buf.p',
            define => 'X509_ASN1_P_IS_PUBLIC',
            c => q[
                #include <mbedtls/asn1.h>
                int main() {
                    mbedtls_asn1_buf foo;

                    void *ptr = &foo.p;

                    return 0;
                }
            ],
        },

        {
            label => 'public asn1_buf.len',
            define => 'X509_ASN1_LEN_IS_PUBLIC',
            c => q[
                #include <mbedtls/asn1.h>
                int main() {
                    mbedtls_asn1_buf foo;

                    void *ptr = &foo.len;

                    return 0;
                }
            ],
        },

        {
            label => 'mbedtls_pk_parse_key(): 5 arguments',
            define => 'PK_PARSE_KEY_5_ARGS',
            c => q[
                #include <mbedtls/pk.h>

                int main() {
                    int v = mbedtls_pk_parse_key(
                        NULL, NULL, 0, NULL, 0
                    );

                    return 0;
                }
            ],
        },

        {
            label => 'mbedtls_pk_parse_key(): 7 arguments',
            define => 'PK_PARSE_KEY_7_ARGS',
            c => q[
                #include <mbedtls/pk.h>

                int main() {
                    int v = mbedtls_pk_parse_key(
                        NULL, NULL, 0, NULL, 0,
                        NULL, NULL
                    );

                    return 0;
                }
            ],
        },
    );

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $i = 0;

    for my $check_hr (@checks) {
        ++$i;

        _note("Checking: $check_hr->{'label'}");

        my $path = "$dir/source-$i.c";
        open my $fh, '>', $path;
        syswrite($fh, $check_hr->{'c'});
        close $fh;

        my $obj_file = eval {
            $builder->compile(
                source => $path,
                include_dirs => \@include_dirs,
            );
        };

        if ($check_hr->{'required'}) {
            die "DEPENDENCY FAILED\n" if !$obj_file;
            next;
        }

        if ($obj_file) {
            push @defines, $check_hr->{'define'};
        }

        my $result = ($obj_file ? q<> : 'NOT ') . 'supported';
        _note("\t$check_hr->{'label'}: $result");
    }

    return map { "-D$_" } @defines;
}

sub _make_mbedtls {
    _note("Building mbedTLS …");

    my $make_bin = $Config{'gmake'} || $Config{'make'} or do {
        die "Cannot build static without either gmake or make!";
    };

    my $mbedtls_build_dir = shift;

    my $cwd = Cwd::getcwd();

    chdir $mbedtls_build_dir;
    system { $make_bin } $make_bin, 'lib' and die;
    chdir $cwd;

    _note("Done building mbedTLS!");
}

sub _note {
    print "===== @_$/";
}
