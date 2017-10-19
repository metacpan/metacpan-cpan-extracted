use 5.006000;
use ExtUtils::MakeMaker;
use ExtUtils::CChecker;

my @defines;
my $cc = ExtUtils::CChecker->new;

if($cc->try_compile_run(
"#include <endian.h>
int main(void) { return (hton64(ntoh64(23)) == 23) ? 0 : 1; }"
)){
	push @defines, "-DHAVE_ENDIAN_H";
}

if($cc->try_compile_run("#include <byteswap.h>
int main(void) { return (bswap_16(0) == 0) ? 0 : 1; }")) {
	push @defines, "-DHAVE_BYTESWAP_H";
if ($cc->try_compile_run("#include <byteswap.h>
int main(void) { return (bswap_32(bswap_32(32)) == 32) ? 0 : 1; }")){
	push @defines, "-DHAVE_BSWAP_32";}
if ($cc->try_compile_run("#include <byteswap.h>
int main(void) { return (bswap_64(bswap_64(64)) == 64) ? 0 : 1; }")){
	push @defines, "-DHAVE_BSWAP_64";}
}

if($cc->try_compile_run(
"#include <stdint.h>
int main(void) { return (sizeof(uint64_t) == 8) ? 0 : 1; }"
)){
	push @defines, "-DHAVE_STDINT_H";
}

if($cc->try_compile_run(
"#include <inttypes.h>
int main(void) { return (sizeof(uint64_t) == 8) ? 0 : 1; }"
)){
	push @defines, "-DHAVE_INTTYPES_H";
}

my $define = "" . join(' ', @defines);

WriteMakefile(
    NAME           => 'Net::Host64',
    VERSION_FROM   => 'lib/Net/Host64.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Math::Int64' => 0 },
    ABSTRACT_FROM  => 'lib/Net/Host64.pm',
    AUTHOR         => 'Eric Herman',
    LIBS           => [],           # e.g., ['-lm']
    DEFINE         => $define,      # e.g., '-DHAVE_SOMETHING'
    INC            => '-I.',        # e.g., '-I. -I/usr/include/other'
    OBJECT         => '$(O_FILES)', # link all the C files too
    LICENSE        => 'perl',       # or LGPLv3+
    META_MERGE     => {
        resources => {
            repository => {
                type => 'git',
                url  => 'git@github.com:ericherman/p5-Net-Host64.git',
                web  => 'https://github.com/ericherman/p5-Net-Host64',
            },
        },
        'meta-spec' => { version => 2 },
      },
);
