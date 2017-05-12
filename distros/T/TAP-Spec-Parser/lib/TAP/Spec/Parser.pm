package TAP::Spec::Parser;
BEGIN {
  $TAP::Spec::Parser::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::Parser::VERSION = '0.10';
}
# ABSTRACT: Reference implementation of the TAP specification
use Mouse;
use Method::Signatures::Simple;
use Try::Tiny;
use Marpa::R2 2.025_001;
use TAP::Spec::TestSet ();

has 'exhaustive_strings' => (
  isa => 'Int',
  is => 'ro',
  default => 0,
);

has 'reader' => (
  isa => 'CodeRef',
  is => 'ro',
  required => 1,
);


# API adapters to MGC
method new_from_string ($class: $string, %args) {
  open my $fh, '<', \$string or die $!;
  my $reader = sub {
    scalar <$fh>;
  };

  $class->new(%args, reader => $reader);
}

method parse_from_string ($class: $string, %args) {
  $class->new_from_string($string, %args)->parse;
}


method new_from_handle ($class: $handle, %args) {
  my $reader = sub {
    scalar <$handle>;
  };

  $class->new(%args, reader => $reader);
}

method parse_from_handle ($class: $handle, %args) {
  $class->new_from_handle($handle, %args)->parse;
}


method new_from_file ($class: $file, %args) {
  open my $fh, '<', $file or die $!;
  my $reader = sub {
    scalar <$fh>;
  };

  $class->new(%args, reader => $reader);
}

method parse_from_file ($class: $file, %args) {
  $class->new_from_file($file, %args)->parse;
}

my $stream_grammar = Marpa::R2::Grammar->new({
  actions => 'TAP::Spec::Parser::Actions',
  start => 'Testset',
  rules => q{
    # Testset = Header (Plan Body / Body Plan) Footer
    Testset ::= Header Plan_And_Body Footer EOF  action => Testset
    Plan_And_Body ::=
        Plan Body  action => Plan_Body
      | Body Plan  action => Body_Plan

    # Header = [Comments] [Version]
    Header ::= Maybe_Comments Maybe_Version  action => Header
    Maybe_Comments ::= Comments  action => subrule1
    Maybe_Comments ::= action => undef
    Maybe_Version ::= Version  action => subrule1
    Maybe_Version ::= action => undef

    # Footer = [Comments]
    Footer ::= Maybe_Comments  action => Footer

    # Body = *(Comment / TAP-Line)
    Body ::= Body_Line*  action => Body
    Body_Line ::=
        Comment  action => subrule1
      | TAP_Line  action => subrule1

    # Comments = 1*Comment
    Comments ::= Comment+  action => Comments
  },
});
$stream_grammar->precompute;

method stream_grammar {
  $stream_grammar
}

