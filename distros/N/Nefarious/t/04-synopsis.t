use Types::Standard qw/Str HashRef/;

our $make_accessor;
BEGIN {
	$make_accessor = sub {
		my ($key) = shift;
		return sub {
			$_[0]->{$key} = $_[1] if $_[1];
			$_[0]->{$key};
		};
	};
}

use Nefarious {
	Properties => {
		size => $make_accessor->('size'),			
		colour => $make_accessor->('colour'),
		material => $make_accessor->('material'),
	},
	Product => {
		new => sub {
			my $self = bless {}, shift;
			$self->set(@_);
			$self;
		},
		name => $make_accessor->('name'),
		description => $make_accessor->('description'),
		properties => sub {
			my ($self, $props) = @_;
			$self->{properties} //= Properties->new();
			if ($props) {
				$self->{properties}->$_($props->{$_}) for (keys %{$props});
			}
			$self->{properties};
		},
		set => [
			[Str, Str, HashRef, sub {
				$_[0]->name($_[1]);
				$_[0]->description($_[2]);
				$_[0]->properties($_[3]);
			}],
			[Str, Str, sub {
				$_[0]->name($_[1]);
				$_[0]->description($_[2]);
			}],
			[Str, sub {
				$_[0]->name($_[1]);
			}],
			sub {
				$_[0]->name('Set the name of the Product');
				$_[0]->description('Set the description of the Product');
			}
		],
		Hat => {
			onesize => $make_accessor->('onesize'),
			Bowler => {
				onesize => 0,
			}
		}
	}
};


use Test::More;

my $product = Product->new('T-Shirt', 'Just a plane old t-shirt', { size => 'L', colour => 'red', material => 'cotton' });

is($product->name, 'T-Shirt');
is($product->description, 'Just a plane old t-shirt');
is_deeply($product->properties, { size => 'L', colour => 'red', material => 'cotton' });

my $flat = Bowler->new('Some Brand', 'A bowler hat made from 100% Wool', { size => '60cm', colour => 'black', material => 'wool' });

is($flat->onesize, 0);

done_testing();
