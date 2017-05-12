package Pod::ToDocBook::Pod2xml;

#$Id: Pod2xml.pm 695 2010-01-18 17:48:33Z zag $

=head1 NAME

Pod::ToDocBook::Pod2xml - Converter POD data to XML::ExtON events.

=head1 SYNOPSIS

    use XML::ExtOn ('create_pipe');
    use Pod::ToDocBook::Pod2xml;
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p = create_pipe( $px, $w );
    $p->parse($text);
    return $buf;
    
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter', base_id=>'namespace';

=head1 DESCRIPTION


Pod::ToDocBook::Pod2xml - Converter POD data to XML::ExtON events.

=head1 XML FORMAT

=over 

=item * =begin, =end, =for

pod:

    =begin table params, params

        some text

    =end

xml:

    <begin params='params, params' name='table'><![CDATA[some text
 
     ]]></begin>
    
pod:

    =for someformat text

xml:

    <begin params='' name='someformat'><![CDATA[text
 
     ]]>

=back

=cut

use warnings;
use strict;
use Pod::Parser;
use Data::Dumper;
use Test::More;
use XML::ExtOn;
use base 'Pod::Parser', 'XML::ExtOn';

sub parse {
    my ( $self, $fd ) = @_;
    unless ( ref $fd ) {
        $fd = new str2fd:: $fd;
    }
    else {
        if ( ref($fd) eq 'SCALAR' ) {
            $fd = new str2fd:: $$fd;
        }
    }
    return $self->parse_from_filehandle($fd);
}

sub new {
    my $self = XML::ExtOn::new(@_);
    return $self;
}

sub begin_input {
    my $parser = shift;
    $parser->start_document;
    if ( $parser->{header} ) {
        $parser->start_dtd(
            {
                Name     => $parser->{doctype},
                PublicId => '-//OASIS//DTD DocBook V4.2//EN',
                SystemId =>
                  'http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd'
            }
        );
        $parser->end_dtd;
    }

    #create root element
    my $root = $parser->mk_element( $parser->{doctype} );
    $root->{ROOT}++;
    $parser->start_element($root);
}

sub end_input {
    my $parser = shift;
    my $self   = $parser;
    while ( $self->_current ) {

        #diag "end Element: ". $self->_current->local_name;
        #flush last element from stack
        $self->_process( $self->pop_elem );
    }
    unless ( exists $parser->current_element->{ROOT} ) {

        #diag "end Element: $parser->current_element->{ROOT}";
        $parser->end_element();
    }

    #diag "end Element: $parser->{doctype}";
    $parser->end_element( $parser->mk_element( $parser->{doctype} ) );
    $parser->end_document;
}

#L<text|name/" sd|sd | ">
#L<text|scheme:...>
#type

=head2 parse_link Ltext

types:

    pod
        L<text> 
        L<text::test>
    man
        L<text(3)>

    url
        L<text|http://example.com>
        L<http://example.com>
=cut

sub parse_link {
    my $self = shift;
    my $text = shift;

    #clean
    $text =~ s/^\w<(.*)>$/$1/;
    $text =~ s/\s+/ /g;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    my $type = 'pod';
    my ( $ltext, $linkto );
    if ( $text =~ /\|/ ) {

        # text|name/" sd|sd | "
        my ( $t1, @linkto ) = split( /\|/, $text );
        ( $ltext, $linkto ) = ( $t1, join "", @linkto );

        #( $ltext, $linkto ) = split( /\|/, $text, 2 );

    }
    else {
        $ltext = $text;
    }
    if ( $ltext =~ /\A\w+:[^:\s]\S*\Z/ ) {
        $linkto = $ltext;
    }
    $linkto ||= '';
    if ( $linkto =~ /\A\w+:[^:\s]\S*\Z/ ) {
        return { type => 'url', text => $ltext, linkto => $linkto };
    }

    #now nandle man an pod types
    my ( $base_id, $section ) = _parse_section( $linkto ? $linkto : $ltext );

    #for L<"pod section">
    unless ($linkto) {

        #may be L<man(1)>
        $ltext = $section if $section;
    }

    #make destanation id
    $linkto = $self->_make_id( $section, $base_id );
    $type = 'man' if ( $ltext =~ /\(\S*\)/ );
    return {
        type    => $type,
        text    => $ltext,
        linkto  => $linkto,
        base_id => $base_id,
        section => $section
    };
}

