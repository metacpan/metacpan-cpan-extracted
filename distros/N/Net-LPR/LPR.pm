package Net::LPR;

use 5.00500;
use strict;

use Carp;
use Socket;
use IO::Socket;
use IO::Socket::INET;
use Sys::Hostname;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = '1.007';

my %valid_options = (
    StrictRFCPorts => 1,
    RemoteServer => 1,
    RemotePort => 1,
    PrintErrors => 1,
    RaiseErrors => 1,
);

# Modes:
#   1 == ROOT command
#   2 == JOB command
#   3 == DATA command

sub new {

    my $class = shift;
    
    my $k;
    
    for $k (keys %{{ @_ }}) {
        croak "Invalid argument to Net::LPR->new: '$k'" unless exists($valid_options{$k});
    }
    
    my $self = {
        StrictRFCPorts => 1,
        RemoteServer => "localhost",
        RemotePort => 515,
        PrintErrors => 0,
        RaiseErrors => 0,

        Socket => undef,
        Jobs => {},        
        LastError => "",
        Mode => 0,

        @_
    };
    
    bless $self, $class;
    
    return $self;
}

sub _report {

    my $self = shift;
    my $prob = shift;
    my @cinfo = caller(1);
    my $func = reverse $cinfo[3];
    
    $func =~ s/::.*//g;
    $func = reverse $func;
    my $err = "$func: $prob";
    
    $self->{LastError} = $err;
    print STDERR ($err) if ($self->{PrintErrors});
    croak ($err) if ($self->{RaiseErrors});
}

sub error {

    croak 'Usage: $lp->error()' if (@_ != 1);

    my $self = shift;

    return $self->{LastError};
}

sub disconnect {

    croak 'Usage: $lp->disconnect()' if (@_ != 1);

    my $self = shift;
    
    undef $self->{Socket};
    
    $self->{Jobs} = {};
    
    return 1;
}

sub connect {

    croak 'Usage: $lp->connect()' if (@_ != 1);

    my $self = shift;

    if ($self->connected()) {
        return 1;
    }

    my $sock;

    if ($self->{StrictRFCPorts}) {
        my $port;
        for $port (721..731) {
            $sock = new IO::Socket::INET (
                PeerAddr => $self->{RemoteServer},
                PeerPort => $self->{RemotePort},
                LocalPort => $port,
                Proto => 'tcp',
                ReuseAddr => 1,
            );
            last if (defined($sock));
            last unless ($! =~ /in use|bad file number/i);
        }
        unless (defined($sock)) {
            if ($!) {
                $self->_report("Can't establish connection to remote printer ($!)");
            } else {
                $self->_report("Can't establish connection to remote printer (No local ports available)");
            }
            return undef;
        }
    } else {
        $sock = new IO::Socket::INET (
            PeerAddr => $self->{RemoteServer},
            PeerPort => $self->{RemotePort},
            Proto => 'tcp',
            ReuseAddr => 1,
        );
        unless (defined($sock)) {
            $self->_report("Can't establish connection to remote printer ($!)");
            return undef;
        }
    }
    
    $sock->autoflush(0);
    
    $self->{Socket} = $sock;
    $self->{Mode} = 1;
    
    return 1;
}

sub connected {

    croak 'Usage: $lp->connected()' if (@_ != 1);

    my $self = shift;

    undef $self->{Socket} if (defined($self->{Socket}) && ! $self->{Socket}->opened());

    return defined($self->{Socket});
}

# Daemon commands

sub print_waiting_jobs {

    croak 'Usage: $lp->print_waiting_jobs($queue)' if (@_ != 2);

    my $self = shift;

    unless ($self->connected()) {
        $self->_report("Not connected");
        return undef;
    }

    unless ($self->{Mode} == 1) {
        $self->_report("Not in ROOT command mode");
        return undef;
    }

    my $queue = shift;
    
    $queue =~ s/[\000-\040\200-\377]//g;
    
    $self->{Socket}->print("\001$queue\n") or do {
        $self->_report("Error sending command ($!)");
        return undef;
    };
    $self->{Socket}->flush() or do {
        $self->_report("Error flushing buffer ($!)");
        return undef;
    };
    
    return $self->disconnect();
}

