use strict;
use warnings;

use Test::More tests => 2;
use File::Spec;

use Sort::External;
use Fcntl;

my @letters = map {"$_\n"} ( 'a' .. 'z' );
my @reversed_letters = reverse @letters;

my ( $sortex, $sort_output );

$sortex = Sort::External->new(
    -working_dir    => File::Spec->curdir,
    -mem_threshold  => 2**24,
    -sortsub        => sub { $Sort::External::a cmp $Sort::External::b },
    -line_separator => 'ignored',
);

$sortex->feed($_) for @reversed_letters;
$sortex->finish(
    -outfile => 'sortfile.txt',
    -flags   => ( O_CREAT | O_WRONLY ),
);
open SORTFILE, "sortfile.txt" or die "Couldn't open file 'sortfile.txt': $!";
$sort_output = [<SORTFILE>];
close SORTFILE;
is_deeply( $sort_output, \@letters, "many -params" );
undef $sortex;
unlink "sortfile.txt" or 1;

$sortex = Sort::External->new( -cache_size => 2, );

$sortex->feed($_) for @reversed_letters;
$sortex->finish;
$sort_output = [];
while ( my $stuff = $sortex->fetch ) {
    push @$sort_output, $stuff;
}
is_deeply( $sort_output, \@letters, "-cache_size" );

