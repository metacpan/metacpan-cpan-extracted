package Sendmail::AbuseIPDB;

use 5.010001;
use strict;
use warnings;
use Carp;

use URI;
use JSON; # imports encode_json, decode_json, to_json and from_json.

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ();
our @EXPORT = ();
our $VERSION = '0.21';

my @categories = (
              '',                     '',             '', 'Fraud Orders',  'DDoS Attack', #   0  ...   4
              '',                     '',             '',             '',   'Open Proxy', #   5  ...   9
      'Web Spam',           'Email Spam',             '',             '',    'Port Scan', #  10  ...  14
       'Hacking',                     '',             '',  'Brute-Force',  'Bad Web Bot', #  15  ...  19
'Exploited Host',       'Web App Attack',          'SSH', 'IoT Targeted',             '', #  20  ...  25
);

my %categories;  # Reverse direction lookup
for( my $i = 0; $i < scalar( @categories ); ++$i ) { $categories{$categories[$i]} = $i; }
delete( $categories{''});

my %defaults = (
    'BaseURL'   => 'https://www.abuseipdb.com/',
    'Days'      =>                           30,
    'Debug'     =>                            0,
    'Key'       =>                           '',
    'v2Key'     =>                           '',
);


sub new( $@ )
{
    my $this = bless { %defaults }, shift;
    my %args = @_;
    unless( defined( $args{Key})
        or defined( $args{v2Key})) { croak( 'Key argument is mandatory, get your API key by creating an account' ); }
    if( defined( $args{v2Key}))
    {
        # Insist on hex keys
        if( $args{v2Key} =~ m{([0-9a-fA-F]+)})
        {
            if( $1 ne $args{v2Key})
            {
                croak( "V2 Key must be hex" );
            }
        }
    }
    foreach my $k ( keys( %$this ))
    {
        if( defined( $args{ $k } )) { $this->{ $k } = $args{ $k }; }
        delete $args{ $k };
    }
    foreach my $k ( keys( %args ))
    {
        croak( "Unknown argument $k" );
    }

    if( $this->{Debug} ) { use Data::Dumper; print STDERR Dumper( $this ); }
    return( $this );
}


sub v2get( $$ )
{
    my $this = shift;
    my $ip = shift;

    my $url = URI->new( "$this->{BaseURL}api/v2/check" );
    $url->query_form( ipAddress => $ip, maxAgeInDays => $this->{Days});

    if( $this->{BaseURL} eq 'test://' )
    {
        if(      $ip eq '192.168.0.1' ) {   return( %categories );      }
        elsif(   $ip eq '192.168.0.3' ) {   return( $url->as_string );  }
    }

    my $fh;
    my $cmd = "/usr/bin/curl -H 'Accept: application/json' -H 'Key: $this->{v2Key}' -s '$url'";
    if( $this->{Debug})
    {
        print STDERR "CMD:   $cmd\n";
    }
    open( $fh, '-|', $cmd );
    unless( $fh ) { croak( "Cannout pipe from curl" ); }
    my $json = '';
    while( <$fh> )
    {
        $json .= $_;
    }
    if ($this->{Debug})
    {
        print STDERR "JSON:  $json\n";
    }

    my $result = from_json( $json );
    if( $this->{Debug})
    {
        require Data::Dumper;
        print STDERR "RESULT:" . Dumper( $result );
    }

    if( ref($result) eq 'HASH' )
    {
        return( $result );
    }

    if( ref($result) eq 'ARRAY' )
    {
        return( @$result );
    }

    return();
}


