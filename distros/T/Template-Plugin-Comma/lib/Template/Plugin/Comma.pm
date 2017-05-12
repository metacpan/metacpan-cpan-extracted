package Template::Plugin::Comma;

use strict;
use vars qw($VERSION);
$VERSION = 0.04;

require Template::Plugin;
use base qw(Template::Plugin);

use vars qw($FILTER_NAME);
$FILTER_NAME = 'comma';

sub new {
    my($self, $context, @args) = @_;
    my $name = $args[0] || $FILTER_NAME;
    $context->define_filter($name, \&commify, 0);
    return $self;
}

sub commify {
    local $_  = shift;
    1 while s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
    return $_;
}

1;
__END__

=head1 NAME

Template::Plugin::Comma - TT Plugin to commify numbers

=head1 SYNOPSIS

  [% USE Comma %]

  [% FILTER comma -%]
  This item costs 10000 dollar.
  [%- END %]

  # Output:
  # This item costs 10,000 dollar.

  This item costs [% item.price | comma %] dollar.

  # Output:
  # This item costs 10,000 dollar.

=head1 DESCRIPTION

Template::Plugin::Comma is a plugin for TT, which allows you to
commify your numbers in templates. This would be especially useful for
prices.

=head1 NOTE

This module does nothing for I18N. If you want it, try
Template::Plugin::Number::Format.

=head1 AUTHOR

Original idea by Yoshiki Kurihara E<lt>kurihara@cpan.orgE<gt>

TT plugin implemented by Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, C<Template::Plugin::Number::Format>

=cut
