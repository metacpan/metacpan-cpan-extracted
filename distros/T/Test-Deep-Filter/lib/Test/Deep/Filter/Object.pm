use 5.006;    # our
use strict;
use warnings;

package Test::Deep::Filter::Object;

# ABSTRACT: Internal plumbing for Test::Deep::Filter

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

our $VERSION = '0.001001';

use parent 'Test::Deep::Cmp';







sub init {
  my ( $self, $filter, $expected ) = @_;
  $self->{ __PACKAGE__ . '_filter' }   = $filter;
  $self->{ __PACKAGE__ . '_expected' } = $expected;
  return;
}











## no critic ( RequireArgUnpacking, RequireFinalReturn )
sub filter   { $_[0]->{ __PACKAGE__ . '_filter' } }
sub expected { $_[0]->{ __PACKAGE__ . '_expected' } }
## use critic







sub descend {
  my ( $self, $got ) = @_;
  delete $self->{ __PACKAGE__ . '_error' };
  my $return;
  {
    local $@ = undef;
    $return = eval { local $_ = $got; $self->filter->($got) };
    if ( defined $@ and length $@ ) {
      $self->{ __PACKAGE__ . '_error' } = $@;
      return 0;
    }
  }
  require Test::Deep;
  return Test::Deep::wrap( $self->expected )->descend($return);    ## no critic (ProhibitCallsToUnexportedSubs)
}







sub diagnostics {
  my ( $self, $where, $last_exp ) = @_;
  return $self->{ __PACKAGE__ . '_error' } if exists $self->{ __PACKAGE__ . '_error' };
  return $self->expected->diagnostics( $where, $last_exp );
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Deep::Filter::Object - Internal plumbing for Test::Deep::Filter

=head1 VERSION

version 0.001001

=head1 METHODS

=head2 C<init>

  my $object = Test::Deep::Filter::Object->new( $filter, $expected_structure );

=head2 C<filter>

  my $filter_sub = $object->filter;

=head2 C<expected>

  my $expected = $object->expected;

=head2 C<descend>

  my $result = $object->descend( $got );

=head2 C<diagnostics>

  my $diagnostics = $object->diagnostics($where, $last_exp);

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
