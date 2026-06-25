## Name

Template::Sluz - A minimalistic Perl templating engine with Smarty-like syntax

## Synopsis

File: `main.pl`

```perl
use Template::Sluz;

my $s = Template::Sluz->new();

$s->assign('name', 'Scott');
$s->assign('array' => ['one', 'two', 'three']);
$s->assign('hash'  => { color => 'red', age => 39});

print $s->fetch('template.stpl');
```

File: `template.stpl`

```
Hello {$name}
Nums: {foreach $array as $x}{$x} {/foreach}
Info: {$hash.color} / {$hash.age}
```

Output:

```
Hello Scott
Nums: one two three
Info: red / 39
```

## Methods

- **new**

    Create a new Template::Sluz instance.

    ```perl
    my $sluz = Template::Sluz->new();
    ```

    Options (all are optional):

    ```perl
    my $sluz = Template::Sluz->new(
        auto_escape => 1,   # auto HTML-escape all variable output
        debug       => 1,   # enable debug mode (currently unused)
    );
    ```

- **assign**

    Assign template variables.

    ```perl
    $s->assign('name', 'Scott');
    $s->assign('array' => ['one', 'two', 'three']);
    $s->assign('hash'  => { color => 'red', age => 39});
    $s->assign('nums'  => $array_ref);
    $s->assign('data'  => $hash_ref);
    ```

- **fetch**

    Process a template file and return the output.

    ```
    $s->fetch('tpls/page.stpl');
    ```

- **parse\_string**

    Process a template string directly without a file.

    ```
    $s->parse_string('Hello {$name}');
    ```

- **set\_delimiters**

    Change the template delimiters from the default `{` and `}` to a custom
    open and close character.  Both arguments are required and must be exactly
    one character each.  The two characters must be different.

    ```
    $s->set_delimiters('<', '>');
    print $s->parse_string('Hello <$name>');
    ```

    This is useful when template content contains curly braces (e.g., inline
    CSS, JavaScript, or JSON) that would otherwise conflict with the default
    template syntax.  All subsequent calls to `fetch`, `parse_string`, etc.
    will use the new delimiters.

## Template Syntax

### Variables

```
{$name}
{$user.first_name}
{$items.0}
```

### Modifiers

```
{$name|uc}
{$name|substr:0,3}
{$name|lc|ucfirst}
{$name|escape}
```

### Default Values

```
{$name|default:'Unknown'}
```

### Conditionals

```
{if $age > 18}
    Adult
{elseif $age > 12}
    Teen
{else}
    Child
{/if}
```

### Loops

```
{foreach $items as $item}
    {$item}
{/foreach}
```

### Includes

```
{include file='header.stpl'}
{include file='header.stpl' title='Home'}
```

### Literal Blocks

```
{literal}function foo() { .. } {/literal}
```

### Comments

```
{* This is a comment *}
```

### Alternate Delimiters

By default the template engine uses `{` and `}` as delimiters.  You can
change them to any single open and close character using `set_delimiters`:

```
$s->set_delimiters('<', '>');

print $s->parse_string('Hello <$name>');
```

All template syntax works the same way with alternate delimiters:

```
<if $age > 18>
    Adult
<else>
    Not adult
</if>

{foreach $items as $item}
    <$item>
{/foreach}
```

This is useful when your template content contains curly braces that would
conflict with the default delimiters.

## Functions as Modifiers

Any Perl built-in or user-defined function can be used as a template
modifier:

```
{$name|ucfirst}
{$items|join:' - '}
{$text|substr:0,10}
```

When a function is called as a modifier the template variable is passed first
and then it is followed by the params.

Example: `{$text|substr:0,10}` would map to the call `substr($text, 0, 10)`

## Security

Template variables hold untrusted data (form input, database rows, URL
parameters) by default.  The `{$var}` construct emits the value verbatim,
so a template that renders user data without escaping is vulnerable to
cross-site scripting (XSS).

### Escape Modifier

Use the `|escape` modifier on any variable that may contain
user-supplied data:

```
{$comment|escape}
```

The `escape` modifier encodes `&`, `<`, `>`, `"`, and `'`
to their HTML entity equivalents.  It can be chained with other modifiers:

```
{$comment|trim|escape}
{$name|uc|escape}
```

### Auto-Escape Mode

Enable automatic HTML escaping for all variable output by setting the
`auto_escape` option on construction:

```perl
my $sluz = Template::Sluz->new(auto_escape => 1);
```

When enabled, every `{$var}` expression is automatically HTML-escaped.
Use `|noescape` to emit raw HTML for a specific variable:

```
{$trusted_html|noescape}
```

Explicit `|escape` takes priority and prevents double-escaping.
Auto-escape is off by default for backward compatibility.

### Built-In Escape Functions

- **escape**

    HTML-escape a string for safe output in an HTML context.  Encodes:

    ```perl
    &  => &amp;
    <  => &lt;
    >  => &gt;
    "  => &quot;
    '  => &#x27;
    ```

- **noescape**

    Identity passthrough. Bypasses auto-escaping when `auto_escape` is
    enabled. Does nothing otherwise.

## Author

Scott Baker - https://www.perturb.org/

## See Also

[https://github.com/scottchiefbaker/sluz](https://github.com/scottchiefbaker/sluz)

## License

GPL-3.0-or-later
