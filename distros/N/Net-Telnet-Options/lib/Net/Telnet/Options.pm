# Net::Telnet::Options
# Module to deal with telnet options via code refs that are called when 
# an option is encountered. Defaults to refusing to do any offered options.

=head1 NAME

  Net::Telnet::Options - Telnet options over any socket

=head1 VERSION
 
This document describes Net::Telnet::Options version 0.0.1

=head1 SYNOPSIS

  use Net::Telnet::Options;

  my %options = (BINARY => { 'DO' => sub {} },
                 MSP    => { 'DO' => sub {} } );

  my $nto = Net::Telnet::Options->new(%options);

  OR

  my $nto = Net::Telnet::Options->new();

  # Accept and deal with incoming TERM TYPE option requests
  $nto->acceptDoOption('TTYPE', {'SB' => \&ttype_sb_callback } );

  sub ttype_sb_callback
  {
     my ($cmd, $subcmd, $data, $pos) = @_;

     $nto->sendOpt($socket, 'SB', 24, 'IS', 'VT100');
     return ;
  }

  # Actively ask the connected party to do the NAWS option
  $nto->activeDoOption('NAWS', {'SB' => \&naws_sb_callback } );

  # Parse and use the NAWS information
  sub naws_sb_callback
  {
    my ($cmd, $subcmd, $data, $pos) = @_;
    print ("NAWS SB: $cmd\n");
    return unless($cmd eq 'IS');
    my ($width, $height) = unpack('nn', $subcmd);
    print ("NAWS width, height: $width, $height\n");
    return ;
  }

  # Add a callback to deal with incoming ECHO requests
  $nto->addOption(0, 'ECHO', {'WILL' => \&willecho_callback,
                              'WONT'  => \&wontecho_callback });

  # Agree to to let them do MXP
  $nto->acceptWillOption('MXP');

  # Send the active options to the connected party
  $nto->doActiveOptions($socket);

  # Assuming $socket is an IO::Handle/Socket

  # Let NTO parse telnet options from incoming data:
  my $data;
  recv($socket, $data, 1024, 0);
  $data = $nto->answerTelnetOpts($socket, $data);

=head1 DESCRIPTION

This module is intended to handle Telnet Option requests on any given socket. Per default it refuses to do any option asked of it by the connected party. Any known telnet option can be set to be explicitly accepted or actively asked of the other side. Callback subroutines allow the user to execute some action upon receiving a particular option.

An instance of Net::Telnet::Options must be created for each socket, to keep track of the current state of each client.

=head1 INTERFACE

=head2 new (%options)

The new method can be passed a hash of default option callbacks to set. The keys of the hash are either option names, as given in the %possoptions hash at the top of this module, or option numbers from the appropriate RFCs.

The values of each item are hash references, with the keys being the option types to be handled, one of either WILL, WONT, DO, DONT, SB or RAW. The values should contain sub references of the callbacks to be called.

=head2 addOption ($activeflag, %opts)

The addOption method can be used to add more options in the same format as the new command, after the instance has been created. The additional activeflag can be set to either 0 or 1 to activate an option. An active option is one that is actively requested of the connected party.

=head2 acceptDoOption (option name/number or hash reference)

Agree to do the specific option. If just an option name/number is given, just agrees to do this option whenever requested by the connected party. (Sets up an empty callback). Can also be passed a hashref as with the hash references passed to the new method, containing callbacks to be called.

=head2 acceptWillOption (option name/number or hash reference)

Agree that the connected party will do a specific option. If just an option name/number is given, just agrees that the other party will do this option wheneverrrequested. (Sets up an empty callback). Can also be passed a hash reference as above to run callbacks.

=head2 activeDoOption (option name/number or hash reference)

Actively ask the connected party to DO a specific option. If just passed an option name/number, will just ask and ignore the response. If passed a hash reference containing WILL/WONT callbacks, these will be run when the connected party answers the request.

=head2 activeWillOption (option name/number or hash reference)

Actively declare that we want to do a specific option. If just passes an option name/number, will just declare what we want to do, and ignore any response. If passed a hash reference containing DO/DONT callbacks, these will be run when the connected party answers the request.

=head2 removeOption (option name/number)

Remove the given option from the set of options we are answering.

=head2 doActiveOptions (socket)

Requests any options set as active, and not yet negotiated,  of the connected party.

=head2 getTelnetOptState (option name/number)

