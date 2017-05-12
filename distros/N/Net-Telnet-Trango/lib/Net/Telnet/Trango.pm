package Net::Telnet::Trango;

# $RedRiver: Trango.pm,v 1.60 2009/07/31 21:46:07 andrew Exp $
use strict;
use warnings;
use base 'Net::Telnet';

=pod

=head1 NAME

Net::Telnet::Trango
- Perl extension for accessing the Trango telnet interface

=head1 SYNOPSIS

  use Net::Telnet::Trango;
  my $t = new Net::Telnet::Trango ( Timeout => 5 );

  $t->open( Host => $ap ) or die "Error connecting: $!";

  $t->login('password') or die "Couldn't log in: $!";

  # Do whatever

  $t->exit;
  $t->close;

=head1 DESCRIPTION

Perl access to the telnet interface on Trango APs and SUs.

A handy feature is that it will parse the output from certain commands that is
in the format "[key1] value1 [key2] value2" and put those in a hashref that is
returned.  This makes using the output from things like sysinfo very easy to
do.

=head2 EXPORT

None

=head1 METHODS

=cut

our $VERSION = '0.05';

my $EMPTY = q{};
my $SPACE = q{ };

=pod

=head2 B<new> - Creates a new Net::Telnet::Trango object.

    new([Options from Net::Telnet,]
        [Decode => 0,]);

Same as new from L<Net::Telnet> but sets the default Trango Prompt: 
'/[\$#]>\s*\Z/'

It also takes an optional parameter 'Decode'.  If not defined it
defaults to 1, if it is set to 0, it will not decode the output and
instead return a reference to an array of the lines that were returned 
from the command.

=cut

sub new {
    my $class = shift;

    my %args = ();
    if ( @_ == 1 ) {
        $args{'Host'} = shift;
    }
    else {
        %args = @_;
    }

    $args{'Prompt'} ||= '/[\$#]>\s*\r?\n?$/';

    my $decode = $args{'Decode'};
    delete $args{'Decode'};

    my $self = $class->SUPER::new(%args);
    bless $self if ref $self;

    $args{Decode}       = defined $decode ? $decode : 1;
    $args{is_connected} = 0;
    $args{logged_in}    = 0;

    *$self->{net_telnet_trango} = \%args;

    return $self;
}

#  _password <new password> <new password>
#  ? [command]
#  apsearch <secs> <ch#> <h|v> [<ch#> <h|v>]...
#  arp -bcast <on|off>
#  bcastscant <all|suid> <ch#> <h|v> [<ch#> <h|v> ...
#  bye
#  cf2cf ap [default|<size>]
#  date
#  date <month> <day> <year>
#  freq scantable
#  freq channeltable
#  freq writescan [<ch#> <h|v>]
#  freq writechannel [<ch#> <freq>] ...
#  freq <ch #> <h|v>
#  help [command]
#  heater [<on temp> <off temp>]
#  ipconfig [<new ip> <new subnet mask> <new gateway>]
#  linktest <suid> [<pkt len, bytes> [<# of pkts> [<# of cycle>]]]
#  log [<# of entries, 1..179>]
#  log <sum> <# of entries, 1..179>
#  logout
#  opmode [ap [y]]
#  password
#  ping <ip addr>
#  polar <h|v>
#  power <setism|setunii> <max|min|<dBm>>
#  reboot
#  restart
#  remarks [<str>]
#  rfrxthreshold [<ism|unii> <-90|-85|-80|-75|-70|-65>]
#  rfrxth [<ism|unii> <-90|-85|-80|-75|-70|-65>]
#  sysinfo
#  set suid <id>
#  set apid <id>
#  set baseid <id>
#  set defaultopmode [<ap|su> <min,0..10>]
#  set defaultopmode off
#  set snmpcomm [<read | write | trap (id or setall)> <str>]
#  set mir [on|off]
#  set mir threshold <kbps>
#  set rssitarget [<ism|unii> <dBm>]
#  set serviceradius [<ism | unii> <miles>]
#  ssrssi <ch #> <h|v>
#  su [<suid>|all]
#  su changechannel <all|suid> <ch#> <h|v>
#  su ipconfig <suid> <new ip> <new subnet> <new gateway>
#  su [live|poweroff|priority]
#  su <ping|info|status> <suid>
#  su powerleveling <all|suid>
#  su reboot <all|suid>
#  su restart <all|suid>
#  su testrflink <all|suid> [r]
#  su testrflink <setlen> [64..1600]
#  su testrflink <aptx> [20..100]
#  su sw <suid|all> <sw #> <on|off>
#  sudb [dload | view]
#  sudb add <suid> pr <cir,kbps> <mir,kbps> <device id,hex>
#  sudb add <suid> reg <cir,kbps> <mir,kbps> <device id,hex>
#  sudb delete <all|<suid>>
#  sudb modify <suid> <cir|mir> <kbps>
#  sudb modify <suid> <su2su> <group id,hex>
#  sudb view
#  sulog [lastmins | sampleperiod <1..60>]
#  sulog [<# of entry,1..18>]
#  survey <ism|unii> <time, sec> <h|v>
#  sw [<sw #> <on|off>]
#  temp
#  tftpd [on|off]
#  time
#  time <hour> <min> <sec>
#  save <mainimage|fpgaimage> <current chksum> <new chksum>
#  save <systemsetting|sudb>
#  updateflash <mainimage|fpgaimage> <current chksum> <new chksum>
#  updateflash <systemsetting|sudb>

