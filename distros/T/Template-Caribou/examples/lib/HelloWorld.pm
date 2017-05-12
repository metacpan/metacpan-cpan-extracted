package HelloWorld;

use 5.10.0;

use strict;
use warnings;

use Moose;
use Template::Caribou::Utils;
use Template::Caribou::Tags::HTML;
use MyTags;

with 'Template::Caribou';
with 'MyWebPage';

has 'user_name' => (
    is => 'ro',
    default => 'buddie',
);

template main => sub {
    my $self = shift;

    h1 { 
        say "welcome ";
        emphasis { $self->user_name };
        say "!";
    };
    my_img { attr src => '/happy_face.png' };

    say ::RAW "this will <not> be escaped.";
    say "this <will> be escaped.";
    
};

__PACKAGE__->meta->make_immutable;
1;
