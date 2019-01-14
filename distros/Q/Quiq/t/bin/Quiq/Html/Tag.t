#!/usr/bin/env perl

package Quiq::Html::Tag::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Tag');
}

# -----------------------------------------------------------------------------

sub test_new : Test(7) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;
    $self->is(ref($h),'Quiq::Html::Tag','new: Klassenname');
    $self->is($h->{'htmlVersion'},'html-5','new: version');
    $self->is($h->{'uppercase'},0,'new: uppercase');

    $h = Quiq::Html::Tag->new(htmlVersion=>'html-5');
    $self->is($h->{'htmlVersion'},'html-5','new: version');
    $self->is($h->{'uppercase'},0,'new: uppercase');

    $h = Quiq::Html::Tag->new(htmlVersion=>'html-4.01',uppercase=>1);
    $self->is($h->{'htmlVersion'},'html-4.01','new: version');
    $self->is($h->{'uppercase'},1,'new: uppercase');
}

# -----------------------------------------------------------------------------

my $Html01 = <<'__HTML__';
<html>
  <head>
    <title>Test</title>
  </head>
  <body>
    <p>
      Dies ist
      ein Test.
    </p>
  </body>
</html>
__HTML__

my $Html02 = <<'__HTML__';
<html>
    <head>
        <title>Test</title>
    </head>
    <body>
        <p>
            Dies ist
            ein Test.
        </p>
    </body>
</html>
__HTML__

sub test_tag : Test(7) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $html =
    $h->tag('html',
      $h->tag('head',
        $h->tag('title','Test')
      ).
      $h->tag('body',
        $h->tag('p',q|
          Dies ist
          ein Test.
        |)
      )
    );
    (my $str = $Html01) =~ s/^  //gm;
    $self->is($html,$str,'tag: Test-Dokument mit normaler Einrückung');

    #--------------------------------------------------------------------------

    $html = $h->tag('pre'," a\nb\nc ");
    $self->is($html,"<pre> a&#10;b&#10;c </pre>\n","tag: -fmt=>'p'");

    #--------------------------------------------------------------------------

    $html = $h->tag('br');
    $self->is($html,"<br />\n","tag: Test -fmt=>'e'");

    #--------------------------------------------------------------------------

    $html = $h->tag('h1','Ein Titel');
    $self->is($html,"<h1>Ein Titel</h1>\n",
        "tag: Test -fmt=>'v', einzeilig");

    #--------------------------------------------------------------------------

    $html = $h->tag('h1',"Ein\nTitel");
    $self->is($html,"<h1>\n  Ein\n  Titel\n</h1>\n",
        "tag: Test -fmt=>'v', mehrzeilig");

    #==========================================================================

    $h = Quiq::Html::Tag->new(indentation=>0);

    ($str = $Html01) =~ s/^\s+//gm;

    $html =
    $h->tag('html',
      $h->tag('head',
        $h->tag('title','Test')
      ).
      $h->tag('body',
        $h->tag('p',q|
          Dies ist
          ein Test.
        |)
      )
    );
    $self->is($html,$str,'tag: Test Document ohne Einrückung');

    #==========================================================================

    $h = Quiq::Html::Tag->new(indentation=>4);

    $html =
    $h->tag('html',
      $h->tag('head',
        $h->tag('title','Test')
      ).
      $h->tag('body',
        $h->tag('p',q|
          Dies ist
          ein Test.
        |)
      )
    );
    $self->is($html,$Html02,'tag: Test Document mit 4x-Einrückung');
}

sub tag_zusammengesetzterInhalt : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $expected = qq|<p class="x">\n  Ein\n  <b>kurzer</b>\n  Text\n</p>\n|;

    my $val = $h->tag('p',
        class=>'x',
        "Ein\n".
        $h->tag('b',-nl=>1,'kurzer').
        'Text'
    );
    $self->is($val,$expected,"tag: Content konkateniert");

    $val = $h->tag('p',
        class=>'x',
        '-',
        "Ein\n",
        $h->tag('b',-nl=>1,'kurzer'),
        'Text',
    );
    $self->is($val,$expected,"tag: Content über mehreren Argumenten");
}

sub tag_dataTags : Test(4) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    # Einzel-Attribute

    my $html = $h->tag('form',
        'data-x'=>'a',
        'data-y'=>'b',
        'data-z'=>'c',
    );
    $self->is($html,qq|<form data-x="a" data-y="b" data-z="c"></form>\n|);

    # Liste von Attributen

    # a) leere Liste

    $html = $h->tag('form',
        data=>[],
    );
    $self->is($html,qq|<form></form>\n|);

    # b) ein Element

    $html = $h->tag('form',
        data=>[
            x=>'a',
        ],
    );
    $self->is($html,qq|<form data-x="a"></form>\n|);

    # c) mehrere Elemente

    $html = $h->tag('form',
        data=>[
            x=>'a',
            y=>'b',
            z=>'c',
        ],
    );
    $self->is($html,qq|<form data-x="a" data-y="b" data-z="c"></form>\n|);
}

# -----------------------------------------------------------------------------