=pod

=head1 ACCESSORS

These are usually only set internally.

=head2 B<firmware_version> - returns the firmware version

Returns the firmware version if available, otherwise undef.

It should be available after a successful open().

=head2 B<host_type> - return the type of host you are connected to.

returns the type of host from the login banner for example M5830S or M5300S.  

Should be available after a successful open().

=head2 B<is_connected> - Status of the connection to host.

returns 1 when connected, undef otherwise.

=head2 B<logged_in> - Status of being logged in to the host.

returns 1 after a successful login(), 0 if it failed and undef if 
login() was never called.

=head2 B<login_banner> - The banner when first connecting to the host.

returns the banner that is displayed when first connected at login.  
Only set after a successful open().

=head2 B<last_lines> - The last lines of output from the last cmd().

returns, as an array ref, the output from the last cmd() that was run.

=head2 B<last_error> - A text output of the last error that was encountered.

returns the last error reported.  Probably contains the last entry in
last_lines.

=head1 ALIASES

=head2 B<bye> - alias of exit()

Does the same as exit()

=head2 B<restart> - alias of reboot()

Does the same as reboot()

=head2 B<save_systemsetting> - alias of save_ss()

Does the same as save_ss()

=head1 COMMANDS

Most of these are just shortcuts to C<cmd(String =E<gt> METHOD)>, 
as such they accept the same options as C<cmd()>.  
Specifically they take a named paramater "args", for example: 
C<tftpd(args =E<gt> 'on')> would enable tftpd

=head2 B<tftpd> - The output from the tftpd command

Returns a hash ref of the decoded output from the 
command. 

Also see enable_tftpd() and disable_tftpd() as those check that it was 
successfully changed.

=head2 B<ver> - The output from the ver command

Returns a hash ref of the decoded output from the 
command. 

=head2 B<sysinfo> - The output from the sysinfo command

Returns a hash ref of the decoded output from the 
command. 

=head2 B<exit> - Exits the connection

exits the command session with the Trango and closes 
the connection

=head2 B<reboot> - Sends a reboot command

reboots the Trango and closes the connection

=head2 B<reset> <all|0..2> - Sends a reset command

resets settings to default

=head2 B<remarks> - Set or retrieve the remarks.

Takes an optional argument, which sets the remarks.  
If there is no argument, returns the current remarks.

  my $old_remarks = $t->remarks();
  $t->remarks($new_remarks);

=head2 B<sulog> - The output from the sulog command

Returns an array ref of hashes containing each log 
line.

=head2 B<save_sudb> - saves the sudb

Returns true on success, undef on failure

=head2 B<syslog> - The output from the sulog command

Returns a hashref of the output from the syslog command

=head2 B<pipe> - the pipe command

Returns the output from the pipe command

=head2 B<maclist> - retrieves the maclist

Returns the output from the maclist command

=head2 B<maclist_reset> - resets the maclist.  

No useful output.

=head2 B<eth_link> - eth link command

Returns the output from the eth link command

This command seems to cause some weird issues.  It often will cause the 
command after it to appear to fail.  I am not sure why.

=head2 B<su_info> - gets the su info

Returns information about the SU.

You need to pass in the $suid and it will return the info for that suid.

  $t->su_info($suid);

=head2 B<su_testrflink> - tests the RF Link to an su

  $t->su_testrflink($suid|'all');

=head2 B<save_ss> - saves the config.  

Returns 1 on success, undef on failure.

=head2 B<set_baseid> - sets baseid

    $t->set_baseid($baseid);

=head2 B<set_suid> - sets baseid

    $t->set_suid($baseid);

=head2 B<set_defaultopmode> - sets default opmode

    $t->set_defaultopmode(ap|su);

=head2 B<opmode> - sets or returns the opmode

    $t->opmode([ap y|su y]);

