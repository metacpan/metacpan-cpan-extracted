package Net::Lyskom;

use 5.8.3;

use base qw{Net::Lyskom::Object};

use strict;
use IO::Socket;
use Time::Local;
use Encode;
use Net::Lyskom::AuxItem;
use Net::Lyskom::MiscInfo;
use Net::Lyskom::Time;
use Net::Lyskom::TextStat;
use Net::Lyskom::Conference;
use Net::Lyskom::Person;
use Net::Lyskom::Util qw(:all);
use Net::Lyskom::Membership;
use Net::Lyskom::TextMapping;
use Net::Lyskom::ConfZInfo;
use Net::Lyskom::DynamicSession;
use Net::Lyskom::StaticSession;
use Net::Lyskom::Member;
use Net::Lyskom::Info;

use Carp;

use vars qw{ @error };


our $VERSION = '1.2';

=head1 NAME

Net::Lyskom - Perl module used to talk to LysKOM servers.

=head1 SYNOPSIS

  use Net::Lyskom;

  $a = Net::Lyskom->new();
  $conf = 6;

  $a->login(pers_no => 437, password => "God", invisible => 1)
    or die "Failed to log in: $a->err_string\n";

  $b = $a->send_message(7680, "Oook!");

  $b = $a->create_text(
                       subject => "Testsubject",
                       body => "A nice and tidy message body.",
                       recpt => [437],
                      );

  if ($b) {
      print "Text number $b created.\n";
  } else {
      print "Text creation failed: $a->err_string.\n";
  }

=head1 DESCRIPTION

Net::Lyskom is a module used to talk to LysKOM servers. This far
it lacks a lot of functions, but there are enough functions implemented
to program statistics robots and such.

=head2 Metoder

=over

=cut

## Variables


@error = qw(no-error
            unused
            not-implemented
            obsolete-call
            invalid-password
            string-too-long
            login-first
            login-disallowed
            conference-zero
            undefined-conference
            undefined-person
            access-denied
            permission-denied
            not-member
            no-such-text
            text-zero
            no-such-local-text
            local-text-zero
            bad-name
            index-out-of-range
            conference-exists
            person-exists
            secret-public
            letterbox
            ldb-error
            illegal-misc
            illegal-info-type
            already-recipient
            already-comment
            already-footnote
            not-recipient
            not-comment
            not-footnote
            recipient-limit
            comment-limit
            footnote-limit
            mark-limit
            not-author
            no-connect
            out-of-memory
            server-is-crazy
            client-is-crazy
            undefined-session
            regexp-error
            not-marked
            temporary-failure
            long-array
            anonymous-rejected
            illegal-aux-item
            aux-item-permission
            unknown-async
            internal-error
            feature-disabled
            message-not-sent
            invalid-membership-type);


## Methods

=item is_error($code, $err_no, $err_status)

Looks at a response from the server and decides if it is an error
message and if that is the case sets some variables in the object and
returns true.

Calls C<die()> if the response does not look as a server response at
all.

This sub is intended for internal use.

=cut

sub is_error {
    my $self = shift;
    my ($code, $err_no, $err_status) = @_;

    if ($code =~ /^=/) {
        $self->{err_no} = 0;
        $self->{err_status} = 0;
        $self->{err_string} = "";
        return 0;               # Not an error
    } elsif ($code =~ /^%%/) {
        $self->{err_no} = 4711;
        $self->{err_status} = $err_status;
        $self->{err_string} = "Protocol error!";
        return 1;               # Is an error
    } elsif ($code =~ /^%/) {
        $self->{err_no} = $err_no;
        $self->{err_status} = $err_status;
        $self->{err_string} = $error[$err_no];
        return 1;               # Is an error
    } else {
        croak "An unknown error? ($code)\n";
    }
}

sub err_no {my $s = shift; return $s->{err_no}}
sub err_status {my $s = shift; return $s->{err_status}}
sub err_string {my $s = shift; return $s->{err_string}}

=item new([options])

Creates a new Net::Lyskom object and connect to a LysKOM server. By
default it connects to the server at Lysator (I<kom.lysator.liu.se>,
port 4894). To connect to another server, use named arguments.

    $a = Net::Lyskom->new(Host => "kom.csd.uu.se", Port => 4894);

If the connection succeded, an object is returned, if not C<undef> is
returned.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my %arg = @_;

    my $host = $arg{Host} || "kom.lysator.liu.se";
    my $port = $arg{Port} || 4894;

    my $name =
      $arg{Name} ||
        $ENV{USER} ||
          $ENV{LOGNAME} ||
            ((getpwuid($<))[0]);

    $self->{refno} = 1;

    $self->{socket} = IO::Socket::INET->new(
                                            PeerAddr => $host,
                                            PeerPort => $port,
                                           )
      or croak "Can't connect to remote server: $!\n";

    $self->{socket}->print("A".holl($name)."\n");

    my $tmp = $self->{socket}->getline;
    while (!$tmp || $tmp !~ /LysKOM/) {
        $tmp = $self->{socket}->getline;
    }

    bless $self, $class;
    return $self;
}

=item getres()

Get responses and asynchronous messages from the server. The asynchronous
messages is passed to C<handle_async()>. This method is intended for
internal use, and shall normally not be used anywhere else then in
this module.

=cut

sub getres {
    my $self = shift;
    my @res;

    @res = $self->getres_sub;
    while ($res[0] =~ m/^:/) {
        $self->handle_asynch(@res);
        @res = $self->getres_sub;
    }
    return @res;
}

=item getres_sub()

Helper function to C<getres()>. Be careful and I<understand> what you are
up to before using it.

=cut

