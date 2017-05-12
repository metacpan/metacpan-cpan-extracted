#!/usr/local/bin/perl
# @(#)Brcd.pm	1.5

package Net::Brcd;

use 5.008;
use Carp;
use Data::Dumper;
use Socket;

use strict;
use constant DEBUG => 0;

use base qw(Exporter);

# Variables de gestion du package
our $VERSION      = 1.13;

# Variables privées
my $_brcd_wwn_re     = join(":",("[0-9A-Za-z][0-9A-Za-z]") x 8);
my $_brcd_port_id    = qr/\d+,\d+/;

sub new {
    my ($class)=shift;

    $class   = ref($class) || $class;
    my $self = {};

    bless $self, $class;
    return $self;
}

sub connect {
    my ($self,$switch,$user,$pass)=@_;

    $user   ||= $ENV{BRCD_USER} || 'admin';
    $pass   ||= $ENV{BRCD_PASS};
    $switch ||= $ENV{BRCD_SWITCH};

    unless ($switch) {
        croak __PACKAGE__,": Need switch \@IP or name.\n";
    }
    unless ($user and $pass) {
        croak __PACKAGE__,": Need user or password.\n";
    }
    $self->{FABRICS}->{$switch} = {};
    $self->{FABRIC}             = $switch;
    $self->{USER}               = $user;

    return $self->proto_connect($switch,$user,$pass);
}

sub proto_connect {
    my ($self,$switch,$user,$pass) = @_;
    
    croak __PACKAGE__, "Error - proto_connect is a virtual function.\n";
}

sub cmd {
    my ($self, $cmd, @cmd)=@_;

    croak __PACKAGE__, "Error - cmd is a virtual function.\n";
}

sub sendcmd {
    my ($self, $cmd, @cmd)=@_;

    croak __PACKAGE__, "Error - sendcmd is a virtual function.\n";
}

sub sendeof {
    my ($self, $cmd, @cmd)=@_;

    croak __PACKAGE__, "Error - sendeof is a virtual function.\n";
}

sub readline {
    my ($self, $arg_ref) = @_;
    
    croak __PACKAGE__, "Error - readline is a virtual function.\n";
}

sub cfgSave {
    my $self = shift;
    my %args = (
        -verbose => 0,
        @_,
    );
    my @rc   = $self->cmd('cfgSave');
    
    my $rc = '';
    SWITCH: {
        DEBUG && warn "DEBUG:cfgsave", Dumper(\@rc);
        unless (@rc) {
            last SWITCH;
        }
        if ($args{-verbose}) {
            warn join("\n", @rc), "\n";
        }
        $rc   = pop @rc;
        return 1 if ($rc =~ m/Nothing/i); # Pas de modif 
        return 1 if ($rc =~ m/Updating/i); # Update fait
    }
    
    croak "Error - Cannot save current configuration: $rc.\n";
}

sub aliShow {
    my $self=shift;

    my %args=(
          -bywwn    =>  0,
          -byport   =>  0,
          -cache    =>  0,
          -onlywwn  =>  1,
          -filter   =>  '*',
          @_
          );

    my $fab_name = $self->{FABRIC};
    my $fab      = $self->{FABRICS}->{$fab_name};
    $args{-onlywwn} = 0 if $args{-byport};

    my ($alias);
    $fab->{PORTID} = {};
    $fab->{WWN}    = {};
    $fab->{ALIAS}  = {};
    foreach ($self->cmd('aliShow "' . $args{-filter} . '"')) {
        next unless $_;
        if (m/alias:\s+(\w+)/) {
            $alias=$1;
            next;
        }
        if ($alias && m/${_brcd_wwn_re}/) {
            s/^\s*//; # on enleve les blancs de devant
            DEBUG && warn "DEBUG: aliShow: $alias: $_\n";
            my @wwn_for_alias = split m/\s*;\s*/;
            foreach my $wwn (@wwn_for_alias) {
                $fab->{WWN}->{$wwn}     = $alias;
            }
            if (exists $fab->{ALIAS}->{$alias}) {
                my $old_alias_value = $fab->{ALIAS}->{$alias};
                unless (ref $old_alias_value) {
                    $fab->{ALIAS}->{$alias} = [$old_alias_value];
                }
                push @{$fab->{ALIAS}->{$alias}}, @wwn_for_alias;
            } else {
                $fab->{ALIAS}->{$alias} = (@wwn_for_alias == 1) ? $wwn_for_alias[0]
                                                                : \@wwn_for_alias;
            }
           
            next;
        }
        
        next if $args{-onlywwn};
        
        if ($alias && m/(${_brcd_port_id})/) {
            my $port_id = $1;
            $fab->{PORTID}->{$port_id} = $alias;
            $fab->{ALIAS}->{$alias}    = $port_id;
            next;
        }
    }
    #}
    DEBUG && warn "DEBUG:zone.?:", Dumper($fab);

    return ($args{'-bywwn'})  ? (%{$fab->{WWN}})    :
           ($args{'-byport'}) ? (%{$fab->{PORTID}}) :                  
                                (%{$fab->{ALIAS}});
}

