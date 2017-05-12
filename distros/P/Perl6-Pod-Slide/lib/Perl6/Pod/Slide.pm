#===============================================================================
#
#  DESCRIPTION:  Make presentations
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
package Perl6::Pod::Slide::Writer;
use Perl6::Pod::Writer;
use base 'Perl6::Pod::Writer';
use strict;
use warnings;
sub print {
    my $self = shift;
    my $fh = $self->o;
#    if (my $type = $self->{escape}) {
#        my $str = join ""=>@_;
#        print $fh ($type eq 'xml') ? _xml_escape($str) : _html_escape($str);
#        return $self
#    }
    print $fh @_;
    $self
}
sub start_nesting {
    my $self = shift;
    my $level = shift || 1 ;
    $self->raw('<blockquote>') for (1..$level);
}
sub stop_nesting {
    my $self = shift;
    my $level = shift || 1 ;
    $self->raw('</blockquote>') for (1..$level);
}

package Perl6::Pod::Slide;

=head1 NAME

Perl6::Pod::Slide - make slides easy

=head1 SYNOPSIS

Create Perl6 Pod file:

 =for DESCRIPTION :title('Perl6 Pod:How it made')
 = :author('Aliaksandr Zahatski') :pubdate('2 jul 2010')
 =config Image :width('2in')

 =begin Slide
 Using B<:pause> attribute
 =for item :numbered
 Item1
 =for item :numbered :pause
 Item2
 =for item :numbered
 Item3
 =end Slide
 

Convert pod file to tex:

  pod6slide < tech_docs.pod > tech_docs.tex

To pdf:

  pdflatex tech_docs.tex

Example for add image:

 =begin Slide :title('Test code')
 Flexowriter
 =for Image :width('2.5in')
 img/pdp1_a.jpg
 =end Slide

Example for programm code listing:

 =begin code :lang('Perl')
  sub print_export {
    my $self = shift;
    push @_, "\n";
    return $self->SUPER::print_export(@_);
  }
 =end code

or some other languages : C<PHP>,C<bash>,C<HTML>,C<Java>,C<Python>,
C<SQL>,C<XSLT>,C<XML>,C<Lisp>,C<Ruby>,C<erlang>, C<TeX> ...

=head1 DESCRIPTION

Perl6::Pod::Slide - make slides easy

=head1 METHODS

=cut
use Perl6::Pod::To::Latex;
use base 'Perl6::Pod::To::Latex';
use Perl6::Pod::Utl;
use strict;
use warnings;
use Data::Dumper;
use File::Temp qw/ tempfile /;

$Perl6::Pod::Slide::VERSION = '0.10';

