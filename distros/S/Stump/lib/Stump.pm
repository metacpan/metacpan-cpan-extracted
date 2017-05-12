use strict; use warnings;
package Stump;
our $VERSION = '0.13';

use Mouse;
use MouseX::App::Cmd;
use App::Cmd;
use File::Share;
use IO::All;
use YAML::XS;

#-----------------------------------------------------------------------------#
package Stump::Command;
use App::Cmd::Setup -command;
use Mouse;
extends qw[MouseX::App::Cmd::Command];

sub validate_args {
}

# Semi-brutal hack to suppress extra options I don't care about.
around usage => sub {
    my $orig = shift;
    my $self = shift;
    my $opts = $self->{usage}->{options};
    @$opts = grep { $_->{name} ne 'help' } @$opts;
    return $self->$orig(@_);
};

#-----------------------------------------------------------------------------#
package Stump;
use App::Cmd::Setup -app;
use Mouse;
extends 'MouseX::App::Cmd';

use Module::Pluggable
  require     => 1,
  search_path => [ 'Stump' ];
Stump->plugins;

# App::Cmd help helpers
use constant usage => 'Stump';
use constant text => "stump command [<options>] [<arguments>]\n";

#-----------------------------------------------------------------------------#
package Stump::Command::init;
Stump->import( -command );
use Mouse;
extends qw[Stump::Command];

use constant abstract => 'Initialize a new Stump presentation';
use constant usage_desc => 'stump init [--force]';

has force => (
    is => 'ro',
    isa => 'Bool',
    documentation => 'Force an init operation',
);

sub execute {
    my ($self, $opt, $args) = @_;

    if ($self->empty_directory or $self->force) {
        my $share = $self->share;
        $self->copy_file("$share/stump.input", "./stump.input");
        $self->copy_file("$share/conf.yaml", "./conf.yaml");
        $self->copy_files("$share/image", "./image");
        $self->init_ok_msg;
    }
    else {
        $self->error__wont_init;
    }
}

#-----------------------------------------------------------------------------#
package Stump::Command::make;
Stump->import( -command );
use Mouse;
extends qw[Stump::Command];

use IO::All;

use constant abstract => 'Make a Stump ODP Presentation';
use constant usage_desc => 'stump make';

sub execute {
    my ($self, $opt, $args) = @_;
    $self->make;
}

#-----------------------------------------------------------------------------#
package Stump::Command::speech;
Stump->import( -command );
use Mouse;
extends qw[Stump::Command];

use constant abstract => 'Start your Stump speech';
use constant usage_desc => 'stump speech';

sub execute {
    my ($self, $opt, $args) = @_;

    my $start_command = $self->conf->{start_command}
        or die "No 'start_command' in conf.yaml";

    $self->make
        if $self->conf->{auto_make} and (
            not -e 'stump.odp' or
            -M 'stump.input' < -M 'stump.odp'
        );

    exec $start_command;
}

#-----------------------------------------------------------------------------#
package Stump::Command::clean;
Stump->import( -command );
use Mouse;
extends qw[Stump::Command];

use constant abstract => 'Cleanup generated files';
use constant usage_desc => 'stump clean';

sub execute {
    my ($self, $opt, $args) = @_;
    system('rm -fr stump stump.odp');
}

#-----------------------------------------------------------------------------#
# Helper methods
#-----------------------------------------------------------------------------#
package Stump::Command;
use File::Share;
use IO::All;
use Cwd qw[cwd abs_path];
use YAML::XS;

has _conf => (
    reader => 'conf',
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        my $file = 'conf.yaml';
        die "There is no conf.yaml file.\n"
            unless -e $file;
        YAML::XS::LoadFile($file);
    },
);

sub make {
    require Stump::Heavy;
    my ($self) = @_;
    my $share = $self->share;
    $self->copy_file("$share/stump.odp", "./stump.odp");
    Stump::Heavy::para2odp();
    io('stump')->rmtree;
}

sub share {
    File::Share::dist_dir('Stump');
}

sub empty_directory {
    io('.')->empty;
}

sub copy_file {
    my ($self, $source, $target) = @_;
    my $file = io($source);
    io("$target")->assert->print($file->all);
}

sub copy_files {
    my ($self, $source, $target) = @_;
    for my $file (io($source)->All_Files) {
        my $short = $file->name;
        $short =~ s!^\Q$source\E/?!! or die $short;
        next if $short =~ /^\./;
        io("$target/$short")->assert->print($file->all);
    }
}

sub init_ok_msg {
    print <<'...';

Stump slideshow created.

Now edit 'stump.input' and 'conf.yaml' and run:

    stump make
    stump speech

...
}

sub error {
    my ($self, $msg) = splice(@_, 0, 2);
    chomp $msg;
    $msg .= $/;
    die sprintf($msg, @_);
}

sub error__wont_init {
    my ($self) = @_;
    $self->error(
        "Won't 'init' in a non empty directory, unless you use --force"
    );
}

1;
