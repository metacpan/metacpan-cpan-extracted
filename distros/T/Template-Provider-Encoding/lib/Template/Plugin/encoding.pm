package Template::Plugin::encoding;
use base qw( Template::Plugin );

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $contetx = shift;
    $_[0];
}

1;

__END__

=head1 NAME

Tempate::Plugin::encoding - Template plugin to specify encoding

=head1 SYNOPSIS

  [% USE encoding 'euc-jp' -%]
  <?xml version="1.0" encoding="[% encoding %]"?>

=head1 DESCRIPTION

Template::Plugin::encoding is a Template plugin to declare the
encoding of template files. This plugin doesn't actually do anything
but Template::Provider::Encoding scans the usage of this module to
find the encoding of templates. As a bonus, you can use C<encoding>
variable in the template to specify file encoding, which might be
useful for XML or HTML meta tag.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Provider::Encoding>

=cut
