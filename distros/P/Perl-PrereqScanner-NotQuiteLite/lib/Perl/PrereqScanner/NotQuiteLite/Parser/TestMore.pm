package Perl::PrereqScanner::NotQuiteLite::Parser::TestMore;

use strict;
use warnings;

sub register { return {
  use => {
    'Test::More' => 'parse_test_more_args',
  },
}}

sub parse_test_more_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  $c->register_keyword(
    'done_testing',
    [$class, 'parse_done_testing_args', $used_module],
  );
}

sub parse_done_testing_args {
  my ($class, $c, $used_module, $raw_tokens) = @_;

  $c->add($used_module => '0.88');
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::NotQuiteLite::Parser::TestMore

=head1 DESCRIPTION

This parser is to update the minimum version requirement of
L<Test::More> to 0.88 if C<done_testing> is found by the scanner.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