sub test_wrapTag : Test(1) {
    my $self = shift;

    my $tag = q|<test attrib1="value 1" attrib2="value 2" attrib3="value 3"|.
        q| attrib4="value 4" attrib5="value 5" attrib6="value 6" />|;

    my $ok = qq|<test attrib1="value 1" attrib2="value 2"\n|.
        qq|  attrib3="value 3" attrib4="value 4"\n|.
        qq|  attrib5="value 5" attrib6="value 6" />|;

    # warn $tag,"\n";
    my $str = Quiq::Html::Tag->wrapTag(40,$tag);
    # warn $str,"\n";
    $self->is($str,$ok);
}

# -----------------------------------------------------------------------------

sub test_cat : Test(4) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new(htmlVersion=>'xhtml-1.0');

    ### keine Argumente ###

    my $val = $h->cat;
    $self->is($val,'','cat: keine Argumente');

    ### String-Argumente ###

    $val = $h->cat('HTML1','HTML2');
    $self->is($val,'HTML1HTML2','cat: String-Argumente');

    ### Komplexer Code

    my $expected = Quiq::String->removeIndentationNl(q|
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

    <!-- Copyright Lieschen Müller -->

    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Meine Homepage</title>
      <style type="text/css">
        .text { color: red; }
      </style>
    </head>
    <body>
      <h1>Hallo Welt!</h1>
      <p class="text">
        Ich heiße Lieschen Müller und dies
        ist meine Homepage.
      </p>
    </body>
    </html>
    |);

    ### Methodenaufrufe

    $val = $h->cat(
        $h->doctype,
        $h->comment(-nl=>2,'Copyright Lieschen Müller'),
        $h->tag('html','-',
            $h->tag('head','-',
                $h->tag('title','Meine Homepage'),
                $h->tag('style',q|
                    .text { color: red; }
                |),
            ),
            $h->tag('body','-',
                $h->tag('h1','Hallo Welt!'),
                $h->tag('p',class=>'text',q|
                    Ich heiße Lieschen Müller und dies
                    ist meine Homepage.
                |),
            ),
        ),
    );
    $self->is($val,$expected,'cat: Methoden-Aufrufe');

    ### PERL-HTML

    $val = $h->cat(
        ['doctype'],
        ['comment',-nl=>2,'Copyright Lieschen Müller'],
        ['HTML',
            ['HEAD',
                ['TITLE','Meine Homepage'],
                ['STYLE',q|
                    .text { color: red; }
                |],
            ],
            ['BODY',
                ['H1','Hallo Welt!'],
                ['P',class=>'text',q|
                    Ich heiße Lieschen Müller und dies
                    ist meine Homepage.
                |],
            ],
        ]
    );
    $self->is($val,$expected,'cat: PERL-HTML');
}

# -----------------------------------------------------------------------------

sub test_doctype : Test(5) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new(htmlVersion=>'html-5');
    my $val = $h->doctype;
    $self->is($val,"<!DOCTYPE html>\n\n");

    $h = Quiq::Html::Tag->new(htmlVersion=>'xhtml-1.0');
    $val = $h->doctype;
    $self->like($val,qr/DTD XHTML/);

    $val = $h->doctype(-frameset=>1);
    $self->like($val,qr/DTD XHTML.*Frameset/);

    $h = Quiq::Html::Tag->new(htmlVersion=>'html-4.01');
    $val = $h->doctype;
    $self->like($val,qr/DTD HTML/);

    $h = Quiq::Html::Tag->new(htmlVersion=>'xyz-47.11');
    eval { $h->doctype };
    $self->like($@,qr/HTML-00002/);
}

# -----------------------------------------------------------------------------

sub test_comment : Test(3) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $val = $h->comment;
    $self->is($val,'','comment: leer');

    my $comment = 'Ein Test';
    $val = $h->comment($comment);
    $self->is($val,"<!-- $comment -->\n",'comment: einzeilig');

    $comment = "Ein\nTest";
    $val = $h->comment($comment);
    $self->is($val,"<!--\n  Ein\n  Test\n-->\n",'comment: mehrzeilig');
}

# -----------------------------------------------------------------------------

sub test_protect : Test(4) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $val = $h->protect(undef);
    $self->is($val,undef);

    $val = $h->protect('a > b');
    $self->is($val,'a &gt; b');

    $val = $h->protect('a < b');
    $self->is($val,'a &lt; b');

    $val = $h->protect('a & b');
    $self->is($val,'a &amp; b');
}

# -----------------------------------------------------------------------------

sub test_optional : Test(4) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $val = $h->optional;
    $self->is($val,'');

    $val = $h->optional('');
    $self->is($val,'');

    my $text = 'Ein Test';
    $val = $h->optional($text);
    $self->is($val,"<!--optional-->$text<!--/optional-->");

    $text = "Ein\nTest";
    $val = $h->optional($text);
    $self->is($val,"<!--optional-->\n$text<!--/optional-->\n");
}

# -----------------------------------------------------------------------------

sub test_import : Test(3) {
    my $self = shift;

    Quiq::Html::Tag->import(htmlVersion=>'html-4.01',uppercase=>1);
    my $h = Quiq::Html::Tag->new;
    $self->is($h->get('htmlVersion'),'html-4.01','import: HTML 4.01');
    $self->is($h->get('uppercase'),1,'import: uppercase');

    Quiq::Html::Tag->import(htmlVersion=>'xhtml-1.0');
    $h = Quiq::Html::Tag->new;
    $self->is($h->get('htmlVersion'),'xhtml-1.0','import: XHTML 1.0');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Tag::Test->runTests;

# eof
