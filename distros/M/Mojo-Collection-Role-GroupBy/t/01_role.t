use Test::More tests => 3;
use Mojo::Collection;
use Mojo::Util qw/dumper/;
use Data::Dumper;

sub dumper { Data::Dumper->new([@_])->Indent(0)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump }

$\ = "\n"; $, = "\t";

my $c = Mojo::Collection->new([0,"a"],[1,"b"],[2,"c"],[3,"d"],[4,"e"],[5,"f"])->with_roles('+GroupBy');

is_deeply($c->group_by(sub { $_->[0] % 2 }, { plain => 1 })->to_grouped_array,
	  [[[0,"a"],[2,"c"],[4,"e"]],[[1,"b"],[3,"d"],[5,"f"]]],
	  "plain"
	 );

is_deeply($c->to_hash(sub { $_->[0] % 2 }),
	  {"0" => [[0,"a"],[2,"c"],[4,"e"]],"1" => [[1,"b"],[3,"d"],[5,"f"]]},
	  "hash conversion on one go"
	 );


is_deeply($c->group_by(sub { $_->[0] % 2 })->to_hash,
	  {"0" => [[0,"a"],[2,"c"],[4,"e"]],"1" => [[1,"b"],[3,"d"],[5,"f"]]},
	  "group and then hash conversion");

