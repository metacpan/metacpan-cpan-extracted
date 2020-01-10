package OpenTracing::Implementation::NoOp::Span;

=head1 NAME

OpenTracing::Implementation::NoOp::Span - NoOp, so code won't break!

=head1 DESCRIPTION

Objects of this class implement the required methods of the
L<OpenTracing::Interface::Span>,
to be compliant during testing and allow applications to continue working
without having to catch acceptions all the time.

None of the methods will do anything usefull.

=cut



use OpenTracing::Implementation::NoOp::SpanContext;



sub new { bless {} }



sub get_context {
    OpenTracing::Implementation::NoOp::SpanContext->new( )
}

sub overwrite_operation_name { shift }

sub finish { shift }

sub set_tag { shift }

sub log_data { shift }

sub set_baggage_item { shift }

sub get_baggage_item { undef }



BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Span'
        if $ENV{OPENTRACING_INTERFACE};
} # check at compile time, perl -c will work



1;
