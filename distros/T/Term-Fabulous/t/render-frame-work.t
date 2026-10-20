use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::UI;
use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;

# A UI of one root box with a child box, drawn without a terminal.
sub ui () {
	my $root  = Term::Fabulous::Widget::Box->new;
	my $child = Term::Fabulous::Widget::Box->new;
	$root->add_child($child);
	return ( Term::Fabulous::Static->new( root => $root, width => 4, height => 1 ), $child );
}

subtest 'after_draw runs once, each_draw after every frame until it returns true' => sub {
	my ($ui) = ui();
	my @ran;
	$ui->after_draw( sub { push @ran, 'once'; return } );
	my $calls = 0;
	$ui->each_draw( sub { push @ran, 'each'; return ++$calls == 3 } );
	$ui->draw for 1 .. 4;
	is \@ran, [qw(once each each each)], 'after_draw once; each_draw until its third call returned true';
	$ui->each_draw(
		sub {
			$ui->each_draw( sub { push @ran, 'queued'; return 1 } );
			return 1;
		}
	);
	$ui->draw;
	is scalar( grep { $_ eq 'queued' } @ran ), 0, 'work registered by a callback waits for the next frame';
	$ui->draw;
	is $ran[-1], 'queued', 'and runs after it';
};

subtest 'owner-bound work gets its owner and ends with it' => sub {
	my ( $ui, $child ) = ui();
	my @owners;
	$ui->after_draw( sub ($owner) { push @owners, $owner; return }, owner => $child );
	$ui->each_draw( sub ($owner) { push @owners, $owner;  return 0 }, owner => $child, name => 'watch' );
	$ui->draw;
	is scalar @owners, 2, 'both ran';
	ref_is $owners[$_], $child, "with the owner ($_)" foreach 0, 1;
	@owners = ();

	$child->parent->remove_child($child);
	$ui->draw;
	is \@owners, [], 'an owner that left the UI is not called';
	$ui->root->add_child($child);
	$ui->draw;
	is \@owners, [], 'and its work ended: it does not come back with the owner';

	my $loose = Term::Fabulous::Widget::Box->new;
	$ui->root->add_child($loose);
	my $ran = 0;
	$ui->each_draw( sub ($owner) { $ran++; return 0 }, owner => $loose );
	$ui->root->remove_child($loose);
	undef $loose;
	$ui->draw;
	is $ran, 0, 'the UI holds the owner weakly: a freed owner is not called';
};

subtest 'frames caps the calls' => sub {
	my ($ui) = ui();
	my $calls = 0;
	$ui->each_draw( sub { $calls++; return 0 }, frames => 3 );
	$ui->draw for 1 .. 5;
	is $calls, 3, 'called after the first three frames only';
};

subtest 'a name replaces the registration of the same owner, and queues it last' => sub {
	my ( $ui, $child ) = ui();
	my @ran;
	$ui->each_draw( sub ($owner) { push @ran, 'first'; return 0 }, owner => $child, name => 'job' );
	$ui->each_draw( sub { push @ran, 'other'; return 0 } );
	$ui->each_draw( sub ($owner) { push @ran, 'second'; return 0 }, owner => $child, name => 'job' );
	$ui->each_draw( sub { push @ran, 'unbound'; return 0 }, name => 'job' );
	$ui->draw;
	is \@ran, [qw(other second unbound)], 'the first job ended; an unbound job of the same name is another one';
	@ran = ();
	$ui->each_draw( sub { push @ran, 'unbound again'; return 1 }, name => 'job' );
	$ui->draw;
	is \@ran, [ 'other', 'second', 'unbound again' ], 'without an owner the name is the key';
};

subtest 'a dying callback ends; the others run, then draw dies with its error' => sub {
	my ($ui) = ui();
	my @ran;
	$ui->each_draw( sub { die "broken\n" } );
	$ui->each_draw( sub { push @ran, 'after'; return 0 } );
	like dies { $ui->draw }, qr/\Abroken$/, 'the error leaves draw';
	is \@ran, ['after'], 'after the next callback ran';
	ok lives { $ui->draw }, 'the dying one ended';
	is \@ran, [ 'after', 'after' ], 'the other one goes on';
};

subtest 'arguments' => sub {
	my ($ui) = ui();
	like dies { $ui->after_draw('later') }, qr/after_draw needs a code reference, got 'later'/, 'a code reference is needed';
	like dies {
		$ui->after_draw( sub { }, name => 'x' )
	}, qr/after_draw does not take name \(known: owner\)/, 'after_draw takes only an owner';
	like dies {
		$ui->each_draw( sub { }, owner => 'me' )
	}, qr/each_draw takes a widget as its owner, got 'me'/, 'an owner is a widget';
	like dies {
		$ui->each_draw( sub { }, frames => 0 )
	}, qr/each_draw: frames must be a positive integer, got '0'/, 'frames is a positive integer';
	like dies {
		$ui->each_draw( sub { }, name => [] )
	}, qr/each_draw: name must be a string/, 'a name is a string';
	like dies {
		$ui->each_draw( sub { }, every => 2 )
	}, qr/each_draw does not take every \(known: owner name frames\)/, 'another option dies';
};

subtest 'Widget::each_frame' => sub {
	my ( $ui, $child ) = ui();
	my @ran;
	is $child->each_frame( sub ($widget) { push @ran, $widget; return 1 }, name => 'mine' ), 1, 'registers with the UI';
	$ui->draw;
	ref_is $ran[0], $child, 'bound to the widget';
	my $later = Term::Fabulous::Widget::Box->new;
	my @waited;
	is $later->each_frame( sub ($widget) { push @waited, 'old'; return 1 }, name => 'wait' ), 1, 'outside a UI the work waits';
	$later->each_frame( sub ($widget) { push @waited, 'new'; return 1 }, name => 'wait' );
	$ui->draw;
	is \@waited, [], 'it does not run while the widget is in no UI';
	$ui->root->add_child($later);
	$ui->draw;
	is \@waited, ['new'], 'it runs once the widget joined a UI; a name replaced the waiting work';
	my $plain    = Term::Fabulous::Widget::Box->new;
	my $plain_ui = Clay::UI->new( root => $plain, width => 4, height => 1 );
	is $plain->each_frame( sub { 1 } ), 0, 'nor in a UI that draws no frames';
	like dies {
		$child->each_frame( sub { 1 }, owner => $child )
	}, qr/each_frame does not take owner \(known: name frames\)/, 'the owner is the widget';
};

done_testing;
