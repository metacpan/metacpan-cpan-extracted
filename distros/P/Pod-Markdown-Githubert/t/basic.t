use Test2::V0;
use Pod::Markdown::Githubert ();

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
