package Pod::ToDocBook::TableDefault;

#$Id: TableDefault.pm 579 2009-07-25 16:23:26Z zag $

=head1 NAME

Pod::ToDocBook::TableDefault - Plugin for generating basic tables with B<=begin table> and B<=end table>. 


=head1 SYNOPSIS


    use Pod::ToDocBook::Pod2xml;
    use Pod::ToDocBook::TableDefault;
    use XML::ExtOn ('create_pipe');
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p =
      create_pipe( $px, qw( Pod::ToDocBook::TableDefault ),
        $w );
    $p->parse($text);

=head1 DESCRIPTION

Pod::ToDocBook::TableDefault - Plugin for generating basic tables with B<=begin table> and B<=end table>. 


=head2 XML FORMAT

For POD:

 =begin table

 table title
 left, center, right
 column name 1,"testname , meters", name3
 123 , 123 , 123
 1,2,"2, and 3"

 =end table

Result:

    <table>
      <title>table title</title>
      <tgroup cols="3">
        <colspec align="left"/>
        <colspec align="center"/>
        <colspec align="right"/>
        <thead>
          <row>
            <entry>column name 1</entry>
            <entry>testname , meters</entry>
            <entry> name3</entry>
          </row>
        </thead>
        <tbody>
          <row>
            <entry>123 </entry>
            <entry> 123 </entry>
            <entry> 123</entry>
          </row>
          <row>
            <entry>1</entry>
            <entry>2</entry>
            <entry>2, and 3</entry>
          </row>
        </tbody>
      </tgroup>
    </table>

=cut

use warnings;
use strict;
use Data::Dumper;
use Test::More;
use Text::ParseWords;
use XML::ExtOn;
use Pod::ToDocBook::Pod2xml;
use base 'XML::ExtOn';

#<begin params='test' name='table'>

sub on_start_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;
    my $attr  = $el->attrs_by_name;
    if ( $lname eq 'begin' and $attr->{name} eq 'table' and !$attr->{params} ) {
        $self->{PROCESS}++;
        $el->delete_element;
    }
    $el;
}

=head2 process_format  $cdata name=>table param=><string>

Must retrun array ref to elements

=cut

sub process_format {
    my ( $self, $cdata, %att ) = @_;
    my ( $title, $align, $row_titles, @strs ) = split( /\n/, $cdata );
    #create POD2XML instance for parce pod sequences
    my $pod_parser = new Pod::ToDocBook::Pod2xml::;
    my $table =
      $self->mk_element('table')
      ->add_content(
        $self->mk_element('title')->add_content( $pod_parser->get_elements_from_text($title, 'table format') )
      );
    my @alignspec = split( /\s*,\s*/, $align );
    ( my $tgroup = $self->mk_element('tgroup') )->attrs_by_name->{cols} =
      scalar(@alignspec);

    #left, center, right
    #add aligns
    for (@alignspec) {
        ( my $colspec = $self->mk_element('colspec') )->attrs_by_name->{align} =
          $_;
        $tgroup->add_content($colspec);
    }

    #make row titles
    # name1, name2, name3
    my $row     = $self->mk_element('row');
    my @entryes = ();
    for ( quotewords( ',|\|', 0, $row_titles ) ) {
        push @entryes,
          $self->mk_element('entry')->add_content( $pod_parser->get_elements_from_text($_, 'table format') );
    }
    $row->add_content(@entryes)->insert_to( $self->mk_element('thead') );

    my @rows = ();

    #fill tbody
    foreach my $line (@strs) {

        #skip empty files
        next if $line =~ /^\s*$/;
        my @fields = quotewords( ',|\|', 0, $line );
        my @elems = ();
        for (@fields) {
            push @elems,
              $self->mk_element('entry')
              ->add_content(  $pod_parser->get_elements_from_text($_, 'table format') );
        }
        push @rows, $self->mk_element('row')->add_content(@elems);
    }
    my $tbody = $self->mk_element('tbody')->add_content(@rows);

    #row
    $table->add_content( $tgroup->add_content( $row, $tbody ) );
    return $table;
}

sub on_end_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;
    if ( $lname eq 'begin' and exists $self->{PROCESS} ) {
        delete $self->{PROCESS};
        my $attr  = $el->attrs_by_name;
        my $cdata = $el->{CDATA};
        delete $el->{CDATA};
        return $self->process_format( $cdata, %$attr );
    }
    $el;
}

sub on_cdata {
    my ( $self, $elem, $cdata ) = @_;
    if ( exists $self->{PROCESS} ) {
        $elem->{CDATA} .= $cdata;
        return undef;
    }
    return $cdata;
}

1;
__END__

=head1 SEE ALSO

XML::ExtOn,  Pod::2::DocBook

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

