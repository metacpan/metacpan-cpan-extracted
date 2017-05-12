package Solstice::StripScripts;

#the sub names are predetermined by the superclass, which isn't our code.
#let's ignore the underscore naming they use
## no critic (RequireCamelCaseSubs)

# $Id: StripScripts.pm 3387 2006-05-18 00:17:59Z jlaney $

=head1 NAME

Solstice::StripScripts - A subclass of HTML::StripScripts that contains our customized whitelists

=head1 SYNOPSIS

  use Solstice::StripScripts;

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use HTML::StripScripts;

our @ISA = qw( HTML::StripScripts );
our ($VERSION) = ('$Revision: 3387 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<HTML::StripScripts|HTML::StripScripts>

=head2 Export

No symbols exported.

=head2 Functions

=over 4

=cut


=item init_context_whitelist ()

Returns a reference to the C<Context> whitelist, which determines
which tags may appear at each point in the document, and which other
tags may be nested within them.

It is a hash, and the keys are context names, such as C<Flow> and
C<Inline>.

The values in the hash are hashrefs.  The keys in these subhashes are
lowercase tag names, and the values are context names, specifying the
context that the tag provides to any other tags nested within it.

The special context C<EMPTY> as a value in a subhash indicates that
nothing can be nested within that tag.

=cut

use vars qw(%_Context);
BEGIN {

    my %pre_content = (
      'br'      => 'EMPTY',
      'span'    => 'Inline',
      'tt'      => 'Inline',
      'i'       => 'Inline',
      'b'       => 'Inline',
      'u'       => 'Inline',
      's'       => 'Inline',
      'strike'  => 'Inline',
      'em'      => 'Inline',
      'strong'  => 'Inline',
      'dfn'     => 'Inline',
      'code'    => 'Inline',
      'q'       => 'Inline',
      'samp'    => 'Inline',
      'kbd'     => 'Inline',
      'var'     => 'Inline',
      'cite'    => 'Inline',
      'abbr'    => 'Inline',
      'acronym' => 'Inline',
      'ins'     => 'Inline',
      'del'     => 'Inline',
      'a'       => 'Flow',
      'CDATA'   => 'CDATA',
    );

    my %inline = (
      %pre_content,
      'img'   => 'EMPTY',
      'big'   => 'Inline',
      'small' => 'Inline',
      'sub'   => 'Inline',
      'sup'   => 'Inline',
      'font'  => 'Inline',
      'nobr'  => 'Inline',
    );

    my %flow = (
      %inline,
      'ins'        => 'Flow',
      'del'        => 'Flow',
      'div'        => 'Flow',
      'p'          => 'Inline',
      'h1'         => 'Inline',
      'h2'         => 'Inline',
      'h3'         => 'Inline',
      'h4'         => 'Inline',
      'h5'         => 'Inline',
      'h6'         => 'Inline',
      'ul'         => 'list',
      'ol'         => 'list',
      'menu'       => 'list',
      'dir'        => 'list',
      'dl'         => 'dt_dd',
      'address'    => 'Inline',
      'hr'         => 'EMPTY',
      'pre'        => 'pre.content',
      'blockquote' => 'Flow',
      'center'     => 'Flow',
      'table'      => 'table',
    );

    my %table = (
      'caption'  => 'Inline',
      'thead'    => 'tr_only',
      'tfoot'    => 'tr_only',
      'tbody'    => 'tr_only',
      'colgroup' => 'colgroup',
      'col'      => 'EMPTY',
      'tr'       => 'th_td',
    );

    my %head = (
      'title'  => 'NoTags',
    );

    %_Context = (
      'Document'    => { 'html' => 'Html' },
      'Html'        => { 'head' => 'Head', 'body' => 'Flow' },
      'Head'        => \%head,
      'Inline'      => \%inline,
      'Flow'        => \%flow,
      'NoTags'      => { 'CDATA' => 'CDATA' },
      'pre.content' => \%pre_content,
      'table'       => \%table,
      'list'        => { 'li' => 'Flow' },
      'dt_dd'       => { 'dt' => 'Inline', 'dd' => 'Flow' },
      'tr_only'     => { 'tr' => 'th_td' },
      'colgroup'    => { 'col' => 'EMPTY' },
      'th_td'       => { 'th' => 'Flow', 'td' => 'Flow' },
    );
}

sub init_context_whitelist { return \%_Context; }

=item init_attrib_whitelist ()

Returns a reference to the C<Attrib> whitelist, which determines which
attributes each tag can have and the values that those attributes can
take.

It is a hash, and the keys are lowercase tag names.

The values in the hash are hashrefs.  The keys in these subhashes are
lowercase attribute names, and the values are attribute value class names,
which are short strings describing the type of values that the
attribute can take, such as C<color> or C<number>.

=cut

use vars qw(%_Attrib);
BEGIN {

    my %attr = (
        'style' => 'style',
        'class' => 'class',
    );

    my %font_attr = (
      %attr,
      'size'  => 'size',
      'face'  => 'wordlist',
      'color' => 'color',
    );

    my %insdel_attr = (
      %attr,
      'cite'     => 'href',
      'datetime' => 'text',
    );

    my %texta_attr = (
      %attr,
      'align' => 'word',
    );

    my %cellha_attr = (
      'align'    => 'word',
      'char'     => 'word',
      'charoff'  => 'size',
    );

    my %cellva_attr = (
      'valign' => 'word',
    );

    my %cellhv_attr = ( %attr, %cellha_attr, %cellva_attr );

    my %col_attr = (
      %attr, %cellhv_attr,
      'width' => 'size',
      'span'  => 'number',
    );

    my %thtd_attr = (
      %attr,
      'abbr'             => 'text',
      'axis'             => 'text',
      'headers'          => 'text',
      'scope'            => 'word',
      'rowspan'          => 'number',
      'colspan'          => 'number',
      %cellhv_attr,
      'nowrap'           => 'novalue',
      'bgcolor'          => 'color',
      'width'            => 'size',
      'height'           => 'size',
      'bordercolor'      => 'color',
      'bordercolorlight' => 'color',
      'bordercolordark'  => 'color',
    );

    %_Attrib = (
      'br'         => { 'clear' => 'word' },
      'em'         => \%attr,
      'strong'     => \%attr,
      'dfn'        => \%attr,
      'code'       => \%attr,
      'samp'       => \%attr,
      'kbd'        => \%attr,
      'var'        => \%attr,
      'cite'       => \%attr,
      'abbr'       => \%attr,
      'acronym'    => \%attr,
      'q'          => { %attr, 'cite' => 'href' },
      'blockquote' => { %attr, 'cite' => 'href' },
      'sub'        => \%attr,
      'sup'        => \%attr,
      'tt'         => \%attr,
      'i'          => \%attr,
      'b'          => \%attr,
      'big'        => \%attr,
      'small'      => \%attr,
      'u'          => \%attr,
      's'          => \%attr,
      'strike'     => \%attr,
      'font'       => \%font_attr,
      'table'      => { %attr,
                        'frame'            => 'word',
                        'rules'            => 'word',
                        %texta_attr,
                        'bgcolor'          => 'color',
                        'background'       => 'src',
                        'width'            => 'size',
                        'height'           => 'size',
                        'cellspacing'      => 'size',
                        'cellpadding'      => 'size',
                        'border'           => 'size',
                        'bordercolor'      => 'color',
                        'bordercolorlight' => 'color',
                        'bordercolordark'  => 'color',
                        'summary'          => 'text',
                      },
      'caption'    => { %attr,
                        'align' => 'word',
                      },
      'colgroup'   => \%col_attr,
      'col'        => \%col_attr,
      'thead'      => \%cellhv_attr,
      'tfoot'      => \%cellhv_attr,
      'tbody'      => \%cellhv_attr,
      'tr'         => { %attr,
                        bgcolor => 'color',
                        %cellhv_attr,
                      },
      'th'         => \%thtd_attr,
      'td'         => \%thtd_attr,
      'ins'        => \%insdel_attr,
      'del'        => \%insdel_attr,
      'a'          => { %attr,
                        href    => 'href',
                        title    => 'text',
                        alt        => 'text',
                        target    => 'word',

                      },
      'h1'         => \%texta_attr,
      'h2'         => \%texta_attr,
      'h3'         => \%texta_attr,
      'h4'         => \%texta_attr,
      'h5'         => \%texta_attr,
      'h6'         => \%texta_attr,
      'p'          => \%texta_attr,
      'div'        => \%texta_attr,
      'span'       => \%texta_attr,
      'ul'         => { %attr,
                        'type'    => 'word',
                        'compact' => 'novalue',
                      },
      'ol'         => { %attr,
                        'type'    => 'text',
                        'compact' => 'novalue',
                        'start'   => 'number',
                      },
      'li'         => { %attr,
                        'type'  => 'text',
                        'value' => 'number',
                      },
      'dl'         => { %attr, 'compact' => 'novalue' },
      'dt'         => \%attr,
      'dd'         => \%attr,
      'address'    => \%attr,
      'hr'         => { %texta_attr,
                        'width'   => 'size',
                        'size '   => 'size',
                        'noshade' => 'novalue',
                      },
      'pre'        => { %attr, 'width' => 'size' },
      'center'     => \%attr,
      'nobr'       => {},
      'img'        => { 'src'    => 'src',
                        'alt'    => 'text',
                        'width'  => 'size',
                        'height' => 'size',
                        'border' => 'size',
                        'hspace' => 'size',
                        'vspace' => 'size',
                        'align'  => 'word',
                        'title'     => 'text',
                        'style'     => 'style',
                      },
      'body'       => { 'bgcolor'    => 'color',
                        'background' => 'src',
                        'link'       => 'color',
                        'vlink'      => 'color',
                        'alink'      => 'color',
                        'text'       => 'color',
                      },
      'head'       => {},
      'title'      => {},
      'html'       => {},
    );
}

sub init_attrib_whitelist { return \%_Attrib; }

=item init_attval_whitelist ()

Returns a reference to the C<AttVal> whitelist, which is a hash that maps
attribute value class names from the C<Attrib> whitelist to coderefs to
subs to validate (and optionally transform) a particular attribute value.

The filter calls the attribute value validation subs with the
following parameters:

=over 4

=item C<filter>

A reference to the filter object.

=item C<tagname>

The lowercase name of the tag in which the attribute appears.

=item C<attrname>

The name of the attribute.

=item C<attrval>

The attribute value found in the input document, in canonical form
(see L</"CANONICAL FORM">).

=back

The validation sub can return undef to indicate that the attribute
should be removed from the tag, or it can return the new value for
the attribute, in canonical form.

=cut

use vars qw(%_AttVal);
BEGIN {
    %_AttVal = (
      'style'     => \&_hss_attval_style,
      'class'     => \&_hss_attval_class,
      'size'      => \&_hss_attval_size,
      'number'    => \&_hss_attval_number,
      'color'     => \&_hss_attval_color,
      'text'      => \&_hss_attval_text,
      'word'      => \&_hss_attval_word,
      'wordlist'  => \&_hss_attval_wordlist,
      'wordlistq' => \&_hss_attval_wordlistq,
      'href'      => \&_hss_attval_href,
      'src'       => \&_hss_attval_src,
      'stylesrc'  => \&_hss_attval_stylesrc,
      'novalue'   => \&_hss_attval_novalue,
    );
}

sub init_attval_whitelist { return \%_AttVal; }

=item init_style_whitelist ()

Returns a reference to the C<Style> whitelist, which determines which CSS
style directives are permitted in C<style> tag attributes.  The keys are
value names such as C<color> and C<background-color>, and the values are
class names to be used as keys into the C<AttVal> whitelist.

=cut

use vars qw(%_Style);
BEGIN {
    %_Style = (
      'color'            => 'color',
      'background-color' => 'color',
      'background'       => 'stylesrc',
      'background-image' => 'stylesrc',
      'font-size'        => 'word',
      'font-family'      => 'wordlistq',
      'font-style'       => 'word',
      'font-variant'     => 'word',
      'font-weight'      => 'word',
      'line-height'      => 'size',
      'text-align'       => 'word',
      'text_indent'      => 'size',
      'text-decoration'  => 'word',
      'text-transform'   => 'word',
      'width'             => 'size',
      'height'             => 'size',
      'vertical-align'   => 'word',
      'margin'           => 'text',
      'padding'          => 'text',
      'border'           => 'text',
      'border-width'     => 'size',
      'border-style'     => 'word',
      'border-color'     => 'color',
      #'float'            => 'word',
      #'clear'            => 'word',
      'white-space'      => 'word',
      'display'          => 'word',
    );
}

sub init_style_whitelist { return \%_Style; }

=item init_class_whitelist ()

Returns a reference to the C<Class> whitelist, which determines which CSS
class names are permitted in C<class> tag attributes.  The keys are the
class names.

=cut

use vars qw(%_Class);
BEGIN {
    %_Class = ();
}

sub init_class_whitelist { return \%_Class; }

sub allowClasses {
    my $self = shift;
    my $list = shift || [];

    for my $class (@$list) {
        $self->{'_hssClass'}{$class} = undef;
    }
}


=item init_deinter_whitelist

Returns a reference to the C<DeInter> whitelist, which determines which inline
tags the filter should attempt to automatically de-interleave if they are
encountered interleaved.  For example, the filter will transform:

  <b>hello <i>world</b> !</i>

Into:

  <b>hello <i>world</i></b><i> !</i>

because both C<b> and C<i> appear as keys in the C<DeInter> whitelist.

=cut

use vars qw(%_DeInter);
BEGIN {
    %_DeInter = map {$_ => 1} qw(
      tt i b big small u s strike font em strong dfn code
      q sub sup samp kbd var cite abbr acronym span
    );
}

sub init_deinter_whitelist { return \%_DeInter; }


=back

=head1 ATTRIBUTE VALUE HANDLER SUBS

References to the following subs appear in the C<AttVal> whitelist
returned by the init_attval_whitelist() method.

=cut

=head2 Private Functions

=over 4

=cut

=item _hss_attval_style( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value hander for the C<style> attribute.

=cut

sub _hss_attval_style {
    my ($filter, $tagname, $attrname, $attrval) = @_;
    my @clean = ();

    # Split on semicolon, making a reasonable attempt to ignore
    # semicolons inside doublequotes or singlequotes.
    while ( $attrval =~ s{^((?:[^;'"]|'[^']*'|"[^"]*")+)}{} ) {
        my $elt = $1;
        $attrval =~ s/^;//;

        if ( $elt =~ m|^\s*([\w\-]+)\s*:\s*(.+?)\s*$|s ) {
            my ($key, $val) = (lc $1, $2);

            my $value_class = $filter->{'_hssStyle'}{$key};
            next unless defined $value_class;
            my $sub =  $filter->{'_hssAttVal'}{$value_class};
            next unless defined $sub;

            my $cleanval = &{$sub}($filter, 'style-psuedo-tag', $key, $val);
            if (defined $cleanval) {
                push @clean, "$key:$val";
            }
        }
    }

    return undef unless @clean;
    return join '; ', @clean;
}

=item _hss_attval_class( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value hander for the C<class> attribute.

=cut

sub _hss_attval_class {
    my ($filter, $tagname, $attrname, $attrval) = @_;
    my @clean = ();

    # Split on whitespace
    for my $class (split ' ', $attrval) {
        next unless exists $filter->{'_hssClass'}{$class};
        push @clean, $class;
    }
   
    return undef unless @clean;
    return join ' ', @clean;
}
    
=item _hss_attval_size ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for attributes who's values are some sort of
size or length.

=cut

sub _hss_attval_size {
    $_[3] =~ /^\s*([+-]?\d{1,20}(?:\.\d{1,20)?)\s*((?:\%|\*|ex|px|pc|cm|mm|in|pt|em)?)\s*$/i
    ? lc "$1$2" : undef;
}

=item _hss_attval_number ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for attributes who's values are a simple
integer.

=cut

sub _hss_attval_number {
    $_[3] =~ /^\s*\+?(\d{1,20})\s*$/ ? $1 : undef;
}

=item _hss_attval_color ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for color attributes.

=cut

sub _hss_attval_color {
    $_[3] =~ /^\s*(\w{2,20}|#[\da-fA-F]{6})\s*$/ ? $1 : undef;
}

=item _hss_attval_text ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for text attributes.

=cut

sub _hss_attval_text {
    length $_[3] <= 200 ? $_[3] : undef;
}

=item _hss_attval_word ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for attributes who's values must consist of
a single short word, with minus characters permitted.

=cut

sub _hss_attval_word {
    $_[3] =~ /^\s*([\w\-]{1,30})\s*$/ ? $1 : undef;
}

=item _hss_attval_wordlist ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for attributes who's values must consist of
one or more words, separated by spaces and/or commas.

=cut

sub _hss_attval_wordlist {
    $_[3] =~ /^\s*([\w\-\, ]{1,200})\s*$/ ? $1 : undef;
}

=item _hss_attval_wordlistq ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for attributes who's values must consist of
one or more words, separated by commas, with optional doublequotes
around words and spaces allowed within the doublequotes.

=cut

sub _hss_attval_wordlistq {
    my ($filter, $tagname, $attrname, $attrval) = @_;

    my @words = grep /^\s*(?:(?:"[\w\- ]{1,50}")|(?:[\w\-]{1,30}))\s*$/,
                split /,/, $attrval;

    scalar(@words) ? join(', ', @words) : undef;
}

=item _hss_attval_href ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for C<href> type attributes.  If the C<AllowHref>
configuration option is set, uses the validate_href_attribute() method
to check the attribute value.

=cut

sub  _hss_attval_href {
   my ($filter, $tagname, $attname, $attval) = @_;

   if ( $filter->{_hssCfg}{AllowHref} ) {
       return $filter->validate_href_attribute($attval);
   }
   else {
       return undef;
   }
}

=item _hss_attval_src ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for C<src> type attributes.  If the C<AllowSrc>
configuration option is set, uses the validate_src_attribute() method
to check the attribute value.

=cut

sub  _hss_attval_src {
   my ($filter, $tagname, $attname, $attval) = @_;

   if ( $filter->{_hssCfg}{AllowSrc} ) {
       return validate_src_attribute($filter, $attval);
   }
   else {
       return undef;
   }
}



sub validate_href_attribute {
    my ($filter, $text) = @_;

    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    
    return $1 if $filter->{_hssCfg}{AllowRelURL} and $text =~ /^([\w\-\.\,\/]{1,100})$/;

    return $1 if $filter->{_hssCfg}{AllowNonHTTP} and $text =~ /^(mailto: ?[^@]{1,100}@[^@]+)/;

    if($text =~ m< ^ ( https? :// [\w\-\.]{1,100} (?:\:\d{1,5})?
            (?: / (?:[\(\)\w\s\-.!~*|;:/?=+\$,%#]|&amp;){0,1000} )?
                )
                $
                >x 
            ){ 
                return $1;
            }else{ 
                return undef;
            }
        }


*validate_src_attribute = \&validate_href_attribute;




=item _hss_attval_stylesrc ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for C<src> type style pseudo attributes.

=cut

sub _hss_attval_stylesrc {
   my ($filter, $tagname, $attname, $attval) = @_;

   if ( $attval =~ m#^\s*url\((.+)\)\s*$# ) {
       return _hss_attval_src($filter, $tagname, $attname, $1);
   }
   else {
       return undef;
   }
}

=item _hss_attval_novalue ( FILTER, TAGNAME, ATTRNAME, ATTRVAL )

Attribute value handler for attributes that have no value or a value that
is ignored.  Just returns the attribute name as the value.

=cut

sub _hss_attval_novalue {
    my ($filter, $tagname, $attname, $attval) = @_;

    return $attname;
}


1;
__END__

=back

=head2 Modules Used

L<HTML::StripScripts|HTML::StripScripts>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3387 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
