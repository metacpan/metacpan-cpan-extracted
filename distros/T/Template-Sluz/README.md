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

## Author

Scott Baker - https://www.perturb.org/

## See Also

[https://github.com/scottchiefbaker/sluz](https://github.com/scottchiefbaker/sluz)

## License

GPL-3.0-or-later
