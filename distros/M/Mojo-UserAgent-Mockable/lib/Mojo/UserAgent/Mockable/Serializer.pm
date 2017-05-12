use 5.014;

package Mojo::UserAgent::Mockable::Serializer;
$Mojo::UserAgent::Mockable::Serializer::VERSION = '1.53';
use warnings::register;

use Carp;
use Class::Load ':all';
use English qw/-no_match_vars/;
use Path::Tiny;
use JSON::MaybeXS qw/encode_json decode_json/;
use Mojo::Base 'Mojo::EventEmitter';
use Safe::Isa (qw/$_isa/);
use Try::Tiny;

# ABSTRACT: A class that serializes Mojo transactions created by Mojo::UserAgent::Mockable.

# VERSION


sub serialize {
    my ( $self, @transactions ) = @_;

    my @serialized = map { $self->_serialize_tx($_) } @transactions;
    for (0 .. $#serialized) {
        $serialized[$_]->{txn_num} = $_;
    }
    return encode_json( \@serialized );
}

sub _serialize_tx {
    my ( $self, $transaction ) = @_;

    if ( !$transaction->$_isa('Mojo::Transaction') ) {
        croak q{Only instances of Mojo::Transaction may be serialized using this class};
    }

    $transaction->emit('pre_freeze');
    my $slush = {
        request  => $self->_serialize_message( $transaction->req ),
        response => $self->_serialize_message( $transaction->res ),
        class    => ref $transaction,
    };
    for my $event ( keys %{ $transaction->{'events'} } ) {
        next if $event eq 'pre_freeze' or $event eq 'post_freeze' or $event eq 'resume';
        carp(qq{Subscriber for event "$event" not serialized}) if warnings::enabled;
        push @{ $slush->{'events'} }, $event;
    }

    $transaction->emit( 'post_freeze', $slush );

    return $slush;
}

sub _serialize_message {
    my ( $self, $message ) = @_;

    $message->emit('pre_freeze');
    my $slush = {
        class => ref $message,
        body  => $message->to_string,
    };
    if ( $message->can('url') ) {
        $slush->{url} = _freeze_url( $message->url );
    }
    for my $event ( keys %{ $message->{'events'} } ) {
        next if $event eq 'pre_freeze' or $event eq 'post_freeze';
        carp(qq{Subscriber for event "$event" not serialized}) if warnings::enabled;
        push @{ $slush->{'events'} }, $event;
    }

    $message->emit( 'post_freeze', $slush );
    return $slush;
}

sub _freeze_url {
    my $url = shift;
    if ( !$url->$_isa('Mojo::URL') ) {
        $url = Mojo::URL->new($url);
    }
    my $slush;
    for my $attr (qw/scheme userinfo host port path query fragment/) {
        $slush->{$attr} = sprintf '%s', $url->$attr if defined $url->$attr;
    }
    if ( %{ $url->base } ) {
        $slush->{base} = _freeze_url( $url->base );
    }
    return $slush;
}

sub deserialize {
    my ( $self, $frozen ) = @_;

    my $slush = decode_json($frozen);

    if ( ref $slush ne 'ARRAY' ) {
        croak q{Invalid serialized data: not stored as array.};
    }
    $self->emit( 'pre_thaw', $slush );

    my @transactions;
    for my $tx_num ( 0 .. $#{$slush} ) {
        my $tx;
        try {
            $tx = $self->_deserialize_tx( $slush->[$tx_num] );
        }
        catch {
            my $tx_num = ( $tx_num + 1 );
            croak qq{Error deserializing transaction $tx_num: $_};
        };

        push @transactions, $tx;
    }

    $self->emit( 'post_thaw', \@transactions, $slush );
    return @transactions;
}

sub _deserialize_tx {
    my ( $self, $slush ) = @_;

    for my $key (qw/class request response/) {
        if ( !defined $slush->{$key} ) {
            croak qq{Invalid serialized data: Missing required key '$key'};
        }
    }

    load_class( $slush->{'class'} );
    my $obj = $slush->{'class'}->new();

    if ( !$obj->$_isa('Mojo::Transaction') ) {
        croak q{Only instances of Mojo::Transaction may be deserialized using this class};
    }

    my $response;
    try {
        $response = $self->_deserialize_message( $slush->{response} );
    }
    catch {
        die qq{Response deserialization failed: $_\n};
    };
    $obj->res($response);

    my $request;
    try {
        $request = $self->_deserialize_message( $slush->{request} );
    }
    catch {
        die qq{Request deserialization failed: $_\n};
    };
    $obj->req($request);

    if ( $slush->{'events'} ) {
        for my $event ( @{ $slush->{'events'} } ) {
            $obj->emit($event);
        }
    }
    return $obj;
}

sub _deserialize_message {
    my ( $self, $slush ) = @_;
    for my $key (qw/body class/) {
        if ( !$slush->{$key} ) {
            croak qq{Invalid serialized data: missing required key "$key"};
        }
    }

    load_class( $slush->{'class'} );
    my $obj = $slush->{'class'}->new;
    if ( $slush->{'url'} && $obj->can('url') ) {
        $obj->url( _thaw_url( $slush->{url} ) );
    }
    if ( !$obj->can('parse') ) {
        die qq{Message class "$slush->{class}" must define the 'parse' method\n};
    }
    $obj->parse( $slush->{'body'} );

    if ( !$obj->can('emit') ) {
        die qq{Message class "$slush->{class}" must define the 'emit' method\n};
    }
    if ( $slush->{'events'} ) {
        for my $event ( @{ $slush->{'events'} } ) {
            $obj->emit($event);
        }
    }

    return $obj;
}