sub getres_sub {
    my $self = shift;
    my ($f, $r);
    my @res;

    $r = $self->{socket}->getline;
    while ($r) {
        if ($r =~ m|^(\d+)H(.*)$|) { # Start of a hollerith string
            my $tot_len = $1;
            my $res;
            $r = $2."\n";
        
            $res = substr $r, 0, $tot_len,"";
            while (length($res) < $tot_len) {
                $r = $self->{socket}->getline;
                debug($r);
                $res .= substr $r, 0, ($tot_len-length($res)),"";
            }
            push @res, $res;
            if ($r eq "") {
                $r = $self->{socket}->getline;
            }
            $r =~ s/^ //;
        } else {
            ($f, $r) = split " ", $r, 2;
            push @res,$f;
        }
    }
    return @res;
}

sub send {
    my $s = shift;

    $s->{socket}->print(@_);
}

=item handle_asynch()

Is automaticly called when a asynchronous message is returned from
the server. Currently this routine does nothing.

=cut

sub handle_asynch {
    my $self = shift;
    my @call = @_;

    #debug "Asynch: @call";
}

## Server calls

=item logout

Log out from LysKOM, this call does not disconnect the session, which
means you can login again without the need of calling another new.

     $a->logout();

=cut

sub logout {
    my $self = shift;

    return $self->gen_call_boolean(1);
}

=item change_conference ($conference)

Changes current conference of the session.

    $a->change_conference(4711);

=cut

sub change_conference {
    my $self = shift;
    my $conference = shift;

    return $self->gen_call_boolean(2,$conference);
}

=item change_name ($conference, $new_name)

Change name of the person or conference numbered $conference to $new_name.

    $a->change_name(46, 'Sweden (the strange land)');

=cut

sub change_name {
    my $self = shift;
    my $conference = shift;
    my $new_name = shift;

    return $self->gen_call_boolean(3, $conference, holl($new_name));
}

=item change_what_i_am_doing ($what_am_i_doing)

Tells the server what the logged-in user is doing. You are encouraged to use
this call creatively.

    $a->change_what_i_am_doing('Eating smorgasbord');

=cut

sub change_what_i_am_doing {
    my $self = shift;
    my $what_am_i_doing = shift;

    return $self->gen_call_boolean(4, holl($what_am_i_doing));
}

=item set_priv_bits($person, admin => 1, wheel => 1, statistic => 1, create_pers => 1, create_conf => 1, change_name => 1)

Set the privbits on person $person. User can specify one or more
privileges by name. Privs not specified default to false.

=cut

sub set_priv_bits {
    my $self = shift;
    my $person = shift;
    my %priv = (
                wheel => 0,
                admin => 0,
                statistic => 0,
                create_pers => 0,
                create_conf => 0,
                change_name => 0
               );
    my %arg = @_;

    foreach (keys %arg) {
        $priv{$_} = $arg{$_}
    }

    my $pstring = join "", map {$_?"1":"0"}
      (
       $priv{wheel},
       $priv{admin},
       $priv{statistic},
       $priv{create_pers},
       $priv{create_conf},
       $priv{change_name},
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      );

    return $self->gen_call_boolean(7, $person, $pstring);
}

=item set_passwd(person => $person, old_pwd => $old, new_pwd => $new)

Changes the password of $person to $new_pwd.

$old is the password of the currently logged in person. All three
arguments are required.

=cut

sub set_passwd {
    my $self = shift;
    my %arg = @_;

    return $self->gen_call_boolean(8,
                                   $arg{person},
                                   holl($arg{old_pwd}),
                                   holl($arg{new_pwd})
                                  );
}

=item delete_conf($conf)

Deletes the conference with number $conf. If $conf is a mailbox,
the corresponding user is also deleted.

    $a->delete_conf(42);

=cut

sub delete_conf {
    my $self = shift;
    my $conf = shift;

    return $self->gen_call_boolean(11, $conf);
}

=item sub_member($conf_no, $pers_no)

Removes the person $pers_no from the membership list of
conference $conf_no.

    $a->sub_member(42,4711);

=cut

sub sub_member {
    my $self = shift;
    my $conf_no = shift;
    my $pers_no = shift;

    return $self->gen_call_boolean(15, $conf_no, $pers_no);
}

=item set_presentation($conf_no, $text_no)

Set the text $text_no as presentation for $conf_no.
To remove a presentation, use $text_no = 0

    $a->set_presentation(42,4711);

=cut

sub set_presentation {
    my $self = shift;
    my $conf_no = shift;
    my $text_no = shift;

    return $self->gen_call_boolean(16, $conf_no, $text_no);
}

=item set_etc_motd($conf_no, $text_no)

Sets the messages of the day on the conference or person $conf_no to
$text_no and removes the old message.

    $a->set_etc_motd(6,1);

=cut

sub set_etc_motd {
    my $self = shift;
    my $conf_no = shift;
    my $text_no = shift;

    return $self->gen_call_boolean(17, $conf_no, $text_no);
}


=item set_supervisor($conf_no, $admin)

Set person/conference $admin as supervisor for the
conference $conf_no

=cut

sub set_supervisor {
    my $self = shift;
    my $conf_no = shift;
    my $admin = shift;

    return $self->gen_call_boolean(18, $conf_no, $admin);
}

=item set_permitted_submitters($conf_no, $perm_sub)

Set $perm_sub as permitted subscribers for $conf_no. If $perm_sub = 0,
all users are welcome to write in the conference.

=cut

sub set_permitted_submitters {
    my $self = shift;
    my $conf_no = shift;
    my $perm_sub = shift;

    return $self->gen_call_boolean(19, $conf_no, $perm_sub);
}

=item set_super_conf($conf_no, $super_conf)

Sets the conference $super_conf as super conference for $conf_no

=cut

sub set_super_conf {
    my $self = shift;
    my $conf_no = shift;
    my $super_conf = shift;

    return $self->gen_call_boolean(20, $conf_no, $super_conf);
}

=item set_garb_nice($conf_no, $nice)

Sets the garb time for the conference $conf_no to $nice days.

    $a->set_garb_nice(42,7);

=cut

sub set_garb_nice {
    my $self = shift;
    my $conf_no = shift;
    my $nice = shift;

    return $self->gen_call_boolean(22, $conf_no, $nice);
}

