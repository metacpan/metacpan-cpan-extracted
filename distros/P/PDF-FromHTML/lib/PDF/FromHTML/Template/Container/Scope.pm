package PDF::FromHTML::Template::Container::Scope;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container);

    use PDF::FromHTML::Template::Container;
}

# This is used as a placeholder for scoping values across any number
# of children. It does nothing on its own.

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Scope

=head1 PURPOSE

To provide scoping for children.

=head1 NODE NAME

SCOPE

=head1 INHERITANCE

PDF::FromHTML::Template::Container

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <scope w="100%">
    <row h="18">
      <textbox text="Hello, world"/>
    </row>
    <row h="8">
      <textbox text="Goodbye, world"/>
    </row>
  </scope>

If you have a number of nodes that share common attribute values, but don't have
a common parent, provide them with a no-op parent that allows consolidation of
attribute specification.

In the above example, the two textbox nodes will inherit the W attribute from
the scope tag.

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

=cut