=head2 B<freq> - sets or returns the freq

    $channel = '11 v';
    $t->freq([$channel]);

=head2 B<freq_writescan> - sets the freq writescan

    $channels = '11 v 11 h 12 v 12 h';
    $t->freq_writescan($channels);

=head2 B<freq_scantable> - returns the freq scantable

    $channels = $t->freq_scantable();
    # now $channels eq '11 v 11 h 12 v 12 h';


=cut

my $success  = 'Success\\.';
my %COMMANDS = (
    _clear      => { String    => "\n" },
    tftpd       => { decode    => 'all', expect => $success },
    ver         => { decode    => 'all' },
    sysinfo     => { decode    => 'all', expect => $success },
    updateflash => { decode    => 'all', expect => $success },
    sulog       => { decode    => 'sulog', expect => $success },
    'exit'      => { no_prompt => 1, cmd_disconnects => 1 },
    reboot      => { no_prompt => 1, cmd_disconnects => 1 },
    'reset'   => {},
    remarks   => { decode => 'all', expect => $success },
    save_sudb => { String => 'save sudb', expect => $success },
    syslog  => { expect => $success },
    'pipe'  => {},      # XXX needs a special decode
    maclist => { decode => 'maclist' },
    maclist_reset => { String => 'maclist reset', expect => 'done' },
    eth_link      => { String => 'eth link',      expect => $success },
    su_info => { String => 'su info', decode => 'all', expect => $success },
    su_testrflink =>
        { String => 'su testrflink', decode => 'each', expect => $success },
    save_ss    => { String => 'save ss', expect => $success },
    set_baseid => {
        String => 'set baseid',
        decode => 'all',
        expect => $success
    },
    set_suid => {
        String => 'set suid',
        decode => 'all',
        expect => $success
    },
    set_defaultopmode => {
        String => 'set defaultopmode',
        decode => 'all',
        expect => $success
    },
    opmode => { decode => 'all',  expect => $success },
    freq   => { decode => 'freq', expect => $success },
    freq_writescan =>
        { String => 'freq writescan', decode => 'all', expect => $success },
    freq_scantable =>
        { String => 'freq scantable', decode => 'all', expect => $success },
    arq => { decode => 'all' },
);

my %ALIASES = (
    bye               => 'exit',
    restart           => 'reboot',
    Host              => 'host',
    save_systemseting => 'save_ss',
);

my %ACCESS = map { $_ => 1 } qw(
    firmware_version
    host_type
    is_connected
    logged_in
    login_banner
    Timeout
    last_lines
    last_vals
    last_error
    Decode
);

sub AUTOLOAD {
    my $self = shift;

    my ($method) = ( our $AUTOLOAD ) =~ /^.*::(\w+)$/
        or die "Weird: $AUTOLOAD";

    if ( exists $ALIASES{$method} ) {
        $method = $ALIASES{$method};
        return $self->$method(@_);
    }

    if ( exists $COMMANDS{$method} ) {
        my %cmd;
        foreach my $k ( keys %{ $COMMANDS{$method} } ) {
            $cmd{$k} = $COMMANDS{$method}{$k};
        }
        $cmd{'String'} ||= $method;
        $cmd{'args'} .= $SPACE . shift if ( @_ == 1 );
        return $self->cmd( %cmd, @_ );
    }

    if ( exists $ACCESS{$method} ) {
        my $s    = *$self->{net_telnet_trango};
        my $prev = $s->{$method};
        ( $s->{$method} ) = @_ if @_;
        return $prev;
    }

    $method = "SUPER::$method";
    return $self->$method(@_);
}

=pod

=head2 B<open> - Open a connection to a Trango AP.

Calls Net::Telnet::open() then makes sure you get a password prompt so
you are ready to login() and parses the login banner so you can get
host_type() and firmware_version()

=cut

sub open {
    my $self = shift;

    unless ( $self->SUPER::open(@_) ) {
        $self->last_error( "Couldn't connect to " . $self->host . ":  $!" );
        return;
    }

    ## Get to login prompt
    unless (
        $self->waitfor(
            -match   => '/password: ?$/i',
            -errmode => "return",
        )
        )
    {
        $self->last_error( "problem connecting to host ("
                . $self->host . "): "
                . $self->lastline );
        return;
    }

    $self->parse_login_banner( $self->lastline );

    $self->is_connected(1);

    return $self->is_connected;
}

=pod

=head2 B<login> - Login to the AP.

Calls open() if not already connected, then sends the password and sets
logged_in() if successful

=cut

