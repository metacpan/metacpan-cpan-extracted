[![Release](https://img.shields.io/github/release/giterlizzi/perl-Mojolicious-Plugin-HTMX.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX/releases) [![Actions Status](https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-Mojolicious-Plugin-HTMX.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-Mojolicious-Plugin-HTMX.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-Mojolicious-Plugin-HTMX.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-Mojolicious-Plugin-HTMX.svg)](https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-Mojolicious-Plugin-HTMX/badge.svg)](https://coveralls.io/github/giterlizzi/perl-Mojolicious-Plugin-HTMX)

# Mojolicious::Plugin::HTMX - </> htmx plugin for Mojolicious

## Usage

```.pl
# Mojolicious
$self->plugin('HTMX');

# Mojolicious::Lite
plugin 'HTMX';

get '/trigger' => 'trigger';
post '/trigger' => sub ($c) {

    state $count = 0;
    $count++;

    $c->htmx->res->trigger(showMessage => 'Here Is A Message');
    $c->render(text => "Triggered $count times");

};
```

```.html
@@ template.html.ep
<html>
<head>
    %= app->htmx->asset
</head>
<body>
    <h1>Mojolicious::Plugin::HTMX<h1>
    <main>
        %= content
    </main>
</body>
</html>

@@ trigger.html.ep
% layout 'default';
<h1>Trigger</h1>

<button hx-post="/trigger">Click Me</button>

<script>
document.body.addEventListener("showMessage", function(e){
    alert(e.detail.value);
});
</script>
```

## Installation

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

Using App::cpanminus:

    cpanm Mojolicious::Plugin::HTMX


## Documentation

 - `perldoc Mojolicious::Plugin::HTMX`
 - https://metacpan.org/release/Mojolicious-Plugin-HTMX

## Copyright

Copyright (C) 2022-2023 by Giuseppe Di Terlizzi
