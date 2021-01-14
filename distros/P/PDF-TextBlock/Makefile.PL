use strict;
use warnings;
use ExtUtils::MakeMaker;

my $choice = 'Builder';  # API2 or Builder default prerequisite?
my $debug = 0;  # 1 to just dump contents
my %versions = (  # minimum version for either
    'API2'    => 2.038,
    'Builder' => 3.021,
);

my %WriteMakefileArgs = (
    NAME                => 'PDF::TextBlock',
    AUTHOR              => 'Jay Hannah <jay@jays.net>',
    VERSION_FROM        => 'lib/PDF/TextBlock.pm',
    ABSTRACT_FROM       => 'lib/PDF/TextBlock.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Class::Accessor::Fast' => 0,
        'File::Temp'            => 0,
    },
    META_MERGE => {
         "meta-spec" => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'git@github.com:jhannah/pdf-textblock.git',
                 web  => 'https://github.com/jhannah/pdf-textblock.git',
             },
             bugtracker  => {
                 web  => 'https://github.com/jhannah/pdf-textblock/issues',
             },
         },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDF-TextBlock-*' },
);

# if neither PDF::API2 nor PDF::Builder is installed, prereq one of them
my $rc;
$rc = eval {
    require PDF::API2;
    1;
};
if (!defined $rc) { $rc = 0; }
if ($rc) {
    # PDF::API2 installed but not up to date?
    if ($PDF::API2::VERSION < $versions{'API2'}) { $rc = 0; }
}
if (!$rc) {
    # no PDF::API2. try PDF::Builder.
    $rc = eval {
        require PDF::Builder;
        1;
    };
    if (!defined $rc) { $rc = 0; }
    if ($rc) {
        # PDF::Builder installed but not up to date?
        if ($PDF::Builder::VERSION < $versions{'Builder'}) { $rc = 0; }
    }
}
# suitable level of PDF::* not already installed?
if (!$rc) {
    $WriteMakefileArgs{'PREREQ_PM'}{"PDF::$choice"} = $versions{$choice};
}

if ($debug) {
    use Data::Dumper;  # two lines for checking prereq work
    print Dumper(\%WriteMakefileArgs);
} else {
    WriteMakefile(%WriteMakefileArgs);
}