Returns a hash reference containing any callbacks set for any particular command, plus 'STATUS_ME', 'STATUS_YOU' which can be any of NONE, ASKING, or WILL. STATUS_ME is the status of the local socket with regard to the option, and STATUS_ME is the status of the connected party.

=head2 answerTelnetOpts (socket, data)

This method must be called whenever data has been received from the connected party, before any other operations are done. It parses any telnet option information out of the given data, answering options as appropriate. The cleaned data is passed back. The socket is needed in order to send answers to any option requests.

If a incomplete telnet option is found in the data, eg an IAC WILL and no option number, the data will be retained, and prepended to the data given in the next call, to be checked again. Thus you can also pass in data a byte at a time and still have the options parsed.

=head2 sendOpt (socket, command, option name/number, suboptioncmd, suboption)

Send a raw telnet option to the connected party. But only if it makes sense. Eg. if DOing NAWS has been negotiated, attempting a DO NAWS with sendOpt will refuse, on the grounds that we are already doing this. Useful for testing and turning off options by hand.

=head1 CALLBACKS

Methods are provided for adding callbacks to each part of the negotiation process. Callbacks for WILL, WONT, DO, DONT commands are passed out the passed in data string, with the option removed. This string may still have other following options in it, so should be treated with caution! The callback is also passed the position which the option was found in the string. It may return a new copy of the data string which will be used for further parsing. In most cases you will not need to look at or return the data string. Be sure to return undef as the last statement in your callback, if you are not changing the data, to not accidently return the value of your last statement.

Sub option callbacks are slightly more complex. Suboptions generally have one of 2 different subcommands, either a SEND which means please send me some information, or IS, which defines the wanted information. The callback is passed either 'SEND' or 'IS' or 'SB' as the first parameter, if IS is passed, the 2nd parameter contains the information being passed, for SEND it is empty and for SB it contains the subcommand and the any information together. The 3rd parameter contains the data string, minus the actual telnet option commands, and the 4th parameter is the position the suboption was in the string.

Currently it is assumed that the module user will remember which callback has been associated with which option. (Thus the callback does not get passed the option name/number for which it is fired)

=head1 Telnet Options Explained

Telnet options are simple but complex. The definition is simple, the implementation is complex as one has to avoid entering endless negotiation loops. The simple explanation should suffice here, as this module intends to hide the complex negotiating from you.

Each Telnet connection consists of two parties, one on either side of the connection. When dealing with telnet options it is unimportant which side is the server and which is the client, important is just 'us' and 'them'. 'us' here is the side using this module, and 'them' is the party we are connected to.

There are 4 basic telnet option commands, WILL, WONT, DO, DONT. If we receive a WILL command, it means the other side wishes to start using an option themselves. If we receive a DO command, the other side wants us to start using an option. These are two separate things. We can use an option that they are not using, and vice versa. WONT and DONT are used to refuse an option.

Example:

1a. We receive a DO TTYPE from them.
1b i. We wish to comply, so we send a WILL TTYPE.
1b ii. We do not wish to comply so we send a WONT TTYPE.

2a. We would like to echo, so we send a WILL ECHO.
2b i. Thats ok with them, so they send a DO ECHO.
2b ii. They dont want us to use echo, so they send us a DONT ECHO.

Once an option has been set in this manner, each side has to remember which options both ends are using. The default for all options is WONT/DONT.

Some options have additional suboptions to set internal parameters. These are sent enclosed in SB and SE commands. (suboption, suboptionend). For example, settting the TTYPE option just indicates we are willing to answer 'what is your terminal type' questions, these are posed and answered using SB commands.

=head1 DIAGNOSTICS 

(TODO)

=head1 CONFIGURATION AND ENVIRONMENT

Net:Telnet::Options requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES
 
None.

=head1 BUGS AND LIMITATIONS
 
No bugs have been reported.
 
Please report any bugs or feature requests to
C<bug-<RT NAME>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 FURTHER INFORMATION

A list of available options: http://www.networksorcery.com/enp/protocol/telnet.htm

=head1 TODO

Support multiple sockets per instance.
Output list of options/names.
 
=head1 AUTHOR
 
Jess Robinson  C<< castaway@desert-island.m.isar.de >>
 
=head1 LICENCE AND COPYRIGHT
 
Copyright (c) 2004,2005, Jess Robinson C<< castaway@desert-island.m.isar.de >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
  
