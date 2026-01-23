use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile1(
    'NAME'          => 'PDF::Reuse',
    'VERSION_FROM'  => 'lib/PDF/Reuse.pm', 
    'PREREQ_PM'     => {  'Digest::MD5'    => 0,
                          'Compress::Zlib' => 0,
                          'Carp'           => 0,
                          'Exporter'       => 0,
                          'AutoLoader'     => 0,
                          'Data::Dumper'   => 0,
                          'Text::PDF::TTFont0' => 0,
                          'Font::TTF'   => 0},
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cnighswonger/PDF-Reuse.git',
                web  => 'https://github.com/cnighswonger/PDF-Reuse',
            },
            bugtracker => {
                web => 'https://github.com/cnighswonger/PDF-Reuse/issues',
            },
        },
        provides => {
            'PDF::Reuse' => {
                file    => 'lib/PDF/Reuse.pm',
                version => '0.43',
            },
            'PDF::Reuse::Util' => {
                file    => 'lib/PDF/Reuse/Util.pm',
            },
        },
        no_index => {
            package => [ 'PDF::Reuse::DocProxy', 'PDF::Reuse::TTFont' ],
        },
    },
    TEST_REQUIRES => {
        'Test' 		=> 0,
	'Test::More'	=> 0,
	'Test::Deep'	=> 0,
	'IO::String'	=> 0,
    },
    ABSTRACT_FROM => 'lib/PDF/Reuse.pm', 
    AUTHOR     => [  'Lars Lundberg LARSLUND@CPAN.ORG',
                     'Chris Nighswonger CNIGHS@CPAN.ORG',
                     ],
);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}