sub get( $$ )
{
    my $this = shift;
    my $ip = shift;

    if( defined( $this->{v2Key}) and length( $this->{v2Key}) > 2 )
    {
        # Use v2 API by preference
        return( $this->v2get( $ip ));
    }

    my $url = URI->new( "$this->{BaseURL}check/$ip/json" );
    $url->query_form( key => $this->{Key}, days => $this->{Days});

    if( $this->{BaseURL} eq 'test://' )
    {
        if(      $ip eq '192.168.0.1' ) {   return( %categories );      }
        elsif(   $ip eq '192.168.0.3' ) {   return( $url->as_string );  }
    }

    my $fh;
    my $cmd = "/usr/bin/curl -s '$url'";
    if( $this->{Debug})
    {
        print STDERR "CMD:   $cmd\n";
    }
    open( $fh, '-|', $cmd );
    unless( $fh ) { croak( "Cannout pipe from curl" ); }
    my $json = '';
    while( <$fh> )
    {
        $json .= $_;
    }
    if ($this->{Debug})
    {
        print STDERR "JSON:  $json\n";
    }

    my $result = from_json( $json );
    if( $this->{Debug})
    {
        require Data::Dumper;
        print STDERR "RESULT:" . Dumper( $result );
    }

    if( ref($result) eq 'HASH' )
    {
        return( $result );
    }

    if( ref($result) eq 'ARRAY' )
    {
        return( @$result );
    }

    return();
}


sub catg( $$ )
{
    my $this = shift;
    return( $categories[ shift ]);
}


sub filter( $$@ )
{
    my $this = shift;
    my @result;
    my $category = shift;

    unless( $category =~ m{^[0-9]+$})
    {
        my $c = $categories{ $category };
        unless( defined( $c ))
        {
            croak( "Unknown category $category" );
        }
        $category = $c;
    }
    while( @_ )
    {
        my $item = shift;
        foreach my $c ( @{$item->{category}} )
        {
            if( $c == $category )
            {
                push( @result, $item );
                last;
            }
        }
    }
    return( @result );
}


sub report( $$$@ )
{
    my $this = shift;
    my $ip = shift;
    my $comment = shift;
    my @catg = ();
    my $category;

    while( @_ )
    {
        $category = shift;
        unless( $category =~ m{^[0-9]+$})
        {
            my $c = $categories{ $category };
            unless( defined( $c ))
            {
                croak( "Unknown category $category" );
            }
            $category = $c;
        }
        push @catg, $category;
    }
    $category = join( ',', @catg );

    my $url = URI->new( "$this->{BaseURL}report/json" );
    $url->query_form( key => $this->{Key}, category => $category, comment => $comment, ip => $ip );

    if( $this->{BaseURL} eq 'test://' )
    {
        if(   $ip eq '192.168.0.3' ) {   return( $url->as_string );  }
    }

    my $fh;
    my $cmd = "/usr/bin/curl -s '$url'";
    if( $this->{Debug})
    {
        print STDERR "CMD:   $cmd\n";
    }
    open( $fh, '-|', $cmd );
    unless( $fh ) { croak( "Cannout pipe from curl" ); }
    my $json = '';
    while( <$fh> )
    {
        $json .= $_;
    }
    if ($this->{Debug})
    {
        print STDERR "JSON:  $json\n";
    }

    my $result = from_json( $json );
    if( $this->{Debug})
    {
        require Data::Dumper;
        print STDERR "RESULT:" . Dumper( $result );
    }

    if( ref($result) eq 'HASH' )
    {
        return( $result );
    }

    die( "Bad result from server: $json" );
}


sub blacklist( $$ )
{
    my $this = shift;
    my $confidence = shift;
    if( defined( $confidence ))
    {
        $confidence = int( $confidence );                  # Just in case
    }
    else
    {
        $confidence = 100;                                 # By default, the worst of the worst
    }

    my $url = URI->new( "$this->{BaseURL}api/v2/blacklist" );
    $url->query_form( confidenceMinimum => $confidence );

    if( $this->{BaseURL} eq 'test://' )
    {
        die( "NOT IMPLEMENTED" );
    }

    my $fh;
    my $cmd = "/usr/bin/curl -H 'Accept: application/json' -H 'Key: $this->{v2Key}' -s '$url'";
    if( $this->{Debug})
    {
        print STDERR "CMD:   $cmd\n";
    }
    open( $fh, '-|', $cmd );
    unless( $fh ) { croak( "Cannout pipe from curl" ); }
    my $json = '';
    while( <$fh> )
    {
        $json .= $_;
    }
    if ($this->{Debug})
    {
        print STDERR "JSON:  $json\n";
    }

    my $result = from_json( $json );
    if( $this->{Debug})
    {
        require Data::Dumper;
        print STDERR "RESULT:" . Dumper( $result );
    }

    return $result;    
}


