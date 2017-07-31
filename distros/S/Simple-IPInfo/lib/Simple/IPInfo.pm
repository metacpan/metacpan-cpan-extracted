# ABSTRACT: Get IP/IPList Info (location, as number, etc)
package Simple::IPInfo;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  read_ipinfo
  iterate_ipinfo
  get_ipinfo

  get_ip_loc
  get_ip_as

  ip_to_inet
  inet_to_ip
  cidr_to_range
);
use utf8;
use Data::Validate::IP qw/is_ipv4 is_ipv6 is_public_ipv4/;
use SimpleR::Reshape;
use Data::Dumper;
use JSON;
use File::Spec;
use Net::CIDR qw/cidr2range/;
use Socket qw/inet_aton inet_ntoa/;
use Memoize;
memoize( 'read_ipinfo' );

our $DEBUG = 0;

our $VERSION = 0.12;

my ( $vol, $dir, $file ) = File::Spec->splitpath( __FILE__ );
our $IPINFO_LOC_F = File::Spec->catpath( $vol, $dir, "inet_loc.csv" );
our $IPINFO_AS_F  = File::Spec->catpath( $vol, $dir, "inet_as.csv" );

my @key = qw/country area isp country_code area_code isp_code as/;
our %UNKNOWN = map { $_ => '' } @key;
our %ERROR   = map { $_ => 'error' } @key;
our %LOCAL   = map { $_ => 'local' } @key;

sub cidr_to_range {
  my ( $cidr, %opt ) = @_;
  $opt{inet} //= 1;

  my ( $addr_range ) = cidr2range( $cidr );
  my @addr = split /-/, $addr_range;
  return @addr unless ( $opt{inet} );

  my @inet = map { unpack( 'N', inet_aton( $_ ) ) } @addr;
  return @inet;
}

sub get_ipinfo {
  my ( $ip_list, %opt ) = @_;
  $opt{i}               ||= 0;
  $opt{return_arrayref} //= 1;

  my $i       = 0;
  my $ip_inet = read_table(
    $ip_list,
    conv_sub => sub {
      my ( $r ) = @_;
      my ( $ip, $inet, $rr ) = calc_ip_inet( $r->[ $opt{i} ], \%opt );
      return [ $i++, $inet ];
    },
    return_arrayref => 1,
  );
  my @sorted_ip_inet = sort { $a->[1] <=> $b->[1] } @$ip_inet;

  my $get_ip_info = iterate_ipinfo(
    \@sorted_ip_inet,
    i               => 1,
    ipinfo_file     => $opt{ipinfo_file},
    ipinfo_names    => $opt{ipinfo_names},
    return_arrayref => 1,
  );

  my @sorted_ip_info = sort { $a->[0] <=> $b->[0] } @$get_ip_info;

  $i = 0;
  my $start_col = $opt{reserve_inet} ? 1 : 2;
  my $end_col   = $#{ $sorted_ip_info[0] };
  my $res       = read_table(
    $ip_list,
    %opt,
    conv_sub => sub {
      my ( $r ) = @_;
      return [ @$r, @{ $sorted_ip_info[ $i++ ] }[ $start_col .. $end_col ] ];
    },
  );

  return $res || $opt{write_file};
} ## end sub get_ipinfo

sub iterate_ipinfo {

  #deal with large ip_list file, ip_list is inet-sorted
  my ( $ip_list, %opt ) = @_;
  $opt{i}               ||= 0;
  $opt{return_arrayref} ||= 0;
  $opt{ipinfo_file}  ||= $IPINFO_LOC_F;
  $opt{ipinfo_names} ||= [qw/country area isp country_code area_code isp_code/];

  my $ip_info = read_ipinfo( $opt{ipinfo_file} );
  my $n       = $#$ip_info;

  my ( $i, $ir ) = ( 0, $ip_info->[0] );
  my ( $s, $e ) = @{$ir}{qw/s e/};

  my $res = read_table(
    $ip_list,
    conv_sub => sub {
        my ( $r ) = @_;
        my ( $ip, $inet, $rr ) = calc_ip_inet( $r->[ $opt{i} ], \%opt );

        return [ @$r, @{$rr}{ @{ $opt{ipinfo_names} } } ] if($rr);

        #start from i=0
        if($i>$n){
            $i = 0;
            ( $s, $e ) = @{$ip_info->[$i]}{qw/s e/};
        }

        #<- to nearby $i
        while($inet<$s and $i>0){
            $i = int($i/2);
            ( $s, $e ) = @{$ip_info->[$i]}{qw/s e/};
        }

        #-> to nearby $i
        while ( $inet > $e and $i < $n ) {
            $i++;
            $ir = $ip_info->[$i];
            ( $s, $e ) = @{$ir}{qw/s e/};
        }

        my $res_r;
        if ( $inet >= $s and $inet <= $e and $i <= $n ) {
            $res_r = $ir;
            print "$i : $ip, start $res_r->{s}, end $res_r->{e}, inet $inet\n" if ( $DEBUG );
        }elsif ( $inet < $s or $i > $n ) {
                $res_r = \%UNKNOWN;
        }

        return [ @$r, @{$res_r}{ @{ $opt{ipinfo_names} } } ];
    },
    %opt,
  );

  print "\n" if ( $DEBUG );
  return $res || $opt{write_file};
} ## end sub iterate_ipinfo

sub inet_to_ip {
  my ( $inet ) = @_;
  return inet_ntoa( pack( 'N', $inet ) );
}

sub ip_to_inet {
  my ( $ip ) = @_;
  return ( -1, \%ERROR ) unless ( is_ip( $ip ) );
  my $inet = unpack( "N", inet_aton( $ip ) );
  return ( $inet, \%LOCAL ) unless ( is_public_ip( $ip ) );
  return ( $inet, undef );
}

sub calc_ip_inet {
  my ( $c, $opt ) = @_;

  my $ip = $c =~ /^\d+$/ ? inet_to_ip( $c ) : $c;

  my @res = ( $ip, ip_to_inet( $ip ) );

  #$res[0]=~s/\.\d+$/.0/ if($opt->{use_ip_c});

  return @res;
}

sub get_ip_as {
  my ( $ip_list, %opt ) = @_;
  $opt{ipinfo_file}  = $IPINFO_AS_F;
  $opt{ipinfo_names} = [qw/as/];
  return get_ipinfo( $ip_list, %opt );
}

sub get_ip_loc {
  my ( $ip_list, %opt ) = @_;
  $opt{ipinfo_file} = $IPINFO_LOC_F;
  return get_ipinfo( $ip_list, %opt );
}

sub read_ipinfo {
    my ( $f, $charset ) = @_;
    $f //= $IPINFO_LOC_F;
    $charset //= 'utf8';

    my @d;
    open my $fh, "<:$charset", $f;
    chomp( my $h = <$fh> );
    my @head = split /,/, $h;
    while ( my $c = <$fh> ) {
        chomp( $c );
        my @line = split /,/, $c;
        my %k = map { $head[$_] => $line[$_] } ( 0 .. $#head );
        push @d, \%k;
    }
    close $fh;
    return \@d;
} ## end sub read_ipinfo

sub is_ip {
  my ( $ip ) = @_;
  return 1 if ( is_ipv4( $ip ) );
  return 1 if ( is_ipv6( $ip ) );
  return;
}

sub is_public_ip {
  my ( $ip ) = @_;
  return 1 if ( is_public_ipv4( $ip ) );
  return;
}

1;
