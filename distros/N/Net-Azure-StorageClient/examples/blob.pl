#!/usr/bin/perl

use warnings;
use strict;
use lib qw( lib );
use Getopt::Long qw/:config posix_default no_ignore_case bundling auto_help/;
use Pod::Usage qw/pod2usage/;
use Net::Azure::StorageClient::Blob;
use Data::Dumper;

my $account = '';
my $accesskey = '';

GetOptions(\my %options, qw/
    account=s
    accesskey=s
    method=s
    url=s
    path=s
    file=s
    protocol=s
    silence=i
    debug=i
/) or pod2usage( 1 );

$account = $options{ account } unless $account;
$accesskey = $options{ accesskey } unless $accesskey;
my $method = $options{ method };
my $url   = $options{ url };
if (! $url ) {
    $url = $options{ path };
}
my $file  = $options{ file };
my $protocol = $options{ protocol } || 'https';
my $silence = $options{ silence };
my $debug = $options{ debug };
if (! $file ) {
    $file = {};
}

if (! $account ) {
    print 'Please enter your account name of Windows Azure Blob Storage:';
    $account = <STDIN>;
    chomp( $account );
}

if (! $accesskey ) {
    print 'Please enter your primary access key of Windows Azure Blob Storage:';
    $accesskey = <STDIN>;
    chomp( $accesskey );
}

if ( (! $account ) || (! $accesskey ) ) {
    die
    'Your account and primary access key of Windows Azure Blob Storage are required.';
}

if (! $method ) {
    print 'Please enter method of StorageClient::Blob to call:';
    $method = <STDIN>;
    chomp( $method );
}

if (! $method ) {
    die
    "Option '--method' is required.";
}

my $blobService = Net::Azure::StorageClient::Blob->new( account_name => $account,
                                                        primary_access_key => $accesskey,
                                                        protocol => $protocol,
);

if (! $blobService->can( $method ) ) {
    die  "Unknown method '$method'.";
}

my $res = $blobService->$method( $url, $file );

if (! $silence ) {
    if ( $debug ) {
        print Dumper $res;
    } else {
        if ( ( ref $res ) eq 'HTTP::Response' ) {
            print $res->code . ':' . $res->message . "\n";
        }
    }
}

1;

__END__

=head1 NAME

Sample script for Net::Azure::StorageClient::Blob.

=head1 SYNOPSIS

  perl examples/blob.pl --account your_account --accesskey you_primary_access_key --method upload_blob --path container_name/README.txt --file README [--silence 1 --debug 1]

=head1 AUTHOR

Junnama Noda <junnama@alfasado.jp>

=head1 COPYRIGHT

Copyright (C) 2013, Junnama Noda.

=head1 LICENSE

This program is free software;
you can redistribute it and modify it under the same terms as Perl itself.

=cut
