#!/usr/bin/env perl

package Quiq::Url::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Url');
}

# -----------------------------------------------------------------------------

sub test_new : Test(4) {
    my $self = shift;

    my $urlObj = Quiq::Url->new;
    $self->is(ref($urlObj),'Quiq::Url');
    $self->is($urlObj->url,'');

    my $url = 'http://user:passw@host.domain:8080/this/is/a/path'.
        '?arg1=val1&arg1=val2&arg2=val3#search';
    $urlObj = Quiq::Url->new($url);
    $self->is($urlObj->url,$url);    

    $urlObj = Quiq::Url->new(a=>1,b=>2,a=>3,d=>4);
    $self->is($urlObj->url,'?a=1&a=3&b=2&d=4');    
}

# -----------------------------------------------------------------------------

sub test_encode : Test(5) {
    my $self = shift;

    my $val = Quiq::Url->encode('-*._1ABCabc');
    $self->is($val,'-*._1ABCabc','encode: Nicht-kodierte Zeichen (ASCII)');

    # iso-8859-1

    $val = Quiq::Url->encode('!"§$%&/()=?','iso-8859-1');
    $self->is($val,'%21%22%A7%24%25%26%2F%28%29%3D%3F',
        'encode: Einige kodierte Zeichen (ASCII)');

    $val = Quiq::Url->encode('ÄÖÜäöüß','iso-8859-1');
    $self->is($val,'%C4%D6%DC%E4%F6%FC%DF','encode: Umlaute (ISO-8859-1)');

    # utf-8 (Default)

    $val = Quiq::Url->encode('!"§$%&/()=?');
    $self->is($val,'%21%22%C2%A7%24%25%26%2F%28%29%3D%3F',
        'encode: Einige kodierte Zeichen (ASCII)');

    $val = Quiq::Url->encode('ÄÖÜäöüß');
    $self->is($val,'%C3%84%C3%96%C3%9C%C3%A4%C3%B6%C3%BC%C3%9F',
        'encode: Umlaute (UTF-8)');

}

# -----------------------------------------------------------------------------

sub test_decode : Test(5) {
    my $self = shift;

    my $val = Quiq::Url->decode('-*._1ABCabc');
    $self->is($val,'-*._1ABCabc','decode: Nicht-kodierte Zeichen (ASCII)');

    # iso-8859-1

    $val = Quiq::Url->decode('%21%22%A7%24%25%26%2F%28%29%3D%3F','iso-8859-1');
    $self->is($val,'!"§$%&/()=?','decode: Einige kodierte Zeichen (ASCII)');

    $val = Quiq::Url->decode('%C4%D6%DC%E4%F6%FC%DF','iso-8859-1');
    $self->is($val,'ÄÖÜäöüß','decode: Umlaute (ISO-8859-1)');

    # utf-8

    $val = Quiq::Url->decode('%21%22%C2%A7%24%25%26%2F%28%29%3D%3F');
    $self->is($val,'!"§$%&/()=?','decode: Einige kodierte Zeichen (ASCII)');

    $val = Quiq::Url->decode('%C3%84%C3%96%C3%9C%C3%A4%C3%B6%C3%BC%C3%9F');
    $self->is($val,'ÄÖÜäöüß','decode: Umlaute (UTF-8)');

}

# -----------------------------------------------------------------------------

sub test_queryEncode : Test(10) {
    my $self = shift;

    # Einfacher Query-String

    my $val = Quiq::Url->queryEncode(a=>1,b=>2,c=>3);
    $self->is($val,'a=1&b=2&c=3');

    # Query-String mit Fragezeichen

    $val = Quiq::Url->queryEncode('?',a=>1,b=>2,c=>3);
    $self->is($val,'?a=1&b=2&c=3');

    # Query-String ohne leere Werte

    $val = Quiq::Url->queryEncode('?',a=>1,b=>2,c=>'',d=>4,e=>undef);
    $self->is($val,'?a=1&b=2&d=4');

    # Query-String ohne leere Werte

    $val = Quiq::Url->queryEncode(a=>1,b=>[2,'',3,undef],c=>'',d=>4,e=>undef);
    $self->is($val,'a=1&b=2&b=3&d=4');

    # Query-String mit leeren Werten

    $val = Quiq::Url->queryEncode('?',-null=>1,a=>1,b=>2,c=>'',d=>4,e=>undef);
    $self->is($val,'?a=1&b=2&c=&d=4&e=');

    # Query-String mit leeren Werten

    $val = Quiq::Url->queryEncode(-null=>1,a=>1,b=>[2,'',3,undef],c=>'',
        d=>4,e=>undef);
    $self->is($val,'a=1&b=2&b=&b=3&b=&c=&d=4&e=');

    # Umlaute iso-8859-1

    $val = Quiq::Url->queryEncode(-encoding=>'iso-8859-1',a=>1,'für'=>'Möller');
    $self->is($val,'a=1&f%FCr=M%F6ller');

    # Umlaute utf-8

    $val = Quiq::Url->queryEncode(a=>1,'für'=>'Möller');
    $self->is($val,'a=1&f%C3%BCr=M%C3%B6ller');

    # Array-Referenz als Wert

    $val = Quiq::Url->queryEncode(a=>1,b=>[1,2,3],c=>3);
    $self->is($val,'a=1&b=1&b=2&b=3&c=3');

    # ; als Trennzeichen

    $val = Quiq::Url->queryEncode(-separator=>';',a=>1,b=>[1,2,3],c=>3);
    $self->is($val,'a=1;b=1;b=2;b=3;c=3');
}

