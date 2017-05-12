##
# name:      Test::Common
# abstract:  Simple, Reusable Module Tests
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

use 5.008003;
package Test::Common;
use Mouse 0.93 ();

our $VERSION = '0.07';

use MouseX::App::Cmd 0.08 ();
use App::Cmd 0.311 ();
use IO::All 0.41 ();
use YAML::XS 0.35 ();
use File::Share 0.01 ();
use File::Copy 2.14 ();
use Template::Toolkit::Simple 0.13 ();

my $conf_file = 't/common.yaml';

#------------------------------------------------------------------------------#
package Test::Common::Command;
use App::Cmd::Setup -command;
use Mouse;
extends qw[MouseX::App::Cmd::Command];

has _conf => (
    is => 'ro',
    lazy => 1,
    reader => 'conf',
    builder => sub { Test::Common::Conf->new() },
);

sub validate_args {
    my ($self) = @_;
    return unless ref($self) =~ /::(config|update|list|clean)$/;
    die "This directory does not seem to be a Perl module package"
        unless
            -f "Makefile.PL" or
            -f "Build.PL" or
            -f "dist.ini";
}

#------------------------------------------------------------------------------#
package Test::Common;
use App::Cmd::Setup -app;
use Mouse;
extends 'MouseX::App::Cmd';

sub list {
    my $conf = Test::Common::Conf->new;
    return sort +(
        map({"t/" . ($_->{name} || $_->{test})} @{$conf->t}),
        map({"xt/" . ($_->{name} || $_->{test})} @{$conf->xt}),
    );
}

sub clean_files {
    my @all = Test::Common::list();
    my $clean = Test::Common::Conf->new->clean;
    return
        ref($clean) ? @$clean :
        ($clean eq 'all') ? @all :
        ($clean eq 'none') ? () :
        ($clean eq 't') ? grep(m!^t/!, @all) :
        ($clean eq 'xt') ? grep(m!^xt/!, @all) :
        die "'$clean' is invalid value for clean";
}

#------------------------------------------------------------------------------#
package Test::Common::Command::config;
use Mouse;
Test::Common->import( -command );
extends 'Test::Common::Command';

sub abstract { return "Create a new Test::Common '$conf_file' file" }
use constant usage_desc => 'test-common config';

has force => (
    is => 'ro',
    isa => 'Bool',
    documentation => "Force overwrite of $conf_file",
);

sub execute {
    my ($self, $opt, $args) = @_;

    die "Won't overwrite '$conf_file' without --force option\n"
        if -f $conf_file and not $self->force;

    mkdir 't' unless -d 't';

    my $share = $self->share('Test-Common');
    $self->copy("$share/common.yaml", $conf_file);
    warn "Wrote $conf_file. You should edit it now.\n";
}

#------------------------------------------------------------------------------#
package Test::Common::Command::update;
use Mouse;
Test::Common->import( -command );
extends 'Test::Common::Command';

use IO::All;
use Template::Toolkit::Simple;

use constant abstract => 'Update Test::Common test files';
use constant usage_desc => 'test-common update';

has source_dirs => (
    is => 'ro',
    lazy => 1,
    builder => 'source_dirs_',
);

sub source_dirs_ {
    my ($self) = @_;
    return [
        map {
            $self->share($_);
        } @{$self->conf->sources}
    ];
}

sub execute {
    my ($self, $opt, $args) = @_;
    if (not $self->conf->ok) {
        warn "No $conf_file found. Run 'test-common config'.\n";
        return;
    }
    $self->update_tests('t');
    $self->update_tests('xt');
}

sub update_tests {
    my ($self, $type) = @_;

    my $list = $self->conf->$type;
    return unless @$list;

    mkdir $type unless -d $type;

    for my $test (@$list) {
        my $test_name = $test->{test};
        my $dir = $self->find_dir($test_name) or do {
            warn "Can't find '$test_name'\n";
            next;
        };
        my $source = io("$dir/$test_name")->all;
        my $filename = $test->{name} || $test->{test};
        my $render = tt->path($dir)->render(
            \$source,
            $test,
        );
        my $target = "$type/$filename";
        if (not (-e $target and $render eq io($target)->all)) {
            warn "Test::Common - updated '$target'\n";
            io($target)->print($render);
        }
    }
}

