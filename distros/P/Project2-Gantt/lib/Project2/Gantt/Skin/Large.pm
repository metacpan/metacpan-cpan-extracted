package Project2::Gantt::Skin::Large;

use Mojo::Base 'Project2::Gantt::Skin';

our $DATE = '2023-02-16'; # DATE
our $VERSION = '0.009';

has spanInfoWidth   => 205 + 200;
has titleSize       => 200 + 200;
has descriptionSize => 145 + 200;
has resourceStartX  => 145 + 2 + 120;
has resourceSize    => 55 + 100;

1;
