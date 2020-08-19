package OpenTracing::Implementation::NoOp::Tracer;

=head1 NAME

OpenTracing::Implementation::NoOp::Tracer - NoOp, so code won't break!

=head1 DESCRIPTION

Objects of this class implement the required methods of the
L<OpenTracing::Interface::Tracer>, to be compliant during testing and allow
applications to continue working without having to catch exceptions all the
time.

None of the methods will do anything useful.

=cut

our $VERSION = 'v0.72.1';



use OpenTracing::Implementation::NoOp::Scope;
use OpenTracing::Implementation::NoOp::ScopeManager;
use OpenTracing::Implementation::NoOp::Span;


sub new { bless {} }


sub get_scope_manager {
    OpenTracing::Implementation::NoOp::ScopeManager->new( )
}

sub get_active_span {
    OpenTracing::Implementation::NoOp::Span->new( )
}

sub start_active_span {
    OpenTracing::Implementation::NoOp::Scope->new( )
}

sub start_span {
    OpenTracing::Implementation::NoOp::Span->new( )
}

sub inject_context { $_[1] } # carrier

sub extract_context { undef }



BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Tracer'
        if $ENV{OPENTRACING_INTERFACE};
} # check at compile time, perl -c will work



1;
