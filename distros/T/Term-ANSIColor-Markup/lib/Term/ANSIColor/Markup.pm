package Term::ANSIColor::Markup;
use 5.008_001;
use strict;
use warnings;
use Term::ANSIColor::Markup::Parser;
use base qw(Class::Accessor::Lvalue::Fast);

our $VERSION = '0.06';

__PACKAGE__->mk_accessors(qw(parser text));

sub new {
    my $class  = shift;
    bless {
        parser => Term::ANSIColor::Markup::Parser->new,
        text   => '',
    }, $class;
}

sub parse {
    my ($self, $text) = @_;
    $self->parser->parse($text);
    $self->parser->eof;
    $self->text = $self->parser->text;
}

sub colorize {
    my ($class, $text) = @_;
    my $self = $class->new;
       $self->parse($text);
       $self->text;
}

1;

__END__

=head1 NAME

Term::ANSIColor::Markup - Colorize tagged strings for screen output

=head1 SYNOPSIS

  use Term::ANSIColor::Markup;

  my $text = qq{aaa<red>bbb<bold>ccc</bold>ddd<black><on_yellow>eee</on_yellow></black>fff</red> &gt; ggg};

  my $parser = Term::ANSIColor::Markup->new;
  $parser->parse($text);
  print $parser->text;

  # or just call colorize method this way:

  print Term::ANSIColor::Markup->colorize($text);

=head1 DESCRIPTION

Term::ANSIColor::Markup provides a simple and friendly way to colorize
screen output; You can do it using HTML-like tags.

You can use the same names for tag names as ones L<Term::ANSIColor>
provides. See the documentation of Term::ANSIColor to get to know what
names you can use.

=head1 METHODS

=head2 new ()

=over 4

  my $parser = Term::ANSIColor::Markup->new;

Creates and returns a new Term::ANSIColor::Markup object.

=back

=head2 parse ( I<$text> )

=over 4

  $parser->parse($text);

Parses given C<$text>. If start tag and end tag aren't correspondent
with each other, this method croaks immediately.

Note that "<" and ">" which are not part of tags must be escaped into
"&lt;" and "&gt;".

=back

=head2 text ()

=over 4

  print $parser->text;

Returns parsed text.

=back

=head2 colorize ($text)

=over 4

  print Term::ANSIColor::Markup->colorize($text);

Returns parsed text in just one way.

=back

=head1 REPOSITORY

https://github.com/kentaro/perl-term-ansicolor-markup/tree

=head1 SEE ALSO

=over 4

=item * TermColor

The idea, converts tagged string to colorized one for term, was
borrowed from http://github.com/jugyo/termcolor/tree/master

=item * Term::ANSIColor

You might want to consult the documentation of Term::ANSIColor to get
to know what tags you can use.

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=head1 SEE ALSO

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
