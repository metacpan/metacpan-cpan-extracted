package Net::Amazon::DynamoDB::Table;
use Net::Amazon::DynamoDB::Lite;
use Carp qw/cluck confess carp croak/;
use Moo;

our $VERSION="0.05";

has table       => (is => 'rw', required => 1);
has hash_key    => (is => 'rw', required => 1);
has range_key   => (is => 'rw', required => 0);
has dynamodb    => (is => 'lazy');
has region      => (is => 'rw', required => 1);
has access_key  => (is => 'rw', lazy => 1, builder => 1);
has secret_key  => (is => 'rw', lazy => 1, builder => 1);
has timeout     => (is => 'rw', default => 5);

sub _build_access_key { $ENV{AWS_ACCESS_KEY} }
sub _build_secret_key { $ENV{AWS_SECRET_KEY} }

sub _build_dynamodb {
    my $self = shift;
    Net::Amazon::DynamoDB::Lite->new(
        region             => $self->region,
        access_key         => $self->access_key,
        secret_key         => $self->secret_key,
        connection_timeout => $self->timeout,
    );
}

sub get {
    my ($self, %args) = @_;
    my $hash_key      = $self->hash_key;
    my $range_key     = $self->range_key;
    my $primary_key   = {};

    die "Key or $hash_key param required" unless $args{Key} || $args{$hash_key};

    if ($args{$hash_key}) {
        my $value = delete $args{$hash_key};
        $primary_key->{$hash_key} = $self->inflate_attribute_value($value);
    }
    if ($range_key && $args{$range_key} ) {
        my $value = delete $args{$range_key};
        $primary_key->{$range_key} = $self->inflate_attribute_value($value);
    }

    $args{Key}       ||= $primary_key;
    $args{TableName} ||= $self->table;

    return $self->dynamodb->get_item(\%args);
}

sub put {
    my ($self, %args)  = @_;

    die "Item param required" unless $args{Item};

    $args{TableName} ||= $self->table;
    $args{Item}        = $self->inflate_item($args{Item});

    return $self->dynamodb->put_item(\%args);
}

sub delete {
    my ($self, %args) = @_;
    my $hash_key      = $self->hash_key;
    my $range_key     = $self->range_key;
    my $primary_key   = {};

    die "Key or $hash_key param required" unless $args{Key} || $args{$hash_key};

    if ($args{$hash_key}) {
        my $value = delete $args{$hash_key};
        $primary_key->{$hash_key} = $self->inflate_attribute_value($value);
    }
    if ($range_key && $args{$range_key} ) {
        my $value = delete $args{$range_key};
        $primary_key->{$range_key} = $self->inflate_attribute_value($value);
    }

    $args{Key}       ||= $primary_key;
    $args{TableName} ||= $self->table;

    return $self->dynamodb->delete_item(\%args);
}

sub inflate_item {
    my ($self, $item) = @_;
    my %new;

    for my $attr (keys %$item) {
        my $val = $item->{$attr};
        $new{$attr} = $self->inflate_attribute_value($val) || next;
    }

    return \%new;
}

sub inflate_hash_key {
    my ($self, $thing) = @_;
    my %new;

    if (ref($thing) eq 'HASH') {
        my %new;
        for my $key (keys %$thing) {
            $new{$key} = $self->inflate_attribute_value($thing->{$key});
        }
        return \%new;
    }
    else {
        return $self->inflate_attribute_value($thing);
    }
}

sub inflate_attribute_value {
    my ($self, $thing) = @_;

    if (ref($thing) eq 'HASH') {
        my %vals;
        for my $key (keys %$thing) {
            $vals{$key} = $self->inflate_attribute_value($thing->{$key}) || next;
        }
        return unless keys %vals;
        return { M => \%vals };
    }
    elsif (ref($thing) eq 'ARRAY') {
        my @vals;
        for my $t (@$thing) {
            push @vals, $self->inflate_attribute_value($t) || next;
        }
        return unless scalar @vals;
        return { L => [@vals] };
    }
    elsif (ref($thing) eq 'SCALAR') {
        return unless $$thing;
        return { B => MIME::Base64::encode_base64($$thing, '') };
    }
    elsif ($self->isa_number($thing)) {
        return { N => "$thing" };
    }
    else {
        return unless $thing;
        return { S => $thing };
    }
}

sub isa_number {
    my ($self, $thing) = @_;
    return 1 if B::svref_2object(\$thing)->FLAGS & (B::SVp_IOK | B::SVp_NOK)
        && 0 + $thing eq $thing
        && $thing * 0 == 0;
    return 0;
}

sub scan {
    my ($self, %args) = @_;
    $args{TableName} ||= $self->table;
    return $self->dynamodb->scan(\%args);
}

sub scan_as_hashref {
    my ($self, %args)  = @_;
    $args{TableName} ||= $self->table;
    my $items_hashref  = {};
    my $items_arrayref = $self->scan(%args);
    my $hash_key_name  = $self->hash_key;

    for my $item (@$items_arrayref) {
        my $hash_key_value = delete $item->{$hash_key_name};
        $items_hashref->{$hash_key_value} = $item;
    }

    return $items_hashref;
}

