# see POD at the bottom for documentation
package Net::Wigle;

use strict;
use warnings;
use Data::Dumper;
use JSON;
use LWP::UserAgent;
use Params::Validate qw(:all);
use 5.010000;

require Exporter;

our @ISA = qw(
  Exporter
  LWP::UserAgent
);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Wigle ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.07';
our $url_query_base = 'https://wigle.net/api/v1/jsonSearch';
our $url_login = 'https://wigle.net/api/v1/jsonUser';

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $self = {};
  bless $self, $class;
  $self->requests_redirectable(['GET', 'HEAD', 'POST']);
  return $self;
}

# purpose  : login to wigle.net

sub log_in {
  my $self = shift;
  my %args = validate @_, {
    user => { type => SCALAR, },
    pass => { type => SCALAR, },
  };
  unless ($self->cookie_jar) {
    $self->cookie_jar({});
  }
  my $form = {
    credential_0 => $args{user},
    credential_1 => $args{pass},
    destination => '/https://wigle.net',
    noexpire => 'checked',
  };
  my $response = $self->post($url_login, $form);
  unless ($response->is_success) {
    return undef;
  }
  return $self->cookie_jar;
}

# purpose : used to return a parsed/scraped html table
#           now it just returns the parsed json

sub query {
  my $self = shift;
  my %args = validate @_, {
    user => {
      type => SCALAR,
    },
    pass => {
      type => SCALAR,
    },
    variance => {
      default => '0.010',
    },
    latrange1 => {
      optional => 1,
    },
    latrange2 => {
      optional => 1,
    },
    longrange1 => {
      optional => 1,
    },
    longrange2 => {
      optional => 1,
    },
    addresscode => {
      optional => 1,
    },
    statecode => {
      optional => 1,
    },
    zipcode => {
      optional => 1,
    },
    pagestart => {
      optional => 1,
    },
    lastupdt => {
      optional => 1,
    },
    netid => {
      optional => 1,
    },
    ssid => {
      optional => 1,
    },
    freenet => {
      optional => 1,
    },
    paynet => {
		  optional => 1,
    },
    dhcp => {
		  optional => 1,
    },
    onlymine => {
		  optional => 1,
    },
    Query => {
      default => 'Query',
    },
  };
  my $cookie_jar = $self->log_in(
    user => $args{user},
    pass => $args{pass},
  ); 
  unless ($cookie_jar) {
    return undef;
  }
  delete $args{user};
  delete $args{pass};
  my $response = $self->query_raw(%args); 
  unless ($response->is_success) {
    return undef;
  }
  return from_json($response->decoded_content);
  my $string_search_response = $response->as_string;
  my @records;
  #$string_search_response =~ qr/.*\<tr\s+class="search"\s*\>(.*?)\<\/tr.*/xmsi;
  while ($string_search_response =~ m{
    \<tr\s+class="search"\s*\>
      (.*?)
    \</tr
  }xmsgi) {
    my $row_raw = $1;
    $row_raw =~ m{
      <td>(.*?)</td>\s* # map link
      <td>(.*?)</td>\s* # netid
      <td>(.*?)</td>\s* # ssid
      <td>(.*?)</td>\s* # comment
      <td>(.*?)</td>\s* # name 
      <td>(.*?)</td>\s* # type 
      <td>(.*?)</td>\s* # freenet 
      <td>(.*?)</td>\s* # paynet 
      <td>(.*?)</td>\s* # firsttime 
      <td>(.*?)</td>\s* # lasttime 
      <td>(.*?)</td>\s* # flags 
      <td>(.*?)</td>\s* # wep 
      <td>(.*?)</td>\s* # trilat 
      <td>(.*?)</td>\s* # trilong 
      <td>(.*?)</td>\s* # dhcp 
      <td>(.*?)</td>\s* # lastupdt 
      <td>(.*?)</td>\s* # channel 
      <td>(.*?)</td>\s* # active 
      <td>(.*?)</td>\s* # bcninterval 
      <td>(.*?)</td>\s* # qos 
    }xmsgi;
    push @records, {
      netid => $2,
      ssid => $3,
      comment => $4,
      name => $5,
      type => $6,
      freenet => $7,
      paynet => $8,
      firsttime => $9,
      lasttime => $10,
      flags => $11,
      wep => $12,
      trilat => $13,
      trilong => $14,
      dhcp => $15,
      lastupdt => $16,
      channel => $17,
      active => $18,
      bcninterval => $19,
      qos => $20,
      userfound => $21,
    };
  }
  return \@records;
}

# purpose  : query wigle, trying to keep this simple
# usage    : args are optional, just provided for informational purposes
# comments : returns an HTTP::Response object

sub query_raw {
  my $self = shift;
  my %args = @_;
  return $self->post($url_query_base, \%args);
}

1;
__END__

=head1 NAME 

Net::Wigle - Perl extension for querying wigle.net 

=head1 SYNOPSIS

  use Net::Wigle;
  use Data::Dumper;
  my $wigle = Net::Wigle->new; 
  print Dumper $wigle->query(
    user => 'insertYourWigleUserNameHere',
    pass => 'insertYourWiglePasswordHere',
    ssid => 'insertAnSsidHere',
  );

=head1 DESCRIPTION

It queries wigle.net.  See output from example code for a list of query params (ssid, netid, etc).

=head1 TODO 

=over 1

=item urlencode params before http post.

=item translate '?' to undef?

=item Figure out if variance is always required.


=back

=head1 SEE ALSO

Forums at http://wigle.net

Code is at https://github.com/allred/p5-Net-Wigle

=head1 MOTD 

"For your health." -Steve Brule

=head1 AUTHOR

Mike Allred, E<lt>mikejallred@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Mike Allred

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
