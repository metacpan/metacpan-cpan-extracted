package Object::Singleton;
use Pony::Object singleton => qw/Object::FirstPonyClass
                                 Object::SecondPonyClass/;

    has f => 'f';
    has h => 'h';

1;