# -----------------------------------------------------------------------------

sub test_queryDecode : Test(5) {
    my $self = shift;

    my $arr = Quiq::Url->queryDecode('');
    $self->isDeeply($arr,[]);

    $arr = Quiq::Url->queryDecode('a=1&b=2');
    $self->isDeeply($arr,[qw/a 1 b 2/]);

    $arr = Quiq::Url->queryDecode('a=1;b=2');
    $self->isDeeply($arr,[qw/a 1 b 2/]);

    # Umlaute iso-8859-1

    $arr = Quiq::Url->queryDecode('a=1;f%FCr=M%F6ller','iso-8859-1');
    $self->isDeeply($arr,[a=>1,'für'=>'Möller']);

    # Umlaute utf-8

    $arr = Quiq::Url->queryDecode('a=1;f%C3%BCr=M%C3%B6ller');
    $self->isDeeply($arr,[a=>1,'für'=>'Möller']);
}

# -----------------------------------------------------------------------------

sub test_split : Test(64) {
    my $self = shift;

    my ($str,$protocol,$user,$passw,$host,$port,$path,$query,$search);

    $str = 'http://user:passw@host.domain:8080/this/is/a/path'.
            '?arg1=val1&arg2=val2#search';
    ($protocol,$user,$passw,$host,$port,$path,$query,$search) =
            Quiq::Url->split($str);

    $self->is($protocol,'http');
    $self->is($user,'user');
    $self->is($passw,'passw');
    $self->is($host,'host.domain');
    $self->is($port,'8080');
    $self->is($path,'/this/is/a/path');
    $self->is($query,'arg1=val1&arg2=val2');
    $self->is($search,'search');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $str = 'index.cgi?seite=test&id=73';
    ($protocol,$user,$passw,$host,$port,$path,$query,$search) =
            Quiq::Url->split($str);

    $self->is($protocol,'');
    $self->is($user,'');
    $self->is($passw,'');
    $self->is($host,'');
    $self->is($port,'');
    $self->is($path,'index.cgi');
    $self->is($query,'seite=test&id=73');
    $self->is($search,'');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $str = 'http://host.domain:8080';
    ($protocol,$user,$passw,$host,$port,$path,$query,$search) =
            Quiq::Url->split($str);

    $self->is($protocol,'http');
    $self->is($user,'');
    $self->is($passw,'');
    $self->is($host,'host.domain');
    $self->is($port,'8080');
    $self->is($path,'');
    $self->is($query,'');
    $self->is($search,'');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $str = 'http://host.domain:8080/';
    ($protocol,$user,$passw,$host,$port,$path,$query,$search) =
            Quiq::Url->split($str);

    $self->is($protocol,'http');
    $self->is($user,'');
    $self->is($passw,'');
    $self->is($host,'host.domain');
    $self->is($port,'8080');
    $self->is($path,'/');
    $self->is($query,'');
    $self->is($search,'');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $str = 'http://user@host.domain/this/is/a/path';
    ($protocol,$user,$passw,$host,$port,$path,$query,$search) =
            Quiq::Url->split($str);

    $self->is($protocol,'http');
    $self->is($user,'user');
    $self->is($passw,'');
    $self->is($host,'host.domain');
    $self->is($port,'');
    $self->is($path,'/this/is/a/path');
    $self->is($query,'');
    $self->is($search,'');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $str = '/this/is/a/path?arg1=val1&arg2=val2&arg3=val3#search';
    ($protocol,$user,$passw,$host,$port,$path,$query,$search) =
            Quiq::Url->split($str);

    $self->is($protocol,'');
    $self->is($user,'');
    $self->is($passw,'');
    $self->is($host,'');
    $self->is($port,'');
    $self->is($path,'/this/is/a/path');
    $self->is($query,'arg1=val1&arg2=val2&arg3=val3');
    $self->is($search,'search');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $str = 'is/a/path?arg1=val1&arg2=val2&arg3=val3#search';
    ($protocol,$user,$passw,$host,$port,$path,$query,$search) =
            Quiq::Url->split($str);

    $self->is($protocol,'');
    $self->is($user,'');
    $self->is($passw,'');
    $self->is($host,'');
    $self->is($port,'');
    $self->is($path,'is/a/path');
    $self->is($query,'arg1=val1&arg2=val2&arg3=val3');
    $self->is($search,'search');

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    $str = '?arg1=val1&arg2=val2&arg3=val3';
    ($protocol,$user,$passw,$host,$port,$path,$query,$search) =
            Quiq::Url->split($str);

    $self->is($protocol,'');
    $self->is($user,'');
    $self->is($passw,'');
    $self->is($host,'');
    $self->is($port,'');
    $self->is($path,'');
    $self->is($query,'arg1=val1&arg2=val2&arg3=val3');
    $self->is($search,'');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Url::Test->runTests;

# eof
