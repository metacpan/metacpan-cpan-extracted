package POE::Filter::XML;
{
  $POE::Filter::XML::VERSION = '1.140700';
}

#ABSTRACT: XML parsing for the POE framework

use Moose;
use MooseX::NonMoose;


extends 'Moose::Object','POE::Filter';

use Carp;
use XML::LibXML;
use POE::Filter::XML::Handler;


has buffer =>
(
    is => 'ro',
    traits => [ 'Array' ],
    isa => 'ArrayRef',
    lazy => 1,
    clearer => '_clear_buffer',
    default => sub { [] },
    handles =>
    {
        has_buffer => 'count',
        all_buffer => 'elements',
        push_buffer => 'push',
        shift_buffer => 'shift',
        join_buffer => 'join',
    }
);


has callback =>
(
    is => 'ro',
    isa => 'CodeRef',
    lazy => 1,
    default => sub { sub { Carp::confess('Parsing error happened: '. join("\n", @_)) } },
);


has handler =>
(
    is => 'ro',
    isa => 'POE::Filter::XML::Handler',
    lazy => 1,
    builder => '_build_handler',
);


has parser =>
(
    is => 'ro',
    isa => 'XML::LibXML',
    lazy => 1,
    builder => '_build_parser',
    clearer => '_clear_parser'
);


has not_streaming =>
(
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

sub _build_handler {
    my ($self) = @_;
    POE::Filter::XML::Handler->new(not_streaming => $self->not_streaming)
}

sub _build_parser {
    my ($self) = @_;
    XML::LibXML->new(Handler => $self->handler)
}


sub BUILD {
    my ($self) = @_;
    if($self->has_buffer)
    {
        eval
        {
            $self->parser->parse_chunk($self->join_buffer("\n"));
            1;
        }
        or do
        {
            my $err = $@ || 'Zombie Error';
            $self->callback->($err);
        };

        $self->_clear_buffer();
    }
}


sub reset {

    my ($self) = @_;
    $self->handler->reset();
    $self->_clear_parser();
    $self->_clear_buffer();
}


sub get_one_start {

    my ($self, $raw) = @_;

    if (defined $raw)
    {
        foreach my $raw_data (@$raw)
        {
            $self->push_buffer(split(/(?=\x0a?\x0d|\x0d\x0a?)/s, $raw_data));
        }
    }
}


sub get_one {

    my ($self) = @_;

    if($self->handler->has_finished_nodes())
    {
        return [$self->handler->get_finished_node()];

    }
    else
    {
        while($self->has_buffer())
        {
            my $line = $self->shift_buffer();

            eval
            {
                $self->parser->parse_chunk($line);
                1;
            }
            or do
            {
                my $err = $@ || 'Zombie error';
                $self->callback->($err);
            };

            if($self->handler->has_finished_nodes())
            {
                my $node = $self->handler->get_finished_node();

                if($node->stream_end() or $self->not_streaming)
                {
                    $self->parser->parse_chunk('', 1);
                    $self->reset();
                }

                return [$node];
            }
        }
        return [];
    }
}


sub put {
    my ($self, $nodes) = @_;
    my $output = [];

    foreach my $node (@$nodes)
    {
        if($node->stream_start())
        {
            $self->reset();
        }
        push(@$output, $node->toString());
    }

    return $output;
}

1;


=pod

=head1 NAME

POE::Filter::XML - XML parsing for the POE framework

=head1 VERSION

version 1.140700

=head1 SYNOPSIS

 use POE::Filter::XML;
 my $filter = POE::Filter::XML->new();

 my $wheel = POE::Wheel:ReadWrite->new(
 	Filter		=> $filter,
	InputEvent	=> 'input_event',
 );

=head1 DESCRIPTION

POE::Filter::XML provides POE with a completely encapsulated XML parsing
strategy for POE::Wheels that will be dealing with XML streams.

The parser is XML::LibXML

=head1 PUBLIC_ATTRIBUTES

=head2 not_streaming

    is: ro, isa: Bool, default: false

Setting the not_streaming attribute to true via new() will put this filter into
non-streaming mode, meaning that whole documents are parsed before nodes are
returned. This is handy for XMLRPC or other short documents.

=head1 PRIVATE_ATTRIBUTES

=head2 buffer

    is: ro, isa: ArrayRef, traits: Array

buffer holds the raw data to be parsed. Raw data should be split on network
new lines before being added to the buffer. Access to this attribute is
provided by the following methods:

    handles =>
    {
        has_buffer => 'count',
        all_buffer => 'elements',
        push_buffer => 'push',
        shift_buffer => 'shift',
        join_buffer => 'join',
    }

=head2 callback

    is: ro, isa: CodeRef

callback holds the CodeRef to be call in the event that there is an exception
generated while parsing content. By default it holds a CodeRef that simply
calls Carp::confess.

=head2 handler

    is: ro, isa: POE::Filter::XML::Handler

handler holds the SAX handler to be used for processing events from the parser.
By default POE::Filter::XML::Handler is instantiated and used.

The L</not_streaming> attribute is passed to the constructor of Handler.

=head2 parser

    is: ro, isa: XML::LibXML

parser holds an instance of the XML::LibXML parser. The L</handler> attribute
is passed to the constructor of XML::LibXML.

=head1 PUBLIC_METHODS

=head2 get_one_start

    (ArrayRef $raw?)

This method is part of the POE::Filter API. See L<POE::Filter/get_one_start>
for an explanation of its usage.

=head2 get_one

    returns (ArrayRef)

This method is part of the POE::Filter API. See L<POE::Filter/get_one> for an
explanation of its usage.

=head2 put

    (ArrayRef $nodes) returns (ArrayRef)

This method is part of the POE::Filter API. See L<POE::Filter/put> for an
explanation of its usage.

=head1 PROTECTED_METHODS

=head2 reset

reset() is an internal method that gets called when either a stream_start(1)
POE::Filter::XML::Node gets placed into the filter via L</put>, or when a
stream_end(1) POE::Filter::XML::Node is pulled out of the queue of finished
Nodes via L</get_one>. This facilitates automagical behavior when using the
Filter within the XMPP protocol that requires many new stream initiations.
This method is also called after every document when not in streaming mode.
Useful for handling XMLRPC processing.

This method really should never be called outside of the Filter, but it is
documented here in case the Filter is used outside of the POE context.

=head1 PRIVATE_METHODS

=head2 BUILD

A BUILD method is provided to parse the initial buffer (if any was included
when constructing the filter).

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

