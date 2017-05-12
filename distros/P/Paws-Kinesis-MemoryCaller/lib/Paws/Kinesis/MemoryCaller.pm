package Paws::Kinesis::MemoryCaller;
use 5.008001;

our $VERSION = "0.09";

=head1 NAME

Paws::Kinesis::MemoryCaller - A Paws Caller with in-memory Kinesis.

=head1 SYNOPSIS

    my $kinesis = Paws->service('Kinesis',
        region      => 'N/A',
        caller      => Paws::Kinesis::MemoryCaller->new(),
        credentials => Paws::Credential::Environment->new(),
    );

    # or simply...

    my $kinesis = Paws::Kinesis::MemoryCaller->new_kinesis();

    # Then use $kinesis as you would normally, for example:

    # Put multiple records on a stream...
    $kinesis->PutRecords(%args);

    # Get records from a stream...
    $kinesis->GetRecords(%args);

=head1 DESCRIPTION

Paws::Kinesis::MemoryCaller implements Paws::Net::CallerRole which simulates its
own streams, shards and records in memory.

The following methods have been implemented:

=over

=item *

CreateStream

=item *

DescribeStream

=item *

GetRecords

=item *

GetShardIterator

=item *

PutRecord

=item *

PutRecords

=back

=cut

use Moose;
with "Paws::Net::CallerRole";

use namespace::autoclean;
use Data::UUID;
use List::AllUtils qw(first_index);
use MIME::Base64 qw(decode_base64);

use Paws;
use Paws::Credential::Environment;

use Paws::Kinesis::DescribeStreamOutput;
use Paws::Kinesis::GetRecordsOutput;
use Paws::Kinesis::GetShardIteratorOutput;
use Paws::Kinesis::PutRecordOutput;
use Paws::Kinesis::PutRecordsOutput;

use Paws::Kinesis::PutRecord;

use Paws::Kinesis::PutRecordsResultEntry;

use Paws::Kinesis::HashKeyRange;
use Paws::Kinesis::Record;
use Paws::Kinesis::Shard;
use Paws::Kinesis::SequenceNumberRange;
use Paws::Kinesis::StreamDescription;

has store => (is => 'ro', isa => 'HashRef', default => sub { +{} });
has shard_iterator__address => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
);

=head1 METHODS

=head2 new_kinesis

Shortcut method to create a new Kinesis service instance that uses this caller.
Equivalent to:

    Paws->service('Kinesis',
        caller      => Paws::Kinesis::MemoryCaller->new(),
        credentials => Paws::Credential::Environment->new(),
        region      => "N/A",
    );

=cut

sub new_kinesis {
    my $class = shift;

    return Paws->service('Kinesis',
        caller      => $class->new(),
        credentials => Paws::Credential::Environment->new(),
        region      => "N/A",
    );
}

sub caller_to_response {}

sub do_call {
    my $self = shift;
    my ($kinesis, $action) = @_;

    my $action_class = ref $action;

    my $method = {
        "Paws::Kinesis::CreateStream"       => "_create_stream",
        "Paws::Kinesis::DescribeStream"     => "_describe_stream",
        "Paws::Kinesis::GetRecords"         => "_get_records",
        "Paws::Kinesis::GetShardIterator"   => "_get_shard_iterator",
        "Paws::Kinesis::PutRecord"          => "_put_record",
        "Paws::Kinesis::PutRecords"         => "_put_records",
    }->{$action_class} or die "($action_class) is not implemented";

    $self->$method($action);
}

sub _create_stream {
    my $self = shift;
    my ($action) = @_;

    my $last_shard = $action->ShardCount - 1;
    $last_shard >= 0
        or die "ShardCount must be greater than zero to CreateStream";

    my $shard_id__records = {
        map { sprintf("shardId-%012d", $_) => [] }
        0..$last_shard
    };

    $self->store->{$action->StreamName} = $shard_id__records;

    return undef;
}

