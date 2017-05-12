use strict;
use warnings;

use lib 't/lib';

use File::Basename;
use File::Spec;
use Pod::Confluence::TestUtil qw(
    write_pod
);
use Test::More tests => 18;

BEGIN { use_ok('Pod::Confluence') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger = Log::Any->get_logger();

my $test_dir = dirname( File::Spec->rel2abs($0) );

sub is_parsed {
    my ( $pod_string, $expected, $message, %options ) = @_;

    my $converter = Pod::Confluence->new(%options);
    my $pod       = pod_string($pod_string);
    $logger->tracef( "****POD****\n%s\n****END POD****", $pod );
    my $markdown = '';

    $converter->output_string( \$markdown );
    $converter->parse_string_document($pod);
    $logger->tracef( "****MARKDOWN****\n%s\n****END MARKDOWN****", $markdown );
    is( $markdown, $expected, $message );
}

is_parsed(
    q[
    my $code;
    $code->does_stuff();

    __END__
    =head1 SYNOPSIS
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<h1>SYNOPSIS</h1>',
    'head1'
);

is_parsed(
    q[
    =head1 SYNOPSIS
    
    foo
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<h1>SYNOPSIS</h1><p>foo</p>',
    'head1 para'
);

is_parsed(
    q[
    =head1 SYNOPSIS

    Cool stuff

        $some_code->does_stuff();
        $some_code->does_other_stuff();

    =head1 DESCRIPTION

    A cool package that does cool stuff

    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<h1>SYNOPSIS</h1>'
        . '<p>Cool stuff</p>'
        . '<ac:structured-macro ac:name=\'code\' ac:schema-version=\'1\'>'
        . '<ac:parameter ac:name=\'language\'>perl</ac:parameter>'
        . '<ac:plain-text-body><![CDATA['
        . "    \$some_code->does_stuff();\n"
        . '    $some_code->does_other_stuff();'
        . ']]></ac:plain-text-body>'
        . '</ac:structured-macro>'
        . '<h1>DESCRIPTION</h1>'
        . '<p>A cool package that does cool stuff</p>',
    'multiple section with code block'
);

is_parsed(
    q[
    =head1 CONSTRUCTORS
    
    =head2 new(%options)

    Creates a new foo. Available options:

    =over 4

    =item bar

    Bar option

    =item baz

    Baz option

    =back
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<h1>CONSTRUCTORS</h1>'
        . '<h2>new(%options)</h2>'
        . '<p>Creates a new foo. Available options:</p>'
        . '<p style="margin-left: 30px;"><strong>bar</strong></p>'
        . '<p style="margin-left: 60px;">Bar option</p>'
        . '<p style="margin-left: 30px;"><strong>baz</strong></p>'
        . '<p style="margin-left: 60px;">Baz option</p>',
    'head1 head2 list'
);

is_parsed(
    q[
    =pod

    Link to L<Foo::Bar> module.

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p>Link to '
        . '<ac:link>'
        . "<ri:page ri:content-title='Foo::Bar' ri:space-key='CP'/>"
        . '<ac:plain-text-link-body><![CDATA[Foo::Bar]]></ac:plain-text-link-body>'
        . '</ac:link>'
        . ' module.</p>',
    'page link',
    space_key         => 'CP',
    packages_in_space => ['Foo::Bar']
);

is_parsed(
    q[
    =pod

    Link to L<baz(%options)|Foo::Bar/baz(%options)> section.

    =head1 METHODS

    =head2 baz(%options)

    Do baz with options.

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p>Link to '
        . '<ac:link ac:anchor=\'baz(%options)\'>'
        . "<ri:page ri:content-title='Foo::Bar' ri:space-key='CP'/>"
        . '<ac:plain-text-link-body><![CDATA[baz(%options)]]></ac:plain-text-link-body>'
        . '</ac:link>'
        . ' section.</p>'
        . '<h1>METHODS</h1>'
        . '<h2>baz(%options)</h2>'
        . '<p>Do baz with options.</p>',
    'page link with section',
    space_key         => 'CP',
    packages_in_space => ['Foo::Bar']
);

is_parsed(
    q[
    =pod

    Link to L</sec> section.

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p>Link to '
        . '<ac:link ac:anchor=\'sec\'>'
        . '<ac:plain-text-link-body><![CDATA["sec"]]></ac:plain-text-link-body>'
        . '</ac:link>'
        . ' section.</p>',
    'section link',
    space_key => 'CP'
);

is_parsed(
    q[
    =pod

    Link to L<name|/sec> section.

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p>Link to '
        . '<ac:link ac:anchor=\'sec\'>'
        . '<ac:plain-text-link-body><![CDATA[name]]></ac:plain-text-link-body>'
        . '</ac:link>'
        . ' section.</p>',
    'section link with name',
    space_key => 'CP'
);

is_parsed(
    q[
    =pod

    Link to L<Foo::Bar> module.

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p>Link to <a href=\'https://metacpan.org/pod/Foo::Bar\'>Foo::Bar</a> module.</p>',
    'page link not in space',
    space_key => 'CP'
);

is_parsed(
    q[
    =pod

    Link to L<baz(%options)|Foo::Bar/baz(%options)> section.

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p>Link to <a href=\'https://metacpan.org/pod/Foo::Bar#baz-options\'>baz(%options)</a> section.</p>',
    'page link with section not in space',
    space_key => 'CP'
);

is_parsed(
    q[
    =pod

    Link to L<google|http://www.google.com> 

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p>Link to <a href=\'http://www.google.com\'>google</a></p>',
    'web link'
);

is_parsed(
    q[
    =pod

    B<Bold> 

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p><strong>Bold</strong></p>',
    'bold'
);

is_parsed(
    q[
    =pod

    I<Italic> 

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p><em>Italic</em></p>',
    'italic'
);

is_parsed(
    q[
    =pod

    C<Code> 

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p><code>Code</code></p>',
    'italic'
);

is_parsed(
    q[
    =pod

    E<lt>E<gt>E<verbar>E<sol>E<eacute>E<0x2615>

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p>&lt;&gt;|/&eacute;&#x2615;</p>',
    'entities'
);

is_parsed(
    q[
    =pod

    F<File> 

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p><em>File</em></p>',
    'file'
);

is_parsed(
    q[
    =pod

    S<$x ? $y : $z> 

    =cut
    ],
    '<p><ac:structured-macro ac:name=\'toc\' ac:schema-version=\'1\' /></p>'
        . '<p>$x&nbsp;?&nbsp;$y&nbsp;:&nbsp;$z</p>',
    'file'
);
