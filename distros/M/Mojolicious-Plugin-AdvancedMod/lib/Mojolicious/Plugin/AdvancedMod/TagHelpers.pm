package Mojolicious::Plugin::AdvancedMod::TagHelpers;

sub init {
  my ( $app, $helpers ) = @_;

  $helpers->{button_to} = \&_button_to;
}

sub _button_to {
  my ( $self, $submit_value ) = ( shift, shift );
  my %opt = @_;

  $opt{data}         ||= [];
  $opt{method}       ||= 'post';
  $opt{submit_class} ||= '';

  my $ret = '<form ';
  foreach my $k ( keys %opt ) {
    next if $k eq 'data' || $k eq 'submit_class';
    $ret .= qq~ $k="$opt{$k}"~;
  }
  $ret .= '>';

  while ( @{ $opt{data} } ) {
    my $key = shift @{ $opt{data} };
    my $val = shift @{ $opt{data} };
    $ret .= qq~<input name="$key" type="hidden" value="$val">~;
  }

  $ret .= qq~<input value="$submit_value" type="submit" class="$opt{submit_class}" />~;
  $ret .= '</form>';

  return $ret;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AdvancedMod::TagHelpers - HTML tag helpers for L<Mojolicious>

=head1 HELPERS

=head2 button_to

  = button_to 'GoGo', 'action' => '/api', 'class' => 'foo bar', 'data' => [qw/user root password q1w2e3/], 'submit_class' => 'btn btn-sm'

Generates a form containing a single button that submits to the URL created by the set of options.

  <form  action="/api" method="post" class="foo bar">
    <input name="user" type="hidden" value="root">
    <input name="password" type="hidden" value="q1w2e3">
    <input value="GoGo" type="submit" class="btn btn-sm" />
  </form>

=head1 AUTHOR

=over 2

=item

Grishkovelli L<grishkovelli@gmail.com>

=item

https://github.com/grishkovelli/Mojolicious-Plugin-AdvancedMod

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, 2014
Grishkovelli L<grishkovelli@gmail.com>

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
