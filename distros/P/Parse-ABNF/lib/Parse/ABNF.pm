package Parse::ABNF;
use 5.012;
use strict;
use warnings;
use Parse::RecDescent;

our $VERSION = '0.11';
our $Grammar = q{

  {
    sub Make {
      my $class = shift;
      my %opts = @_;

      # Unfold single item groups and choices
      return $opts{value}->[0] if $class eq 'Group' and @{$opts{value}} == 1;
      return $opts{value}->[0] if $class eq 'Choice' and @{$opts{value}} == 1;

      return { class => $class, %opts };
    }
  }

  parse: rulelist {
    $return = $item[1];
  }

  empty_line: c_wsp(s?) c_nl

  # The /^\Z/ ensures that we don't leave unparsed trailing content
  # if there are errors in the grammar (Parse::RecDescent's default)

  rulelist: empty_line(s?) rule(s) /^\Z/ {
    $return = $item[2];
  }

  rule: rulename c_wsp(s?) "=" c_wsp(s?) elements c_nl empty_line(s?) {
    $return = Make(Rule => name => $item[1], value => $item[5]);
  }

  rule: rulename c_wsp(s?) "=/" c_wsp(s?) elements c_nl empty_line(s?) {
    $return = Make(Rule => name => $item[1], value => $item[5], combine => 'choice');
    
  }

  # Generate an error message if the rule production is not matched.
  rule: <error>

  rulename: /[a-zA-Z][a-zA-Z0-9-]*/ {
    $return = $item[1];
  }

  # n exactly
  repetition: /\d+/ element {
    $return = Make(Repetition => min => $item[1], max => $item[1], value => $item[2]);
  }

  # n to m
  repetition: /\d+/ "*" /\d+/ element {
    $return = Make(Repetition => min => $item[1], max => $item[3], value => $item[4]);
  }

  # 0 to n
  repetition: "*" /\d+/ element {
    $return = Make(Repetition => min => 0, max => $item[2], value => $item[3]);
  }

  # n or more
  repetition: /\d+/ "*" element {
    $return = Make(Repetition => min => $item[1], max => undef, value => $item[3]);
  }

  # zero or more
  repetition: "*" element {
    $return = Make(Repetition => min => 0, max => undef, value => $item[2]);
  }

  # exactly one
  repetition: element {
     $return = $item[1];
  }

  # 
  elements: alternation c_wsp(s?) {
    $return = $item[1];
  }

  alt_op: "/"

  #
  alternation: concatenation (c_wsp(s?) alt_op c_wsp(s?) concatenation)(s?) {
    $return = Make(Choice => value => [$item[1], @{$item[2]}]);
  }

  #
  concatenation: repetition (c_wsp(s) repetition)(s?) {
    $return = Make(Group => value => [$item[1], @{$item[2]}]);
  }

  #
  element: ref_val | group | option | char_val | num_val | prose_val {
    $return = $item[1];
  }

  ref_val: rulename {
    $return = Make(Reference => name => $item[1]);
  }

  # 
  group: "(" c_wsp(s?) alternation c_wsp(s?) ")" {
    $return = $item[3];
  }

  #
  option: "[" c_wsp(s?) alternation c_wsp(s?) "]" {
    $return = Make(Repetition => min => 0, max => 1, value => $item[3]);
  }

  c_wsp: /[ \t]/

  c_wsp: c_nl /[ \t]/

  newline: "\n"

  c_nl: newline

  c_nl: comment

  comment: /;[ \t\x21-\x7e]*/ newline

  char_val: '"' /[\x20-\x21\x23-\x7E]*/ '"' {
    $return = Make(Literal => value => $item[2]);
  }

  num_val: bin_val | dec_val | hex_val {
    $return = $item[1];
  }

  bin_val: "%b" /[01]+/ "-" /[01]+/ {
    $return = Make(Range => type => 'binary', min => $item[2], max => $item[4]);
  }

  dec_val: "%d" /\d+/ "-" /\d+/ {
    $return = Make(Range => type => 'decimal', min => $item[2], max => $item[4]);
  }

  hex_val: "%x" /[0-9a-fA-F]+/ "-" /[0-9a-fA-F]+/ {
    $return = Make(Range => type => 'hex', min => $item[2], max => $item[4]);
  }

  bin_val: "%b" /[01]+/ /(?:\.[01]+)*/ {
    $return = Make(String => type => 'binary',  value => [split/\./, "$item[2]$item[3]"]);
  }

  dec_val: "%d" /\d+/ /(?:\.\d+)*/ {
     $return = Make(String => type => 'decimal', value => [split/\./, "$item[2]$item[3]"]);
  }

  hex_val: "%x" /[0-9a-fA-F]+/ /(?:\.[0-9a-fA-F]+)*/ {
    $return = Make(String => type => 'hex', value => [split/\./, "$item[2]$item[3]"]);
  }

  prose_val: "<" /[\x20-\x3d\x3f-\x7e]*/ ">" {
    $return = Make(ProseValue => value => $item[2]);
  }

};

