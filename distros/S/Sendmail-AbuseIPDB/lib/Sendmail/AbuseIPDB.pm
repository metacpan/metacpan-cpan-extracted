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
our $VERSION = '0.10';

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
);


sub new( $@ )
{
    my $this = bless { %defaults }, shift;
    my %args = @_;
    unless( defined( $args{Key})) { croak( 'Key argument is mandatory, get your API key by creating an account' ); }
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


sub get( $$ )
{
    my $this = shift;
    my $ip = shift;

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


1;
__END__

=head1 NAME

Sendmail::AbuseIPDB - API access for IP address abuse database

=head1 SYNOPSIS

    use Sendmail::AbuseIPDB;

    my $db = Sendmail::AbuseIPDB->new(Key => '** your API key here **');

    my $ip = '31.210.35.146';                       # IP of sender
    my @all_data = $db->get( $ip );

    foreach my $d ( @all_data )
    {
        foreach my $c ( @{$d->{category}} )
        {
            print "DATE:$d->{created}   CATEGORY:" . $db->catg( $c ) . "\n";
        }
    }

=head1 DESCRIPTION

    Convenient toolbox for API access to https://www.abuseipdb.com/

    Potentially for other sites with compatible API if you want to change the BaseURL.

=head1 METHODS

=head2 new( Key => $key, ... )

    Additional parameters are: BaseURL, Days, Debug

=head2 get( $ip )

    Do a query to check an IP address. Returns array of hash references, looking similar to this:

        {
            'created' => 'Sun, 17 Sep 2017 04:53:45 +0000',
            'country' => 'Turkey',
            'isoCode' => 'TR',
            'ip' => '31.210.35.146',
            'category' => [
                            14
                          ]
        }


=head2 catg( $number )

    Convert the category from integer to printable string.


=head2 filter( $category, @data )

    Return an array of those members in @data that match the given category.
    The format of @data is same as the return array from get() so see above.
    The $category can be either a number, or a printable string.


=head2 report( $ip, $comment, @category_list )

    Report an abusive IP address back to the database.
    The comment can be "" empty string or any other brief comment to explain why
    you believe this IP has done something wrong.
    One or more categories must be included, these can be numbers or printable
    string categories. e.g. :

    $db->report( '111.119.210.10', 'Very annoying IP address', 'Brute-Force', 'Port Scan' );


=head1 SEE ALSO

    https://www.abuseipdb.com/api.html

    https://www.abuseipdb.com/categories

    Sendmail::PMilter

    Example program abuseipdb_milter.pl for a simple way to block suspicious senders.

=head1 AUTHOR

    <ttndy@cpan.org>

=head1 COPYRIGHT AND LICENSE

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself, either Perl version 5.10.1 or,
    at your option, any later version of Perl 5 you may have available.

=cut
