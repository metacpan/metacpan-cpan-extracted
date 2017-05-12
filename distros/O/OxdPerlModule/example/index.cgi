#!/usr/bin/perl
=pod
/**
 * Language: Perl 5
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @Created On: 21-10-2016
 * Author: Inderpal Singh
 * Email: inderpal@ourdesignz.com
 * Company: ourdesignz Pvt Ltd.
 * Company Website: http://wwww.ourdesignz.com
 * @license   http://www.opensource.org/licenses/mit-license.php MIT License
 */
=cut

###############
## Libraries ##
###############

use warnings;
use CGI qw{ :standard };
use lib './modules';
use JSON::PP;
use CGI::Carp qw(fatalsToBrowser); # show errors in browser
use CGI::Session;
#Load Oxd Perl Module
use OxdPerlModule;

# Create the CGI object
my $cgi = new CGI;
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);
# print the HTTP header and set the session ID cookie
print $session->header();


$object = new OxdConfig();
my $opHost = $object->getOpHost();
my $oxdHostPort = $object->getOxdHostPort();
my $authorizationRedirectUrl = $object->getAuthorizationRedirectUrl();
my $postLogoutRedirectUrl = $object->setPostLogoutRedirectUrl();
my $scope = $object->getScope();
my $applicationType = $object->getApplicationType();
my $responseType = $object->getResponseType();
my $grantType = $object->getGrantTypes();
my $acrValues = $object->getAcrValues();


# Output the HTTP header
#print $cgi->header ( );

##################
## User-defined ##
##################

##################
## Main program ##
##################
#server_side_ajax();
print_page_header();
print_html_head_section();
print_html_body_section_top();
# Process form if submitted; otherwise display it
if($cgi->param("submit")) {
	# Parameters are defined, therefore the form has been submitted
	display_results($cgi);
} else {
	# We're here for the first time, display the form
	print_html_form();
}

print_html_body_section_bottom();



#$object->setRequestOpHost( "Mohd." );
#my $firstName = $object->getRequestOpHost();
#print $firstName;


#################
## Subroutines ##
#################
sub print_page_header {
    # Print the HTML header (don't forget TWO newlines!)
    #print "Content-type:  text/html\n\n";
}


sub print_html_head_section {
    # Include stylesheet 'pm.css', jQuery library,
    # and javascript 'pm.js' in the <head> of the HTML.
    ##
    print "<!DOCTYPE html>\n";
    print '<html lang="en">'."\n";
    print '<head>'."\n";
    print '<title>Oxd Perl Application</title>'."\n";
    print '<meta charset="utf-8">'."\n";
    print '<meta name="viewport" content="width=device-width, initial-scale=1">'."\n";
    print '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">'."\n";
    print "</head>\n";
}


sub print_html_body_section_top {
    # Create HTML body and show values from 1 - $max ($ncols per row)
    print '<body>'."\n";
    print '<div class="container">'."\n";
    print '<h1>Oxd Perl Application</h1>'."\n";
   
}

sub print_html_body_section_bottom {    
   
    print '</div>'."\n";
    print '</body>'."\n";
    print '</html>'."\n";
}

# Displays the  form
sub print_html_form {
	my $error_message = shift;
    my $your_mail = shift;
    my $gluu_server_url = shift;
    

    # Remove any potentially malicious HTML tags
    if($your_mail){
		$your_mail =~ s/<([^>]|\n)*>//g;
	}else{
		$your_mail = "";
	}
	if(!$gluu_server_url){
		$gluu_server_url = "";
	}
	
	print '<div class="row">'."\n";
    print '<div class="col-md-4">'."\n";
    if($error_message){
		print '<p>'.$error_message.'</p>';
	}
	print '<form name="gluu-form" action="index.cgi" method="post" >
				<div class="form-group">
					<label for="email">Your Email</label>
					<input type="email" class="form-control" id="email" name="your_mail" placeholder="Email" value="'.$your_mail.'" />
				</div>
				<div class="form-group">
					<label for="gluu_server_url">Your Gluu server url</label>
					<input type="text" class="form-control" id="gluu_server_url" name="gluu_server_url" placeholder="Gluu server url" value="'.$gluu_server_url.'"  />
				</div>
				<input type="hidden" name="submit" value="Submit">
				<input type="submit" name="submit" value="Login" class="btn btn-success" >
			</form>'."\n";
	print '</div>'."\n";
    print '</div>'."\n";
}

