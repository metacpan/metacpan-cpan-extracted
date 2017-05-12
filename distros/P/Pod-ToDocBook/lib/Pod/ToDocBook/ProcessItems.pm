package Pod::ToDocBook::ProcessItems;

#$Id: ProcessItems.pm 695 2010-01-18 17:48:33Z zag $

=head1 NAME

Pod::ToDocBook::ProcessItems - Process POD lists.

=head1 SYNOPSIS


    use Pod::ToDocBook::Pod2xml;
    use XML::ExtOn ('create_pipe');
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p = create_pipe(
        $px, qw( Pod::ToDocBook::ProcessItems ),
        $w
    );
    $p->parse($text);

=head1 DESCRIPTION

Pod::ToDocBook::ProcessItems - Process POD lists.

  * process over and items
  * set >blockqoute> for <para> inside <over>
  * delete <over>

=cut

use warnings;
use strict;
use Data::Dumper;
use Test::More;
use XML::ExtOn;
use base 'XML::ExtOn';

sub _process_item {
    my ( $self, $elem ) = @_;
    my $attr      = $elem->attrs_by_name;
    my $paragraph = $elem->{TITLE};

    #default item type
    my $list = 'ilist';

    #check if first item
    unless ( exists $self->{IN_LISTE} ) {

        #now determine type of list
        if ( !defined($paragraph) || $paragraph =~ /^\s*$/s ) {

            #itemized
            $list = 'ilist';
        }
        elsif ( $paragraph =~ /^([1aAiI\*])\.?/ ) {
            my $numeration = {
                1   => 'arabic',
                a   => 'loweralpha',
                A   => 'upperalpha',
                i   => 'lowerroman',
                I   => 'upperroman',
                '*' => 'itemized'
            }->{$1};
            if ( $1 ne '*' ) {
                $list = 'olist';

                #$elem->attrs_by_name->{numeration} = $numeration;
                $elem->{NUMERATION} = $numeration;
            }

        }
        else {
            $list = 'vlist';
        }
        $elem->{TYPE} = $list;
    }
    return $elem;

}

sub on_start_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;
    #warn "start: $lname:";
    my $cname =
      $self->current_element ? $self->current_element->local_name : '';
    my $attr = $el->attrs_by_name;
    my @res  = ($el);
    if ( $lname eq 'item' ) {
        $el = $self->_process_item($el);
        unless ( exists $self->{IN_LIST} ) {

            #get type of list
            my $type = $el->{TYPE};
            my $name = {
                ilist => 'itemizedlist',
                olist => 'orderedlist',
                vlist => 'variablelist'
            }->{$type};
            my $start_elem = $el->mk_element($name);
            if ( $type eq 'olist' and my $num = $el->{NUMERATION} ) {
                $start_elem->attrs_by_name->{numeration} = $num;
            }
            $self->{LIST_ELEMENT} = $start_elem;

            #$el->insert_to($start_elem);
            #warn "mk start ".$start_elem->local_name;
            @res = ( $self->mk_start_element($start_elem), $el );
            $self->{IN_LIST} = $type;
        }
        my $name = {
            ilist => 'listitem',
            olist => 'listitem',
            vlist => 'varlistentry'
        }->{ $self->{IN_LIST} };
        $el->local_name($name)

    }
    elsif ($lname eq 'title'
        && $cname =~ /^varlistentry|listitem$/ )
    {
        $el->local_name( $cname eq 'varlistentry' ? 'term' : 'para' );
        if ( $cname eq 'varlistentry' ) {
            $el->local_name('term');
        }

        #clean paragraph from first sym
        $el->{CLEAN_FIRST} = 1;
    }
    elsif ( $lname eq 'over' ) {
        $el->delete_element;
    }
    elsif ( $lname eq 'para' && $self->current_element->local_name eq 'over' ) {
        $el->insert_to( $self->mk_element('blockquote') )

    }

    #<varlistentry> .. <listitem> <para>text</para> ..</listitem></varlistentry>
    elsif ($lname =~ /para|verbatim/
        && $cname eq 'varlistentry'
        && !exists $self->{NEED_CLOSE_LISTITEM} )
    {
        my $entry = $el->mk_element('listitem');
        $self->{NEED_CLOSE_LISTITEM} = $entry;
        unshift @res, $self->mk_start_element($entry);
    }

    \@res;
}

sub on_end_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;
    #warn "end: $lname:";
    my $cname =
      $self->current_element ? $self->current_element->local_name : '';
    if ( $lname eq 'over' && exists $self->{IN_LIST} ) {

        #cleanup list variables
        delete $self->{IN_LIST};
        my $list_elem = delete $self->{LIST_ELEMENT};

        #warn "mk end ". $list_elem->local_name;
        return [ $self->mk_end_element($list_elem), $el ];
    }
    if ( $lname eq 'varlistentry' and exists $self->{NEED_CLOSE_LISTITEM} ) {
        my $entry = delete $self->{NEED_CLOSE_LISTITEM};
        return [ $self->mk_end_element($entry), $el ];
    }
    $el;
}

sub on_characters {
    my ( $self, $el, $txt ) = @_;
    if ( exists $el->{CLEAN_FIRST} ) {

        #clean paragraph from first sym
        for ( $self->{IN_LIST} ) {
            /olist/      && do { $txt =~ s/^[\d\w]+\.?\s+// }
              || /ilist/ && do { $txt =~ s/^\*\.?(\s+)?// }
        }
    }
    return $txt;

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

