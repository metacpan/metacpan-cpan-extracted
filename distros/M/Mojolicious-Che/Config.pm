
=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Che

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Config.pm - Пример конфига для Mojolicious::Che приложения

=head1 DESCRIPTION

See raw this module content.

=cut


{
  'Проект'=>'Тест-проект',
  # mojo => {
    # mode=>...,
    # log_level => ...,
    # secrets => ...,
    # plugins=> ...,
    # session => ...,
    # hooks => ...,
    # has => ...,
  # },
  mojo_mode=> 'development',
  mojo_log=>{level => 'debug'},
  # plugins
  'плугины'=>[ 
      #~ [charset => { charset => 'UTF-8' }, ],
      #~ ['HeaderCondition'],
      #~ ['ParamsArray'],
  ],
  #mojo_session
  'сессия'=> {cookie_name => 'ELK'},
  #mojo_secret
  'шифры' => ['true 123 my app',],
  # hooks
  'хуки'=>{
    #~ before_dispatch => sub {1;},
  },
  # has
  'хазы' => {
    foo => sub {my $app = shift; return 'bar!';},
  },
  # dbh
  'базы000'=>{# will be as has dbh!
    'main' => {
      # DBI->connect(dsn, user, passwd, $attrs)
      connect => ["DBI:Pg:dbname=test;", "guest", undef, {
        ShowErrorStatement => 1,
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 1, 
        pg_enable_utf8 => 1,
        #mysql_enable_utf8 => 1,
        #mysql_auto_reconnect=>1,
      }],
      # will do on connect
      do => ['set datestyle to "ISO, DMY";',],
      # prepared sth will get $app->sth->{<dbh name>}{<sth name>}
      sth => {
        foo => <<SQL,
select * 
from foo
where
  bar = ?;
SQL
      },
    }
  },
  # sth 
  # prepared sth will get $app->sth->{<dbh name>}{<sth name>}
  'запросы' => {
    main => {
      now => "select now();"
    },
  },
  # ns | namespaces
  'спейсы'=>[],
  # routes
  'маршруты' => [
    [get=>'/', to=> {cb=>sub{shift->render(format=>'txt', text=>'Здорова!');},}],
  ]
};
