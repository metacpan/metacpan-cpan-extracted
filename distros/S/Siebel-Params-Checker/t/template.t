use warnings;
use strict;
use Siebel::Params::Checker::Data qw(by_param by_server);
use Siebel::Params::Checker::Template qw(gen_report);
use Test::More;
use Cwd;
use File::Spec;
use Test::HTML::Lint;

my $report_file = File::Spec->catfile( getcwd(), 'output.html' );
my $report_file2 = File::Spec->catfile( getcwd(), 'output2.html' );
my ( $header, $rows ) = by_server( more_parameters() );
ok( gen_report( 'testing', $header, $rows, $report_file ),
    'report with more servers' );
html_ok(read_all_doc($report_file), 'validating HTML of report with more servers');
( $header, $rows ) = by_param( more_servers() );
ok( gen_report( 'testing2', $header, $rows, "$report_file2" ),
    'report with more parameters' );
html_ok(read_all_doc($report_file2), 'validating HTML of report with more parameters');
unlink $report_file;
unlink $report_file2;
done_testing();

sub read_all_doc {
    my $path = shift;
    local $/ = undef;
    open(my $in, '<', $path) or die "cannot read $path: $!";
    my $content = <$in>;
    close($in);
    return $content;
}

sub more_servers {
    return {
        'foobar005' => {
            'MinMTServers' => '1',
            'MaxTasks'     => '20'
        },
        'foobar004' => {
            'MaxTasks'     => '50',
            'MinMTServers' => '1',
        },
        'foobar008' => {
            'MaxTasks'     => '50',
            'MinMTServers' => '1',
        },
        'foobar009' => {
            'MaxTasks'     => '50',
            'MinMTServers' => '1',
        }
    };
}

sub more_parameters {
    return {
        'foobar005' => {
            'MinMTServers'    => '1',
            'MaxMTServers'    => '1',
            'BusObjCacheSize' => '0',
            'MaxTasks'        => '20'
        },
        'foobar004' => {
            'MaxTasks'        => '50',
            'MinMTServers'    => '1',
            'MaxMTServers'    => '1',
            'BusObjCacheSize' => '0'
        },
        'foobar008' => {
            'MaxMTServers'    => '1',
            'BusObjCacheSize' => '0',
            'MinMTServers'    => '1',
            'MaxTasks'        => '50'
        }
    };
}
