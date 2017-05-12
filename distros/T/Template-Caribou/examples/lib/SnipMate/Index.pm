package SnipMate::Index;

use 5.14.0;

use strict;
use warnings;

use Method::Signatures;

use Moose;

use MooseX::Types::Path::Class;

use SnipMate::Snippets;

use Template::Caribou::Utils;
use Template::Caribou::Tags::HTML qw/ :all /;

with 'Template::Caribou';

has 'snippet_dir' => (
    isa => 'Path::Class::Dir',
    is => 'ro',
    default => $ENV{HOME}.'/.vim/snippets',
    coerce => 1,
);

has snippet_files => (
    is => 'ro',
    traits => [ 'Array' ],
    lazy => 1,
    default => sub {[
        map  { Path::Class::file($_) }
        grep { /\.snippets$/ }
        $_[0]->snippet_dir->children
    ]},
    handles => {
        'all_snippet_files' => 'elements'
    },
);

template webpage => method {
    html { body { ul { 
        li {
            anchor $_->basename.'.html' => $_->basename;
        } for $self->all_snippet_files;
    } } }
};

method generate_pages {
    for ( $self->all_snippet_files ) {
        generate_snippet_file( $_, $_->basename . '.html' );
    }
}

sub generate_snippet_file {
    my ( $src, $dest ) = @_;
    open my $fh, '>', $dest or die $!;

    print $fh SnipMate::Snippets->new( snippet_file => $src)
                    ->render('webpage');
}

__PACKAGE__->meta->make_immutable;

1;
