package MooseX::AttributeHelpers::Trait::String;
use Moose::Role;

our $VERSION = '0.25';

use MooseX::AttributeHelpers::MethodProvider::String;

with 'MooseX::AttributeHelpers::Trait::Base';

has 'method_provider' => (
    is        => 'ro',
    isa       => 'ClassName',
    predicate => 'has_method_provider',
    default   => 'MooseX::AttributeHelpers::MethodProvider::String',
);

sub helper_type { 'Str' }

before 'process_options_for_provides' => sub {
    my ($self, $options, $name) = @_;

    # Set some default attribute options here unless already defined
    if ((my $type = $self->helper_type) && !exists $options->{isa}){
        $options->{isa} = $type;
    }
    
    $options->{is}      = 'rw' unless exists $options->{is};
    $options->{default} = ''   unless exists $options->{default};
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

MooseX::AttributeHelpers::Trait::String

=head1 VERSION

version 0.25

=head1 SYNOPSIS

  package MyHomePage;
  use Moose;
  use MooseX::AttributeHelpers;
  
  has 'text' => (
      metaclass => 'String',
      is        => 'rw',
      isa       => 'Str',
      default   => sub { '' },
      provides  => {
          append => "add_text",
          replace => "replace_text",
      }
  );

  my $page = MyHomePage->new();
  $page->add_text("foo"); # same as $page->text($page->text . "foo");

=head1 DESCRIPTION

This module provides a simple string attribute, to which mutating string
operations can be applied more easily (no need to make an lvalue attribute
metaclass or use temporary variables). Additional methods are provided for
completion.

If your attribute definition does not include any of I<is>, I<isa>,
I<default> or I<provides> but does use the C<String> metaclass,
then this module applies defaults as in the L</SYNOPSIS>
above. This allows for a very basic counter definition:

  has 'foo' => (metaclass => 'String');
  $obj->append_foo;

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

=item I<inc>

Increments the value stored in this slot using the magical string autoincrement
operator. Note that Perl doesn't provide analogeous behavior in C<-->, so
C<dec> is not available.

=item I<append> C<$string>

Append a string, like C<.=>.

=item I<prepend> C<$string>

Prepend a string.

=item I<replace> C<$pattern> C<$replacement>

Performs a regexp substitution (L<perlop/s>). There is no way to provide the
C<g> flag, but code references will be accepted for the replacement, causing
the regex to be modified with a single C<e>. C</smxi> can be applied using the
C<qr> operator.

=item I<match> C<$pattern>

Like I<replace> but without the replacement. Provided mostly for completeness.

=item C<chop>

L<perlfunc/chop>

=item C<chomp>

L<perlfunc/chomp>

=item C<clear>

Sets the string to the empty string (not the value passed to C<default>).

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
