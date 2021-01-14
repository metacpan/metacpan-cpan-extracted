=head1 NAME

QMail::QueueHandler - Module to manage QMail message queues

=head1 DESCRIPTION

This is all the code behind the qmHandle command line program.

=head1 SYNOPSIS

    use QMail::QueueHandler;

    QMail::QueueHandler->new->run;

=cut

package QMail::QueueHandler;

use Moose;

use Term::ANSIColor;
use Getopt::Std;
use File::Basename;

our $VERSION = '2.0.4';
my $me       = basename $0;

# Where qmail stores all of its files
has queue => (
    is      => 'ro',
    isa     => 'Str',
    default => '/var/qmail/queue/',
);

# Which todo format do we have?
has bigtodo => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { -d $_[0]->queue . 'todo/0' },
);

# Various commands that we use
has commands => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {
            start => '/sbin/service qmail start',
            stop  => '/sbin/service qmail stop',
            pid   => '/sbin/pidof qmail-send',
        };
    },
);

# Colours for output.
# Default is non-coloured. These values can be changed in parse_args.
has colours => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {
            msg  => '',
            stat => '',
            end  => '',
        };
    },
);

# Are we showing a summary?
has summary => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

# Are we supposed to be deleting things?
has deletions => (
    is  => 'rw',
    isa => 'Bool',
);

# What actions are we carrying out.
# Each element in this array is another array.
# The first element in these second level arrays is a code ref.
# The other elements are arguments to be passed to the code ref.
has actions => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_action  => 'push',
        all_actions => 'elements',
    },
);

# Do we need to restart QMail once we have finished?
has restart => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

# List of messages to delete
has to_delete => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_to_delete   => 'push',
        all_to_delete   => 'elements',
        to_delete_count => 'count',
    },
);

before add_to_delete => sub {
    my $self = shift;
    my ($msg_id) = @_;

    warn "Message [$msg_id] queued for deletion.\n";
};

# List of messages to flag
has to_flag => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        add_to_flag => 'push',
        all_to_flag => 'elements',
    },
);

# Hash containing details of the messages in the queue
has msglist => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub BUILD {
    my $self = shift;

    # Get command line options
    $self->parse_args;
}

=head1 METHODS

=head2 run()

Main driver method.

=cut

sub run {
    my $self = shift;
    my @args = @_;

    # (Possibly) stop qmail
    $self->stop_qmail;

    # Execute actions
    foreach my $action ( $self->all_actions ) {
        my $sub = shift @$action;    # First element is the sub
        $self->$sub(@$action);       # Others the arguments, if any
    }

    # If we have planned deletions, then do them.
    if ( $self->to_delete_count ) {
        $self->trash_msgs;
    }

    # If we stopped qmail, then restart it
    $self->start_qmail;
}

sub _get_todo {
    my $self = shift;
    my ($todohash, $msglist) = @_;

    my $queue = $self->queue;

    opendir( my $tododir, "${queue}todo" );

    if ( $self->bigtodo ) {
        foreach my $todofile ( grep { !/\./ } readdir $tododir ) {
            $todohash->{$todofile} = $todofile;
        }
    }
    else {
        foreach my $tododir ( grep { !/\./ } readdir $tododir ) {
            opendir( my $subdir, "${queue}todo/$tododir" );
            foreach my $todofile (
                grep { !/\./ }
                map  { "$tododir/$_" } readdir $subdir
              ) {
                $msglist->{$todofile}{'todo'} = $todofile;
            }
        }
    }
    closedir $tododir;
}

sub _get_info {
    my $self = shift;
    my ($dir, $msglist) = @_;

    my $queue = $self->queue;

    opendir( my $infosubdir, "${queue}info/$dir" );

    foreach my $infofile (
        grep { !/\./ }
        map  { "$dir/$_" } readdir $infosubdir
      ) {
        $msglist->{$infofile}{sender} = 'S';
    }

    close $infosubdir;
}

sub _get_local {
    my $self = shift;
    my ($dir, $msglist) = @_;

    my $queue = $self->queue;

    opendir( my $localsubdir, "${queue}local/$dir" );

    foreach my $localfile (
        grep { !/\./ }
        map  { "$dir/$_" } readdir $localsubdir
      ) {
        $msglist->{$localfile}{local} = 'L';
    }

    close $localsubdir;
}

