use Mojo::DOM;
use Mojo::File qw/path/;
use Getopt::Long::Descriptive;
use Mojo::Util qw/dumper/;

$\ = "\n"; $, = "\t";

my $svg = Mojo::DOM->new->with_roles('+Style', '+File')->from_file($ARGV[0]);

print $svg->at('#rect10')->style('stroke', 'black');

print $svg->at('#rect10')->style('stroke', 'black')->attr('x');

print $svg->at('#rect10')->style('stroke', 'black')->{stroke};

print $svg->at('#rect10')->style('stroke', 'black')->{fill};