=head1 DISCLAIMER OF WARRANTY
 
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.
 
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

package Net::Telnet::Options;
use Data::Dumper;

my $DEBUG = 0;
our $VERSION = '0.01';

my %possoptions = (
   BINARY          => 0, # Binary Transmission - RFC 856
   ECHO            => 1, # Echo                - RFC 857
   RCP             => 2, # Reconnection        -
   SGA             => 3, # Suppress Go Ahead   - RFC 858
   NAMS            => 4, # Approx Message Size Negotiation -
   STATUS          => 5, # Status              - RFC 859
   TM              => 6, # Timing Mark         - 860
   RCTE            => 7, # Remote Con. Trans,Echo - RFC 563,726
   NAOL            => 8, # Output Line Width   - NIC50005
   NAOP            => 9, # Output Page Size    - NIC50005
   NAOCRD          => 10, # Out. CR Disposition - RFC 652
   NAOHTS          => 11, # Out. Horiz. Tab Stops - RFC 653
   NAOHTD          => 12, # Out. Horiz. Tab Dispo. - RFC 654
   NAOFFD          => 13, # Out. Formfeed Disposition - RFC 655
   NAOVTS          => 14, # Out. Vertical Tabstops - RFC 656
   NAOVTD          => 15, # Out. Vertical Tab Dispo. - RFC 657
   NAOLFD          => 16, # Out. Linefeed Disposition - RFC 658
   XASCII          => 17, # Extended ASCII     - RFC 698
   LOGOUT          => 18, # Logout             - RFC 727
   BM              => 19, # Byte Macro         - RFC 735
   DET             => 20, # Data Entry Terminal - RFC 732,1043
   SUPDUP          => 21, # SUPDUP             - RFC 734,736
   SUPDUPOUTPUT    => 22, # SUPDUP Output      - RFC 749
   SNDLOC          => 23, # Send Location      - RFC 779
   TTYPE           => 24, # Terminal Type      - RFC 1091
   EOR             => 25, # End of Record      - RFC 885
   TUID            => 26, # TACACS User Ident. - RFC 927
   OUTMRK          => 27, # Output Marking     - RFC 933
   TTYLOC          => 28, # Terminal Location Number - RFC 946
   '3270REGIME'    => 29, # Telnet 3270 Regime - RFC 1041
   X3PAD           => 20, # X.3 PAD            - RFC 1053
   NAWS            => 31, # Negotiate Ab. Win. Size - RFC 1073
   TSPEED          => 32, # Terminal Speed     - RFC 1079
   LFLOW           => 33, # Remote Flow Control - RFC 1372
   LINEMODE        => 34, # Linemode           - RFC 1184
   XDISPLOC        => 35, # X Display Location - RFC 1096
   OLD_ENVIRON     => 36, # Environment Option - RFC 1408
   AUTHENTICATION  => 37, # Auth.- RFC 1416,2941,2942,2943,2951
   ENCRYPT         => 38, # Encryption Option - RFC 2946
   NEW_ENVIRON     => 39, # New Environment Option - RFC 1572
   TN3270E         => 40, # TN3270 ?          - RFC 2355
   XAUTH           => 41, # XAUTH             -
   CHARSET         => 42, # Negotiate charset to use - RFC 2066
   RSP             => 43, # Telnet remote serial port - RFC 
   CPCO            => 44, # Com port control option - RFC 2217
   TSLE            => 45, # Telnet suppress local echo -
   STARTTLS        => 46, # Telnet Start TLS -
   KERMIT          => 46, # Kermit ?           - RFC 2840
   SENDURL         => 47, # Send URL           -
   FORWARDX        => 48, # X forwarding
   MCCP1           => 85, # Mud Compression Protocol (v1)
   MCCP2           => 86, # Mud Compression Protocol (v2)
   MSP             => 90, # Mud Sound Protocol
   MXP             => 91, # Mud eXtension Protocol
   PRAGMALOGON     => 138, # Telnet option pragma logon
   SSPILOGON       => 139, # Telnet option SSPI login
   PRAGMAHB        => 140, # Telnet option pragma heartbeat
   EXOPL           => 255, # Extended-Options-List - RFC 861
                  );
my %optposs = reverse %possoptions;

