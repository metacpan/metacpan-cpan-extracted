package MooseX::AttributeHelpers::Trait::Bool;
use Moose::Role;
use MooseX::AttributeHelpers::MethodProvider::Bool;

our $VERSION = '0.25';

with 'MooseX::AttributeHelpers::Trait::Base';

sub helper_type { 'Bool' }

# NOTE:
# we don't use the method provider for this 
# module since many of the names of the provied
# methods would conflict with keywords
# - SL

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'MooseX::AttributeHelpers::MethodProvider::Bool'
);

before 'process_options_for_provides' => sub {
    my ($self, $options, $name) = @_;

    # Set some default attribute options here unless already defined
    if ((my $type = $self->helper_type) && !exists $options->{isa}){
        $options->{isa} = $type;
    }
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::Trait::Bool

=head1 VERSION

version 0.25

=head1 SYNOPSIS

  package Room;
  use Moose;
  use MooseX::AttributeHelpers;
  
  has 'is_lit' => (
      metaclass => 'Bool',
      is        => 'rw',
      isa       => 'Bool',
      default   => sub { 0 },
      provides  => {
          set     => 'illuminate',
          unset   => 'darken',
          toggle  => 'flip_switch',
          not     => 'is_dark'
      }
  );

  my $room = Room->new();
  $room->illuminate;     # same as $room->is_lit(1);
  $room->darken;         # same as $room->is_lit(0);
  $room->flip_switch;    # same as $room->is_lit(not $room->is_lit);
  return $room->is_dark; # same as !$room->is_lit

=head1 DESCRIPTION

This provides a simple boolean attribute, which supports most of the
basic math operations.

=head1 METHODS

=over 4

=item B<meta>

=item B<helper_type>

=item B<method_constructors>

=item B<has_method_provider>

=item B<method_provider>

=back

=head1 PROVIDED METHODS

It is important to note that all those methods do in place
modification of the value stored in the attribute.

=over 4

=item I<set>

Sets the value to C<1>.

=item I<unset>

Set the value to C<0>.

=item I<toggle>

Toggle the value. If it's true, set to false, and vice versa.

=item I<not>

Equivalent of 'not C<$value>'.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-AttributeHelpers>
(or L<bug-MooseX-AttributeHelpers@rt.cpan.org|mailto:bug-MooseX-AttributeHelpers@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

Jason May

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Stevan Little and Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
