#===============================================================================
#
#  DESCRIPTION:  test for =table 
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Block::table;

package T::Block::table;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use base 'TBase';


use Perl6::Pod::Block::table;
sub parse_table {
 return Perl6::Pod::Block::table::parse_table(@_)
}


sub a00_table_headers:Test(2) {
    my $t1 = parse_table(<<T,3);
        The Shoveller e | Eddie Stevens     |  King Arthur's singing shovel  
        ================+===================+============================
        The Shovell2er  | Eddie 2Stevens    | King Arthur's singing shovel2
        The Shoveel2er  | Eddie 2S3tevens   | King Arthur's singing shovel23  
T
    ok $t1->{row_delims}->[0]->{header_row_delims}, 'header row delims';
    is @{$t1->{row}}, 3, 'rows';
}

sub a03_table_headers:Test() {
    my $t1 = parse_table(<<T,3);
        Superhero     | Secret Identity   |  Superpower 
        ==============|=================+================================
        The Shoveller | Eddie Stevens   | King Arthur's singing shovel

        Blue Raja     | Geoffrey Smith  | Master of cutlery              
        Mr Furious    | Roy Orson       | Ticking time bomb of fury      
        The Bowler    | Carol Pinnsler     Haunted bowling ball           
T
    is @{$t1->{row}},5, 'multiline'
}

sub a02_table_headers:Test() {
    my $t1 = parse_table(<<T,3);
        The Shoveller e   Eddie Stevens      King Arthur's singing shovel 
        The Shovell25er    Eddie 2Stevens    King Arthur's singing shovel2   
        The Shoveel26er   Eddie 2S3tevens    King Arthur's singing shovel23  
T

    is @{$t1->{row}},3, 'cols with whitespace delims'
}

sub c01_table_xml:Test(2) {
    my $t = shift;
    my $x = $t->parse_to_test (<<T);
=begin pod
=begin table
= :w<2>
        Superhero     | Secret          | 
                      | Identity        | Superpower 
        ==============|=================+================================
        The Shoveller | Eddie Stevens   | King Arthur's singing shovel

        Blue Raja     | Geoffrey Smith  | Master of cutlery              
        Mr Furious    | Roy Orson       | Ticking time bomb of fury      
        The Bowler    | Carol Pinnsler     Haunted bowling ball           
=end table
=end pod
T
 my $t1 = $x->{table}->[0];
 ok $t1->is_header_row, "check header row";
 is @{$t1->get_rows}, 5, 'get_rows';
}

sub c02_table_xhtml:Test {
    my $t = shift;
    my $x = $t->parse_to_xhtml (<<T);
=begin pod
=begin table :caption("a")
= :w<2>
        Superhero     | Secret          
        ==============|=================
        The Shoveller | Eddie Stevens   
=end table
=end pod
T

$t->is_deeply_xml( $x,
q#<?xml version="1.0"?>
<xhtml xmlns="http://www.w3.org/1999/xhtml">
  <table>
    <caption>a</caption>
    <tr>
      <th>Superhero</th>
      <th>Secret</th>
    </tr>
    <tr>
      <td>The Shoveller</td>
      <td>Eddie Stevens</td>
    </tr>
  </table>
</xhtml>
#)
}

sub c03_table_docbook:Test {
    my $t = shift;
    my $x = $t->parse_to_docbook (<<T);
=begin pod
=begin table :caption("a")
= :w<2>
        Superhero     | Secret          
        ==============|=================
        The Shoveller | Eddie Stevens   
=end table
=end pod
T
$t->is_deeply_xml ($x, q#<?xml version="1.0"?>
<chapter>
  <table>
    <title>a</title>
    <tgroup align='center' cols='2'>
    <thead>
      <row>
        <entry>Superhero</entry>
        <entry>Secret</entry>
      </row>
    </thead>
    <tbody>
      <row>
        <entry>The Shoveller</entry>
        <entry>Eddie Stevens</entry>
      </row>
    </tbody>
    </tgroup>
  </table>
</chapter>#)
}

1;