=item get_text(text => $text, start_char => $start, end_char => $end)

Get a text from the server, the first argument, C<text>, is the global
text number for the text to get. The retrival stars at position
C<start_char> (the first character in the text is numbered 0) and ends
at position C<end_char>.

Default is 0 for C<start_char> and 2147483647 for C<end_char>. This
means that a complete message is fetched, unless otherwise stated.

Also note that you can get an entire text, pre-split into subject and
body, via the object returned from the C<get_text_stat> method.

To get the first 100 chars from text 4711:

    my $text = $a->get_text(text => 4711, start_char => 0, end_char => 100);

=cut

sub get_text {
    my $self = shift;
    my %arg = @_;
    my @res;

    unless ($arg{text}) {
        croak "get_text() called with no text number argument";
    }
    $arg{start_char} = 0 unless $arg{start_char};
    $arg{end_char} = 2147483647 unless $arg{end_char};

    return $self->gen_call_scalar(25, $arg{text}, $arg{start_char}, $arg{end_char});
}

=item delete_text($text)

Deletes the text with the global text number $text from the database.

=cut

sub delete_text {
    my $self = shift;
    my $text = shift;

    return $self->gen_call_boolean(29, $text);
}

=item add_recipient(text_no => $text, conf_no => $conf, type => $type)

Add a recipient to a text. $type can be one of "recpt", "cc" or "bcc". 
If not given (or if set to something other than one of those three
strings) it defaults to "recpt". C<text_no> and C<conf_no> are
required.

=cut

sub add_recipient {
    my $self = shift;
    my %arg = @_;

    if ($arg{type} eq "bcc") {
        $arg{type} = 15
    } elsif ($arg{type} eq "cc") {
        $arg{type} = 1
    } else {
        $arg{type} = 0
    }
    return $self->gen_call_boolean(30,$arg{text_no},$arg{conf_no},$arg{type});
}

=item sub_recipient($text_no, $conf_no)

Remove a recipient from a text.

=cut

sub sub_recipient {
    my $self = shift;
    my $textno = shift;
    my $confno = shift;

    return $self->gen_call_boolean(31, $textno, $confno);
}

=item add_comment($text_no, $comment_to)

Add a comment link between the text comment-to and the text text-no
(text-no becomes a comment to the text comment-to). This call is used
to add comment links after a text has been created.

=cut

sub add_comment {
    my $self = shift;
    my $textno = shift;
    my $commentto = shift;

    return $self->gen_call_boolean(32, $textno, $commentto);
}

=item get_time

Ask the server for the current time. Returns a L<Net::Lyskom::Time> object.

=cut

sub get_time {
    my $self = shift;
    my @res;

    @res = $self->server_call(35);
    if ($self->is_error(@res)) {
        return undef;
    } else {
        shift @res;    # Remove return code
        return Net::Lyskom::Time->new_from_stream(\@res);
    }
}

=item set_unread($conf_no, $no_of_unread)

Only read the $no_of_unread texts in the conference $conf_no.

=cut

sub set_unread {
    my $self = shift;
    my $conf_no = shift;
    my $no_of_unread = shift;

    return $self->gen_call_boolean(40, $conf_no, $no_of_unread);
}

=item set_motd_of_lyskom($text_no)

Sets the login message of LysKOM, can only be executed by a privileged person,
with the proper privileges enabled.

=cut

sub set_motd_of_lyskom {
    my $self = shift;
    my $text_no = shift;

    return $self->gen_call_boolean(41, $text_no);
}

=item enable($level)

Sets the security level for the current session to $level.

=cut

sub enable {
    my $self = shift;
    my $level = shift;

    return $self->gen_call_boolean(42, $level);
}

=item sync_kom

This call instructs the LysKOM server to make sure the permanent copy of its
databas is current. This call is privileged in most implementations.

    $a->sync_kom();

=cut

sub sync_kom {
    my $self = shift;

    return $self->gen_call_boolean(43);
}

=item shutdown_kom($exit_val)

Instructs the server to save all data and shut down. The variable $exit_val is
currently not used.

=cut

sub shutdown_kom {
    my $self = shift;
    my $exit_val = shift;

    return $self->gen_call_boolean(44, $exit_val);
}

=item get_person_stat($persno)

Get status for a person from the server. Returns a L<Net::Lyskom::Person>
object.

=cut

sub get_person_stat {
    my $self = shift;
    my $persno = shift;
    my @res;

    @res = $self->server_call(49, $persno);
    if ($self->is_error(@res)) {
        return 0;
    } else {
        shift @res;             # Remove return code
        return Net::Lyskom::Person->new_from_stream(\@res);
    }
}

=item get_unread_confs($pers_no)

Get a list of conference numbers in which the person $pers_no
may have unread texts.

    my @unread_confs = $a->get_unread_confs(7);

=cut

sub get_unread_confs {
    my $self = shift;
    my $pers_no = shift;
    my @res;

    @res = $self->server_call(52, $pers_no);
    if ($self->is_error(@res)) {
        return ();
    } else {
        shift @res;    # Remove return code
        return parse_array_stream(sub{shift @{$_[0]}},\@res);
    }

}

=item send_message($recipient, $message)

Sends the message $message to all members of $recipient that is
currently logged in. If $recipient is 0, the message is sent to all
sessions that are logged in.

=cut

sub send_message {
    my $self = shift;
    my $recipient = shift;
    my $message = shift;

    return $self->gen_call_boolean(53, $recipient, holl($message));
}

=item who_am_i

Get the session number of the current session.

    my $session_number = $a->who_am_i();

=cut

sub who_am_i {
    my $self = shift;

    return $self->gen_call_scalar(56);
}

=item get_last_text($time)

$time should be given a as a unix time_t (that is, as the number of
seconds since 00:00:00 01 Jan 1970 UCT).

=cut

sub get_last_text {
    my $self = shift;
    my $time = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime($time);
    return $self->gen_call_scalar(58,$sec,$min,$hour,$mday,$mon,$year,$wday,
                                  $yday,($isdst?1:0));
}

