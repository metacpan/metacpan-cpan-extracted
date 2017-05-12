package Perl::PrereqScanner::NotQuiteLite::Parser::Moose;

use strict;
use warnings;
use Perl::PrereqScanner::NotQuiteLite::Util;

sub register { return {
  use => {
    'Moose' => 'parse_moose_args',
    'Moo'   => 'parse_moose_args',
    'Mo'    => 'parse_moose_args',
    'Mouse' => 'parse_moose_args',
  },
  no => {
    'Moose' => 'parse_no_moose_args',
    'Moo'   => 'parse_no_moose_args',
    'Mo'    => 'parse_no_moose_args',
    'Mouse' => 'parse_no_moose_args',
  },
}}

sub parse_moose_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  $c->register_keyword(
    'extends',
    [$class, 'parse_extends_args', $used_module],
  );
  $c->register_keyword(
    'with',
    [$class, 'parse_with_args', $used_module],
  ) unless $used_module eq 'Mo'; # Mo doesn't support with
}

sub parse_no_moose_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  $c->remove_keyword('extends');
  $c->remove_keyword('with') unless $used_module eq 'Mo';
}

sub parse_extends_args { shift->_parse_loader_args(@_) }
sub parse_with_args { shift->_parse_loader_args(@_) }

sub _parse_loader_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  my $tokens = convert_string_tokens($raw_tokens);
  shift @$tokens; # discard extends, with;

  my $prev;
  for my $token (@$tokens) {
    if (!ref $token) {
      $c->add($token => 0);
      $prev = $token;
      next;
    }
    my $desc = $token->[1];
    if ($desc eq '{}') {
      my @hash_tokens = @{$token->[0] || []};
      for(my $i = 0, my $len = @hash_tokens; $i < $len; $i++) {
        if ($hash_tokens[$i][0] eq '-version' and $i < $len - 2) {
          my $maybe_version_token = $hash_tokens[$i + 2];
          my $maybe_version = $maybe_version_token->[0];
          if (ref $maybe_version) {
            $maybe_version = $maybe_version->[0];
          }
          if ($prev and is_version($maybe_version)) {
            $c->add($prev => $maybe_version);
          }
        }
      }
    }
  }
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::NotQuiteLite::Parser::Moose

=head1 DESCRIPTION

This parser is to deal with modules loaded by C<extends> and/or
C<with> from L<Moose> and its friends.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
