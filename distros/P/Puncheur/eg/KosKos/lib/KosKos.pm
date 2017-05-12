package KosKos;
use strict;
use warnings;
use utf8;

use parent 'Puncheur';
use Puncheur::Dispatcher::Lite;
use Data::Section::Simple ();
__PACKAGE__->setting(
    template_dir => [Data::Section::Simple::get_data_section],
);

any '/' => sub {
    my $c = shift;

    $c->render('index.tx');
};

1;

__DATA__
@@ index.tx
<h1>It Works!</h1>
