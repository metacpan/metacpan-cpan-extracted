use 5.006;
use strict;
use warnings;

package Pod::Eventual::Reconstruct::LazyCut;

# ABSTRACT: A Subclass of Pod::Eventual::Reconstruct that emits less =cut's

our $VERSION = '1.000002';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY












use Moo qw( extends has around );
use Carp qw(carp);
use Data::Dump qw(pp);
extends 'Pod::Eventual::Reconstruct';











has 'inpod' => (
  is        => ro  =>,
  writer    => 'set_inpod',
  clearer   => 'clear_inpod',
  predicate => 'is_inpod',
  lazy      => 1,
  builder   => sub { undef },
);

around write_command => sub {
  my ( $orig, $self, $event ) = @_;
  if ( $event->{type} ne 'command' ) {
    return $self->$orig($event);
  }
  if ( $event->{command} ne 'cut' ) {
    my $result = $self->$orig($event);
    $self->set_inpod(1);
    return $result;
  }
  if ( $self->is_inpod ) {
    my $result = $self->$orig($event);
    $self->clear_inpod();
    return $result;
  }

  # Skipping a cut
  return $self;
};

around write_text => sub {
  my ( $orig, $self, $event ) = @_;
  if ( $event->{type} ne 'text' ) {
    return $self->$orig($event);
  }
  if ( not $self->is_inpod ) {
    return $self->write_text_outside_pod( $orig, $event );
  }
  return $self->$orig($event);
};

around write_nonpod => sub {
  my ( $orig, $self, $event ) = @_;
  if ( $event->{type} ne 'nonpod' ) {
    return $self->$orig($event);
  }
  if ( $self->is_inpod ) {
    return $self->write_nonpod_inside_pod( $orig, $event );
  }
  return $self->$orig($event);
};

no Moo;













sub write_text_outside_pod {
  my ( $self, $orig, $event ) = @_;
  carp 'POD Text element outside POD ' . pp($event);
  return $self->$orig($event);
}













sub write_nonpod_inside_pod {
  my ( $self, $orig, $event ) = @_;
  carp 'NONPOD element inside POD ' . pp($event);
  return $self->$orig($event);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Eventual::Reconstruct::LazyCut - A Subclass of Pod::Eventual::Reconstruct that emits less =cut's

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

If you're blindly filtering POD in an Eventual manner, sometimes removing elements
may change the semantics.

For instance, in

    codehere

    =begin foo

    =end foo

    =cut

    codehere

That C<=cut> is an "End of POD Marker".

However, if you simply remove the elements before the C<=cut>, the semantics change:

    codehere

    =cut

    codehere

Here, C<=cut> marks a "Start of POD" and the second C<codehere> is deemed "in the POD".

This module attempts to keep the document "consistent" by not emitting C<=cut> unless a preceding C<=command> is seen in the output.

Additionally, this module will warn if elements are posted to it in ways that are likely to cause errors, for instance:

=over 4

=item * A POD Text element outside a POD region

=item * A Non-POD element inside a POD region

=back

The specific behavior occurred when hitting these errors can be customized via sub-classing,
and overriding L</write_text_outside_pod> and L</write_nonpod_inside_pod>

=head1 METHODS

=head2 C<set_inpod>

=head2 C<clear_inpod>

=head2 C<is_inpod>

=head2 write_text_outside_pod

Is called when a C<text> event is seen but we don't appear to be inside a C<POD> region.

    $recon->write_text_outside_pod( $orig_method, $event );

Default implementation warns via C<Carp> and then emits the element anyway, via

    $self->$orig_method( $event )

=head2 write_nonpod_inside_pod

Is called when a C<nonpod> event is seen but we appear to be inside a C<POD> region.

    $recon->write_nonpod_inside_pod( $orig_method, $event );

Default implementation warns via C<Carp> and then emits the element anyway, via

    $self->$orig_method( $event )

=head1 ATTRIBUTES

=head2 C<inpod>

=begin MetaPOD::JSON v1.0.0

{
    "namespace":"Pod::Eventual::Reconstruct::LazyCut",
    "inherits":"Pod::Eventual::Reconstruct"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
