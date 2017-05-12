package Template::Plugin::PwithBR;

use strict;
use warnings;

use base qw( Template::Plugin );
use Template::Plugin;

our $FILTER_NAME = 'p_with_br';

our $VERSION = '0.04';

sub new {
    my($class, $context, @args) = @_;
    my $name = $args[0] || $FILTER_NAME;
    $context->define_filter($name, \&p_with_br, 0);
    return $class;
}

sub p_with_br {
    my $text = shift;
    $text =~ s/\x0D\x0A/\n/g;
    $text =~ tr/\x0D\x0A/\n\n/; 

    $text =~ s{(?<!\n)(\n)(?!\n)}{<br />\n}g;
    $text = "<p>\n"
        . join("\n</p>\n\n<p>\n", split(/(?:\r?\n){2,}/, $text))
        . "</p>\n";
    $text;
}

1;
__END__
=head1 NAME

Template::Plugin::PwithBR - TT Plugin that changes paragraph and newline into p with br.

=head1 SYNOPSIS

  [% USE PwithBR %]
  [% FILTER p_with_br %]
  foo
  bar
  
  hoge
  [% END %]

Output:

  <p>
  foo<br />
  bar
  </p>
  
  <p>
  hoge</p>

=head1 DESCRIPTION

Template::Plugin::PinBR is TT plugin.When this plugin is used,
E<lt>pE<gt> and E<lt>brE<gt> are appropriately output.

It is not possible to achieve it with the filter html_para and
html_break / html_para_break or html_line_break.

=head1 SEE ALSO

L<Template>, L<Template::Plugin>

=head1 AUTHOR

Daisuke Komatsu, E<lt>taro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