sub send_jobs {

    croak 'Usage: $lp->send_jobs($queue)' if (@_ != 2);
    my $self = shift;

    unless ($self->connected()) {
        $self->_report("Not connected");
        return undef;
    }

    unless ($self->{Mode} == 1) {
        $self->_report("Not in ROOT command mode");
        return undef;
    }

    my $queue = shift;
    
    $queue =~ s/[\000-\040\200-\377]//g;
    
    $self->{Socket}->print("\002$queue\n") or do {
        $self->_report("Error sending command ($!)");
        return undef;
    };
    
    $self->{Socket}->flush() or do {
        $self->_report("Error flushing buffer ($!)");
        return undef;
    };
    
    my $result;
    
    $result = $self->{Socket}->getc();
    
    if (length($result)) {
        $result = unpack("C", $result);
    } else {
        $self->_report("Error getting result ($!)");
        return undef;
    };
    
    if ($result != 0) {
        $self->_report("Printer reported an error ($result)");
        return undef;
    }
    
    $self->{Mode} = 2;
    
    return 1;
}

sub get_queue_state {

    croak 'Usage: $lp->get_queue_state($queue [, $longflag [, @items]])' if (@_ < 2);
    
    my $self = shift;
    
    unless ($self->connected()) {
        $self->_report("Not connected");
        return undef;
    }

    unless ($self->{Mode} == 1) {
        $self->_report("Not in ROOT command mode");
        return undef;
    }

    my $queue = shift;
    
    $queue =~ s/[\000-\040\200-\377]//g;

    my $longflag = shift || 0;
    
    my $cmd = $longflag ? "\004" : "\003";

    $self->{Socket}->print("$cmd$queue ") or do {
        $self->_report("Error sending command ($!)");
        return undef;
    };

    my $item;
    
    while (defined($item = shift)) {

        $item =~ s/[\000-\040\200-\377]//g;

        $self->{Socket}->print("$item ") or do {
            $self->_report("Error sending item ($!)");
            return undef;
        };
    }
    
    $self->{Socket}->print("\n") or do {
        $self->_report("Error sending command ($!)");
        return undef;
    };

    $self->{Socket}->flush() or do {
        $self->_report("Error flushing buffer ($!)");
        return undef;
    };
    
    my $response = "";
    my $line;
    
    while (defined($line = $self->{Socket}->getline())) {
        $response .= $line;
    }
    
    return ( $self->disconnect() || undef ) && $response;
}

sub remove_jobs {

    croak 'Usage: $lp->remove_jobs($queue, $username [, @items])' if (@_ < 3);
    
    my $self = shift;
    
    unless ($self->connected()) {
        $self->_report("Not connected");
        return undef;
    }

    unless ($self->{Mode} == 1) {
        $self->_report("Not in ROOT command mode");
        return undef;
    }

    my $queue = shift;
    $queue =~ s/[\000-\040\200-\377]//g;
    
    my $username = shift;
    $username =~ s/[\000-\040\200-\377]//g;

    $self->{Socket}->print("\005$queue $username") or do {
        $self->_report("Error sending command ($!)");
        return undef;
    };

    my $item;
    
    while (defined($item = shift)) {

        $item =~ s/[\000-\040\200-\377]//g;

        $self->{Socket}->print(" $item") or do {
            $self->_report("Error sending item ($!)");
            return undef;
        };
    }
    
    $self->{Socket}->print("\n") or do {
        $self->_report("Error sending command ($!)");
        return undef;
    };
    
    $self->{Socket}->flush() or do {
        $self->_report("Error flushing buffer ($!)");
        return undef;
    };

    return $self->disconnect();
}

#
# Job subcommands
#

sub job_abort {

    croak 'Usage: $lp->job_abort()' if (@_ != 1);
    
    my $self = shift;
    
    unless ($self->connected()) {
        $self->_report("Not connected");
        return undef;
    }

    unless ($self->{Mode} == 2) {
        $self->_report("Not in JOB command mode");
        return undef;
    }

    $self->{Jobs} = {};

    $self->{Socket}->print("\001\n") or do {
        $self->_report("Error sending command ($!)");
        return undef;
    };
    
    $self->{Socket}->flush() or do {
        $self->_report("Error flushing buffer ($!)");
        return undef;
    };
    
    my $result;
    
    $result = $self->{Socket}->getc();
    
    if (length($result)) {
        $result = unpack("C", $result);
    } else {
        $self->_report("Error getting result ($!)");
        return undef;
    };
    
    if ($result != 0) {
        $self->_report("Printer reported an error ($result)");
        return undef;
    }

    return 1;
}