sub login {
    my $self = shift;

    unless ( $self->is_connected ) {
        $self->open or return;
    }

    my $password = shift;

    $self->print($password);
    unless (
        $self->waitfor(
            -match   => $self->prompt,
            -errmode => "return",
        )
        )
    {
        $self->last_error( "login ($self->host) failed: " . $self->lastline );
        return;
    }

    $self->logged_in(1);

    return $self->logged_in;
}

=pod

=head2 B<parse_login_banner> - Converts the login_banner to something useful.

Takes a login banner (what you get when you first connect to the Trango)
or reads what is already in login_banner() then parses it and sets
host_type() and firmware_version() as well as login_banner()

=cut

sub parse_login_banner {
    my $self = shift;

    if (@_) {
        $self->login_banner(@_);
    }

    my $banner = $self->login_banner;

    my ( $type, $sep1, $subtype, $sep2, $ver )
        = $banner
        =~ /Welcome to Trango Broadband Wireless,? (\S+)([\s-]+)(\S+)([\s-]+)(.+)$/i;

    $type .= $sep1 . $subtype;
    $ver = $subtype . $sep2 . $ver;

    $self->login_banner($banner);
    $self->host_type($type);
    $self->firmware_version($ver);

    return 1;
}

=pod

=head2 B<linktest> - Link test to SU

linktest('suid'[, 'pkt len, bytes'[, '# of pkts'[, '# of cycles']]]);

Returns a hash reference to the results of the test

=cut

sub linktest {
    my $self = shift;
    my $suid = shift;

    # These numbers are what I found as defaults when running the command
    my $pkt_len = shift || 1600;
    my $pkt_cnt = shift || 500;
    my $cycles  = shift || 10;

    my %config = @_;

    # * 2, one for the FromAP, one FromSU.  Then / 1000 to get to ms.
    # XXX This might need to be changed, this makes the default timeout the
    # same as $pkt_len, and that might not be enough at slower speeds.
    $config{Timeout} ||= int( ( $pkt_len * $pkt_cnt * $cycles * 2 ) / 1000 );

    my $string = join $SPACE, 'linktest', $suid, $pkt_len, $pkt_cnt, $cycles;
    return $self->cmd(
        %config,
        String => $string,
        decode => 'linktest',
    );

}

=pod

=head2 B<su_password> - Set the password on SUs connected to the AP.

su_password('new_password'[, 'suid']) If no suid is specified,
the default is "all".

  $t->su_password('good_pass', 5);

=cut

sub su_password {
    my $self     = shift;
    my $new_pass = shift || $EMPTY;
    my $su       = shift || 'all';

    unless ( defined $new_pass ) {
        $self->last_error("No new password");

        #return;
    }

    return $self->cmd(
        String => 'su password ' 
            . $su 
            . $SPACE
            . $new_pass
            . $SPACE
            . $new_pass,
        expect => $success,
    );
}

=pod

=head2 B<ipconfig> - Change IP configuration

ipconfig( 'new_ip', 'new_subnet', 'new_gateway' )

  $t->ipconfig( '10.0.1.5', '255.255.255.0', '10.0.1.1' );

=cut

sub ipconfig {
    my $self = shift;

    my $string = join $SPACE, 'ipconfig', @_;

    if ( @_ == 3 ) {
        $self->print($string);
        my @lines = $self->waitfor( Match => '/save\s+and\s+activate/', );
        $self->print('y');

        $self->logged_in(0);
        $self->is_connected(0);

        foreach my $line (@lines) {
            if ( $line =~ s/New \s configuration:\s+//xms ) {
                return _decode_lines($line);
            }
        }

        return {};
    }

    # ipconfig [ <new ip> <new subnet> <new gateway> ]
    return $self->cmd( String => $string, expect => $success );
}

=pod

=head2 B<su_ipconfig> - Change IP configuration on SUs connected to the AP.

su_ipconfig( 'suid', 'new_ip', 'new_subnet', 'new_gateway' )

  $t->su_ipconfig( 5, '10.0.1.5', '255.255.255.0', '10.0.1.1' );

=cut

sub su_ipconfig {
    my $self = shift;

    my $suid        = shift;
    my $new_ip      = shift;
    my $new_subnet  = shift;
    my $new_gateway = shift;

    if ( $suid =~ /\D/ ) {
        $self->last_error("Invalid suid '$suid'");
        return;
    }
    unless ($new_ip) {
        $self->last_error("no new_ip passed");
        return;
    }
    unless ($new_subnet) {
        $self->last_error("no new_subnet passed");
        return;
    }
    unless ($new_gateway) {
        $self->last_error("no new_gateway passed");
        return;
    }

    # su ipconfig <suid> <new ip> <new subnet> <new gateway>
    return $self->cmd(
        String => 'su ipconfig ' 
            . $suid 
            . $SPACE 
            . $new_ip 
            . $SPACE
            . $new_subnet
            . $SPACE
            . $new_gateway,
        expect => $success,
    );
}

