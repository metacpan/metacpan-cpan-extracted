package Pod::ToDocBook::FormatList;

#$Id: FormatList.pm 695 2010-01-18 17:48:33Z zag $

=head1 NAME

Pod::ToDocBook::FormatList - Plugin for generating item lists

=head1 SYNOPSIS


    use Pod::ToDocBook::Pod2xml;
    use Pod::ToDocBook::FormatList;
    use Pod::ToDocBook::ProcessItems;
    use XML::ExtOn ('create_pipe');
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p =
      create_pipe( $px, qw( Pod::ToDocBook::FormatList Pod::ToDocBook::ProcessItems),
        $w );
    $p->parse($text);

=head1 DESCRIPTION

Pod::ToDocBook::TableDefault - Plugin for generating item lists


=head2 XML FORMAT

For POD:


 =begin list 
 
 - item 1
 - item 2
 - item 3
 
 =end list


Result:

    <itemizedlist>
      <listitem>
        <para>item 1</para>
      </listitem>
      <listitem>
        <para>item 2</para>
      </listitem>
      <listitem>
        <para>item 3</para>
      </listitem>
    </itemizedlist>

For POD:


 =begin list 
 
 - item 1
 - item 2
 - item 3
 
 =end list


Result:

    <itemizedlist>
      <listitem>
        <para>item 1</para>
      </listitem>
      <listitem>
        <para>item 2</para>
      </listitem>
      <listitem>
        <para>item 3</para>
      </listitem>
    </itemizedlist>


=cut

use warnings;
use strict;
use Data::Dumper;
use Test::More;
use Pod::ToDocBook::Pod2xml;
use Pod::ToDocBook::TableDefault;
use base 'Pod::ToDocBook::TableDefault';

#<begin params='test' name='table'>

sub on_start_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;
    my $attr  = $el->attrs_by_name;
    if ( $lname eq 'begin' and $attr->{name} eq 'list' ) {
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

    #    my ( $title, $align, $row_titles, @strs ) = split( /\n/, $cdata );
    my $pod_parser = new Pod::ToDocBook::Pod2xml::;
    my $over = $self->mk_element('over');
    my @lines = split( /\n/, $cdata );
    foreach my $line (@lines) {
        # replace - to *
        $line =~ s/^[-+](\s+)/\*$1/;
        #make item element and add to over
        my $item =
          $self->mk_element('item')
          ->add_content( $self->mk_element('title')
              ->add_content(  $pod_parser->get_elements_from_text($line, 'list format')) ); #$self->mk_characters($line) 
     $over->add_content( $item)
    }
    return $over;
    #create POD2XML instance for parce pod sequences
    #    my $pod_parser = new Pod::ToDocBook::Pod2xml::;
    return undef;
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