sub new {
    my $class = shift;
    my %args = @_;

    my $writer = new  Perl6::Pod::Slide::Writer::
             out => ( $args{out} || \*STDOUT );
    return $class->SUPER::new(@_,writer=>$writer, format=>'latex')
#    return $class->SUPER::new(@_, writer)
}
sub start_write {
    my $self = shift;
    $self->w->raw(<<'HEAD') if $self->{headers};
% maked by p5-Perl6-Pod-Slide
%
\documentclass{beamer}
\useinnertheme{rectangles}
\setbeamercolor{rectangles}{bg=violet!12,fg=black}

\usetheme{default}
\setbeamertemplate{blocks}[rounded][shadow=true] 
\useoutertheme[footline=authortitle]{miniframes}
\usetheme[height=7mm]{Rochester}
%\useoutertheme{umbcfootline} 
\usepackage{listings}

\usepackage[T2A]{fontenc}
\usepackage[utf8]{inputenc}
\setbeamertemplate{items}[ball] 
\setbeamertemplate{navigation symbols}{} 

% insert for eps
\ifx\pdftexversion\undefined
\usepackage[dvips]{graphicx}
\else
\usepackage{graphicx}
\DeclareGraphicsRule{*}{mps}{*}{}
\fi

\lstdefinelanguage{JavaScript}{
keywords={typeof, new, true, false, catch, function, return, null, catch, switch, var, if, in, while, do, else, case, break},
keywordstyle=\color{blue}\bfseries,
ndkeywords={class, export, boolean, throw, implements, import, this},
ndkeywordstyle=\color{darkgray}\bfseries,
identifierstyle=\color{black},
sensitive=false,
comment=[l]{//},
morecomment=[s]{/*}{*/},
commentstyle=\color{purple}\ttfamily,
stringstyle=\color{red}\ttfamily,
morestring=[b]',
morestring=[b]"
}

% Permet l'ajout de code par insertion du fichier le contenant
% Coloration + ajout titre
% Les arguments sont :
% $1 : titre associИ Ю l'extrait de code
% $2 : nom du fichier Ю inclure
% $3 : le type de langage (C++, C, Java ...)
\newcommand{\addCode}[2]{%

  % Configuration de la coloration syntaxique du code
  \definecolor{colKeys}{rgb}{0,0,1}
  \definecolor{colIdentifier}{rgb}{0,0,0}
  \definecolor{colComments}{rgb}{0,0.5,1}
  \definecolor{colString}{rgb}{0.6,0.1,0.1}

  % Configuration des options
  \lstset{%
    language = #2,%
    identifierstyle=\color{colIdentifier},%
    basicstyle=\ttfamily\scriptsize, %
    keywordstyle=\color{colKeys},%
    stringstyle=\color{colString},%
    commentstyle=\color{colComments},%
    columns = flexible,%
    %tabsize = 8,%
    showspaces = false,%
    numbers = left, numberstyle=\tiny,%
    frame = single,frameround=tttt,%
    breaklines = true, breakautoindent = true,%
    captionpos = b,%
    xrightmargin=10mm, xleftmargin = 15mm, framexleftmargin = 7mm,%
  }%
    \begin{center}
    \lstinputlisting{#1}
    \end{center}
}

HEAD
}


sub block_Pause {
    my $self = shift;
    $self->w->say('\pause');
}

sub block_Latex {
    my $self = shift;
    my $el   = shift;
    $self->w->say($el->childs->[0]);
}

sub block_code {
    my $self  =shift;
    my $el = shift;
    # =for code :lang('Perl')
    # convert to 
    #\addCode{ TMP_FILE }{Perl}
    my $pod_attr = $el->get_attr;
    my $w = $self->writer;
    if (my $lang = $pod_attr->{lang} ) {
          #make temporary file      
      my ( $fh, $filename ) = tempfile(TEMPLATE => 'slidesXXXXX',
                                    SUFFIX => '.tmp');
        binmode( $fh, ":utf8" );      
        print $fh $el->childs->[0];
      $w->raw("\n\\addCode{ $filename }{$lang} ");
      return 
    }
    if ( my $allow = $el->get_attr->{allow} ) {
        $el->{content} =
          Perl6::Pod::Utl::parse_para( $el->childs->[0], allow => $allow );
    }
    $w->say('\begin{verbatim}');
    $self->visit_childs($el);
    $w->say('\end{verbatim}');
}

=head2 block_Slide

    =begin Slide :title('Asd') 
    = :backimage('img/297823712_f8e59447a5_z.jpg')
    = :valign(t)  :valign(c) :valign(b)

=cut
sub block_Slide {
    my $self = shift;
    my $el   = shift;
    my $w = $self->writer;
    my $pod_attr = $el->get_attr;
    #fill backimage
    #http://tex.stackexchange.com/questions/7916/
    my $if_enclosed = 0;
    if ( my $backimage = $pod_attr->{backimage} ){
        $if_enclosed = 1;
        $w->say('{');
#        $w->say('\usebackgroundtemplate{\includegraphics[width=\paperwidth]{'
#        .$backimage.'}}');

        $w->say('\usebackgroundtemplate{
\vbox to \paperheight{\vfil\hbox to \paperwidth{\hfil\includegraphics[width=\paperwidth]{'.$backimage.'}\hfil}\vfil}}');
    }
    if (my $valign = $pod_attr->{valign}) {
        $w->say("\\begin{frame}[$valign]");
    } else {
        $w->say("\\begin{frame}[fragile]");
    }
    if ( my $title = $pod_attr->{title} ) {
        $title = join "" => @$title if ref($title);
        $w->say("\\frametitle{$title}");
    }
#    warn "====Start parse" . $el->childs->[0];
#    use Data::Dumper;die Dumper (Perl6::Pod::Utl::parse_pod($el->childs->[0], default_pod=>1)) if $el->childs->[0] =~/asdasdasdasd/;
    $self->visit(Perl6::Pod::Utl::parse_pod($el->childs->[0], default_pod=>1));
    $w->say("\\end{frame}");
    if ($if_enclosed) {
        $w->say('}');
    }
}

=head2 Image

 \begin{figure}[h]
  \begin{center}
  \includegraphics[height=5cm,width=90mm]{leaves.jpg}
 \end{center}
  \caption{Caption of the image}
 \label{leave}
 \end{figure}
            

=cut

sub block_Image {
    my $self      = shift;
    my $el        = shift;
    my $pod_attr  = $el->get_attr;
    my @size_attr = ();
    if ( my $height = $pod_attr->{height} ) {
        push @size_attr, "height=$height";
    }
    if ( my $width = $pod_attr->{width} ) {
        push @size_attr, "width=$width";
    }
    my $iattr = "";
    if (@size_attr) {
        $iattr = "[" . join( "=", @size_attr ) . "]";
    }
    #add $caption;
    my $ititle="";
    if ( my $title = $pod_attr->{title} ) {
        $ititle='\caption{'.$title.'}'
    }
   my $image     = $el->childs->[0];
   chomp $image;
     $self->w->raw('
\begin{figure}[!ht]
  \begin{center}
  \includegraphics' . $iattr . '{' . ${image} . '}
\end{center}'.$ititle.'
\label{leave}
\end{figure}
');


}

sub code_B {
    my $self = shift;
    my $el   = shift;
    $self->w->raw("\\textbf{");
    $self->visit_childs($el);
    $self->w->raw("}");
}

sub code_I {
    my $self = shift;
    my $el   = shift;
    $self->w->raw("\\emph{");
    $self->visit_childs($el);
    $self->w->raw("}");
}

sub block_DESCRIPTION {
    my $self     = shift;
    my $el       = shift;
    my $w  = $self->w;
    my $pod_attr = $el->get_attr;
    my $title = $pod_attr->{title};
    if ( ref($title) ) {
        $title = join "" => @$title;
    }
    $w->say( "\\title{$title}" );
    my $author_txt =
      exists $pod_attr->{author}
      ? $pod_attr->{author}
      : "Unknown author. Use :author('My name')";
    $w->say("\\author{$author_txt}");

    my $pubdate =
      exists $pod_attr->{pubdate}
      ? $pod_attr->{pubdate}
      : '\today';
    $w->say("\\date{$pubdate}");
}

=head2 

 =for para :bg<white> :color<black>


=cut
sub block_para {
    my ( $self, $el ) = @_;
    my $attr = $el->get_attr;
    my $to_close = 0;
    if (my $bgcolor = $attr->{bg})  {
        ++$to_close;
        $self->w->say('\colorbox{'.$bgcolor.'} {')
    }
    if (my $txtcolor = $attr->{color})  {
        ++$to_close;
        $self->w->say('\textcolor{'.$txtcolor.'} {')
    }

    $self->visit(Perl6::Pod::Utl::parse_para($el->childs->[0]) );

    if ($to_close) {
        $self->w->say('}') for (1..$to_close);
    }
    $self->w->say('');
}
=head2 Items

For make puse after item  add B<pause> attribute
    =for item :numbered :pause
    One
    =for item :numbered :pause
    Two

=cut
sub block_defn {
    my $self = shift;
    $self->block_item(@_);
}

sub block_item {
    my ( $self, $el, $prev, $next ) = @_;
    my $w = $self->w;

    my ( $list_name, $items_name ) = @{
        {
            ordered    => [ 'enumerate',  'item' ],
            unordered  => [ 'itemize', 'item' ],
            definition => [ 'description', 'item' ]
        }->{ $el->item_type }
      };
    if (!$prev || $el->get_item_sign($prev) ne $el->get_item_sign($el) ) {
        #nesting first (only 2> )
        unless (exists $el->get_attr->{nested}) {
            my $tonest = $el->item_level - 1 ;
            $w->start_nesting(  $tonest  ) if $tonest;
        }

    $w->say('\begin{' . $list_name . '}');
    }

    $w->raw('\item');

    if ( $el->item_type eq 'definition' ) {
        $w->raw('[');
        $self->visit( Perl6::Pod::Utl::parse_para( $el->{term} ) );
        $w->raw(']')

    }
    $w->raw(' ');#space

    #parse first para
    $el->{content}->[0] =
      Perl6::Pod::Utl::parse_para( $el->{content}->[0] );
    $self->visit_childs($el);
    if ( $el->get_attr->{pause} ) {
        $w->say('\pause');
    }

    if (!$next || $el->get_item_sign($next) ne $el->get_item_sign($el) ) {
        $w->say('\end{' . $list_name . '}');
        unless (exists $el->get_attr->{nested}) {
            my $tonest = $el->item_level - 1  ;
            $w->stop_nesting(  $tonest  ) if $tonest;
        }

    }

}

sub end_write {
    my $self = shift;
    $self->w->say('\end{document}') if $self->{headers};
}

=head1 SEE ALSO

Perl6::Pod, Perl6::Pod::Lib::Include, Perl6::Pod::Lib::Image

L<http://perlcabal.org/syn/S26.html>

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