=item find_next_text_no($text_no)

Returns the global number of the readable text that follows the text
C<$text_no>.

=cut

sub find_next_text_no {
    my $self = shift;
    my $start = shift;

    return $self->gen_call_scalar(60, $start);
}

=item find_previous_text_no($text_no)

Returns the global number of the readable text that precedes the text
C<$text_no>.

=cut

sub find_previous_text_no {
    my $self = shift;
    my $start = shift;

    return $self->gen_call_scalar(61, $start);
}

=item login(pers_no => $pers, password => $pwd, invisible => $invis)

Log in to LysKOM. $persno is the number of the person which is to be
logged in. $pwd is the password of that person. If $invis is true, a
secret login is done (the session is not visible in who-is-on-lists et al.)

=cut

sub login {
    my $self = shift;
    my %arg = @_;

    return $self->gen_call_boolean(62,
                                   $arg{pers_no},
                                   holl($arg{password}),
                                   ($arg{invisible})?1:0);
}

=item set_client_version($client_name, $client_version)

Tells the server that this is the software $client_name and the
version $client_version.

    $a->set_client_version('My-cool-software','0.001 beta');

=cut

sub set_client_version {
    my $self = shift;
    my $client_name = shift;
    my $client_version = shift;

    return $self->gen_call_boolean(69, holl($client_name), holl($client_version));
}

=item get_client_name($session)

Ask the server for the name of the client software logged in with
session number $session.

=cut

sub get_client_name {
    my $self = shift;
    my $session = shift;

    return $self->gen_call_scalar(70, $session);
}

=item get_client_version($session)

Ask the server for the version of the client software logged in with
session number $session.

=cut

sub get_client_version {
    my $self = shift;
    my $session = shift;

    return $self->gen_call_scalar(71, $session);
}

=item get_version_info

Ask the server for the version info of the server software itself. 
Returns a three-element array with the protocol version, server
software name and server software version.

=cut

sub get_version_info {
    my $self = shift;
    my @res;

    @res = $self->server_call(75);
    if ($self->is_error(@res)) {
        return ();
    } else {
        shift @res;    # Remove return code
        return @res[0..2];
    }
}

=item lookup_z_name(name => $name, want_pers => $wp, want_conf => $wc)

Lookup the name $name in the server, returns a list of all matching
conferences and/or persons, in the form of L<Net::Lyskom::ConfZInfo>
objects. The server database is searched with standard kom name
expansion.

If $want_pers is true, the server includes persons in the answer, if
$want_conf is true, conferences is included.

=cut 

sub lookup_z_name {
    my $self = shift;
    my @res;
    my %arg = @_;

    @res = $self->server_call(76,
                              holl($arg{name}),
                              ($arg{want_pers}?1:0),
                              ($arg{want_conf}?1:0));
    if ($self->is_error(@res)) {
        return 0;
    } else {
        shift @res;             # Remove return code
        return parse_array_stream(sub{Net::Lyskom::ConfZInfo->new_from_stream(@_)},\@res)
    }
}

=item re_z_lookup(name => $name, want_pers => $wp, want_conf => $wc)

Regexp lookup of the name $name in the server, returns a list of all
matching conferences and/or persons, in the form of
L<Net::Lyskom::ConfZInfo> objects.

If $want_pers is true, the server includes persons in the answer, if
$want_conf is true, conferences is included.

=cut 

sub re_z_lookup {
    my $self = shift;
    my @res;
    my %arg = @_;

    @res = $self->server_call(74,
                              holl($arg{name}),
                              ($arg{want_pers}?1:0),
                              ($arg{want_conf}?1:0));
    if ($self->is_error(@res)) {
        return 0;
    } else {
        shift @res;             # Remove return code
        return parse_array_stream(sub{Net::Lyskom::ConfZInfo->new_from_stream(@_)},\@res)
    }
}

=item user_active

Tells the server that the user is active.

=cut

sub user_active {
    my $self = shift;

    return $self->gen_call_boolean(82);
}

=item who_is_on_dynamic(want_visible => $wv, want_invisible => $wi, active_last => $al)

Returns a list of L<Net::Lyskom::DynamicSession> objects. If
C<want_visible> is true, the visible users are included in the answer.
If C<want_invisible> is true, invisible users are included.

Only the users active the last C<active_last> seconds are included in
the answer. If C<active_last> is zero, all users (who match the
visibility limits) are returned.

If not given, C<want_visible> defaults to true, C<want_invisible>
defaults to false and C<active_last> defaults to 0.

=cut

sub who_is_on_dynamic {
  my $self = shift;
  my %arg = @_;
  my @res;

  $arg{want_visible} = 1 unless $arg{want_visible};
  $arg{want_invisible} = 0 unless $arg{want_invisible};
  $arg{active_last} = 0 unless $arg{active_last};

  @res = $self->server_call(83,
                            ($arg{want_visible}?1:0),
                            ($arg{want_invisible}?1:0),
                            $arg{active_last});
  if ($self->is_error(@res)) {
    return 0;
  } else {
    shift @res;         # Remove return code
    return parse_array_stream(sub{Net::Lyskom::DynamicSession->new_from_stream(@_)},\@res)
  }
}

=item get_static_session_info($session_no)

Returns a C<Net::Lyskom::StaticSession> object holding details on the
specified session.

=cut

sub get_static_session_info {
    my $self = shift;
    my $session = shift;
    my @res;

    @res = $self->server_call(84, $session);
    if ($self->is_error(@res)) {
        return undef;
    } else {
        shift @res;
        return Net::Lyskom::StaticSession->new_from_stream(\@res);
    }
}


=item create_text(subject => "This is the subject", body => "This is the text body.", recpt => [6], cc_recpt => [437], bcc_recpt => [19, 23], comm_to => [4711], footn_to => [11147], aux => [@aux_obj_list])

