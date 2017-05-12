package Net::Artera;

use 5.005;
use strict;
use Data::Dumper;
use LWP::UserAgent;
use XML::Simple;
use Locale::Country;

#require Exporter;
use vars qw($VERSION @ISA $DEBUG @login_opt); #$WARN );
         # @EXPORT @EXPORT_OK %EXPORT_TAGS);
#@ISA = qw(Exporter);

# This allows declaration	use Net-Artera ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#%EXPORT_TAGS = ( 'all' => [ qw(
#	
#) ] );

#@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#@EXPORT = qw();

$VERSION = '0.01';

#$WARN = 0;
$DEBUG = 0;

=head1 NAME

Net::Artera - Perl extension for Artera XML API.

=head1 SYNOPSIS

  use Net::Artera;

  my $connection = new Net::Artera (
    'rid'        => 'reseller_id',
    'username'   => 'reseller_username',
    'password'   => 'reseller_password',
    'production' => 0,
  );

  my $result = $artera->newOrder(
    'email' => $email,
    'cname' => $name,
    'ref'   => $refnum,,
    'aid'   => $affiliatenum,
    'add1'  => $address1,
    'add2'  => $address2,
    'add3'  => $city,
    'add4'  => $state,
    'zip'   => $zip,
    'cid'   => $country,
    'phone' => $phone,
    'fax'   => $fax,
  );

  if ( $result->{'id'} == 1 ) {
    #Success!
    $serialnum = $result->{'ASN'};
    $keycode   = $result->{'AKC'};
  } else {
    #Failure
    die $result->{'message'};
  }

  # etc...

=head1 DESCRIPTION

This is a Perl module which speaks the Artera XML API.
See <http://www.arteraturbo.com>.  Artera Resellers can use this module
to access some features of the API.

=head1 METHODS

=over 4

=item new [ OPTIONS_HASHREF | OPTION => VALUE ... ]

Constructor.  Options can be passed as a hash reference or a list.  Options are
case-insensitive.

Available options are:

=over 4

=item username - Reseller username

=item password - Reseller password

=item rid - Reseller ID (RID)

=item pid - Product ID (PID).

=item production - if set true, uses the production server instead of the staging server.  

=back

=cut

@login_opt = qw( RID Username Password );

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless ($self, $class);

  my $opt = $self->_lc_hash_or_hashref(@_);
  $self->{$_} = $opt->{$_} for map lc($_), @login_opt;

  if ( defined($opt->{'production'}) && $opt->{'production'} ) {
    $self->{'url'} = 'https://secure.arteragroup.com/';
  } else {
    $self->{'url'} = 'http://staging.arteragroup.com/';
  }
  $self->{'url'} .= 'Wizards/wsapi/31/APIService.asmx';

  $self->{'ua'} = LWP::UserAgent->new;

  warn "\n$self created: ". Dumper($self) if $DEBUG;

  $self;
}

sub _lc_hash_or_hashref {
  my $self = shift;
  my $opt = ref($_[0]) ? shift : {@_};
  my $gratuitous = { map { lc($_) => $opt->{$_} } keys %$opt };
  $gratuitous;
}

=item newTrial [ OPTIONS_HASHREF | OPTION => VALUE ... ]

Options can be passed as a hash reference or a list.  Options are
case-insensitive.

Available options are:

=over 4

=item email (required)

=item cname (required) - Customer's name

=item ref (required) - Reseller's own order reference

=item pid (required) - Artera Product ID

=item priceid (required) - Artera Price ID

=item aid - Affiliate ID number used when the Reseller wants to track some type of sales channel beneath them.

=item add1*

=item add2

=item add3* - City

=item add4* - State

=item zip*

=item cid* - Country ID.  Defaults to 2 (USA).  Can be specified as a numeric CID or as an ISO 3166 two-letter country code or full name.

=item phone

=item fax

=back 

*These fields are optional, but must be supplied as a set.

Returns a hash reference with the following keys (these keys B<are>
case-sensitive):

=over 4

=item id - This is the Result ID to indicate success or failure: 1 for success, anything else for failure

=item message - Some descriptive text regarding the success or failure

=item ASN - The Artera Serial Number

=item AKC - The Artera Key Code

=item TrialID - The Artera Trial Number