sub zoneShow {
    my $self = shift;

    my %args = (
          -bymember => 0,
          -cache    => 0,
          -filter   => '*',
          @_
          );

    my $fab_name = $self->{FABRIC};
    my $fab      = $self->{FABRICS}->{$fab_name};

    my ($zone);
    foreach ($self->cmd('zoneShow "' . $args{-filter} . '"')) {
        DEBUG && warn "DEBUG:CMDDUMP: $_\n";
        if (m/zone:\s+(\w+)/) {
            $zone = $1;
            next;
        }
        if ($zone && m/\s*(\w[:\w\s;]+)/) {
            my $members = $1;
            my @member  = split m/;\s+/, $members;

            foreach my $member (@member) {
                $fab->{ZONE}->{$zone}->{$member}++;
                $fab->{MEMBER}->{$member}->{$zone}++;
            }
        }
    }
    
    unless ($fab->{MEMBER} and $fab->{ZONE}) {
        croak "Warning - Empty zone.\n";
    }

    if (wantarray()) {
        return ($args{'-bymember'})?(%{$fab->{MEMBER}}):(%{$fab->{ZONE}});
    }
}

sub zoneMember {
    my ($self, $zone)=@_;

    my $fab_name = $self->{FABRIC};
    my $fab      = $self->{FABRICS}->{$fab_name};

    return unless exists $fab->{ZONE}->{$zone};

    return sort keys %{$fab->{ZONE}->{$zone}};
}

sub memberZone {
    my ($self,$member)=@_;

    my $fab_name = $self->{FABRIC};
    my $fab      = $self->{FABRICS}->{$fab_name};

    return unless exists $fab->{MEMBER}->{$member};

    return sort keys %{$fab->{MEMBER}->{$member}};
}

sub switchShow {
    my $self=shift;

    my %args=(
          -bywwn        => 0,
          -withportname => 0,
          -byslot       => 0,
          @_
          );

    my $fab_name = $self->{FABRIC};
    my $fab      = $self->{FABRICS}->{$fab_name};

    my (%wwn);
    foreach ($self->cmd("switchShow")) {
        next unless $_;
DEBUG && warn  "SWITCHSHOW   : $_\n";
        if (m/^(\w+):\s+(.+)/) {
            $fab->{$1} = $2;
            next;
        }
#12000 :  0    1    0   id    2G   Online    E-Port  (Trunk port, master is Slot  1 Port
#48000 : 13    1   13   0a0d00   id    N2   Online           F-Port  10:00:00:00:c9:35:99:4b
#48000 : 12    1   12   0a0c00   id    N4   No_Light
#4100  :       0   0            id    2G   Online    E-Port  10:00:00:05:1e:35:f6:e5 "PS4100A"       
#5100  :       0   0   010000   id    N4   Online      FC  F-Port  50:0a:09:81:98:4c:a8:9d
#5100  :       1   1   010100   id    N4   No_Light    FC  
#3800  : port  0: id 2G Online         F-Port 50:06:01:60:10:60:04:26
      
        if (m{
            ^[port\s]*(\d+):? \s*     # Le port number forme ok:port 1: ; 12;144
            (?:
                (?:
                  (\d{1,3})\s+        # Le slot que sur les directeurs
                )?
                (\d{1,3})             # Le port dans le slot
                \s*              
                (
                [0-9a-zA-Z]
                [0-9a-zA-Z]
                [0-9a-zA-Z]
                [0-9a-zA-Z]
                [0-9a-zA-Z]
                [0-9a-zA-Z]
                )?              # Adresse FC, qu'à partir de FabOS 5.2.0a
            )?
            \s+ [i-][d-] \s+             # Le mot magique qui dit que c'est la bonne ligne
            [a-zA-Z]*(\d+)[a-zA-Z]*  \s+ # Vitesse du port plusieurs format à priori toujours en Go/s
            (\w+)  \s*                   # Status du port
            (.*)                         # Toutes les autres informations (notamment le WWN si connectés)
        }mxs) {
DEBUG && warn  "SWITCHSHOW-RE: #$1# #$2# #$3# #$4# #$5# #$6# #$7#\n";
            # Récupération des champs, les champs dans les même ordre que les $
            my @fields = qw(SLOT NUMBER ADDRESS SPEED STATUS INFO);              
            my $port_number  = $1;
            my $port_info    = $7;  
            foreach my $re ($2, $3, $4, $5, $6, $7) {
                my $field = shift @fields;
                if (defined $re) {
                    $fab->{PORT}->{$port_number}->{$field} = $re;
                }
            }
            $fab->{PORT}->{$port_number}->{PORTNAME} = $self->portShow($port_number) if $args{-withportname};
            $fab->{SLOTN}->{
                (($fab->{PORT}->{$port_number}->{SLOT}) ? $fab->{PORT}->{$port_number}->{SLOT} . '/'
                :                                        "")
                . $fab->{PORT}->{$port_number}->{NUMBER}
            }->{PORT} = $port_number;

            if ($port_info and $port_info =~ m/^(\w-\w+)\s+(${_brcd_wwn_re})?/) {
                my ($type, $wwn) = ($1,$2);
                $fab->{PORT}->{$port_number}->{TYPE} = $type;
                $fab->{PORT}->{$port_number}->{WWN}  = $wwn   if $wwn;
                

                if ($type eq "F-Port") {
                    $wwn{$wwn} = $port_number;
                }
            }
        } else {
            DEBUG && warn "DEBUG:???? >>$_<<\n";
        }
    }

    return   ($args{'-bywwn'})       ? %wwn
           : ($args{'-byslot'})      ? %{$fab->{SLOTN}}
           : (exists $fab->{PORT})   ? %{$fab->{PORT}}
           :                           undef;
}

