# Template::Swig

Perl interface to Django-inspired Swig templating engine.

### Synopsis

```perl
my $swig = Template::Swig->new;

# Compile and render an inline template:
$swig->compile('message', 'Welcome, {{name}}');
my $output = $swig->render('message', { name => 'Arthur' });

# Compile and render a file:
$swig->compileFromFile('path/to/file.html');
my $output = $swig->render('path/to/file.html', { some_param => 'foo' });
```

### Description

Template::Swig uses [JavaScript::V8](http://search.cpan.org/perldoc?JavaScript::V8) and [Paul Armstrong's Swig](https://github.com/paularmstrong/swig/) templating engine to provide fast Django-inspired templating in a Perl context.  Templates are compiled to JavaScript functions and stored in memory, then executed each time they're rendered.

Swig's feature list includes multiple inheritance, formatter and helper functions, macros, auto-escaping, and custom tags.  See the [Swig Documentation](https://github.com/paularmstrong/swig/blob/master/docs/README.md) for more.

### Methods

#### new( template_dir => $path, extends_callback => sub { } )

Initialize a swig instance, given the follwing parameters:

> ###### template_dir
>
> Optional path where templates live
>
> ###### extends_callback
>
> Optional callback to be run when Swig encounters an `extends` tag; receives filename and its encoding as parameters

#### compile($template\_name, $swig\_source)

Compile a template given, given a template name and swig template source as a string.

#### render($template\_name, $data)

Render a template, given a name and a reference to a hash of data to interpolate.

### Template Examples

Iterate through a list:

```html
{% for image in images %}
    <img src="{{ image.src }}" width="{{ image.width }}" height="{{ image.height }}">
{% else %}
    <div class="message">No images to show</div>
{% endfor %}
```

Custom helpers / filters:

```html
{{ created|date('r') }}
```

#### Inheritance

In main.html:

```
{% block greeting %}
    Hi, there.
{% endblock %}
```
In custom.html: 

```
{% extends 'main.html' %}
    
{% block greeting %}
    Welcome, {{ name }}
{% endblock %}
```

### See Also

[Dotiac::DTL](http://search.cpan.org/perldoc?Dotiac::DTL), [Text::Caml](http://search.cpan.org/perldoc?Text::Caml), [Template::Toolkit](http://search.cpan.org/perldoc?Template::Toolkit)

### Copyright and License

Copyright (c) 2012, David Chester

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

