package Net::SMS::WorldText;

use strict;
use warnings;

use Carp qw(confess);
use LWP::UserAgent;
use URI::Escape;

our $VERSION = "1.3";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT;

our %errhash = (
    ARGUMENTS     => "Wrong number of arguments",
    AUTHORISATION => "Login/password incorrect",
    BLACKLISTED   => "Blacklisted MSISDN",
    CREDIT        => "Not enough credit",
    DESTINATION   => "Incorrect MSISDN",
    DISABLED      => "Account suspended, contact support",
    EXCEPTION     => "Internal Server Error",
    INTERNAL      => "Internal routing error, please retry",
    INVALIDARGS   => "Invalid arguments",
    KEYEXPIRED    => "Authentication key expired",
    MESSAGEID     => "Invalid or blank message id",
    SOURCEADDR    => "Unallocated source address",
    SUBMITRESP    => "Incorrect SMPP response received, please retry",
    TIMEOUT       => "SMPP request timed out, please retry",
    THROTTLED     => "Request throttled, retry in 20 seconds",
    UNKNOWNCMD    => "Unknown command",
    VERSION       => "Incorrect interface version specified",
    SQL           => "Number already exists in group", # Guessing, based on trying to add a number twice
);

sub new {
    my ($class, %opts) = @_;
    my $self = {
        user => $opts{user},
        pass => $opts{pass},
        proxyapi => $opts{proxyapi},
        baseurl => $opts{proxyapi} ? 
            'https://www.world-text.com/proxyapi/' :
            'https://sms.world-text.com:1082/',
        ua => LWP::UserAgent->new,
    };
    return bless($self, $class);
}

sub __request {
    my ($self, $request, %args) = @_;
    if($request !~ /authkey|ping/) {
        $args{user} = $self->{user};
        $args{pass} = $self->{pass};
    }
    if(exists $args{dstaddr}) {
        $args{dstaddr} =~ s/[^0-9,]//g;
    }
    my $req = HTTP::Request->new("POST" => $self->{baseurl} . $request);
    $req->content_type('application/x-www-form-urlencoded');
    if(%args) {
        $req->content(join('&', map { sprintf("%s=%s", $_, uri_escape($args{$_})) } keys(%args)));
    }
    my $res = $self->{ua}->request($req);
    if(!$res->is_success) {
        confess("HTTP request to WorldText failed: " . $res->status_line);
    }
    my $content = $res->content;
    $content =~ s/^\s*(.*?)\s*$/$1/s;
    if($content =~ /^FAIL (.*)/s) {
        my $err = $errhash{$1} || $1;
        confess "API request failed: $err";
    }
    if($content =~ /SUCCESS (.*)/s) {
        return $1;
    }
    return $content;
}

sub ping {
    my ($self) = @_;
    $self->__request("ping");
}

sub credits {
    my ($self) = @_;
    $self->__request("credits");
}

sub send {
    my ($self, %opts) = @_;
    my $dest = delete $opts{dest};
    $dest = join(',', ref($dest) ? @$dest : ( $dest, ));
    my $ret = $self->__request("sendsms", txt=>delete $opts{message}, dstaddr=>$dest, %opts);
    $ret =~ s/SUCCESS //g;
    my @ret;
    for my $line (split /\r\n/, $ret) {
        my @line = split / /, $line;
        push @ret, \@line;
    }
    return \@ret;
}

sub query {
    my ($self, $msgid) = @_;
    return $self->__request("querysms", msgid=>$msgid);
}

sub group {
    my ($self, $group) = @_;
    return Net::SMS::WorldText::Group->new($self, $group);
}

sub create_group {
    my ($self, %opts) = @_;
    return Net::SMS::WorldText::Group->create($self, $opts{name}, $opts{srcaddr}, $opts{pin});
}

sub __normalize {
    my ($number) = @_;
    $number =~ s/[^0-9]//g;
}
    
1;

package Net::SMS::WorldText::Group;

use strict;
use warnings;

sub new {
    my ($class, $wt, $group) = @_;
    my $self = {
        wt => $wt,
        grpid => $group,
    };
    return bless($self, $class);
}

sub create {
    my ($class, $wt, $name, $srcaddr, $pin) = @_;
    $name = substr($name, 0, 20);
    my $grpid = $wt->__request("groupcreate", name=>$name, srcaddr=>$srcaddr, pin=>$pin);
    return $class->new($wt, $grpid);
}

sub add {
    my ($self, $number, $name) = @_;
    $name = substr($name, 0, 20);
    $self->{wt}->__request("groupadd", grpid=>$self->{grpid}, dstaddr=>$number, name=>$name);
}

sub del {
    my ($self, $number) = @_;
    $self->{wt}->__request("groupdel", grpid=>$self->{grpid}, dstaddr=>$number);
}

