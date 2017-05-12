package Template::Declare::TagSet::HTML;

use strict;
use warnings;
use base 'Template::Declare::TagSet';
#use Smart::Comments;

our %AlternateSpelling = (
    tr   => 'row',
    td   => 'cell',
    base => 'html_base',
    q    => 'quote',
    time => 'datetime',
);

sub get_alternate_spelling {
    my ($self, $tag) = @_;
    $AlternateSpelling{$tag};
}

# no need to load CGI, really
#sub get_tag_list {
#    my @tags = map { lc($_) } map { @{$_||[]} }
#        @CGI::EXPORT_TAGS{
#                qw/:html2 :html3 :html4 :netscape :form/
#        };
#    return [ @tags, qw/form canvas/ ];
#}

sub get_tag_list {
    return [qw(
        h1 h2 h3 h4 h5 h6 p br hr ol ul li dl dt dd menu code var strong em tt
        u i b blockquote pre img a address cite samp dfn html head base body
        link nextid title meta kbd start_html end_html input select option
        comment charset escapehtml div table caption th td tr tr sup sub
        strike applet param nobr embed basefont style span layer ilayer font
        frameset frame script small big area map abbr acronym bdo col colgroup
        del fieldset iframe ins label legend noframes noscript object optgroup
        q thead tbody tfoot blink fontsize center textfield textarea filefield
        password_field hidden checkbox checkbox_group submit reset defaults
        radio_group popup_menu button autoescape scrolling_list image_button
        start_form end_form startform endform start_multipart_form
        end_multipart_form isindex tmpfilename uploadinfo url_encoded
        multipart form canvas section article aside hgroup header footer nav
        figure figcaption video audio embed mark progress meter time ruby rt
        rp bdi wbr command details datalist keygen output
    )]
}

sub can_combine_empty_tags {
    my ($self, $tag) = @_;
    $tag
        =~ m{^ (?: base | meta | link | hr | br | param | img | area | input | col ) $}x;
}

1;
__END__

=head1 NAME

Template::Declare::TagSet::HTML - Template::Declare tag set for HTML

=head1 SYNOPSIS

    # normal use on the user side:
    use base 'Template::Declare';
    use Template::Declare::Tags 'HTML';

    template foo => sub {
        html {
            body {
            }
        }
    };

    # in Template::Declare::Tags:

    use Template::Declare::TagSet::HTML;
    my $tagset = Template::Declare::TagSet::HTML->new({
        package   => 'MyHTML',
        namespace => 'html',
    });
    my $list = $tagset->get_tag_list();
    print $_, $/ for @{ $list };

    if ( $altern = $tagset->get_alternate_spelling('tr') ) {
        print $altern;
    }

    if ( $tagset->can_combine_empty_tags('img') ) {
        print q{<img src="blah.gif" />};
    }

=head1 DESCRIPTION

Template::Declare::TagSet::HTML defines a full set of HTML tags for use in
Template::Declare templates. All elements for HTML 2, HTML 3, HTML 4, and
XHTML 1 are defined. You generally won't use this module directly, but will
load it via:

    use Template::Declare::Tags 'HTML';

=head1 METHODS

=head2 new( PARAMS )

    my $html_tag_set = Template::Declare::TagSet->new({
        package   => 'MyHTML',
        namespace => 'html',
    });

Constructor inherited from L<Template::Declare::TagSet|Template::Declare::TagSet>.

=head2 get_tag_list

    my $list = $tag_set->get_tag_list();

Returns an array ref of all the HTML tags defined by
Template::Declare::TagSet::HTML. Here is the complete list:

=over

=item * C<h1>

=item * C<h2>

=item * C<h3>

=item * C<h4>

=item * C<h5>

=item * C<h6>

=item * C<p>

=item * C<br>

=item * C<hr>

=item * C<ol>

=item * C<ul>

=item * C<li>

=item * C<dl>

=item * C<dt>

=item * C<dd>

=item * C<menu>

=item * C<code>

=item * C<var>

=item * C<strong>

=item * C<em>

=item * C<tt>

=item * C<u>

=item * C<i>

=item * C<b>

=item * C<blockquote>

=item * C<pre>

=item * C<img>

=item * C<a>

=item * C<address>

=item * C<cite>

=item * C<samp>