1;
__END__

=head1 NAME

Net::Amazon::DynamoDB::Table - Higher level interface to Net::Amazon::DyamoDB::Lite


=head1 SYNOPSIS

    use Net::Amazon::DynamoDB::Table;

    my $table = Net::Amazon::DynamoDB::Table->new(
        region      => 'us-east-1',  # required
        table       => $table,       # required
        hash_key    => 'planet',     # required
        range_key   => 'species',    # required if table has a range key
        access_key  => ...,          # default: $ENV{AWS_ACCESS_KEY};
        secret_key  => ...,          # default: $ENV{AWS_SECRET_KEY};
    );

    # create or update an item
    $table->put(Item => { planet => 'Mars', ... });

    # get the item with the specified primary key; returns a hashref
    my $item = $table->get(planet => 'Mars');

    # delete the item with the specified primary key
    $table->delete(planet => 'Mars');

    # scan the table for items; returns an arrayref of items
    my $items_arrayref = $table->scan();

    # scan the table for items; returns items as a hash of key value pairs
    my $items_hashref = $table->scan_as_hashref();


=head1 DESCRIPTION

A Net::Amazon::DynamoDB::Table object represents a single table in DynamoDB.
This module provides a simple UI layer on top of Net::Amazon::DynamoDB::Lite.

There are two features which make this class "simpler" than
Net::Amazon::DynamoDB::Lite.  

The first is that you don't need to specify the TableName in every call.

The second is that you don't need to worry about types.  

=head1 METHODS

=head2 new()

Returns a Net::Amazon::DynamoDB::Table object.  Accepts the following
attributes:

        region      => 'us-east-1',  # required
        table       => $table,       # required
        hash_key    => $hash_key,    # required
        range_key   => $range_key,   # required if table has a range key
        access_key  => ...,          # default: $ENV{AWS_ACCESS_KEY};
        secret_key  => ...,          # default: $ENV{AWS_SECRET_KEY};
    

=head2 put()

Creates a new item, or replaces an old item with a new item.  This method
accepts the same parameters as those accepted by the AWS DynamoDB put_item api
endpoint.  Note however, that you don't need to specify any types.  This module
does that for you.  For example:

    $dynamodb->put((
        Item => {
            a => 1,                  # a Number
            b => "boop",             # a String
            c => [ "hi mom", 23.5 ], # a List composed of a String and Number
            d => {                   # a Map
                chipmunks       => [qw/alvin theodore/], # a List of Strings
                backstreet_boys => [qw/Nick Kevin/],     # a List of Strings
                thing           => 23,                   # a Number
            },
        },
    );


=head2 get()

Returns a hashref representing the item specified by the given primary key.
You can specify the primary key using the HashKey and RangeKey parameters
provided for convenience by this module:

    my $item = $dynamodb->get(
        planet  => 'Mars',
        species => 'green aliens',
    );

Or you can explicitly specify the primary key and types using the Key parameter
like this:

    my $item = $dynamodb->get(
        Key => [ 
            { planet  => { S => 'Mars'         } },
            { species => { N => 'green aliens' } },
        ],
    );

This method also accepts the same parameters as those accepted by the
AWS DynamoDB get_item api endpoint.  For example:

    my $item = $dynamodb->get(
        planet         => 'Mars',
        species        => 'green aliens',
        ConsistentRead => 1,
    );


=head2 delete()

Deletes a single item from a table using the given primary key.  You can
specify the primary key using the HashKey and RangeKey parameters provided for
convenience by this module:

    my $item = $dynamodb->delete(
        planet  => 'Mars',
        species => 'green aliens',
    );

Or you can explicitly specify the primary key and types using the Key parameter
like this:

    my $item = $dynamodb->get(
        Key => [ 
            { planet  => { S => 'Mars'         } },
            { species => { N => 'green aliens' } },
        ],
    );

This method also accepts the same parameters as those accepted by the
AWS DynamoDB get_item api endpoint.  For example:

    my $item = $dynamodb->get(
        planet                    => 'Mars',
        species                   => 'green aliens',
        ConditionExpression       => "planet := :p",
        ExpressionAttributeValues => { ':p' => { S => 'Mars' } },
    );


=head2 scan()

This method accepts the same parameters as those accepted by the
AWS DynamoDB scan api endpoint.  It returns an arrayref of item hashrefs.


=head2 scan_as_hashref()

This method accepts the same parameters as those accepted by the
AWS DynamoDB scan api endpoint.  It returns the results as a hashref that looks
like this:

    # { $hash_key_value1 => $item1,
    #   $hash_key_value2 => $item2, 
    #   ...,
    # }


=cut

=head1 ACKNOWLEDGEMENTS

Thanks to L<DuckDuckGo|http://duckduckgo.com> for making this module possible.

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