my %posscommands = (
                    GA     => 249, # you may reverse the line
                    EL     => 248, # erase the current line
                    EC     => 247, # erase the current character
                    AYT    => 246, # are you there
                    AO     => 245, # abort output--but let prog finish
                    IP     => 244, # interrupt process--permanently
                    BREAK  => 243, # break
                    DM     => 242, # data mark--for connect. cleaning
                    NOP    => 241, # nop
                    SE     => 240, # end sub negotiation
                    EOR    => 239, # end of record (transparent mode)
                    ABORT  => 238, # Abort process
                    SUSP   => 237, # Suspend process
                    EOF    => 236, # End of file
#                    SYNCH  => 242, # Data mark in urgent mode
                    );
my %commposs = reverse %posscommands;

my $chIAC = chr(255);
my $chDONT = chr(254);
my $chDO = chr(253);
my $chWONT = chr(252);
my $chWILL = chr(251);
my $chSB = chr(250);
my $chSE = chr(240);

# Auth commands
my $chNAME = chr(3);
my $chREPLY = chr(2);
my $chSEND = chr(1);
my $chIS = chr(0);
# Auth types
my %authtypes = (
                 NULL        => 0,  # RFC 2941
                 KERBEROS_V4 => 1,  # RFC 2941
                 KERBEROS_V5 => 2,  # RFC 2942
                 SPX         => 3,  # RFC 2941
                 MINK        => 4,  # RFC 2941
                 SRP         => 5,  # RFC 2944
                 RSA         => 6,  # RFC 2941
                 SSL         => 7,  # RFC 2941
                 ''          => 8,  # Unassigned
                 ''          => 9,  # Unassigned
                 LOKI        => 10, # RFC 2941
                 SSA         => 11, # Schoch ?
                 KEA_SJ      => 12, # RFC 2951
                 KEA_SJ_INTEG=> 13, # RFC 2951
                 DSS         => 14, # RFC 2943
                 NTLM        => 15, # Kahn ?
                );

my $OPT_LINEMODE_MODE = 1;
my $OPT_LINEMODE_MODE_EDIT = 1;

# The 4 telnet negotiation types, Subnegotiation, and Raw (call sub whenever
# option encountered, ie EOR)
my @opttypes = ('WILL', 'WONT', 'DO', 'DONT', 'SB', 'RAW');

sub new
{
    # Create new Net::Telnet::Options
    # Parameter: Class-Name/Reference, Properties
    my $class = shift;
    $class = ref($class) || $class;
    my $self = {};
    bless($self, $class);
    $self->initModule(@_);
    return $self;
}

sub initModule
{
    # Set default values
    # Parameter: Object, Option list (eg: NAWS => {WILL => coderef, WONT => coderef .. }
    my ($mod, %opts) = @_;

    $mod->{'telnetopts'} = {};

    foreach $opt (keys %opts)
    {
        $mod->addOption(0, $opt => $opts{$opt});
     }

    $mod->{'lastcommand'} = '';
    $mod->{'olddata'} = '';
}

sub addOption
{
    # Add a new set of option responses
    # Parameter: Object, Option hash
    my ($mod, $active, %opts) = @_;

    my $opt = $orgopt = (keys(%opts))[0];
    if (defined($possoptions{uc($opt)}) || defined($opt = $optposs{$opt}))
    {
        foreach my $opttype (@opttypes)
        {
            if (exists($opts{$orgopt}->{$opttype}))
            {
                $mod->{'telnetopts'}{uc($opt)}{$opttype} = $opts{$orgopt}->{$opttype};
            }
        }
        $mod->{'telnetopts'}{uc($opt)}{'STATUS_ME'} = 'NONE';
        $mod->{'telnetopts'}{uc($opt)}{'STATUS_YOU'} = 'NONE';
        $mod->{'telnetopts'}{uc($opt)}{'ACTIVE'} = 1 if($active);
    }
#    debug("addOption: ". Dumper($mod->{'telnetopts'}). "\n");
}

sub acceptDoOption
{
    # I'll DO option, when the other side requests it
    # Add a new option that defaults to 'DO' with no callback
    # Parameter: Object, Active, Option hash
    my ($mod, @opts) = @_;
    my %opts;
    %opts = (@opts == 1 ? (@opts, 1) : @opts);

    my $opt = (keys(%opts))[0];
    if (defined($possoptions{uc($opt)}) || defined($opt = $optposs{$opt}))
    {
        $mod->{'telnetopts'}{uc $opt}{'DO'} = \&empty_callback;
        $mod->{'telnetopts'}{uc $opt}{'DONT'} = \&empty_callback;
    }
#    debug("acceptDoOption: ". Dumper($mod->{'telnetopts'}). "\n");
    $mod->addOption(0, %opts);
}

