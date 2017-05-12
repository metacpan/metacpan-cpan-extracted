
use strict;
use ExtUtils::MakeMaker;
use Alien::SDL;

use File::Spec;

sub _slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

my $lib      = 'betweener';
my $test     = 'betweener_unit_tests';
my $cpp_path = 'src/cpp';
my $lib_ar   = "$cpp_path/lib$lib\$(LIB_EXT)";
my $cc       = 'g++';

WriteMakefile(
    NAME              => 'SDLx::Betweener',
    VERSION_FROM      => 'lib/SDLx/Betweener.pm',
    PREREQ_PM         => {
        'Alien::SDL' => '1.430',
        'SDL'        => '2.536',
        'Moose'      => '2.0402',
    },
    CC                => $cc,
    LD                => '$(CC)',
    ($] >= 5.005 ?
      (ABSTRACT  => 'SDL Perl XS Tweening Animation Library',
       AUTHOR         => 'eilara <ran.eilam@gmail.com>') : ()),
    LIBS              => Alien::SDL->config('libs', '-lm'),
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => Alien::SDL->config('cflags'). ' -I. -Isrc/cpp -Isrc/cpp_xs',
    OBJECT            => '$(O_FILES)',
    'MYEXTLIB'        => $lib_ar,
    (($ExtUtils::MakeMaker::VERSION >= 6.48)
        ? (MIN_PERL_VERSION => '5.012',)
        : ()
    ),
    (($ExtUtils::MakeMaker::VERSION >= 6.48)
        ? (LICENSE => 'perl',)
        : ()
    ),
    (($ExtUtils::MakeMaker::VERSION >= 6.48)
        ? (
            META_MERGE =>
            {
                "meta-spec" => { version => 2 },
                provides => {
                    'SDLx::Betweener' => {
                        file => "lib/SDLx/Betweener.pm",
                        version => sub {
                            my $contents = _slurp(File::Spec->catfile(File::Spec->curdir, qw( lib SDLx Betweener.pm)));
                            if (my ($version) = ($contents =~ /^our \$VERSION = '([^']*)'/ms))
                            {
                                return $version;
                            }
                            else
                            {
                                die "Cannot find version in file.";
                            }
                        }->(),
                    },
                },
                resources => {
                    repository => {
                        type => 'git',
                        url => 'git://github.com/shlomif/SDLx-Betweener.git',
                        web => 'https://github.com/shlomif/SDLx-Betweener',
                    },

                },
 ,
            },
        )
        : ()
    ),
#    clean   => {'FILES' => ''},
);


sub MY::postamble {
'
$(MYEXTLIB): src/Makefile
	cd src && $(MAKE) $(PASSTHRU)
';
}
