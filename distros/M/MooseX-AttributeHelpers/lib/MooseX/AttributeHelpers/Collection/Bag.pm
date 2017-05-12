package MooseX::AttributeHelpers::Collection::Bag;
use Moose;

our $VERSION = '0.25';

extends 'Moose::Meta::Attribute';
with 'MooseX::AttributeHelpers::Trait::Collection::Bag';

no Moose;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Collection::Bag;
sub register_implementation { 'MooseX::AttributeHelpers::Collection::Bag' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::Collection::Bag

=head1 VERSION

version 0.25

=head1 SYNOPSIS

  package Stuff;
  use Moose;
  use MooseX::AttributeHelpers;
  
  has 'word_histogram' => (
      metaclass => 'Collection::Bag',
      is        => 'ro',
      isa       => 'Bag', # optional ... as is default
      provides  => {
          'add'    => 'add_word',
          'get'    => 'get_count_for',            
          'empty'  => 'has_any_words',
          'count'  => 'num_words',
          'delete' => 'delete_word',
      }
  );

=head1 DESCRIPTION

This module provides a Bag attribute which provides a number of 
bag-like operations. See L<MooseX::AttributeHelpers::MethodProvider::Bag>
for more details.

=head1 METHODS

=over 4

=item B<meta>

=item B<method_provider>

=item B<has_method_provider>

=item B<helper_type>

=item B<process_options_for_provides>

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