sub delall {
    my ($self) = @_;
    $self->{wt}->__request("groupdelall", grpid=>$self->{grpid});
}

sub list {
    my ($self) = @_;
    my $group = $self->{wt}->__request("groupget", grpid=>$self->{grpid});

    my @group = map { '+' . $_} split /\r\n/, $group;
    return \@group;
}

sub details {
    my ($self) = @_;
    my $group = $self->{wt}->__request("groupgetdetails", grpid=>$self->{grpid});
    my %group = ();
    for my $user (split /\r\n/, $group) {
        $user =~ /"(.*?)","(.*?)"/;
        $group{$2} = "+$1";
    }
    return \%group;
}

sub send {
    my ($self, $message, %opts) = @_;
    $self->{wt}->__request("sendgroup", grpid=>$self->{grpid}, txt=>$message, %opts);
}

sub remove {
    my ($self) = @_;
    eval {
        $self->{wt}->__request("groupremove", grpid=>$self->{grpid});
        1;
    } or do {
        return "SUCCESS" if($@ =~ /Number already exist/);
        die;
    }
}

1;

__END__

=head1 NAME

Net::SMS::WorldText - Send SMS messages via the World-Text HTTP API

=head1 SYNOPSIS

    use Net::SMS::WorldText;
    my $wt = Net::SMS::WorldText->new(user => "testuser", pass => "123456");
    $wt->send(
        message => "A thing of beauty is a joy forever",
        dest => "+15550123456",
    );

=head1 DESCRIPTION

Perl module to send sms'es and manage bulk-sending groups via World-Text's HTTP
api on sms.world-text.com.

=head1 METHODS

All methods below will confess upon any failure.

=head2 new

    my $wt = Net::SMS::WorldText->new(user => "username", pass => "password" [, proxyapi => 1]);

Creates an object for you to use. Specify proxy => 1 if you cannot connect to
port 1082 on sms.world-text.com, it will then use the proxy api ont he standard
https port of www.world-text.com.

If you need to use a proxy to access the world-text service, you can set it in
the underlying LWP::Useragent object as follows:

    $wt->{ua}->proxy(['http','https'], 'http://my.proxy.host:3128');

=head2 ping

    $wt->ping;

Checks whether you can connect.

=head2 send

    $wt->send(message => "Hello, world", dest => "+15550123456" [, srcaddr => "SMSAlert"] [, multipart => 1] [, callback => "url"]);

Send a message to one or more recipients. To send the message to more than one
recipient, pass an arrayref as dest. srcaddr can be any source address assigned
to your account. Messages that are too long will be split, multipart specifies
the maximum number of parts. The callback url will be called when the message
status changes. It will receive three POST parameters: error (en arror code),
msgid (of this message) and state (DELIVRD, EXPIRED, UNDELIV, ACCEPTD, REJECTD).

This method returns an reference to an array of arrayrefs. Each of those refs
points to a 2-element array (msgid, balance) of the message sent and the credit
balance left after sending it.

=head2 credits

    my $credits = $wt->credits;

Returns your SMS credit balance.

=head2 query

    my $result = $wt->query($msgid);

Returns the current status of your message.

=head2 group

    my $group = $wt->group(1042);

Returns a Net::SMS::WorldText::Group object that represents a group with that
group id. You can find these id's in the World-Text web interface.

=head2 create_group

    my $group = create_group(name => "Testgroup", srcaddr => "SMSAlert", pin => "1234");

Creates a new bulk send group and returns it. Name should not be longer than 20
characters and may not contain spaces, srcaddr can be any of the source
addresses available to your account.

=head1 GROUP METHODS

Bulk groups make it easy to send messages to the same set of people frequently.
These groups can be managed and addressed with the following methods.

=head2 add

    $group->add("+15550123456", "Dennis Kaarsemaker");

Adds a member to the group. The name should not be longer than 20 characters
and will be truncated.

=head2 del

    $group->del("+15550123456");

Removes a member, only phonenumbers can be passed to this call.

=head2 delall

    $group->delall;

Removes all members from the group.

=head2 list

    $group->list;

Returns all phonenumbers in the group.

=head2 details

    $group->details;

Like list, but returns a has mapping names to numbers.

=head2 send

    $group->send("Hello, group!" [, srcaddr => "SMSAlert"] [, multipart => 1]);

Sends a message to all members of the group. Returns the amount of sms'es sent.

=head2 remove

    $group->remove;

Deletes the group from the World-Text system.

=head1 SEE ALSO

L<World-Text http api documentation|http://www.world-text.com/docs/interfaces/>

Github source: L<http://github.com/seveas/Net-SMS-WorldText>

=head1 AUTHOR

Dennis Kaarsemaker, E<lt>dennis@kaarsemaker.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Dennis Kaarsemaker

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