# Parse the name and section portion of a link into a name and section.
sub _parse_section {
    my ($link) = @_;
    $link =~ s/^\s+//;
    $link =~ s/\s+$//;

    # If the whole link is enclosed in quotes, interpret it all as a section
    # even if it contains a slash.
    return ( undef, $1 ) if ( $link =~ /^"\s*(.*?)\s*"$/ );

    # Split into page and section on slash, and then clean up quoting in the
    # section.  If there is no section and the name contains spaces, also
    # guess that it's an old section link.
    my ( $page, $section ) = split( /\s*\/\s*/, $link, 2 );
    $section =~ s/^"\s*(.*?)\s*"$/$1/ if $section;
    if ( $page && $page =~ / / && !defined($section) ) {
        $section = $page;
        $page    = undef;
    }
    else {
        $page    = undef unless $page;
        $section = undef unless $section;
    }
    return ( $page, $section );
}

sub get_elements_from_text {
    my ( $parser, $text, $line_num ) = @_;
    my @childs = ();

    #process paragrapth
    if ( my $root = $parser->parse_text( $text, $line_num ) ) {
        foreach my $node ( $root->children ) {
            unless ( ref($node) ) {
                push @childs, $parser->mk_characters($node);
            }
            else {
                my $elem = $parser->mk_element('code');
                my $attr = $elem->attrs_by_name;

                #handle L
                if ( $node->cmd_name() eq 'L' ) {
                    my $lattr = $parser->parse_link( $node->raw_text );
                    %{$attr} = %{$lattr};
                }
                $attr->{name} = $node->cmd_name();

                #set content
                $elem->{TITLE}    = $node->raw_text;
                $elem->{LINE_NUM} = $line_num;
                $elem->add_content( $parser->mk_cdata( $node->raw_text ) );
                push @childs, $elem;
            }
        }
    }
    return @childs;
}

sub stack {
    my $self = shift;
    $self->{STACK} = [] unless exists $self->{STACK};
    return $self->{STACK};
}

sub push_elem {
    my ( $self, $elem ) = @_;
    push @{ $self->stack }, $elem;
}

sub pop_elem {
    my ( $self, $elem ) = @_;
    pop @{ $self->stack };
}

sub _current {
    my $self = shift;
    return $self->stack->[-1];
}

#process levels
# $self->_process( <element> )
sub _process {
    my $self = shift;
    my ($elem) = @_;
#    warn "process ". $elem . "at " . $elem->local_name;
#    warn (ref($elem) eq 'HASH') ?  $elem->{type} : $elem->local_name;

    #get element for current level
    if ( my $current = $self->_current ) {
        $current->add_content($elem);
    }
    else {
        $self->start_element($elem);
        $self->end_element($elem);

    }

}

sub _start_elem {
    my ( $self, $elem ) = @_;
    $self->push_elem($elem);
}

sub _stop_elem {
    my ( $self, $elem ) = @_;
    if ( my $current = $self->pop_elem ) {
        if ($elem) {

            #check stack
            my $open_name  = $current->local_name;
            my $close_name = $elem->local_name;
            die
"Stack error: got unexpected: $elem->{COMMAND} at line: $elem->{LINE_NUM}"
              . ". In stack: $current->{COMMAND} ( from line: $current->{LINE_NUM} )"
              unless $open_name eq $close_name;
        }

        #special handle format tag
        if ( $current->local_name eq 'begin' ) {
            if ( my $cdata = delete $current->{TEXT_BLOCK} ) {
                $current->add_content( $self->mk_cdata($cdata) );
            }
        }
        $self->_process($current);
    }

}

