use strict;
use warnings;
use utf8;
use lib 'lib';
use Puncheur;

my $app = Puncheur->new(
    view         => 'MT',
    template_dir => 'eg/tmpl',
);

$app->to_psgi;