=item * C<dfn>

=item * C<html>

=item * C<head>

=item * C<base>

=item * C<body>

=item * C<link>

=item * C<nextid>

=item * C<title>

=item * C<meta>

=item * C<kbd>

=item * C<start_html>

=item * C<end_html>

=item * C<input>

=item * C<select>

=item * C<option>

=item * C<comment>

=item * C<charset>

=item * C<escapehtml>

=item * C<div>

=item * C<table>

=item * C<caption>

=item * C<th>

=item * C<td>

=item * C<tr>

=item * C<tr>

=item * C<sup>

=item * C<sub>

=item * C<strike>

=item * C<applet>

=item * C<param>

=item * C<nobr>

=item * C<embed>

=item * C<basefont>

=item * C<style>

=item * C<span>

=item * C<layer>

=item * C<ilayer>

=item * C<font>

=item * C<frameset>

=item * C<frame>

=item * C<script>

=item * C<small>

=item * C<big>

=item * C<area>

=item * C<map>

=item * C<abbr>

=item * C<acronym>

=item * C<bdo>

=item * C<col>

=item * C<colgroup>

=item * C<del>

=item * C<fieldset>

=item * C<iframe>

=item * C<ins>

=item * C<label>

=item * C<legend>

=item * C<noframes>

=item * C<noscript>

=item * C<object>

=item * C<optgroup>

=item * C<q>

=item * C<thead>

=item * C<tbody>

=item * C<tfoot>

=item * C<blink>

=item * C<fontsize>

=item * C<center>

=item * C<textfield>

=item * C<textarea>

=item * C<filefield>

=item * C<password_field>

=item * C<hidden>

=item * C<checkbox>

=item * C<checkbox_group>

=item * C<submit>

=item * C<reset>

=item * C<defaults>

=item * C<radio_group>

=item * C<popup_menu>

=item * C<button>

=item * C<autoescape>

=item * C<scrolling_list>

=item * C<image_button>

=item * C<start_form>

=item * C<end_form>

=item * C<startform>

=item * C<endform>

=item * C<start_multipart_form>

=item * C<end_multipart_form>

=item * C<isindex>

=item * C<tmpfilename>

=item * C<uploadinfo>

=item * C<url_encoded>

=item * C<multipart>

=item * C<form>

=item * C<canvas>

=item * C<section>

=item * C<article>

=item * C<aside>

=item * C<hgroup>

=item * C<header>

=item * C<footer>

=item * C<nav>

=item * C<figure>

=item * C<figcaption>

=item * C<video>

=item * C<audio>

=item * C<embed>

=item * C<mark>

=item * C<progress>

=item * C<meter>

=item * C<time>

=item * C<ruby>

=item * C<rt>

=item * C<rp>

=item * C<bdi>

=item * C<wbr>

=item * C<command>

=item * C<details>

=item * C<datalist>

=item * C<keygen>

=item * C<output>

=back

=head2 get_alternate_spelling( TAG )

    $bool = $obj->get_alternate_spelling($tag);

Returns the alternative spelling for a given tag if any or undef otherwise.
Currently, C<tr> is mapped to C<row>, C<td> is mapped to C<cell>, C<q> is
mapped to C<quote>, C<base> is mapped to C<html_base>, and C<time> is mapped
to C<datetime>. These alternates are to avoid conflicts with the Perl C<tr>
and C<q> operators, the C<time> function, and the L<base|base> module, with
C<td> changed so as to keep consistent with table rows.

=head2 can_combine_empty_tags( TAG )

    $bool = $obj->can_combine_empty_tags($tag);

Specifies whether C<< <tag></tag> >> can be combined into a single token,
C<< <tag /> >>. Currently, only a few HTML tags are allowed to be combined:

=over

=item * C<base>

=item * C<meta>

=item * C<link>

=item * C<hr>

=item * C<br>

=item * C<param>

=item * C<img>

=item * C<area>

=item * C<input>

=item * C<col>

=back

=head1 AUTHOR

Agent Zhang <agentzh@yahoo.cn>

=head1 SEE ALSO

L<Template::Declare::TagSet>, L<Template::Declare::TagSet::XUL>,
L<Template::Declare::TagSet::RDF>, L<Template::Declare::Tags>,
L<Template::Declare>.

