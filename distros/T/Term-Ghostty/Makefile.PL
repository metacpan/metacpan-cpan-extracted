use v5.10;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper ();

my %args = Alien::Base::Wrapper->new('Alien::ghostty=0.01')->mm_args2(
    NAME             => 'Term::Ghostty',
    DISTNAME         => 'Term-Ghostty',
    VERSION_FROM     => 'lib/Term/Ghostty.pm',
    ABSTRACT_FROM    => 'lib/Term/Ghostty.pm',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    TEST_REQUIRES    => {
        'Test::More' => '0.98',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-term-ghostty.git',
                web  => 'https://github.com/vividsnow/perl5-term-ghostty',
            },
            bugtracker => { web => 'https://github.com/vividsnow/perl5-term-ghostty/issues' },
        },
        no_index => { directory => ['examples'] },
    },
);
my @ldflags;
push @ldflags, '-Wl,-S' unless grep { /^OPTIMIZE=.*-g/ } @ARGV, split ' ', $ENV{PERL_MM_OPT} // '';
push @ldflags, '-Wl,--exclude-libs,ALL' if $^O =~ /^(?:linux|freebsd|netbsd|openbsd|dragonfly|gnu)/;
$args{LDDLFLAGS} = join ' ', $args{LDDLFLAGS} // $Config{lddlflags}, @ldflags if @ldflags;

WriteMakefile(%args);

sub MY::postamble {
    return <<'MAKE';

readme : README

README : lib/Term/Ghostty.pm
	$(PERLRUN) -MPod::Text -e "Pod::Text->new->parse_from_file(q{lib/Term/Ghostty.pm}, q{README})"

create_distdir : README
MAKE
}
