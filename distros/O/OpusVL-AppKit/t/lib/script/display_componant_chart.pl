
use strict;
use Catalyst::ScriptRunner;
use CatalystX::Dispatcher::AsGraph;

use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../../../lib";

# load the application (so that AppBuilder calls the ->setup, etc. )
Catalyst::ScriptRunner->run('TestApp', 'Test');

# load the CatalystX::Dispatcher object with the TestApp ..
my $graph = CatalystX::Dispatcher::AsGraph->new
(
    appname => 'TestApp',
    output  => 'TestApp.png'
);
$graph->run;

# how to output?...
if ( $ARGV[0] && $ARGV[0] eq 'dot' )
{
    # output as graphviz image...
    if ( open( my $png, '|-', 'dot -Tpng -o ' . $graph->output ) ) 
    {
        print $png $graph->graph->as_graphviz;
        close($png);
    }
}
else
{
    print $graph->graph->as_txt
}
