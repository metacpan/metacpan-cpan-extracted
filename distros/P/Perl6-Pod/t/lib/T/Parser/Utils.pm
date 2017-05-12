#===============================================================================
#
#  DESCRIPTION:  Test Utils
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::Parser::Utils;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Perl6::Pod::To::XHTML;
use Perl6::Pod::Parser::Utils qw(parse_URI );
use base 'TBase';
sub p00_http_file : Test(6) {
    my $t = shift;
    my $u1 = 'Name|http://example.com/index.html#txt';
    is_deeply parse_URI($u1),
      {
        'is_external' => 1,
        'name'        => 'Name',
        'section'     => 'txt',
        'address'     => 'example.com/index.html',
        'scheme'      => 'http'
      }, $u1;

    my $u2 = 'http://example.com/index.html';
    is_deeply parse_URI($u2),
      {
        'is_external' => 1,
        'name'        => '',
        'section'     => '',
        'address'     => 'example.com/index.html',
        'scheme'      => 'http'
      }, $u2;
    my $u3 = 'file:../example/index.html';
    is_deeply parse_URI($u3),
      {
        'is_external' => '',
        'name'        => '',
        'section'     => '',
        'address'     => '../example/index.html',
        'scheme'      => 'file'
      }, $u3;
    my $u4 = '../data/test.pod';
    is_deeply parse_URI($u4),
      {
        'is_external' => '',
        'name'        => '',
        'section'     => '',
        'address'     => '../data/test.pod',
        'scheme'      => 'file'
      }, $u4;
    my $u5 = '../data/test.pod#Sect1';
    is_deeply parse_URI($u5),
      {
        'is_external' => '',
        'name'        => '',
        'section'     => 'Sect1',
        'address'     => '../data/test.pod',
        'scheme'      => 'file'
      }, $u5;
    my $u6 ='mailto:zag@rrru';
    is_deeply parse_URI($u6),
     {
           'is_external' => 1,
           'name' => '',
           'section' => '',
           'address' => 'zag@rrru',
           'scheme' => 'mailto'
        }, $u6 ;
#        diag Dumper parse_URI('L<#id>');
}

sub p01_include_rules  : Test(3){
    my $t = shift;
    my $u6 = '../data/test.pod(head1 :todo)';
    is_deeply parse_URI($u6), {
          'is_external' => '',
          'name' => '',
          'section' => '',
          'address' => '../data/test.pod',
          'scheme' => 'file',
          'rules' => 'head1 :todo'
        }, $u6;

    my $u7 = '../data/test.pod#name ( head1 :todo ) ';
    is_deeply parse_URI($u7), {
          'is_external' => '',
          'name' => '',
          'section' => 'name',
          'address' => '../data/test.pod',
          'scheme' => 'file',
          'rules' => ' head1 :todo '
        }, $u7;
    my $u8 = 'http://www.com/d.pod(head1 :todo, para)';
    is_deeply parse_URI($u8),{
          'is_external' => '1',
          'name' => '',
          'section' => '',
          'address' => 'www.com/d.pod',
          'scheme' => 'http',
          'rules' => 'head1 :todo, para'
        }, $u8;
}
1;


