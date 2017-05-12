#!/usr/bin/perl -w
use strict;
use utf8;
use lib qw(%PATH%lib);
use MySQL::Admin::Settings;
use vars qw($m_hrS $m_bReturn $m_bError $m_nSkipCaptch);
$m_bError = 0;
use CGI qw(param header);
loadSettings('%PATH%config/settings.pl');
*m_hrS= \$MySQL::Admin::Settings::m_hrSettings;
my $m_sAction = defined param('action') ? param('action') :'settings';

if( $m_hrS->{login} || ( param('username') eq $m_hrS->{admin}{name}  &&  param('password') eq $m_hrS->{admin}{password}) ){
  $m_hrS->{admin}{name}        = defined param('username')   ? param('username')   : defined $m_hrS->{admin}{name} ? $m_hrS->{admin}{name} :'Admin';
  $m_hrS->{admin}{password}    = defined param('password')   ? param('password')   : $m_hrS->{admin}{password};
  $m_hrS->{cgi}{serverName}    = defined param('serverName') ? param('serverName') : $m_hrS->{cgi}{serverName};
  $m_hrS->{language}           = defined param('language')   ? param('language')   : $m_hrS->{language};
  $m_hrS->{database}{host}     = defined param('dbhost')     ? param('dbhost')     : $m_hrS->{database}{host};
  $m_hrS->{database}{user}     = defined param('dbuser')     ? param('dbuser')     : $m_hrS->{database}{user};
  $m_hrS->{database}{name}     = defined param('dbname')     ? param('dbname')     : $m_hrS->{database}{name};
  $m_hrS->{database}{password} = defined param('dbpassword') ? param('dbpassword') : $m_hrS->{database}{password};
}else{
  $m_hrS->{admin}{name}        = 'Admin';
  $m_hrS->{admin}{password}    = '';
  $m_hrS->{cgi}{serverName}    = '';
  $m_hrS->{language}           = 'en';
  $m_hrS->{database}{host}     = '';
  $m_hrS->{database}{user}     = '';
  $m_hrS->{database}{name}     = '';
  $m_hrS->{database}{password} = '';
  $m_sAction = 'settings';
}


print header(
    -type    => 'text/xml',
#     -access_control_allow_origin => '*',
#     -access_control_allow_credentials => 'true',
    -charset => 'UTF-8'
);
print qq(<?xml version="1.0" encoding="UTF-8"?><xml>\n\n);

