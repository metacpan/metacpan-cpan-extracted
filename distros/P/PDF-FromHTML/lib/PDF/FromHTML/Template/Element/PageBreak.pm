package PDF::FromHTML::Template::Element::PageBreak;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Element);

    use PDF::FromHTML::Template::Element;
}

sub new
{
   my $class = shift;
   my $self = $class->SUPER::new(@_);

   $self->trip(0);

   return $self;
}

sub reset
{
   my $self = shift;

   $self->trip(0);

   return $self->SUPER::reset;
}

sub trip { $_[0]{__TRIP_WIRE__} = $_[1] if defined $_[1]; $_[0]{__TRIP_WIRE__} }

sub render
{
   my $self = shift;
   my ($context) = @_;

   return 0 unless $self->should_render($context);

   return 1 if $self->trip;

    # Regardless of whether a pagebreak actually occurs, this node
    # has done its job.

   $self->trip(1);

    if ($context->get($self, 'Y') != $context->get($self, 'START_Y'))
    {
       $context->trip_pagebreak;
    }

   return 0;
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Element::PageBreak

=head1 PURPOSE

To insert a hard pagebreak.

=head1 NODE NAME

PAGEBREAK

=head1 INHERITANCE

PDF::FromHTML::Template::Element

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <pagebreak/>

This will cause a pagebreak to occur at the spot the node is.

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

=cut
