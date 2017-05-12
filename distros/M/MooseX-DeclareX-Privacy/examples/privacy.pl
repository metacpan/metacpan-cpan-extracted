use 5.010;
use MooseX::DeclareX
	plugins => [qw(private public protected)],
	;

class Monkey
{
	public method screech (@thoughts) {
		say $_ for @thoughts;
	}	
		
	private method think (@thoughts) {
		say "... $_" for @thoughts;
	}
	
	public method hear (@ideas) {
		$self->think(grep { rand(100) < 30 } @ideas);
	}
}

my $bobo = Monkey->new;
$bobo->screech("Eee!");
$bobo->hear(qw(A B C D E F G H I J));
$bobo->think("Hmmm...");