SWITCH:{
  if($m_sAction eq 'save'){
    eval{
      use Authen::Captcha;
      my $captcha = Authen::Captcha->new(data_folder   => "$m_hrS->{cgi}{bin}/config/",
					  output_folder => "$m_hrS->{cgi}{DocumentRoot}/images");
      $m_nSkipCaptch = $captcha->check_code(param("captcha"), param("md5"));
    };
    $m_nSkipCaptch = 1 if $@;
    if($m_nSkipCaptch <= 0){
      &install();
      last SWITCH;
    }
    if( param('username') eq $m_hrS->{admin}{name}  &&  param('password') eq $m_hrS->{admin}{password} ){
    my $m_sFile = '';
    eval{
	my %conf = (
	  name => $m_hrS->{database}{name},
	  host => $m_hrS->{database}{hsot},
	  user => $m_hrS->{database}{user}  
	);
	$conf{password} = $m_hrS->{database}{password};
	use DBI::Library;
	my $dDatabase = new DBI::Library();
	$dDatabase->initDB(\%conf);
	open(IN, "config/install.sql") or warn $!;
	local $/;
	$m_sFile = <IN>;
	foreach my $sql (split /;\n/, $m_sFile){
	    $dDatabase->void($sql);
	}
	close(IN);
	eval 'use MD5';
	unless ($@) {
	    my $md5 = new MD5;
	    $md5->add($m_hrS->{admin}{name});
	    $md5->add($m_hrS->{admin}{password});
	    my $fingerprint = $md5->hexdigest();
	    $dDatabase->void(qq/insert into users (`user`,`pass`,`right`,`id`) values(?,?,5,?)/, 'admin', $fingerprint,'2');
	} else {
	    warn $@;
	    $dDatabase->void(qq/insert into users (`user`,`pass`,`right`,`id`) values('admin','0008e525bc0894a780297b7f3aed6f58','5','2')/);
	}
      };
      if( $@ ){
        &install();
      }else{
	$m_hrS->{login} = 0;
	print qq|<output id="content"><![CDATA[<textarea style="width:90%;min-height:400px;">$m_sFile</textarea>]]></output>|;
	saveSettings('config/settings.pl');
      }
    }else{
      &install();
    }
    last SWITCH;
  }
  &install();
}
sub install{
    my $authen ='';
    eval{
      my $right_captcha_text = 'Right';
      my $wrong_captcha_text = 'Wrong';
      use Authen::Captcha;
      my $captcha = Authen::Captcha->new(
      data_folder   => "$m_hrS->{cgi}{bin}/config/",
      output_folder => "$m_hrS->{cgi}{DocumentRoot}/images",
      expire        => 300);
      my $md5sum = $captcha->generate_code(3);
      $authen = qq|<input size="5" type="hidden" name="md5" value="$md5sum"/>
      <img src="images/$md5sum.png" border="0"  style="vertical-align:middle;margin:0%">
      <input style="width:35px;" autocomplete="off" onkeypress="if(enter(event))return false;" type="text" size="3" data-regexp="|.'/^.{3}$/'.qq|" data-error="$wrong_captcha_text" data-right="$right_captcha_text"  name="captcha"/>|;
    };
  print qq|<output id="errorMessage"><![CDATA[$@]]></output>| if $@;
  print qq|<output id="content">
  <![CDATA[
  <form onsubmit="submitForm(this,'SQL','SQL',false,'GET','cgi-bin/install.pl?');return false;">
    <input type="hidden" name="action" value="save"/>
    <table align="center">
      <tr>
	<td class="header"><label for="username">Username</label></td>
	<td class="header"><label for="password">Password</label></td>
	<td class="header"><label for="serverName">Host</label></td>
      </tr>
      <tr>
	<td><input style="margin:0%" id="username" type="text" name="username" value="$m_hrS->{admin}{name}"/></td>
	<td><input style="margin:0%" id="password" type="text" name="password" value="$m_hrS->{admin}{password}"/></td>
	<td><input style="margin:0%" id="serverName" type="text" name="serverName" value="$m_hrS->{cgi}{serverName}"/></td>
      </tr>
      <tr>
	<td class="header"><label for="dbhost">Database&#160;Host</label></td>
	<td class="header"><label for="dbusername">Database&#160;Username</label></td>
	<td class="header"><label for="dbpassword">Database&#160;Password</label></td>
      </tr>
      <tr>
	<td><input style="margin:0%" id="dbhost" type="text" name="dbhost" value="$m_hrS->{database}{host}"/></td>
	<td><input style="margin:0%" id="dbusername" type="text" name="dbuser" value="$m_hrS->{database}{user}"/></td>
	<td><input style="margin:0%" id="dbpassword" type="text" name="dbpassword" value="$m_hrS->{database}{password}"/></td>
      </tr>
      <tr>
	<td class="header"><label for="dbhost">Database&#160;Name</label></td>
	<td class="header"><label for="language">Language</label></td>
	<td class="header">Captcha</td>
      </tr>
      <tr>
	<td><input style="margin:0%" id="dbname" type="text" name="dbname" value="$m_hrS->{database}{name}"/></td>
	<td align="left">
	    <select name="language">
	    <option value="en" |.($m_hrS->{language} eq 'en' ? 'selected="selected"'  :'').qq|>English</option>
	    <option value="de" |.($m_hrS->{language} eq 'de' ? 'selected="selected"'  :'').qq|>Deutsch</option>
	    </select>
	</td>
	<td align="left">$authen</td>
      </tr>
      <tr><td align="right" colspan="3"><input style="margin:-2px" type="submit" value="Install"/></td></tr>
  </table>
  </form>
  ]]>
  </output></xml>|;
}
