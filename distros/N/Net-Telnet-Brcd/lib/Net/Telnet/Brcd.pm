#!/usr/local/bin/perl
# @(#)Brcd.pm	1.12

package Net::Telnet::Brcd;

use 5.008;
use Net::Telnet;
use Carp;
use Data::Dumper;
use Socket;

use strict;
use constant DEBUG => 0;

use base qw(Net::Brcd Exporter);

# Variables de gestion du package

our $VERSION      = 1.13;

# Variables privées
my $_brcd_prompt     = '\w+:\w+>\s+';
my $_brcd_commit     = 'yes, y, no, n';
my $_brcd_continue   = 'Type <CR> to continue, Q<CR> to stop:';
my $_brcd_prompt_re  = "/(?:${_brcd_prompt}|${_brcd_continue}|${_brcd_commit})/";
my $_brcd_timeout    = 20; # secondes

sub new {
    my ($class)=shift;

    my $self  = $class->SUPER::new();
    bless $self, $class;
    return $self;
}

sub proto_connect {
    my ($self, $switch, $user, $pass) = @_;
    
    my $proto = new Net::Telnet (Timeout => ${_brcd_timeout},
                                 Prompt  => "/${_brcd_prompt}/",
                                 );
    $proto->errmode("return");
    unless ($proto->open($switch)) {
        croak __PACKAGE__,": Cannot open connection with '$switch': $!\n";
    }
    unless ($proto->login($user, $pass)) {
        croak __PACKAGE__,": Cannot login as $user/*****: $!\n";
    }
    $self->{PROTO} = $proto;
    
    # Retourne l'objet TELNET
    return $proto;
}


sub cmd {
    my ($self, $cmd, @cmd)=@_;
    
    DEBUG && warn "DEBUG: $cmd, @cmd\n";
    
    my $proto = $self->{PROTO} or croak __PACKAGE__, ": Error - Not connected.\n";
    
    if (@cmd) {
        $cmd .= ' "' . join('", "', @cmd) . '"';
    }
    $self->sendcmd($cmd);
    #sleep(1); # Temps d'envoi de la commande

    # Lecture en passant les continue
    @cmd = ();
    CMD: while (1) {
       my ($str, $match) = $proto->waitfor(${_brcd_prompt_re});

       DEBUG && warn "DEBUG:: !$match!$str!\n";
       push @cmd, split m/[\n\r]+/, $str;
       if ($match eq ${_brcd_commit}) {
            $proto->print('yes');
            next CMD;
       }
       if ($match eq ${_brcd_continue}) {
          $proto->print("");
          next CMD;
       }
       last CMD;
    }
    @cmd = grep {defined $_} @cmd;

    $self->{OUTPUT} = \@cmd;

    return @cmd;
}

sub sendcmd {
    my ($self, $cmd) = @_;
    
    my $proto = $self->{PROTO} or croak __PACKAGE__, ": Error - Not connected.\n";
    
    DEBUG && $proto->dump_log("/tmp/telnet.log");
    DEBUG && warn "Execute: $cmd\n";
    
    unless ($proto->print($cmd)) {
        croak __PACKAGE__,": Cannot send '$cmd': $!\n";
    }
    return 1;
}

sub sendeof {
    my ($self) = @_;
    
    my $proto = $self->{PROTO} or croak __PACKAGE__, ": Error - Not connected.\n";

    unless ($proto->print("\cD")) {
        croak __PACKAGE__,": Cannot Ctrl-D: $!\n";
    }
    return 1;
}

sub readline {
    my ($self, $arg_ref) = @_;  

    #my ($str, $match) = $proto->waitfor(m/^\s+/);
    my $proto = $self->{PROTO} or croak __PACKAGE__, ": Error - Not connected.\n";
    #DEBUG && warn "DEBUG:: <$str>:<$match>\n";
    #return $str;
    my $str = $proto->getline(($arg_ref?%{$arg_ref}:undef));
    if ($str =~ m/{_brcd_prompt_re}/) {
        return;
    }
    return $str;
}

sub DESTROY {
    my $self = shift;

    $self->{PROTO}->close() if exists $self->{PROTO};
}


1;

__END__

=pod

=head1 NAME

Net::Telnet::Brcd - Contact BROCADE switch with TELNET

=head1 SYNOPSIS

    use Net::Telnet::Brcd;
    
    my $sw = new Net::Telnet::Brcd;
    
    $sw->connect($sw_name,$user,$pass) or die "\n";
    
    %wwn_port = $sw->switchShow(-bywwn=>1);
    my @lines = $sw->cmd("configShow");

=head1 DESCRIPTION

This library part is the implementation of BROCADE command with TELNET.  The
general DOCUMENTATION could be read in Net::Brcd(3) module.

=head2 How to implement interface for a specific network PROTOCOL

Youre parent module is Net::Brcd.

    use base qw(Net::Brcd Exporter ...);

You have to code the methods :

=over

=item $obj = Net::<Proto>::Brcd->new();

    sub new {
        my ($class)=shift;

        my $self  = $class->SUPER::new();
        bless $self, $class;
        return $self;
    }

This method is a relay to the new function of Net::Brcd.

=item $ok_no_ok = $obj->proto_connect($ip_switch, $user, $pass);

This method is used in the connect function of Net::Brcd. You could store 
youre specific parameter in object $obj->{PROTO}.

=item @res = $obj->cmd($cmd);

Execute $cmd and return res as ARRAY without \r\n. The command have 
to send automatically the command continue (space character) and answer
yes for question to be silent as possible.

=item $obj->sendcmd($cmd);

Execute $cmd without wait for response.

=item $obj->sendeof();

Stop current command.

=item $obj->readline();

Read line by line the answer. Return undef for the last line.

=back

=head1 SEE ALSO

Brocade Documentation, BrcdAPI, Net::Telnet(3), Net::Brcd(3).

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

1.12

=item History

Created 6/27/2005, Modified 7/3/10 22:04:20

=back

=cut
