package Net::Riak::MapReduce;
{
  $Net::Riak::MapReduce::VERSION = '0.1702';
}

# ABSTRACT: Allows you to build up and run a map/reduce operation on Riak

use JSON;
use Moose;
use Scalar::Util;

use Data::Dumper;

use Net::Riak::LinkPhase;
use Net::Riak::MapReducePhase;

with 'Net::Riak::Role::Base' =>
  {classes => [{name => 'client', required => 1}]};

has phases => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[Object]',
    auto_deref => 1,
    lazy       => 1,
    default    => sub { [] },
    handles    => {
        get_phases => 'elements',
        add_phase  => 'push',
        num_phases => 'count',
        get_phase  => 'get',
    },
);
has inputs_bucket => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_inputs_bucket',
);
has inputs => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef]',
    handles => {add_input => 'push',},
    default => sub { [] },
);
has input_mode => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_input_mode',
);

sub add {
    my $self = shift;
    my $arg  = shift;

    if (ref $arg eq 'ARRAY') {
        do{
            $self->add_input($arg);
        }while($arg = shift @_);

        return $self;
    }

    if (!scalar @_) {
        if ($arg->isa('Net::Riak::Object')) {
            $self->add_object($arg);
        } elsif ($arg->isa('Net::Riak::Bucket')) {
            $self->add_bucket($arg->name);
        } else {
            $self->add_bucket($arg);
        }
    }
    else {
        $self->add_bucket_key_data($arg, @_);
    }
    $self;
}

sub add_object {
    my ($self, $obj) = @_;
    $self->add_bucket_key_data($obj->bucket->name, $obj->key);
}

sub add_bucket_key_data {
    my ($self, $bucket, $key, $data) = @_;
    if ($self->has_input_mode && $self->input_mode eq 'bucket') {
        croak("Already added a bucket, can't add an object");
    }
    else {
        $self->add_input([$bucket, $key, $data]);
    }
}

sub add_bucket {
    my ($self, $bucket) = @_;
    $self->input_mode('bucket');
    $self->inputs_bucket($bucket);
    $self;
}

sub link {
    my ($self, $bucket, $tag, $keep) = @_;
    $bucket ||= '_';
    $tag    ||= '_';
    $keep   ||= JSON::false;

    $self->add_phase(
        Net::Riak::LinkPhase->new(
            bucket => $bucket,
            tag    => $tag,
            keep   => $keep
        )
    );
}

sub map {
    my ($self, $function, %options) = @_;

    my $map_reduce = Net::Riak::MapReducePhase->new(
        type     => 'map',
        function => $function,
        keep     => $options{keep} ? JSON::true : JSON::false,
        arg      => $options{arg} || [],
    );
    $self->add_phase($map_reduce);
    $self;
}

sub reduce {
    my ($self, $function, %options) = @_;

    my $map_reduce = Net::Riak::MapReducePhase->new(
        type     => 'reduce',
        function => $function,
        keep     => $options{keep} || JSON::false,
        arg      => $options{arg} || [],
    );
    $self->add_phase($map_reduce);
    $self;
}

sub run {
    my ($self, $timeout) = @_;

    my $num_phases = $self->num_phases;
    my $keep_flag  = 0;
    my $query      = [];

    my $total_phase = $self->num_phases;
    foreach my $i (0 .. ($total_phase - 1)) {
        my $phase = $self->get_phase($i);
        if ($i == ($total_phase - 1) && !$keep_flag) {
            $phase->keep(JSON::true);
        }
        $keep_flag = 1 if ($phase->{keep}->isa(JSON::true));
        push @$query, $phase->to_array;
    }

    my $inputs;
    if ($self->has_input_mode && $self->input_mode eq 'bucket' && $self->has_inputs_bucket) {
        $inputs = $self->inputs_bucket;
    }else{
        $inputs = $self->inputs;
    }

    my $job = {inputs => $inputs, query => $query};

    # how phases set to 'keep'.
    my $p = scalar ( grep { $_->keep } $self->phases);

    my $result = $self->client->execute_job($job, $timeout, $p);

    my @phases = $self->phases;
    if (ref $phases[-1] ne 'Net::Riak::LinkPhase') {
        return $result;
    }

    my $a = [];
    foreach (@$result) {
        my $l = Net::Riak::Link->new(
            bucket => Net::Riak::Bucket->new(name => $_->[0], client => $self->client),
            key    => $_->[1],
            tag    => $_->[2],
            client => $self->client
        );
        push @$a, $l;
    }
    return $a;
}

