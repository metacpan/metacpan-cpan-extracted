package Parse::BBCode::SCEditor;
BEGIN {
  $Parse::BBCode::SCEditor::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Parse::BBCode::HTML specific for SCEditor
$Parse::BBCode::SCEditor::VERSION = '0.001';
use strict;
use warnings;
use Carp qw(croak carp);
use base qw/ Parse::BBCode /;
use Parse::BBCode::HTML;

my %default_tags = (
  Parse::BBCode::HTML->defaults(),
  's' => '<strike>%s</strike>',
  'sub' => '<sub>%s</sub>',
  'sup' => '<sup>%s</sup>',
  'font' => '<font face="%a">%s</font>',
  'size' => '<font size="%a">%s</font>',
  'color' => '<font color="%{htmlcolor}a">%s</font>',
  'center' => '<p style="text-align:center;">%s</p>',
  'right' => '<p style="text-align:right;">%s</p>',
  'justify' => '<p style="text-align:justify;">%s</p>',
  'ul' => '<ul>%s</ul>',
  'ol' => '<ol>%s</ol>',
  'li' => '<li>%s</li>',
  'table' => {
    code => sub {
      my ($parser, $attr, $content, $attribute_fallback) = @_;
      $$content =~ s{\r?\n|\r}{}g;
      return "<table><tbody>$$content</tbody></table>";
    },
    parse => 1,
    class => 'block',
  },
  'tr' => '<tr>%s</tr>',
  'td' => '<td>%s</td>',
  'hr' => {
    class => 'block',
    output => '<hr>',
    single => 1,
  },
  'code' => {
    code => sub {
      my ($parser, $attr, $content, $attribute_fallback) = @_;
      $content = Parse::BBCode::escape_html($$content);
      $content =~ s{\r?\n|\r}{<br>\n}g;
      return "<code>$content</code>";
    },
    parse => 0,
    class => 'block',
  },
  'quote' => '<blockquote>%s</blockquote>',
  '' => sub {
    my ($parser, $tag, $content, $info) = @_;
    my $text = Parse::BBCode::escape_html($content);
    my $in = $info->{stack}->[-1];
    if ($in eq 'table' || $in eq 'tr' || $in eq 'ol' || $in eq 'ul') {
      # explicit not adding the <br>
    } else {
      $text =~ s{\r?\n|\r}{<br>\n}g;
    }
    $text;
  },
);

my %optional_tags = (
  Parse::BBCode::HTML->optional(),
);

my %default_escapes = (
  Parse::BBCode::HTML->default_escapes,
);
 
sub defaults {
  my ($class, @keys) = @_;
  return @keys
    ? (map { $_ => $default_tags{$_} } grep { defined $default_tags{$_} } @keys)
    : %default_tags;
}
 
sub default_escapes {
  my ($class, @keys) = @_;
  return @keys
    ? (map { $_ => $default_escapes{$_} } grep  { defined $default_escapes{$_} } @keys)
    : %default_escapes;
}
 
sub optional {
  my ($class, @keys) = @_;
  return @keys ? (grep defined, @optional_tags{@keys}) : %optional_tags;
}

1;

__END__

=pod

=head1 NAME

Parse::BBCode::SCEditor - Parse::BBCode::HTML specific for SCEditor

=head1 VERSION

version 0.001

=head1 DESCRIPTION

=head1 SUPPORT

IRC

  Join #hardware on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  https://github.com/Getty/p5-parse-bbcode-sceditor
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/Getty/p5-parse-bbcode-sceditor/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