sub toSlot {
    my $self        = shift;
    my $port_number = shift;
    
    my $fab_name = $self->{FABRIC};
    my $fab      = $self->{FABRICS}->{$fab_name};

DEBUG && warn "TOSLOT: $port_number\n";
    
    unless (exists $fab->{PORT}->{$port_number}) {
        $@ = __PACKAGE__.":toSlot: port number $port_number does not exist\n";
        
DEBUG && warn "$@\n";

        return;
    }
    unless (exists $fab->{PORT}->{$port_number}->{SLOT}) {
    
        $@ = __PACKAGE__.":toSlot: port number $port_number is not a director\n";
DEBUG && warn "$@\n";

        return;
    }
    
DEBUG && warn "TOSLOT: ",$fab->{PORT}->{$port_number}->{SLOT}."/".$fab->{PORT}->{$port_number}->{NUMBER},"\n";

    return (wantarray())?($fab->{PORT}->{$port_number}->{SLOT},$fab->{PORT}->{$port_number}->{NUMBER}):
                          $fab->{PORT}->{$port_number}->{SLOT}."/".$fab->{PORT}->{$port_number}->{NUMBER};
}

sub portShow {
    my $self        = shift;
    my $port_number = shift;

    my $fab_name = $self->{FABRIC};
    my $fab      = $self->{FABRICS}->{$fab_name};
    
DEBUG && warn "PORTSHOW-PORTNUMBER:test: $port_number\n";
    $port_number = $self->toSlot($port_number) || $port_number;
DEBUG && warn "PORTSHOW-PORTNUMBER:set: $port_number\n";
    my (%port, $param, $value, $portname);
    
    no warnings;
    foreach ($self->cmd("portShow $port_number")) {    
DEBUG && warn "PORTSHOW:parse: $_\n";

        if (m/^([\w\s]+):\s+(.+)/) {
            $param        = $1;
            $value        = $2;
            
DEBUG && warn "PORTSHOW: param #$param# value #$value#\n";
            
            $port{$param} = $value;
            SWITCH: {
                if ($param eq 'portName') {
                    $fab->{SLOTN}->{$port_number}->{PORTNAME} = $value;
                    $portname                                 = $value;
                    last SWITCH;
                }
            }
            next;
        }
        
        if (m/^([\w\s]+):\s*$/) {
            $param = $1;
            next;
        }
        
        if (m/^\s+(.+)/) {
            $port{$param} = $1;
            next;
        }
    }
    use warnings;

    return (wantarray())?(%port):($portname);
}

