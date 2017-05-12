#!/usr/bin/env perl 

use Data::Dumper;

MyApp->run( daemon => 0 );

print Dumper($c);

1;

package MyApp;

use Data::Dumper;

use base 'NetSDS::App';

sub start {

	my ($this) = @_;

	$this->use_features('NetSDS::Kannel' => 'kannel');

	print Dumper($this);

}

sub process {

	my $this = shift;

	for (my $i=1; $i<10; $i++) {

		$this->log( "info", "My PID: " . $$a ."; iteration: $i" );

		sleep 1;
	}

	#print Dumper($this);
	#$this->{resp}->{data} = Dumper($this);

	#$this->{resp}->{mime} = 'text/plain';
	#$this->{resp}->{data} = "TEST: " . $this->cgi->param('test');
}

1;