=item Ref - The Reseller Reference

=item CustomerID - Artera's CustomerID

=item TrialLength - Trial Length

=cut

sub newTrial {
  my $self = shift;
  my $opt = $self->_lc_hash_or_hashref(@_);
  $self->_newX('Trial', $opt);
}

=item newOrder [ OPTIONS_HASHREF | OPTION => VALUE ... ]

Available options are the same as B<newTrial>.  Additionally the I<asn> and
I<akc> fields may be specified to convert a trial to an order.

=cut

sub newOrder {
  my $self = shift;
  my $opt = $self->_lc_hash_or_hashref(@_);
  push @{$opt->{'optional_params'}}, qw( ASN AKC );
  $self->_newX('Order', $opt);
}

sub _newX {
  my( $self, $x, $opt ) = @_;

  if ( defined($opt->{'cid'}) ) {
    $opt->{'cid'} = $self->_country2cid($opt->{'cid'});
  } else {
    $opt->{'cid'} = 2 if grep defined($_), qw(Add1 Add3 Add4 Zip);
  }

  push @{$opt->{'required_params'}},
       qw( Email CName Ref PID PriceID );
  push @{$opt->{'optional_params'}},
       qw( AID Add1 Add2 Add3 Add4 Zip CID Phone Fax );

  $self->_submit( "new$x", $opt );

}

my %country2cid = (
  'uk' => 1,
  'gb' => 1,
  'us' => 2,
  'in' => 3,
  'jp' => 4,
  'ru' => 5,
  'fr' => 6,
  'pl' => 7,
  'gr' => 8,
  'ug' => 9,
  'lk' => 10,
  'sa' => 11,
  'nl' => 12,
  'pe' => 13,
  'ca' => 14,
  'nz' => 15,
  'kr' => 16,
  'it' => 17,
  'es' => 18,
  'il' => 19,
  'se' => 20,
  'de' => 21,
  'ie' => 22,
  'mx' => 23,
  'au' => 24,
  'to' => 25,
  'eg' => 26,
  'tr' => 27,
  'am' => 28,
  'az' => 29,
  'by' => 30,
  'ee' => 31,
  'ge' => 32,
  'kz' => 33,
  'kg' => 34,
  'lt' => 35,
  'md' => 36,
  'tj' => 38,
  'tm' => 39,
  'ua' => 40,
  'uz' => 41,
  '' => 42, #BOSNIA
  '' => 43, #HERZEGOVINA
  'hr' => 44,
  'mk' => 45,
  '' => 46, #SERBIA
  '' => 47, #MONTENEGRO
  'si' => 48,
  'er' => 49,
  'mh' => 51,
  'pw' => 52,
  'fm' => 53,
  'na' => 54,
  'lv' => 56,
  'za' => 57,
  'jm' => 58,
);

sub _country2cid {
  my( $self, $country ) = @_;
  if ( $country =~ /^\s*(\d+)\s*$/ ) {
    $1;
  } elsif ( $country =~ /^\s*(\w\w)\s*$/ ) {
    $country2cid{$1};
  } elsif ( $country !~ /^\s*$/ ) {
    $country2cid{country2code($country)};
  } else {
    '';
  }
}

=item statusChange [ OPTIONS_HASHREF | OPTION => VALUE ... ]

Options can be passed as a hash reference or a list.  Options are
case-insensitive.

Available options are:

=over 4

=item ASN (required) - Artera Serial Number

=item AKC (required) - Artera Key Code

=item StatusID (required) - Possible StatusID values are as follows:

=over 4

=item 15 - Normal Unrestricted: re-enable a disabled Serial Number (e.g. a payment dispute has been resolved so the Serial Number needs to be re-enabled).

=item 16 - Disable: temporarily prohibit an end-user's serial number from working (e.g. there is a payment dispute, so you want to turn off the Serial Number until the dispute is resolved).

=item 17 - Terminate: permanently prohibit an end-user's Serial Number from working (e.g. subscription cancellation) 

=back

=item Reason - Reason for terminating

=back

Returns a hash reference with the following keys (these keys B<are>
case-sensitive):

=over 4

=item id - This is the Result ID to indicate success or failure: 1 for success, anything else for failure

=item message - Some descriptive text regarding the success or failure

=back

=cut

