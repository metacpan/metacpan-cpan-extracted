package Moose::Autobox::String;
# ABSTRACT: the String role
use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.16';

with 'Moose::Autobox::Value';

# perl built-ins

sub lc      { CORE::lc      $_[0] }
sub lcfirst { CORE::lcfirst $_[0] }
sub uc      { CORE::uc      $_[0] }
sub ucfirst { CORE::ucfirst $_[0] }
sub chomp   { CORE::chomp   $_[0] }
sub chop    { CORE::chop    $_[0] }
sub reverse { CORE::reverse $_[0] }
sub length  { CORE::length  $_[0] }
sub lines   { [ CORE::split '\n', $_[0] ] }
sub words   { [ CORE::split ' ',  $_[0] ] }
sub index   {
    return CORE::index($_[0], $_[1]) if scalar @_ == 2;
    return CORE::index($_[0], $_[1], $_[2]);
}
sub rindex  {
    return CORE::rindex($_[0], $_[1]) if scalar @_ == 2;
    return CORE::rindex($_[0], $_[1], $_[2]);
}
sub split   {
    return [ CORE::split($_[1], $_[0]) ] if scalar @_ == 2;
    return [ CORE::split($_[1], $_[0], $_[2]) ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::String - the String role

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  use Moose::Autobox;

  "Hello World"->uc; # HELLO WORLD

=head1 DESCRIPTION

This is a role to describes a String value.

=head1 METHODS

=over 4

=item C<chomp>

=item C<chop>

=item C<index>

=item C<lc>

=item C<lcfirst>

=item C<length>

=item C<reverse>

=item C<rindex>

=item C<uc>

=item C<ucfirst>

=item C<split>

  $string->split($pattern);

=item C<words>

This is equivalent to splitting on space.

=item C<lines>

This is equivalent to splitting on newlines.

=back

=over 4

=item C<meta>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Moose-Autobox>
(or L<bug-Moose-Autobox@rt.cpan.org|mailto:bug-Moose-Autobox@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
