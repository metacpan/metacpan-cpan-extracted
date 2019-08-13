package Quiq::Html::Page;
use base qw/Quiq::Html::Base/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.154';

use Quiq::Css;
use Quiq::JavaScript;
use Quiq::Template;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Page - HTML-Seite

=head1 BASE CLASS

L<Quiq::Html::Base>

=head1 SYNOPSIS

    use Quiq::Html::Page;
    
    $h = Quiq::Html::Producer->new;
    
    $obj = Quiq::Html::Page->new(
        body => 'hello world!',
    );
    
    $html = $obj->html($h);

=head1 ATTRIBUTES

=over 4

=item body => $str (Default: '')

Rumpf der Seite.

=item comment => $str (Default: undef)

Kommentar am Anfang der Seite.

=item encoding => $charset (Default: 'utf-8')

Encoding der Seite, z.B. 'iso-8859-1'.

=item head => $str (Default: '')

Kopf der Seite.

=item load => \@arr

Liste von Ladeanweisungen für CSS- und JavaScript-Dateien. Die
Ladeanweisungen werden vor anderem CSS- und JavaScript-Code
(s. Attribute javaScript und styleSheet) in den Head der Seite
geschrieben. Eine CSS-Datei wird durch die Angabe eines Paars
css => $url, eine JavaScript-Datei durch die Angabe eines Paars
js => $url geladen. Hat $url die Endung .css oder .js, kann die
Typangabe auch weggelassen werden. Beispiel:

    load => [
        css => 'https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css',
        js => 'https://code.jquery.com/ui/1.12.1/jquery-ui.min.js',
    ],

Oder kurz (da die Dateiendungen den Typ verraten):

    load => [
        'https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css',
        'https://code.jquery.com/ui/1.12.1/jquery-ui.min.js',
    ],

=item noNewline => $bool (Default: 0)

Füge kein Newline am Ende der Seite hinzu.

=item placeholders => \@keyVal (Default: [])

Ersetze im generierten HTML-Code die angegebenen Platzhalter durch
ihre Werte.

=item javaScript => $url|$jsCode|[...] (Default: undef)

URL oder JavaScript-Code im Head der Seite. Mehrfach-Definition,
wenn Array-Referenz. Das Attribut kann mehrfach auftreten, die
Werte werden zu einer Liste zusammengefügt.

=item javaScriptToHead => $bool (Default: 0)

Setze den JavaScrip-Code nicht an das Ende des Body, sondern in
den Head der HTML-Seite.

=item styleSheet => $spec | \@specs (Default: undef)

Einzelne Style-Spezifikation oder Liste von Style-Spezifikationen.
Siehe Methode Quiq::Css->style(). Das Attribut kann mehrfach
auftreten, die Werte werden zu einer Liste zusammengefügt.

=item title => $str (Default: undef)

Titel der Seite.

=item topIndentation => $n (Default: 2)

Einrückung des Inhalts der obersten Elemente <head> und <body>.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $obj = $class->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        body => '',
        comment => undef,
        encoding => 'utf-8',
        head => '',
        load => [],
        noNewline => 0,
        placeholders => [],
        javaScript => [],
        javaScriptToHead => 0,
        styleSheet => [],
        title => '',
        topIndentation => 2,
    );

    while (@_) {
        my $key = shift;
        my $val = shift;

        if ($key eq 'javaScript' || $key eq 'load' || $key eq 'styleSheet') {
            my $arr = $self->get($key);
            push @$arr,ref $val? @$val: $val;
        }
        else {
            $self->set($key=>$val);
        }
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

    $html = $obj->html($h);
    $html = $class->html($h,@keyVal);

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($body,$comment,$encoding,$head,$loadA,$noNewline,$placeholders,
        $title,$javaScript,$javaScriptToHead,$styleSheet,$topIndentation) =
        $self->get(qw/body comment encoding head load noNewline placeholders
        title javaScript javaScriptToHead styleSheet topIndentation/);

    # CSS- und JavaScript-Dateien laden (Test auf @$loadA wg. der
    # neuen Klasse Quiq::Html::Construct - bei Feher $h auf
    # Quiq::Html::Producer instantiieren)

    # my $loadTags = @$loadA? $h->loadFiles(@$loadA): '';
    my $loadTags = $h->loadFiles(@$loadA);

    # Stylesheet-Defininition(en)
    my $styleTags = Quiq::Css->style($h,$styleSheet);

    # Script-Definition(en)
    my $scriptTags = Quiq::JavaScript->script($h,$javaScript);

    # Wenn $body keinen body-Tag enthält, fügen wir ihn hinzu.

    $body = $h->cat($body);
    if ($body !~ /^<body/i) {
        $body = $h->tag('body',
            -ind => $topIndentation,
            '-',
            $body,
            $javaScriptToHead? (): $scriptTags,
        );
    }

    my $html = $h->cat(
        $h->doctype,
        $h->comment(-nl=>2,$comment),
        $h->tag('html',
            '-',
            $h->tag('head',
                -ind => $topIndentation,
                '-',
                $h->tag('title',
                    -ignoreIf => !$title,
                    '-',
                    $title,
                ),
                $h->tag('meta',
                    'http-equiv' => 'content-type',
                    content => "text/html; charset=$encoding",
                ),
                $h->cat($head),
                $loadTags,
                $styleTags,
                $javaScriptToHead? $scriptTags: (),
            ),
            $body,
        ),
    );

    if (@$placeholders) {
        # Platzhalter ersetzen

        my $tpl = Quiq::Template->new('text',\$html);
        $tpl->replace(@$placeholders);
        $html = $tpl->asString;
    }

    if ($noNewline) {
        chomp $html;
    }

    return $html;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.154

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
