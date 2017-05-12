use strict;
use warnings;

use Test::More; 

my @data = <DATA>;
plan tests => 1 + (scalar @data)/2;
require_ok('Pod::Plainer');

my $parser = Pod::Plainer->new();
my $header = "=pod\n\n";
my $input  = 'plnr_in.pod';
my $output = 'plnr_out.pod';

while( my $data = shift @data ) {
    my $expected = $header.(shift @data); 

    open(IN, '>', $input) or die $!;
    print IN $header, $data;
    close IN or die $!;

    open IN, '<', $input or die $!;
    open OUT, '>', $output or die $!;
    $parser->parse_from_filehandle(\*IN,\*OUT);
    close IN;

    open OUT, '<', $output or die $!;
    my $returned; { local $/; $returned = <OUT>; }
    close OUT;
    
    chomp $data;
    is($returned,$expected,"POD ".$data);
}

END { 
    1 while unlink $input;
    1 while unlink $output;
}

# $Id: plainer.t 363 2014-07-04 09:09:41Z robin $

__END__
=head <> now reads in records
=head E<lt>E<gt> now reads in records
=item C<-T> and C<-B> not implemented on filehandles
=item C<-T> and C<-B> not implemented on filehandles
e.g. C<< Foo->bar() >> or C<< $obj->bar() >>
e.g. C<Foo-E<gt>bar()> or C<$obj-E<gt>bar()>
The C<< => >> operator is mostly just a more visually distinctive
The C<=E<gt>> operator is mostly just a more visually distinctive
C<uv < 0x80> in which case you can use C<*s = uv>.
C<uv E<lt> 0x80> in which case you can use C<*s = uv>.
C<time ^ ($$ + ($$ << 15))>), but that isn't necessary any more.
C<time ^ ($$ + ($$ E<lt>E<lt> 15))>), but that isn't necessary any more.
The bitwise operation C<<< >> >>>
The bitwise operation C<E<gt>E<gt>>
