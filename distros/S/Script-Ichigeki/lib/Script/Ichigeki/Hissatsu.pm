package Script::Ichigeki::Hissatsu;
use Mouse;
use Mouse::Util::TypeConstraints;

use Encode;
use Time::Piece;
use Path::Class qw/file/;
use IO::Prompt::Simple qw/prompt/;
use IO::Handle;
use File::Tee qw/tee/;
use Term::Encoding qw(term_encoding);

subtype 'Time::Piece' => as Object => where { $_->isa('Time::Piece') };
coerce 'Time::Piece'
    => from 'Str',
    => via {
        my $t = Time::Piece->strptime($_, '%Y-%m-%d');
        die "Invalie time format: [$_] .(format should be '%Y-%m-%d'.)" unless $t;
        localtime($t);
    };

has exec_date => (
    is      => 'ro',
    isa     => 'Time::Piece',
    coerce => 1,
    default => sub {
        localtime(Time::Piece->strptime(localtime->ymd, "%Y-%m-%d"));
    }
);

has confirm_dialog => (
    is      => 'ro',
    default => 1,
);

has log_file_postfix => (
    is      => 'ro',
    default => '.log',
);

has script => (
    is       => 'ro',
    default  => sub { file($0) },
);

has is_running => (
    is       => 'rw',
);

has in_compilation => (
    is => 'ro'
);

has dialog_message => (
    is   => 'ro',
    default => sub {
        'Do you really execute `%s` ?';
    }
);

no Mouse;

sub execute {
    my $self = shift;

    my $now   = localtime;
    my $today = localtime(Time::Piece->strptime($now->ymd, "%Y-%m-%d"));
    $self->_exiting('exec_date: '. $self->exec_date->strftime('%Y-%m-%d') .' is not today!') unless $self->exec_date == $today;

    $self->_exiting(sprintf('Can\'t execute! Execution log file [%s] already exists!', $self->_log_file)) if -f $self->_log_file;

    if ($self->confirm_dialog) {
        my $enc = term_encoding || 'utf-8';
        my $answer = prompt(encode($enc, sprintf($self->dialog_message, $self->script->basename) . ' [y/n] [n]'));
        $self->_exiting('canceled.') unless $answer =~ /^y(?:es)?$/i;
    }

    STDOUT->autoflush;
    STDERR->autoflush;

    $self->_log(join "\n",
        '# This log file is generated dy Script::Icigeki.',
        "start: @{[localtime->datetime]}",
        '---', ''
    );

    $self->is_running(1);
    tee STDOUT, $self->_log_fh;
    tee STDERR, $self->_log_fh;
}

{
    my  $_log_file;
    sub _log_file {
        my $self = shift;
        $_log_file ||= do {
            my $script = $self->script;
            $script->dir->file('.' . $script->basename . $self->log_file_postfix);
        };
    }

    my $_log_fh;
    sub _log_fh {
        $_log_fh ||= shift->_log_file->open('>>');
    }
}

sub _log {
    shift->_log_fh->print(@_);
}


sub _exiting {
    my ($self, $msg) = @_;

    $msg .= "\n";
    if ($self->in_compilation) {
        warn $msg;
        exit 1;
    }
    else {
        die $msg;
    }
}

sub DEMOLISH {
    my $self = shift;
    if ($self->is_running) {
        my $now = localtime->datetime;
        $self->_log(join "\n",
            '','---',
            "end: $now",'',
        );
    }
}

__PACKAGE__->meta->make_immutable;