sub command {
    my ( $parser, $command, $paragraph, $line_num ) = @_;
    my $self = $parser;
    $paragraph =~ s/\s+$//ms if defined $paragraph and $command ne 'for';
    my $elem = $parser->mk_element($command);

    #save para at element
    $elem->{TITLE}    = $paragraph;
    $elem->{LINE_NUM} = $line_num;
    $elem->{COMMAND}  = $command;
    $elem->{ID}       = $self->_make_uniq_id($paragraph);

    #    =begin html string
    #    adasdasd
    #    =end
    #convert to
    #    <format name="html" params=>"string">
    #        adasdasd
    #    </format>

    #special handle format tags begin and for
    # =begin   =for
    # =end
    if ( $command =~ /^begin|for$/ ) {
        $elem = $parser->mk_element('begin');
        my $attr = $elem->attrs_by_name;
        my ( $format_name, $format_params ) =
          $paragraph =~ m/\s*(\w+)(?:\s+?(.*))?$/gis;
        $attr->{name} = $format_name;
        if ( $command eq 'for' ) {
            my $content = $format_params;
            $format_params = '';
            $elem->add_content( $parser->mk_cdata($content) );
        }
        $attr->{params} = $format_params;
        $self->_start_elem($elem);
        if ( $command eq 'for' ) {
            $self->command( 'end', $format_name, $line_num );
        }
    }
    elsif ( $command eq 'end' ) {
        $elem->local_name('begin');
        $self->_stop_elem($elem);

    }
    elsif ( $command =~ /head(\d)/ ) {

        #if
        my $to_level = $1;

        #get current level from head from stack
        my $current_head =
          $self->_current ? $self->_current->local_name : "NONE";
        my ($current_level) = $current_head =~ /head(\d+)/;
        unless ( defined $current_level ) {

            #diag 'no current level for' . $current_head;
            die "check syntax before line $line_num for command: $current_head"
              unless $current_head =~ /^NONE|pod$/;
            $current_level = 0;
        }

        my $title = $parser->mk_element('title');
        $title->add_content(
            $parser->get_elements_from_text( $paragraph, $line_num ) );
        $elem->add_content($title);
        if ( $current_level < $to_level ) {

            #up level
            #=head1
            #=head2
            #set current stack
            die
"found step more then 1 level near =head$to_level at line: $line_num "
              if $to_level - $current_level > 1;
            $self->_start_elem($elem);
        }
        elsif ( $current_level == $to_level ) {
            $self->_stop_elem( $self->_current );

            #set current head at stack
            $self->_start_elem($elem);
        }
        else {

            # $current_level > $to_level
            #=head2
            #=head3
            #=head1
            #flush levels
            for ( 0 .. $current_level - $to_level ) {
                $self->_stop_elem( $self->_current );
            }
            $self->_start_elem($elem);
        }
    }
    elsif ( $command eq 'item' ) {
        my $cur_elem = $self->_current;
        unless ($cur_elem) {
            die "error near line: $line_num : =item not in over";
        }
        my $cur_name = $cur_elem->local_name;
        if ( $cur_name eq 'item' ) {
            $self->_stop_elem( $self->mk_element('item') );
        }
        elsif ( $cur_name ne 'over' ) {
            die "error near line: $line_num : =item not in over";
        }
        my $title = $parser->mk_element('title');
        $title->add_content(
            $parser->get_elements_from_text( $paragraph, $line_num ) );
        $elem->add_content($title);
        $self->_start_elem($elem);

    }
    elsif ( $command =~ /^over|pod$/ ) {
        $self->_start_elem($elem);
    }
    elsif ( $command eq 'back' ) {

        #close previus item
        my $current = $self->_current;
        if ( $current && $current->local_name eq 'item' ) {
            $self->_stop_elem($current);
        }
        $elem->local_name('over');
        $self->_stop_elem($elem);
    }
    elsif ( $command eq 'cut' ) {
        $elem->local_name('pod');

        #diag "Close!!";
        #die "aaa";
        $self->_stop_elem($elem);

    }
    else {
        die "Not handled tag $command : $paragraph";
    }
}

sub verbatim {
    my ( $parser, $paragraph, $line_num ) = @_;
    if ( $parser->_current && $parser->_current->local_name eq 'begin' ) {
        $parser->_current->{TEXT_BLOCK} .= $paragraph;
        return undef;
    }
    my $elem =
      $parser->mk_element('verbatim')
      ->add_content( $parser->mk_cdata($paragraph) );
    $parser->_process($elem);
}

sub textblock {
    my ( $parser, $paragraph, $line_num ) = @_;
    unless ( $parser->_current && $parser->_current->local_name eq 'begin' ) {
        $paragraph =~ s/\s+$//ms;
    }
    else {
        $parser->_current->{TEXT_BLOCK} .= $paragraph;
        return undef;
    }
    my $elem =
      $parser->mk_element('para')
      ->add_content( $parser->get_elements_from_text( $paragraph, $line_num ) );
    $parser->_process($elem)

}