our $CoreRulesGrammar = q{

ALPHA          =  %x41-5A / %x61-7A
BIT            =  "0" / "1"
CHAR           =  %x01-7F
CR             =  %x0D
CRLF           =  CR LF
CTL            =  %x00-1F / %x7F
DIGIT          =  %x30-39
DQUOTE         =  %x22
HEXDIG         =  DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
HTAB           =  %x09
LF             =  %x0A
LWSP           =  *(WSP / CRLF WSP)
OCTET          =  %x00-FF
SP             =  %x20
VCHAR          =  %x21-7E
WSP            =  SP / HTAB

};

# TODO: Perhaps this is not such a good idea, users may attempt to
# modify the data and thus affect simultaneously running modules.
our $CoreRules = do {
  __PACKAGE__->new->parse( $CoreRulesGrammar );
};

sub new {
  my $class = shift;
  local $Parse::RecDescent::skip = '';
  bless { _p => Parse::RecDescent->new($Grammar) }, $class;
}

sub parse {
  my $self = shift;
  my $string = shift;
  my $result = $self->{_p}->parse($string);
  return $result;
}

sub parse_to_grammar_formal {
  my ($self, $string, %options) = @_;
  my $result = $self->{_p}->parse($string);
  
  require Grammar::Formal;
  my $g = Grammar::Formal->new;
  
  my @rules = map { _abnf2g($_, $g) } @$result;

  ###################################################################
  # Install all rules in the grammar
  ###################################################################
  for my $rule (@rules) {
    if ($g->rules->{$rule->name}) {
      my $old = $g->rules->{$rule->name};
      my $new = Grammar::Formal::Rule->new(
        name => $rule->name,
        p => $g->Choice($old->p, $rule->p),
      );
      $g->set_rule($rule->name, $new);
    } else {
      $g->set_rule($rule->name, $rule);
    }
  }
  
  ###################################################################
  # Add missing Core rules if requested
  ###################################################################
  if ($options{core}) {
    my %referenced;
    my @todo = values %{ $g->{rules} };
    while (my $c = pop @todo) {
      if ($c->isa('Grammar::Formal::Reference')) {
        $referenced{$c->ref}++;
      } elsif ($c->isa('Grammar::Formal::Unary')) {
        push @todo, $c->p;
      } elsif ($c->isa('Grammar::Formal::Binary')) {
        push @todo, $c->p1, $c->p2;
      }
    }
    
    my @core_rules = map { _abnf2g($_, $g) } @$CoreRules;

    for my $rule (@core_rules) {
      next if $g->rules->{$rule->name};
      next unless $referenced{$rule->name};
      $g->set_rule($rule->name, $rule);
    }
  }
  
  return $g;
}

sub _abnf2g {
  my ($p, $g, %options) = @_;
  for ($p->{class}) {
    if ($_ eq "Group") {
      my @values = map { _abnf2g($_, $g, %options) } @{ $p->{value} };
      my $group = $g->Empty;
      while (@values) {
        $group = $g->Group(pop(@values), $group);
      }
      return $group;
    }
    elsif ($_ eq "Choice") {
      my @values = map { _abnf2g($_, $g, %options) } @{ $p->{value} };
      my $choice = $g->NotAllowed;
      while (@values) {
        $choice = $g->Choice(pop(@values), $choice);
      }
      return $choice;
    }
    elsif ($_ eq "Repetition") {
      if (defined $p->{max}) {
        return Grammar::Formal::BoundRepetition->new(
          min => $p->{min},
          max => $p->{max},
          p => _abnf2g($p->{value}, $g, %options),
        );
      } else {
        return Grammar::Formal::SomeOrMore->new(
          min => $p->{min},
          p => _abnf2g($p->{value}, $g, %options),
        );
      }
    }
    elsif ($_ eq "Rule") {
      return Grammar::Formal::Rule->new(
        name => $p->{name},
        p => _abnf2g($p->{value}, $g, %options),
      );
    }
    elsif ($_ eq "Reference") {
      return Grammar::Formal::Reference->new(
        ref => $p->{name},
      );
    }
    elsif ($_ eq "Literal") {
      return Grammar::Formal::AsciiInsensitiveString->new(
        value => $p->{value},
      );
    }
    elsif ($_ eq "ProseValue") {
      return Grammar::Formal::ProseValue->new(
        value => $p->{value},
      );
    }
    elsif ($_ eq "String") {
      my @items;
      for ($p->{type}) {
        if ($_ eq "decimal") {
          @items = map { $_ } @{ $p->{value} };
        }
        elsif ($_ eq "hex") {
          @items = map { hex $_ } @{ $p->{value} };
        }
        else {
          ...
        }
      }
      my @values = map {
        Grammar::Formal::Range->new(
          min => $_,
          max => $_,
        )
      } @items;
      
      my $group = $g->Empty;
      while (@values) {
        $group = $g->Group(pop(@values), $group);
      }

      return $group;
    }
    elsif ($_ eq "Range") {
      return Grammar::Formal::Range->new(
        min => hex $p->{min},
        max => hex $p->{max},
      ) if $p->{type} eq 'hex';
      die;
    }
    else {
      ...
    }
  }
}

