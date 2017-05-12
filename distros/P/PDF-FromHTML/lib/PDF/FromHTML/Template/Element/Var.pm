package PDF::FromHTML::Template::Element::Var;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Element);

    use PDF::FromHTML::Template::Element;
}

sub resolve { ($_[1])->param($_[0]{NAME}) }

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Element::Var

=head1 PURPOSE

To provide variable support

=head1 NODE NAME

VAR

=head1 INHERITANCE

PDF::FromHTML::Template::Element

=head1 ATTRIBUTES

=over 4

=item * NAME
This is the name of the parameter to substitute

=back

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <var name="SomeParam"/>

=head1 NOTE

In most cases, the use of VAR is unnecessary as the nodes all have the ability
to use the $-notation for variablized attributes. For example, the filename for
IMAGE or the text for TEXTBOX can be specified by the appropriate attribute.

However, the node is not provided solely for backwards compatibility. There are
some situations where the attribute $-notation is inadequate and a VAR node is
required. (q.v. TEXTBOX for an example)

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

TEXTBOX, IMAGE

=cut
