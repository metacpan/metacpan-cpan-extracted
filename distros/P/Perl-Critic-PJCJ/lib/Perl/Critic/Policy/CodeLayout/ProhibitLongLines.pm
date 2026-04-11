package Perl::Critic::Policy::CodeLayout::ProhibitLongLines v0.2.6;

use v5.26.0;
use strict;
use warnings;
use feature "signatures";
use experimental "signatures";

use parent qw( Perl::Critic::Policy );

use File::Basename                      qw( dirname );
use List::Util                          qw( any );
use Perl::Critic::Utils                 qw( $SEVERITY_MEDIUM );
use Perl::Critic::Utils::SourceLocation ();

my $Desc = "Line exceeds maximum length";
my $Expl = "Keep lines under the configured maximum for readability";

sub supported_parameters { (
  {
    name            => "max_line_length",
    description     => "Maximum allowed line length in characters",
    default_string  => "80",
    behavior        => "integer",
    integer_minimum => 1,
  }, {
    name           => "allow_lines_matching",
    description    => "Regex patterns for lines exempt from length check",
    default_string => "",
    behavior       => "string list",
  }, {
    name           => "gitattributes_line_length",
    description    => "Git attribute name for per-file line length override",
    default_string => "custom-line-length",
    behavior       => "string",
  },
) }

sub default_severity { $SEVERITY_MEDIUM }
sub default_themes   { qw( cosmetic formatting ) }

sub applies_to { "PPI::Document" }

sub violates ($self, $elem, $doc) {
  my $override = $self->_get_gitattr_line_length($doc->filename);
  return if defined $override && $override eq "ignore";

  my $max_length = $override // $self->{_max_line_length};
  my @patterns   = keys $self->{_allow_lines_matching}->%*;
  my $source     = $doc->serialize;
  my @lines      = split /\n/, $source;

  my @violations;

  for my $line_num (0 .. $#lines) {
    my $length = length $lines[$line_num];
    if ($length > $max_length) {
      next if any { $lines[$line_num] =~ /$_/ } @patterns;
      my $violation_desc
        = "Line is $length characters long (exceeds $max_length)";

      # Find a token on this line for accurate line number reporting
      my $line_token = $self->_find_token_on_line($doc, $line_num + 1);

      # If no token found, create synthetic element with correct line number
      if (!$line_token) {
        $line_token = Perl::Critic::Utils::SourceLocation->new(
          line_number   => $line_num + 1,
          column_number => 1,
          content       => $lines[$line_num],
          filename      => $doc->filename
        );
      }

      push @violations, $self->violation($violation_desc, $Expl, $line_token);
    }
  }

  @violations
}

sub _get_gitattr_line_length ($self, $filename) {
  return unless defined $filename && length $filename;
  my $attr = $self->{_gitattributes_line_length};
  return unless defined $attr && length $attr;

  my $output = eval {
    my $dir = dirname($filename);
    open my $fh, "-|", "git", "-C", $dir, "check-attr", $attr, "--", $filename
      or return;
    my $result = do { local $/ = undef; <$fh> };
    close $fh or return;
    $result
  };
  return unless defined $output && $output =~ /: \Q$attr\E: (.+)$/m;

  my $value = $1;
  return "ignore" if $value eq "ignore";
  return $value   if $value =~ /^\d+$/;
  return
}

sub _find_token_on_line ($self, $doc, $target_line) {
  my $found_token;

  $doc->find(
    sub ($top, $elem) {
      return 0 unless $elem->isa("PPI::Token");

      my $line = $elem->line_number;
      if (defined $line && $line == $target_line) {
        $found_token = $elem;
        return 1;
      }
      return 0;
    }
  );

  $found_token
}

"
I know you have a little life in you yet
I know you have a lot of strength left
"

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitLongLines - Prohibit long lines

=head1 VERSION

version v0.2.6

=head1 SYNOPSIS

  [CodeLayout::ProhibitLongLines]
  max_line_length = 72

  # Bad - line exceeds configured maximum
  my $very_long_variable_name = "long string that exceeds maximum length";

  # Good - line within limit
  my $very_long_variable_name =
    "long string that exceeds maximum length";

=head1 DESCRIPTION

This policy flags lines that exceed a configurable maximum length. Long lines
can be difficult to read, especially in narrow terminal windows or when
viewing code side-by-side with diffs or other files.

The default maximum line length is 80 characters, which provides good
readability across various display contexts while still allowing reasonable
code density.

You can configure C<perltidy> to keep lines within the specified limit.  Only
when it is unable to do that will you need to manually make changes.

=head1 CONFIGURATION

=head2 max_line_length

The maximum allowed line length in characters. Defaults to 80.

  [CodeLayout::ProhibitLongLines]
  max_line_length = 72

=head2 allow_lines_matching

A space-separated list of regex patterns. Lines matching any pattern are
exempt from the length check. This is useful for lines that cannot
reasonably be shortened, such as long package declarations or URLs.

  [CodeLayout::ProhibitLongLines]
  allow_lines_matching = ^\s*package\s+

Multiple patterns (space-separated):

  [CodeLayout::ProhibitLongLines]
  allow_lines_matching = ^\s*package\s+ https?://

=head2 gitattributes_line_length

The name of a git attribute to look up for per-file line length overrides.
Defaults to C<custom-line-length>. Set to an empty string to disable.

The attribute value may be an integer (overriding C<max_line_length> for
that file) or the literal string C<ignore> (suppressing all violations for
that file).

Configure in C<.gitattributes>:

  t/legacy/messy.t        custom-line-length=ignore
  t/generated/*.t         custom-line-length=200

Then in C<.perlcriticrc> (the default attribute name is shown; you only
need this line if you want a different name):

  [CodeLayout::ProhibitLongLines]
  gitattributes_line_length = custom-line-length

Requires C<git> on C<$PATH>. Falls back to the configured
C<max_line_length> when git is unavailable, the file is outside a
repository, or the attribute is unspecified.

=head1 EXAMPLES

=head2 Long Variable Assignments

  # Bad - exceeds 72 characters
  my $configuration_manager = VeryLongModuleName::ConfigurationManager->new;

  # Good - broken into multiple lines
  my $configuration_manager =
    VeryLongModuleName::ConfigurationManager->new;

=head2 Long Method Calls

  # Bad - exceeds 72 characters
  $object->some_very_very_long_method_name($param1, $param2, $param3, $param4);

  # Good - parameters on separate lines
  $object->some_very_very_long_method_name(
    $param1, $param2, $param3, $param4
  );

=head2 Long String Literals

  # Bad - exceeds 72 characters
  my $error_message =
    "This is a very long error message that exceeds the configured maximum";

  # Good - use concatenation or heredoc
  my $error_message = "This is a very long error message that " .
    "exceeds the configured maximum";

=head1 METHODS

=head2 supported_parameters

This method returns the parameters supported by this policy.

=head1 AFFILIATION

This Policy is part of the Perl::Critic::PJCJ distribution.

=head1 AUTHOR

Paul Johnson C<< <paul@pjcj.net> >>

=head1 COPYRIGHT

Copyright 2025 Paul Johnson.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
