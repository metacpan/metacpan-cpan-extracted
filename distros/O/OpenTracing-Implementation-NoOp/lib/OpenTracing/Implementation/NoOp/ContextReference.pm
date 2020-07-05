package OpenTracing::Implementation::NoOp::ContextReference;

=head1 NAME

OpenTracing::Implementation::NoOp::ContextReference - NoOp, so code won't break!

=head1 DESCRIPTION

Objects of this class implement the required methods of the
L<OpenTracing::Interface::ContextReference>,
to be compliant during testing and allow applications to continue working
without having to catch exceptions all the time.

None of the methods will do anything useful.

=cut

our $VERSION = 'v0.71.1';



use OpenTracing::Implementation::NoOp::SpanContext;



sub new                  { bless {} }
sub new_child_of         { bless {} }
sub new_follows_from     { bless {} }

sub type_is_child_of     { undef }
sub type_is_follows_from { undef }

sub get_referenced_context {
  OpenTracing::Implementation::NoOp::SpanContext->new();
}




BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::ContextReference'
        if $ENV{OPENTRACING_INTERFACE};
} # check at compile time, perl -c will work



1;
