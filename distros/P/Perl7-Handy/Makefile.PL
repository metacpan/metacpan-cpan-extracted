use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use ExtUtils::MakeMaker;

my %args = (
    'NAME'      => q{Perl7::Handy},
    'VERSION'   => q{0.12},
    'ABSTRACT'  => q{Handy Perl7 scripting environment on Perl5},
    'PREREQ_PM' => {
        'Fcntl' => '1.03',
        'bareword::filehandles' => '0',
        'multidimensional' => '0',
        'perl' => '5.00503',
        'strict' => '1.01',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
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
                'web' => 'https://github.com/ina-cpan/Perl7-Handy/issues',
            },
            'repository' => {
                'url'  => 'https://github.com/ina-cpan/Perl7-Handy',
                'web'  => 'https://github.com/ina-cpan/Perl7-Handy',
                'type' => 'git',
            },
        },
        'provides' => {
            'Perl7::Handy' => {
                'file'    => 'lib/Perl7/Handy.pm',
                'version' => '0.12',
            }
        },
    };
}

WriteMakefile(%args);

__END__
