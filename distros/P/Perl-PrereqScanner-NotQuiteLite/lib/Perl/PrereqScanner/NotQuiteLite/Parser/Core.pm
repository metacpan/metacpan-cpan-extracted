package Perl::PrereqScanner::NotQuiteLite::Parser::Core;

use strict;
use warnings;
use Perl::PrereqScanner::NotQuiteLite::Util;

sub register { return {
  use => {
    if => 'parse_if_args',
    base => 'parse_base_args',
    parent => 'parse_parent_args',
  },
}}

sub parse_if_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  while(my $token = shift @$raw_tokens) {
    last if $token->[1] eq 'COMMA';
  }

  my $tokens = convert_string_tokens($raw_tokens);
  my $module = shift @$tokens;
  if (ref $module and $module->[1] eq 'WORD') {
    $module = $module->[0];
  }
  if (is_module_name($module)) {
    if (is_version($tokens->[0])) {
      my $version = shift @$tokens;
      $c->add($module => $version);
    } else {
      $c->add($module => 0);
    }
  } else {
    push @{$c->{errors}}, "use if module not found";
  }
}

sub parse_base_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  my $tokens = convert_string_tokens($raw_tokens);
  if (is_version($tokens->[0])) {
    $c->add($used_module => shift @$tokens);
  }
  $c->add($_ => 0) for grep {!ref $_} @$tokens;
}

sub parse_parent_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  my $tokens = convert_string_tokens($raw_tokens);
  if (is_version($tokens->[0])) {
    $c->add($used_module => shift @$tokens);
  }
  my $prev;
  for my $token (@$tokens) {
    last if $token eq '-norequire';
    if (ref $token) {
      last if $token->[0] eq '-norequire';
      $prev = $token->[0];
      next;
    }
    $prev = $token;
    $c->add($token => 0) if is_module_name($token);
  }
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::NotQuiteLite::Parser::Core

=head1 DESCRIPTION

This parser is to deal with module inheritance by C<base> and
C<parent> modules, and conditional loading by C<if> module.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
