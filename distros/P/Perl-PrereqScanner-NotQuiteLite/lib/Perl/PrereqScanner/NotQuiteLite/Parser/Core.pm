package Perl::PrereqScanner::NotQuiteLite::Parser::Core;

use strict;
use warnings;
use Perl::PrereqScanner::NotQuiteLite::Util;

my %feature_since = (
  say => '5.010',
  state => '5.010',
  switch => '5.010',
  unicode_strings => '5.012',
  current_sub => '5.016',
  evalbytes => '5.016',
  fc => '5.016',
  arybase => '5.016',  # removed
  unicode_eval => '5.016',
  lexical_subs => '5.018',
  postderef => '5.020',
  postderef_qq => '5.020',
  signatures => '5.020',
  bitwise => '5.022',
  refaliasing => '5.022',
  declared_refs => '5.026',
  indirect => '5.032',
  isa => '5.032',
  multidimensional => '5.034',
  bareword_filehandles => '5.034',
  try => '5.034',
  defer => '5.036',
  extra_paired_delimiters => '5.036',
  class => '5.038',
  module_true => '5.038',
);

my %builtin_since = (
  true => '5.036',
  false => '5.036',
  inf => '5.040',
  nan => '5.040',

  is_bool => '5.036',
  weaken => '5.036',
  unweaken => '5.036',
  is_weak => '5.036',
  blessed => '5.036',
  refaddr => '5.036',
  reftype => '5.036',
  ceil => '5.036',
  floor => '5.036',
  is_tainted => '5.038',
  trim => '5.036',
  stringify => '5.040',

  created_as_string => '5.036',
  created_as_number => '5.036',

  load_module => '5.040',

  indexed => '5.036',
  export_lexically => '5.038',
);

sub register { return {
  use => {
    if => 'parse_if_args',
    base => 'parse_base_args',
    parent => 'parse_parent_args',
    feature => 'parse_feature_args',
    experimental => 'parse_feature_args',
    builtin => 'parse_builtin_args',
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

sub parse_feature_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  if ($used_module eq 'feature') {
    $c->add_perl('5.010', 'feature');
  } elsif ($used_module eq 'experimental') {
    $c->add_perl('5.020', 'experimental');
  }
  my $tokens = convert_string_tokens($raw_tokens);
  if (is_version($tokens->[0])) {
    $c->add($used_module => shift @$tokens);
  }
  while(my $token = shift @$tokens) {
    next if ref $token;
    $c->{feature}{$token} = 1;
    if ($token eq 'class') {
        $class->register_class($c, $used_module);
    }
    if (exists $feature_since{$token}) {
      $c->add_perl($feature_since{$token} => "feature $token");
      next;
    }
    if ($token =~ /^:5\.([0-9]+)(\.\[0-9]+)?/) {
      my $version = sprintf '5.%03d', $1;
      $c->add_perl($version, $token);
      next;
    }
  }
}

sub parse_builtin_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  my $tokens = convert_string_tokens($raw_tokens);
  if (is_version($tokens->[0])) {
    $c->add($used_module => shift @$tokens);
  }
  while(my $token = shift @$tokens) {
    next if ref $token;
    $c->{builtin}{$token} = 1;
    if (exists $builtin_since{$token}) {
      $c->add_perl($builtin_since{$token} => "builtin $token");
      next;
    }
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
  my $token = shift @$tokens;
  if (ref $token && $token->[1] && $token->[1] eq 'WORD') {
    $c->add_package($token->[0]);
  }
  if (@$tokens) {
    $token = shift @$tokens;
    if (is_version($token)) {
      $c->add_perl("5.012", "package PACKAGE VERSION");
      $token = shift @$tokens;
    }
    if (ref $token && $token->[1] && $token->[1] =~ /^\{/) {
      $c->add_perl("5.014", "package PACKAGE (VERSION) {}");
    }
  }
}

sub register_class {
  my ($class, $c, $used_module) = @_;

  $c->register_sub_parser(
    'class',
    [$class, 'parse_class_args', $used_module],
  );
  # not implemented yet
  # $c->register_sub_parser(
  #   'role',
  #   [$class, 'parse_role_args', $used_module],
  # );

  $c->register_keyword_parser(
    'class',
    [$class, 'parse_class_args', $used_module],
  );
  # not implemented yet
  # $c->register_keyword_parser(
  #   'role',
  #   [$class, 'parse_role_args', $used_module],
  # );

  # role is not implemented yet
  $c->register_sub_keywords(qw/
     class method
  /);

  $c->prototype_re(qr{\G(\((?:[^\\\(\)]*(?:\\.[^\\\(\)]*)*)\))});
}

sub parse_class_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  my $tokens = convert_string_tokens($raw_tokens);
  shift @$tokens; # discard class

  my $isa = my $does = 0;
  while(my $token = shift @$tokens) {
    my ($name, $version) = ('', 0);
    if (ref $token && $token->[1] && $token->[1] eq 'WORD') {
      if (is_module_name($token->[0])) {
        $name = $token->[0];
        if (@$tokens && is_version($tokens->[0])) {
          $version = shift @$tokens;
        }
        $c->add_package($name => $version);
      }
    }
    if (ref $token && $token->[1] && $token->[1] eq 'ATTRIBUTE') {
      while($token->[0] =~ s/:(?:isa|does)\(([^)]+)\)//) {
        my ($name, $version) = split /\s+/, $1;
        $version ||= 0;
        if (is_module_name($name) && is_version($version)) {
          $c->add($name => $version);
        }
      }
    }
  }
}

sub parse_role_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  my $tokens = convert_string_tokens($raw_tokens);
  shift @$tokens; # discard role

  while(my $token = shift @$tokens) {
    my ($name, $version) = ('', 0);
    if (is_module_name($token->[0])) {
      $name = $token->[0];
      if (@$tokens && is_version($tokens->[0])) {
        $version = shift @$tokens;
      }
      $c->add_package($name => $version);
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