=pod

=head2 B<sudb_view> - Returns the output from the sudb view command

returns a reference to an array of hashes each containing these keys
'suid', 'su2su', 'type', 'cir', 'mir' and 'mac'

=cut

sub sudb_view {
    my $self = shift;

    my $lines = $self->cmd( String => 'sudb view', expect => $success ) || [];

    return unless @{$lines};

    my $s = *$self->{net_telnet_trango};
    return $lines if !$s->{'Decode'};

    my @sus;
    foreach ( @{$lines} ) {
        next unless $_;
        if (/^
            \[(\d+)\]
            \s+
            [[:xdigit:]]{2}
            ([[:xdigit:]])
            ([[:xdigit:]])
            \s+
            (\d+)
            \s+
            (\d+)
            \s+
            ([[:xdigit:]\s]+)
        $/ixms
            )
        {
            my %s = (
                suid  => $1,
                su2su => $2 ? $2 : undef,
                type  => $3 == 1 ? 'reg' : $3 == 5 ? 'pri' : $3,
                cir   => $4,
                mir   => $5,
                mac   => $6,
            );

            $s{'mac'} =~ s/\s//gxms;
            $s{'mac'} = uc( $s{'mac'} );

            push @sus, \%s;
        }
    }

    return \@sus;
}

=pod

=head2 B<sudb_add> - Adds an su to the sudb

Takes the following paramaters

    suid : numeric,
    type : (reg|pr)
    cir  : numeric,
    mir  : numeric,
    mac  : Almost any format, it will be reformatted,

and returns true on success or undef otherwise.

  $t->sudb_add($suid, 'reg', $cir, $mir, $mac);

You should save_sudb() after calling this, or your changes  will be lost 
when the AP is rebooted.

=cut

sub sudb_add {
    my $self = shift;
    my $suid = shift;
    my $type = shift;
    my $cir  = shift;
    my $mir  = shift;
    my $mac  = shift;

    if ( $suid =~ /\D/ ) {
        $self->last_error("Invalid suid '$suid'");
        return;
    }

    unless ( lc($type) eq 'reg' || lc($type) eq 'pr' ) {
        $self->last_error("Invalid type '$type'");
        return;
    }

    if ( $cir =~ /\D/ ) {
        $self->last_error("Invalid CIR '$cir'");
        return;
    }

    if ( $mir =~ /\D/ ) {
        $self->last_error("Invalid MIR '$mir'");
        return;
    }

    my $new_mac = $mac;
    $new_mac =~ s/[^0-9A-Fa-f]//g;
    unless ( length $new_mac == 12 ) {
        $self->last_error("Invalid MAC '$mac'");
        return;
    }
    $new_mac = join $SPACE, $new_mac =~ /../g;

    my $string
        = 'sudb add ' 
        . $suid 
        . $SPACE 
        . $type 
        . $SPACE 
        . $cir 
        . $SPACE 
        . $mir
        . $SPACE
        . $new_mac;

    return $self->cmd( String => $string, expect => $success );
}

=pod

=head2 B<sudb_delete> - removes an su from the sudb

Takes either 'all' or the  suid of the su to delete
and returns true on success or undef otherwise.

  $t->sudb_delete($suid);

You should save_sudb() after calling this, or your changes  will be lost 
when the AP is rebooted.

=cut

sub sudb_delete {
    my $self = shift;
    my $suid = shift;

    #if (lc($suid) ne 'all' || $suid =~ /\D/) {
    if ( $suid =~ /\D/ ) {
        $self->last_error("Invalid suid '$suid'");
        return;
    }

    return $self->cmd( String => 'sudb delete ' . $suid, expect => $success );
}

=pod

=head2 B<sudb_modify> - changes the su information in the sudb

Takes either the  suid of the su to change
as well as what you are changing, either "cir, mir or su2su"
and returns true on success or undef otherwise.

cir and mir also take a value to set the cir/mir to.

su2su takes a group id parameter that is in hex.

  $t->sudb_modify($suid, 'cir', 512);

You should save_sudb() after calling this, or your changes  will be lost 
when the AP is rebooted.

=cut

