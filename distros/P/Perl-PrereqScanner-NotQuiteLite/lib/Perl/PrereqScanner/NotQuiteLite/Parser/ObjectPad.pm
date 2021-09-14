package Perl::PrereqScanner::NotQuiteLite::Parser::ObjectPad;

use strict;
use warnings;
use Perl::PrereqScanner::NotQuiteLite::Util;

sub register { return {
  use => {
    'Object::Pad' => 'parse_object_pad_args',
  },
}}

sub parse_object_pad_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  $c->register_sub_parser(
    'class',
    [$class, 'parse_class_args', $used_module],
  );
  $c->register_sub_parser(
    'role',
    [$class, 'parse_role_args', $used_module],
  );

  $c->register_keyword_parser(
    'class',
    [$class, 'parse_class_args', $used_module],
  );
  $c->register_keyword_parser(
    'role',
    [$class, 'parse_role_args', $used_module],
  );

  $c->register_sub_keywords(qw/
    class method role
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
      if ($token->[0] eq 'isa' or $token->[0] eq 'extends') {
        $isa  = 1;
        $does = 0;
        next;
      }
      if ($token->[0] eq 'does' or $token->[0] eq 'implements') {
        $isa  = 0;
        $does = 1;
        next;
      }
      if (is_module_name($token->[0])) {
        $name = $token->[0];
        if (@$tokens && is_version($tokens->[0])) {
          $version = shift @$tokens;
        }
        if ($isa or $does) {
          $c->add($name => $version);
        } else {
          $c->add_package($name => $version);
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

Perl::PrereqScanner::NotQuiteLite::Parser::ObjectPad

=head1 DESCRIPTION

This parser is to deal with modules loaded by C<isa/extends> and/or
C<does> from L<Object::Pad>.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
