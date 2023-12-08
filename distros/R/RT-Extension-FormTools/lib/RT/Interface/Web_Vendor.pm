package HTML::Mason::Commands;

no warnings qw(redefine);

# This should be the same class we are overlaying here
my $original_abort = \&HTML::Mason::Commands::Abort;

*HTML::Mason::Commands::Abort = sub {
    my $why = shift;
    my %args = @_;

    if ( $why =~ /^No permission to view newly created ticket #(\d+)/ ) {
        # We're showing a custom "form submitted" page, not the ticket,
        # so we don't want to abort if the user doesn't have rights to
        # see the ticket.

        # Just return for this case so the create ticket form can get
        # the ticket object and any actual error messages.

        return;
    }

    &$original_abort( $why, %args );
};

1;
