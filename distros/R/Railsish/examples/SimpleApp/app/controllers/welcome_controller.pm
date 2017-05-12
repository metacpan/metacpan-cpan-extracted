package WelcomeController;
our $VERSION = '0.21';

use Railsish::Controller;

sub index {
    render(title => "Welcome");
}

sub here {
    our $answer = 42;
    render;
}


1;