sub statusChange {
  my $self = shift;
  my $opt = $self->_lc_hash_or_hashref(@_);

  push @{$opt->{'required_params'}},
       qw( ASN AKC StatusID );
  push @{$opt->{'optional_params'}}, 'Reason';

  $self->_submit('statusChange', $opt );
}

=item getProductStatus [ OPTIONS_HASHREF | OPTION => VALUE ... ]

Options can be passed as a hash reference or a list.  Options are
case-insensitive.

Available options are:

=over 4

=item ASN (required) - Artera Serial Number

=item AKC (required) - Artera Key Code

=back

Returns a hash reference with the following keys (these keys B<are>
case-sensitive):

=over 4

=item id - This is the Result ID to indicate success or failure: 1 for success, anything else for failure

=item message - On failure, descriptive text regarding the failure

=item StatusID (required) - Possible StatusID values are as follows:

=over 4

=item 15 - Normal Unrestricted: re-enable a disabled Serial Number (e.g. a payment dispute has been resolved so the Serial Number needs to be re-enabled).

=item 16 - Disable: temporarily prohibit an end-user's serial number from working (e.g. there is a payment dispute, so you want to turn off the Serial Number until the dispute is resolved).

=item 17 - Terminate: permanently prohibit an end-user's Serial Number from working (e.g. subscription cancellation) 

=back

=item Description - Status description

=back

=cut

sub getProductStatus {
  my $self = shift;

  my $opt = $self->_lc_hash_or_hashref(@_);

  push @{$opt->{'required_params'}}, qw( ASN AKC );

  my $result = $self->_submit('getProductStatus', $opt );

  # munch results, present as flat list
  $result->{$_} = $result->{'Status'}->{$_} foreach (qw(StatusID Description));
  delete $result->{'Status'};

  $result;

}

=item updateContentControl [ OPTIONS_HASHREF | OPTION => VALUE ... ]

Options can be passed as a hash reference or a list.  Options are
case-insensitive.

Available options are:

=over 4

=item ASN (required) - Artera Serial Number

=item AKC (required) - Artera Key Code

=item UseContentControl (required) - 0 for off, 1 for on

=back

Returns a hash reference with the following keys (these keys B<are>
case-sensitive):

=over 4

=item id - This is the Result ID to indicate success or failure: 1 for success, anything else for failure

=item message - Some descriptive text regarding the success or failure

=back

=cut

sub updateContentControl {
  my $self = shift;

  my $opt = $self->_lc_hash_or_hashref(@_);

  push @{$opt->{'required_params'}}, qw( ASN AKC UseContentControl );

  $self->_submit('updateContentControl', $opt );
}

=item orderListByDate [ OPTIONS_HASHREF | OPTION => VALUE ... ]

Unimplemented.

=cut

#--

sub _submit {
  my( $self, $method, $opt ) = @_;
  my $ua = $self->{'ua'};

  my $param = {
    ( map { $_ => $self->{lc($_)} }
          @login_opt,
    ),
    ( map { $_ => $opt->{lc($_)} }
          @{$opt->{'required_params'}}
    ),
    ( map { $_ => ( exists $opt->{lc($_)} ? $opt->{lc($_)} : '' ) }
          @{$opt->{'optional_params'}}
    ),
  };
  warn "$self url $self->{url}/$method\n" if $DEBUG;
  warn "$self request parameters: ". Dumper($param). "\n" if $DEBUG;

  #POST
  my $response = $ua->post( "$self->{'url'}/$method", $param );

  warn "$self raw response: ". $response->content. "\n" if $DEBUG;

  #unless ( $response->is_success ) {
  #  die $response->content;
  #}

  my $xml = XMLin( $response->content );
  warn "$self parsed response: ". Dumper($xml) if $DEBUG;

  #warn "\n".$xml->{'message'}."\n" unless $xml->{'id'} == 1 or not $WARN;

  $xml;

}

=back

=head1 BUGS

orderListByDate is unimplemented.

=head1 SEE ALSO

<http://www.arteraturbo.com>

=head1 AUTHOR

Ivan Kohler, E<lt>ivan-net-artera@420.amE<gt>

Freeside, open-source billing for ISPs: <http://www.sisd.com/freeside>

Not affiliated with Artera Group, Inc.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Ivan Kohler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