1;
__END__

=head1 NAME

Sendmail::AbuseIPDB - API access for IP address abuse database

=head1 SYNOPSIS

    use Sendmail::AbuseIPDB;

    # CURRENT: For v2 API like this:
    my $db = Sendmail::AbuseIPDB->new( v2Key => '** your v2 API key here **' );

    # OBSOLETE: For v1 API like this:
    my $db = Sendmail::AbuseIPDB->new( Key => '** your API key here **' );

    my $ip = '190.180.154.131';                       # IP of sender
    my $result = $db->get( $ip );

    if( defined( $result->{data} ))
    {
        print "Abuse confidence of $ip is $result->{data}{abuseConfidenceScore}\n";
    }
    else
    {
        warn( "Failed to get result for $ip" );
    }


=head1 DESCRIPTION

    Convenient toolbox for Version-2 API access to https://www.abuseipdb.com/

    Potentially for other sites with compatible API if you want to change the BaseURL.

=head1 METHODS

=head2 new( v2Key => $key, ... )

    Additional parameters are: BaseURL, Days, Debug

    Old parameter was Key which is for v1 API calls, supported for compatibility,
    but most of the old v1 API has been shut down by the provider.


=head2 get( $ip )

    Do a query to check an IP address. Returns single reference, looking similar to this:

       {
           'data' => {
               'isp' => 'Cicomsa S.A.',
               'lastReportedAt' => '2021-06-25T04:24:08+00:00',
               'domain' => 'mshquil.com.ar',
               'numDistinctUsers' => 8,
               'ipVersion' => 4,
               'abuseConfidenceScore' => 67,
               'isWhitelisted' => 0,
               'hostnames' => [],
               'countryCode' => 'AR',
               'totalReports' => 50,
               'usageType' => 'Fixed Line ISP',
               'isPublic' => 1,
               'ipAddress' => '190.180.154.131'
            }
       }


=head2 report( $ip, $comment, @category_list )

    Report an abusive IP address back to the database.
    The comment can be "" empty string or any other brief comment to explain why
    you believe this IP has done something wrong.
    One or more categories must be included, these can be numbers or printable
    string categories. e.g. :

    $db->report( '142.93.218.225', 'Very annoying IP address', 'Brute-Force', 'Port Scan' );

=head3 Warning copied from provider documentation.

    STRIP ANY PERSONALLY IDENTIFIABLE INFORMATION (PPI);
    WE ARE NOT RESPONSIBLE FOR PPI YOU REVEAL.


=head2 blacklist( $confidence )

    Get a list of IP addresses where $confidence is the minimum confidence score
    (percentage) that this IP address is likely to be abusive.
    Depending on your account the server might force your $confidence value upwards
    (in the case of free accounts only 100% confidence results are provided).

    Result format is like this:

        {
            'data' => [
                {
                    'ipAddress' => '60.29.254.252',
                    'abuseConfidenceScore' => '100',
                    'totalReports' => 4723
                },
                {
                    'ipAddress' => '118.24.214.107',
                    'abuseConfidenceScore' => '100',
                    'totalReports' => 4712
                },
                # ... many others ...
            ],
            'meta' => {
                'generatedAt' => '2019-01-01T01:01:01+00:00'
            }
        }

    It requires apallingly bad behaviour to achieve 100% confidence of abuse,
    so the worst offender IP addresses should be filtered without remorse.
    When using the "ipset" Linux kernel feature, set a reasonable timeout so that
    old IP addresses will automatically be removed from the list once they are
    no longer abusive. Hopefully most compromised systems do get cleaned up.


=head1 SEE ALSO

    https://docs.abuseipdb.com/#check-endpoint

    https://www.abuseipdb.com/categories

    Sendmail::PMilter

    Example program abuseipdb_milter.pl for a simple way to block suspicious senders.

    Example program abuseipdb_blacklist_ipset.pl to feed into "ipset restore".

=head1 AUTHOR

    <ttndy@cpan.org>

=head1 COPYRIGHT AND LICENSE

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself, either Perl version 5.10.1 or,
    at your option, any later version of Perl 5 you may have available.

=cut
