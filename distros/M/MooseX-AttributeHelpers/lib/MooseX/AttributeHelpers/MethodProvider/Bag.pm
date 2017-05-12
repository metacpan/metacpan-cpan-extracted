package MooseX::AttributeHelpers::MethodProvider::Bag;
use Moose::Role;

our $VERSION = '0.25';

with 'MooseX::AttributeHelpers::MethodProvider::ImmutableHash';

sub add : method {
    my ($attr, $reader, $writer) = @_;
    return sub { $reader->($_[0])->{$_[1]}++ };
}

sub delete : method {
    my ($attr, $reader, $writer) = @_;
    return sub { CORE::delete $reader->($_[0])->{$_[1]} };
}

sub reset : method {
    my ($attr, $reader, $writer) = @_;
    return sub { $reader->($_[0])->{$_[1]} = 0 };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::MethodProvider::Bag

=head1 VERSION

version 0.25

=head1 DESCRIPTION

This is a role which provides the method generators for
L<MooseX::AttributeHelpers::Collection::Bag>.

This role is composed from the 
L<MooseX::AttributeHelpers::Collection::ImmutableHash> role.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 PROVIDED METHODS

=over 4

=item B<count>

=item B<delete>

=item B<empty>

=item B<exists>

=item B<get>

=item B<keys>

=item B<add>

=item B<reset>

=item B<values>

=item B<kv>

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
