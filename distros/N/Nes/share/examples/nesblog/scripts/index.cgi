#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón Barbero
#  Licensed under the GNU GPL.
#
#  CPAN:
#  http://search.cpan.org/dist/Nes/
#
#  Sample:
#  http://nes.sourceforge.net/
#
#  Repository:
#  http://github.com/Skriptke/nes
# 
#  Version 1.03
#
#  index.cgi
#
# -----------------------------------------------------------------------------

use Nes;
my $nes       = Nes::Singleton->new();
my $q         = $nes->{'query'}->{'q'};
my $config    = $nes->{'CFG'};
my $action    = $q->{'action'};
my $item      = $q->{'item'};
my $source    = $q->{'source'};
my $nes_tags  = {};

$nes_tags->{'HTTP-headers'}  = "Cache-control: max-age=0\n";
$nes_tags->{'HTTP-headers'} .= "Cache-control: no-cache\n";
$nes_tags->{'HTTP-headers'} .= "Expires: Mon, 1 Jan 1900 00:00:00 GMT\n";
$nes_tags->{'HTTP-headers'} .= "Content-type: text/html; charset=utf-8\n\n";

$nes_tags->{'item_name'}        = $item;
$nes_tags->{'title'}            = 'Sample to use Nes; A powerful template system in Perl.';
$nes_tags->{'header'}           = 'header.nhtml';
$nes_tags->{'intro'}            = 'intro.nhtml';
$nes_tags->{'comments'}         = 'comments.nhtml';
$nes_tags->{'user_links'}       = 'user_links.nhtml';
$nes_tags->{'top_articles'}     = 'top_articles.nhtml';
$nes_tags->{'latest_articles'}  = 'latest_articles.nhtml';
$nes_tags->{'latest_comments'}  = 'latest_comments.nhtml';
$nes_tags->{'footer'}           = 'footer.nhtml';

$nes_tags->{'show_comments'}    = 1;
$nes_tags->{'show_right_panel'} = 1;

my $lang = $ENV{'PATH_INFO'};
$lang =~ s/.*\/(..)\/[^\/]*/$1/;
$nes_tags->{'lang'} = $lang;

if ( $action =~ /^login$/i ) {
  
  $nes_tags->{'show_comments'} = 0;
  $nes_tags->{'title'}         = 'Login';
  $nes_tags->{'content'}       = 'login.nhtml';
  
} elsif ( $action =~ /^logindb$/i ) {
  
  $nes_tags->{'show_comments'} = 0;
  $nes_tags->{'title'}         = 'Login';
  $nes_tags->{'content'}       = 'login_db.nhtml';
  
} elsif ( $action =~ /^register$/i ) {
  
  $nes_tags->{'show_comments'} = 0;
  $nes_tags->{'title'}         = 'Register';
  $nes_tags->{'content'}       = 'register.nhtml';
  
} elsif ( $action =~ /^remember$/i ) {
  
  $nes_tags->{'show_comments'} = 0;
  $nes_tags->{'title'}         = 'Remember';  
  $nes_tags->{'content'}       = 'remember.nhtml';

} elsif ( $action =~ /^comment$/i ) {
  
  $nes_tags->{'show_comments'} = 1;
  $nes_tags->{'title'}         = 'Add Commnet to: '.$item;   
  $nes_tags->{'content'}       = 'add_comment.nhtml';

} elsif ( $action =~ /^index$/i ) {
  
  $nes_tags->{'show_comments'} = 1;
  $nes_tags->{'title'}         = 'Article Index';     
  $nes_tags->{'content'}       = 'article_index.nhtml';

} elsif ( $action =~ /^item$/i ) {
  
  $nes_tags->{'title'}         = $item;
  $nes_tags->{'show_comments'} = 0 if $item eq 'index';
  $nes_tags->{'content'} = 'items.nhtml';

} elsif ( $action =~ /^profile$/i ) {
  
  $nes_tags->{'show_comments'} = 0;
  $nes_tags->{'title'}         = 'User profile';
  $nes_tags->{'content'} = 'profile.nhtml';

} elsif ( $action =~ /^users$/i ) {
  
  $nes_tags->{'show_comments'} = 0;
  $nes_tags->{'title'}         = 'Users List';
  $nes_tags->{'content'} = 'user_list.nhtml';

} elsif ( $action =~ /^logout$/i ) {
  
  $nes_tags->{'content'} = 'logout.nhtml';

} else {
  
  $nes_tags->{'content'} = 'items.nhtml';

}

$nes_tags->{'link_source'} = $ENV{'QUERY_STRING'};
$nes_tags->{'link_source'} = $ENV{'QUERY_STRING'}.'&source=1#source' if !$source;
$nes_tags->{'title'}       = 'Show Source: '.$item if $source;


$nes->out(%$nes_tags);

1;
