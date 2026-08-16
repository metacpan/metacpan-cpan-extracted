use 5.024000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# Punk::OAuth2 is an XS dist: the OAuth2 flows, token exchange, JWKS
# handling, and id_token verification run in C over the house ABIs -
# jws_abi.h (Crypt::JWS), frj_abi.h (File::Raw::JSON), fetch_abi.h
# (Fetch). Perl remains only as the keyword/registration glue and POD.

my $INC = '-Iinclude';

my $pkg;
my @deps = ('Crypt::JWS', 'File::Raw::JSON', 'Fetch');
eval { $pkg = ExtUtils::Depends->new('Punk::OAuth2', @deps); 1 };
if (!$pkg) {
    # sibling-directory fallbacks for the uninstalled-ABI case
    my %sibling = (
        'Crypt::JWS'      => '../Crypt-JWS/include',
        'File::Raw::JSON' => '../File-Raw-JSON/include',
        'Fetch'           => '../Fetch/include/fetch',
    );
    my @found;
    for my $dep (@deps) {
        if (eval { ExtUtils::Depends->new('Punk::OAuth2', $dep); 1 }) {
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
    $pkg = ExtUtils::Depends->new('Punk::OAuth2', @found);
}
my %dep = $pkg->get_makefile_vars;
$INC = join ' ', grep { defined && length } $INC, delete $dep{INC};
delete $dep{LDFROM};
delete $dep{LIBS};

require File::Find;
File::Find::find(sub {
    return unless /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

my $hdeps = join ' ', glob('include/pox/*.h xs/*.xs');

WriteMakefile(
    NAME             => 'Punk::OAuth2',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Punk/OAuth2.pm',
    ABSTRACT_FROM    => 'lib/Punk/OAuth2.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.024000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Crypt::JWS'          => '0.01',
        'File::Raw::JSON'     => '0.05',
        'Fetch'               => '0.08',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    PREREQ_PM => {
        'Punk'            => '0.04',
        'Crypt::JWS'      => '0.01',
        'File::Raw::JSON' => '0.05',
        'Fetch'           => '0.08',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            test => { recommends => { 'Hyperman' => '0.14' } },
        },
    },
    INC    => $INC,
    XS     => { 'POAuth2.xs' => 'POAuth2.c' },
    OBJECT => 'POAuth2$(OBJ_EXT)',
    depend => {
        'POAuth2.c'         => $hdeps,
        'POAuth2$(OBJ_EXT)' => $hdeps,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Punk-OAuth2-* POAuth2.c POAuth2.o POAuth2.bs' },
    %dep,
);
