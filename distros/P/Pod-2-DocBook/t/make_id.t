use strict;
use warnings;

use Test::More;                      # last test to print

use Pod::2::DocBook;

eval "use XML::LibXML; 1" 
    or plan skip_all => 'test requires XML::LibXML'; 

plan tests => 1;

my $parser = Pod::2::DocBook->new( doctype => 'article' );

my $in = join '', <DATA>;
open my $in_fh, '<', \$in;

my $out;
open my $out_fh, '>', \$out;


$parser->parse_from_file( $in_fh, $out_fh );

my $dom = XML::LibXML->new->parse_string( $out );

my @ids = map $_->findvalue( '@id' ), $dom->findnodes( '//section' );

isnt $ids[0] => $ids[1], 'ids are different';

__END__

__DATA__

=head1 FOO

This is the first one

=head1 FOO

And this is the second one