sub acceptWillOption
{
    # I'll accept WILL option, when the other side wants to do it
    # Add a new option that defaults to 'DO' with no callback
    # Parameter: Object, Active, Option hash
    my ($mod, @opts) = @_;
    my %opts;
    %opts = (@opts == 1 ? (@opts, 1) : @opts);

    my $opt = (keys(%opts))[0];
    if (defined($possoptions{uc($opt)}) || defined($opt = $optposs{$opt}))
    {
        $mod->{'telnetopts'}{uc $opt}{'WILL'} = \&empty_callback;
        $mod->{'telnetopts'}{uc $opt}{'WONT'} = \&empty_callback;
    }
    debug("acceptWillOption: ". Dumper($mod->{'telnetopts'}). "\n");
    $mod->addOption(0, %opts);
}

sub activeDoOption
{
    # I'm  asking the other side to DO option
    # Add a new option that defaults to 'DO' with no callback
    # Parameter: Object, Active, Option hash
    my ($mod, @opts) = @_;
    my %opts;
    %opts = (@opts == 1 ? (@opts, 1) : @opts);

    my $opt = (keys(%opts))[0];
    if (defined($possoptions{uc($opt)}) || defined($opt = $optposs{$opt}))
    {
        $mod->{'telnetopts'}{uc $opt}{'WILL'} = \&empty_callback;
        $mod->{'telnetopts'}{uc $opt}{'WONT'} = \&empty_callback;
        $mod->{'telnetopts'}{uc $opt}{'ACTIVE'} = 1;
    }
#    debug("activeDoOption: ". Dumper($mod->{'telnetopts'}). "\n");
    $mod->addOption(1, %opts);
}

sub activeWillOption
{
    # I WILL do option when requested
    # Add a new option that defaults to 'DO' with no callback
    # Parameter: Object, Active, Option hash
    my ($mod, @opts) = @_;
    my %opts;
    %opts = (@opts == 1 ? (@opts, 1) : @opts);

    my $opt = (keys(%opts))[0];
    if (defined($possoptions{uc($opt)}) || defined($opt = $optposs{$opt}))
    {
        $mod->{'telnetopts'}{uc $opt}{'DO'} = \&empty_callback;
        $mod->{'telnetopts'}{uc $opt}{'DONT'} = \&empty_callback;
        $mod->{'telnetopts'}{uc $opt}{'ACTIVE'} = 1;
    }
    debug("activeWillOption: ". Dumper($mod->{'telnetopts'}). "\n");
    $mod->addOption(1, %opts);
}

sub removeOption
{
    # Remove a set of option responses
    # Parameter: Object, Option
    my ($mod, $opt) = @_;

    if(defined $possoptions{uc($opt)} || defined($opt = $optposs{$opt}))
    {
        if(exists($mod->{'telnetopts'}{uc $opt}))
        {
            delete $mod->{'telnetopts'}{uc $opt};
            return 1;
        }
    }
}

sub doActiveOptions
{
    # Go through the options that are set as active, and not yet negotiated.
    # If passed a socket, send to socket, else option_callback.. 
    # Parameters: Object, Socket?
    my ($mod, $sock) = @_;

    foreach my $opt (keys %{$mod->{'telnetopts'}})
    {
        if($mod->{'telnetopts'}{$opt}{'ACTIVE'})
        {
            if($mod->{'telnetopts'}{$opt}{'WILL'})
            {
                $mod->sendOpt($sock, 'DO', $opt);
            }
            elsif($mod->{'telnetopts'}{$opt}{'DO'})
            {
                $mod->sendOpt($sock, 'WILL', $opt);
            }
        }
    }
}

sub getTelnetOptState
{
    # Return the current state of an option by name/number
    # If not available, assume '0' = dont know this option
    # Parameter: Object, Option
    my ($mod, $opt) = @_;
    $opt = $optposs{$opt} if(!$possoptions{uc $opt});
    return if(!$opt);

    if (exists($mod->{'telnetopts'}{uc($opt)}))
    {
        return $mod->{'telnetopts'}{uc($opt)};
    }
    return 'NONE';
}

# Callback for answers to options? (ie dont pass in socket)

