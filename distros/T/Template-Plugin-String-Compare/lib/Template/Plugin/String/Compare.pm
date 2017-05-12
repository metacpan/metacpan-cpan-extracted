package Template::Plugin::String::Compare;

use strict;
use base qw/Template::Plugin::String/;

$Template::Plugin::String::Compare::VERSION = 0.01;

use overload (
    '<'      => \&_lt,
    '>'      => \&_gt,
    '<='     => \&_le,
    '>='     => \&_ge,
    fallback => 1,
);

sub _lt {
    return $_[2]
        ? "$_[1]" lt "$_[0]"
        : "$_[0]" lt "$_[1]";
}

sub _gt {
    return $_[2]
        ? "$_[1]" gt "$_[0]"
        : "$_[0]" gt "$_[1]";
}

sub _le {
    return $_[2]
        ? "$_[1]" le "$_[0]"
        : "$_[0]" le "$_[1]";
}

sub _ge {
    return $_[2]
        ? "$_[1]" ge "$_[0]"
        : "$_[0]" ge "$_[1]";
}

sub compare {
    my ($self, $text) = @_;
    return "$self" cmp "$text";
}

1;
__END__

=head1 NAME

Template::Plugin::String::Compare - TT extension for Template::Plugin::String objects

=head1 SYNOPSIS

  # This is not printed.
  [% IF '2005-03-01' < '2005-04-01' %]
  Normally this is evaluated in numeric context.
  [% END %]

  # This is printed.
  [% USE String.Compare %]
  [% IF String.Compare.new('2005-03-01') < '2005-04-01' %]
  This is evaluated in string context.
  [% END %]

=head1 DESCRIPTION

This Template Toolkit plugin provides the way to compare string
in string context. And this inherit from Template::Plugin::String.
So you can use methods that Template::Plugin::String provides.

=head1 METHODS

=over 4

=item compare($text)

Compares the two strings.

  [% USE String.Compare('001b') %]
  [% String.Compare.compare('001a') %] # => '1'
  [% String.Compare.compare('001b') %] # => '0'
  [% String.Compare.compare('001c') %] # => '-1'

=back

=head1 SEE ALSO

L<Template>, L<Template::Plugin::String>

=head1 AUTHOR

Satoshi Tanimoto, E<lt>tanimoto@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005- by Satoshi Tanimoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
