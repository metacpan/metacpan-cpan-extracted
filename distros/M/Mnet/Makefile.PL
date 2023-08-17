#!/usr/bin/env perl

# user install info is in the INSTALLATION section of perldoc lib/Mnet.pm

# developer new release info is below
#
#   description of the new release process:
#
#       check that all tests pass and all necessary files are in manifest
#       Changes doc and Mnet module version information get updated
#       github is updated, replacing old release with tagged new release
#       github master contains latest release readme and Mnet-*.tar.gz files
#       cpan is updated with new release distribution file
#       github development ready to continue on master branch
#
#   follow the steps listed below to correctly create a new release:
#
#       perl Makefile.PL && make realclean, to start with a clean slate
#       perl Makefile.PL && make distcheck, skip Mnet-*.tar.gz and README.md
#       make test, commit any fixes made so far, then we're ready for release
#       vim Changes, update w/date and new <RELEASE> number, 5.09, 5.10, etc
#       note: for cpan development, <RELEASE> =~ /^\d+\.\d+_\d+$/
#       vim lib/Mnet.pm, update $VERSION variable to the new <RELEASE> number
#       git rm Mnet-*.tar.gz, to remove old distribution when new is committed
#       make realclean && perl Makefile.PL && make dist && make realclean
#       perform any additional testing before upload to cpan, no going back
#       upload new Mnet-<RELEASE>.tar.gz to cpan using cpan PAUSE account
#       firefox https://pause.perl.org/pause/authenquery?ACTION=add_uri
#       wait for email that file upload to cpan is complete
#       wait for email that file has been indexed and on cpan, unless trial ver
#       git add Changes Mnet-*.tar.gz && git commit -m 'latest release'
#       git push origin master
#       git tag -a "v<RELEASE>" -m latest release' `git log -1 --pretty=%H`
#       git push origin "v<RELEASE>"
#       git push --delete origin "v<RELEASE>", to PERMANENTLY delete if desired
#       git restore lib/Mnet.pm, to restore $VERSION variable to "dev"

# required modules
use warnings;
use strict;
use ExtUtils::MakeMaker;

# create README file from Mnet.pm, some perl tools supposedly look for this
#   skipped if no README.md file, as is the case when user downloads from cpan
if (-f "README.md") {
    eval("require Pod::Text; 1") or die "missing Pod::Text perl module";
    my $pod_text = Pod::Text->new(sentence => 0, width => 78);
    $pod_text->parse_from_file('lib/Mnet.pm', 'README');
}

# create README.md file from Mnet.pm for github, CPAN used Mnet.pm directly
#   skipped if no README.md file, as is the case when user downloads from cpan
if (-f "README.md") {
    eval("require Pod::Markdown; 1") or die "missing Pod::Markdown perl module";
    my $pod_md = Pod::Markdown->new;
    open(my $fh, '>', 'README.md') or die 'unable to write to README.md, $!';
    $pod_md->output_fh($fh);
    $pod_md->parse_file('lib/Mnet.pm');
}

# create make file
#   metacpan will use cpan v2 spec meta_merge github links
#   update Mnet.pm if minimum perl version changes
WriteMakefile(
    ABSTRACT_FROM       => 'lib/Mnet.pm',
    AUTHOR              => 'Mike Menza <mmenza@cpan.org>',
    LICENSE             => 'gpl_3',
    META_MERGE          => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository  => {
                type => 'git',
                url  => 'https://github.com/menzascripting/Mnet.git',
                web  => 'https://github.com/menzascripting/Mnet',
            },
        },
    },
    MIN_PERL_VERSION    => '5.12.0',
    NAME                => 'Mnet',
    PREREQ_PM           => {
        'Expect'     => 0,
        'JSON'       => 0,
        'Text::Diff' => 0,
    },
    VERSION_FROM        => 'lib/Mnet.pm',
);

# finished
exit;

