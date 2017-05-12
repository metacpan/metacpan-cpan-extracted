package MooseX::AttributeHelpers::Trait::Counter;
use Moose::Role;

our $VERSION = '0.25';

use MooseX::AttributeHelpers::MethodProvider::Counter;

with 'MooseX::AttributeHelpers::Trait::Base';

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'MooseX::AttributeHelpers::MethodProvider::Counter',
);

sub helper_type { 'Num' }

before 'process_options_for_provides' => sub {
    my ($self, $options, $name) = @_;

    # Set some default attribute options here unless already defined
    if ((my $type = $self->helper_type) && !exists $options->{isa}){
        $options->{isa} = $type;
    }

    $options->{is}      = 'ro' unless exists $options->{is};
    $options->{default} = 0    unless exists $options->{default};
};

after 'check_provides_values' => sub {
    my $self     = shift;
    my $provides = $self->provides;

    unless (scalar keys %$provides) {
        my $method_constructors = $self->method_constructors;
        my $attr_name           = $self->name;

        foreach my $method (keys %$method_constructors) {
            $provides->{$method} = ($method . '_' . $attr_name);
        }
    }
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::Trait::Counter

=head1 VERSION

version 0.25

=head1 SYNOPSIS

  package MyHomePage;
  use Moose;
  use MooseX::AttributeHelpers;
  
  has 'counter' => (
      metaclass => 'Counter',
      is        => 'ro',
      isa       => 'Num',
      default   => sub { 0 },
      provides  => {
          inc => 'inc_counter',
          dec => 'dec_counter',          
          reset => 'reset_counter',
      }
  );

  my $page = MyHomePage->new();
  $page->inc_counter; # same as $page->counter($page->counter + 1);
  $page->dec_counter; # same as $page->counter($page->counter - 1);  

=head1 DESCRIPTION

This module provides a simple counter attribute, which can be 
incremented and decremeneted. 

If your attribute definition does not include any of I<is>, I<isa>,
I<default> or I<provides> but does use the C<Counter> metaclass,
then this module applies defaults as in the L</SYNOPSIS>
above. This allows for a very basic counter definition:

  has 'foo' => (metaclass => 'Counter');
  $obj->inc_foo;

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=item B<helper_type>

=item B<process_options_for_provides>

Run before its superclass method.

=item B<check_provides_values>

Run after its superclass method.

=back

=head1 PROVIDED METHODS

It is important to note that all those methods do in place
modification of the value stored in the attribute.

=over 4

=item I<set>

Set the counter to the specified value.

=item I<inc>

Increments the value stored in this slot by 1. Providing an argument will
cause the counter to be increased by specified amount.

=item I<dec>

Decrements the value stored in this slot by 1. Providing an argument will
cause the counter to be increased by specified amount.

=item I<reset>

Resets the value stored in this slot to it's default value. 

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Stevan Little and Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