sub output {
    my $self=shift;

    return join("\n",@{$self->{OUTPUT}})."\n";
}

sub wwn_re {
    return ${_brcd_wwn_re};
}

sub fabricShow {
    my $self=shift;
    my %args=(
          -bydomain        => 0,
          @_
          );
    my (%fabric,%domain);
    
    foreach ($self->cmd('fabricShow')) {
        next unless $_;
DEBUG && warn "DEBUG:: $_\n";
        if (m{
            ^\s* (\d+) : \s+ \w+ \s+  # Domain id + identifiant FC
            ${_brcd_wwn_re} \s+       # WWN switch
            (\d+\.\d+\.\d+\.\d+) \s+  # Adresse IP switch
            \d+\.\d+\.\d+\.\d+   \s+  # Adresse IP FC switch (FCIP)
            (>?)"([^"]+)              # Master, nom du switch
        }msx) {
            my ($domain_id, $switch_ip, $switch_master, $switch_name) = ($1, $2, $3, $4);
            my $switch_host = gethostbyaddr(inet_aton($switch_ip), AF_INET);
            my @fields      = qw(DOMAIN IP MASTER FABRIC NAME MASTER);
            foreach my $re ($domain_id, $switch_ip, $switch_master, $switch_host, $switch_name) {
                my $field = shift @fields;
                if ($re) {
                    $domain{$domain_id}->{$field}   = $re;
                    $fabric{$switch_name}->{$field} = $re;
                } 
            }
            
            $fabric{$switch_host} = $switch_name if $switch_host;
        }
    }
    
    return ($args{-bydomain}) ? (%domain) :
                                (%fabric);
}

sub currentFabric {
    my $self = shift;
    
    return $self->{FABRIC};
}


sub isWwn {
    my $self = shift;    
    my $wwn = shift;
    
    ($wwn =~ m/^${_brcd_wwn_re}/)?(return 1):(return);
    
}

sub portAlias {
    my $self = shift;
    my $port_alias = shift;
    
    if ($port_alias =~ m/(\d+),(\d+)/){
        return ($1, $2);
    }
    return;
}

sub rename {
    my ($self, $old_zone_object, $new_zone_object) = @_;
    
    unless ($old_zone_object and $new_zone_object) {
        croak "Error - Need old and new name.\n";
    }
    
    return $self->cmd("zoneObjectRename $old_zone_object, $new_zone_object");
}

sub _zoning_cmd {
    my ($self, $cmd_name, $zone_object, @cmd_args) = @_;
    
    unless ($cmd_name) {
        croak "Error - Need command name.\n";
    }
    unless ($zone_object) {
        croak "Error - Need object name.\n";
    }
    
    my $cmd = "$cmd_name $zone_object";
    my $str_args;
    if (@cmd_args == 1) {
        $str_args = shift @cmd_args;
        if (ref $str_args eq 'ARRAY') {
            $str_args = join(';', @{$str_args});
        }
    } elsif (@cmd_args) {
        $str_args = join(';', @{$str_args});
    }
    if ($str_args) {
        $cmd .= ", \"$str_args\"";
    }
    
    return $self->cmd($cmd);
}

sub _build_cmd_name {
    my ($prefix, $args_ref) = @_;
    
    my @exclude = (
        '^-name',
        '^-members',
    );
    my $action;
    ARG_CMD: foreach my $arg (keys %{$args_ref}) {
        next unless ($args_ref->{$arg});
        foreach my $exclude (@exclude) {
            if ($arg =~ m/$exclude/) {
                next ARG_CMD;
            }
        }
        $arg    =~ s/^[-]*//;
        $action = $arg;
    }
    unless ($action) {
        croak "Error - cannot find action.\n";
    }
    
    return $prefix . $action;
}

sub zone {
    my $self = shift;
    
    my %args = (
        -create  => 0,
        -add     => 0,
        -delete  => 0,
        -remove  => 0,
        -name    => "",
        -members => "",
        @_,
    );
    my $cmd_name = _build_cmd_name('zone', \%args);
     
    return $self->_zoning_cmd($cmd_name, $args{-name}, $args{-members});
}

sub ali {
    my $self = shift;
    
    my %args = (
        -create  => 0,
        -add     => 0,
        -delete  => 0,
        -remove  => 0,
        -name    => "",
        -members => "",
        @_,
    );
    my $cmd_name = _build_cmd_name('ali', \%args);
 
    DEBUG && warn "DEBUG:ALI:", Dumper($cmd_name, \%args);

    return $self->_zoning_cmd($cmd_name, $args{-name}, $args{-members});
}


