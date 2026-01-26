use Test2::V0;
use HTML::Entities ();  # to get consistent behavior from internal encode_entities()
use Pod::Markdown::Githubert ();

{
    my $parser = Pod::Markdown::Githubert->new(hl_language => 'floop');
    $parser->output_string(\my $markdown);
    $parser->parse_string_document(<<'_EOT_');
=pod

A

 one

B

 two

=for highlighter language=

C

 three

D

 four
_EOT_

    is $markdown, <<'_EOT_', "setting default syntax with hl_language works";
A

```floop
one
```

B

```floop
two
```

C

```
three
```

D

```
four
```
_EOT_
}

local $/ = "-----\n";
while (my $spec = readline DATA) {
    chomp $spec;
    my ($pod, $expected) = split /\n>>>>>\n/, $spec, 2;
    my $name =
        $pod =~ s/\A# ([^\n]+)\n//
            ? $1
            : "DATA test $.";

    local $/ = "\n";

    my $parser = Pod::Markdown::Githubert->new;
    $parser->output_string(\my $markdown);
    $parser->parse_string_document($pod);

    is $markdown, $expected, $name;
}

done_testing;
__DATA__
# code blocks containing backticks
=head1 SYNOPSIS

      abc
       def
     ```
        ````

Nice.
>>>>>
# SYNOPSIS

`````
 abc
  def
```
   ````
`````

Nice.
-----
# syntax highlighting
=for highlighter language=perl

    my $dog = "spot";

... other stuff ...

    my $car = "cdr";

=for highlighter html

    <p>Hello!</p>
>>>>>
```perl
my $dog = "spot";
```

... other stuff ...

```perl
my $car = "cdr";
```

```html
<p>Hello!</p>
```
-----
# list items starting with code blocks
=over

=item 1.

    uh-oh

=back
>>>>>
1. <!-- -->

    ```
    uh-oh
    ```
-----
# github oddities with $ and _
=over

=item $$

=item the I<N>th

=back
>>>>>
- &#36;&#36;
- the *N*th
