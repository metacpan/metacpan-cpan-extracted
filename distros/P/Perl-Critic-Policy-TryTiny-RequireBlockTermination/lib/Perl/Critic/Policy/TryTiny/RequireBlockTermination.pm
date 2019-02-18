package Perl::Critic::Policy::TryTiny::RequireBlockTermination;

$Perl::Critic::Policy::TryTiny::RequireBlockTermination::VERSION = '0.02';

use strict;
use warnings;

use Readonly;
use Perl::Critic::Utils qw{ :severities :classification :ppi };

use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESC => q{A try/catch/finally not terminated};
Readonly::Scalar my $EXPL => q{Try::Tiny blocks must be terminated by either a semicolon or by residing at the end of a block};

sub supported_parameters { return() }
sub default_severity     { return $SEVERITY_HIGH }
sub default_themes       { return qw( bugs ) }
sub applies_to           { return 'PPI::Token::Word'  }

sub violates {
    my ($self, $try) = @_;

    return unless $try->content() eq 'try';

    my $try_block = $try->snext_sibling();
    return unless $try_block and $try_block->isa('PPI::Structure::Block');

    my $try_end = $try_block->snext_sibling();

    # Lets walk past any catch or finally blocks.
    while (
        $try_end and
        $try_end->isa('PPI::Token::Word') and
        ($try_end->content() eq 'catch' or $try_end->content() eq 'finally') and
        $try_end->snext_sibling() and
        $try_end->snext_sibling()->isa('PPI::Structure::Block')
    ) {
        $try_end = $try_end->snext_sibling->snext_sibling();
    }

    # The try/catch/finally is the last statement in the block.
    return if !$try_end;

    # There was a semicolon at the end.
    return if $try_end->isa('PPI::Token::Structure')
           and $try_end->content() eq ';';

    return $self->violation( $DESC, $EXPL, $try );
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::TryTiny::RequireBlockTermination - Requires that
try/catch/finally blocks are properly terminated.

=head1 DESCRIPTION

A common problem with L<Try::Tiny> is forgetting to put a semicolon after the
try/catch/finally block which can lead to difficul to debug issues.  While
L<Try::Tiny> does do its best to detect this issue it cannot if the code after
the block returns an empty list.

For example, this will fail:

    try { } catch { }
    my $foo = 2;

Since the C<my $foo=2> returns C<2> and C<try> throws an exception that an
unexpected argument was passed.

But this will not fail:

    try { } catch { }
    grep { ... } @some_empty_list;

With the above the code after the try blocks produces an empty list.  Lots of
different things produce empty lists.  When this happens the code after the try
blocks is executed BEFORE the try blocks are executed since they are evaluated
as arguments to the try function!

And this also does not fail:

    try { } catch { }
    return()

Flow control logic after the try blocks will execute before the try blocks are executed
for the same reason as the previous example.

There is one situation (that the author is aware of) where non-terminated try blocks
makes sense.

    try { } catch { } if ...;

In this case the code will run as expected, the if, when evaluating to true, will
cause the try blocks to be run, and if false they will not be run.  Despite this
working this module fails on it.  If this is something that you think is important
to support the author is happy to accept requests and patches.

Note that this policy should be just as useful with other similar modules such as
L<Try::Catch> and L<TryCatch>.

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

