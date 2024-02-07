package Project2::Gantt::Skin;

use Mojo::Base -base;
use Imager::Font;
use Alien::Font::Vera;

our $DATE = '2024-02-05'; # DATE
our $VERSION = '0.011';

has primaryText     => 'black';
has secondaryText	=> '#363636';
has primaryFill	    => '#c4dbed';
has secondaryFill   => '#e5e5e5';
has infoStroke      => 'black';
has doTitle         => 1;
has containerStroke	=> 'black';
has containerFill	=> 'grey';
has itemFill        => '2ab1aa';
has background      => 'white';
has font            => sub { Imager::Font->new(file => Alien::Font::Vera::path) };
has doSwimLanes     => 1;
has spanInfoWidth   => 205;
has titleSize       => 200;
has descriptionSize => 145;
has resourceStartX  => 145 + 2;
has resourceSize    => 55;

#26ccbb green
#43acf2 blue
#fd9742 orange
#d63031 red
#a75eeb purple

1;