# Validate submiited data
sub validate_form
{
    my $your_mail = $cgi->param("your_mail");
    my $gluu_server_url = $cgi->param("gluu_server_url");
   
    my $error_message = "";

    $error_message .= "Please enter your email<br/>" if ( !$your_mail );
    $error_message .= "Please specify your gluu url<br/>" if ( !$gluu_server_url );
    
    if ( $error_message )
    {
        # Errors with the form - redisplay it and return failure
        print_html_form ( $error_message, $your_mail, $gluu_server_url);
        return 0;
    }
    else
    {
        # Form OK - return success
        return 1;
    }
}

# Displays the results of the form
sub display_results {
	if ( validate_form ( ) ){
		my $email = $cgi->param('your_mail');
		my $gluu_server_url = $cgi->param('gluu_server_url');
        
        print '<div class="row">'."\n";
        print '<div class="col-md-8">'."\n";
		print $cgi->h4("Your Email: $email");
		print $cgi->h4("Your Gluu server url:  $gluu_server_url");
		print '</div>';
		print '</div>';
		# in main program
		#my $worker = Employee->new("Fred Flintstone", 1234, 40);
		oxd_authentication($email, $gluu_server_url);
		
	}
}

sub oxd_authentication{
	
	my ($emal, $gluu_server_url) = @_;
   
	use Data::Dumper;
	my $oxd_id = $session->param('oxd_id');
	
	#print $oxd_id ;
	if($session->param('oxd_id') eq ""){
		my $register_site = new OxdRegister( );
		
 		$register_site->setRequestOpHost($gluu_server_url);
		$register_site->setRequestAcrValues($acrValues);
		$register_site->setRequestAuthorizationRedirectUri($authorizationRedirectUrl);
		$register_site->setRequestPostLogoutRedirectUri($postLogoutRedirectUrl);
		$register_site->setRequestContacts([$emal]);
		$register_site->setRequestGrantTypes($grantType);
		$register_site->setRequestResponseTypes($responseType);
		$register_site->setRequestScope($scope);
		$register_site->setRequestApplicationType($applicationType);
		$register_site->request();

		if($register_site->getResponseOxdId()){
			# storing data in the session
			$session->param('oxd_id', $register_site->getResponseOxdId());
			# retrieving data
			my $oxd_id = $session->param('oxd_id');
			$session->save_param($cgi, ["oxd_id"]);
			
		
			$update_site_registration = new UpdateRegistration();
			
			$update_site_registration->setRequestAcrValues($acrValues);
			$update_site_registration->setRequestOxdId($oxd_id);
			$update_site_registration->setRequestAuthorizationRedirectUri($authorizationRedirectUrl);
			$update_site_registration->setRequestPostLogoutRedirectUri($postLogoutRedirectUrl);
			$update_site_registration->setRequestContacts([$emal]);
			$update_site_registration->setRequestGrantTypes($grantType);
			$update_site_registration->setRequestResponseTypes($responseType);
			$update_site_registration->setRequestScope($scope);
			$update_site_registration->request();
			
			$session->param('oxd_id', $update_site_registration->getResponseOxdId());
			
			
		}
	}

	
	$get_authorization_url = new GetAuthorizationUrl( );
	$get_authorization_url->setRequestOxdId($session->param('oxd_id'));
	$get_authorization_url->setRequestScope($scope);
	$get_authorization_url->setRequestAcrValues($acrValues);
	$get_authorization_url->request();
    my $oxdurl = $get_authorization_url->getResponseAuthorizationUrl();
    
    #print $get_authorization_url->getResponseAuthorizationUrl();
	#print "<META HTTP-EQUIV=refresh CONTENT=\"$t;URL=$oxdurl\">";
	print '<meta http-equiv="refresh" content="0;URL='.$oxdurl.'" />    ';


	#exit 0;
}

sub server_side_ajax {
    my $mode = param('mode') || "";
    ($mode eq 'info') or return;

    # If we get here, it's because we were called with 'mode=info'
    # in the HTML request (via the ajax function 'ajax_info()').
    ##
    print "Content-type:  text/html\n\n";  # Never forget the header!
    my $ltime = localtime();
    print "Server local time is $ltime";
    exit;
}


