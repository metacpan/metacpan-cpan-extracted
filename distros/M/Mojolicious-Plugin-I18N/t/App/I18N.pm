package App::I18N;
use base 'Locale::Maketext';

package App::I18N::ru;
use Mojo::Base 'App::I18N';
use utf8;

our %Lexicon = (hello => 'Привет', hello2 => 'Привет два');

package App::I18N::en;
use Mojo::Base 'App::I18N';

our %Lexicon = (_AUTO => 1, hello2 => 'Hello two');

1;
