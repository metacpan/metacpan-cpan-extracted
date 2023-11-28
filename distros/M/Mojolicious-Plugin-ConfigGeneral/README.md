[//]: # ( README.md Fri 27 Oct 2023 16:44:50 MSK )

# Mojolicious::Plugin::ConfigGeneral

Mojolicious::Plugin::ConfigGeneral is a Config::General Configuration Plugin for Mojolicious

# RU

Выпуск плагина Mojolicious::Plugin::ConfigGeneral 1.01

В октябре 2023 состоялся релиз плагина [Mojolicious::Plugin::ConfigGeneral](https://metacpan.org/pod/Mojolicious::Plugin::ConfigGeneral) для [Mojolicious](https://metacpan.org/pod/Mojolicious). Плагин предоставляет доступ к конфигурации [Config::General](https://metacpan.org/pod/Config::General) из приложений Mojolicious, а также реализует методы получения данных конфигурации с помощью хелперов указателя, на базе модуля [Mojo::JSON::Pointer](https://metacpan.org/pod/Mojo::JSON::Pointer).

## Пример использования

Более обширное описание можно найти на странице проекта [Mojolicious::Plugin::ConfigGeneral](https://metacpan.org/pod/Mojolicious::Plugin::ConfigGeneral). Здесь привожу пример только из классического Mojolicious приложения

``` perl
sub startup {
    my $self = shift;

    # Plugins
    $self->plugin(ConfigGeneral => {file => '/etc/app/app.conf'});

    ...

    my $val = $self->conf->latest('/foo/bar/baz');

    ...
}
```

## Хелперы

К хелперам относятся:

### get

Этот хелпер возвращает значение или структуру по пути (указателю), например:

```perl
say $app->conf->get('/foo/bar/baz');
```

### first

Хелпер возвращает первое найденное значение по пути (указателю):

```perl
dumper $app->conf->first('/foo/bar/baz'); # ['first', 'second', 'third']
    # 'first'
```

### latest

Хелпер возвращает последнее найденное значение по пути (указателю):

```perl
dumper $app->conf->latest('/foo/bar/baz'); # ['first', 'second', 'third']
    # 'third'
```
### list

Хелпер возвращает значение в виде ссылки на массив значений (список)

```perl
dumper $app->conf->array('/foo/bar/baz'); # ['first', 'second', 'third']
    # ['first', 'second', 'third']
dumper $app->conf->array('/foo/bar/qux'); # 'value'
    # ['value']
```

У этого хелпера существует алиас - `array`

### object

Хелпер возвращает значение в виде ссылки на объект (хэш)

```perl
dumper $app->conf->array('/foo'); # { foo => 'first', bar => 'second' }
    # { foo => 'first', bar => 'second' }
```

У этого хелпера существует алиас - `hash`