1;

__END__

=head1 NAME

Parse::ABNF - Parse IETF Augmented BNF (ABNF) grammars.

=head1 SYNOPSIS

  use Parse::ABNF;
  my $parser = Parse::ABNF->new;
  my $rules = $parser->parse($grammar);
  my $core = $Parse::ABNF::CoreRules;

=head1 DESCRIPTION

This module parses IETF ABNF (STD 68, RFC 5234, 4234, 2234) grammars into
a Perl data structure, a list of rules as specified below. It does not
generate a parser for the language described by some ABNF grammar, but
makes it easier to turn an ABNF grammar into a grammar suitable for use
with a parser generator that does not natively support ABNF grammars.

Artifacts are mapped into hash references as follows:

  A  = B ~ { class => 'Rule',       value => B, name => A               }
  A /= B ~ { class => 'Rule',       value => B, ... combine => 'choice' }
  A / B  ~ { class => 'Choice',     value => [A, B]                     }
  A B    ~ { class => 'Group',      value => [A, B]                     }
  A      ~ { class => 'Reference',  name  => A                          }
  n*mA   ~ { class => 'Repetition', value => A, min  => n, max => m     }
  [ A ]  ~ { class => 'Repetition', value => A, min  => 0, max => 1     }
  *A     ~ { class => 'Repetition', value => A, min  => 0, max => undef }
  "A"    ~ { class => 'Literal',    value => A                          }
  <A>    ~ { class => 'ProseValue', value => A                          }
  %xA.B  ~ { class => 'String',     value => [A, B], type => 'hex'      }
  %bA.B  ~ { class => 'String',     value => [A, B], type => 'binary'   }
  %dA.B  ~ { class => 'String',     value => [A, B], type => 'decimal'  }
  %xA-B  ~ { class => 'Range',      type  => 'hex', min => A, max => B  }

Forms not listed here are mapped in an analogous manner.

As an example, the ABNF grammar

  A = (B C) / *D

is parsed into

  [ {
    'value' => {
      'value' => [
        {
          'value' => [
            {
              'name' => 'B',
              'class' => 'Reference'
            },
            {
              'name' => 'C',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'min' => 0,
          'value' => {
            'name' => 'D',
            'class' => 'Reference'
          },
          'max' => undef,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'A',
    'class' => 'Rule'
  } ]

Until this module matures, this format is subject to change. Contact the
author if you would like to depend on this module.

=head1 METHODS

=over

=item new

Creates a new C<Parse::ABNF> object.

=item parse($string)

Parses a string into a structure as described above.

=item parse_to_grammar_formal($string, %options)

When the L<Grammar::Formal> module is available, this function will parse
C<$string> into a new Grammar::Formal object. To obtain the ABNF Core rules
apply it to the string C<$Parse::ABNF::CoreRulesGrammar>. Alternatively,
pass C<core> as option and the method will do it for you.

=back

=head1 ERROR HANDLING

The C<parse> method will retun C<undef> if there is an error in the grammar
and C<Parse::RecDescent> will automatically print an error message. Future
versions might throw an exception instead.

=head1 CORE RULES

The ABNF specification defines some Core Rules that are used without
defining them locally in many ABNF grammars. You can access these rules
as parsed by this module via C<$Parse::ABNF::CoreRules>.

=head1 CAVEATS

Instead of CRLF line endings this module expects "\n" as line terminator.
If necessary, convert the line endings e.g. using

  $grammar =~ s/\x0d\x0a/\n/g;

The ABNF specification disallows white space preceding the left hand side,
and so does this module. Remove it prior to passing the grammar e.g. using

  $grammar =~ s/^\s+(?=[\w-]+\s*=)//mg;

This module does not do that for you in order to preserve line and column
numbers. Patches adapting the grammar to allow leading white space welcome.

The ABNF specification allows non-terminals to be enclosed inside <...>.
That is the same syntax as used for prose values, and this module makes no
attempt to differentiate the two.

Comments are not currently made available, this may change in future versions.

=head1 BUG REPORTS

Please report bugs in this module via
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parser-ABNF>

=head1 SEE ALSO

  * http://www.ietf.org/rfc/rfc5234.txt
  * Parse::RecDescent

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2008-2009 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