sub _get_shard_iterator {
    my $self = shift;
    my ($action) = @_;

    my $shard_iterator_type = $action->ShardIteratorType;

    my $method = {
        LATEST                  => "_get_shard_iterator_latest",
        TRIM_HORIZON            => "_get_shard_iterator_trim_horizon",
        AT_SEQUENCE_NUMBER      => "_get_shard_iterator_at_sequence_number",
        AFTER_SEQUENCE_NUMBER   => "_get_shard_iterator_after_sequence_number",
    }->{$shard_iterator_type}
        or die "ShardIteratorType($shard_iterator_type) is invalid or not implemented";

    my $shard_iterator = $self->$method(
        stream_name     => $action->StreamName,
        shard_id        => $action->ShardId,
        sequence_number => $action->StartingSequenceNumber,
    );

    return Paws::Kinesis::GetShardIteratorOutput->new(
        ShardIterator => $shard_iterator,
    );
}

sub _get_shard_iterator_after_sequence_number {
    my $self = shift;
    my %args = @_;

    my $index = $self->_get_index_by_sequence_number(%args);

    return $self->_create_shard_iterator(
        $args{stream_name},
        $args{shard_id},
        $index + 1,
    );
}

sub _get_shard_iterator_at_sequence_number {
    my $self = shift;
    my %args = @_;

    my $index = $self->_get_index_by_sequence_number(%args);

    return $self->_create_shard_iterator(
        $args{stream_name},
        $args{shard_id},
        $index,
    );
}

sub _get_index_by_sequence_number {
    my $self = shift;
    my %args = @_;

    my $stream_name = $args{stream_name};
    my $shard_id = $args{shard_id};
    my $sequence_number = $args{sequence_number}
        or die "StartingSequenceNumber is required";

    my $records = $self->_get_records_from_store($stream_name, $shard_id);

    return first_index {
        $_->SequenceNumber eq $sequence_number
    } @$records;
}

sub _get_shard_iterator_latest {
    my $self = shift;
    my %args = @_;

    my $stream_name = $args{stream_name};
    my $shard_id = $args{shard_id};

    my $records = $self->_get_records_from_store($stream_name, $shard_id);

    my $index = @$records ? scalar @$records : 0;

    return $self->_create_shard_iterator($stream_name, $shard_id, $index);
}

sub _get_shard_id__records {
    my $self = shift;
    my ($stream_name) = @_;

    my $shard_id__records = $self->store->{$stream_name}
        or die "StreamName($stream_name) does not exist";

    return $shard_id__records;
}

sub _get_records_from_store {
    my $self = shift;
    my ($stream_name, $shard_id) = @_;

    my $shard_id__records = $self->_get_shard_id__records($stream_name);

    my $records = $shard_id__records->{$shard_id}
        or die sprintf(
            "ShardId(%s) does not exist. ShardIds are (%s)",
            $shard_id,
            join(", ", sort { $a cmp $b } keys %$shard_id__records),
        );

    return $records;
}

sub _push_record_to_store {
    my $self = shift;
    my ($stream_name, $shard_id, $record) = @_;

    my $records = $self->_get_records_from_store($stream_name, $shard_id);
    push @$records, $record;
}

sub _get_shard_iterator_trim_horizon {
    my $self = shift;
    my %args = @_;

    my $stream_name = $args{stream_name};
    my $shard_id = $args{shard_id};

    return $self->_create_shard_iterator($stream_name, $shard_id, 0);
}

sub _create_shard_iterator {
    my $self = shift;
    my ($stream_name, $shard_id, $index) = @_;

    my $shard_iterator = Data::UUID->new->create_b64();

    $self->shard_iterator__address->{$shard_iterator} = {
        stream_name => $stream_name,
        shard_id => $shard_id,
        index => $index,
    };

    return $shard_iterator;
}

sub _describe_stream {
    my $self = shift;
    my ($action) = @_;

    my $stream_name = $action->StreamName;

    my $shard_ids = $self->_get_shard_ids_from_stream_name($stream_name);

    my $shards = [
        map {
            Paws::Kinesis::Shard->new(
                HashKeyRange => Paws::Kinesis::HashKeyRange->new(
                    EndingHashKey   => "",
                    StartingHashKey => "",
                ),
                SequenceNumberRange => Paws::Kinesis::SequenceNumberRange->new(
                    StartingSequenceNumber => "",
                ),
                ShardId => $_,
            )
        }
        @$shard_ids
    ];

    return Paws::Kinesis::DescribeStreamOutput->new(
        StreamDescription => Paws::Kinesis::StreamDescription->new(
            EnhancedMonitoring => [],
            HasMoreShards => "",
            RetentionPeriodHours => 24,
            Shards => $shards,
            StreamARN => "",
            StreamCreationTimestamp => "",
            StreamName => $stream_name,
            StreamStatus => "",
        ),
    );
}

