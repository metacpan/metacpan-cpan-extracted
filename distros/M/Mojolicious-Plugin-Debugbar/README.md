# Mojolicious-Plugin-Debugbar
Debugbar plugin for Mojolicious

# Intialization

```perl
$self->plugin('Debugbar', {
    enabled     => 1,
    hide_empty  => 0,
    monitors    => [
        'Mojo::Debugbar::Monitor::Request',
        'Mojo::Debugbar::Monitor::DBIx',
        'Mojo::Debugbar::Monitor::Template',
        'Mojo::Debugbar::Monitor::ValidationTiny',
    ]
});
```
