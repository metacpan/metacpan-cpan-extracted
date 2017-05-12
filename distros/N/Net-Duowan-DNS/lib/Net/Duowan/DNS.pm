package Net::Duowan::DNS;

use 5.006;
use warnings;
use strict;
use Carp qw/croak/;
use LWP::UserAgent;
use Net::Duowan::DNS::Zones;
use Net::Duowan::DNS::Records;
use Net::Duowan::DNS::Owner;

use vars qw/$VERSION/;
$VERSION = '1.2.0';

sub new {
    my $class = shift;
    my %arg = @_;
    
    my $psp = $arg{passport} || croak "no passport provided"; 
    my $token = $arg{token} || croak "no token provided";

    eval {
        require LWP::Protocol::https;
    } or croak "LWP::Protocol::https along with LWP::UserAgent is required";

    bless { psp => $psp, token => $token }, $class;
}

sub zones {
    my $self = shift;
    return Net::Duowan::DNS::Zones->new($self->{psp},$self->{token} );
}

sub records {
    my $self = shift;
    return Net::Duowan::DNS::Records->new($self->{psp},$self->{token} );
}

sub owner {
    my $self = shift;
    return Net::Duowan::DNS::Owner->new($self->{psp},$self->{token} );
}

1;

=head1 NAME

Net::Duowan::DNS - Perl client for YY ClouDNS API

=head1 VERSION

Version 1.2.0

=head1 SYNOPSIS

    use Net::Duowan::DNS;

    my $dwdns = Net::Duowan::DNS->new(passport => 'YY_Passport', 
                                      token => 'Token_to_verify');

    # the object for the owner
    my $o = $dwdns->owner;

    # the object for zones management
    my $z = $dwdns->zones;

    # the object for records management
    my $r = $dwdns->records;

    ##########################
    # owner operation methods
    ###########################
    
    # re-generate the token, the new token is included in the returned hashref
    $re = $o->reGenerateToken;

    # fetch the operation logs, the default offset and number are 0 and 100
    # the log items are utf-8 encoded, you may want to encode_utf8(item) before printing them
    $re = $o->fetchOpsLog(number=>10,offset=>0);

    # fetch the history for zone applying, the default offset and number are 0 and 100
    $re = $o->fetchZoneApplyHistory(number=>10,offset=>0);

    ##########################
    # zones management methods
    ###########################
    
    # fetch all zones under an user
    # you can also use offset and number to limit the returned items
    $re = $z->fetch;

    # check the information for special zones
    $re = $z->check('zone1.com','zone2.com');

    # create a zone
    # for both zone create and remove, you should be able to notice from the returned message that,
    # they don't become effective at once, but wait for the administrator to approve them
    # about zone status:
    # 0 - prepare to be activated
    # 1 - activated
    # 2 - prepare to be deleted
    $re = $z->create('zone.com');

    # remove a zone
    $re = $z->remove('zone.com');

    ##########################
    # records management methods
    ###########################

    # fetch the records from a zone, the default offset and number are 0 and 100
    # you may specify offset=>0, number=>-1 to get all the records for this zone
    $re = $r->fetchMulti('zone.com',offset=>0,number=>10);

    # fetch records' size within a zone
    $re = $r->fetchSize('zone.com');

    # fetch a record, you should specify the record id
    # the record's options are included in the returned hashref
    $r->fetchOne('zone.com',rid=>123);

    # create a record
    # name - the hostname for a record
    # content - the record value
    # isp - with either tel or uni from China ISP
    # type - A, CNAME, MX, TXT, NS, AAAA
    # ttl - time to live, in seconds
    # about the record status:
    # 0 - prepare to be activated
    # 1 - activated
    # 2 - prepare to be deleted
    $re = $r->create('zone.com',name=>'www',content=>'11.22.33.44',isp=>'tel',type=>'A',ttl=>300);

    # modify a record, you must specify the rid to be modified
    $re = $r->modify('zone.com',rid=>123,name=>'www',content=>'5.6.7.8',isp=>'uni',type=>'A',ttl=>300);

    # remove a record, you must specify the rid to be removed
    $re = $r->remove('zone.com',rid=>123);

    # bulk remove records, all records included in the rids list are removed
    $re = $r->bulkRemove('zone.com',rids=>[123,456]);

    # remove records by hostname
    $re = $r->removebyHost('zone.com',name=>'www');

    # bulk create records, the value for records is a list
    # each element in the list must be the record options
    my $rec =
        [ { type => "A",
            name => "test1",
            content => "1.2.3.4", 
            isp => "tel",
            ttl => 300 
          },
          { type => "A",
            name => "test1", 
            content => "5.6.7.8", 
            isp => "uni",
            ttl => 300 
          }
        ];

    $re = $r->bulkCreate('zone.com',records=>$rec);

    # search records with the keyword
    # it will search from the name and content fields with the keyword
    # you can also use offset,number to limit the returned items
    $r->search('zone.com',keyword=>'test');

    # fetch records by hostname
    # all records with the specified hostname will be included in the hashref
    # you can also use offset,number to limit the returned items
    $re = $r->fetchbyHost('zone.com',name=>'www');

    # fetch records by wild matching within the hostname string
    # the example below gets the records of test1.zone.com, test2.zone.com, ...
    $re = $r->fetchbyPrefix('zone.com',prefix=>'test*');

    ##########################
    # print out the results
    ###########################
    
    # the result returned is a hash reference, just dump it
    # you should get the wanted data from the hashref
    # in the future version I may decode the hashref, return all options as methods
    # but in the current release you should be able to parse the hash by your end
    use Data::Dumper;
    print Dumper $re;


=head1 METHODS

=head2 new(passport=>'string', token=>'string')

The class method for initializing the object.

To use the API, you firstly should sign up an account on YY.com, that's your passport.

The token is obtained from YY ClouDNS's user management panel.

For more details please check the API document from their official website:

    http://dnscp.duowan.com/

=head2 owner()

Got an object for the owner, who has several methods for the user management

=head2 zones()

Got an object which has all methods for zones management

=head2 records()

Got an object which has all methods for records management

=head1 AUTHOR

Ken Peng <yhpeng@cpan.org>

=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <yhpeng@cpan.org>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Duowan::DNS

=head1 COPYRIGHT & LICENSE

Copyright 2013 Ken Peng, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
