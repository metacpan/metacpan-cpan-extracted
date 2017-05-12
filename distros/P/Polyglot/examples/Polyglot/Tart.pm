package Polyglot::Tart;

use vars qw($VERSION);

$VERSION = 0.10;

package Polyglot;

print "Loaded Tart\n";

map { $polyglot->add_state( $_ ) } qw( FATAL REFERER VERBOSE STICKY CONTENT_TYPE );
map { $polyglot->add_toggle( $_ ) } qw( COOKIES REDIRECT STICKY );
map { $polyglot->add_action( @$_ ) }
	[ 'DUMP', sub {
		my $self = shift;
		print "$0 state\n\n";
		
		my $pad_length = 20;
		foreach my $state ( grep { $self->{$_}[0] eq $polyglot->state } 
			$self->directives )
			{
			printf "%-*s %s\n", $pad_length, $state, $self->{$state}[ 2 ];
			}
			
		} ];

1;