sub answerTelnetOpts
{
    # Answer all telnetoptions and remove from the given stream, 
    # according to settings.
    # Object, Socket (for answers), Data
    my ($mod, $sock, $data) = @_;
    my $pos = -1;
    my $option;

    {
        $data = $mod->{'lastcommand'} . $data;
        $mod->{'lastcommand'} = '';
    }

    while (($pos = index($data, $chIAC, $pos)) > -1)
    {
        #		debug("Found IAC\n");
        my $nextchar = substr($data, $pos + 1, 1);
        if (!length($nextchar))
        {
            $mod->{'lastcommand'} = $chIAC;
            chop($data);
            last;
        }
        if ($nextchar eq $chIAC)
        {
            substr($data, $pos, 1) = '';
            $pos++;
        }
        elsif ($nextchar eq $chDONT or $nextchar eq $chDO or
               $nextchar eq $chWONT or $nextchar eq $chWILL)
        {
            $option = substr($data, $pos + 2, 1);
            if (!length($option))
            {
                $mod->{'lastcommand'} .= $chIAC . $nextchar;
                chop($data);
                chop($data);
                last;
            }
            substr($data, $pos, 3) = '';

            $data = $mod->negotiate_option($sock, $data, $nextchar, ord($option), $pos);
        }
        elsif ($nextchar eq $chSB)
        {
            my $endpos = index($data, $chSE, $pos);
            if ($endpos == -1)
            {
                $mod->{'lastcommand'} .= substr($data, $pos);
                substr($data, $pos) = '';
                last;
            }
            my $subcmd = substr($data, $pos + 2, $endpos - $pos + 1);
            substr($data, $pos, $endpos - $pos + 1) = '';

            $data = $mod->negotiate_suboption($sock, $data, $nextchar, $subcmd, $pos);
        }
#        elsif ($nextchar eq $chEOR)
#        {
#            # extract prompt from datastring
#            # debug("Extracting prompt..\n");
#            $testdata = $mod->{'olddata'} . $data;
#            substr($data, $pos, 2) = '';
#        }
        else                    # Unknown option, delete
        {
            debug("Command: " . $commposs{ord($nextchar)} . "\n");
            substr($data, $pos, 2) = '';
            if($commposs{ord($nextchar)} && 
               $mod->{'telnetopts'}{$commposs{ord($nextchar)}} &&
               (my $coderef = $mod->{'telnetopts'}{$commposs{ord($nextchar)}}{'RAW'}))
            {
                $coderef->($mod->{'olddata'} . $data, $pos+
                           length($mod->{'olddata'}));
            }
        }
    }
    # Add previous data line because of EORs/prompts
    $mod->{'olddata'} = $data;

    return $data;
}

