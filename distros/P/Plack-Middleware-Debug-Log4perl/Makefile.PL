
use inc::Module::Install;
  
# Define metadata
name           'Plack-Middleware-Debug-Log4perl';

author        'Mike Tonks <miket@cpan.org>';
version_from  'lib/Plack/Middleware/Debug/Log4perl.pm';
license       'perl';
 
# Specific dependencies
requires       'Log::Log4perl'  => 0;
requires       'Plack::Middleware::Debug'  => 0;

#manifest_skip;

no_index directory => 'sample';

WriteAll;
