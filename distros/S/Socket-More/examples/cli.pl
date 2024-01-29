#Example for processing command line arguments
use v5.36;
use Socket::More;
use Getopt::Long;

use Data::Dumper;
use Text::Table;

my @listen;
my $help;
GetOptions(
	"listen=s@"=>\@listen,
	"help"=>\$help
);

sub dump_listeners {
	#Generate a table of all the listeners

	my $tab=Text::Table->new("Interface", "Address", "Family", "Group", "Port", "Path", "Type", "Data");
	$tab->load([
			$_->{interface},
			$_->{address},
			family_to_string($_->{family}),
			$_->{group},
			$_->{port},
			$_->{path},
			sock_to_string($_->{type}),
			join ",",($_->{data}//[])->@*

		])
	for @_;
	join "", $tab->table;

}

if($help or @listen==0){
	say "specify one or more listener specification in the following format:
		-l host:port
		-l :port
		-l interface=en0,type=stream,family=>INET

	";
}
my @spec=map parse_passive_spec($_), @listen;

#say "Parsed specifications:";


my @passive=map sockaddr_passive($_), @spec;
#say Dumper @passive;
say dump_listeners @passive;


#The items in @passive, contain an addr field, this is the on you want to bind with
# eg
# for(@passive){
# 	socket my $socket, $_->{family},$_->{type},0;
# 	bind $socket $_->{addr};
# }