Creates texts. Takes arguments as indicated in the synopsis just above
(that is, as a hash with zero or more of the given keys and strings or
arrayrefs as values, as appropriate). Any of the arguments can be left
out, but a text without at least one recipient is not very useful (nor
is one with neither subject nor body). The C<aux> argument should be a
reference to a list of L<Net::Lyskom::AuxInfo> objects.

If the C<aux> list is not given, or given but not containing a
content-type item, an item with content type
C<text/x-kom-basic;charset=utf-8> will be added. In this case, the
subject and body will also be converted from Perl's internal encoding
to UTF-8 before being sent out over the network. 

Example:

  $k->create_text(
                  subject => "Test",
                  body => "Body",
                  recpt => [437],
                  aux => [
                          Net::Lyskom::AuxItem->new(
                                                    tag => content_type,
                                                    data => "text/plain"
                                                   )
                         ]);


=cut

sub create_text {
    my $self = shift;
    my %arg = @_;
    my @misc;
    my $misc_count = 0;
    my @aux;
    my $aux_count = 0;
    my @call;

    if (
        !$arg{aux}
        or scalar(grep {$_->tag == 1} @{$arg{aux}})==0
       ) {
        # No Aux-items, or at least no Content-Type
        push @{$arg{aux}}, Net::Lyskom::AuxItem->new(
                                                     tag => 'content_type',
                                                     data => 'text/x-kom-basic;charset=utf-8'
                                                    );
        $arg{subject} = encode_utf8($arg{subject});
        $arg{body} = encode_utf8($arg{body});
    }

    push @call, holl($arg{subject}."\n".$arg{body});
    if ($arg{recpt}) {
        foreach (@{$arg{recpt}}) {
            push @misc, 0, $_;
            $misc_count++;
        }
    }
    if ($arg{cc_recpt}) {
        foreach (@{$arg{cc_recpt}}) {
            push @misc, 1, $_;
            $misc_count++;
        }
    }
    if ($arg{bcc_recpt}) {
        foreach (@{$arg{bcc_recpt}}) {
            push @misc, 15, $_;
            $misc_count++;
        }
    }
    if ($arg{comm_to}) {
        foreach (@{$arg{comm_to}}) {
            push @misc, 2, $_;
            $misc_count++;
        }
    }
    if ($arg{footn_to}) {
        foreach (@{$arg{footn_to}}) {
            push @misc, 4, $_;
            $misc_count++;
        }
    }
    push @call, $misc_count, '{', @misc, '}';

    if ($arg{aux}) {
        foreach (@{$arg{aux}}) {
            push @aux, $_->to_server;
            $aux_count++;
        }
    }
    push @call, $aux_count, '{', @aux, '}';

    return $self->gen_call_scalar(86, @call);
}

=item get_text_stat($textno)

Fetch the status for a text from the server. Returns a
L<Net::Lyskom::TextStat> object.

=cut

sub get_text_stat {
    my $self = shift;
    my $textno = shift;
    my @res;

    @res = $self->server_call(90, $textno);
    if ($self->is_error(@res)) {
        return 0;
    } else {
        shift @res;             # Remove return code
        return Net::Lyskom::TextStat->new_from_stream($self, $textno, \@res);
    }
}

=item get_conf_stat(@conf_no)

Get status for one or more conferences from the server. Returns a
L<Net::Lyskom::Conference> object in scalar context and a list of such
objects in list context.

=cut

sub get_conf_stat {
    my $self = shift;
    my @confno = @_;
    my @res;
    my @tmp;

    @tmp = $self->server_call([map {[91,$_]} @confno]);
    foreach (@tmp) {
        if ($self->is_error(@{$_})) {
            push @res,undef;
        } else {
            shift @{$_};                # Remove return code
            push @res, Net::Lyskom::Conference->new_from_stream($_);
        }
    }

    if (wantarray) {
        return @res;
    } else {
        return $res[0];
    }
}

=item modify_text_info( text => $text, delete => $delete_array_ref, add => $add_array_ref)

Add and/or delete aux items to/from a text. C<delete> should be a
reference to an array of aux_info order numbers to remove from the
text. C<add> should be a reference to an array of
C<Net::Lyskom::AuxInfo> objects to add to the text.

=cut

sub modify_text_info {
    my $self = shift;
    my %arg = @_;
    my @aux;
    my $aux_count = 0;
    my @del;
    my $del_count = 0;
    my @call;

    push @call, 92;
    push @call, $arg{text};

    if ($arg{delete}) {
        foreach (@{$arg{delete}}) {
            push @del, $_;
            $del_count++;
        }
    }
    push @call, $del_count, '{', @del, '}';

    if ($arg{add}) {
        foreach (@{$arg{add}}) {
            push @aux, $_->to_server;
            $aux_count++;
        }
    }
    push @call, $aux_count, '{', @aux, '}';

    return $self->gen_call_boolean(@call);
}

=item butt_ugly_fast_reply($text, $data)

Adds a fast-reply auxitem with the contents $data to the text $text. 
Now implemented in terms of C<modify_text_info>, name retained for
backwards compatibility.

=cut

sub butt_ugly_fast_reply {      # Less ugly re-implementation
    my $self = shift;
    my ($text, $data) = @_;

    $self->modify_text_info(
                            text => $text,
                            add => [
                                    Net::Lyskom::AuxItem->new(
                                                              tag => "fast_reply",
                                                              data => $data
                                                             )
                                   ]
                           );
}

=item query_predefined_aux_items 

Ask the server which predefined aux items that exists in the server.

=cut

sub query_predefined_aux_items {
    my $self = shift;
    my @res;

    @res = $self->server_call(96);
    if ($self->is_error(@res)) {
        return ();
    } else {
        shift @res;
        return parse_array_stream(sub{shift @{$_[0]}},\@res);
    }
}

=item get_membership(person => $p, first => $f, no_of_confs => $no, want_read_texts => $w)

