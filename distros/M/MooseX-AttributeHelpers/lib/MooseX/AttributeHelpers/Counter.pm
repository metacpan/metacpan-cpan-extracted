package MooseX::AttributeHelpers::Counter;
use Moose;

our $VERSION = '0.25';

extends 'Moose::Meta::Attribute';
with 'MooseX::AttributeHelpers::Trait::Counter';

no Moose;

# register the alias ...
package # hide me from search.cpan.org
    Moose::Meta::Attribute::Custom::Counter;
sub register_implementation { 'MooseX::AttributeHelpers::Counter' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::Counter

=head1 VERSION

version 0.25

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
