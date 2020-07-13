#!perl
# ABSTRACT: 'threads' version of object representing Blobs in Azure Blob Storage

use strict;
use warnings;
use v5.10;

package Net::Azure::StorageClient::Blob::Thread;
$Net::Azure::StorageClient::Blob::Thread::VERSION = '0.6';
use parent qw/Net::Azure::StorageClient::Blob/;
use threads;
use Thread::Semaphore;

use namespace::clean;

sub download_use_thread {
    my ( $self, $args ) = @_;
    my $thread = $args->{ thread } || 10;
    my $semaphore = Thread::Semaphore->new( $thread );
    my $download_items = $args->{ download_items };
    my $params = $args->{ params };
    my $container_name = $args->{ container_name };
    my %th;
    for my $key ( keys %$download_items ) {
        my $item;
        if ( $self->{ container_name } ) {
            $item = $key;
        } else {
            $item = $container_name . '/' . $key,
        }
        $th{ $key } = threads->new(\&_download,
                                    $self,
                                    $item,
                                    $download_items->{ $key },
                                    $params,
                                    $semaphore );
    }
    my @responses;
    for my $key ( keys %$download_items ) {
        my ( $res ) = $th{ $key }->join();
        push ( @responses, $res );
    }
    return @responses;
}

sub _download {
    my ( $self, $from, $to, $params, $semaphore ) = @_;
    $semaphore->down();
    $params->{ force } = 1;
    my $res = $self->download( $from, $to, $params );
    $semaphore->up();
    return $res;
}

sub upload_use_thread {
    my ( $self, $args ) = @_;
    my $thread = $args->{ thread } || 10;
    my $semaphore = Thread::Semaphore->new( $thread );
    my $upload_items = $args->{ upload_items };
    my $params = $args->{ params };
    my %th;
    for my $key ( keys %$upload_items ) {
        $th{ $key } = threads->new(\&_upload,
                                    $self,
                                    $key,
                                    $upload_items->{ $key },
                                    $params,
                                    $semaphore );
    }
    my @responses;
    for my $key ( keys %$upload_items ) {
        my ( $res ) = $th{ $key }->join();
        push ( @responses, $res );
    }
    return @responses;
}

sub _upload {
    my ( $self, $from, $to, $params, $semaphore ) = @_;
    $semaphore->down();
    $params->{ force } = 1;
    my $res = $self->upload( $from, $to, $params );
    $semaphore->up();
    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Azure::StorageClient::Blob::Thread - 'threads' version of object representing Blobs in Azure Blob Storage

=head1 VERSION

version 0.6

=head1 AUTHOR

Junnama Noda <junnama@alfasado.jp>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Junnama Noda.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
