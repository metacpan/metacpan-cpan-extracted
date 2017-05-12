#!/usr/bin/perl 


use strict;
use warnings;

use StartCom::API;

use Pod::Usage;
use Getopt::Long;


Getopt::Long::Configure("no_ignore_case");
pod2usage({'-exitval' => 3, '-verbose' => 2})
	unless $ARGV[0] && $ARGV[0] =~ /^(?:apply|retrieve)/;

my ($opts, $params);
$opts->{'mode'} = shift @ARGV;
GetOptions(
	'orderid=s' => \$params->{'orderID'},
	'csr=s' => \$opts->{'csr'},
	'c|clientcert=s' => \$opts->{'client_cert'},
	'k|clientkey=s' => \$opts->{'client_key'},
	'i|tokenID=s' => \$opts->{'tokenID'},
	'd|domain=s' => \@{$params->{'domains'}},
	't|type=s' => \$params->{'certType'},
	'o|output=s' => \$opts->{'output'},
	'h|help' => sub {pod2usage({'-exitval' => 3, '-verbose' => 2})}
) or pod2usage({'-exitval' => 3, '-verbose' => 0});
foreach (keys %$params) {delete $params->{$_} unless defined $params->{$_}};

pod2usage({'-exitval' => 3, '-verbose' => 0}) unless
	defined $opts->{'client_cert'} && defined $opts->{'client_key'} &&
	defined $opts->{'tokenID'};

die "cannot find client cert file" unless -e $opts->{'client_cert'};
die "cannot find client key file" unless -e $opts->{'client_key'};

my $api = new StartCom::API;

$api->tokenID($opts->{'tokenID'});
$api->client_cert($opts->{'client_cert'});
$api->client_key($opts->{'client_key'});
$api->testmode(1);

my $res;

if ($opts->{'mode'} eq 'apply') {
	pod2usage({'-exitval' => 3, '-verbose' => 0}) unless $params->{'domains'} &&
		$opts->{'csr'};
	open CSR, "<".$opts->{'csr'} or die $@;
	while (<CSR>) {$params->{'csr'} .= $_}
	close CSR;
	$res = $api->apply($params);
} elsif ($opts->{'mode'} eq 'retrieve') {
	pod2usage({'-exitval' => 3, '-verbose' => 0}) unless $params->{'orderID'};
	$res = $api->retrieve($params->{'orderID'});
}

unless ($res) {
	printf STDERR "an error occurred: %s\n", $api->errormsg;
	exit 255
}

if ($opts->{'output'}) {
	open OUT, ">".$opts->{'output'} or die $@;
	print OUT $api->certificate . $api->intermediate;
	close OUT
} else {
	print $api->certificate . $api->intermediate;
}

printf STDERR "orderNo: %s\n", $api->orderNo;
printf STDERR "orderID %s\n", $api->orderID;


__END__

=head1 NAME

StartAPI - apply for and retrieve ssl certificates from StartCom

=head1 VERSION

0.1

=head1 SYNOPSIS

 StartAPI <apply|retrieve> [OPTIONS]

=head1 OPTIONS

=over 8

=item B<--clientcert> I<CCERT>

Mandatory. Sets the path to the client certificate file.

=item B<--clientkey> I<CKEY>

Mandatory. Sets the path to the client key file.

=item B<--tokenID> I<TOKEN>

Mandatory. Sets the API token.

=item B<--orderid> I<ID>

Mandatory when retrieving certificate. Selects the order id of the certificate.

=item B<--csr> I<CSR>

Mandatory when applying for a certificate. Sets the path to the csr file.

=item B<--domain> I<DOMAIN>

Mandatory when applying for a certificate. Sets the domain name. Can be set multiple times.

=item B<--type> I<TYPE>

Optional. Sets the certificate type (C<DVSSL>, C<IVSSL>, C<OVSSL> or C<EVSSL>). Defaults to C<DVSSL>.

=item B<--output> I<FILE>

Optional. Saves the certificate + intermediate to I<FILE>. If not set, the certificates will be sent to C<STDOUT>.

=back

=head1 DESCRIPTION

Applies for or retrieves ssl certificates from StartCom.

=head1 EXAMPLES

=head2 apply for a new certificate

 $ h=test.yourdomain.example

 $ openssl req -new -newkey rsa:4096 -nodes \
     -keyout ${h}.key -out ${h}.csr -subj "/CN=${h}"
 $ StartAPI apply -c ccert.pem -k ccert.key -i tk_123456789 \
     --csr ${h}.csr -d ${h} -o ${h}.pem

=head2 retrieve certificate

 $ StartAPI retrieve -c ccert.pem -k ccert.key -i tk_123456789 \
     --orderid 11111111-2222-3333-4444-555555555555

=head1 DEPENDENCIES

=over 4

=item * L<StartCom::API>

=back

=head1 AUTHOR

Philippe Kueck <projects at unixadm dot org>

=cut

