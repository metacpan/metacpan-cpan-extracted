package Package::Conf;
use Mouse;

use Cwd;
use File::Spec;
use Hash::Merge;
use IO::All;
use YAML::XS;

has src_dir => (
    is => 'ro',
    required => 1,
);
has cli_args => (
    is => 'ro',
    required => 1,
);
has pkg_name => (
    is => 'ro',
    required => 1,
);
has dirs => (
    is => 'ro',
    builder => 'dirs_builder',
    lazy => 1,
);
has stash => (
    is => 'ro',
    builder => 'stash_builder',
    lazy => 1,
);
has manifest => (
    is => 'ro',
    builder => 'manifest_builder',
    lazy => 1,
);

sub dirs_builder {
    my ($self) = @_;
    my $home = Cwd::cwd;
    my $dir = $self->src_dir;
    my @dirs;
    while (1) {
        $dir = Cwd::abs_path($dir);
        chdir $dir or die "'$dir' does not exist";
        die "$dir is not a directory" unless -d $dir;
        my $conf_file =
            -f 'pkg.conf' ? 'pkg.conf' : ''
            or die "$dir contains no pkg.conf file";
        unshift @dirs, $dir;
        my $conf = YAML::XS::LoadFile($conf_file);
        last if $conf->{pkg}{top};
        my @dir = File::Spec->splitdir($dir) or die;
        pop @dir;
        $dir = File::Spec->catdir(@dir) or die;
    }
    chdir $home or die;
    return \@dirs;
}

sub manifest_builder {
    my ($self) = @_;
    my $manifest = {};
    $self->tree_walker(manifest => sub {
        my ($name, $path, $conf) = @_;
        my $list = $conf->{pkg}{ignore} || [];
        return if grep {$path eq $_} @$list;
        delete $manifest->{"./$_"} for @{delete($conf->{pkg}{remove}) || []};
        $manifest->{$name} = Cwd::abs_path($path);
    });
    return $manifest;
}

# ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
sub date_hash {
    my @t = localtime;
    my $hash = {
        year => $t[5] + 1900,
        time => scalar(localtime),
    };
    return $hash;
}

sub stash_builder {
    my ($self) = @_;
    my $stash = {};
    $self->tree_walker(stash => sub {
        my $hash = YAML::XS::LoadFile('pkg.conf') || {};
        $stash = Hash::Merge::merge($hash, $stash);
    });
    $stash->{env} = {%ENV};
    $stash->{date} = $self->date_hash;
    $stash->{pkg}{name} = $self->pkg_name;
    $stash = Hash::Merge::merge(
        $self->cli_args_hash, $stash,
    );
    my @keys = keys %$stash;
    for my $k (@keys) {
        next unless $k =~ /\./;
        $stash = Hash::Merge::merge(
            $self->hashlet($k, delete $stash->{$k}),
            $stash,
        );
    }

    $self->{stash} = $stash;
    if (my $actions = delete $stash->{pkg}{actions}) {
        for my $action (@$actions) {
            $self->apply($action);
        }
    }

    for (1..5) {
        $self->expand_refs($self->{stash});
    }

    # XXX Hack because something (Hash::Merge?) messes up my name!
    use Encode;
    Encode::_utf8_on($self->{stash}{author}{name});

    return $self->{stash};
}

sub expand_refs {
    my ($self, $hash) = @_;
    for my $k (keys %$hash) {
        my $v = $hash->{$k};
        if (ref($v) eq 'HASH') {
            $self->expand_refs($v);
        }
        elsif (not ref($v)) {
            next unless $v =~ /\%([^\%]+)\%/;
            my $x = $1;
            $hash->{$k} =~ s/(\%([^\%]+)\%)/$self->lookup($2) || $1/e;
        }
    }
}

sub apply {
    my ($self, $action) = @_;
    my $method = $self->get_method($action);
    die "$method action not supported"
        unless $self->can($method);
    return $self->$method($action);
}

sub get_method {
    my ($self, $args) = @_;
    return "action_" . shift @$args;
}

sub get_arg {
    my ($self, $args) = @_;
    my $arg = shift @$args;
    return ref($arg)
    ? $self->apply($arg)
    : $arg;
}

sub set_value {
    my ($self, $key, $value) = @_;
    my $hash = $self->hashlet($key, $value);
    my $stash = $self->{stash};
    delete $stash->{$key};
    $self->{stash} = Hash::Merge::merge(
        $hash,
        $stash,
    );
    return $value;
}

sub action_get {
    my ($self, $args) = @_;
    my $key = $self->get_arg($args);
    return $self->lookup($key);
}

sub action_init {
    my ($self, $args) = @_;
    my $name = $self->get_arg($args);
    my $value = $self->lookup($name);
    return $value if defined $value;
    $value = $self->get_arg($args);
    return unless defined $value;
    return $self->set_value($name, $value);
}

sub action_replace {
    my ($self, $args) = @_;
    my $val = $self->get_arg($args);
    my $pat = $self->get_arg($args);
    my $rep = $self->get_arg($args);
    return unless defined $val;
    $val =~ s/$pat/$rep/g;
    return $val;
}

sub lookup {
    my ($self, $k, $v) = @_;
    $v ||= $self->{stash};
    while ($k =~ s/(.*?)\.//) {
        $v = $v->{$1};
    }
    return unless defined $v and ref($v) eq 'HASH';
    return $v->{$k};
}

sub hashlet {
    my ($self, $k, $v) = @_;
    my $h = {};
    my $p = $h;
    while ($k =~ s/(.*?)\.//) {
        $p = $p->{$1} = {};
    }
    $p->{$k} = $v;
    return $h;
}

sub cli_args_hash {
    my ($self) = @_;
    my $hash = {};
    my $args = $self->cli_args;
    for my $arg (@$args) {
        $arg =~ /^--([\w\.]+)(?:=(.*))?$/ or next;
        my ($k, $v) = ($1, $2);
        $v = 1 if not defined $v;
        if (exists $hash->{$k}) {
            $hash->{$k} = [$hash->{$k}]
                unless ref $hash->{$k} eq 'ARRAY';
            push @{$hash->{$k}}, $2;
        }
        else {
            $hash->{$1} = $2;
        }
    }
    return $hash;
}

sub tree_walker {
    my ($self, $type, $callback) = @_;
    my $home = Cwd::cwd;
    my $dirs = $self->dirs;
    for (my $i = 0; $i < @$dirs; $i++) {
        my $dir = $dirs->[$i];
        chdir $dir;
        my $conf = YAML::XS::LoadFile('pkg.conf');
        File::Find::find(sub {
            if (-f 'pkg.conf' and $File::Find::dir ne $File::Find::topdir) {
                $File::Find::prune = 1;
                return;
            }
            if ($i == 0) {
                if ($type eq 'stash') {
                    $callback->();
                }
                $File::Find::prune = 1;
                return;
            }
            if ($File::Find::dir =~ /\.git/) {
                $File::Find::prune = 1;
                return;
            }
            if ($_ eq 'pkg.conf') {
                if ($type eq 'stash') {
                    $callback->();
                }
                return;
            }
            return if /^\./;
            return if -d;
            if ($type eq 'manifest') {
                $callback->($File::Find::name, $_, $conf);
            }
        }, '.');
    }
    chdir $home;
}

1;
