package MyTemplate;

use Moose;
with 'Template::Caribou';

use Template::Caribou::Utils;
use Template::Caribou::Tags::HTML;

has name => (
    is => 'ro',
);

template page => sub {
    html { 
        head { title { 'Example' } };
        show( 'body' );
    }
};

template body => sub {
    my $self = shift;

    body { 
        h1 { 'howdie ' . $self->name } 
    }
};

1;

package main;

my $template = MyTemplate->new( name => 'Bob' );
print $template->render('page');




