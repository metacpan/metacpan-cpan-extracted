use strict;
use Test::More;
use Pandoc::Elements;
use Pandoc;
use Pod::Simple::Pandoc;
use Pod::Pandoc::Modules;
use Test::Exception;

plan skip_all => 'pandoc not available' unless pandoc;

my $parser = Pod::Simple::Pandoc->new;

# add
{
    my $modules = Pod::Pandoc::Modules->new;
    my $name = 'Pod::Simple::Pandoc';
    my $file = 'lib/Pod/Simple/Pandoc.pm';
    my $doc = $parser->parse_file($file);
    ok $modules->add( $name => $doc ), 'add';
    is $modules->{$name}, $doc, 'added'; 

    ok !$modules->add( $name => $parser->parse_file('script/pod2pandoc') );
    is $modules->{$name}, $doc, 'add doesn\'t override'; 

    $file = 't/examples/Pandoc.pod';
    ok $modules->add( $name => $parser->parse_file($file) ), 'add';
    is $modules->{$name}->metavalue('file'), $file, '.pod overrides .pm';
    is $modules->{$name}->metavalue('title'), $name, 'title without NAME';
}

# constructor
my $modules = Pod::Pandoc::Modules->new({ 
    'Pod::Simple::Pandoc' => $parser->parse_file('lib/Pod/Simple/Pandoc.pm')
});

# index
sub is_index {
    my ( $name, $opt, $meta, $url, $title ) = @_;

    is_deeply $modules->index(%$opt),
      Document( $meta, [
            DefinitionList [ [
                [
                    Link attributes {},
                    [ Str 'Pod::Simple::Pandoc' ],
                    [ $url, $title ]
                ],
                [ [ Plain [ Str 'convert Pod to Pandoc document model' ] ] ]
            ] ]
        ]), $name;
}

is_index(
    'index (default)',
    {}, {},
    'Pod-Simple-Pandoc.html', 'Pod::Simple::Pandoc'
);

is_index(
    'index (wiki & title)',
    { wiki => 1, title => 'test' }, { title => MetaString 'test' },
    'Pod-Simple-Pandoc', 'wikilink'
);


done_testing;
