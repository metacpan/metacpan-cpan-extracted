use strict;
use Test::More;
use Pandoc::Elements;
use Pandoc;
use Pod::Simple::Pandoc;
use Test::Exception;

plan skip_all => 'pandoc not available' unless pandoc;

my $parser = Pod::Simple::Pandoc->new();
my $file   = 'lib/Pod/Simple/Pandoc.pm';

# parse_file
{
    my $doc = $parser->parse_file($file);

    is_deeply $doc->query( Header => sub { $_->level == 1 ? $_->string : () } ),
      [ qw(SYNOPSIS DESCRIPTION OPTIONS METHODS MAPPING), 'SEE ALSO' ],
      'headers';

    is_deeply $doc->metavalue,
      {
        title    => 'Pod::Simple::Pandoc',
        subtitle => 'convert Pod to Pandoc document model',
        file     => $file,
      },
      'metadata';

    is_deeply $doc->query( RawBlock => sub { $_->format } ),
      [qw(markdown html html tex tex)], 'data sections as RawBlock';

    foreach ( '', 'Pandoc::Elements' ) {
        dies_ok { $parser->parse_file($_) } 'parse_file not found';
    }
}

# parse_file with name
{
    my $doc = Pod::Simple::Pandoc->new( name => 1 )->parse_file($file);
    is $doc->content->[0]->string, 'NAME', 'keep NAME section';
}

# parse module
isa_ok $parser->parse_module('Pandoc::Elements'), 'Pandoc::Document';

if ( $ENV{RELEASE_TESTING} ) {
    my $files = $parser->parse_dir('lib');
    is scalar( keys %$files ), 4, 'parse_dir';
    my $doc = $files->{'lib/Pod/Pandoc.pm'};
    isa_ok $doc, 'Pandoc::Document';
    is_deeply $doc->metavalue,
      {
        file     => 'lib/Pod/Pandoc.pm',
        title    => 'Pod::Pandoc',
        subtitle => 'process Plain Old Documentation format with Pandoc',
        base     => '../',
      },
      'parse_dir document metadata';

    $files = $parser->parse_dir('script');
    my @keys = keys %$files;
    like $keys[0], qr{^(script/)?pod2pandoc}, 'parse_dir with script';
}

# parse_string
{
    my $doc = $parser->parse_string(<<POD);
=over

I<hello>

=back
POD

    is_deeply $doc,
      Document( {}, [ BlockQuote [ Para [ Emph [ Str 'hello' ] ] ] ] ),
      'parse_string';
    is $doc->metavalue('title'), undef, 'no title';
}

# podurl
{
    my %opt  = ( podurl => 'http://example.org/' );
    my $doc  = Pod::Simple::Pandoc->new(%opt)->parse_file($file);
    my $urls = $doc->query( Link => sub { $_->url } );
    is $urls->[0], 'http://example.org/perlpod', 'podurl';
}

# parse data sections
if ( pandoc and pandoc->version >= '1.12' ) {
    my %opt = ( 'parse' => '*' );

    my $doc = Pod::Simple::Pandoc->new(%opt)->parse_file($file);
    is_deeply $doc->query( Header => sub { $_->level == 3 ? $_->string : () } ),
      ['Examples'],
      'data-sections';

    is_deeply [], $doc->query( RawBlock => sub { $_->format } ), 'no RawBlock';
}

done_testing;
