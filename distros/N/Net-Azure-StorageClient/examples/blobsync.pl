#!/usr/bin/perl -w
use strict;
use lib qw( lib );
use Getopt::Long qw/:config posix_default no_ignore_case bundling auto_help/;
use Pod::Usage qw/pod2usage/;
use Net::Azure::StorageClient::Blob;
use Data::Dumper;
use threads;
use Time::HiRes;

my $account = '';
my $accesskey = '';

GetOptions(\my %options, qw/
    account=s
    accesskey=s
    direction=s
    path=s
    directory=s
    protocol=s
    excludes=s
    include_invisible=i
    silence=i
    debug=i
    use_thread=i
    measure=i
/) or pod2usage( 1 );

$account = $options{ account } unless $account;
$accesskey = $options{ accesskey } unless $accesskey;
my $direction = $options{ direction };
my $directory = $options{ directory };
my $path = $options{ path };
my $excludes = $options{ excludes };
my $include_invisible = $options{ 'include_invisible' };
my $silence = $options{ silence };
my $use_thread = $options{ use_thread };
my $measure = $options{ measure };
my $debug = $options{ debug };
my $protocol = $options{ protocol } || 'https';

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

if ( ! $direction || ! $path || ! $directory ) {
    die
    "Option '--direction', '--path' and '--directory' is required.";
}

if ( ( $direction ne 'upload' ) && ( $direction ne 'download' ) ) {
    die "Option '--direction' is 'upload' or 'download'.";
}

my $blobService = Net::Azure::StorageClient::Blob->new( account_name => $account,
                                                        primary_access_key => $accesskey,
                                                        protocol => $protocol,
);

my $params = { direction => $direction };
$params->{ include_invisible } = $include_invisible;
if ($excludes) {
    my @exclude_items = split( /,/, $excludes );
    $params->{ excludes } = \@exclude_items;
}
$params->{ use_thread } = $use_thread;

my $start = Time::HiRes::time;
my $res = $blobService->sync( $path, $directory, $params );
my $score = sprintf( "%0.2f", Time::HiRes::time - $start );

if (! $silence ) {
    if ( ( ref $res ) eq 'ARRAY' ) {
        if ( $debug ) {
            print Dumper $res;
        } else {
            for my $obj ( @$res ) {
                my $uri = $obj->base;
                my $path = $uri->path;
                my $meth = $obj->{ _request }->{ _method };
                print  $meth . ',' . $path . ',' . $obj->code . ',' . $obj->message . "\n";
            }
        }
    } elsif ( ( ref $res ) eq 'HASH' ) {
        if ( $debug ) {
            print Dumper $res;
        } else {
            my $removed_files = $res->{ removed_files };
            my $responses = $res->{ responses };
            for my $obj ( @$responses ) {
                my $uri = $obj->base;
                my $path = $uri->path;
                my $meth = $obj->{ _request }->{ _method };
                print  $meth . ',' . $path . ',' . $obj->code . ',' . $obj->message . "\n";
            }
            for my $file ( @$removed_files ) {
                print  ',' . $file . ",,Removed\n";
            }
        }
    } elsif (! $res ) {
        if ( $debug ) {
            print "Blob did not synchronize.\n";
        }
    }
    if ( $measure && (! $silence ) ) {
        print "Processing time ${score} second.\n";
    }
}

1;

__END__

=head1 NAME

Synchronize between the directory of blob storage and the local directory.

=head1 SYNOPSIS

  upload
    perl examples/blobsync.pl --account your_account --accesskey you_primary_access_key --direction upload --path container_name/directory_name --directory /path/to/local/directory [--use_thread 10 --excludes foo,bar --include_invisible 1 --silence 1 --measure 1 --debug 1]

  download
    perl examples/blobsync.pl --account your_account --accesskey you_primary_access_key --direction download --path container_name/directory_name --directory /path/to/local/directory [--use_thread 10 --excludes foo,bar --include_invisible 1 --silence 1 --measure 1 --debug 1]

=head1 AUTHOR

Junnama Noda <junnama@alfasado.jp>

=head1 COPYRIGHT

Copyright (C) 2013, Junnama Noda.

=head1 LICENSE

This program is free software;
you can redistribute it and modify it under the same terms as Perl itself.

=cut
