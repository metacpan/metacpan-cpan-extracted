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

    my $ua = LWP::UserAgent->new;
    my %headers;

    if (defined $args{api_token}) {
        %headers = (
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer $args{api_token}",
        );
    } else {
        %headers = (
            'Content-Type' => 'application/json',
            'X-Auth-Key'   => $args{api_key},
            'X-Auth-Email' => $args{email},
        );
    }

    my $zone_id = $args{zone_id};
    die "no zone_id provided" unless defined $zone_id;

    my $base_url = "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records";

    bless { ua => $ua,
            headers => \%headers,
            base_url => $base_url,
          }, $class;
}
 
sub get_records {
    my $self = shift;
    my %args = @_;

    my $uri = URI->new($self->{base_url});
    $uri->query_form(%args);
    my $ua = $self->{ua};

    my $res = $ua->get($uri,
        %{$self->{headers}},
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
    my $uri = URI->new($self->{base_url});
    my $ua = $self->{ua};

    my $res = $ua->post($uri,
        %{$self->{headers}},
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
    my $uri = URI->new($self->{base_url} . "/$record_id");
    my $ua = $self->{ua};

    my $res = $ua->put($uri,
        %{$self->{headers}},
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

    my $uri = URI->new($self->{base_url} . "/$record_id");
    my $ua = $self->{ua};
 
    my $res = $ua->delete($uri,
        %{$self->{headers}},
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

Version 0.22

=cut

our $VERSION = '0.22';


=head1 SYNOPSIS

This perl module is working for Cloudflare DNS API v4.

My system is Ubuntu, to use the module, I have the following perl modules pre-installed in the system.

    sudo apt install libio-socket-ssl-perl
    sudo cpanm LWP::Protocol::https

After then, you can run "cpanm Net::Cloudflare::DNS" to install this module.

    use Net::Cloudflare::DNS;
    use Data::Dumper;

    # zone_id for your domain
    my $zone_id = " ";

    # new the object with email and api_key
    my $email = " ";
    my $api_key = " ";
    my $dns = Net::Cloudflare::DNS->new(email=>$email, api_key=>$api_key, zone_id=>$zone_id);

    # or, new the object with bearer token
    my $api_token = " ";
    my $dns = Net::Cloudflare::DNS->new(api_token=>$api_token, zone_id=>$zone_id);

    # create record
    $dns->create_record(type=>"A", name=>"www.sample.com", content=>"74.81.81.81", proxied=>\1, ttl=>60);

    # get records
    my $res = $dns->get_records(name=>"www.sample.com");

    # parse record id
    my $rid = $res->{result}->[0]->{id};

    # update record
    $dns->update_record($rid, type=>"A", name=>"www.sample.com",content=>"52.1.14.22", proxied=>\0, ttl=>60);

    # delete record
    $dns->delete_record($rid);

If the instance method succeeds, cloudflare's response is resturned as a reference to you.
Otherwise it just dies, you could catch the error in the code.

    $res = $dns->create_record(...);
    print Dumper $res;


=head1 SUBROUTINES/METHODS

=head2 new

    my $dns = Net::Cloudflare::DNS->new(email=>$email, api_key=>$api_key, zone_id=>$zone_id);
    # or,
    my $dns = Net::Cloudflare::DNS->new(api_token=>$api_token, zone_id=>$zone_id);

You have to provide either email+api_key or api_token along with zone_id to new() method. 
All those values can be found on cloudflare's management panel.

Please note: You must enable zone edit permissions for this API. In management panel, when you click "Create Token", 
you have the chance to setup permissions for the zone, with which you can edit zone's DNS records. 
 

=head2 create_record

    $dns->create_record(type=>"A", name=>"www.sample.com",content=>"1.2.3.4",proxied=>\1,ttl=>1);

Create record in the zone.

You have to provide the following parameters.

type: includes "A", "TXT", "MX", "CNAME" ... They are standard DNS record types.

name: the hostname you want to create, such as www.example.com.

content: record value, for "A" record, it's an IP address.

ttl: time to live. You can set it to 1, which means to be automated by Cloudflare.

Optional parameters:

priority: MX priority, default 0.

proxied: whether proxied by cloudflare, it's either \1 (true) or \0 (false).

Please read their official documentation below.

    https://developers.cloudflare.com/api/#dns-records-for-a-zone-properties


=head2 update_record

    $dns->update_record($record_id, type=>"TXT", name=>"www.sample.com",content=>"bala bala",ttl=>1);

Update record in the zone.

Please provide $record_id as the first argument, the rest are almost the same as create_record.

You can get $record_id from get_records method.


=head2 delete_record

    $dns->delete_record($record_id);

Delete record from the zone.

Provide $record_id as the unique argument.


=head2 get_records

    my $res = $dns->get_records(conditions...);

List records by conditions. For details please read the following documentation.

    https://developers.cloudflare.com/api/#dns-records-for-a-zone-properties



=head1 AUTHOR

Wesley Peng, C<< <wesley at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-cloudflare-dns at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Cloudflare-DNS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 THANKS

1. Thibault, C<< <thibault.duponchelle at gmail.com> >> for porting the bearer token authentication method.


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