my $g_job_id = 0;

sub new_job {

    croak 'Usage: $jobkey = $lp->new_job([$jobid [, $jobhostname]])' if (@_ < 1 || @_ > 3);

    my $self = shift;
    my $jobid = shift;
    
    $jobid = $g_job_id unless (defined($jobid));
    
    if ($jobid !~ /^\d+$/ || $jobid > 999) {
        $self->_report("Invalid Job ID specified");
        return undef;
    }
    
    $g_job_id = ($jobid + 1) % 1000;

    my $jobname = shift;
    
    $jobname = hostname() unless (defined($jobname));
    
    $jobname =~ s/[\000-\040\200-\377]//g;
    
    my $jobkey = sprintf('%03d%s', $jobid, $jobname);
    
    if (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Duplicate Job ID specified");
        return undef;
    }
    
    my $user;
    
    if ($^O eq 'MSWin32') {
    	$user = getlogin();
    } else {
    	$user = scalar(getpwuid($>));
    }
    
    $self->{Jobs}->{$jobkey} = {
        JobID => $jobid,
        Jobname => $jobname,
        SentControl => 0,
        SentData => 0,
        UsedDataFileName => 0,
        ControlFileName => "cfA$jobkey",
        DataFileName => "dfA$jobkey",
        PrintingMode => '',
        DataSize => 0,
        DataSent => 0,
        CE => {
            H => hostname(),
            P => $user,
        },
    };
    
    return $jobkey;
}

sub job_get_data_filename {

    croak 'Usage: $lp->job_get_data_filename($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    return $self->{Jobs}->{$jobkey}->{DataFileName};
}

