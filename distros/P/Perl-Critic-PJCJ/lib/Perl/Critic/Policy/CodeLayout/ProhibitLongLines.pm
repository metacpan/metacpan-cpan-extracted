package Perl::Critic::Policy::CodeLayout::ProhibitLongLines v0.3.0;

use v5.26.0;
use strict;
use warnings;
use feature "signatures";
use experimental "signatures";

use parent qw( Perl::Critic::Policy );

use Encode              qw( decode FB_CROAK );
use File::Basename      qw( basename dirname );
use File::Spec          ();
use List::Util          qw( any );
use Perl::Critic::Utils qw( $SEVERITY_MEDIUM words_from_string );
use Perl::Critic::Utils::SourceLocation ();

my $Expl = "Keep lines under the configured maximum for readability";

my %Lookup_needed;  # abs dir             -> can a lookup possibly answer?
my %Attr_value;     # "$attr\0$abs_file"  -> computed override (may be undef)

sub _parse_allow_lines_matching ($self, $parameter, $config_string) {
  my $string = $config_string // $parameter->get_default_string // "";
  my @patterns;
  for my $pattern (words_from_string($string)) {
    my $re = eval { qr/$pattern/ };
    if (!defined $re) {
      my $error = $@;
      chomp $error;
      $self->throw_parameter_value_exception(
        "allow_lines_matching", $pattern,
        undef,                  "is not a valid regular expression: $error",
      );
    }
    push @patterns, $re;
  }
  $self->__set_parameter_value($parameter, \@patterns);
  return
}

sub supported_parameters ($self) { (
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
    parser         => \&_parse_allow_lines_matching,
  }, {
    name           => "gitattributes_line_length",
    description    => "Git attribute name for per-file line length override",
    default_string => "custom-line-length",
    behavior       => "string",
  },
) }

sub default_severity ($self) { $SEVERITY_MEDIUM }
sub default_themes   ($self) { qw( cosmetic formatting pjcj ) }

sub applies_to ($self) { "PPI::Document" }

sub _lookup_needed ($dir) {
  while (1) {
    return 1 if -e "$dir/.gitattributes";
    if (-e "$dir/.git") {
      return 1 if !-d "$dir/.git" || -e "$dir/.git/info/attributes";
      return 0;
    }
    my $parent = dirname($dir);
    return 0 if $parent eq $dir;
    $dir = $parent;
  }
}

sub _gitattr_lookup ($self, $attr, $filename) {
  my $dir     = dirname($filename);
  my $abs_dir = File::Spec->rel2abs($dir);
  $Lookup_needed{$abs_dir} //= _lookup_needed($abs_dir);
  return unless $Lookup_needed{$abs_dir};

  my $base   = basename($filename);
  my $output = eval {
    open my $saved_err, ">&", \*STDERR or return;
    my $quiet  = open STDERR, ">", File::Spec->devnull;
    my $opened = open my $fh, "-|", "git", "-C", $dir, "check-attr", $attr,
      "--", $base;
    if ($quiet) {
      # Restore our own STDERR; keep going even if the dup back fails, since
      # abandoning the lookup would not make a broken STDERR any better
      open STDERR, ">&", $saved_err or warn "Cannot restore STDERR: $!\n";
    }
    return unless $opened;
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

sub _get_gitattr_line_length ($self, $filename) {
  return unless defined $filename && length $filename;
  my $attr = $self->{_gitattributes_line_length};
  return unless defined $attr && length $attr;

  my $key = join "\0", $attr, File::Spec->rel2abs($filename);
  return $Attr_value{$key} if exists $Attr_value{$key};
  $Attr_value{$key} = $self->_gitattr_lookup($attr, $filename)
}

sub _first_tokens_by_line ($self, $doc) {
  my %first;
  for my $token ($doc->tokens) {
    my $line = $token->line_number;
    next unless defined $line;
    $first{$line} //= $token;
  }
  \%first
}

sub violates ($self, $elem, $doc) {
  my $override = $self->_get_gitattr_line_length($doc->filename);
  return if defined $override && $override eq "ignore";

  my $max_length = $override // $self->{_max_line_length};
  my $patterns   = $self->{_allow_lines_matching};
  my $source     = $doc->serialize;

  # PPI serializes source as octets, so decode to characters before measuring
  # line lengths.  Keep the octets if the source is not valid UTF-8.
  my $decoded = eval { decode("UTF-8", $source, FB_CROAK) };
  $source = $decoded if defined $decoded;

  my @lines = split /\n/, $source;

  my @violations;
  my $token_map;

  for my $line_num (0 .. $#lines) {
    my $length = length $lines[$line_num];
    if ($length > $max_length) {
      next if any { $lines[$line_num] =~ $_ } @$patterns;
      my $violation_desc
        = "Line is $length characters long (exceeds $max_length)";

      # Anchor at the first token on this line for accurate reporting
      $token_map //= $self->_first_tokens_by_line($doc);
      my $line_token = $token_map->{ $line_num + 1 };

      # If no token found, create synthetic element with correct line number
      if (!$line_token) {
        $line_token = Perl::Critic::Utils::SourceLocation->new(
          line_number   => $line_num + 1,
          column_number => 1,
          content       => $lines[$line_num],
          filename      => $doc->filename,
        );
      }

      push @violations, $self->violation($violation_desc, $Expl, $line_token);
    }
  }

  @violations
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

version v0.3.0

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

=head1 CHARACTER ENCODING

Line lengths are measured in characters.  Source is decoded as UTF-8 before
measuring, so each multi-byte UTF-8 character counts as one.  Single-byte
encodings such as ASCII and Latin-1 are also measured correctly.  Source in
other multi-byte encodings (for example Shift-JIS) is not decoded and is
measured by its octet length instead.

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

Invalid patterns are reported as a configuration error when the policy is
loaded.

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

Overrides are read from C<.gitattributes> files and the repository's
C<.git/info/attributes>. Attribute sources configured elsewhere (such as
C<core.attributesFile>) are not consulted.

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

Paul Johnson <paul@pjcj.net>

=head1 COPYRIGHT

Copyright 2025 Paul Johnson.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