Get a membership list for C<person>, in the form of a list of
L<Net::Lyskom::Membership> objects. Start at position C<first> in the
membership list and get C<no_of_confs> conferences. If
C<want_read_texts> is true the server will also send information about
read texts in the conference.

=cut

sub get_membership {
    my $self = shift;
    my %arg = @_;
    my @res;

    $arg{first} = 0 unless $arg{first};
    $arg{no_of_confs} = 10 unless $arg{no_of_confs};
    $arg{want_read_texts} = 1 unless $arg{want_read_texts};

    @res = $self->server_call(99,
                              $arg{person},
                              $arg{first},
                              $arg{no_of_confs},
                              ($arg{want_read_texts})?1:0);
    if ($self->is_error(@res)) {
        return ();
    } else {
        shift @res;    # Remove return code
        return parse_array_stream(sub{Net::Lyskom::Membership->new_from_stream(@_)},\@res);
    }
}

=item local_to_global(conf => $conf, first => $first, number => $no)

Given a local text number and an integer smaller than 256, returns a
L<Net::Lyskom::TextMapping> object detailing the mapping between the
local and global text numbers of up to that many texts. All arguments
are required.

=cut

sub local_to_global {
    my $self = shift;
    my %arg = @_;
    my @res;

    @res = $self->server_call(103, $arg{conf}, $arg{first}, $arg{number});
    if ($self->is_error(@res)) {
        return ();
    } else {
        shift @res;             # Remove return code
        return Net::Lyskom::TextMapping->new_from_stream(\@res);
    }
}

=item map_created_texts(pers_no => $pers, first => $first, number => $no)

Given a local text number and an integer smaller than 256, returns a
L<Net::Lyskom::TextMapping> object detailing the mapping between texts
written by C<pers_no> and global text numbers of up to that many
texts. All arguments are required.

=cut

sub map_created_texts {
    my $self = shift;
    my %arg = @_;
    my @res;

    @res = $self->server_call(104, $arg{pers_no}, $arg{first}, $arg{number});
    if ($self->is_error(@res)) {
        return ();
    } else {
        shift @res;             # Remove return code
        return Net::Lyskom::TextMapping->new_from_stream(\@res);
    }
}

=item set_membership_type(pers => $p, conf => $c, invitation => $i, passive => $pa, secret => $s)

Set the membership flags for user C<pers> in conference C<conf>.

=cut

sub set_membership_type {
    my $self = shift;
    my %arg = @_;
    my $str = sprintf "%s%s%s00000",
      ($arg{invitation}?"1":"0"),
        ($arg{passive}?"1":"0"),
          ($arg{secret}?"1":"0");

    return $self->gen_call_boolean(102, $arg{pers}, $arg{conf}, $str);
}

=item get_members(conf => $conf_no, first => $first_index, $count => $no_of_members)

=cut

sub get_members {
    my $self = shift;
    my %arg = @_;
    my @res;

    @res = $self->server_call(101, $arg{conf}, $arg{first}, $arg{count});
    if ($self->is_error(@res)) {
        return undef
    } else {
        shift @res;
        return parse_array_stream(sub{Net::Lyskom::Member->new_from_stream(@_)}, \@res)
    }
}

=item add_member(conf => $conf, pers => $pers_no, priority => $prio, where => $where, invitation => $invite, passive => $pass, secret => $secret)

Add person number C<pers> as a member of conference number C<conf>, at
priority C<priority> and at position C<where>. C<invitation>,
C<passive> and C<secret> specify the membership type.

=cut

sub add_member {
    my $self = shift;
    my %arg = @_;

    my $type = sprintf "%s%s%s00000",
      ($arg{invitation}?"1":"0"),
        ($arg{passive}?"1":"0"),
          ($arg{secret}?"1":"0");
    return $self->gen_call_boolean(100, $arg{conf}, $arg{pers},
                                   $arg{priority}, $arg{where}, $type);
}

=item query_read_texts($pers, $conf)

Return information on which texts person $pers has read in conference
$conf. Returns an C<Net::Lyskom::Membership> object.

=cut

sub query_read_texts {
    my $self = shift;
    my ($pers, $conf) = @_;

    my @res = $self->server_call(98,$pers,$conf);
    if ($self->is_error(@res)) {
        return undef
    } else {
        shift @res;
        return Net::Lyskom::Membership->new_from_stream(\@res)
    }
}

=item set_expire($conf, $expire)

Set the garb-nice value for conference C<$conf> to C<$expire>.

=cut

sub set_expire {
    my $self = shift;
    my ($conf, $expire) = @_;

    return $self->gen_call_boolean(97, $conf, $expire);
}

=item mark_text($text, $mark)

Sets a mark of (numerical) type C<$mark> on text number C<$text>.

=cut

sub mark_text {
    my $self = shift;
    my ($text, $mark) = @_;

    return $self->gen_call_boolean(72, $text, $mark);
}

=item get_marks

Returns an array of (text_no, mark_type) pairs, showing the texts the
current user has marked.

=cut

sub get_marks {
    my $self = shift;

    my @res = $self->server_call(23);
    if ($self->is_error(@res)) {
        return undef;
    } else {
        shift @res;
        return parse_array_stream(sub{[splice @{$_[0]},0,2]},\@res);
    }
}

=item unmark_text($text)

Remove any marks on the specified text.

=cut

sub unmark_text {
    my $self = shift;
    my $text = shift;

    return $self->gen_call_boolean(73, $text);
}

=item set_last_read($conf,$local_no)

Tell the server that the current user has read everything up to local
number C<$local_no> in conference number C<$conf>.

=cut

sub set_last_read {
    my $self = shift;
    my ($conf, $local_no) = @_;

    return $self->gen_call_boolean(77, $conf, $local_no)
}

=item set_conf_type(conf => $conf, rd_prot => $rp, original => $orig, secret => $sec, letterbox => $letter, allow_anonymous => $anon, forbid_secret => $nosecret)

Set the type of conference C<conf>. C<conf> is required, the rest
default to false if not specified.

=cut

