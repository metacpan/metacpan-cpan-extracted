package Blah;
use Mojo::Base 'Mojolicious';

sub startup { shift->plugin(Tables => { connect_info=>["dbi:SQLite:$ENV{EXAMPLEDB}", '', ''] }) }

1;
