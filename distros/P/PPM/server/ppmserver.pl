
# SOAP-Lite PPM server front-end

use SOAP::Transport::HTTP;

# The following is needed for performance reasons with SOAP-Lite
# v. 0.43, due to the fact that the server moves big chunks of XML.
*SOAP::Serializer::as_string = \&SOAP::XMLSchema1999::Serializer::as_base64;

# This needs to be used here, so we can access it in PPMServer.pm
use PPM::XML::RepositorySummary;

# Change this to point to the directory containing PPMServer.pm
$serverdir = '/home/http/soap/lib';

SOAP::Transport::HTTP::CGI
  -> dispatch_to($serverdir) 
  -> handle
;