=head2 _make_id($text[, $base_id])

Function will construct an element id string. Id string is composed of
C<< join (':', $base_id || $parser->{base_id} , $text) >>, where C<$text> in most cases
is the pod heading text.

The xml id string has strict format. Checkout L</"cleanup_id"> function for
specification.

=cut

sub _make_id {
    my $parser  = shift;
    my $text    = shift || '';
    my $base_id = shift || $parser->{base_id} || '';

    # trim text spaces
    $text    =~ s/^\s*//xms;
    $text    =~ s/\s*$//xms;
    $base_id =~ s/^\s*//xms;
    $base_id =~ s/\s*$//xms;

    return _cleanup_id( join( ':', $base_id, $text ) );
}

=head2 _make_uniq_id($text)

Calls C<< $parser->make_id($text) >> and checks if such id was already
generated. If so, generates new one by adding _i1 (or _i2, i3, ...) to the id
string. Return value is new uniq id string.

=cut

sub _make_uniq_id {
    my $parser = shift;
    my $text   = shift;

    my $id_string = $parser->_make_id($text);

    # prevent duplicate ids
    my $ids_used = $parser->{'ids_used'} || {};
    while ( exists $ids_used->{$id_string} ) {
        if ( $id_string =~ m/_i(\d+)$/xms ) {
            my $last_used_id_index = $1;
            substr(
                $id_string,         0 - length($last_used_id_index),
                length($id_string), $last_used_id_index + 1
            );
        }
        else {
            $id_string .= '_i1';
        }
    }
    $ids_used->{$id_string} = 1;
    $parser->{'ids_used'} = $ids_used;

    return $id_string;
}

=head2 _cleanup_id($id_string)

This function is used internally to remove/change any illegal characters
from the elements id string. (see http://www.w3.org/TR/2000/REC-xml-20001006#NT-Name
for the id string specification)

    $id_string =~ s/<!\[CDATA\[(.+?)\]\]>/$1/g;   # keep just inside of CDATA
    $id_string =~ s/<.+?>//g;                     # remove tags
    $id_string =~ s/^\s*//;                       # ltrim spaces
    $id_string =~ s/\s*$//;                       # rtrim spaces
    $id_string =~ tr{/ }{._};                     # replace / with . and spaces with _
    $id_string =~ s/[^\-_a-zA-Z0-9\.: ]//g;       # closed set of characters allowed in id string

In the worst case when the C<$id_string> after clean up will not conform with
the specification, warning will be printed out and random number with leading colon
will be used.

=cut

sub _cleanup_id {
    my $id_string = shift;

    $id_string =~ s/<!\[CDATA\[(.+?)\]\]>/$1/gxms;   # keep just inside of CDATA
    $id_string =~ s/<.+?>//gxms;                     # remove tags
    $id_string =~ s/^\s*//xms;                       # ltrim spaces
    $id_string =~ s/\s*$//xms;                       # rtrim spaces
    $id_string =~ tr{/ }{._};    # replace / with . and spaces with _
    $id_string =~ s/[^\-_a-zA-Z0-9\.:\s]//gxms
      ;                          # closed set of characters allowed in id string

# check if the id string is valid (SEE http://www.w3.org/TR/2000/REC-xml-20001006#NT-Name)
# TODO refactor to the function, we will need if also later and some tests will be handfull
#      we should also "die" if the base_id is set through the command line parameter
    if ( $id_string !~ m/^[A-Za-z_:] [-A-Za-z0-9_.:]*/xms ) {
        $id_string = q{:} . _big_random_number();
        warn 'wrong xml id string "', $id_string, '", throwing away and using ',
          $id_string, ' instead!', "\n";
    }

    return $id_string;
}

sub _big_random_number {
    ## no critic ValuesAndExpressions::ProhibitMagicNumbers
    return int( rand(9e10) + 10e10 );
    ## use critic
}

1;

package str2fd;
use strict;
use warnings;

sub new {
    my ( $pkg, $str ) = @_;
    my $self = bless { str => [ split /\n/, $str ] }, $pkg;
    return $self;
}

sub getline {
    my $self = shift;
    my $arr  = $self->{str};
    return undef unless scalar(@$arr);
    return ( shift(@$arr) ) . "\n";
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