my $line_grammar = Marpa::R2::Grammar->new({
  actions => 'TAP::Spec::Parser::Actions',
  start => 'Valid_Line',
  rules => q{
    # "Any output line that is not a version, a plan, a test line, a diagnostic
    # or a bail out is considered an 'unknown' line."
    # Valid_Line is a meta-rule that matches any valid line of TAP (a rule that
    # starts at the beginning of a line and matches EOL at the end). Any line of
    # input that doesn't match "Valid_Line" is discarded as a "junk line", so
    # keep this up to date.
    Valid_Line ::=
        TAP_Line  action => tokenize_TAP_Line
      | Version   action => tokenize_Version
      | Plan      action => tokenize_Plan
      | Comment   action => tokenize_Comment

    # Tap-Line = Test-Result / Bail-Out
    TAP_Line ::=
        Test_Result  action => subrule1
      | Bail_Out     action => subrule1

    # Version = "TAP version" SP Version-Number EOL ; ie. "TAP version 13"
    Version ::= TAP_version SP Version_Number EOL  action => Version

    # Version-Number = Positive-Integer
    Version_Number ::= Positive_Integer  action => subrule1

    # Plan = ( Plan-Simple / Plan-Todo / Plan-Skip-All ) EOL
    Plan ::=
        Plan_Simple   EOL  action => subrule1
      | Plan_Todo     EOL  action => subrule1
      | Plan_Skip_All EOL  action => subrule1

    # Plan-Simple = "1.." Number-Of-Tests
    Plan_Simple ::= Plan_Simple_Body  action => Plan_Simple
    Plan_Simple_Body ::= ONE_DOT_DOT Number_Of_Tests  action => subrule2 # Capture no. of tests

    # Plan-Todo = Plan-Simple "todo" 1*(SP Test-Number) ";" ; obsolete
    Plan_Todo ::= Plan_Simple_Body SP todo SP Test_Numbers SEMI  action => Plan_Todo
    Test_Numbers ::= Test_Number+  separator => SP proper => 1 action => Test_Numbers

    # Plan-Skip-All = "1..0" SP "skip" SP Reason
    Plan_Skip_All ::= ONE_DOT_DOT_0 SP skip SP Reason  action => Plan_Skip_All

    # Reason = String
    Reason ::= String  action => subrule1

    # Test-Number = Positive-Integer
    Test_Number ::= Positive_Integer  action => subrule1

    # Test-Result = Status [SP Test-Number] [SP Description]
    #               [SP "#" SP Directive [SP Reason]] EOL
    Test_Result ::= Status Maybe_Test_Number Maybe_Description Maybe_Directive_Reason EOL  action => Test_Result
    Maybe_Test_Number ::= SP Test_Number  action => subrule2
    Maybe_Test_Number ::= action => undef
    Maybe_Description ::= SP Description  action => subrule2
    Maybe_Description ::= action => undef
    Maybe_Directive_Reason ::= SP HASH SP Directive Maybe_Reason   action => Maybe_Directive_Reason
    Maybe_Directive_Reason ::= action => undef
    Maybe_Reason ::= SP Reason  action => subrule2
    Maybe_Reason ::= action => undef

    # Status = "ok" / "not ok"
    Status ::=
        ok      action => subrule1
      | not_ok  action => subrule1

    # Description = Safe-String
    Description ::= Safe_String  action => subrule1

    # Directive = "SKIP" / "TODO"
    Directive ::=
        SKIP  action => subrule1
      | TODO  action => subrule1

    # Bail-Out = "Bail out!" [SP Reason] EOL
    Bail_Out ::= Bail_out Maybe_Reason EOL  action => Bail_Out

    # Comment = "#" String EOL
    Comment ::= HASH String EOL  action => Comment

    # String = 1*(Safe-String / "#")
    String ::= String_Part+  action => String
    String_Part ::=
        Safe_String  action => subrule1
      | HASH         action => subrule1
  },
});
$line_grammar->precompute;

method line_grammar {
  $line_grammar
}

