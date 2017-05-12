package TestsFor::Template::Caribou::Files;

use strict;
use warnings;

use Test::More tests => 1;

-d $_ or mkdir $_ for map "t/$_", qw/ foo bar /;

{ 
    package Bar;

    use Moose::Role;
    use Template::Caribou;

    with 'Template::Caribou::Files' => {
        dirs => [ 't/bar' ],
    };
}

use Template::Caribou;

with 'Template::Caribou::Files' => {
    dirs => [ 't/foo' ],
};
with 'Bar';

subtest all_template_dirs => sub {
    my $self = __PACKAGE__->new;
    
    is_deeply [ $self->all_template_dirs ], [ map "t/$_", qw/ foo bar / ], 'all_template_dirs';
};
