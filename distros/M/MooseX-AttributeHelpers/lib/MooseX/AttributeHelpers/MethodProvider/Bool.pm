package MooseX::AttributeHelpers::MethodProvider::Bool;
use Moose::Role;

our $VERSION = '0.25';

sub set : method {
    my ($attr, $reader, $writer) = @_;
    return sub { $writer->($_[0], 1) };
}

sub unset : method {
    my ($attr, $reader, $writer) = @_;
    return sub { $writer->($_[0], 0) };
}

sub toggle : method {
    my ($attr, $reader, $writer) = @_;
    return sub { $writer->($_[0], !$reader->($_[0])) };
}

sub not : method {
    my ($attr, $reader, $writer) = @_;
    return sub { !$reader->($_[0]) };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::MethodProvider::Bool

=head1 VERSION

version 0.25

=head1 DESCRIPTION

This is a role which provides the method generators for 
L<MooseX::AttributeHelpers::Bool>.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 PROVIDED METHODS

=over 4

=item B<set>

=item B<unset>

=item B<toggle>

=item B<not>

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

Jason May E<lt>jason.a.may@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Stevan Little and Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
