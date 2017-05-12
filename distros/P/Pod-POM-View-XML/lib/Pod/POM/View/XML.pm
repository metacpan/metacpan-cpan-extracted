package Pod::POM::View::XML;
BEGIN {
  $Pod::POM::View::XML::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: XML view of a Pod Object Model
$Pod::POM::View::XML::VERSION = '0.0.2';


use strict;

use Pod::POM::View;
use parent qw( Pod::POM::View );

use vars qw( $VERSION $DEBUG $ERROR $AUTOLOAD );

use PerlX::Maybe;
use XML::Writer 0.620;
use Escape::Houdini qw/ escape_xml /;


$DEBUG   = 0 unless defined $DEBUG;
my $HTML_PROTECT = 0;
my @OVER;

our $TAG_PREFIX = 'pod';
our %TAGS = qw/
        pod              pod

        head1          section
        head1_title    title
        head2          section
        head2_title    title
        head3          section
        head3_title    title
        head4          section
        head4_title    title

        over             over
        item             item
        item_title       title

        for              div
        begin            div

        textblock        para
        verbatim         preformated

        b                bold
        i                italic
        c                code
        f                file
        l                link

        index            index
/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_)
	|| return;

    # initalise stack for maintaining info for nested lists
    my %args = @_;

    $self->{ OVER } = [];
    $self->{tag_prefix} = exists $args{tag_prefix} ? $args{tag_prefix} : $TAG_PREFIX; 
    $self->{tags} = {
        %TAGS,
        %{ $args{tags} || {} },
    };

    return $self;
}

sub tag {
    my( $self, $pod ) = @_;

    return join '_', grep { $_ }
        ( ref $self ? $self->{tag_prefix} : $TAG_PREFIX ),
        ( ref $self ? $self->{tags}{$pod} : $TAGS{$pod} );
}

sub xml {
    XML::Writer->new( OUTPUT => 'self', NEWLINES => 1, UNSAFE => 1 );
}

sub view {
    my ($self, $type, $item) = @_;

    if ($type =~ s/^seq_//) {
	return $item;
    }
    elsif (UNIVERSAL::isa($item, 'HASH')) {
	if (defined $item->{ content }) {
	    return $item->{ content }->present($self);
	}
	elsif (defined $item->{ text }) {
	    my $text = $item->{ text };
	    return ref $text ? $text->present($self) : $text;
	}
	else {
	    return '';
	}
    }
    elsif (! ref $item) {
	return $item;
    }
    else {
	return '';
    }
}

sub view_pod {
    my ($self, $pod) = @_;

    my $xml = xml();

    $xml->startTag( $self->tag('pod') );
    $xml->raw( $pod->content->present($self) );
    $xml->endTag;

    $xml;
}


sub view_headn {
    my ($self, $head, $level) = @_;

    my $xml = xml();
    $xml->startTag( $self->tag( 'head'.$level ), head_level => $level );
    $xml->startTag( $self->tag( 'head'.$level.'_title') );
    $xml->raw( $head->title->present($self) );
    $xml->endTag;

    $xml->raw( $head->content->present($self) );

    $xml->endTag;

    $xml;
}

sub view_head1 { $_[0]->view_headn( $_[1], 1 ) }
sub view_head2 { $_[0]->view_headn( $_[1], 2 ) }
sub view_head3 { $_[0]->view_headn( $_[1], 3 ) }
sub view_head4 { $_[0]->view_headn( $_[1], 4 ) }


sub view_over {
    my( $self, $over ) = @_;

    if( my $items = $over->item() ) {
        return $self->view_over_items( $over, $items );
    }
    else {
        return $self->view_over_no_items( $over );
    }

}

sub view_over_items {
    my ($self, $over, $items) = @_;
    my ($strip, $type);

    my $first_title = $items->[0]->title();

    if ($first_title =~ /^\s*\*\s*/) {
	    # '=item *' => <ul>
	    $strip = qr/^\s*\*\s*/;
	}
	elsif ($first_title =~ /^\s*\d+\.?\s*/) {
	    # '=item 1.' or '=item 1 ' => <ol>
	    $strip = qr/^\s*\d+\.?\s*/;
        $type = 'numerical';
	}

    my $overstack = ref $self ? $self->{ OVER } : \@OVER;
    push @$overstack, $strip;

    my $xml = xml();

    $xml->startTag( $self->tag('over'), maybe 'type' => $type );

    $xml->raw( $over->content->present($self) );

    $xml->endTag;

    pop @$overstack;

    $xml;
}

sub view_over_no_items {
    my( $self, $over ) = @_;

    my $xml = xml();
    $xml->raw( $over->content->present($self) );

    $xml;
}