sub negotiate_option
{
    # Given a telnet option found, do the actual answering etc.
    # Parameter: Object, Socket, Data stream, Option Type, Option #, Position 
    my ($mod, $socket, $data, $opt_req, $opt, $optpos) = @_;
    debug("Mud sent option request:" . ord($opt_req) . ":" . $opt . "\n");
    if ($opt_req eq $chDO)
    {
        debug("Do " . $optposs{$opt} . "\n");
        if (exists($mod->{'telnetopts'}{$optposs{$opt}}) &&
            $mod->{'telnetopts'}{$optposs{$opt}}{'DO'})
        {
            if ($mod->{'telnetopts'}{$optposs{$opt}}{'STATUS_ME'} ne 'ASKING')
            {
                print $socket $chIAC . $chWILL . chr($opt);
            }
            $mod->{'telnetopts'}{$optposs{$opt}}{'STATUS_ME'} = 'WILL';
            my $res = $mod->{'telnetopts'}{$optposs{$opt}}{'DO'}->
              ($data, $optpos);
            $data = $res if(defined($res));
        }
        else
        {
            print $socket $chIAC . $chWONT . chr($opt);
        }
    }
    elsif ($opt_req eq $chWILL)
    {
        debug("Will ". $optposs{$opt} . "\n");
        if (exists($mod->{'telnetopts'}{$optposs{$opt}}) &&
            $mod->{'telnetopts'}{$optposs{$opt}}{'WILL'})
        {
            if ($mod->{'telnetopts'}{$optposs{$opt}}{'STATUS_YOU'} ne 'ASKING')
            { 
                print $socket $chIAC . $chDO . chr($opt);
            }
            $mod->{'telnetopts'}{$optposs{$opt}}{'STATUS_YOU'} = 'WILL';
            my $res = $mod->{'telnetopts'}{$optposs{$opt}}{'WILL'}->
              ($data, $optpos);
            $data = $res if(defined($res));
        }
        else
        {
            print $socket $chIAC . $chDONT . chr($opt);
        }
    }
    elsif ($opt_req eq $chWONT)
    {
        debug("Wont " . $optposs{$opt} . "\n");
        if (exists($mod->{'telnetopts'}{$optposs{$opt}}) &&
            $mod->{'telnetopts'}{$optposs{$opt}}{'WONT'})
        {
            if ($mod->{'telnetopts'}{$optposs{$opt}}{'STATUS_YOU'} eq 'ASKING')
            {
                $mod->{'telnetopts'}{$optposs{$opt}}{'STATUS_YOU'} = 'NONE';
                print $socket $chIAC . $chDONT . chr($opt);
            }
            my $res = $mod->{'telnetopts'}{$optposs{$opt}}{'WONT'}->
              ($data, $optpos);
            $data = $res if(defined($res));
        }
        else
        {
            print $socket $chIAC . $chDONT . chr($opt);
        }
    }
    elsif ($opt_req eq $chDONT)
    {
        debug("Wont ". $optposs{$opt} . "\n");
        if (exists($mod->{'telnetopts'}{$optposs{$opt}}) &&
            $mod->{'telnetopts'}{$optposs{$opt}}{'DONT'})
        {
            if ($mod->{'telnetopts'}{$optposs{$opt}}{'STATUS_ME'} eq 'ASKING')
            {
                $mod->{'telnetopts'}{$optposs{$opt}}{'STATUS_ME'} = 'NONE';
                print $socket $chIAC . $chWONT . chr($opt);
            }
            my $res = $mod->{'telnetopts'}{$optposs{$opt}}{'DONT'}->
              ($data, $optpos);
            $data = $res if(defined($res));
        }
        else
        {
            print $socket $chIAC . $chWONT . chr($opt);
        }
    }
    return $data;
}

sub negotiate_suboption
{
    my ($mod, $socket, $data, $opt_req, $cmd, $optpos) = @_;
    my $option = substr($cmd, 0, 1);
    # IAC, SB, TTYPE, SEND, IAC, SE
    debug("Got suboption request:" . ord($opt_req) . " :" . 
          ord($option). "\n");

    debug("Option: ". $optposs{ord($option)}."\n");
    debug(Dumper($mod->{'telnetopts'}{$optposs{ord($option)}})."\n");

    return $data unless(exists($mod->{'telnetopts'}{$optposs{ord($option)}}));

    if($mod->{'telnetopts'}{$optposs{ord($option)}}{'STATUS_ME'} eq 'WILL' || 
       $mod->{'telnetopts'}{$optposs{ord($option)}}{'STATUS_YOU'} eq 'WILL')
    {
        my $coderef = $mod->{'telnetopts'}{$optposs{ord($option)}}{'SB'};
        return $data unless($coderef);
        if (substr($cmd, 1, 1) eq $chSEND)
        {
            my $res = $coderef->('SEND', '', $data, $optpos);
            $data = $res if(defined($res));
        }
        elsif(substr($cmd, 1, 1) eq $chIS)
        {
            my $res = $coderef->('IS', substr($cmd, 1), $data, $optpos);
            $data = $res if(defined($res));
        }
        else
        {
            my $res = $coderef->('SB', $cmd, $data, $pos);
            $data = $res if(defined($res));
        }
    }

    return $data;
}

