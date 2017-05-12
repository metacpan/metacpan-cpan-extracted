#the dumb terminal webmysql module
#mt 16/11/2003 2.4	moved version into this module
package Plack::App::WebMySQL;
use strict;
use warnings;
use CGI::Compile;
use CGI::Emulate::PSGI;
use Plack::Builder;
use Plack::App::MCCS;
use Exporter();
use File::Share ':all';
use File::Spec;
our %form;	#data from the previous page
our $error = "";	#error flag
our $VERSION ="3.02";	#version of this software
our @ISA = qw(Exporter);
our @EXPORT = qw(%form $error $VERSION);
###############################################################################
sub new{
	my $script = dist_file('Plack-App-WebMySQL', 'cgi-bin/webmysql/webmysql.cgi');
	my $sub = CGI::Compile->compile($script);
	my $app = CGI::Emulate::PSGI->handler($sub);

	my $staticDir = dist_dir('Plack-App-WebMySQL');
	$staticDir = File::Spec->catdir($staticDir, 'htdocs');
	my $staticApp = Plack::App::MCCS->new(root => $staticDir)->to_app;
		
	my $builder = Plack::Builder->new();
	$builder->mount("/app" => $app);	
	$builder->mount("/" => $staticApp);
	return $builder;
}
###############################################################################
return 1;
