use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# Punk::SAML is an XS dist: the request builder, the response verifier,
# the signature check, the metadata reader and the flow cookie run in C
# over the house ABIs - frx_abi.h (File::Raw::XML: the tree and the
# canonical form), jws_abi.h (Crypt::JWS: signatures, digests, HMAC, the
# CSPRNG, constant-time compare) and fetch_abi.h (Fetch: metadata).
# Perl remains only as the keyword and registration glue and the POD.

my $INC = '-Iinclude';

my $pkg;
my @deps = ('File::Raw::XML', 'Crypt::JWS', 'Fetch');
eval { $pkg = ExtUtils::Depends->new('Punk::SAML', @deps); 1 };
if (!$pkg) {
    # sibling-directory fallbacks for the uninstalled-ABI case
    my %sibling = (
        'File::Raw::XML' => '../File-Raw-XML/include',
        'Crypt::JWS'     => '../Crypt-JWS/include',
        'Fetch'          => '../Fetch/include/fetch',
    );
    my @found;
    for my $dep (@deps) {
        if (eval { ExtUtils::Depends->new('Punk::SAML', $dep); 1 }) {
            push @found, $dep;
        }
        elsif (-d $sibling{$dep}) {
            $INC .= " -I$sibling{$dep}";
        }
        else {
            die "Cannot find the $dep dependency (install it, or place "
              . "it as a sibling directory).\n";
        }
    }
    $pkg = ExtUtils::Depends->new('Punk::SAML', @found);
}
my %dep = $pkg->get_makefile_vars;
$INC = join ' ', grep { defined && length } $INC, delete $dep{INC};
delete $dep{LDFROM};
delete $dep{LIBS};

# A provider's get_makefile_vars replaces the PM map MakeMaker would have
# autodetected, so the .pm files have to be put back by hand.
require File::Find;
File::Find::find(sub {
    return unless /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# MakeMaker tracks neither include/*.h nor the xs/*.xs that PSAML.xs
# INCLUDEs, so without this a header edit leaves the old object in place
# and the build reports success. The glob runs at configure time: a
# header added later is invisible until Makefile.PL is re-run.
my $hdeps = join ' ', glob('include/psaml/*.h xs/*.xs');

WriteMakefile(
    NAME             => 'Punk::SAML',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Punk/SAML.pm',
    ABSTRACT_FROM    => 'lib/Punk/SAML.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw::XML'      => '0.03',
        'Crypt::JWS'          => '0.07',
        'Fetch'               => '0.23',
    },
    TEST_REQUIRES => {
        'Test::More'                  => '0.98',
        'MIME::Base64'                => '0',   # t/04: the base64 oracle
        'IO::Uncompress::RawInflate'  => '0',   # t/04: the DEFLATE oracle
        'Time::Local'                 => '0',   # t/04: the dateTime oracle
    },
    PREREQ_PM => {
        'Punk'           => '0.45',  # install_kw, helper, route, on_compile,
                                     # host, login, safe_path, session_rotate,
                                     # the cookie surface. Phase 7 raises this
                                     # to 0.46 when it first calls $c->xml;
                                     # the floor is what is called, not what
                                     # exists.
        'File::Raw::XML' => '0.03',  # frx_abi.h v2: the SV bridge
        'Crypt::JWS'     => '0.07',  # jws_abi.h v3: key_from_x509_der
        'Fetch'          => '0.23',  # fetch_abi.h: request, blocking at boot
    },
    INC    => $INC,
    XS     => { 'PSAML.xs' => 'PSAML.c' },
    OBJECT => 'PSAML$(OBJ_EXT)',
    depend => {
        'PSAML.c'         => $hdeps,
        'PSAML$(OBJ_EXT)' => $hdeps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Punk-SAML-* PSAML.c PSAML.o PSAML.bs' },
    %dep,
);