sub _get_remote {
    my $self = shift;
    my ($dir, $msglist) = @_;

    my $queue = $self->queue;

    opendir( my $remotesubdir, "${queue}remote/$dir" );

    foreach my $remotefile (
        grep { !/\./ }
        map  { "$dir/$_" } readdir $remotesubdir
    ) {
        $msglist->{$remotefile}{remote} = 'R';
    }

  close $remotesubdir;
}

sub _get_subdir {
    my $self = shift;
    my ($dir, $msglist, $todohash, $bouncehash) = @_;

    my $queue = $self->queue;

    opendir( my $subdir, "${queue}mess/$dir" );

    foreach my $file (
        grep { !/\./ }
        map  { "$dir/$_" } readdir $subdir
      ) {
        my $msgno = ( split( /\//, $file ) )[1];
        if ( $bouncehash->{$msgno} ) {
            $msglist->{$file}{bounce} = 'B';
        }
        if ( $self->bigtodo ) {
            if ( $todohash->{$msgno} ) {
                $msglist->{$file}{todo} = $msgno;
            }
        }
    }

    closedir $subdir;
}

sub _build_msglist {
    my $self = shift;

    my $queue = $self->queue;

    my ( $todohash, $bouncehash );
    my $msglist = {};

    $self->_get_todo($todohash, $msglist);

    opendir( my $bouncedir, "${queue}bounce" );
    foreach my $bouncefile ( grep { !/\./ } readdir $bouncedir ) {
        $bouncehash->{$bouncefile} = 'B';
    }
    closedir $bouncedir;

    opendir( my $messdir, "${queue}mess" );

    foreach my $dir ( grep { !/\./ } readdir $messdir ) {
        $self->_get_info($dir);
        $self->_get_local($dir);
        $self->_get_remote($dir);
        $self->_get_subdir($dir);
    }
    closedir $messdir;

    return $msglist;
}

=head2 parse_args()

Parse the command line arguments and set any required attributes.

=cut

sub parse_args {
    my $self = shift;

    @ARGV or $self->usage;

    my %opt;

    my %option = (
        # (Attempt to) send all queued messages
        a => {
            arg  => 0,
            code => sub {
                $self->add_action( [ \&send_msgs ] );
            },
        },
        # List message queues
        l => {
            arg  => 0,
            code => sub {
                $self->add_action( [ \&list_msg, 'A' ] );
            },
        },
        # List local message queue
        L => {
            arg  => 0,
            code => sub {
                $self->add_action( [ \&list_msg, 'L' ] );
            },
        },
        # List remote message queue
        R => {
            arg  => 0,
            code => sub {
                $self->add_action( [ \&list_msg, 'R' ] );
            },
        },
        # List message numbers only
        N => {
            arg  => 0,
            code => sub {
                $self->summary(1);
            },
        },
        # Coloured output
        c => {
            arg  => 0,
            code => sub {
                @{ $self->colours }{qw[msg stat end]} = (
                    color('bold bright_blue'),
                    color('bold bright_red'),
                    color('reset'),
                );
            },
        },
        # Show statistics of queues
        s => {
            arg  => 0,
            code => sub {
                $self->add_action( [ \&stats ] );
            },
        },
        # Display message with given number
        m => {
            arg  => 1,
            code => sub {
                $self->add_action( [ \&view_msg, @_ ] );
            },
        },
        # Delete messages from given sender
        f => {
            arg  => 1,
            code => sub {
                $self->add_action( [ \&del_msg_from_sender, @_ ] );
                $self->deletions(1);
            },
        },
        # Delete messages from given sender (regex match)
        F => {
            arg  => 1,
            code => sub {
                $self->add_action( [ \&del_msg_from_sender_r, @_ ] );
                $self->deletions(1);
            },
        },
        # Delete message with given number
        d => {
            arg  => 1,
            code => sub {
                $self->add_action( [ \&del_msg, @_ ] );
                $self->deletions(1);
            },
        },
        # Delete messages with matching subject
        S => {
            arg  => 1,
            code => sub {
                $self->add_action( [ \&del_msg_subj, @_ ] );
                $self->deletions(1);
            },
        },
        # Delete messages with matching header (case insensitive)
        h => {
            arg  => 1,
            code => sub {
                $self->add_action( [ \&del_msg_header_r, @_, 1 ] );
                $self->deletions(1);
            },
        },
        # Delete messages with matching body (case insensitive)
        b => {
            arg  => 1,
            code => sub {
                $self->add_action( [ \&del_msg_body_r, @_, 1 ] );
                $self->deletions(1);
            },
        },
        # Delete messages with matching header (case sensitive)
        H => {
            arg  => 1,
            code => sub {
                $self->add_action( [ \&del_msg_header_r, @_, 0 ] );
                $self->deletions(1);
            },
        },
        # Delete messages with matching body (case sensitive)
        B => {
            arg  => 1,
            code => sub {
                $self->add_action( [ \&del_msg_body_r, @_, 0 ] );
                $self->deletions(1);
            },
        },
        # Flag messages with matching recipients
        t => {
            arg  => 1,
            code => sub {
                $self->add_actions( [ \&flag_remote, @_ ] );
            },
        },
        # Delete all messages in queues
        D => {
            arg  => 0,
            code => sub {
                $self->add_action( [ \&del_all ] );
                $self->deletions(1);
            },
        },
        # Display program version
        V => {
            arg  => 0,
            code => sub {
                $self->add_action( [ \&version ] );
            },
        },
        # Display help
        '?' => {
            arg  => 0,
            code => sub {
                $self->usage;
            },
        },
    );

    my $optstring = join '', map { $_ . ( $option{$_}{arg} ? ':' : '' ) }
      keys %option;

    getopts( $optstring, \%opt );

    foreach my $opt ( keys %opt ) {
        if (! exists $option{$opt}) {
            warn "$opt is not a valid option\n";
            next;
        }
        if ( $option{$opt}{arg} and not $opt{$opt} ) {
            die "Option $opt must have an argument\n";
        }

        if ($option{$opt}{arg}) {
            $option{$opt}{code}->($opt{$opt});
        } else {
            $option{$opt}{code}->();
        }
    }

    return;
}

=head2 stop_qmail()

Optionally stop the qmail daemon.

=cut

sub stop_qmail {
    my $self = shift;

    # Don't need to stop qmail if we're not planning to delete stuff
    return unless $self->deletions;

    # If qmail is running, we stop it
    if ( my $qmpid = $self->qmail_pid ) {

        # If there is a system script available, we use it
        if ( $self->commands->{stop} ne '' ) {

            warn "Calling system script to terminate qmail...\n";
            if ( system( $self->commands->{stop} ) > 0 ) {
                die 'Could not stop qmail';
            }
            sleep 1 while $self->qmail_pid;

            # Otherwise, we're killers!
        }
        else {
            warn "Terminating qmail (pid $qmpid)... ",
              "this might take a while if qmail is working.\n";
            kill 'TERM', $qmpid;

            sleep 1 while $self->qmail_pid;
        }

        # If it isn't, we don't. We also return a false value so our caller
        # knows they might not want to restart it later.
    }
    else {
        warn "Qmail isn't running... no need to stop it.\n";
        return;
    }

    $self->restart(1);

    return 1;
}


=head2 start_qmail()

Restart the qmail daemon if it was previously stopped.

=cut

sub start_qmail {
    my $self = shift;

    return unless $self->restart;

    # If qmail is running, why restart it?
    if ( my $qmpid = $self->qmail_pid ) {
        warn "Qmail is already running again, so it won't be restarted.\n";
        return 1;
    }

    # In any other case, we restart it
    warn "Restarting qmail... \n";
    system( $self->commands->{start} );
    warn "Done (hopefully).\n";

    return 1;
}

=head2 get_subject($msg_id)

Given the id of a message, return the subject of that message.

=cut

sub get_subject {
    my $self = shift;
    my ($msg_id) = @_;

    my $msgsub;
    my $queue = $self->queue;
    open( my $msg_fh, '<', "${queue}mess/$msg_id" )
      or die("cannot open message $msg_id! Is qmail-send running?\n");
    while (<$msg_fh>) {
        chomp;
        last if !/\S/; # End of headers
        if (/^Subject: (.*)/) {
            $msgsub = $1;
            last;
        }
    }
    close($msg_fh);
    return $msgsub;
}

=head2 get_sender($msg_id)

Given the id of a message, return the sender of the message.

=cut

sub get_sender {
    my $self = shift;
    my ($msg_id) = @_;

    my $queue = $self->queue;

    open( my $msg_fh, '<', "${queue}/info/$msg_id" )
      or die( "cannot open info file ${queue}/info/$msg_id! ",
        "Is qmail-send running?\n" );
    my $sender = <$msg_fh>;
    substr( $sender, 0, 1 ) = '';
    chomp $sender;
    close($msg_fh);
    return $sender;
}

=head2 send_msgs()

Attempt to send all currently queued messages.

It does this by sending SIGALRM to the qmail daemon.

=cut

sub send_msgs {
    my $self = shift;

    # If qmail is running, we force sending of messages
    if ( my $qmpid = $self->qmail_pid ) {

        kill 'ALRM', $qmpid;

    }
    else {

        warn "Qmail isn't running, can't send messages!\n";

    }
    return;
}

=head2 show_msg_info($msg_id)

Given a message id, display the information about that message.

=cut

sub show_msg_info {
    my $self = shift;
    my ($msg_id) = @_;

    my %msg;
    my $queue = $self->queue;

    open( my $info_fh, '<', "${queue}info/$msg_id" );
    $msg{ret} = <$info_fh>;
    substr( $msg{ret}, 0, 1 ) = '';
    chomp $msg{ret};
    close($info_fh);
    my ( $dirno, $rmsg ) = split( /\//, $msg_id );
    print "$rmsg ($dirno, $msg_id)\n";

    # Get message (file) size
    $msg{fsize} = ( stat("${queue}mess/$msg_id") )[7];

    my %header = (
        Date    => 'date',
        From    => 'from',
        Subject => 'subject',
        To      => 'to',
        Cc      => 'cc',
    );

    # Read something from message header (sender, receiver, subject, date)
    open( my $msg_fh, '<', "${queue}mess/$msg_id" );
    while (<$msg_fh>) {
        chomp;
        # Stop processing at the end of the headers
        last unless /\S/;
        foreach my $h ( keys %header ) {
            if (/^$h: (.*)/) {
                $msg{ $header{$h} } = $1;
                last;
            }
        }
    }
    close($msg_fh);

    # Add "pseudo-headers" for output
    $header{'Return-path'} = 'ret';
    $header{Size} = 'fsize';

    my $colours = $self->colours;
    my ( $cmsg, $cend ) = @{$colours}{qw[msg end]};

    for (qw[Return-path From To Cc Subject Date Size]) {
        next unless exists $msg{ $header{$_} };

        print "  ${cmsg}$_${cend}: $msg{$header{$_}}\n";
    }

    return;
}

=head2 list_msg($queue)

Display information for all messages in a given queue.

The $queue parameter should be 'L' to display only local messages, 'R'
to display only remote messages or anything else to display all messages.

=cut

sub list_msg {
    my $self = shift;
    my ($q) = @_;

    $q = uc $q;

    my $local =  $q ne 'R';
    my $remote = $q ne 'L';

    my $msglist = $self->msglist;
    if ( !$self->summary ) {
        for my $msg ( keys %$msglist ) {
            next if $local  and not $msglist->{$msg}{local};
            next if $remote and not $msglist->{$msg}{remote};

            $self->show_msg_info($msg);
        }
    }

    $self->stats;
    return;
}

=head2 view_msg($msg_id)

View a message in the queue

=cut

sub view_msg {
    my $self = shift;
    my ($msg_id) = @_;

    if ( $msg_id =~ /\D/ ) {
        warn "$msg_id is not a valid message number!\n";
        return;
    }

    # Search message
    my $ok    = 0;
    my $queue = $self->queue;
    for my $msg ( keys %{ $self->msglist } ) {
        if ( $msg =~ /\/$msg_id$/ ) {
            $ok = 1;
            print "\n --------------\nMESSAGE NUMBER $msg_id \n --------------\n";
            open( my $msg_fh, '<', "${queue}mess/$msg" );
            print while <$msg_fh>;
            close($msg_fh);
            last;
        }
    }

    # If the message isn't found, print a notice
    if ( !$ok ) {
        warn "Message $msg_id not found in the queue!\n";
    }

    return;
}

=head2 trash_msgs()

Delete all of the messages whose ids are in the C<all_to_delete>
array.

=cut

sub trash_msgs {
    my $self = shift;

    my $queue    = $self->queue;
    my $msglist  = $self->msglist;
    my @todelete = ();
    my $grouped  = 0;
    my $deleted  = 0;
    foreach my $msg ( $self->all_to_delete ) {
        $grouped++;
        $deleted++;
        my $msgno = ( split( /\//, $msg ) )[1];
        if ( $msglist->{$msg}{bounce} ) {
            push @todelete, "${queue}bounce/$msgno";
        }
        push @todelete, "${queue}mess/$msg", "${queue}info/$msg";
        if ( $msglist->{$msg}{remote} ) {
            push @todelete, "${queue}remote/$msg";
        }
        if ( $msglist->{$msg}{local} ) {
            push @todelete, "${queue}local/$msg";
        }
        if ( $msglist->{$msg}{todo} ) {
            push @todelete, "${queue}todo/$msglist->{$msg}{'todo'}",
                            "${queue}intd/$msglist->{$msg}{'todo'}";
        }
        if ( $grouped == 11 ) {
            unlink @todelete;
            @todelete = ();
            $grouped  = 0;
        }
    }
    if ($grouped) {
        unlink @todelete;
    }
    my $msg_str = $deleted == 1 ? 'message' : 'messages';
    warn "Deleted $deleted $msg_str from queue\n";
    return;
}

=head2 flag_msgs()

Flag all messages whose ids are in the C<all_to_flag> array.

=cut

sub flag_msgs {
    my $self = shift;

    my $queue     = $self->queue;
    my $now       = time;
    my @flagqueue = ();
    my $flagged   = 0;
    foreach my $msg ( $self->all_to_flag ) {
        push @flagqueue, "${queue}info/$msg";
        $flagged++;
        if ( $flagged == 30 ) {
            utime $now, $now, @flagqueue;
            $flagged   = 0;
            @flagqueue = ();
        }
    }
    if ($flagged) {
        utime $now, $now, @flagqueue;
    }
    return;
}

=head2 del_msg($msg_id)

Given a message id, add that message to the list of messages to delete.

The actual deletion is carried out by C<trash_msgs>.

=cut

sub del_msg {
    my $self = shift;
    my ($msg_id) = @_;

    if ( $msg_id =~ /\D/ ) {
        warn "$msg_id is not a valid message number!\n";
        return;
    }

    # Search message
    my $ok = 0;
    for my $msg ( keys %{ $self->msglist } ) {
        if ( $msg =~ /\/$msg_id$/ ) {
            $ok = 1;
            $self->add_to_delete($msg);
            last;
        }
    }

    # If the message isn't found, print a notice
    if ( !$ok ) {
        warn "Message $msg_id not found in the queue!\n";
    }

    return;
}

=head2 del_msg_from_sender($sender)

Given a sender's email address, add all messages from that sender to the
list of messages to delete.

The actual deletion is carried out by C<trash_msgs>.

=cut

sub del_msg_from_sender {
    my $self = shift;
    my ($sender) = @_;

    warn "Looking for messages from $sender\n";

    my $ok = 0;
    for my $msg ( keys %{ $self->msglist } ) {
        if ( $self->msglist->{$msg}{sender} ) {
            my $msg_sender = $self->get_sender($msg);
            if ( $msg_sender eq $sender ) {
                $ok = 1;
                $self->add_to_delete($msg);
            }
        }
    }

    # If no messages are found, print a notice
    if ( !$ok ) {
        warn "No messages from $sender found in the queue!\n";
    }

    return;
}

=head2 del_msg_from_sender_r($sender)

Given a sender's email address, add all messages from that sender to the
list of messages to delete.

This method treats $sender as a regex.

The actual deletion is carried out by C<trash_msgs>.

=cut

sub del_msg_from_sender_r {
    my $self = shift;
    my ($sender_re) = @_;

    warn "Looking for messages from senders matching $sender_re\n";

    my $ok = 0;
    for my $msg ( keys %{ $self->msglist } ) {
        if ( $self->msglist->{$msg}{sender} ) {
            my $msg_sender = $self->get_sender($msg);
            if ( $msg_sender =~ /$sender_re/ ) {
                $ok = 1;
                $self->add_to_delete($msg);
            }
        }
    }

    # If no messages are found, print a notice
    if ( !$ok ) {
        warn "No messages from senders matching ",
          "$sender_re found in the queue!\n";
    }

    return;
}

=head2 del_msg_header($header_re, $is_case_sensitive)

Given a regex, add all messages with headers that match the regex to the
list of messages to delete.

The actual deletion is carried out by C<trash_msgs>.

=cut

sub del_msg_header_r {
    my $self = shift;
    my ( $header_re, $is_case_sensitive ) = @_;

    warn "Looking for messages with headers matching $header_re\n";

    $header_re = "(?i)$header_re" if $is_case_sensitive;

    my $queue = $self->queue;
    my $ok    = 0;
    for my $msg ( keys %{ $self->msglist } ) {
        open( my $msg_fh, '<', "${queue}mess/$msg" )
          or die("cannot open message $msg! Is qmail-send running?\n");
        while (<$msg_fh>) {
            chomp;
            last if ! /\S/; # End of headers
            if (/$header_re/) {
                $ok = 1;
                $self->add_to_delete($msg);
                last;
            }
        }
        close($msg_fh);

    }

    # If no messages are found, print a notice
    if ( !$ok ) {
        warn "No messages with headers matching $header_re ",
            "found in the queue!\n";
    }

    return;
}

=head2 del_msg_body_r($body_re, $is_case_sensitive)

Given a regex, add all messages with a body that matches the regex to the
list of messages to delete.

The actual deletion is carried out by C<trash_msgs>.

=cut

sub del_msg_body_r {
    my $self = shift;
    my ( $body_re, $is_case_sensitive ) = @_;

    my $queue = $self->queue;

    warn "Looking for messages with body matching $body_re\n";

    $body_re = "(?i)$body_re" if $is_case_sensitive;

    my $ok = 0;
    for my $msg ( keys %{ $self->msglist } ) {
        open( my $msg_fh, '<', "${queue}mess/$msg" )
          or die("cannot open message $msg! Is qmail-send running?\n");
        # Skip headers
        while (<$msg_fh>) {
            chomp;
            last if !/\S/;
        }
        while (<$msg_fh>) {
            if (/$body_re/) {
                $ok = 1;
                $self->add_to_delete($msg);
                last;
            }
        }
        close($msg_fh);
    }

    # If no messages are found, print a notice
    if ( !$ok ) {
        warn "No messages with body matching $body_re found in the queue!\n";
    }

    return;
}

=head2 del_msg_subj($subject, $is_case_sensitive)

Given a subject, add all messages with that subject to the list of messages
to delete.

The actual deletion is carried out by C<trash_msgs>.

=cut

sub del_msg_subj {
    my $self = shift;
    my ($subject) = @_;

    warn "Looking for messages with Subject: $subject\n";

    # Search messages
    my $ok = 0;
    for my $msg ( keys %{ $self->msglist } ) {
        my $msgsub = $self->get_subject($msg);

        if ( $msgsub and $msgsub =~ /$subject/ ) {
            $ok = 1;
            $self->add_to_delete($msg);
        }

    }

    # If no messages are found, print a notice
    if ( !$ok ) {
        warn "No messages matching Subject \"$subject\" found in the queue!\n";
    }

    return;
}

=head2 del_all()

Delete all messages in the queue.

The actual deletion is carried out by C<trash_msgs>.

=cut

sub del_all {
    my $self = shift;

    # Search messages
    my $ok = 0;
    for my $msg ( keys %{ $self->msglist } ) {
        $ok = 1;
        $self->add_to_delete($msg);
    }

    # If no messages are found, print a notice
    if ( !$ok ) {
        warn "No messages found in the queue!\n";
    }

    return;
}

=head2 flag_remote($recipient_re)

Flag all remote messages whose recipient matches the given regex.

=cut

sub flag_remote {
    my $self = shift;
    my ($recipient_re) = @_;

    my $queue = $self->queue;

    warn "Looking for messages with recipients in $recipient_re\n";

    my $ok = 0;
    for my $msg ( keys %{ $self->msglist } ) {
        if ( $self->msglist->{$msg}{remote} ) {
            open( my $msg_fh, '<', "${queue}remote/$msg" )
              or die( "cannot open remote file for message $msg! ",
                "Is qmail-send running?\n" );
            my $recipients = <$msg_fh>;
            chomp($recipients);
            close($msg_fh);
            if ( $recipients =~ /$recipient_re/ ) {
                $ok = 1;
                $self->add_to_flag($msg);
                warn "Message $msg being tagged for earlier retry ",
                  "(and lengthened stay in queue)!\n";
            }
        }
    }

    # If no messages are found, print a notice
    if ( !$ok ) {
        warn "No messages with recipients in $recipient_re ",
            "found in the queue!\n";
        return;
    }

    $self->flag_msgs;

    return;
}

=head2 stats()

Display statistics about the queue.

=cut

sub stats {
    my $self = shift;

    my $total = 0;
    my $l     = 0;
    my $r     = 0;
    my $b     = 0;
    my $t     = 0;

    foreach my $msg ( keys %{ $self->msglist } ) {
        $total++;
        $self->msglist->{$msg}{local}  && $l++;
        $self->msglist->{$msg}{remote} && $r++;
        $self->msglist->{$msg}{bounce} && $b++;
        $self->msglist->{$msg}{todo}   && $t++;
    }

    my $colours = $self->colours;
    my ( $cstat, $cend ) = @{$colours}{qw[stat end]};

    print <<"END_OF_STATS";
${cstat}Total messages${cend}: $total
${cstat}Messages with local recipients${cend}: $l
${cstat}Messages with remote recipients${cend}: $r
${cstat}Messages with bounces${cend}: $b
${cstat}Messages in preprocess${cend}: $t
END_OF_STATS
    return;
}

=head2 qmail_pid()

Get the pid of the qmail daemon

=cut

sub qmail_pid {
    my $self   = shift;
    my $pidcmd = $self->commands->{pid};
    my $qmpid  = `$pidcmd`;
    return 0 unless $qmpid;
    chomp($qmpid);
    $qmpid =~ s/\s+//g;
    return 0 if $qmpid =~ /\D/;
    return $qmpid;
}

=head2 usage()

Display usage information.

=cut

sub usage {
    print <<"END_OF_HELP";
$me v$VERSION
Copyright (c) 2016 Dave Cross <dave\@perlhacks.com>
Based on original version by Michele Beltrame <mb\@italpro.net>

Available parameters:
  -a       : try to send queued messages now (qmail must be running)
  -l       : list message queues
  -L       : list local message queue
  -R       : list remote message queue
  -s       : show some statistics
  -mN      : display message number N
  -dN      : delete message number N
  -fsender : delete message from sender
  -F're'   : delete message from senders matching regular expression re
  -Stext   : delete all messages that have/contain text as Subject
  -h're'   : delete all messages with headers matching regular expression
             re (case insensitive)
  -b're'   : delete all messages with body matching regular expression
             re (case insensitive)
  -H're'   : delete all messages with headers matching regular expression
             re (case sensitive)
  -B're'   : delete all messages with body matching regular expression
             re (case sensitive)
  -t're'   : flag messages with recipients in regular expression 're' for
             earlier retry (note: this lengthens the time message can
             stay in queue)
  -D       : delete all messages in the queue (local and remote)
  -V       : print program version
  -?       : Display this help

Additional (optional) parameters:
  -c       : display colored output
  -N       : list message numbers only
           (to be used either with -l, -L or -R)

You can view/delete multiple message i.e. -d123 -m456 -d567

END_OF_HELP
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head2 version()

Display the version.

=cut

sub version {
    print "$me v$VERSION\n";
    return;
}

=head2 AUTHOR

Copyright (c) 2016 Dave Cross E<lt>dave@perlhacks.comE<gt>

Based on original version by Michele Beltrame E<lt>mb@italpro.netE<gt>

=head2 LICENCE

This program is distributed under the GNU GPL.
For more information have a look at http://www.gnu.org

=cut

1;
