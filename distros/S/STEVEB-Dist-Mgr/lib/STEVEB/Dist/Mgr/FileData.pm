package STEVEB::Dist::Mgr::FileData;

use warnings;
use strict;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
    _ci_github_file

    _git_ignore_file

    _module_section_ci_badges
    _module_template_file

    _makefile_section_meta_merge
    _makefile_section_bugtracker
    _makefile_section_repo

    _manifest_skip_file

    _unwanted_filesystem_entries
);

sub _ci_github_file {
    my ($os) = @_;

    if (! defined $os) {
        $os = [qw(l w)];
    }

    my %os_matrix_map = (
        l => qq{ubuntu-latest},
        w => qq{windows-latest},
        m => qq{macos-latest},
    );

    my $os_matrix = "[ ";
    $os_matrix .= join(', ', map { $os_matrix_map{$_} } @$os);
    $os_matrix .= " ]";

    return (
        qq{name: CI},
        qq{on:},
        qq{  push:},
        qq{    branches: [ master ]},
        qq{  pull_request:},
        qq{    branches: [ master ]},
        qq{  workflow_dispatch:},
        qq{jobs:},
        qq{  ubuntu:},
        qq{    runs-on: \${{ matrix.os }}},
        qq{    strategy:},
        qq{      fail-fast: false},
        qq{      matrix:},
        qq{        os: $os_matrix},
        qq{        perl-version: [ '5.32', '5.30' ]},
        qq{        include:},
        qq{          - perl-version: '5.30'},
        qq{            os: ubuntu-latest},
        qq{            release-test: false},
        qq{            coverage: true},
        qq{    container: perl:\${{ matrix.perl-version }}},
        qq{    steps:},
        qq{      - uses: actions/checkout\@v2},
        qq{      - run: cpanm -n --installdeps .},
        qq{      - run: perl -V},
        qq{      - name: Run tests (no coverage)},
        qq{        if: \${{ !matrix.coverage }}},
        qq{        run: prove -l t},
        qq{      - name: Run tests (with coverage)},
        qq{        if: \${{ matrix.coverage }}},
        qq{        env:},
        qq{          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}},
        qq{        run: |},
        qq{          cpanm -n Devel::Cover::Report::Coveralls},
        qq{          cover -test -report Coveralls},
    );
}

sub _git_ignore_file {
    return (
        q{Makefile},
        q{*~},
        q{*.bak},
        q{*.swp},
        q{*.bak},
        q{.hg/},
        q{.git/},
        q{MYMETA.*},
        q{*.tar.gz},
        q{_build/},
        q{blib/},
        q{Build/},
        q{META.json},
        q{META.yml},
        q{*.old},
        q{*.orig},
        q{pm_to_blib},
        q{.metadata/},
        q{.idea/},
        q{*.debug},
        q{*.iml},
        q{*.bblog},
        q{BB-Pass/},
        q{BB-Fail/},
    );
}

sub _module_section_ci_badges {
    my ($author, $repo) = @_;

    return (
        qq{},
        qq{=for html},
        qq{<a href="https://github.com/$author/$repo/actions"><img src="https://github.com/$author/$repo/workflows/CI/badge.svg"/></a>},
        qq{<a href='https://coveralls.io/github/$author/$repo?branch=master'><img src='https://coveralls.io/repos/$author/$repo/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>},
        qq{},
    );
}
sub _module_template_file {
    my ($author, $email) = @_;

    if (! defined $author || ! defined $email) {
        croak("_module_template_file() requires 'author' and 'email' parameters");
    }

    my ($email_user, $email_domain);

    if ($email =~ /(.*)\@(.*)/) {
        $email_user   = $1;
        $email_domain = $2;
    }

    my $year = (localtime)[5] + 1900;

    return (
        qq{package Test::Module;},
        qq{},
        qq{use strict;},
        qq{use warnings;},
        qq{},
        qq{our \$VERSION = '0.01';},
        qq{},
        qq{__placeholder {}},
        qq{},
        qq{1;},
        qq{__END__},
        qq{},
        qq{=head1 NAME},
        qq{},
        qq{Test::Module - One line description},
        qq{},
        qq{=head1 SYNOPSIS},
        qq{},
        qq{=head1 DESCRIPTION},
        qq{},
        qq{=head1 METHODS},
        qq{},
        qq{=head2 name},
        qq{},
        qq{Description.},
        qq{},
        qq{I<Parameters>:},
        qq{},
        qq{    \$bar},
        qq{},
        qq{I<Mandatory, String>: The name of the thing with the guy and the place.},
        qq{},
        qq{I<Returns>: C<0> upon success.},
        qq{},
        qq{=head1 AUTHOR},
        qq{},
        qq{$author, C<< <$email_user at $email_domain> >>},
        qq{},
        qq{=head1 LICENSE AND COPYRIGHT},
        qq{},
        qq{Copyright $year $author.},
        qq{},
        qq{This program is free software; you can redistribute it and/or modify it},
        qq{under the terms of the the Artistic License (2.0). You may obtain a},
        qq{copy of the full license at:},
        qq{},
        qq{L<http://www.perlfoundation.org/artistic_license_2_0>},
    );
}

sub _makefile_section_meta_merge {
    return (
        "    META_MERGE => {",
        "        'meta-spec' => { version => 2 },",
        "        resources   => {",
        "        },",
        "    },"
    );
}
sub _makefile_section_bugtracker {
    my ($author, $repo) = @_;

    return (
        "            bugtracker => {",
        "                web => 'https://github.com/$author/$repo/issues',",
        "            },"
    );

}
sub _makefile_section_repo {
    my ($author, $repo) = @_;

    return (
        "            repository => {",
        "                type => 'git',",
        "                url => 'https://github.com/$author/$repo.git',",
        "                web => 'https://github.com/$author/$repo',",
        "            },"
    );

}

sub _manifest_skip_file {
    return (
        q{~$},
        q{^blib/},
        q{^pm_to_blib/},
        q{.old$},
        q{.orig$},
        q{.tar.gz$},
        q{.bak$},
        q{.swp$},
        q{^test/},
        q{.hg/},
        q{.hgignore$},
        q{^_build/},
        q{^Build$},
        q{^MYMETA\.yml$},
        q{^MYMETA\.json$},
        q{^README.bak$},
        q{^Makefile$},
        q{.metadata/},
        q{.idea/},
        q{pm_to_blib$},
        q{.git/},
        q{.debug$},
        q{.gitignore$},
        q{^\w+.pl$},
        q{.ignore.txt$},
        q{.travis.yml$},
        q{.iml$},
        q{examples/},
        q{build/},
        q{^\w+.list$},
        q{.bblog$},
        q{.base$},
        q{BB-Pass/},
        q{BB-Fail/},
        q{cover_db/},
        q{scrap\.pl},
    );
}

sub _unwanted_filesystem_entries {
    return qw(
        xt/
        ignore.txt
        README
    );
}

sub __placeholder {}

1;
__END__

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
