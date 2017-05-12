package Mojolicious::Controller::REST;

# ABSTRACT: Mojolicious Controller for RESTful operations
our $VERSION = '0.006'; # VERSION
use Mojo::Base 'Mojolicious::Controller';

sub data {
    my $self = shift;
    my %data = @_;

    my $json = $self->stash('json');

    if ( defined( $json->{data} ) ) {
        @{ $json->{data} }{ keys %data } = values %data;
    }
    else {
        $json->{data} = {%data};
    }

    $self->stash( json => $json );
    return $self;
}

sub message {
    my $self = shift;
    my ( $message, $severity ) = @_;

    $severity //= 'info';

    my $json = $self->stash('json');

    if ( defined( $json->{messages} ) ) {
        push( $json->{messages}, { text => $message, severity => $severity } );
    }
    else {
        $json->{messages} = [ { text => $message, severity => $severity } ];
    }

    $self->stash( json => $json );
    return $self;
}

sub message_warn { $_[0]->message( $_[1], 'warn' ) }

sub status {
    my $self   = shift;
    my $status = shift;
    $self->stash( 'status' => $status );
    return $self;
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Controller::REST - Mojolicious Controller for RESTful operations

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    # In Mojolicious Controller
    use Mojo::Base 'Mojolicious::Controller::REST';
    
    $self->data( hello => 'world' )->message('Something went wrong');
    
    # renders json response as:
    
    {
        "data":
        {
            "hello": "world"
        },
        "messages":
        [
            {
                "severity": "info",
                "text": "Something went wrong"
            }
        ]
    }

=head1 DESCRIPTION

Mojolicious::Controller::REST helps with JSON rendering in RESTful applications. It follows  
and ensures the output of the method in controller adheres to the following output format as JSON:

    {
        "data":
        {
            "<key1>": "<value1>",
            "<key2>": "<value2>",
            ...
        },
        "messages":
        [
            {
                "severity": "<warn|info>",
                "text": "<message1>"
            },
            {
                "severity": "<warn|info>",
                "text": "<message2>"
            },
            ...
        ]
    }

Mojolicious::Controller::REST extends Mojolicious::Controller and adds below methods

=head1 METHODS

=head2 data

Sets the data element in 'data' array in JSON output. Returns controller object so that
other method calls can be chained.

=head2 message

Sets an individual message in 'messages' array in JSON output. Returns controller object so that
other method calls can be chained.

A custom severity value can be used by calling message as:

    $self->message('Something went wrong', 'fatal');

    # renders json response as:
    
    {
        "messages":
        [
            {
                "text": "Something went wrong",
                "severity": "fatal"
            }
        ]
    }

=head2 message_warn

Similar to message, but with severity = 'warn'. Returns controller object so that
other method calls can be chained.

=head2 status

Set the status of response. Returns controller object so that other methods can be chained.

=head1 AUTHOR

Abhishek Shende <abhishekisnot@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Abhishek Shende.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
