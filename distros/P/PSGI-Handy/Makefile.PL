use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use ExtUtils::MakeMaker;

my %args = (
    'NAME'      => q{PSGI::Handy},
    'VERSION'   => q{0.01},
    'ABSTRACT'  => q{a tiny dependency-free PSGI web framework for Perl 5.005_03+},
    'PREREQ_PM' => {
        'Carp' => '0',
        'ExtUtils::MakeMaker' => '5.4302',
        'perl' => '5.00503',
    },
    'AUTHOR'    => q{ina <ina.cpan@gmail.com>},
);

# LICENSE was introduced in ExtUtils::MakeMaker 6.31 (2006).
# Passing it to older versions produces an "is not a known parameter" warning
# without failing, but we suppress the noise by checking the version.
if ($ExtUtils::MakeMaker::VERSION >= 6.31) {
    $args{LICENSE} = q{perl};
}

# MIN_PERL_VERSION (6.48) and META_MERGE (6.46) arrived together in the
# same EUMM release cycle; guard them under the higher threshold (6.48)
# so both are always either present or absent.
if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $args{MIN_PERL_VERSION} = q{5.00503};
    $args{META_MERGE} = {
        'meta-spec' => { version => 2 },
        'resources' => {
            'license'    => [ 'http://dev.perl.org/licenses/' ],
            'bugtracker' => {
                'web' => 'https://github.com/ina-cpan/PSGI-Handy/issues',
            },
            'repository' => {
                'url'  => 'https://github.com/ina-cpan/PSGI-Handy',
                'web'  => 'https://github.com/ina-cpan/PSGI-Handy',
                'type' => 'git',
            },
        },
        'provides' => {
            'PSGI::Handy' => {
                'file'    => 'lib/PSGI/Handy.pm',
                'version' => '0.01',
            },
            'PSGI::Handy::Context' => {
                'file'    => 'lib/PSGI/Handy.pm',
                'version' => '0.01',
            },
            'PSGI::Handy::Request' => {
                'file'    => 'lib/PSGI/Handy.pm',
                'version' => '0.01',
            },
            'PSGI::Handy::Response' => {
                'file'    => 'lib/PSGI/Handy.pm',
                'version' => '0.01',
            },
            'PSGI::Handy::Router' => {
                'file'    => 'lib/PSGI/Handy.pm',
                'version' => '0.01',
            }
        },
    };
}

WriteMakefile(%args);

__END__
