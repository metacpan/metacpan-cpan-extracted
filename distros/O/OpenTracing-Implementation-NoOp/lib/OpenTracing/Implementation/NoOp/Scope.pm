package OpenTracing::Implementation::NoOp::Scope;

=head1 NAME

OpenTracing::Implementation::NoOp::Scope - NoOp, so code won't break!

=head1 DESCRIPTION

Objects of this class implement the required methods of the
L<OpenTracing::Interface::Scope>,
to be compliant during testing and allow applications to continue working
without having to catch exceptions all the time.

None of the methods will do anything useful.

=cut

our $VERSION = 'v0.71.1';



use OpenTracing::Implementation::NoOp::Span;



sub new { bless {} }



sub close { shift }

sub get_span {
    OpenTracing::Implementation::NoOp::Span->new( )
}



BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Scope'
        if $ENV{OPENTRACING_INTERFACE};
} # check at compile time, perl -c will work



1;
