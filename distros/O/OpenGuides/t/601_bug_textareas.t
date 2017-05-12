use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Template;
use OpenGuides::Test;
use OpenGuides::Utils;
use Test::More;

eval { require DBD::SQLite; };

if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 1;

    OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

my $out = OpenGuides::Template->output(
    wiki     => $wiki,
    config   => $config,
    template => "edit_form.tt",
    vars     => {
                  locales  => [
                                { name => "Barville" },
                                { name => "Fooville" },
                              ],
                },
);

like( $out, qr/Barville\nFooville/,
     "locales properly separated in textarea" );
