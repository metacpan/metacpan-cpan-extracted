package Runops::Recorder::Viewer;

use strict;
use warnings;

use Runops::Recorder::Reader;

use Scalar::Util qw(weaken);
use Term::Screen;
use Time::HiRes qw(sleep);

my $screen = Term::Screen->new();
$screen->clrscr();

for my $accessor (qw(
    reader current_file_path current_file all_lines
    num_lines skip_files last_line skip_installed
    autorun
    )) { 
    no strict 'refs'; 
    *{$accessor} = sub { $_[0]->{$accessor}; };
}

sub new {
    my ($pkg, $path, $args) = @_;
    
    $args = {} unless ref $args eq 'HASH';
    
    my $self = bless { 
        skip_files => {},
        last_line => 0,
        skip_installed => $ENV{RR_SKIP_INC} || $args->{skip_installed} || 0,
        autorun => $ENV{RR_AUTORUN} || $args->{autorun} || 0,
    }, $pkg;

    my $reader = Runops::Recorder::Reader->new($path, { handler => $self });

    $self->{reader} = $reader;
    
    return $self;
}

sub on_switch_file {
    my ($self, $id, $path) = @_;
    
    close $self->current_file if $self->current_file;
    $self->{current_file_path} = $path;

    if (-e $self->current_file_path) {
        open my $file, "<", $self->current_file_path or die $!;
        $self->{current_file} = $file;
        my @lines = <$file>;
        $self->{all_lines} = \@lines;
        $self->{num_lines} = @lines;

    }
    else {
        $self->{num_lines} = -1;
        $self->{all_lines} = [];
        $self->{current_file} = undef;
    }    
    
    $self->_show_current_file();
}

sub on_keyframe_timestamp {
    my ($self, $tz_sec) = @_;
    
    my ($sec, $min, $hour, $day, $month, $year) = localtime($tz_sec);
    $self->{last_tz} = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $month + 1, $day, $hour, $min, $sec);
}

sub on_keyframe_timestamp_usec {
    my ($self, $tz_usec) = @_;
    
    $self->{last_tz} .= sprintf ".%6d", $tz_usec;
}

sub _formatted_last_tz {
    my $self = shift;
    return defined $self->{last_tz} ? "At: " . $self->{last_tz} : "";
}

sub _show_current_file {
    my $self = shift;
    
    $screen->clrscr();
    $screen->at(0, 0);

    if ($self->current_file) {
        $screen->bold->puts($self->current_file_path)->normal();
    }
    else {
        $screen->bold->puts("Can't find file\n")->normal();                
    }

    $screen->at(1, 0)->puts($self->_formatted_last_tz);
}

{
    my $site_libs = join "|", grep { /^\// } @INC;
    my $site_qr = qr{$site_libs};

    sub on_next_statement {
        my ($self, $line_no) = @_;

        $self->{last_line} = $line_no - 1;

        return unless $self->current_file;
        return if $self->skip_files->{$self->current_file_path};
        return if $self->skip_installed && $self->current_file_path =~ $site_qr;

        $self->_show_current_line();
        $self->_process_key();
    }

    sub _show_current_line {
        my $self = shift;
    
        my $line_no = $self->last_line;
        
        my $screen_cols = $screen->cols;
        my $screen_rows = int(($screen->rows - 4) / 2);
    
        my $from = $line_no > $screen_rows ? $line_no - $screen_rows : 0;
        my $to = $line_no + $screen_rows < $self->num_lines - 1 ? $line_no + $screen_rows : $self->num_lines - 1;
    
        # Adjust to fill screen
        $to += ($screen->rows - 4 - ($to - $from)) if ($to - $from) < $screen->rows - 4;

        $screen->at(1, 0)->puts($self->_formatted_last_tz);

        $screen->at(2, 0);
        $screen->clreos();
        my $p = length $self->num_lines;
    
        my $i = 0;
        for my $l ($from..$to) {    
            last if $l > $self->num_lines;
            last unless defined $self->all_lines->[$l];
            $screen->at(2 + $i++, 0);
            $screen->reverse if $l == $line_no;
            my $src = sprintf("% ${p}d: %s", $l, substr($self->all_lines->[$l], 0, $screen_cols - ($p + 2)));
            $screen->puts($src);
            $screen->normal if $l == $line_no;
        }        
    }
}

my %KEY_HANDLER = (
    q => sub { shift->done },
    s => sub { 
        my $self = shift; 
        $self->skip_files->{$self->current_file_path} = 1; 
    },
    a => sub { 
        $_[0]->{skip_installed} ^= 1;
        $screen->at(1, 0)->puts("Skip installed is: " . ((qw(OFF ON)[$_[0]->skip_installed])));
        $screen->getch();
    },
    h => \&_show_help,
);

sub _process_key {
    my $self = shift;
    
    if ($self->{autorun}) {
        sleep $self->{autorun};
        return;
    }
    
    my $k = lc $screen->getch();
    $screen->at(1, 0);

    my $handler = $KEY_HANDLER{$k} // sub {};
    $handler->($self);
    
    1;
}

sub _show_help {
    my $self = shift;
    
    $screen->clrscr();
    $screen->at(0, 0)->puts("Help for 'rr-viewer'");
    $screen->at(2, 0)->puts("'a' - Toggle skip files in \@INC at start");
    $screen->at(3, 0)->puts("'s' - Skip the current file");
    $screen->at(5, 0)->puts("'h' - Show this help");
    $screen->at(6, 0)->puts("'q' - Quit prematurely");
    $screen->at(8, 0)->puts("... press the ANY key to continue ...");
    $screen->getch();
    
    $self->_show_current_file();
    $self->_show_current_line();    
}

sub playback {
    my $self = shift;

    $self->reader->read_all();    
    $self->done;
}

sub done {
    my $self = shift;

    $self->_show_current_file();
    $self->_show_current_line();    
    
    $screen->at(0, 0)->clreol();
    $screen->at(0, 0)->puts("Playback completed, press the ANY key to quit...");

  
    $screen->getch();
    
    exit 0;
}

sub view {
    my ($pkg, $path, $args) = @_;

    my $viewer = $pkg->new($path, $args);
    
    $viewer->playback();
}

1;