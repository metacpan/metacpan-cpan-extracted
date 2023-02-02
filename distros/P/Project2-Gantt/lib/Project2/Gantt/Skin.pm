package Project2::Gantt::Skin;

use Mojo::Base -base;
use Imager::Font;
use Alien::Font::Vera;

our $DATE = '2023-02-02'; # DATE
our $VERSION = '0.006';

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

#26ccbb green
#43acf2 blue
#fd9742 orange
#d63031 red
#a75eeb purple

1;