sub sudb_modify {
    my $self  = shift;
    my $suid  = shift;
    my $opt   = shift;
    my $value = shift;

    if ( $suid =~ /\D/ ) {
        $self->last_error("Invalid suid '$suid'");
        return;
    }

    if ( lc($opt) eq 'cir' or lc($opt) eq 'mir' ) {
        if ( $value =~ /\D/ ) {
            $self->last_error("Invalid $opt '$value'");
            return;
        }
    }
    elsif ( lc($opt) eq 'su2su' ) {
        if ( $value =~ /[^0-9A-Za-f]/ ) {
            $self->last_error("Invalid MAC '$value'");
            return;
        }
    }
    else {
        $self->last_error("Invalid option '$opt'");
        return;
    }

    my $string = 'sudb modify ' . $suid . $SPACE . $opt . $SPACE . $value;

    return $self->cmd( String => $string, expect => $success );
}

=pod

=head2 B<enable_tftpd> - enable the TFTP server

runs C<tftpd(args =E<gt> 'on')> and makes sure that Tftpd is now 'listen'ing

=cut

sub enable_tftpd {
    my $self = shift;

    my $vals = $self->tftpd( args => 'on' );

    if ( ref $vals eq 'HASH' && $vals->{'Tftpd'} eq 'listen' ) {
        return $vals;
    }
    else {
        return;
    }
}

=pod

=head2 B<disable_tftpd> - disable the TFTP server

runs C<tftpd(args =E<gt> 'off')> and makes sure that Tftpd is now 'disabled'

=cut

sub disable_tftpd {
    my $self = shift;

    my $vals = $self->tftpd( args => 'off' );

    if ( ref $vals eq 'HASH' && $vals->{'Tftpd'} eq 'disabled' ) {
        return $vals;
    }
    else {
        return;
    }
}

=pod

=head2 B<cmd> - runs a command on the AP.

This does most of the work.  At the heart, it calls Net::Telnet::cmd()
but it also does some special stuff for Trango.

Normally returns the last lines from from the command

If you are using this, rather than one of the "easy" methods above, 
you probably want to read through the source of this module to see how 
some of the other commands are called.

In addition to the Net::Telnet::cmd() options, it also accepts these:

I<decode> 
- if this is true, then it will send the output lines to _decode_lines()
and then returns the decoded output

I<no_prompt>
- if this is true, it does not wait for a prompt, so you are not stuck 
waiting for something that will never happen.

I<cmd_disconnects>
- if this is true, it then sets logged_in() to false, then it will
close() the connection and set is_connected() to false

I<expect>
- if this is set (usually to 'Success.') it will check for that in the
last line of output and if it does not, will return undef because the
command probably failed

I<args>
- a string containing the command line options that are passed to the
command

    $t->cmd( String => 'exit', no_prompt => 1, cmd_disconnects => 1 );

=cut

sub cmd {
    my $self = shift;
    my $s    = *$self->{net_telnet_trango};

    my @valid_net_telnet_opts = qw(
        String
        Output
        Cmd_remove_mode
        Errmode
        Input_record_separator
        Ors
        Output_record_separator
        Prompt
        Rs
        Timeout
    );

    my %cfg;
    if ( @_ == 1 ) {
        $cfg{'String'} = shift;
    }
    elsif ( @_ > 1 ) {
        %cfg = @_;
    }

    $cfg{'Timeout'} ||= $self->Timeout;

    unless ( $cfg{'String'} ) {
        $self->last_error("No command passed");
        return;
    }

    unless ( $self->is_connected ) {
        $self->last_error("Not connected");
        return;
    }

    unless ( $self->logged_in ) {
        $self->last_error("Not logged in");
        return;
    }

    my %cmd;
    foreach (@valid_net_telnet_opts) {
        if ( exists $cfg{$_} ) {
            $cmd{$_} = $cfg{$_};
        }
    }
    if ( $cfg{'args'} ) {
        $cmd{'String'} .= $SPACE . $cfg{'args'};
    }

    #print "Running cmd $cmd{String}\n";
    my @lines;
    if ( $cfg{'no_prompt'} ) {
        $self->print( $cmd{'String'} );
        @lines = $self->lastline;
    }
    else {
        @lines = $self->SUPER::cmd(%cmd);
    }

    $self->last_lines( \@lines );

    my $last   = $self->lastline;
    my $prompt = $self->prompt;
    $prompt =~ s{^/}{}xms;
    $prompt =~ s{/[gixms]*$}{}xms;
    while ( @lines && $last =~ qr($prompt) ) {
        pop @lines;
        $last = $lines[-1];
    }
    $self->last_error($EMPTY);

    my $vals = 1;
    if ( $s->{'Decode'} && $cfg{'decode'} ) {
        if ( $cfg{'decode'} eq 'each' ) {
            $vals = _decode_each_line(@lines);
        }
        elsif ( $cfg{'decode'} eq 'sulog' ) {
            $vals = _decode_sulog(@lines);
        }
        elsif ( $cfg{'decode'} eq 'maclist' ) {
            $vals = _decode_maclist(@lines);
            if ( !$vals ) {
                $self->last_error("Error decoding maclist");
            }
        }
        elsif ( $cfg{'decode'} eq 'linktest' ) {
            $vals = _decode_linktest(@lines);
            if ( !$vals ) {
                $self->last_error("Error decoding linktest");
            }
        }
        elsif ( $cfg{'decode'} eq 'freq' ) {
            $vals = _decode_freq(@lines);
        }
        else {
            $vals = _decode_lines(@lines);
        }
    }
    if ( ref $vals eq 'HASH' ) {
        $vals->{_raw} = join q{}, @lines;
    }
    $self->last_vals($vals);

    if ( ( not $cfg{'expect'} ) || $last =~ /$cfg{'expect'}$/ ) {
        if ( $cfg{'cmd_disconnects'} ) {
            $self->logged_in(0);
            $self->close;
            $self->is_connected(0);
        }

        if ( $s->{'Decode'} && $cfg{'decode'} ) {
            return $vals;
        }
        else {
            return \@lines;
        }
    }
    else {
        my $err;
        if ( grep {/\[ERR\]/} @lines ) {
            $err = _decode_lines(@lines);
        }

        if ( ref $err eq 'HASH' && $err->{ERR} ) {
            $self->last_error( $err->{ERR} );
        }
        else {
            $self->last_error("Error with command ($cmd{'String'}): $last");
        }
        return;
    }
}