sub job_set_data_filename {

    croak 'Usage: $lp->job_set_data_filename($jobkey, $filename)' unless (@_ == 3);
    
    my $self = shift;
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentData}) {
        $self->_report("Already sent data file for '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{UsedDataFileName}) {
        $self->_report("Already referenced existing data file name for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    if (length($text) < 1) {
        $self->_report("File name must be at least one character");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{DataFileName} = $text;

    return 1;
}

sub job_get_control_filename {

    croak 'Usage: $lp->job_get_control_filename($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    return $self->{Jobs}->{$jobkey}->{ControlFileName};
}

sub job_set_control_filename {

    croak 'Usage: $lp->job_set_control_filename($jobkey, $filename)' unless (@_ == 3);
    
    my $self = shift;
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{UsedDataFileName}) {
        $self->_report("Already referenced existing data file name for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    if (length($text) < 1) {
        $self->_report("File name must be at least one character");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{ControlFileName} = $text;

    return 1;
}

sub job_set_banner_class {

    croak 'Usage: $lp->job_set_banner_class($jobkey, $text)' unless (@_ == 3);
    
    my $self = shift;
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 32) {
        $self->_report("Banner Class is too long (31 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("Banner Class is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{C} = $text;

    return 1;
}

sub job_set_hostname {

    croak 'Usage: $lp->job_set_hostname($jobkey, $hostname)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 32) {
        $self->_report("Hostname is too long (31 octet limit)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{H} = $text;

    return 1;
}

sub job_set_banner_name {

    croak 'Usage: $lp->job_set_banner_name($jobkey, $name)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 100) {
        $self->_report("Banner Name is too long (99 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("Banner Name is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{J} = $text;

    return 1;
}

sub job_enable_banner_page {

    croak 'Usage: $lp->job_enable_banner_page($jobkey, $username)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 32) {
        $self->_report("Banner User Name is too long (31 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("Banner User Name is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{L} = $text;

    return 1;
}

sub job_mail_when_printed {

    croak 'Usage: $lp->job_mail_when_printed($jobkey, $username)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 32) {
        $self->_report("Mail User Name is too long (31 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("Mail User Name is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{M} = $text;

    return 1;
}

sub job_set_source_filename {

    croak 'Usage: $lp->job_set_source_filename($jobkey, $filename)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 132) {
        $self->_report("Filename is too long (131 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("Filename is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{N} = $text;

    return 1;
}

sub job_set_user_id {

    croak 'Usage: $lp->job_set_user_id($jobkey, $username)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 32) {
        $self->_report("User Name is too long (31 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("User Name is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{P} = $text;

    return 1;
}

sub job_set_symlink_data {

    croak 'Usage: $lp->job_set_symlink_data($jobkey, $dev, $inode)' unless (@_ == 4);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $dev = shift;
    my $inode = shift;
    
    unless ($dev =~ /^\d+$/ && $inode =~ /^\d+$/) {
        $self->_report("Expected numeric arguments");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{S} = "$dev $inode";

    return 1;
}

sub job_unlink {

    croak 'Usage: $lp->job_unlink($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    $self->{Jobs}->{$jobkey}->{UsedDataFileName} = 1;
    
    $self->{Jobs}->{$jobkey}->{CE}->{P} = $self->{Jobs}->{$jobkey}->{DataFileName};

    return 1;
}

sub job_set_troff_r_font {

    croak 'Usage: $lp->job_set_troff_r_font($jobkey, $filename)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 256) {
        $self->_report("File Name is too long (255 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("File Name is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{1} = $text;

    return 1;
}

sub job_set_troff_i_font {

    croak 'Usage: $lp->job_set_troff_i_font($jobkey, $filename)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 256) {
        $self->_report("File Name is too long (255 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("File Name is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{2} = $text;

    return 1;
}

sub job_set_troff_b_font {

    croak 'Usage: $lp->job_set_troff_b_font($jobkey, $filename)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 256) {
        $self->_report("File Name is too long (255 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("File Name is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{3} = $text;

    return 1;
}

sub job_set_troff_s_font {

    croak 'Usage: $lp->job_set_troff_s_font($jobkey, $filename)' unless (@_ == 3);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $text = shift;

    $text =~ s/[\000-\040\200-\377]//g;
    
    unless (length($text) < 256) {
        $self->_report("File Name is too long (255 octet limit)");
        return undef;
    }
    
    unless (length($text) > 0) {
        $self->_report("File Name is too short (1 octet minimum)");
        return undef;
    }
    
    $self->{Jobs}->{$jobkey}->{CE}->{4} = $text;

    return 1;
}

sub job_mode_cif {

    croak 'Usage: $lp->job_mode_cif($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f' || $f eq 'l');
        delete $job->{CE}->{$f};
    }
    
    $job->{PrintFormat} = 'c';
     
    $job->{CE}->{c} = $job->{DataFileName};

    return 1;    
}

sub job_mode_dvi {

    croak 'Usage: $lp->job_mode_dvi($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f' || $f eq 'l');
        delete $job->{CE}->{$f};
    }
    
    $job->{PrintFormat} = 'd';
     
    $job->{CE}->{d} = $job->{DataFileName};

    return 1;    
}

sub job_mode_text {

    croak 'Usage: $lp->job_mode_text($jobkey [, $width [, $indentation [, $nofilter]]])' unless (@_ >= 2 && @_ <= 5);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $width = shift;
    
    if (defined($width) && $width !~ /^\d+$/) {
        $self->_report("Width argument must be numeric");
        return undef;
    }
    
    my $indentation = shift;

    if (defined($indentation) && $indentation !~ /^\d+$/) {
        $self->_report("Indentation argument must be numeric");
        return undef;
    }
    
    my $nofilter = shift;
    
    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f' || $f eq 'l');
        delete $job->{CE}->{$f};
    }
    
    if (defined($nofilter) && $nofilter) {
        $f = 'l';
    } else {
        $f = 'f';
    }
    
    $job->{PrintFormat} = $f;
     
    $job->{CE}->{$f} = $job->{DataFileName};
    $job->{CE}->{W} = $width if (defined($width));
    $job->{CE}->{I} = $indentation if (defined($indentation));

    return 1;    
}

sub job_mode_plot {

    croak 'Usage: $lp->job_mode_plot($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f');
        delete $job->{CE}->{$f};
    }
    
    $job->{PrintFormat} = 'g';
     
    $job->{CE}->{g} = $job->{DataFileName};

    return 1;    
}

sub job_mode_ditroff {

    croak 'Usage: $lp->job_mode_ditroff($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f' || $f eq 'l');
        delete $job->{CE}->{$f};
    }
    
    $job->{PrintFormat} = 'n';
     
    $job->{CE}->{n} = $job->{DataFileName};

    return 1;    
}

sub job_mode_postscript {

    croak 'Usage: $lp->job_mode_postscript($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f' || $f eq 'l');
        delete $job->{CE}->{$f};
    }
    
    $job->{PrintFormat} = 'o';
     
    $job->{CE}->{o} = $job->{DataFileName};

    return 1;    
}

sub job_mode_pr {

    croak 'Usage: $lp->job_mode_pr($jobkey [, $title [, $width]])' unless (@_ >= 2 && @_ <= 4);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $title = shift;
    
    if (defined($title)) {
        $title =~ s/[\000-\040\200-\377]//g;
        if (length($title) < 0) {
            $self->_report("Title too short (1 octet minimum)");
            return undef;
        } 
        if (length($title) > 79) {
            $self->_report("Title too long (79 octet maximum)");
        }
    }
    
    my $width = shift;
    
    if (defined($width) && $width !~ /^\d+$/) {
        $self->_report("Width argument must be numeric");
        return undef;
    }

    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f' || $f eq 'l');
        delete $job->{CE}->{$f};
    }
    
    $job->{PrintFormat} = 'p';
     
    $job->{CE}->{p} = $job->{DataFileName};
    $job->{CE}->{T} = $title if (defined($title));
    $job->{CE}->{W} = $width if (defined($width));

    return 1;    
}

sub job_mode_fortran {

    croak 'Usage: $lp->job_mode_fortran($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f' || $f eq 'l');
        delete $job->{CE}->{$f};
    }
    
    $job->{PrintFormat} = 't';
     
    $job->{CE}->{t} = $job->{DataFileName};

    return 1;    
}

