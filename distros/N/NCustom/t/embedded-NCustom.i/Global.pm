#########################################################################
# We would represent this as CPAN/Config.pm does;			#
# however we broke it up as some values depend upon others. 		#
#									#
#########################################################################
# Add new 							#
# 	$Config{'name'} = "value"; 				#
# entries that you can use from all of you NCustom scripts.	#
# 								#
#################################################################

package NCustom ;

no warnings;

$Config{'test_data1'}	= "global_value";
$Config{'test_data2'}	= "global_value";
$Config{'test_url1'}	= "baneharbinger.com/NCustom/index.html";
$Config{'base_dir'}	= "$ENV{HOME}/.ncustom";
$Config{'save_dir'}	= "$Config{'base_dir'}/save";
$Config{'tmp_dir'}	= "$Config{'base_dir'}/tmp";
$Config{'get_url'}	= \&get_url;
$Config{'src_fqdn'}	= "baneharbinger.com";
$Config{'default_src'}	= ["~/", "./", "http://$Config{'src_fqdn'}/NCustom/"] ;

$Config{'internal_fqdn'}	= "internal.home";
$Config{'perimeter_fqdn'}	= "perimeter.home";
$Config{'external_fqdn'}	= "example.com";
$Config{'lanserver'}		= "lanserver.$Config{'internal_fqdn'}";
$Config{'netserver'}		= "netserver.$Config{'perimeter_fqdn'}";

$Config{'country_code'}		= "AU" ;
$Config{'state'}		= "Victoria" ;
$Config{'city'}			= "Melbourne" ;
$Config{'organisation'}		= "Home" ;
$Config{'organisation_unit'}	= "Home" ;


# passwords generated with slappasswd
# override them in your personal config file
# dont change them in this global file (as it is world readable)
$Config{'users'}  	= { user1 => 501, user2 => 502, user3 => 503 } ;
$Config{'admin_user'}	= "user1" ;
$Config{'low_password'} = [ "{CLEAR}changeme", "{CRYPT}wMgpRr3xnNKbk", "{SSHA}HI89zc2t1e87G/snv4wWMDbTj2ghFySR" ] ;
$Config{'high_password'} = [ "{CLEAR}secret", "{CRYPT}LC4DzvurxORlw", "{SSHA}imWMYrKs2Vo6FcPVkDIivekMw4wo08wD" ] ;

sub get_url {
  my ($url, $target_dir) = @_;
  # the following should be configured for your system
  # it can also be configured in ~/.ncustom/NCustom/MyConfig.pm
  # you may use your favorite utility (curl, wget, pavuk...)
  # you may want to add arguments, such as proxy, or .netrc 
  $url =~ /([^\/]*)$/ ;
  my $basename = $1;
  my $target = "$target_dir/$basename" ;
  my $rc =system("/usr/bin/curl $url --fail -o $target > /dev/null 2>&1 ");
  if($rc != 0){ unlink($target); }
  chmod 0750, $target ;
  return (! $rc);
}

1;
