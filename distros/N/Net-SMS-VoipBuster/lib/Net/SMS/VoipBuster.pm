package Net::SMS::VoipBuster;

use strict;
use warnings;
use LWP::UserAgent;
use XML::XPath;
use XML::XPath::XMLParser;
use Carp;

our $VERSION = '0.04';

sub new {
    my $class    = shift;
    my $user     = shift;
    my $password = shift;
    
    croak("Please insert an user.")     unless ($user);
    croak("Please insert an password.") unless ($password);

    my $self     = bless {
        'user' => $user, 
        'pass' => $password 
    }, $class;

    return $self;
}

sub send {
    my $self = shift;
    my $msg  = shift;
    my $to   = shift;

    croak("Please insert an message.")           unless ($msg);
    croak("Please insert number to destination") unless($to);

    my $ua = LWP::UserAgent->new;
    #$ua->timeout(10);
    #$ua->env_proxy;

    my $send_url = $ua->get("https://www.voipbuster.com/myaccount/sendsms.php?username=$self->{'user'}&password=$self->{'pass'}&from=$self->{'user'}&to=$to&text=$msg");
    
    my $result = $send_url->content;

    $result =~ s/^(?:\s+)(.*)(?:\s+)$/$1/gm; # Thanks Manuel Silva ;)

    my $xp = XML::XPath->new( 'xml' => $result );
    my $nodeset = $xp->find('//result');

    my $check;
    foreach my $node ($nodeset->get_nodelist) {
        $check =  XML::XPath::XMLParser::as_string($node);
        $check =~ s/<[^>]*>//gs;

        if ($check) {
            return $self->{'success'} = 1;
        } else {
            my $error = {
                'error'    => $send_url->status_line,
                'is_error' => '1',
            };
            return $self->{'error'} = $error;
        }
    }
}

sub extra {
    my $self = shift;
    my $extra = "To my Mom. Maria Luisa Mesquista (1954 - 2007)";

    return $self->{'extra'} = $extra;
}

1;
__END__

=head1 NAME

Net::SMS::VoipBuster - Send SMS from VoipBuster

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

  use Net::SMS::VoipBuster;

  my $c = Net::SMS::VoipBuster->new($user, $pass);

  my $res = $c->send($msg, $to);


=head1 FUNCTIONS

=head2 new

Creates a new Net::SMS::VoipBuster object.

  my $c = Net::SMS::VoipBuster->new($user, $pass);

=head2 send

  my $res = $c->send($msg, $to);

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMS::VoipBuster

=head1 AUTHOR

Filipe Dutra, C<< <mopy at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Filipe Dutra

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