#=item _decode_lines

sub _decode_lines {
    my @lines = @_;

    my %conf;

    my $key = $EMPTY;
    my $val = undef;
    my @vals;
    my $in_key = 0;
    my $in_val = 1;

LINE: while ( my $line = shift @lines ) {
        next LINE if $line =~ /$success\Z/;
        next LINE if $line =~ /^ \*+ \s+ \d+ \s+ \*+ \Z/xms;

        # Special decode for sysinfo on a TrangoLink 45
        if ( $line =~ /^(.* Channel \s+ Table):\s*(.*)\Z/xms ) {
            my $key  = $1;
            my $note = $2;

            my %vals;
            while ( $line = shift @lines ) {
                if ( $line =~ /^\Z/ ) {
                    $conf{$key} = \%vals;
                    $conf{$key}{note} = $note;
                    next LINE;
                }

                my $decoded = _decode_lines($line);
                if ($decoded) {
                    %vals = ( %vals, %{$decoded} );
                }
            }
        }

        # Another special decode for the TrangoLink
        elsif (
            $line =~ /^
            RF \s Band \s \# 
            (\d+) \s+ 
            \( ([^\)]+) \) \s*
            (.*)$
        /xms
            )
        {
            my $num   = $1;
            my $band  = $2;
            my $extra = $3;

            if ( $extra =~ /\[/ ) {
                my $decoded = _decode_lines($extra);
                $conf{'RF Band'}{$num} = $decoded;
            }
            else {
                $conf{'RF Band'}{$num}{$extra} = 1;
            }
            next LINE;
        }

        my @chars = split //, $line;

        my $last_key = $EMPTY;
        foreach my $c (@chars) {

            if ( $c eq '[' || $c eq "\r" || $c eq "\n" ) {
                if ( $c eq '[' ) {
                    $in_key = 1;
                    $in_val = 0;
                }
                else {
                    $in_key = 0;
                    $in_val = 1;
                }

                if ($key) {
                    $key =~ s/^\s+//;
                    $key =~ s/\s+$//;

                    if ($val) {
                        $val =~ s/^\s+//;
                        $val =~ s/\s+\.*$//;
                    }

                    if ( $key eq 'Checksum' && $last_key ) {

                        # Special case for these bastids.
                        my $new = $last_key;
                        $new =~ s/\s+\S+$//;
                        $key = $new . $SPACE . $key;
                    }

                    $conf{$key} = $val;
                    $last_key   = $key;
                    $key        = $EMPTY;
                }
                elsif ($val) {
                    push @vals, $val;
                }
                $val = $EMPTY;

            }
            elsif ( $c eq ']' ) {
                $in_val = 1;
                $in_key = 0;
                $c      = shift @chars;

            }
            elsif ($in_key) {
                $key .= $c;

            }
            elsif ($in_val) {
                $val .= $c;
            }
        }
    }

    unless ($key) {
        push @vals, $val;
    }

    foreach my $val (@vals) {
        if ( defined $val && length $val ) {
            $val =~ s/^\s+//;
            $val =~ s/\s+\.*$//;
        }
    }

    if ( @vals == 1 ) {
        $val = $vals[0];
    }
    elsif (@vals) {
        $val = \@vals;
    }
    else {
        $val = undef;
    }

    if (%conf) {
        $conf{_pre} = $val if $val;
        return \%conf;
    }
    else {
        return $val;
    }
}

