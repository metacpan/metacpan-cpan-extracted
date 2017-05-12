package Perl6::Pod::Lib::Image;

=pod

=head1 NAME

Perl6::Pod::Lib::Image - add image

=head1 SYNOPSIS

    =Image t/image.jpg
    =Image file:t/data/P_test1.png
    =for Image :title('Test image title')
    img/image.png

=head1 DESCRIPTION

The B<=Image> block is used for include image link.
For definition of the target file are used a URI:

    =Image t/image.jpg
    =Image file:../test.jpg
    =Image http://example.com/img.jpg

For set title of image add attribute B<:title> or define in Pod Link format:

    =for Image :title('test caption')
    t/data/P_test1.png
    =for Image
    test caption|t/data/P_test1.png
    

=back

=cut

use warnings;
use strict;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    #get only for one image
    my @lines = split( /[\n]/m, $self->childs->[0] );
    my $src = shift(@lines) || return;

    my $title = $self->get_attr()->{title};
    if ($src =~ /\|/) {
        ($title, $src) = split( /\s*\|\s*/, $src);
    }
    $self->{SRC} = $src;
    $self->{TITLE} = $title;
    $self;
}

sub _transalated_path {
    my $self   = shift;
    my $renderer = shift;
    my $path   = shift;

    #now translate relative addr
    if ( $path !~ /^\//
        and my $current = $renderer->context->custom->{src} )
    {
        my ( $file, @cpath ) = reverse split( /\//, $current );
        my $cpath = join "/", reverse @cpath;
        $path = $cpath ? $cpath . "/" . $path : $path;
    }
    return $path;
}

=head2 to_xhml

  <img src="boat.gif" alt="Big Boat" title="Big Boat"/>

=cut

sub to_xhtml {
    my ( $self, $to ) = @_;
    my $src = $self->{SRC};
    #local file ?
    if ( $src !~/http/ ) {
        $src =  $self->_transalated_path( $to, $self->{SRC} );
    }
    my $title = $self->{TITLE} ||'';
    $to->w->raw(qq%<img src="$src" alt="$title" title="$title" />%);
}

=head2 to_docbook

    <mediaobject>
        <imageobject>
            <imagedata align='center' 
                        caption='test' 
                        format='PNG' 
                        valign='bottom' 
                        scalefit='1' 
                        fileref='t/data/P_test1.png' />
        </imageobject>
        <caption>test</caption>
     </mediaobject>

=cut
sub to_docbook {
    my ( $self, $to ) = @_;
    my $src = $self->{SRC};
    #local file ?
    if ( $src !~/http/ ) {
        $src =  $self->_transalated_path( $to, $self->{SRC} );
    } else {
        warn "Only images from local filesystem supported" ;
    }
    my $ext = "JPG";
    if ( $src =~ /\.(\w+)$/ ) {
        $ext = uc($1);
    }

    my $w = $to->w;
    my $title = $self->{TITLE} || '';
    $w->raw(<<"T");
    <mediaobject>
        <imageobject>
            <imagedata align='center' 
                        caption='$title' 
                        format='$ext' 
                        valign='bottom' 
                        scalefit='1' 
                        fileref='$src' />
        </imageobject>
        
T
    $w->raw('<caption>')->print($title)->raw('</caption>');
    $w->raw('</mediaobject>');
}
1;