sub _thaw_url {
    my $slush = shift;
    # FIXME: Temporary workaround
    return Mojo::URL->new($slush) unless ref $slush;

    my $url   = Mojo::URL->new;

    for my $attr ( keys %{$slush} ) {
        $url->$attr( $slush->{$attr} );
    }
    if ( $slush->{base} ) {
        $url->base( _thaw_url( $slush->{base} ) );
    }
    return $url;
}

sub store {
    my ( $self, $file, @transactions ) = @_;

    my $serialized = $self->serialize(@transactions);
    path($file)->spew_utf8($serialized);
}

sub retrieve {
    my ( $self, $file ) = @_;

    my $contents = path($file)->slurp_utf8;
    return $self->deserialize($contents);
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::UserAgent::Mockable::Serializer - A class that serializes Mojo transactions created by Mojo::UserAgent::Mockable.

=head1 VERSION

version 1.53

=head1 SYNOPSIS

    # This module is not intended to be used directly. Synopsis here is given to show how 
    # Mojo::UserAgent::Mockable uses the module to record transactions.
    
    use Mojo::UserAgent::Mockable::Serializer;
    use Mojo::UserAgent;
    use File::Slurper qw(read_text write_text);

    my $ua = Mojo::UserAgent->new;
    my $serializer = Mojo::UserAgent::Mockable::Serializer->new;
    
    my @transactions;
    push @transactions, $ua->get('http://example.com');
    push @transactions, $ua->get('http://example.com/object/123');
    push @transactions, $ua->get('http://example.com/subobject/456');

    my $json = $serializer->serialize(@transactions);
    write_text('/path/to/file/json', $json);

    # OR

    $serializer->store('/path/to/file.json', @transactions);

    # Later...

    my $json = read_text('/path/to/file.json');
    my @reconstituted_transactions = $serializer->deserialize($json);

    # OR
    #
    my @reconstituted_transactions = Mojo::UserAgent::Mockable::Serializer->retrieve('/path/to/file.json');

=head1 METHODS

=head2 serialize

Serialize or freeze one or more instances of L<Mojo::Transaction>.  Takes an array of transactions 
to be serialized as the single argument. This method will generate a warning if the instance has 
any subscribers (see L<Mojo::EventEmitter/on>).  Suppress this warning with (e.g.):

  no warnings 'Mojo::UserAgent::Mock::Serializer';
  $serializer->serialize(@transactions);
  use warnings 'Mojo::UserAgent::Mock::Serializer';

=head2 deserialize

Deserialize or thaw a previously serialized array of L<Mojo:Transaction>. Arguments:

=over 4

=item $data 

JSON containing the serialized objects.

=back

=head2 store

Serialize an instance of L<Mojo::Transaction> and write it to the given file or file handle.  Takes two
arguments:

=over 4

=item $file 

File or handle to write serialized object to.

=item @transactions

Array of L<Mojo::Transaction> to serialize

=back

=head2 retrieve

Read from the specified file or file handle and deserialize one or more instances of 
L<Mojo::Transaction> from the data read.  If a file handle is passed, data will be 
read until an EOF is received. Arguments:

=over 4

=item $file

File containing serialized object

=back

=head1 EVENTS

This module emits the following events:

=head2 pre_thaw

    $serializer->on( pre_thaw => sub {
        my ($serializer, $slush) = @_;
        ...
    });

Emitted immediately before transactions are deserialized. See L</DATA STRUCTURE> below for details
of the format of $slush.

=head2 post_thaw

    # Note that $transactions is an arrayref here.
    $serializer->on( post_thaw => sub {
        my ($serializer, $transactions, $slush) = @_;
        ...
    }

Emitted immediately after transactions are deserialized. See L</DATA STRUCTURE> below for details
of the format of $slush.

In addition, each transaction, as well as each message therein, serialized using this module will 
emit the following events:

=head2 pre_freeze

    $transaction->on(freeze => sub {
        my $tx = shift;
        ...
    });

Emitted immediately before the transaction is serialized.

=head2 post_freeze

Emitted immediately after the transaction is serialized. See L</Messages> for details of the 
frozen format. 

    $transaction->on(post_freeze => sub {
        my $tx = shift;
        my $frozen = shift;
        ...
    });

=head1 DATA STRUCTURE

L<serialize> produces, and L<deserialize> expects, JSON data. Transactions are stored as an array 
of JSON objects (i.e. hashes). Each transaction object has the keys:

=over 4

=item 'class'

The original class of the transaction.

=item 'request'

The request portion of the transaction (e.g. "GET /foo/bar ..."). See L</Messages> below for 
encoding details.

=item 'response'

The response portion of the transaction (e.g. "200 OK ..."). See L</Messages> below for encoding
details.

=back

=head2 Messages

Individual messages are stored as JSON objects (i.e. hashes) with the keys:

=over 4

=item 'class'

The class name of the serialized object.  This should be a subclass of L<Mojo::Message>

=item 'events'

Array of events with subscribers in the serialized object. These events will be re-emitted after 
the L</thaw> event is emitted, but any subscribers present in the original object will be lost.

=item 'body'

The raw HTTP message body.

=back

=head1 CAVEATS

This module does not serialize any event listeners.  This is unlikely to change in future releases.

=head1 AUTHOR

Kit Peters <kit.peters@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Broadbean Technology.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
