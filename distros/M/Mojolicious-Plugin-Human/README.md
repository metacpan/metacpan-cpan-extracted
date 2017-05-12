#Mojolicious::Plugin::Human

Helpers to print values as human readable form.
You can use this module in Mojo template engine to make you users happy.

```perl
# Enable and configure
$self->plugin('Human', {

        # Set money parameters if you need
        money_delim => ",",
        money_digit => " ",

        # Or change date and time strings
        datetime    => '%d.%m.%Y %H:%M',
        time        => '%H:%M:%S',
        date        => '%d.%m.%Y',
    });
```

```
  %# ... Somewhere in templates ...

  <%= human_datetime $date_from_db %>
  ...
  <%= human_money $money %>
```

#Date and time helpers

 * str2time - Get string, return timestamp
 * strftime - Get string, return formatted string
 * human_datetime - Get string, return date and time string in human readable form.
 * human_time - Get string, return time string in human readable form.
 * human_date - Get string, return date string in human readable form.

#Money helpers

 * human_money - Get number, return money string in human readable form with levels.

# Phone helpers

 * human_phones - Get srtring, return phones (if many) string in human readable form.
 * yandex_phone - Get srtring, return just numbers phone string without country code.

#Text helpers

 * human_suffix $str, $count, $one, $two, $many - Get word base form and add some of suffix ($one, $two, $many) depends of $count
