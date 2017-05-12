use strict;
use warnings;
use ExtUtils::MakeMaker;

if ($^O =~ /mswin32/i) {
    print "Sorry but this doesn't work on Windows. Patches welcome.\n";
    exit;
}

my $pm = 'lib/Test/CGI/External.pm';
my $pod = 'lib/Test/CGI/External.pod';
my $github = 'github.com/benkasminbullock/test-cgi-external';
my $repo = "https://$github";
use FindBin '$Bin';

# Edit the test scripts to give them the right path.

# http://stackoverflow.com/questions/10390173/getting-absolute-path-to-perl-executable-for-the-current-process#10393492

use Config;
my $perlpath = $Config{perlpath};
my @cgis = map {"$Bin/t/$_.cgi"} qw/test unicode json not-json/;
push @cgis, map {"$Bin/examples/$_.cgi"} qw/bad-method rupert x/;
for my $cgi (@cgis) {
    open my $in, "<", $cgi or die "Cannot open $cgi: $!";
    my @lines;
    while (<$in>) {
	s/^#!.*perl.*$/#!$perlpath/;
	push @lines, $_;
    }
    close $in or die "Cannot close $cgi: $!";
    open my $out, ">", $cgi or die "Cannot open $cgi: $!";
    for (@lines) {
	print $out $_;
    }
    close $out or die "Cannot close $cgi: $!";
}

WriteMakefile1(
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    ABSTRACT_FROM => $pod,
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
#	    homepage => 'http://',
        },
	prereqs => {
	    runtime => {
		recommends => {
		    'Gzip::Faster' => '0.14',
		    'HTTP::Date' => '6.02',
		    'JSON::Parse' => '0.49',
		    'Unicode::UTF8' => '0.60',
		    'Image::PNG::Libpng' => '0.43', 
		},
	    },
	},
    },
    #BUILD_REQUIRES => {
    #},

    NAME => 'Test::CGI::External',
    VERSION_FROM => 'lib/Test/CGI/External.pm',
    PREREQ_PM => {
	# Added the latest versions, earlier ones may also be
	# compatible.
	'Encode' => 0,
	'Test::Builder' => 0,
	'Test::Tester' => '0.109',
        'Test::More' => 0,
    },
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

