package OpenTracing::Implementation::NoOp::Span;

=head1 NAME

OpenTracing::Implementation::NoOp::Span - NoOp, so code won't break!

=head1 DESCRIPTION

Objects of this class implement the required methods of the
L<OpenTracing::Interface::Span>,
to be compliant during testing and allow applications to continue working
without having to catch exceptions all the time.

None of the methods will do anything useful.

=cut

our $VERSION = 'v0.72.1';



use OpenTracing::Implementation::NoOp::SpanContext;



sub new { bless {} }



sub get_context {
    OpenTracing::Implementation::NoOp::SpanContext->new( )
}

sub overwrite_operation_name { shift }

sub finish { shift }

sub add_tag  { shift }
sub add_tags { shift }

sub get_tags { return ( ) }

sub log_data { shift }

sub add_baggage_item  { shift }
sub add_baggage_items { shift }

sub get_baggage_item  { undef }
sub get_baggage_items { return ( ) }


BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Span'
        if $ENV{OPENTRACING_INTERFACE};
} # check at compile time, perl -c will work



1;
