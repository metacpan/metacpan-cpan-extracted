package Net::DNSbed;

use 5.006;
use warnings;
use strict;
use Carp qw/croak/;
use JSON;
use LWP::UserAgent;

use vars qw/$VERSION/;
$VERSION = '0.02';

sub new {
    my $class = shift;
    my $uid = shift;
    my $token = shift;
    
    bless {uid=>$uid,token=>$token},$class;
}

sub addZone {
    my $self = shift;
    my $uid = $self->{uid};
    my $token = $self->{token};
    my $zone = shift || croak "you must provide a zone name";

    $self->reqTemplate('addZone',"uid=$uid&token=$token&zone=$zone");
}
    
sub delZone {
    my $self = shift;
    my $uid = $self->{uid};
    my $token = $self->{token};
    my $zid = shift || croak "you must provide a zone ID";

    $self->reqTemplate('delZone',"uid=$uid&token=$token&zid=$zid");
}

sub addRecord {
    my $self = shift;
    my $uid = $self->{uid};
    my $token = $self->{token};
    my $zid = shift || croak "you must provide a zone ID";
    my %args = @_;

    my $rname = $args{rname};
    my $rtype = $args{rtype};
    my $rvalue = $args{rvalue};
    my $ttl = $args{ttl};
    my $mxnum = $args{mxnum};

    $self->reqTemplate('addRecord',"uid=$uid&token=$token&zid=$zid&rname=$rname&rtype=$rtype&rvalue=$rvalue&ttl=$ttl&mxnum=$mxnum");
}
    
sub delRecord {
    my $self = shift;
    my $uid = $self->{uid};
    my $token = $self->{token};
    my $zid = shift || croak "you must provide a zone ID";
    my %args = @_;

    my $rid = $args{rid};

    $self->reqTemplate('delRecord',"uid=$uid&token=$token&zid=$zid&rid=$rid");
}

sub listZones {
    my $self = shift;
    my $uid = $self->{uid};
    my $token = $self->{token};
    my $zid = shift;

    if ($zid) {
        $self->reqTemplate('listZones',"uid=$uid&token=$token&zid=$zid");
    } else {
        $self->reqTemplate('listZones',"uid=$uid&token=$token");
    }
}

sub checkZone {
    my $self = shift;
    my $uid = $self->{uid};
    my $token = $self->{token};
    my $zone = shift || croak "you must provide a valid zone";

    $self->reqTemplate('checkZone',"uid=$uid&token=$token&zone=$zone");
}

sub listRecords {
    my $self = shift;
    my $uid = $self->{uid};
    my $token = $self->{token};
    my $zid = shift || croak "you must provide a zone ID";
    my %args = @_;

    my $rid = $args{rid};
    my $rids = $args{rids};
    
    if ($rid) {
        $self->reqTemplate('listRecords',"uid=$uid&token=$token&zid=$zid&rid=$rid");
    } elsif ($rids) {
        $self->reqTemplate('listRecords',"uid=$uid&token=$token&zid=$zid&rids=$rids");
    } else {
        $self->reqTemplate('listRecords',"uid=$uid&token=$token&zid=$zid");
    }
}
    
sub modifyRecord {
    my $self = shift;
    my $uid = $self->{uid};
    my $token = $self->{token};
    my $zid = shift || croak "you must provide a zone ID";
    my %args = @_;

    my $rid = $args{rid};
    my $rname = $args{rname};
    my $rtype = $args{rtype};
    my $rvalue = $args{rvalue};
    my $ttl = $args{ttl};
    my $mxnum = $args{mxnum};

    $self->reqTemplate('modifyRecord',"uid=$uid&token=$token&zid=$zid&rid=$rid&rname=$rname&rtype=$rtype&rvalue=$rvalue&ttl=$ttl&mxnum=$mxnum");
}

sub searchRecords {
    my $self = shift;
    my $uid = $self->{uid};
    my $token = $self->{token};
    my $zid = shift || croak "you must provide a zone ID";
    my %args = @_;

    my $keyword = $args{keyword};

    $self->reqTemplate('searchRecords',"uid=$uid&token=$token&zid=$zid&keyword=$keyword");
}

