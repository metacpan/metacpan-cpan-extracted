package Perl6::Pod::Block::table;

=pod

=head1 NAME

Perl6::Pod::Block::table  - Simple tables

=head1 SYNOPSIS

    =table
        The Shoveller   Eddie Stevens     King Arthur's singing shovel   
        Blue Raja       Geoffrey Smith    Master of cutlery              
        Mr Furious      Roy Orson         Ticking time bomb of fury      
        The Bowler      Carol Pinnsler    Haunted bowling ball           


    =for table :caption('Tales in verse')
     Year  |                Name
     ======+==========================================
     1830  | The Tale of the Priest and of His Workman Balda
     1830  | The Tale of the Female Bear 
     1831  | The Tale of Tsar Saltan
     1833  | The Tale of the Fisherman and the Fish
     1833  | The Tale of the Dead Princess
     1834  | The Tale of the Golden Cockerel

=head1 DESCRIPTION

Simple tables can be specified in Perldoc using a =table block. The table may be given an associated description or title using the :caption option. 

Each individual table cell is separately formatted, as if it were a nested =para.

Columns are separated by whitespace (by regex {2,}), vertical lines (|), or border intersections (+). Rows can be specified in one of two ways: either one row per line, with no separators; or multiple lines per row with explicit horizontal separators (whitespace, intersections (+), or horizontal lines: -, =, _) between every row. Either style can also have an explicitly separated header row at the top. 

Each individual table cell is separately formatted, as if it were a nested =para.

This means you can create tables compactly, line-by-line:

    =table
        The Shoveller   Eddie Stevens     King Arthur's singing shovel   
        Blue Raja       Geoffrey Smith    Master of cutlery              
        Mr Furious      Roy Orson         Ticking time bomb of fury      
        The Bowler      Carol Pinnsler    Haunted bowling ball           


or line-by-line with multi-line headers:

    =table
        Superhero     | Secret          | 
                      | Identity        | Superpower 
        ==============|=================+================================
        The Shoveller | Eddie Stevens   | King Arthur's singing shovel   
        Blue Raja     | Geoffrey Smith  | Master of cutlery              
        Mr Furious    | Roy Orson       | Ticking time bomb of fury      
        The Bowler    | Carol Pinnsler  | Haunted bowling ball           
=cut

use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::Utl;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
our $VERSION = '0.01';

use constant {
    NEW_LINE           => qr/^ \s* $/xms,
    COLUMNS_SEPARATE   => qr/\s*\|\s*|[\ ]{2,}/xms,
    COLUMNS_FORMAT_ROW => qr/(\s+)?[\=\-]+[\=\-\+\n]+(\s+)?/xms,
    COLUMNS_FORMAT_ROW_SEPARATE   => qr/\s*\|\s*|\+|[\ ]{2,}/xms,
};

sub new {
    my $class = shift;
    my $self =  $class->SUPER::new(@_);
    my $content = $self->{content}->[0];
    my $count = $self->_get_count_cols($content);
    $self->{tree} = &parse_table($content, $count);
    $self->{col_count} = $count;
    $self

}

sub parse_table {
 my $text = shift;
 my $count_cols = shift;
 my $DEFER_REGEX_COMPILATION = "";
 my $qr = do {
  use Regexp::Grammars;
   qr{
       \A <Table> \Z

    <token: col_content>( [^\n]*? )
    <token: row>
       ^ \s* <[content=col_content]>+ % <col_delims> \s*
        <require: (?{ 
                $count_cols == scalar(@{ $MATCH{content} })
                })>
   <token: col_delims>( \s+[\|\+]\s+ | \ {2,} | \t+ )
   <token: row_delims>(
        \s* \n* <[header_row_delims=([=-_]+)]>+ % (\+|\s+|\|) \s* \n 
        | <endofline=((\s*\n)+)>
        )
    <token: Table>
        <[row]>+ % <[row_delims]>
    $DEFER_REGEX_COMPILATION
   }xms
 };
 if ($text =~ $qr ) {
    return $/{Table}
 } else {
    die "can't parse"
 }
}

=head2 is_header_row

Flag id header row exists

=cut

sub is_header_row {
    my $self = shift;
    exists $self->{tree}->{row_delims}->[0]->{header_row_delims}
}

sub get_rows {
    my $self = shift;
    my $rows = $self->{tree}->{row};
}


sub _get_count_cols {
    my $self      = shift;
    my $txt       = shift;
    my $row_count = 1;

    # calculate count of fields
    foreach my $line ( split /\n/, $txt ) {

        # clean begin and end of line
        $line =~ s/^\s*//;
        $line =~ s/\s*$//;
        my @columns = split( /${\( COLUMNS_SEPARATE )}/, $line );

        #try find format line
        # ---------|-----------, =====+=======
        if ( $line =~ /${\( COLUMNS_FORMAT_ROW )}/ ) {
            @columns = split( /${\( COLUMNS_FORMAT_ROW_SEPARATE )}/, $line );
            $row_count = scalar(@columns);
            $self->{NEED_NEAD}++;
            last;
        }

        #update max row_column
        $row_count =
          scalar(@columns) > $row_count ? scalar(@columns) : $row_count;
    }
    return $row_count;
}

sub _make_row {
    my $self = shift;
    my $rows = shift;
    for (@$rows) { $_ = join " ", @{ $_ || [] } }
    return { data => [@$rows], type => 'row' };

}

sub _make_head_row {
    my $self = shift;
    my $res  = $self->_make_row(@_);
    $res->{type} = 'head';
    delete $self->{NEED_NEAD};
    return $res;
}

sub to_xhtml {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    $w->raw('<table>');
    if ( my $caption = $self->get_attr->{caption}) {
        $w->raw('<caption>')->print($caption)->raw('</caption>')
    }
    my @rows = @{ $self->get_rows };
    if ( $self->is_header_row) {
       my $header = shift @rows; 
        $w->raw('<tr>');
        foreach my $h (@{ $header->{content} }) {
            $w->raw('<th>');
            $to->visit(Perl6::Pod::Utl::parse_para($h));
            $w->raw('</th>');
        }
        $w->raw('</tr>');
    }
    #render content
    foreach my $r ( @rows ) {
        $w->raw('<tr>');
        foreach my $cnt ( @{$r->{content}} ) {
          $w->raw('<td>');
          $to->visit(Perl6::Pod::Utl::parse_para($cnt));
          $w->raw('</td>');
        }
        $w->raw('</tr>');
    }
    $w->raw('</table>');
}

sub to_docbook {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    $w->raw('<table>');
    if ( my $caption = $self->get_attr->{caption}) {
        $w->raw('<title>')->print($caption)->raw('</title>')
    }
    $w->raw(qq!<tgroup align="center" cols="!.$self->{col_count}.'">');
    my @rows = @{ $self->get_rows };
    if ( $self->is_header_row) {
       my $header = shift @rows; 
        $w->raw('<thead><row>');
        foreach my $h (@{ $header->{content} }) {
            $w->raw('<entry>');
            $to->visit(Perl6::Pod::Utl::parse_para($h));
            $w->raw('</entry>');
        }
        $w->raw('</row></thead>');
    }
    #render content
     $w->raw('<tbody>');
    foreach my $r ( @rows ) {
         $w->raw('<row>');
        foreach my $cnt ( @{$r->{content}} ) {
         $w->raw('<entry>');
          $to->visit(Perl6::Pod::Utl::parse_para($cnt));
         $w->raw('</entry>');
        }
          $w->raw('</row>');
    }
    $w->raw('</tbody>');
    $w->raw('</tgroup>');
    $w->raw('</table>');

}

1;
__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