1;

__END__

=pod

=head1 NAME

Net::Riak::MapReduce - Allows you to build up and run a map/reduce operation on Riak

=head1 VERSION

version 0.1702

=head1 SYNOPSIS

    use Net::Riak;

    my $riak = Net::Riak->new( host => "http://10.0.0.127:8098/" );
    my $bucket = $riak->bucket("Cats");

    my $query = $riak->add("Cats");
    $query->map(
        'function(v, d, a) { return [v]; }',
        arg => [qw/some params to your function/]
    );

    $query->reduce("function(v) { return [v];}");
    my $json = $query->run(10000);

    # can also be used like:

    my $query = Net::Riak::MapReduce->new(
        client => $riak->client
    );

    # named functions
    my $json = $query->add_bucket('Dogs')
        ->map('Riak.mapValuesJson')
        ->reduce('Your.SortFunction')
        ->run;

=head1 DESCRIPTION

The MapReduce object allows you to build up and run a map/reduce operations on Riak.

=head2 ATTRIBUTES

=over 4

=item B<phases>

=item B<inputs_bucket>

=item B<inputs>

=item B<input_mode>

=back

=head1 METHODS

=head2 add

arguments: L<Net::Riak::Bucket> / Bucket name /  L<Net::Riak::Object> / Array

return: a Net::Riak::MapReduce object

Add inputs to a map/reduce operation. This method takes three different forms, depending on the provided inputs. You can specify either a RiakObject, a string bucket name, or a bucket, key, and additional arg.

Create a MapReduce job

    my $mapred = $riak->add( ["alice","p1"],["alice","p2"],["alice","p5"] );

Add your inputs to a MapReduce job

    $mapred->add( ["alice","p1"],["alice","p2"] );
    $mapred->add( "alice", "p5" );
    $mapred->add( $riak->bucket("alice")->get("p6") );

=head2 add_object

=head2 add_bucket_key_data

=head2 add_bucket

=head2 link

arguments: bucketname, tag, keep

return: $self

Add a link phase to the map/reduce operation.

The default value for bucket name is '_', which means all buckets.

The default value for tag is '_'.

The flag argument means to flag whether to keep results from this stage in the map/reduce. (default False, unless this is the last step in the phase)

=head2 map

arguments: $function, %options

return: self

    ->map("function () {..}", keep => 0, args => ['foo', 'bar']);
    ->map('Riak.mapValuesJson'); # de-serializes data into JSON

Add a map phase to the map/reduce operation.

functions is either a named javascript function (i: 'Riak.mapValues'), or an anonymous javascript function (ie: 'function(...) ....')

%options is an optional associative array containing:

    language
    keep - flag
    arg - an arrayref of parameterss for the JavaScript function

=head2 reduce

arguments: $function, %options

return: $self

    ->reduce("function () {..}", keep => 1, args => ['foo', 'bar']);

Add a reduce phase to the map/reduce operation.

functions is either a named javascript function (i: 'Riak.mapValues'), or an anonymous javascript function (ie: 'function(...) ....')

=head2 run

arguments: $function, %options

arguments: $timeout

return: arrayref

Run the map/reduce operation and attempt to de-serialize the JSON response to a perl structure. rayref of RiakLink objects if the last phase is a link phase.

Timeout in milliseconds,

=head2 SEE ALSO

REST API

https://wiki.basho.com/display/RIAK/MapReduce

List of built-in named functions for map / reduce phases

http://hg.basho.com/riak/src/tip/doc/js-mapreduce.org#cl-496

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
