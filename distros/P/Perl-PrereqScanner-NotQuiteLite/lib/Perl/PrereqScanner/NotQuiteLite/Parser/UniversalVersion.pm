package Perl::PrereqScanner::NotQuiteLite::Parser::UniversalVersion;

use strict;
use warnings;
use Perl::PrereqScanner::NotQuiteLite::Util;

sub register { return {
  method => {
    VERSION => 'parse_version_args',
  },
}}

sub parse_version_args {
  my ($class, $c, $raw_tokens) = @_;

  my ($module_token, undef, undef, $args_tokens) = @$raw_tokens;
  my $module = $module_token->[0];
  my @tokens_in_parens = @{$args_tokens->[0] || []};
  my ($module_version) = $tokens_in_parens[0][0][0];
  if ($module_version =~ /^v?[0-9._]+$/) {
    $c->add_recommendation($module => $module_version) if $c->has_added_recommendation($module);
  }
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::NotQuiteLite::Parser::UniversalVersion

=head1 DESCRIPTION

This parser is to deal with a VERSION method called by a	 module.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
