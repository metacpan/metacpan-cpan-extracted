package Package;
our $VERSION = '0.26';

#------------------------------------------------------------------------------#
package Package::Command;
use App::Cmd::Setup -command;
use Mouse;
extends 'MouseX::App::Cmd::Command';

sub validate_args {}

# Semi-brutal hack to suppress extra options I don't care about.
around usage => sub {
    my $orig = shift;
    my $self = shift;
    my $opts = $self->{usage}->{options};
    @$opts = grep { $_->{name} ne 'help' } @$opts;
    return $self->$orig(@_);
};

#-----------------------------------------------------------------------------#
package Package;
use App::Cmd::Setup -app;
use Mouse;
extends 'MouseX::App::Cmd';

use Module::Pluggable
  require     => 1,
  search_path => [ 'Package::Command' ];
Package->plugins;

#------------------------------------------------------------------------------#
package Package::Command::new;
Package->import( -command );
use Mouse;
extends 'Package::Command';

use Cwd 'abs_path';
use IO::All;
use Template::Toolkit::Simple;

use constant abstract => 'Create new module package directory from template';
use constant usage_desc => 'pkg init --from=<dir> --module=<Name> --to=<dir>';

has dryrun => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    documentation => 'Create new package but skip git',
);


sub execute {
    my ($self, $opt, $args) = @_;
    my $pkg_name = pop(@$args) || '';
    $self->_args($args);

    my $to = io($pkg_name || '.')->absolute;

    $pkg_name ||= do {
        my $cwd = Cwd::cwd;
        $cwd =~ s!.*/!!;
        $cwd;
    };
    $self->_pkg_name($pkg_name);

    my $stash = $self->conf->stash;

    if ($to->exists) {
        die <<"..." if not $to->empty;
$to is not an empty directory.
Can't make a new pkg here.

Either specify the name of a new directory you wish to create,
or name an empty directory, or cd to an empty directory.
...
    }
    else {
        $to->assert->mkdir;
    }
    $to->chdir or die "Can't chdir to $to";

    for my $file (sort keys %{$self->conf->manifest}) {
        if (not $file =~ /%(.*?)%/) {
            $self->write_file($file, $file);
            next;
        }
        my $key = $1;
        my $path = $self->conf->lookup($key)
            or die "Config variable '$key' is not defined.\n";
        (my $f = $file) =~ s/%.*?%/$path/;
        $self->write_file($f, $file);
    }

    if ($stash->{git}{init}) {
        if ($self->dryrun or $to =~ /^.*\/[xyz]{1,5}\d?$/) {
            (my $url = $stash->{git}{origin}) =~
                s/\%pkg\.name\%/$stash->{pkg}{name}/e;
            print <<"...";
New package '$to' successfully created, but GitHub repo creation skipped.

The GitHub info would be:

    origin: $url
    repo:   $pkg_name
    desc:   $stash->{desc}
...
            return;
        }
        system("git init; git add .; git commit -m 'First commit'");
        if (my $url = $stash->{git}{origin}) {
            $url =~ s/\%pkg\.name\%/$stash->{pkg}{name}/e;
            system("git remote add origin $url");
        }
        $self->create_git_repo($pkg_name, $stash->{desc});
    }

    print "New package '$to' successfully created!\n";
}

sub write_file {
    my ($self, $file, $key) = @_;
    my $path = $self->conf->manifest->{$key};
    my $template = io($path)->all;
    my $text = eval {
        tt
        ->path([])
        ->strict(1)
        ->data($self->conf->stash)
        ->render(\$template);
    };
    if ($@) {
        if ($@ =~ /var\.undef error - undefined variable: (\S+)/) {
            die "Config variable '$1' is not defined.\n";
        }
        die $@;
    }
    io($file)->assert->print($text);
    if (-x $path) {
        chmod 0755, $file;
    }
}

#------------------------------------------------------------------------------#
package Package::Command::repo;
Package->import( -command );
use Mouse;
extends 'Package::Command';

use constant abstract => 'Create a new repo on github';
use constant usage_desc => 'pkg repo --from=<dir>';

sub execute {
    my ($self, $opt, $args) = @_;
    die "Directory has no git repo"
        unless -d '.git';

    my $stash = $self->conf->stash;
    for (@$args) {
        if (/^--(\w+)=(.*)/) {
            my ($k, $v) = ($1, $2);
            # $v =~ s/^'(.*)'$/$1/;
            # $v =~ s/^"(.*)"$/$1/;
            $stash->{$k} = $v;
        }
    }

    my $pkg_name = do {
        my $cwd = Cwd::cwd;
        $cwd =~ s!.*/!!;
        $cwd;
    };

    $self->create_git_repo($pkg_name, $stash->{desc});
}

#------------------------------------------------------------------------------#
package Package::Command::listvars;
Package->import( -command );
use Mouse;
extends 'Package::Command';

use constant abstract => 'Print list of config variables from template';
use constant usage_desc => 'pkg listvars --from=<dir>';

sub execute {
    my ($self, $opt, $args) = @_;
    print YAML::XS::Dump($self->conf->stash);
}

#------------------------------------------------------------------------------#
package Package::Command;

has from => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'Pkg template directory',
);

has _conf => (
    is => 'ro',
    lazy => 1,
    reader => 'conf',
    default => sub {
        require Package::Conf;
        my ($self) = @_;
        Package::Conf->new(
            src_dir => $self->from,
            cli_args => $self->_args,
            pkg_name => $self->_pkg_name,
        );
    },
);

has _pkg_name => (
    is => 'rw',
);

has _args => (
    is => 'rw',
    default => sub {[]},
);

sub create_git_repo {
    my ($self, $pkg_name, $desc) = @_;
    my $stash = $self->conf->stash;
    # XXX Check Net::Ping->new->ping("github.com");
    if (my $github = $stash->{git}{github}) {
        my $login = $github->{login};
        my $token = $github->{token};
        system(qq{curl -F login=$login -F token=$token https://github.com/api/v2/yaml/repos/create -F name=$pkg_name -F "description=$desc"});
        system("git push origin master");
    }
}

1;
