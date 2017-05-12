#!perl
use strict;
use warnings;

use File::Path;
use Test::More;

plan tests => 15;

# load module
use_ok("RackMan::SCM");

# check API
can_ok("RackMan::SCM", qw< new add commit update >);

# check diagnostics
eval { RackMan::SCM->new };
like $@, qr/^Attribute \(type\) is required/,
    "check that attribute type is required";

eval { RackMan::SCM->new(type => "plonk") };
like $@, qr/^Attribute \(type\) does not pass the type constraint because: Validation failed for 'ScmType' with value "?plonk"?/,
    "check that attribute type must be within ScmType";

# test RackMan::SCM with no tool, to check that the API itself works
API: {
    my $path = "t/files/repotest";
    my $file = "lipsum.txt";

    my $scm = eval { RackMan::SCM->new({ type => "none", path => $path }) };
    is $@, "", "RackMan::SCM->new({ type => 'none' })";
    isa_ok $scm, "RackMan::SCM", "check that \$scm";

    eval { $scm->update };
    is $@, "", "\$scm->update";

    eval { $scm->add($file) };
    is $@, "", "\$scm->add($file)";

    eval { $scm->commit($file, "added $file for great justice") };
    is $@, "", "\$scm->commit($file, 'added $file for great justice')";
}

# test RackMan::SCM with git, if available
SKIP: {
    skip "because Git is not installed", 6
        unless `git --version` =~ /^git version/;

    # auto-configure Git so it doesn't whine about that
    if (not `git config --global user.name`) {
        my ($login, $name);
        my $host = eval { require Sys::Hostname; Sys::Hostname::hostname() };

        if (eval { eval { require Win32; 1 } }) {
            $login = Win32::LoginName();
        }
        else {
            ($login, $name) = eval { (getpwuid($<))[0,6] };
        }

        $login ||= "dummy";
        $name  ||= $login;
        $host  ||= "localhost";

        system qw< git config --global user.name >, $name;
        system qw< git config --global user.email >, "$login\@$host";
    }

    # create a Git repository where we can work
    my $path = "t/files/repotest";
    mkpath $path;
    chdir $path or die $!;
    system qw< git init >;
    chdir "../../..";

    # actually use the module
    my $scm = eval { RackMan::SCM->new({ type => "git", path => $path }) };
    is $@, "", "RackMan::SCM->new({ type => 'git', path => '$path' })";
    isa_ok $scm, "RackMan::SCM", "check that \$scm";

    diag "git errors below are normal";
    eval { $scm->update };
    is $@, "", "\$scm->update";

    my $file = "lipsum.txt";
    open my $fh, ">", "$path/$file" or die $!;
    print {$fh} "Lorem ipsum dolor sit amet";
    close $fh;

    eval { $scm->add($file) };
    is $@, "", "\$scm->add($file)";

    eval { $scm->commit($file, "added $file for great justice") };
    is $@, "", "\$scm->commit($file, 'added $file for great justice')";

    # check that the commit really succeeded
    chdir $path;
    my $out = `git log -- $file`;
    like $out, qr/added $file for great justice/m,
        "check that the commit succeeded with git log";
    chdir "../../..";

    # clean the test repository
    rmtree $path;
}