sub _get_records {
    my $self = shift;
    my ($action) = @_;

    my $shard_iterator = $action->ShardIterator;
    my $limit = $action->Limit;

    my $address =
        $self->shard_iterator__address->{$shard_iterator}
            or die "ShardIterator($shard_iterator) does not exist";

    my $stream_name = $address->{stream_name};
    my $shard_id = $address->{shard_id};
    my $index = $address->{index};

    my @stream_shard_records =
        @{$self->_get_records_from_store($stream_name, $shard_id)};

    my $end_index = defined $limit
        ? $index + $limit - 1
        : scalar(@stream_shard_records) - 1;

    my $records = [ grep { $_ } @stream_shard_records[$index..$end_index] ];

    my $next_shard_iterator = $self->_create_shard_iterator(
        $stream_name, $shard_id, $index + scalar(@$records),
    );

    return Paws::Kinesis::GetRecordsOutput->new(
        Records => $records,
        NextShardIterator => $next_shard_iterator,
    );
}

sub _put_record {
    my $self = shift;
    my ($action) = @_;

    my $stream_name = $action->StreamName;
    my $data = $action->Data;

    decode_base64($data) && length($data) % 4 == 0
        or die "Data($data) is not valid Base64";

    my $shard_id = $self->_get_shard_id_from_partition_key($action);
    my $records = $self->_get_records_from_store($stream_name, $shard_id);

    my $sequence_number = scalar(@$records + 1);

    my $record = Paws::Kinesis::Record->new(
        Data            => $data,
        PartitionKey    => $action->PartitionKey,
        SequenceNumber  => $sequence_number,
    );

    $self->_push_record_to_store($stream_name, $shard_id, $record);

    return Paws::Kinesis::PutRecordOutput->new(
        ShardId => $shard_id,
        SequenceNumber => $sequence_number,
    );
}

sub _put_records {
    my $self = shift;
    my ($action) = @_;

    my $stream_name = $action->StreamName;

    my $records = [
        map {
            my $record = $_;

            my $data = $record->Data;
            my $paritition_key = $record->PartitionKey;

            my $put_record_output = $self->_put_record(
                Paws::Kinesis::PutRecord->new(
                    PartitionKey => $paritition_key,
                    StreamName   => $stream_name,
                    Data         => $data,
                ),
            );

            Paws::Kinesis::PutRecordsResultEntry->new(
                ShardId        => $put_record_output->ShardId,
                SequenceNumber => $put_record_output->SequenceNumber,
            );
        }
        @{$action->Records}
    ];

    return Paws::Kinesis::PutRecordsOutput->new(
        Records => $records,
    );
}

sub _get_shard_id_from_partition_key {
    my $self = shift;
    my ($action) = @_;

    my $paritition_key = $action->PartitionKey;
    my $stream_name = $action->StreamName;

    my $shard_ids = $self->_get_shard_ids_from_stream_name($stream_name);

    die "stream ($stream_name) has no shards" unless scalar @$shard_ids;

    my $index = length($paritition_key) % scalar(@$shard_ids);
    return $shard_ids->[$index];
}

sub _get_shard_ids_from_stream_name {
    my $self = shift;
    my ($stream_name) = @_;

    my $shard_id__records = $self->_get_shard_id__records($stream_name);

    return [ sort { $a cmp $b } keys %$shard_id__records ],
}

__PACKAGE__->meta->make_immutable;

=head1 LICENSE

Copyright (C) Keith Broughton.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DEVELOPMENT

=head2 Author

Keith Broughton C<< <keithbro [AT] cpan.org> >>

=head2 Bug reports

Please report any bugs or feature requests on GitHub:

L<https://github.com/keithbro/Paws-Kinesis-MemoryCaller/issues>.

=cut
