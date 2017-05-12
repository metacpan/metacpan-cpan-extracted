
package RayApp::CGIStorable;
use RayApp ();
use Storable ();
use IO::ScalarArray ();

use vars qw! @params @style_params !;

BEGIN {
	
	my ($rayapp, $dsd);
	if (defined $ENV{'RAYAPP_INPUT_MODULE'}) {

		eval "use $ENV{'RAYAPP_INPUT_MODULE'};";
		if ($@) {
			print "Status: 500\nContent-Type: text/plain\n\nError loading input module $ENV{'RAYAPP_INPUT_MODULE'}\n$@";
			exit;
		}

		if (@ARGV) {
			$rayapp = new RayApp;
			$dsd = $rayapp->load_dsd(shift);
		}

		my $handler = "$ENV{'RAYAPP_INPUT_MODULE'}::handler";
		{
		no strict;
		eval { @params = &{ $handler }( $dsd ); };
		}
		if ($@) {
			print "Status: 500\nContent-Type: text/plain\n\nError running input module $ENV{'RAYAPP_INPUT_MODULE'}::handler\n$@";
			exit;
		}
	}
	if (defined $ENV{'RAYAPP_STYLE_PARAMS_MODULE'}) {

		eval "use $ENV{'RAYAPP_STYLE_PARAMS_MODULE'};";
		if ($@) {
			print "Status: 500\nContent-Type: text/plain\n\nError loading style params module $ENV{'RAYAPP_STYLE_PARAMS_MODULE'}\n$@";
			exit;
		}

		if (@ARGV and not defined $dsd) {
			$rayapp = new RayApp;
			$dsd = $rayapp->load_dsd(shift);
		}

		my $handler = "$ENV{'RAYAPP_STYLE_PARAMS_MODULE'}::handler";
		{
		no strict;
		eval { @style_params = &{ $handler }( $dsd, @params ); };
		}
		if ($@) {
			print "Status: 500\nContent-Type: text/plain\n\nError running style params module $ENV{'RAYAPP_STYLE_PARAMS_MODULE'}::handler\n$@";
			exit;
		}
	}
}

END {
	my @data;
	tie *STDOUT, IO::ScalarArray, \@data;
	my $value = eval { main::handler( @params ) };
	untie *STDOUT;

	if ($@) {
		print "Status: 500\nContent-Type: text/plain\n\nError running application $0\n$@";
		exit;
	}
	if (ref $value) {
		print "Content-Type: application/x-perl-storable\n\n";
		if (@style_params) {
			print Storable::freeze([ $value, @style_params ]);
		} else {
			print Storable::freeze( $value );
		}
	} else {
		print "Status: $value\n";
		print @data;
	}
}

1;

