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
#  lwp.pl
#
# -----------------------------------------------------------------------------

  use Nes;
  my $nes     = Nes::Singleton->new('./lwp.nhtml');
  my $obj     = $nes->{'query'}->{'q'}{'obj_param_0'};
  my $url     = $nes->{'query'}->{'q'}{$obj.'_param_1'};
  my $extrac  = $nes->{'query'}->{'q'}{$obj.'_param_2'} || 'content';
  my $method  = $nes->{'query'}->{'q'}{$obj.'_param_3'} || 'GET';
  my $query   = $nes->{'query'}->{'q'}{$obj.'_param_4'};
  my $charset = $nes->{'query'}->{'q'}{$obj.'_param_5'};
  my $uagent  = $nes->{'query'}->{'q'}{$obj.'_param_6'} || 'Nes/1.0';
  my $uamail  = $nes->{'query'}->{'q'}{$obj.'_param_6'} || $ENV{'SERVER_ADMIN'};
  $uamail = 'no-mail@example.com' if $uamail !~ /[^@]?+\@[^@]?+\..?+/;
  my %tags;
  
  my $call_from_nhtml = 1 if $nes->{'this_template_name'} =~ /\.?html$/;
  my $call_from_pl    = 1 if $nes->{'this_template_name'} =~ /\.pl$/;
 
  use LWP::RobotUA;
  my $ua = LWP::RobotUA->new($uagent,$uamail);
  $ua->delay(0);
  
  use HTTP::Request::Common;
  my $req = HTTP::Request->new();
  $req->method($method);
  $url .= '?'.$query if $method eq 'GET' && $query;
  $req->uri($url);
  $req->referer("http://$ENV{'SERVER_NAME'}$ENV{'PATH_INFO'}");
  $req->content_type('application/x-www-form-urlencoded') if $method eq 'POST';
  $req->content($query) if $method eq 'POST' && $query;
  my $response = $ua->request($req);
 
  $tags{'status'}       = $response->status_line;
  $tags{'request'}      = $req->as_string;
  $tags{'request'}      =~ s/\n/<br>\n/g;
  $tags{'Content-Type'} = $response->header('Content-Type');
  $tags{'content'}      = $response->content;
  
  if ( $charset eq 'UTF-8' ) {
    use utf8;
    utf8::decode($tags{'content'});
    utf8::encode($tags{'content'});
  }
  
  if ( $charset eq 'ISO' ) {
    use utf8;
    utf8::decode($tags{'content'});
  }  

  ( $tags{'title'} )    = $tags{'content'} =~ /<title>(.*)<\/title>/si;
  ( $tags{'head'} )     = $tags{'content'} =~ /<head>(.*)<\/head>/si;
  ( $tags{'body'} )     = $tags{'content'} =~ /<body>(.*)<\/body>/si;

  if ( $extrac =~ /:-:/ ) {

    my $include_tag = $extrac =~ s/^:-://;
    $extrac =~ s/:-:$//;
    my ( $star, $end ) = split (':-:', $extrac);
    if ( $include_tag ) {
      ( $tags{'extrac'} ) = $tags{'content'} =~ /(\Q$star\E.*\Q$end\E)/si;
    } else {
      ( $tags{'extrac'} ) = $tags{'content'} =~ /\Q$star\E(.*)\Q$end\E/si;
    }

  } else {
    
    $tags{'extrac'} =  $tags{$extrac};
    
  }
  
  $tags{'extrac'} = $tags{'status'} if !$response->is_success;
  
  print $tags{'extrac'} if $call_from_pl;
  $nes->out(%tags)      if $call_from_nhtml;

1;