my %tokens = (
  'ONE_DOT_DOT'   => [ qr/\G1\.\./ ],
  'ONE_DOT_DOT_0' => [ qr/\G1\.\.0/ ],
  'TODO'          => [ qr/\GTODO/i, 'TODO' ],
  'SKIP'          => [ qr/\GSKIP/i, 'SKIP' ],
  'ok'            => [ qr/\Gok/i, 'ok' ],
  'not_ok'        => [ qr/\Gnot ok/i, 'not ok' ],
  'TAP_version'   => [ qr/\GTAP version/i ],
  'Bail_out'      => [ qr/\GBail out!/i ],
  'HASH'          => [ qr/\G#/, '#' ],
  'SEMI'          => [ qr/\G;/, ';' ],
  'SP'            => [ qr/\G /, ' ' ],
  
  # EOL = LF / CRLF
  'EOL' => [ qr/\G(?:\n|\r\n)/ ],
  
  # Safe-String = 1*(%x01-09 %x0B-0C %x0E-22 %x24-FF)  ; UTF8 without EOL or "#"
  'Safe_String' => [ qr/\G([\x01-\x09\x0b-\x0c\x0e-\x22\x24-\xff]+)/ ],

  # Positive-Integer = ("1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9") *DIGIT
  'Positive_Integer' => [ qr/\G([1-9][0-9]*)/, sub { 0 + $1 } ],

  # Number-Of-Tests = 1*DIGIT
  'Number_Of_Tests' => [ qr/\G(\d+)/, sub { 0 + $1 } ],
);

method lex ($input, $pos, $expected) {
  my @matches;

  TOKEN: for my $token_name (@$expected) {
    my $token = $tokens{$token_name};
    die "Unknown token $token_name" unless defined $token;
    my $rule = $token->[0];
    pos($$input) = $pos;
    next TOKEN unless $$input =~ $rule;

    my $matched_len = $+[0] - $-[0];
    my $matched_value = undef;

    if (defined( my $val = $token->[1] )) {
      if (ref $val eq 'CODE') {
        $matched_value = $val->();
      } else {
        $matched_value = $val;
      }
    } elsif ($#- > 0) { # Captured a value
      $matched_value = $1;
    }

    push @matches, [ $token_name, \$matched_value, $matched_len ];

    if ($token_name eq 'Safe_String') {
      if ($self->exhaustive_strings) {
        for my $len (reverse 1 .. $matched_len - 1) {
          my $value = substr($matched_value, 0, $len);
          push @matches, [ $token_name, \$value, $len ];
        }
      } elsif ($matched_value =~ /(.*) $/) {
        my $value = $1;
        push @matches, [ $token_name, \$value, $matched_len - 1 ];
      }
    }
  }

  return @matches;
}

method parse_line ($line) {
  my $rec = Marpa::R2::Recognizer->new({
      grammar => $self->line_grammar,
      ranking_method => 'rule',
#      trace_terminals => 2,
#      trace_values => 1,
#      trace_actions => 1,
  });

  for my $pos (0 .. length($line) - 1) {
    my $expected_tokens = $rec->terminals_expected;

    if (@$expected_tokens) {
      my @matching_tokens = $self->lex(\$line, $pos, $expected_tokens);
      $rec->alternative( @$_ ) for @matching_tokens;
    }

    my $ok = eval {
      $rec->earleme_complete;
      1;
    };
    if (!$ok) {
      return [ 'Junk_Line', $line ];
    }
  }

  $rec->end_input;

  return ${$rec->value};
}

method parse {
  my $rec = Marpa::R2::Recognizer->new({
      grammar => $self->stream_grammar,
      ranking_method => 'rule',
#      trace_terminals => 2,
#      trace_values => 1,
#      trace_actions => 1,
  });

  my $reader = $self->reader;

  while (defined( my $line = $reader->() )) {
#    print "Expecting: ", join(" ", @{ $rec->terminals_expected }), "\n";
    my $line_token = $self->parse_line($line);
    next if $line_token->[0] eq 'Junk_Line'; # XXX do something cooler
    unless (defined $rec->read(@$line_token)) {
      my $expected = $rec->terminals_expected;
      die "Parse error, expecting [@$expected], got $line_token->[0]";
    }
  }

  $rec->read('EOF');

  return ${$rec->value};
}

no Mouse;

package TAP::Spec::Parser::Actions;
BEGIN {
  $TAP::Spec::Parser::Actions::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::Parser::Actions::VERSION = '0.10';
}

sub subrule1 {
  $_[1];
}

sub subrule2 {
  $_[2];
}

sub tokenize_TAP_Line {
  [ 'TAP_Line', $_[1] ];
}

sub tokenize_Version {
  [ 'Version', $_[1] ];
}

sub tokenize_Plan {
  [ 'Plan', $_[1] ];
}

sub tokenize_Comment {
  [ 'Comment', $_[1] ];
}

sub Testset {
  my %tmp;
  $tmp{header} = $_[1] || TAP::Spec::Header->new;
  $tmp{plan} = $_[2][0];
  $tmp{body} = $_[2][1];
  $tmp{footer} = $_[3] || TAP::Spec::Footer->new;

  TAP::Spec::TestSet->new(%tmp);
}

sub Plan_Body {
  my $plan = $_[1];
  my $body = $_[2];
  [ $plan, $body ];
}

sub Body_Plan {
  my $body = $_[1];
  my $plan = $_[2];
  [ $plan, $body ];
}

sub Header {
  my %tmp;
  $tmp{comments} = $_[1] if defined $_[1];
  $tmp{version} = $_[2] if defined $_[2];
  TAP::Spec::Header->new(%tmp);
}

# Footer          = [Comments]
sub Footer {
  my %tmp;
  $tmp{comments} = $_[1] if defined $_[1];
  TAP::Spec::Footer->new(%tmp);
}

# Body            = *(Comment / TAP-Line)
sub Body {
  shift;
  my @lines = @_;
  TAP::Spec::Body->new(lines => \@lines);
}

sub Comments {
  shift;
  my @comments = @_;
  return \@comments;
}

sub Version {
  my $version_number = $_[3];
  TAP::Spec::Version->new(version_number => $version_number);
}

sub Plan_Simple {
  my $number_of_tests = $_[1];
  TAP::Spec::Plan::Simple->new(number_of_tests => $number_of_tests);
}

sub Plan_Todo {
  my $number_of_tests = $_[1];
  my $skipped_tests = $_[5];

  TAP::Spec::Plan::Todo->new(
    number_of_tests => $number_of_tests,
    skipped_tests => $skipped_tests,
  );
}

sub Test_Numbers {
  shift;
  my @test_numbers = @_;
  \@test_numbers;
}

sub Plan_Skip_All {
  my $reason = $_[5];
  TAP::Spec::Plan::SkipAll->new(
    reason => $reason,
  );
}

sub Test_Result {
  my %tmp;
  $tmp{status} = $_[1];
  $tmp{number} = $_[2] if defined $_[2];
  $tmp{description} = $_[3] if defined $_[3];
  $tmp{directive} = $_[4][0] if defined $_[4] && defined $_[4][0];
  $tmp{reason} = $_[4][1] if defined $_[4] && defined $_[4][1];
  TAP::Spec::TestResult->new(%tmp);
}

sub Maybe_Directive_Reason {
  my $directive = $_[4];
  my $reason = $_[5];
  return [ $directive, $reason ];
}

sub Bail_Out {
  my %tmp;
  $tmp{reason} = $_[1] if defined $_[1];
  TAP::Spec::BailOut->new( %tmp );
}

sub Comment {
  my $text = $_[1];
  TAP::Spec::Comment->new( text => $text );
}

sub String {
  shift;
  my @parts = @_;
  return join "", @parts;
}

sub undef {
  undef
}

1;

__END__

=pod

=head1 NAME

TAP::Spec::Parser - Reference implementation of the TAP specification

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This module is part of the effort to turn the Test Anything Protocol into an
IETF-approved internet standard. It's not optimized for production use (although
people might find it useful); instead it's meant as a running embodiment of the
TAP grammar in the draft standard, allowing the grammar to be comprehensively
tested.

=head1 METHODS

=head2 TAP::Spec::Parser->parse_from_string($string)

Attempt to parse a TAP TestSet from C<$string>. Returns a L<TAP::Spec::TestSet>
on success, throws an exception on failure.

=head2 TAP::Spec::Parser->parse_from_handle($handle)

Like C<parse_from_string> only accepts an opened filehandle.

=head2 TAP::Spec::Parser->parse_from_file($filename)

Like C<parse_from_string> only accepts the name of a file to read a TAP
stream from.

=head1 SEE ALSO

=over 4

=item * L<http://testanything.org/wiki/index.php/TAP_at_IETF:_Draft_Standard>

=back

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
