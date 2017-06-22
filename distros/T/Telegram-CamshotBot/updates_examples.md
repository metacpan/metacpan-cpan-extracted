Examples of Updates


## Single user


```perl
my $a = {
          'message' => {
                         'chat' => {
                                   'username' => 'Vadyan161',
                                   'last_name' => 'Gorbatenko',
                                   'id' => 146696695,
                                   'first_name' => 'Vadim',
                                   'type' => 'private'
                                 },
                         'text' => '/shot',
                         'message_id' => 5122,
                         'date' => 1485680368,
                         'entities' => [
                                       {
                                         'offset' => 0,
                                         'length' => 5,
                                         'type' => 'bot_command'
                                       }
                                     ],
                         'from' => {
                                   'first_name' => 'Vadim',
                                   'id' => 146696695,
                                   'last_name' => 'Gorbatenko',
                                   'username' => 'Vadyan161'
                                 }
                       },
          'update_id' => 346938337
        };
```

## Group chat


```perl
my $b = {
          'update_id' => 346938339,
          'message' => {
                       'message_id' => 1337,
                       'from' => {
                                 'username' => 'serikoff',
                                 'last_name' => 'Serikov',
                                 'first_name' => 'Pavel',
                                 'id' => 218718957
                               },
                       'date' => 1485686547,
                       'chat' => {
                                 'type' => 'supergroup',
                                 'title' => "\x{424}\x{430}\x{431}\x{421}\x{435}\x{43a}\x{442}\x{430}",
                                 'id' => '-1001078197767'
                               },
                       'entities' => [
                                     {
                                       'offset' => 0,
                                       'length' => 17,
                                       'type' => 'bot_command'
                                     }
                                   ],
                       'text' => '/shot@camshot_bot'
                     }
        };
```