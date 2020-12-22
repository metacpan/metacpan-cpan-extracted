package Net::Cloudflare::DNS;

use 5.006;
use strict;
use warnings;
use JSON;
use URI;
use LWP::UserAgent;
use LWP::Protocol::https;
 
 
sub new {
    my $class = shift;
    my %args = @_;
    bless \%args, $class;
}
 
sub get_records {
    my $self = shift;
    my %args = @_;

    my $email = $self->{email};
    my $api_key = $self->{api_key};
    my $zone_id = $self->{zone_id};
    
    my $uri = URI->new("https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records");
    $uri->query_form(%args);

    my $ua = LWP::UserAgent->new;
    my %headers = (
        'Content-Type' => 'application/json',
        'X-Auth-Key'   => $api_key,
        'X-Auth-Email' => $email,
    );
 
    my $res = $ua->get($uri,
        %headers,
    );

    if ($res->is_success ) {
        return decode_json($res->decoded_content);
    } else {
        die $res->status_line, $res->decoded_content;
    }
}


sub create_record {
    my $self = shift;
    my %args = @_;

    my $data = encode_json(\%args);
    my $email = $self->{email};
    my $api_key = $self->{api_key};
    my $zone_id = $self->{zone_id};
    

    my $uri = "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records";
    my $ua = LWP::UserAgent->new;
    my %headers = (
        'Content-Type' => 'application/json',
        'X-Auth-Key'   => $api_key,
        'X-Auth-Email' => $email,
    );
 
    my $res = $ua->post($uri,
        %headers,
        Content => $data,
    );

    if ($res->is_success ) {
        return decode_json($res->decoded_content);
    } else {
        die $res->status_line, $res->decoded_content;
    }
}

sub update_record {
    my $self = shift;
    my $record_id = shift;
    my %args = @_;

    my $data = encode_json(\%args);
    my $email = $self->{email};
    my $api_key = $self->{api_key};
    my $zone_id = $self->{zone_id};

    my $uri = "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id";
    my $ua = LWP::UserAgent->new;
    my %headers = (
        'Content-Type' => 'application/json',
        'X-Auth-Key'   => $api_key,
        'X-Auth-Email' => $email,
    );
 
    my $res = $ua->put($uri,
        %headers,
        Content => $data,
    );

    if ($res->is_success ) {
        return decode_json($res->decoded_content);
    } else {
        die $res->status_line, $res->decoded_content;
    }
}

sub delete_record {
    my $self = shift;
    my $record_id = shift;

    my $email = $self->{email};
    my $api_key = $self->{api_key};
    my $zone_id = $self->{zone_id};

    my $uri = "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id";
    my $ua = LWP::UserAgent->new;
    my %headers = (
        'Content-Type' => 'application/json',
        'X-Auth-Key'   => $api_key,
        'X-Auth-Email' => $email,
    );
 
    my $res = $ua->delete($uri,
        %headers,
    );

    if ($res->is_success ) {
        return decode_json($res->decoded_content);
    } else {
        die $res->status_line, $res->decoded_content;
    }
}

=head1 NAME

Net::Cloudflare::DNS - DNS API for Cloudflare API v4 

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Cloudflare API v4 has big improvement to the older ones. This API operates against the specific zone based on API v4. 

I use this module to dyna update my DNS zone everyday. Cloudflare's DNS and its API behave very well in my life.

If you have met any issue with the module, please don't hesitate to drop me an email: iwesley [at] pobox.com

To use the module, you must have these two perl modules installed in the system:

    sudo apt install libio-socket-ssl-perl
    sudo cpanm LWP::Protocol::https

My system is Ubuntu, which can use apt to install IO::Socket::SSL. I can't install this module with cpanm tool.

    use Net::Cloudflare::DNS;

    # new the object
    my $dns = Net::Cloudflare::DNS->new(email=>$email, api_key=>$api_key, zone_id=>$zone_id);

    # create the record
    my $res = $dns->create_record(type=>"A", name=>"test.myhostnames.com",content=>"1.1.1.1",ttl=>1);

    # update the record
    $res = $dns->update_record($record_id, type=>"TXT", name=>"test.myhostnames.com",content=>"bala bala",ttl=>1);

    # delete the record
    $res = $dns->delete_record($record_id);

    # list records by conditions
    $res = $dns->get_records(name=>"test.myhostnames.com");

    # if the method succeed, a structure reference was returned, whose content is response content from cloudflare 
    # otherwise the method just dies, you should catch the error in your code
    use Data::Dumper;
    print Dumper $res;