sub job_mode_troff {

    croak 'Usage: $lp->job_mode_troff($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f' || $f eq 'l');
        delete $job->{CE}->{$f};
    }
    
    $job->{PrintFormat} = 't';
     
    $job->{CE}->{t} = $job->{DataFileName};

    return 1;    
}

sub job_mode_raster {

    croak 'Usage: $lp->job_mode_raster($jobkey)' unless (@_ == 2);
    
    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    my $job = $self->{Jobs}->{$jobkey};

    my $f = $job->{PrintFormat};

    $job->{UsedDataFileName} = 1;
    
    if (defined($f) && length($f)) {
        delete $job->{CE}->{W} if ($f eq 'f' || $f eq 'l' || $f eq 'p');
        delete $job->{CE}->{T} if ($f eq 'p');
        delete $job->{CE}->{I} if ($f eq 'f' || $f eq 'l');
        delete $job->{CE}->{$f};
    }
    
    $job->{PrintFormat} = 'v';
     
    $job->{CE}->{v} = $job->{DataFileName};

    return 1;    
}

sub job_send_control_file {

    croak 'Usage: $lp->job_send_control_file($jobkey)' unless (@_ == 2);

    my $self = shift;
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentControl}) {
        $self->_report("Already sent control file for '$jobkey'");
        return undef;
    }

    unless ($self->{Mode} == 2) {
        $self->_report("Not in JOB command mode");
        return undef;
    }

    my $cf = "";
    
    my $k;

    my $result;
    
    for $k (qw(C H I J M N P S T U W L 1 2 3 4 c d f g k l n o p r t v z)) {
        next unless (exists($self->{Jobs}->{$jobkey}->{CE}->{$k}));
        $cf .= $k . $self->{Jobs}->{$jobkey}->{CE}->{$k} . "\n";
    }

    $self->{Socket}->print("\002".length($cf)." ".$self->{Jobs}->{$jobkey}->{ControlFileName}."\n") or do {
        $self->_report("Error sending command ($!)");
        return undef;
    };
    
    $self->{Socket}->flush() or do {
        $self->_report("Error flushing buffer ($!)");
        return undef;
    };

    $result = $self->{Socket}->getc();
    
    if (length($result)) {
        $result = unpack("C", $result);
    } else {
        $self->_report("Error getting result ($!)");
        return undef;
    };
    
    if ($result != 0) {
        $self->_report("Printer reported an error ($result)");
        return undef;
    }

    $self->{Socket}->print("$cf\000") or do {
        $self->_report("Error sending control file ($!)");
        return undef;
    };
    
    $self->{Socket}->flush() or do {
        $self->_report("Error flushing buffer ($!)");
        return undef;
    };

    $result = $self->{Socket}->getc();
    
    if (length($result)) {
        $result = unpack("C", $result);
    } else {
        $self->_report("Error getting result ($!)");
        return undef;
    };
    
    if ($result != 0) {
        $self->_report("Printer reported an error ($result)");
        return undef;
    }

    $self->{Jobs}->{$jobkey}->{SentControl} = 1;
}