sub find_dir {
    my ($self, $test) = @_;
    for my $dir (reverse @{$self->source_dirs}) {
        return $dir if -e "$dir/$test";
    }
    return;
}

#------------------------------------------------------------------------------#
package Test::Common::Command::list;
use Mouse;
Test::Common->import( -command );
extends 'Test::Common::Command';

use constant abstract => 'List test files';
use constant usage_desc => 'test-common list';

sub execute {
    my ($self, $opt, $args) = @_;
    print "$_\n" for Test::Common::list();
}

#------------------------------------------------------------------------------#
package Test::Common::Command::clean;
use Mouse;
Test::Common->import( -command );
extends 'Test::Common::Command';

use constant abstract => 'Remove generated test files';
use constant usage_desc => 'test-common clean';

sub execute {
    my ($self, $opt, $args) = @_;

    my @list = Test::Common::_clean_list();
    if (@list) {
        warn "unlink @list\n";
        unlink @list;
    }
}

#------------------------------------------------------------------------------#
package Test::Common::Command;

use YAML::XS;
use File::Share;
use File::Copy ();

sub share {
    my ($self, $dist) = @_;
    return File::Share::dist_dir($dist);
}

sub copy {
    my ($self, $from, $to) = @_;
    File::Copy::copy($from, $to);
}

#------------------------------------------------------------------------------#
package Test::Common::Conf;
use Mouse;

use YAML::XS;

has ok => ( is => 'ro', default => 0 );
has sources => ( is => 'ro', default => sub {[]} );
has t => ( is => 'ro', default => sub {[]} );
has xt => ( is => 'ro', default => sub {[]} );
has clean => ( is => 'ro', default => 'none' );

sub BUILD {
    my ($self) = @_;
    if (-e $conf_file) {
        my $hash = YAML::XS::LoadFile($conf_file);
        for my $k (keys %$hash) {
            $self->{$k} = $hash->{$k};
        }
        $self->{ok} = 1;
    }
}

1;

=head1 SYNOPSIS

From the command line:

    > test-common help
    > test-common config
    > edit t/common.yaml
    > test-common update

Optionally, in your Module::Install based Makefile.PL:

    use inc::Module::Install;
    ...
    # Keep common tests up to date
    test_common_update;

=head1 DESCRIPTION

There are many module unit tests that are either exactly the same or slightly
different, from dist to dist. Test::Common is a framework for distributing and
sharing these common tests. (The hope is...) By having many authors contribute
to common test pools, not only will it be easier to write common tests fast,
it will help expose where specific tests need to be written, and common ways
to set these tests up.

As a module author, you maintain a configuration file called C<t/common.yaml>,
which contains information on all the common tests you want to use. These
tests can come from Common::Test or any other module that distributes tests in
the same way.

The common test scripts are files under the F<share/> directory. These files
are actually Template Toolkit templates. Test::Common renders the templates
into real test files (using data from t/common.yaml) every time you run the
command C<test-common update>.

=head1 CONFIGURATION

When you run:

    test-common config

you get an example C<t/common.yaml> file. Edit it. There are comments inside
exlaining the basics. For a given entry, like:

    - test: foo-bar.t

all the data in that hash gets passed to Template Toolkit to render the test's
template. Simple.

To rename a test, do:

    - test: foo-bar.t
      name: test-foo-bar.t

=head1 EXTENDING

To create a package of your own common tests, put .t files into a share
directory, so they get installed by C<make install>, et al. Then other authors
can add your test package to the 'sources' list of their C<t/common.yaml>
file.

=head1 COMMIT OR CLEAN?

Since Test::Common tests are always generated, it is your choice whether or
not to commit the rendered tests. The only file you really ever need is
C<t/common.yaml>.

The config file has a C<clean> setting that allows you to control what:

    common-tests clean

does. If you use the Module::Install plugin then you can just do:

    make clean
