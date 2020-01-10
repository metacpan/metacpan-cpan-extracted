package OpenTracing::Implementation::NoOp::Tracer;

=head1 NAME

OpenTracing::Implementation::NoOp::Span - NoOp, so code won't break!

=head1 DESCRIPTION

Objects of this class implement the required methods of the
L<OpenTracing::Interface::Scope>, to be compliant during testing and allow
applications to continue working without having to catch acceptions all the
time.

None of the methods will do anything usefull.

=cut



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

sub inject_context { }

sub extract_context { undef }



BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Tracer'
        if $ENV{OPENTRACING_INTERFACE};
} # check at compile time, perl -c will work



1;
