use strict;
use Test::More;
use Test::Exception;
use Pandoc::Elements;
use Pandoc::Filter::Multifilter qw(find_filter apply_filter);
use IPC::Cmd 'can_run';
use Pandoc;

# find_filter( ... )
{
    my @tests = (
        {   input    => ['script/multifilter'],
            expected => ['script/multifilter'],
            name     => 'absolute path',
            skip     => 'MSWin32',
        },
        {   input    => ['t/pandoc/filters/empty.pl'],
            expected => [ 'perl', 't/pandoc/filters/empty.pl' ],
            name     => 'known extension',
        },
        {   input    => ['perl'],
            expected => [ can_run('perl') ],
            name     => 'executable in $PATH',
        },
    );

    local $ENV{HOME} = 't';
    if ( -e 't/.pandoc' ) {    # only in git repository
        push @tests,
            (
            {   input    => ['empty.pl'],
                expected => [ 'perl', 't/.pandoc/filters/empty.pl' ],
                name     => 'known extension in DATA_DIR',
            },
            {   input    => ['caps'],
                expected => ['t/.pandoc/filters/caps'],
                name     => 'executable in DATA_DIR',
                skip     => 'MSWin32',
            },
            );
    }

    while ( my $test = shift @tests ) {
    SKIP: {
            skip 'find_filter: ' . $test->{name} . ' on ' . $^O, 1
                if $^O eq ($test->{skip} || '-');
            my @filter = find_filter( @{ $test->{input} } );
            is_deeply \@filter, $test->{expected}, join ' ', 'find_filter: ' . $test->{name};
        }
    }

    my $notfound = '0c9703d020ded30c97682e812636c9ef';
    throws_ok { find_filter($notfound) } qr/^filter not found: $notfound/;
}

if ( $ENV{RELEASE_TESTING} and pandoc and pandoc->version('1.12') ) {

    my $in = Document {}, [ Para [ Str 'hi' ] ];

    my $out = apply_filter( $in, 'html', find_filter( 'caps', 't/pandoc' ) );
    is $out->string, 'HI', 'apply_filter';

    throws_ok {
        apply_filter( $in, 'html', find_filter( 'empty.pl', 't/pandoc' ) );
    }
    qr{^filter emitted no valid JSON};

    if ( -e 't/.pandoc' ) {    # only in git repository
        $in->meta( { multifilter => MetaList [ MetaInlines [ Str 'caps' ] ] } );
        local $ENV{HOME} = 't';
        Pandoc::Filter::Multifilter->new->apply($in)->to_json;
        is $in->string, 'HI', 'apply_filter';
    }

} else {
    note "Skipping detailed testing of Pandoc::Filter::Multifilter";
}

done_testing;