sub set_conf_type {
    my $self = shift;
    my %arg = @_;

    die unless exists($arg{conf});
    $arg{rd_prot}         = 0 unless $arg{rd_prot};
    $arg{original}        = 0 unless $arg{original};
    $arg{secret}          = 0 unless $arg{secret};
    $arg{letterbox}       = 0 unless $arg{letterbox};
    $arg{allow_anonymous} = 0 unless $arg{allow_anonymous};
    $arg{forbid_secret}   = 0 unless $arg{forbid_secret};

    my $type = sprintf "%s%s%s%s%s%s000",
      ($arg{rd_prot}?"1":"0"),
        ($arg{original}?"1":"0"),
          ($arg{secret}?"1":"0"),
            ($arg{letterbox}?"1":"0"),
              ($arg{allow_anonymous}?"1":"0"),
                ($arg{forbid_secret}?"1":"0");
    return $self->gen_call_boolean(21, $arg{conf}, $type);

}

=item mark_as_read($conf, @texts)

Marks the texts specified by the local text numbers in C<@texts> as
read in the conference C<$conf>.

=cut

sub mark_as_read {
    my $self = shift;
    my $conf = shift;
    my @texts = @_;

    return $self->gen_call_boolean(27, $conf, scalar @texts, '{', @texts, '}');
}

=item sub_comment($text, $comment)

Removes C<$text> from C<$comment>s list of comments.

=cut

sub sub_comment {
    my $self = shift;
    my ($text, $comment) = @_;

    return $self->gen_call_boolean(33, $text, $comment);
}

=item add_footnote($text, $footnote_to)

Makes text number C<$text> be a footnote to text number C<$footnote_to>.

=cut

sub add_footnote {
    my $self = shift;
    my ($text, $footnote_to) = @_;

    return $self->gen_call_boolean(37, $text, $footnote_to);
}

=item sub_footnote($text, $footnote_to)

Makes text number C<$text> not be a footnote to text number C<$footnote_to>.

=cut

sub sub_footnote {
    my $self = shift;
    my ($text, $footnote_to) = @_;

    return $self->gen_call_boolean(38, $text, $footnote_to);
}

=item disconnect($session)

Make session number C<$session> lose its connection with the server,
given sufficient privilege. Session zero is always interpreted as the
current session.

=cut

sub disconnect {
    my $self = shift;
    my $session = shift;

    return $self->gen_call_boolean(55, $session);
}

=item set_user_area($pers_no, $text_no)

Make text number C<$text_no> be the user area for user number C<$pers_no>.

=cut

sub set_user_area {
    my $self = shift;
    my ($pers, $text) = @_;

    return $self->gen_call_boolean(57, $pers, $text);
}

=item get_uconf_stat($conf)

Get a subset of all information for conference number C<$conf>. 
Returns a L<Net::Lyskom::Conference> object with only some fields
filled.

=cut

sub get_uconf_stat {
    my $self = shift;
    my @confno = @_;
    my @res;
    my @tmp;

    @tmp = $self->server_call([map {[78,$_]} @confno]);
    foreach (@tmp) {
        if ($self->is_error(@{$_})) {
            push @res,undef;
        } else {
            shift @{$_};                # Remove return code
            push @res, Net::Lyskom::Conference->new_from_ustream($_);
        }
    }

    if (wantarray) {
        return @res;
    } else {
        return $res[0];
    }
}

=item set_info(conf_pres_conf => $cpc, pers_pres_conf => $ppc, motd_conf => $mc, kom_news_conf => $knc, motd_of_lyskom => $mol)

Sets server information.

=cut

sub set_info {
    my $self = shift;
    my %arg = @_;

    $arg{conf_pres_conf} = 0 unless $arg{conf_pres_conf};
    $arg{pers_pres_conf} = 0 unless $arg{pers_pres_conf};
    $arg{motd_conf} = 0 unless $arg{motd_conf};
    $arg{kom_news_conf} = 0 unless $arg{kom_news_conf};
    $arg{motd_of_lyskom} = 0 unless $arg{motd_of_lyskom};

    return $self->gen_call_boolean(79, 0, # The zero must be there, see prot-a
                                   $arg{conf_pres_conf},
                                   $arg{pers_pres_conf},
                                   $arg{motd_conf},
                                   $arg{kom_news_conf},
                                   $arg{motd_of_lyskom}
                                  );
}

=item accept_async(@call_numbers)

Tell the server to send the asynchronous calls with the numbers
specified in C<@call_numbers>.

=cut

sub accept_async {
    my $self = shift;

    return $self->gen_call_boolean(80, scalar @_, '{', @_, '}');
}

=item query_async

Ask server which asynchronous calls are turned on for this session. 
Returns a list of integers.

=cut

sub query_async {
    my $self = shift;

    my @res = $self->server_call(81);
    if ($self->is_error(@res)) {
        return undef
    } else {
        return parse_array_stream(sub{shift @{$_[0]}},\@res);
    }
}

=item get_collate_table

Get the active collate table from the server.

=cut

sub get_collate_table {
    my $self = shift;

    return $self->gen_call_scalar(85);
}

=item create_anonymous_text(...arguments...)

Exactly the same as C<create_text>, except that it uses the call to
create the text anonymously.

=cut

sub create_anonymous_text {
    my $self = shift;
    my %arg = @_;
    my @misc;
    my $misc_count = 0;
    my @aux;
    my $aux_count = 0;
    my @call;

    push @call, holl($arg{subject}."\n".$arg{body});
    if ($arg{recpt}) {
        foreach (@{$arg{recpt}}) {
            push @misc, 0, $_;
            $misc_count++;
        }
    }
    if ($arg{cc_recpt}) {
        foreach (@{$arg{cc_recpt}}) {
            push @misc, 1, $_;
            $misc_count++;
        }
    }
    if ($arg{bcc_recpt}) {
        foreach (@{$arg{bcc_recpt}}) {
            push @misc, 15, $_;
            $misc_count++;
        }
    }
    if ($arg{comm_to}) {
        foreach (@{$arg{comm_to}}) {
            push @misc, 2, $_;
            $misc_count++;
        }
    }
    if ($arg{footn_to}) {
        foreach (@{$arg{footn_to}}) {
            push @misc, 4, $_;
            $misc_count++;
        }
    }
    push @call, $misc_count, '{', @misc, '}';

    if ($arg{aux}) {
        foreach (@{$arg{aux}}) {
            push @aux, $_->to_server;
            $aux_count++;
        }
    }
    push @call, $aux_count, '{', @aux, '}';

    return $self->gen_call_scalar(87, @call);
}

