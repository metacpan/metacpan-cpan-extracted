use 5.014;

package main;

use Test::Most;
use Test::Memory::Cycle;
use File::stat;
use File::Temp;
use Mojo::UserAgent::Mockable;

my $url = q{http://www.example.com/};
my $dir = File::Temp->newdir;
my $output_file = qq{$dir/scoping.json};

{
    my $mock =
        Mojo::UserAgent::Mockable->new( ioloop => Mojo::IOLoop->singleton, mode => 'record', file => $output_file );
    memory_cycle_ok($mock, 'No circular references');
    $mock->get( $url );
}

if ( -e $output_file ) {
    my $st = stat($output_file);
    say 'Exists and ' . ($st->size > 0 ? 'nonzero' : 'zero') . ' size';
}
else {
    say 'Output file does not exist';
}

done_testing;
