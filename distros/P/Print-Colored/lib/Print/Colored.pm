package Print::Colored;
use strict;
use warnings;
use utf8;
use v5.24.0;

use Exporter 'import';
use IO::Prompter;
use Term::ANSIColor qw|colored coloralias|;

our $VERSION = '0.01';

our @EXPORT      = ();
our @EXPORT_OK   = ();
our %EXPORT_TAGS = ();

coloralias('error', 'bright_red');
coloralias('info',  'bright_blue');
coloralias('input', 'bright_cyan');
coloralias('ok',    'bright_green');
coloralias('warn',  'bright_magenta');

# functions

{
  no strict 'refs';    ## no critic
  for my $context (qw|error info input ok warn|) {

    # color
    my $fn = "color_$context";
    push $EXPORT_TAGS{color}->@*, $fn;

    *{__PACKAGE__ . "::$fn"} = sub { return colored [$context], @_ };

    # print
    $fn = "print_$context";
    push $EXPORT_TAGS{print}->@*, $fn;

    *{__PACKAGE__ . "::$fn"} = sub { print colored [$context], @_ };

    # prompt
    $fn = "prompt_$context";
    push $EXPORT_TAGS{prompt}->@*, $fn;

    *{__PACKAGE__ . "::$fn"} = sub {
      my $style = coloralias($context) =~ s/bright_/bold /r;
      return prompt shift, -v, -style => $style, -echostyle => $style, @_;
    };

    # say
    $fn = "say_$context";
    push $EXPORT_TAGS{say}->@*, $fn;

    *{__PACKAGE__ . "::$fn"} = sub { say colored [$context], @_ };
  }

  $EXPORT_TAGS{all}->@* = @EXPORT_OK = map { $EXPORT_TAGS{$_}->@* } qw|color print prompt say|;
}

1;

=encoding utf8

=head1 NAME

Print::Colored - print, say, prompt with predefined colors

=head1 SYNOPSIS

    use Print::Colored;
    use Print::Colored ':all';

    # color
    use Print::Colored ':color';

    $colored_text = color_error $text;    # bright red
    $colored_text = color_info $text;     # bright blue
    $colored_text = color_input $text;    # bright cyan
    $colored_text = color_ok $text;       # bright green
    $colored_text = color_warn $text;     # bright magenta

    # print
    use Print::Colored ':print';

    print_error $text;
    print_info $text;
    print_input $text;
    print_ok $text;
    print_warn $text;

    # prompt
    use Print::Colored ':prompt';

    $input = prompt_error $text, @params;
    $input = prompt_info $text, @params;
    $input = prompt_input $text, @params;
    $input = prompt_ok $text, @params;
    $input = prompt_warn $text, @params;

    # say
    use Print::Colored ':say';

    say_error $text;
    say_info $text;
    say_input $text;
    say_ok $text;
    say_warn $text;

=head1 DESCRIPTION

L<Print::Colored> provides functions to print, say, prompt with predefined colors.

=over

=item C<error> bright red

=item C<info> bright blue

=item C<input> bright cyan

=item C<ok> bright green

=item C<warn> bright magenta

=back

We should use colors all the time we write sripts that run in the terminal.
Read L<Use terminal colors to distinguish information|https://www.perl.com/article/use-terminal-colors-to-distinguish-information/>
by L<brian d foy|https://metacpan.org/author/BDFOY> to get some more ideas about it.

But experience shows that the more commands and constants we have to use the less colors our
scripts have. This was the reason to build this rather simple module.

=head2 Limitations

Because the colors are predefined, there isn't much to configure. If you don't like them (and quite
sure you don't) and until we come up with a better solution, you can use L<Term::ANSIColor/coloralias>
to modify them.

    use Term::ANSIColor 'coloralias';

    coloralias('error', 'yellow');          # default: bright_red
    coloralias('info',  'white');           # default: bright_blue
    coloralias('input', 'bright_white');    # default: bright_cyan
    coloralias('ok',    'black');           # default: bright_green
    coloralias('warn',  'red');             # default: bright_blue

All the commands except L</color_> write directly to C<STDOUT>.

    print_ok $filehandle 'Everything okay.';    # ✗ no
    say_ok $filehandle 'Everything okay.';      # ✗ no

You can't L</print_> and L</say_> to filehandles.

    print $filehandle color_ok 'Everything okay.';    # ✓
    say $filehandle color_ok 'Everything okay.';      # ✓

Instead you have to use one of the L</color_> functions.

=head1 color_

    use Print::Colored ':color';

Imports the functions L</color_error>, L</color_info>, L</color_input>, L</color_ok>, and L</color_warn>.

=head2 color_error

    $colored_text = color_error 'There was an error';

Returns a text colored as C<error>.

=head2 color_info

    $colored_text = color_info 'This is an info';

Returns a text colored as C<info>.

=head2 color_input

    $colored_text = color_input 'Waiting for an input...';

Returns a text colored as C<input>.

=head2 color_ok

    $colored_text = color_ok 'Everything okay';

Returns a text colored as C<ok>.

=head2 color_warn

    $colored_text = color_warn 'Last warning';

Returns a text colored as C<warn>.

=head1 print_

    use Print::Colored ':print';

Imports the functions L</print_error>, L</print_info>, L</print_input>, L</print_ok>, and L</print_warn>.

=head2 print_error

    print_error 'There was an error';

Prints a text colored as C<error>.

=head2 print_info

    print_info 'This is an info';

Prints a text colored as C<info>.

=head2 print_input

    print_input 'Waiting for an input...';

Prints a text colored as C<input>.

=head2 print_ok

    print_ok 'Everything okay';

Prints a text colored as C<ok>.

=head2 print_warn

    print_warn 'Last warning';

Prints a text colored as C<warn>.

=head1 prompt_

    use Print::Colored ':prompt';

Imports the functions L</prompt_error>, L</prompt_info>, L</prompt_input>, L</prompt_ok>, and L</prompt_warn>.
Internally they call L<IO::Prompter/prompt>.

=head2 prompt_error

    $input = prompt_error 'Enter your data: ';

Prompts colored as C<error> and returns the input.

=head2 prompt_info

    $input = prompt_info 'Enter your data: ';

Prompts colored as C<info> and returns the input.

=head2 prompt_input

    $input = prompt_input 'Enter your data: ';

Prompts colored as C<input> and returns the input.

=head2 prompt_ok

    $input = prompt_ok 'Enter your data: ';

Prompts colored as C<ok> and returns the input.

=head2 prompt_warn

    $input = prompt_warn 'Enter your data: ';

Prompts colored as C<warn> and returns the input.

=head1 say_

    use Print::Colored ':say';

Imports the functions L</say_error>, L</say_info>, L</say_input>, L</say_ok>, and L</say_warn>.

=head2 say_error

    say_error 'There was an error';

Prints a text with appended newline colored as C<error>.

=head2 say_info

    say_info 'This is an info';

Prints a text with appended newline colored as C<info>.

=head2 say_input

    say_input 'Waiting for an input...';

Prints a text with appended newline colored as C<input>.

=head2 say_ok

    say_ok 'Everything okay';

Prints a text with appended newline colored as C<ok>.

=head2 say_warn

    say_warn 'Last warning';

Prints a text with appended newline colored as C<warn>.

=head1 AUTHOR & COPYRIGHT

© 2019 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<IO::Prompter>, L<Term::ANSIColor>.

=cut