sub reqTemplate {
    my $self = shift;
    my $path = shift;
    my $args = shift;

    my $url = "http://www.dnsbed.com/api/$path";
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);
    my $req = HTTP::Request->new(POST => $url);

    $req->content_type('application/x-www-form-urlencoded');
    $req->content($args);

    my $res = $ua->request($req);
    return decode_json($res->decoded_content);
}


1;


=head1 NAME

Net::DNSbed - Perl client for DNSbed API

=head1 VERSION

Version 0.02


=head1 SYNOPSIS

    use Net::DNSbed;

    my $dnsbed = Net::DNSbed->new($uid,$token);

    $dnsbed->addZone($zone);
    $dnsbed->listZones;
    $dnsbed->checkZone($zone);
    $dnsbed->delZone($zid);

    $dnsbed->addRecord($zid,
        rname => $rname,
        rtype => $rtype,
        rvalue => $rvalue,
        ttl => $ttl,
        mxnum => $mxnum);

    $dnsbed->modifyRecord($zid,
        rid => $rid,
        rname => $rname,
        rtype => $rtype,
        rvalue => $rvalue,
        ttl => $ttl,
        mxnum => $mxnum);

    $dnsbed->delRecord($zid,rid => $rid);
    
    $dnsbed->listRecords($zid);
    $dnsbed->listRecords($zid,rid => $rid);
    $dnsbed->listRecords($zid,rids => $rids);

    $dnsbed->searchRecords($zid,keyword => $keyword);


=head1 METHODS

=head2 new(uid,token)

Initialize the object. You should be able to get your UID and token from DNSbed.com

=head2 addZone(zone)

The argument is the valid zone name, i.e, google.com, but not www.google.com

For the result of this method and all the methods below, just Data::Dumper it.

    use Data::Dumper;
    my $res = $dnsbed->addZone($zone);
    print Dumper $res;

=head2 listZones()

    use Data::Dumper;
    my $res = $dnsbed->listZones; # or
    my $res = $dnsbed->listZones($zid);
    print Dumper $res;

=head2 checkZone(zone)

    use Data::Dumper;
    my $res = $dnsbed->checkZone($zone);
    print Dumper $res;

=head2 delZone(zid)

The only argument is a valid zone ID.

=head2 addRecord(zid,rr_hash)

The first argument is zid, which must be provided.

The keys in rr_hash must have:

rname: the record's name, i.e, www (but not www.example.com)

rtype: the record's type, which can be one of these: A, CNAME, AAAA, MX, NS, TXT

rvalue: the record's value, it could be an IP address or a hostname, based on the type

ttl: the record's TTL, it's a number, i.e, 600 means 600 seconds

mxnum: if the record's type is MX, this means MX host's priority, otherwise it's meaningless

=head2 modifyRecord(zid,rr_hash)

The first argument is zid, which must be provided.

The keys in rr_hash must have:

rid: the record's ID with the values you want to modify

rname, rtype, rvalue, ttl, mxnum: the new values provided by you

Notice: after executing this method, the old RID will be lost, with the new record you get a new RID, not the before one.

=head2 delRecord(zid,rr_hash)

The first argument is zid, which must be provided.

The keys in rr_hash must have:

rid: the record's ID with the values you want to delete

=head2 listRecords(zid,optional_rr_hash)

The first argument is zid, which must be provided.

If you don't provide the second argument, it returns all the records for this zone ID.

optional_rr_hash could have one of these two keys:

rid: if provided, it returns only one record with this rid

rids: it could be, i.e, "1,2,3,4", then returns the records with rid 1,2,3 and 4

=head2 searchRecords(zid,kw_hash)

The first argument is zid, which must be provided.

The keys in kw_hash must have:

keyword: the keyword you want to search with

It returns the records whose rname or rvalue have the keyword included.


=head1 SEE ALSO

http://www.dnsbed.com/API.pdf


=head1 AUTHOR

Ken Peng <yhpeng@cpan.org>


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <yhpeng@cpan.org>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DNSbed


=head1 COPYRIGHT & LICENSE

Copyright 2012 Ken Peng, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.
