package App;
use Mojo::Base 'Mojolicious';

has test => 'Test App';

sub startup {
	my $self = shift;
	
	$self->plugin('mail');
	$self->plugin(I18N => {default => 'ru', support_url_langs => [qw(ru en)]});
	
	$self->renderer->paths(['.']);
}

package App::I18N;
use base 'Locale::Maketext';

sub import { warn __PACKAGE__ . ' ' . caller; }

package App::I18N::en;
use Mojo::Base 'App::I18N';

our %Lexicon = (_AUTO => 1, hello2 => 'Hello two');

package App::I18N::ru;
use Mojo::Base 'App::I18N';
use utf8;

our %Lexicon = (hello => 'Привет', hello2 => 'Привет два');

1;
