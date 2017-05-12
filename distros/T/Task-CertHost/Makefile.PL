use inc::Module::Install;

name         'Task-CertHost';
abstract     'Install PerlCertifiedHosting module requirements';
author       'Lyle Hopkins <cosmicnet@cpan.org>';
version_from 'lib/Task/CertHost.pm';
license      'perl';

# All the things we need for PerlCertifiedHosting

### Database section
requires     'Bundle::DBI' => 0;
requires     'DBD::mysql' => 0;
requires     'DBD::ODBC' => 0;
requires     'DBD::Pg' => 0;
requires     'DBD::SQLite' => 0;

### CGI
requires     'Bundle::LWP' => 0;
requires     'CGI' => 0;
requires     'CGI::Simple' => 0;
requires     'FCGI' => 0;
requires     'CGI::Fast' => 0;

### Frameworks
requires     'Task::CGI::Application' => 0;
requires     'Task::Catalyst' => 0;

### Encryption
requires     'Digest::MD5' => 0;
requires     'Digest::SHA1' => 0;

### XML
requires     'XML::Stream' => 0;
requires     'XML::Parser' => 0;
requires     'XML::Simple' => 0;

### MIME
requires     'MIME::Parser' => 0;
requires     'MIME::Base64' => 0;
requires     'MIME::Lite' => 0;

### HTML
requires     'HTML::Parser' => 0;
requires     'HTML::TreeBuilder' => 0;

### Misc
requires     'DateTime' => 0;
requires     'Date::Calc' => 0;
requires     'GD' => 0;
requires     'Image::Size' => 0;
requires     'Storable' => 0;
requires     'Net::DNS' => 0;


WriteAll;