1;

__END__

=pod

=head1 NAME

Net::Brcd - Perl libraries to contact Brocade switch

=head1 SYNOPSIS

    #use Net::<Proto>::Brcd;
    use Net::Telnet::Brcd;
    
    #my $sw = new Net::<Proto>::Brcd;
    #Example :
    my $sw = new Net::Telnet::Brcd;
    
    $sw->connect($sw_name,$user,$pass) or die "\n";
    
    %wwn_port = $sw->switchShow(-bywwn=>1);
    my @lines = $sw->cmd("configShow");

=head1 DESCRIPTION

Perl libraries to contact Brocade switch. You could set this
environment variable to simplify coding:

=over 4

=item C<BRCD_USER>

login name

=item C<BRCD_PASS>

login password

=item C<BRCD_SWITCH>

switch name or IP address

=back

This module should not be call directly. You have to choose <Proto> for your
communication.

=head1 FUNCTIONS

=head2 new

    my $brcd = new Net::<Proto>::Brcd;
    # For instance <Proto> = Telnet

Initialize Brocade object. No arguments needed.

=head2 connect

    $brcd->connect($switch,$user,$pass);

Connect to a Brocade switch. The command exit if an error
occured. 

B<Do it before any switch command>.

One object is required for each connection. If you want simultaneous connection
you need several objects.

=head2 cmd

    my @results = $brcd->cmd("configShow");
    my $ok      = $brcd->cmd("cfgsave");

This function is used to send command to a brocade switch. And implement 
differents features:

=over

=item *

The command tracks the continue question and answer 'yes'.
The goal of this module is to be used in silent mode.

=item *

The Brocade command answer is returned without carriage return (no \r \n).

=item *

Two methods is used to give parameters.

scalar: The string command is sent as is.

array: The command thinks that the first element is a command, the second
the principal arguments and other members. It is very useful for ali* command.

=back

Examples :

    my @results=$brcd->cmd("aliAdd","toto",":00:00:0:5:4:54:4:5");
    aliAdd "toto", "00:00:0:5:4:54:4:5"

The command does not decide that the command answer is an error or not. It just
store the stdout of the brocade command and return it in a array.

=head2 sendcmd

    my $rc = $brcd->sendcmd("portperfshow");

This function execute command without trap standard output. It's useful for 
command that needs to be interrupted.

You have to use the C<readline> function to read each line generated by the command.

=head2 sendeof

    my $rc = $brcd->sendeof();

Send Ctrl-D command to interrupt command (useful for portperfshow).

=head2 readline

    while (my ($str) = $brcd->readline()) {
        # Do what you want with $str
    }

Read output as piped command. You have a to decided when to stop (If the line 
content a prompt, I return undef).

    $brcd->readline({Timeout => 60});

You have to set argument with a hash ref.

=head2 aliShow

    my %alias_to_wwn = $brcd->aliShow();

Send command C<aliShow "*"> and return a hash. Some option, change the content
of the returned hash :

=over 1

=item default

Without option : return key = alias, value = WWN. 

B<Be carefull !!> If one alias contains multiple WWN, value is a ref array of 
all the WWN member.

=item -onlywwn

With option -onlywwn => 1 (default option) : does not return alias with port 
naming. Disable this option (-onlywwn => 0), if you want both.

=item -filter

By default, -filter is set to '*'. You could use an other filter to select
specific alias. Recall of rbash regular expression, you could use in filter :

=over 2

=item *

Any character.

=item ?

One character.

=item [..]

Character class. For instance a or b => [ab]

=item Examples

    -filter => '*sv*'
    -filter => 'w_??[ed]*'

=back

=item -bywwn

With option -bywwwn => 1, return key = WWN, value = alias

    my %wwn_to_alias = $brcd->aliShow(-bywwn => 1);

=item -byport

With option -byport => 1, return key = port, value = alias

=back

=head2 zoneShow

    my %zone = $brcd->zoneShow();

Return a hash with one key is a zone and value an array of alias member or WWN or ports.

    my %zone = $brcd->zoneShow();

    foreach my $zone (%zone) {
        print "$zone:\n\t";
        print join("; ", keys %{$zone{$zone}} ),"\n";
    }

=over *

=item -bymember => 1

If you set option C<< -bymember => 1 >>, you have a hash with key a member and value an array of
zones where member exists.

=item -filter   => '*'

By default, select all zone but you could set a POSIX filter for your zone.