#=item _decode_each_line

sub _decode_each_line {
    my @lines = @_;
    my @decoded;
    foreach my $line (@lines) {
        my $decoded = _decode_lines($line);
        push @decoded, $decoded if defined $decoded && length $decoded;
    }
    return \@decoded;
}

#=item _decode_linktest

sub _decode_linktest {
    my @lines = @_;
    my %decoded;
    foreach my $line (@lines) {

        if ( $line =~ s/^(\d+) \s+ //xms ) {
            my $line_id = $1;
            my ( $tm, $rt );
            if ( $line =~ s/\s+ (\d+ \s+ \w+) \s* $//xms ) {
                $rt = $1;
            }
            if ( $line =~ s/\s+ (\d+ \s+ \w+) \s* $//xms ) {
                $tm = $1;
            }

            my $d = _decode_lines( $line . "\n" );
            $decoded{tests}[$line_id]         = $d;
            $decoded{tests}[$line_id]{'time'} = $tm;
            $decoded{tests}[$line_id]{rate}   = $rt;
        }

        else {
            my $d = _decode_lines( $line . "\n" );
            if ($d) {
                while ( my ( $k, $v ) = each %{$d} ) {
                    $decoded{$k} = $v;
                }
            }
        }

    }
    return \%decoded;
}

#=item _decode_sulog

sub _decode_sulog {
    my @lines = @_;
    my @decoded;
    my $last_tm;
    foreach my $line (@lines) {
        my $decoded = _decode_lines($line);

        if ( defined $decoded ) {
            if ( $decoded->{'tm'} ) {
                $last_tm = $decoded->{'tm'};
                next;
            }
            else {
                $decoded->{'tm'} = $last_tm;
            }
            next unless $last_tm;

            push @decoded, $decoded if defined $decoded;
        }
    }
    return \@decoded;
}

#=item _decode_maclist

sub _decode_maclist {
    my @lines = @_;
    my @decoded;
    my $total_entries = 0;
    my $current_tm    = 0;
    foreach my $line (@lines) {
        $line =~ s/\r?\n$//;
        my ( $mac, $loc, $tm ) = $line =~ /
            ([0-9a-fA-F ]{17})\s+
            (.*)\s+
            tm\s+
            (\d+)
        /x;

        if ($mac) {
            $mac =~ s/\s+//g;
            $loc =~ s/^\s+//;
            $loc =~ s/\s+$//;

            my $suid = undef;
            if ( $loc =~ /suid\s+=\s+(\d+)/ ) {
                $suid = $1;
                $loc  = undef;
            }

            push @decoded,
                {
                mac  => $mac,
                loc  => $loc,
                tm   => $tm,
                suid => $suid,
                };
        }
        elsif ( $line =~ /(\d+)\s+entries/ ) {
            $total_entries = $1;
        }
        elsif ( $line =~ /current tm = (\d+)\s+sec/ ) {
            $current_tm = $1;
        }
    }

    map { $_->{'cur_tm'} = $current_tm } @decoded;

    if ( scalar @decoded == $total_entries ) {
        return \@decoded;
    }
    else {
        return;
    }
}

#=item _decode_freq

sub _decode_freq {
    my @lines   = @_;
    my $decoded = _decode_lines(@lines);

    if ( $decoded && $decoded->{ERR} ) {
        return $decoded;
    }

LINE: foreach my $line (@lines) {
        if (my ( $channel, $polarity, $freq )
            = $line =~ /
            Ch \s+ \#(\d+) 
            \s+
            (\w+)
            \s+
            \[ (\d+) \s+ MHz\]
        /ixms
            )
        {
            $decoded = {
                channel   => $channel,
                polarity  => $polarity,
                frequency => $freq,
            };
            last LINE;
        }
    }
    return $decoded;
}

1;    # End of Net::Telnet::Trango
__END__

=head1 SEE ALSO

Trango Documentation - 
L<http://www.trangobroadband.com/support/product_docs.htm>

L<Net::Telnet>

=head1 TODO

There are still a lot of commands that are not accessed directly.  If
you call them (as cmd("command + args") or whatever) and it works,
please send me examples that work and I will try to get it incorporated
into the next version of the script.

I also want to be able to parse the different types of output from
commands like su, sudb all and anything else that would be better
available as a perl datastructure.

=head1 AUTHOR

Andrew Fresh E<lt>andrew@rraz.netE<gt>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Telnet::Trango

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Telnet-Trango>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Telnet-Trango>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Telnet-Trango>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Telnet-Trango>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005,2006,2007 by Andrew Fresh

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
