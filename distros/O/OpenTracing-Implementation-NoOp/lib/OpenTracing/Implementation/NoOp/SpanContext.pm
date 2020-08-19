package OpenTracing::Implementation::NoOp::SpanContext;

=head1 NAME

OpenTracing::Implementation::NoOp::SpanContext - NoOp, so code won't break!

=head1 DESCRIPTION

Objects of this class implement the required methods of the
L<OpenTracing::Interface::SpanContext>,
to be compliant during testing and allow applications to continue working
without having to catch exceptions all the time.

None of the methods will do anything useful.

=cut

our $VERSION = 'v0.72.1';



sub with_baggage_item { __PACKAGE__->new( ) }

sub with_baggage_items { __PACKAGE__->new( ) }

sub get_baggage_item  { undef }
sub get_baggage_items { return ( ) }


sub new { bless {} }



BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::SpanContext'
        if $ENV{OPENTRACING_INTERFACE};
} # check at compile time, perl -c will work



1;