=back

It's important to run this command before using the followings functions.

=head2 zoneMember

    my @member = $brcd->zoneMember("z_sctxp004_0");

Return an array of member of one zone. Need to execute C<< $brcd->zoneShow >> before.

=head2 memberZone

    my @zones = $brcd->memberZone("w_sctxp004_0");

Return an array of zones where member exist. Need to execute C<< $brcd->zoneShow >> before.

=head2 switchShow

    my %port = $brcd->switchShow();

This function send the switchShow command on the connected switch (see only one switch
not all the fabric). It returns the following structure:

    $port{port number}->{SPEED}  = <2G|1G|...>
                      ->{STATUS} = <OnLine|NoLight|...>
                      ->{SLOT}   = blade number
                      ->{NUMBER} = port number on blade
                      ->{TYPE}   = <E-Port|F-Port|...>
                      ->{WWN}    if connected

If you set C<-bywwn=1>, it's return only a hash of WWN as key and port number as value.

    my %wwn_to_port = $brcd->switchShow(-bywwn => 1);

If you set C<-withportname=1>, the portName command is execute on each port of the switch to get the portname.

If you set C<-byslot=1>, it's return only a hash of slot/number as key and portname and port number 
as value.

=head2 toSlot

    my ($slot,$slot_number) = $brcd->toSlot(36);
    my $slot_address        = $brcd->toSlot(36);

The function need to have an execution of C<< $brcd->switchShow >>. It's usefull for
a Director Switch to have the translation between absolute port number and slot/port number value.

If you use it in scalar context, the command return the string C<slot/slot_number> (portShow format).

=head2 portShow

    my %port     = $brcd->portShow($port_number);
    my $portname = $brcd->portShow($port_number);

Need to have running the C<< $brcd->switchShow >> command. The function use the C<toSlot>
function before sending the portShow command.

In array context, function return a hash with key as the portName. In scalar context returns the
portname.

=head2 output

    print $brcd->output();

Return the last function output.

=head2 wwn_re

    my $wwn_re = $brcd->wwn_re();

    if (m/($wwn_re)/) {
        ...
    }

Return the WWN re.

=head2 fabricShow

    my %fabric = $brcd->fabricShow();

Return a hash with all the switch in the fabric. Return the result byswitch name C<-byswitch> or
C<-bydomain=1>.

=head2 currentFabric

    my $dns_fabric = $brcd->currentFabric();

Return the current fabric NAME.

=head2 isWwn

    if ($brcd->isWwn($str)) {
        ...
    }

Test a string to check if it is a WWN.

=head2 portAlias

    my ($domain, $port_number) = $brcd->portAlias("199,6");

Split a string whith zoning format in domain and port number in the switch.

=head2 cfgSave

    my $boolean = $brcd->cfgSave();
    
The function execute cfgSave command an return true if ok or exit. You can trap
this exception whith C<eval {};> block. Error message always begin with C<Error - >.

=head2 zone

    my @rc = $brcd->zone(
        -add     => 1,
        -name    => 'z_toto1',
        -members => '10:00:00:00:C9:3D:F3:04',
    );
        
    my @rc = $brcd->zone(
        -add     => 1,
        -name    => 'z_toto2',
        -members => [
            '10:00:00:00:C9:3D:F3:04',
            '10:00:00:00:C9:48:08:E2',
        ],
    );

Supported sub commmand are -add, -create, -delete, -remove.

=head2 ali

    my @rc = $brcd->ali(
        -create  => 1,
        -name    => 'w_toto1',
        -members => '10:00:00:00:C9:51:FB:29',
    );
        
    my @rc = $brcd->ali(
        -add     => 1,
        -name    => 'w_toto2',
        -members => [
            '10:00:00:00:C9:46:D8:FD',
            '10:00:00:00:C9:46:DA:A7',
        ],
    );
    
    my @rc = $brcd->ali(
        -add     => 1,
        -name    => 'w_toto3',
        -members => [
            '10:00:00:00:C9:46:D5:B7',
        ],
    );

Supported sub commmand are -add, -create, -delete, -remove.

=head1 SEE ALSO

Brocade Documentation, BrcdAPI, Net::Telnet::Brcd(3).

=head1 BUGS

...

=head1 AUTHOR

Laurent Bendavid, E<lt>lbendavid@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Laurent Bendavid

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=over

=item Version

1.5

=item History

Created 6/27/2005, Modified 7/3/10 22:13:07

=back

=cut
