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
  keyword => {
    package => 'parse_package',
    exit => 'parse_begin_exit',
  },
}}

sub parse_if_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  while(my $token = shift @$raw_tokens) {
    last if $token->[1] eq 'COMMA';
  }

  my $tokens = convert_string_tokens($raw_tokens);
  my $module = shift @$tokens;
  if (ref $module and ($module->[1] eq 'WORD' or $module->[1] eq 'KEYWORD')) {
    $module = $module->[0];
  }
  if (is_module_name($module)) {
    if (is_version($tokens->[0])) {
      my $version = shift @$tokens;
      $c->add_recommendation($module => $version);
    } else {
      $c->add_recommendation($module => 0);
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
  while(my $token = shift @$tokens) {
    my $module = $token;
    if (ref $module and ($module->[1] || '') eq 'WORD') {
      # allow bareword, but disallow function()
      $module = $module->[0];
      next if @$tokens and ref $tokens->[0] and ($tokens->[0][1] || '') eq '()';
    }
    # bareword in parentheses
    if (ref $module and ref $module->[0]) {
      $module = $module->[0][0];
    }
    if (is_module_name($module)) {
      $c->add($module => 0);
    }
  }
}

sub parse_parent_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  my $tokens = convert_string_tokens($raw_tokens);
  if (is_version($tokens->[0])) {
    $c->add($used_module => shift @$tokens);
  }
  while(my $token = shift @$tokens) {
    last if $token eq '-norequire';
    my $module = $token;
    if (ref $token) {
      last if $token->[0] eq '-norequire';
    }
    if (ref $module and ($module->[1] || '') eq 'WORD') {
      # allow bareword, but disallow function()
      $module = $module->[0];
      next if @$tokens and ref $tokens->[0] and ($tokens->[0][1] || '') eq '()';
    }
    # bareword in parentheses
    if (ref $module and ref $module->[0]) {
      $module = $module->[0][0];
    }
    $c->add($module => 0) if is_module_name($module);
  }
}

sub parse_begin_exit {
  my ($class, $c, $raw_tokens) = @_;

  my @stack = @{$c->{stack} || []};
  if (grep {$_->[0] eq '{' and $_->[2] eq 'BEGIN'} @stack) {
    if (grep {$c->token_is_conditional($_->[0])} @$raw_tokens) {
      $c->{force_cond} = 1;
    } elsif (grep {$_->[0] eq '{' and $c->token_is_conditional($_->[2])} @stack) {
      $c->{force_cond} = 1;
    } else {
      $c->{ended} = 1;
      @{$c->{stack}} = ();
    }
  }
}

sub parse_package {
  my ($class, $c, $raw_tokens) = @_;

  my $tokens = convert_string_tokens($raw_tokens);
  shift @$tokens; # drop "package"
  my $package;
  for my $token (@$tokens) {
    if (ref $token && $token->[1] && $token->[1] eq 'WORD') {
      $c->add_package($token->[0]);
      last;
    }
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
