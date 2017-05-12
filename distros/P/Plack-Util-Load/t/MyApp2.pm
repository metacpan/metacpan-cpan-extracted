package MyApp2;
use parent 'Plack::Component';
sub call { [200,[],[__PACKAGE__.$_[1]->{PATH_INFO}]]; }
1;
