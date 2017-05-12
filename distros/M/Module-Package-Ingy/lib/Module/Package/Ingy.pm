##
# name:      Module::Package::Ingy
# abstract:  Ingy's Module::Package Plugins
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2011
# see:
# - Module::Package

# TODO:
# - Look at auto_provides
# - Look at other plugins

use 5.008003;
use strict;

# Don't load experimental (Alt-) modules
{
    my @inc;
    BEGIN {
        @inc = @INC;
        @INC = grep not(/^lib$/), @INC;
    }
use IO::All 0.44 ();
    use IO::All::File ();
    BEGIN {
        @INC = @inc;
    }
}

use Module::Package 0.30 ();
use Module::Install::AckXXX 0.18 ();
use Module::Install::AutoLicense 0.08 ();
use Module::Install::GithubMeta 0.16 ();
# use Module::Install::Gloom 0.16 ();
# use Module::Install::MetaModule 0.01 ();
use Module::Install::ReadmeFromPod 0.12 ();
use Module::Install::RequiresList 0.10 ();
use Module::Install::Stardoc 0.18 ();
use Module::Install::TestCommon 0.07 ();
use Module::Install::TestML 0.26 ();
use Module::Install::VersionCheck 0.16 ();
my $testbase_skip = "
use Module::Install::TestBase 0;
use Spiffy 0;
use Test::More 0;
use Test::Builder 0;
use Test::Base::Filter 0;
use Test::Builder::Module 0;
";

use Capture::Tiny 0.11 ();
use Pegex 0.19 ();
my $skip_pegex = "
use Pegex::Mo 0;
use Pegex::Grammar 0;
use Pegex::Parser 0;
use Pegex::Receiver 0;
";
use Test::Base 0.60 ();
use TestML 0.26 ();
use YAML::XS 0.37 ();

#-----------------------------------------------------------------------------#
package Module::Package::Ingy;

our $VERSION = '0.20';

#-----------------------------------------------------------------------------#
package Module::Package::Ingy::modern;
# XXX Want to use Mo, but doesn't work yet for unknown reason.
use Moo;
extends 'Module::Package::Plugin';
use IO::All;

sub main {
    my ($self) = @_;

    # These run before the Makefile.PL body. (During use inc::...)
#     $self->mi->meta_module_compile
#       if Module::Install::MetaModule->new->_has_meta();
    $self->mi->stardoc_make_pod;
    $self->mi->stardoc_clean_pod;
    $self->mi->readme_from($self->pod_or_pm_file);
#     $self->check_use_gloom;
    $self->check_use_test_base;
    $self->check_use_testml;
    $self->check_test_common;
    $self->strip_extra_comments;
    $self->mi->ack_xxx;
#     $self->mi->sign;  # XXX need to learn more about this

    # These run later, as specified.
    $self->post_all_from(sub {$self->mi->version_check});
    $self->post_all_from(sub {$self->mi->auto_license});
    $self->post_all_from(sub {$self->mi->clean_files('LICENSE')});
    $self->post_all_from(sub {$self->mi->githubmeta});
    $self->post_WriteAll(sub {$self->mi->requires_list});
    $self->post_WriteAll(sub {$self->make_release});
}

sub make_release {
    io('Makefile')->append(<<'...');

release ::
	$(PERL) "-Ilib" "-MModule::Package::Ingy" -e "Module::Package::Ingy->make_release()"

...
}

package Module::Package::Ingy;
use Capture::Tiny qw(capture_merged);
use IO::All;

sub run {
    my $cmd = shift;
    my %options = map {($_, 1)} @_;
    warn "******** >> $cmd ********\n";
    my $error;
    my $output = capture_merged {
        system($cmd) == 0 or $error = 1;
    };
    print $output unless $options{-quiet};
    if ($error) {
        die "\nError. Command failed:\n$output";
    }
}

# This is Ingy's personal release process. It probably won't match your own.
# It requires a YAML Changes file and git and tagged releases and other stuff.
sub make_release {
    my $class = shift or die;
    die "make release expects this to be a git repo\n\n"
        unless -e '.git';
    my $meta = YAML::XS::LoadFile('META.yml');
    my @changes = YAML::XS::LoadFile('Changes');
    die "Failed to load 'Changes'"
        unless @changes;
    my $change = shift @changes;
    die "Changes entry has more than 3 keys"
        if @{[keys %$change]} > 3;
    die "Changes entry does not define 'version', 'date' and 'changes'" unless
        exists $change->{version} and
        exists $change->{date} and
        exists $change->{changes};
    die "Changes entry 'date' should be blank for release\n\n"
        if $change->{date};
    my $changes_version = $change->{version};
    my $module_version = $meta->{version};
    die "'Changes' version '$changes_version' " .
        "does not match module version '$module_version'\n\n"
        unless $changes_version eq $module_version;
    (my $branch = `git branch`) =~ s/^.*\* (\S+).*$/$1/s or die;
    my $tag_prefix = ($branch eq 'master') ? '' : "${branch}-";
    my @lines = grep {
        s/^${tag_prefix}(\d+\.\d+)$/$1/;
    } map {
        chomp;
        $_;
    } sort `git tag`;
    my $tag_version = pop(@lines) or die "No relevant git tags!";
    die "Module version '$module_version' is not 0.01 greater " .
        "than git tag version '$tag_version'"
        if abs($module_version - $tag_version - 0.01) > 0.0000001;
    my $date = `date`;
    chomp $date;
    my $Changes = io('Changes')->all;
    $Changes =~ s/date: *\n/date:    $date\n/ or die;

    run "perl -Ilib Makefile.PL", -quiet;
    run "make purge", -quiet;
    my $status = `git status`;
    die "You have untracked files:\n\n$status"
        if $status =~ m!Untracked!;

    run "perl -Ilib Makefile.PL", -quiet;
    run "make test", -quiet;
    run "make purge", -quiet;

    run "perl -Ilib Makefile.PL", -quiet;
    run "make", -quiet;
    if ($branch eq 'master') {
        run "sudo -k make install", -quiet;
    }
    else {
        run "sudo -k echo 'not installing'", -quiet;
    }
    run "make purge", -quiet;

    io('Changes')->print($Changes);
    run "perl -Ilib Makefile.PL", -quiet;
    run "make manifest", -quiet;
    run "make upload", -quiet;
    run "make purge", -quiet;

    run qq{git commit -a -m "Released version $module_version"}, -quiet;
    run "git tag $tag_prefix$module_version", -quiet;
    run "git push", -quiet;
    run "git push --tag", -quiet;
    $status = `git status`;
    die "git status is not clean:\n\n$status"
        unless $status =~ /\(working directory clean\)/;
    run "git status";

    print <<"...";

$meta->{name}-$meta->{version} successfully released.

Relax. Have a beer. \\o/

...
}

1;

=head1 SYNOPSIS

In your Makefile.PL:

    use inc::Module::Package 'Ingy:modern';

=head1 DESCRIPTION

This module defines the standard configurations for Module::Package based
Makefile.PLs, used by Ingy döt Net. You don't have to be Ingy to use it. If
you write a lot of CPAN modules, you might want to copy or subclass it under a
name matching your own CPAN id.

=head1 FLAVORS

Currently this module only defines the C<:modern> flavor.

=head2 :modern

In addition to the inherited behavior, this flavor uses the following plugins:

    - Stardoc
    - ReadmeFromPod
    - AckXXX
    - VersionCheck

It also conditionally uses these plugins if you need them:

    - TestBase
    - TestML

=head1 OPTIONS

This module does not add any usage options of than the ones inherited from
L<Module::Package::Plugin>.