sub view_item {
    my ($self, $item) = @_;

    my $over  = ref $self ? $self->{ OVER } : \@OVER;
    my $title = $item->title();
    my $strip = $over->[-1];

    if (defined $title) {
        $title = $title->present($self) if ref $title;
        $title =~ s/$strip// if $strip;
    }

    my $xml = xml();
    $xml->startTag($self->tag('item'));
    if( $title ) {
        $xml->startTag($self->tag('title'));
        $xml->raw($title);
        $xml->endTag;
    }
    $xml->raw($item->content->present($self));
    $xml->endTag;

    $xml;
}


sub view_for {
    my ($self, $for) = @_;

    my $xml = xml();

    $xml->startTag($self->tag('for'), 'for' => $for->format );
    if( $for->format =~ /(ht|x)ml/ ) {
        $xml->raw($for->text);
    }
    else {
        $xml->characters($for->text);
    }
    $xml->endTag;

    $xml;
}

sub view_begin {
    my ($self, $begin) = @_;

    my $xml = xml();

    $xml->startTag($self->tag('begin'), for => $begin->format );

    $HTML_PROTECT++ if $begin->format =~ /\b(x|ht)ml\b/;
    $xml->raw( $begin->content->present($self) );
    $HTML_PROTECT-- if $begin->format =~ /\b(x|ht)ml\b/;

    $xml->endTag;

    $xml;
}

sub view_textblock {
    my ($self, $text) = @_;

    if( $HTML_PROTECT ) {
        return  $text . "\n";
    }

    my $xml = xml();

    $xml->startTag($self->tag('textblock'));
    $xml->raw( $text );
    $xml->endTag;

    $xml;
}


sub view_verbatim {
    my ($self, $text) = @_;

    my $xml = xml();

    $xml->startTag($self->tag('verbatim'));
    $xml->characters($text);
    $xml->endTag;

    $xml;

}


sub view_seq_bold {
    my ($self, $text) = @_;

    my $xml = xml();

    $xml->startTag( $self->tag('b') );
    $xml->raw( $text );
    $xml->endTag;

    $xml;
}


sub view_seq_italic {
    my ($self, $text) = @_;
    
    my $xml = xml();

    $xml->startTag( $self->tag('i') );
    $xml->raw( $text );
    $xml->endTag;

    $xml;
}


sub view_seq_code {
    my ($self, $text) = @_;

    my $xml = xml();

    $xml->startTag( $self->tag('c') );
    $xml->raw( $text );
    $xml->endTag;

    $xml;
}

sub view_seq_file {
    my ($self, $text) = @_;
    my $xml = xml();
    $xml->startTag( $self->tag('f') );
    $xml->raw( $text );
    $xml->endTag;

    $xml;
}

sub view_seq_space {
    my ($self, $text) = @_;
    $text =~ s/\s/&nbsp;/g;

    $text;

}


sub view_seq_entity {
    my ($self, $entity) = @_;

    "&$entity;";
}


sub view_seq_index {
    my( $self, $index ) = @_;

    my $xml = xml();
    $xml->startTag( $self->tag('index') );
    $xml->raw( $index );
    $xml->endTag;

    $xml;
}


sub view_seq_link {
    my ($self, $link) = @_;

    my $xml = xml();

    $xml->dataElement( $self->tag('l') => $link );
    
    $xml;
}

sub view_seq_text {
     my ($self, $text) = @_;

     if( $HTML_PROTECT ) {
         return $text;
     }

     return escape_xml( $text );
}

sub encode {
    my($self,$text) = @_;
    require Encode;
    return Encode::encode("ascii",$text,Encode::FB_XMLCREF());
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::POM::View::XML - XML view of a Pod Object Model

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use Pod::POM;
    use Pod::POM::View::XML;

    my $parser = Pod::POM->new;
    my $pom = $parser->parse_text( $some_pod );

    my $xml = Pod::POM::View::XML->print($pom);

=head1 DESCRIPTION

C<Pod::POM::View::XML> is a view that aims at
producing a direct XML rendition of the POD.

=head2 new(%options)

The constructor C<new()> accepts the following options.

=over

=item prefix

Prefix added to all tags. Defaults to C<pod> (so the 
xml tags will be C<pod_pod>, C<pod_section>, C<pod_para>, etc).
For no prefix, set to C<undef>. 

The global default value can be set via C<$Pod::POM::View::XML::TAG_PREFIX>.

=item tags

Mapping of the POD keywords to the xml tags. Tags that aren't
defined here will use the default mapping as given below.

The global defaults can also be set via C<%Pod::POM::View::XML::TAGS>.

The defaults (without prefix) are:

        POD              XML
        ----------       ---------
        pod              pod

        head*n*          section
        head*n*_title    title
        
        over             over
        item             item
        item_title       title
        
        for              div
        begin            div
        
        textblock        para
        verbatim         preformated

        b                bold
        i                italic
        c                code
        f                file
        l                link

        index            index

=back

=head1 SEE ALSO

=over

=item L<Pod::POM>

=item L<Pod::POM::View::DocBook>

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
