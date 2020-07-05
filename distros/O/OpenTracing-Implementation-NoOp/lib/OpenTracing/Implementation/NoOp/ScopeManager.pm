package OpenTracing::Implementation::NoOp::ScopeManager;

=head1 NAME

OpenTracing::Implementation::NoOp::ScopeManager - NoOp, so code won't break!

=head1 DESCRIPTION

Objects of this class implement the required methods of the
L<OpenTracing::Interface::ScopeManager>,
to be compliant during testing and allow applications to continue working
without having to catch exceptions all the time.

None of the methods will do anything useful.

=cut

our $VERSION = 'v0.71.1';



use OpenTracing::Implementation::NoOp::Scope;



sub new { bless {} }



sub activate_span {
    OpenTracing::Implementation::NoOp::Scope->new( )
}

sub get_active_scope {
    OpenTracing::Implementation::NoOp::Scope->new( )
}



BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::ScopeManager'
        if $ENV{OPENTRACING_INTERFACE};
} # check at compile time, perl -c will work



1;