sub job_send_data {

    croak 'Usage: $lp->job_send_data($jobkey, $data [, $totalsize])' unless (@_ >= 1);
    
    my $self = shift;
    
    if ($self->{Mode} == 2) {
        croak 'JOB Mode Usage: $lp->job_send_data($jobkey, $data [, $totalsize])' unless (@_ >= 2 && @_ <= 3);
    } elsif ($self->{Mode} == 3) {
        croak 'DATA Mode Usage: $lp->job_send_data($jobkey, $data)' unless (@_ == 2);
    } else {
        $self->_report("Not in JOB or DATA command mode");
    }
    
    my $jobkey = shift;
    
    unless (exists($self->{Jobs}->{$jobkey})) {
        $self->_report("Nonexistant Job Key '$jobkey'");
        return undef;
    }

    if ($self->{Jobs}->{$jobkey}->{SentData}) {
        $self->_report("Already sent data file for '$jobkey'");
        return undef;
    }
    
    my $data = shift;

    my $totalsize = shift;

    if (defined($totalsize) && $totalsize !~ /^\d+$/) {
        $self->_report("Size argument must be numeric");
        return undef;
    }

    if ($self->{Mode} == 2) {

	if (defined($totalsize)) {
            $self->{Socket}->print("\003$totalsize ".$self->{Jobs}->{$jobkey}->{DataFileName}."\n") or do {
        	$self->_report("Error sending command ($!)");
        	return undef;
            };
	} else {
            $self->{Socket}->print("\003 ".$self->{Jobs}->{$jobkey}->{DataFileName}."\n") or do {
        	$self->_report("Error sending command ($!)");
        	return undef;
            };
        }

        $self->{Socket}->flush() or do {
            $self->_report("Error flushing buffer ($!)");
            return undef;
        };

        my $result;

        $result = $self->{Socket}->getc();

        if (defined($result) && length($result)) {
            $result = unpack("C", $result);
        } else {
            $self->_report("Error getting result ($!)");
            return undef;
        };

        if ($result != 0) {
            $self->_report("Printer reported an error ($result)");
            return undef;
        }

        $self->{Jobs}->{$jobkey}->{DataSize} = $totalsize if (defined($totalsize));
        $self->{Mode} = 3;        
        $self->{Jobs}->{$jobkey}->{UsedDataFileName} = 1;
    }
    
    if ($self->{Mode} != 3) {
        $self->_report("Can't send data in this mode");
        return undef;
    }
    
    my $job = $self->{Jobs}->{$jobkey};

    my $dsize = length($data);

    if ($job->{DataSize} > 0 && $dsize + $job->{DataSent} > $job->{DataSize}) {
        $data = substr($data, 0, $job->{DataSize} - $job->{DataSent});
    }
    
    if (length($data) > 0) {
        $self->{Socket}->print($data) or do {
            $self->_report("Error sending data ($!)");
            return undef;
        };
    }
    
    $job->{DataSent} += length($data);
    
    if ($job->{DataSent} >= $job->{DataSize}) {

        $job->{SentData} = 1;

        if ($job->{SentControl}) {
            delete $self->{Jobs}->{$jobkey};
        }
        
        $self->{Socket}->print("\000") or do {
            $self->_report("Error sending data ($!)");
            return undef;
        };
        
        $self->{Socket}->flush() or do {
            $self->_report("Error flushing buffer ($!)");
            return undef;
        };

        my $result;

        $result = $self->{Socket}->getc();

        if (length($result)) {
            $result = unpack("C", $result);
        } else {
            $self->_report("Error getting result ($!)");
            return undef;
        };

        if ($result != 0) {
            $self->_report("Printer reported an error ($result)");
            return undef;
        }
    }
    
    if ($dsize != length($data)) {
        $self->_report("Data overflow error");
        return undef;
    }
    
    return 1;
}

1;
