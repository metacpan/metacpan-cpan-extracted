
#
# vim:ts=2:sw=2
#
package Shell::Grid;

use Tk;
use Tk::Table;

my ($gout, $tab);

sub cw {
	my $self = shift;
	my $mw = $self->{mw};
	$gout = $mw->Toplevel();
	$gout->title( "Grid Table out" );

	$tab = $gout->Table( -takefocus => 1, -scrollbars => 'nw',
		-fixedrows => 1,
	)->pack();
}

my ($row, $col);

sub h {
	my $self = shift;
	my @col  = @_;
	for $x (@col) {
		$ha{$x} = $tab->Button( -text => $x );
		$tab->put( $row, $col, $ha{$x} );
		$col++;
	}
	$row++;
}

sub r {
	my $self = shift;
	my @col  = @_;
	$col = 0;
	for $x (@col) {
		my $old = $tab->Label( -text => $x );
		$tab->put( $row, $col, $old );
		$col++;
	}
	$row++;
}

sub release {
	my $self = shift;
	$gout->destroy() if Tk::Exists($gout);
	$gout = undef;
	$tab  = undef;
	$row  = 0;
	$col  = 0;
}
1;
