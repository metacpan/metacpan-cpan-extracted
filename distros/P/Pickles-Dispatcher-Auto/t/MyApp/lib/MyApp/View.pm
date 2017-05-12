package MyApp::View;

use strict;
use warnings;
use parent 'Pickles::View::Xslate';

__PACKAGE__->config(
    module => [ 'Text::Xslate::Bridge::TT2Like' ],
    syntax => 'TTerse',
    suffix => '.html',
);

1;

__END__