sub sendOpt
{
    # Request a telnet option direct
    # Parameter: Object, Socket, DO/WILL/DONT/WONT/SB, Option number, suboption
    my ($mod, $socket, $req, $opt, $subopt1, $subopt2) = @_;
    $subopt1 ||='';
    $subopt2 ||='';
    debug("SendOpt: $req, $opt, $subopt1, $subopt2\n");

    if (defined($possoptions{uc($opt)}) || ($opt = $optposs{$opt}))
#    $opt = $optposs{$opt} if(!defined($possoptions{$opt}));
#    return if(!$opt);
    {
        if ($req eq 'WILL')
        {
            if ($mod->{'telnetopts'}{$opt}{'STATUS_ME'} eq 'ASKING' || 
                $mod->{'telnetopts'}{$opt}{'STATUS_ME'} eq 'WILL')
            {
                carp("Already asking $opt.\n");
                return;
            }
            print $socket $chIAC . $chWILL . chr($possoptions{$opt});
            $mod->{'telnetopts'}{$opt}{'STATUS_ME'} = 'ASKING';
        }
        if ($req eq 'WONT')
        {
            if ($mod->{'telnetopts'}{$opt}{'STATUS_ME'} ne 'WILL' &&
                $mod->{'telnetopts'}{$opt}{'STATUS_ME'} ne 'ASKING')
            {
                carp("We're not wanting that anyway!\n");
                return;
            }
            print $socket $chIAC . $chWONT . chr($possoptions{$opt});
            $mod->{'telnetopts'}{$opt}{'STATUS_ME'} = 'NONE';
        }
        if ($req eq 'DO')
        {
            if ($mod->{'telnetopts'}{$opt}{'STATUS_YOU'} eq 'WILL' || 
                $mod->{'telnetopts'}{$opt}{'STATUS_YOU'} eq 'ASKING')
            {
                carp("Already wanting $opt.\n");
                return;
            }
            print $socket $chIAC . $chDO . chr($possoptions{$opt});
            $mod->{'telnetopts'}{$opt}{'STATUS_YOU'} = 'ASKING';
        }
        if ($req eq 'DONT')
        {
            if ($mod->{'telnetopts'}{$opt}{'STATUS_YOU'} ne 'WILL' &&
                $mod->{'telnetopts'}{$opt}{'STATUS_YOU'} ne 'ASKING')
            {
                carp("We're not wanting that anyway!\n");
                return;
            }
            print $socket $chIAC . $chDONT . chr($possoptions{$opt});
            $mod->{'telnetopts'}{$opt}{'STATUS_YOU'} = 'ASKING';
        }
        if ($req eq 'SB')
        {
            debug("Sendopt: $opt, Status: $mod->{telnetopts}{$opt}\n");
            if($mod->{'telnetopts'}{$opt}{'STATUS_YOU'} eq 'WILL' &&
               $subopt1 eq 'SEND')
            {
                print $socket $chIAC . $chSB . chr($possoptions{$opt}) . 
                    $chSEND . $subopt2 . $chIAC . $chSE;
            }
            elsif($mod->{'telnetopts'}{$opt}{'STATUS_ME'} eq 'WILL' &&
                  $subopt1 eq 'IS')
            {
                print $socket $chIAC . $chSB . chr($possoptions{$opt}) . 
                  $chIS . $subopt2 . $chIAC . $chSE;
            }
            elsif($mod->{'telnetopts'}{$opt} && 
                  ($mod->{'telnetopts'}{$opt}{'STATUS_YOU'} eq 'WILL' || 
                   $mod->{'telnetopts'}{$opt}{'STATUS_ME'} eq 'WILL'
                  ))
            {
                print $socket $chIAC . $chSB . chr($possoptions{$opt}) . 
                  $subopt2 . $chIAC . $chSE;
            }
            else
            {
                carp("Option $opt not turned on!\n");
            }
        }
    }
}


sub empty_callback
{
}

sub debug
{
#    ::main::debug(@_);

    print @_, "\n" if($DEBUG);
}

1;

# Deafult 'NONE' means 'WONT' ?
# POD:
# Calls WILL, DO, WONT, DONT, RAW coderefs with $data and $pos
# Calls SB coderef with SEND/IS/SB, Rest, $data, $pos
#
# Active doing/wanting of options.. 

  #
  # Us:   DO   X -- X_YOU = 'ASKING'
  # Them: WONT X
  # If X_YOU eq 'ASKING' -> 'NONE', confirm change of plan with 'DONT X'
  # Else agree 'DONT X' 
  #
  # Them: WILL X
  # if X_YOU eq 'ASKING' -> 'DO', no reply
  # Else if 'WILL X' set, answer 'DO X' 'DO' (we havent requested, but would like)
  # Else refuse 'DONT X'
  #
  # Us:   WILL X -- X_ME = 'ASKING'
  # Them: DONT X
  # If X_ME eq 'ASKING' -> 'NONE', confirm change of plan with 'WONT X'
  # Else agree WONT X
  #
  # Them: DO X
  # If X_ME eq 'ASKING' -> 'WILL', no reply
  # Else if 'DO X' set, answer 'WILL X' (will do) -> 'WILL'
  # Else refuse 'WONT X'