Hence this is my own script for test purpose:

    use strict;
    use warnings;
    use Net::Cloudflare::DNS;

    my $obj = Net::Cloudflare::DNS->new(email    => $ENV{'CLOUDFLARE_EMAIL'},
                                        api_key  => $ENV{'CLOUDFLARE_API_KEY'},
                                        zone_id  => $ENV{'CLOUDFLARE_ZONE_ID'},
                                       );

    #
    # batch add
    #
    for (1..10) {
        my $rand_hostname = int(rand(3333333)) . ".myhostnames.com";
        my $rand_ip = int(rand(255)) ."." . int(rand(255)). ".". int(rand(255)). ".". int(rand(255));

        $obj->create_record(type=>"A", name=>$rand_hostname,content=>$rand_ip,ttl=>1);
    }

    #
    # get records
    #
    my @records;

    my $ref = $obj->get_records('per_page'=>100);
    my @rr = @{$ref->{result}};

    for (@rr) {
        if ($_->{name} =~ /^\d+/) {
          push @records, [$_->{id}, $_->{name}]; 
        }
    }

    #
    # batch update
    #
    for  (@records) {
        my $id = $_->[0];
        my $hostname = $_->[1];
        my $rand_ip = int(rand(255)) ."." . int(rand(255)). ".". int(rand(255)). ".". int(rand(255));

        $obj->update_record($id, type=>"A", name=>$hostname,content=>$rand_ip,ttl=>1);
    }

    #
    # batch delete
    #
    for  (@records) {
        $obj->delete_record($_->[0]);
    }


=head1 SUBROUTINES/METHODS

=head2 new

    my $dns = Net::Cloudflare::DNS->new(email=>$email, api_key=>$api_key, zone_id=>$zone_id);

You have to provide 3 arguments to new() method. One is your registration email on Cloudflare. Another is your API Key, which can be 
found on Cloudflare's management panel ("Global API Key"). The last is Zone ID, each zone has the unique ID, which can be found
on zone's page.

Please notice: You must enable zone edit permissions for this API. In management panel, when you click "Create Token", you have the
chance to setup permissions for the zone, with which you can edit zone's DNS records. 
 


=head2 create_record

    my $res = $dns->create_record(type=>"A", name=>"test.myhostnames.com",content=>"1.1.1.1",ttl=>1);

You can create record in the zone with this method.

Required parameters:

type: includes "A", "TXT", "MX", "CNAME" ... They are standard DNS record type.

name: the hostname you want to create, must be FQDN.

content: record's value, for "A" record, it's an IP address.

ttl: time to live. You can always set it to 1, which means automatic by Cloudflare. otherwise it's must be larger than 120.

Optional parameters:

priority: MX's priority, default 0.

proxied: whether proxied by cloudflare, default false.

Please read the official documentation here:

    https://api.cloudflare.com/#dns-records-for-a-zone-properties



=head2 update_record

    $res = $dns->update_record($record_id, type=>"TXT", name=>"test.myhostnames.com",content=>"bala bala",ttl=>1);

Update the record in the zone.

You must provide $record_id as the first argument, the left arguments are almost the same with create_record method.

You can get $record_id from get_records method.



=head2 delete_record

    $res = $dns->delete_record($record_id);

Delete the record in the zone.

You must provide $record_id as the unique argument.



=head2 get_records

    $res = $dns->get_records(conditions...);

List the records by conditions. For details you can read the documentation:

    https://api.cloudflare.com/#dns-records-for-a-zone-properties



=head1 AUTHOR

Wesley Peng, C<< <wesley at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-cloudflare-dns at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Cloudflare-DNS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Cloudflare::DNS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Cloudflare-DNS>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Cloudflare-DNS>

=item * Search CPAN

L<https://metacpan.org/release/Net-Cloudflare-DNS>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Wesley Peng.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::Cloudflare::DNS