=item create_conf(name => $name, rd_prot => $rp, original => $orig, secret => $sec, letterbox => $letter, allow_anonymous => $anon, forbid_secret => $nosecret, aux => $aux_array_ref)

Create a conference.

=cut

sub create_conf {
    my $self = shift;
    my %arg = @_;

    croak "Tried to create conference with no name" unless $arg{name};
    $arg{rd_prot}         = 0 unless $arg{rd_prot};
    $arg{original}        = 0 unless $arg{original};
    $arg{secret}          = 0 unless $arg{secret};
    $arg{letterbox}       = 0 unless $arg{letterbox};
    $arg{allow_anonymous} = 0 unless $arg{allow_anonymous};
    $arg{forbid_secret}   = 0 unless $arg{forbid_secret};
    $arg{aux} = [] unless $arg{aux};

    my $type = sprintf "%s%s%s%s%s%s000",
      ($arg{rd_prot}?"1":"0"),
        ($arg{original}?"1":"0"),
          ($arg{secret}?"1":"0"),
            ($arg{letterbox}?"1":"0"),
              ($arg{allow_anonymous}?"1":"0"),
                ($arg{forbid_secret}?"1":"0");

    return $self->gen_call_scalar(88,
                                  holl($arg{name}),
                                  $type,
                                  scalar @{$arg{aux}},
                                  '{',
                                  map ({$_ and $_->to_server} @{$arg{aux}}),
                                  '}'
                                 );
}

=item create_person(name => $name, password => $pwd, unread_is_secret => $uis, aux => $aux_array_ref)

Create a person.

=cut

sub create_person {
    my $self = shift;
    my %arg = @_;

    croak "Tried to create person without name" unless $arg{name};
    croak "Tried to create person without password" unless $arg{password};
    $arg{unread_is_secret} = 0 unless $arg{unread_is_secret};
    $arg{aux} = [] unless $arg{aux};
    my $type = sprintf "%s0000000", ($arg{unread_is_secret}?"1":"0");

    return $self->gen_call_scalar(89,
                                  holl($arg{name}),
                                  holl($arg{password}),
                                  $type,
                                  scalar @{$arg{aux}},
                                  '{',
                                  map ({$_ and $_->to_server} @{$arg{aux}}),
                                  '}'
                                 );
}

=item modify_conf_info(conf => $conf, delete => $del_array_ref, add => $add_array_ref)

Delete and/or add aux items to a conference. C<$del_array_ref> is a
reference to an array of aux item numbers to delete. C<$add_array_ref>
is a reference to an array of aux items to add.

=cut

sub modify_conf_info {
    my $self = shift;
    my %arg = @_;

    $arg{delete} = [] unless $arg{delete};
    $arg{add} = [] unless $arg{add};

    return undef unless $arg{conf};
    return $self->gen_call_boolean(93, $arg{conf},
                                   scalar @{$arg{delete}},
                                   '{',@{$arg{delete}},'}',
                                   scalar @{$arg{add}},
                                   '{', map {$_->to_server} @{$arg{add}},'}'
                                   );
}

=item modify_system_info(delete => $del_array_ref, add => $add_array_ref)

Add and/or delete aux items for the server itself. Similar arguments
as above.

=cut

sub modify_system_info {
    my $self = shift;
    my %arg = @_;

    $arg{delete} = [] unless $arg{delete};
    $arg{add} = [] unless $arg{add};

    return $self->gen_call_boolean(95,
                                   scalar @{$arg{delete}},
                                   '{',@{$arg{delete}},'}',
                                   scalar @{$arg{add}},
                                   '{', map {$_->to_server} @{$arg{add}},'}'
                                   );

}

=item set_keep_commented($conf, $keep)

Set the C<keep_commented> field for conference number C<$conf> to C<$keep>.

=cut

sub set_keep_commented {
    my $self = shift;
    my ($conf, $keep) = @_;

    return $self->gen_call_boolean(105, $conf, $keep);
}

=item set_pers_flags(person => $pers, unread_is_secret => $uis)

Set the personal flags for person number C<person>. At the moment
there is only one such flag, but this method uses the many-args
calling convention for ease of future expansion.

=cut

sub set_pers_flags {
    my $self = shift;
    my %arg = @_;
    my $type = sprintf "%s0000000", ($arg{unread_is_secret}?"1":"0");

    return $self->gen_call_boolean(106, $arg{person}, $type);
}

=item get_info

Get the server info. Returns a C<Net::Lyskom::Info> object.

=cut

sub get_info {
    my $self = shift;

    my @res = $self->server_call(94);
    if ($self->is_error(@res)) {
        return undef;
    } else {
        return Net::Lyskom::Info->new_from_stream(\@res);
    }
}

=back

=cut

# Return something true
1;

__END__

=head1 AUTHORS

=item Calle Dybedahl <calle@lysator.liu.se>

=item Erik S-O Johansson <fl@erp.nu>

=item Hans Persson <unicorn@lysator.liu.se>

=head1 SEE ALSO

L<Net::Lyskom::AuxItem>, L<Net::Lyskom::ConfZInfo>, L<Net::Lyskom::Conference>,
L<Net::Lyskom::Membership>, L<Net::Lyskom::Object>, L<Net::Lyskom::Person>,
L<Net::Lyskom::TextMapping>, L<Net::Lyskom::Time>, L<Net::Lyskom::Util>
