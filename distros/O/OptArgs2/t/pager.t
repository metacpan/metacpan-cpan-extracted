#!/usr/bin/env perl
use Test2::V0;
use OptArgs2::Pager ':all';
use Capture::Tiny 'capture';

# As Capture::Tiny does not present filehandles as ttys, this is mostly
# an academic check of the interface.

my $stdout = select;
my ( $out, $err );

# Run
subtest 'start/stop' => sub {
    stop_pager();    # harmless before anything else happened
    is( (select), $stdout, 'still default stdout' );

    ( $out, $err ) = capture {
        start_pager();
        print "text\n";
        stop_pager();
    };
    is $out, "text\n", 'out';
    is $err, '',       'err';

    ( $out, $err ) = capture {
        start_pager();
        start_pager();
        print "text\n";
        stop_pager();
        stop_pager();
    };
    is $out, "text\n", 'out';
    is $err, '',       'err';
};

subtest 'page' => sub {
    ( $out, $err ) = capture {
        page("text\n");
        page("text2\n");    # multiple calls ok
    };
    is $out, "text\ntext2\n", 'out';
    is $err, '',              'err';
};

subtest 'Pager' => sub {
    subtest 'auto' => sub {
        ( $out, $err ) = capture {
            is( (select), $stdout, 'default stdout' );
            {
                #                diag 'STDOUT is ' . STDOUT->fileno;
                my $p = OptArgs2::Pager->new( auto => 1 );

                #                diag 'Pager would be ' . $p->pager;
                is $p->orig_fh, $stdout, 'orig stdout';
                is $p->fh, (select), 'pager fh';
                todo 'no tty for test' => sub {
                    isnt( (select), $stdout, 'pager fh selected' );
                };
                print "text\n";
            }
            is( (select), $stdout, 'default stdout' );
        };
        is $out, "text\n", 'out';
        is $err, '',       'err';
    };

};

done_testing();
