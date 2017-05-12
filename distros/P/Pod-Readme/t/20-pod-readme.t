use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use Cwd;
use File::Compare qw/ compare_text /;
use File::Temp qw/ tempfile /;
use Path::Tiny qw/ path /;

use lib 't/lib';
use Pod::Readme::Test;

# use Pod::Readme::Test::Kit;

my $class = 'Pod::Readme';
use_ok $class;

isa_ok $prf = $class->new( output_fh => $io, ), $class;

{
    ok !$prf->can('cmd_noop'), 'no noop';

    filter_lines('=for readme plugin noop');
    is $prf->mode, 'pod:for', 'mode';

    filter_lines('');
    is $prf->mode, 'pod', 'mode';
    ok $prf->in_target, 'in target';

    is $out, '', 'no output';

    can_ok( $prf, 'cmd_noop' );
    isa_ok( $prf, 'Pod::Readme::Filter' );

    throws_ok {
        filter_lines('=for readme plugin noop::invalid');
        is $prf->mode, 'pod:for', 'mode';
        filter_lines('');
    }
    qr/Unable to locate plugin 'noop::invalid'/, 'bad plugin';

    is $prf->mode('pod'), 'pod', 'mode reset';

    filter_lines( '=for readme plugin noop', '' );

    can_ok( $prf, qw/ noop_bool noop_str / );
    ok !$prf->noop_bool, 'plugin accessor default';
    is $prf->noop_str, '', 'plugin accessor default';

    filter_lines( '=for readme plugin noop bool', '' );
    ok $prf->noop_bool, 'plugin accessor set';
    filter_lines( '=for readme plugin noop no-bool str="Isn\'t this nice?"',
        '' );
    ok !$prf->noop_bool, 'plugin accessor unset';
    is $prf->noop_str, "Isn\'t this nice?", 'plugin accessor set';

    throws_ok {
        filter_lines( '=for readme plugin noop no-bool bad-attr="this"', '' );
    }
    qr/Invalid argument key 'bad-attr' at input line \d+/;
};

{
    my $source = 't/data/README-1.pod';

    lives_ok {

        my $dest = ( tempfile( UNLINK => 1 ) )[1];
        note $dest;

        ok my $parser = Pod::Readme->new, 'new (no args)';
        $parser->parse_from_file( $source, $dest );

        ok !compare_text( $dest, 't/data/README.txt' ), 'expected output';

    }
    'parse_from_file';

    lives_ok {

        my $dest = ( tempfile( UNLINK => 1 ) )[1];
        note $dest;

        Pod::Readme->parse_from_file( $source, $dest );

        ok !compare_text( $dest, 't/data/README.txt' ), 'expected output';

    }
    'parse_from_file (class method)';

    lives_ok {

        open my $source_fh, '<', $source;
        my ( $dest_fh, $dest ) = tempfile( UNLINK => 1 );
        note $dest;

        ok my $parser = Pod::Readme->new, 'new (no args)';
        $parser->parse_from_filehandle( $source_fh, $dest_fh );

        ok !compare_text( $dest, 't/data/README.txt' ), 'expected output';

        close $source_fh;

    }
    'parse_from_filehandle';

    lives_ok {

        open my $source_fh, '<', $source;
        my ( $dest_fh, $dest ) = tempfile( UNLINK => 1 );
        note $dest;

        Pod::Readme->parse_from_filehandle( $source_fh, $dest_fh );

        ok !compare_text( $dest, 't/data/README.txt' ), 'expected output';

        close $source_fh;

    }
    'parse_from_filehandle (class method)';

}

done_testing;
