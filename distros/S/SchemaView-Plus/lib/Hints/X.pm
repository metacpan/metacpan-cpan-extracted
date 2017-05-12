package Hints::X;

use strict;
use vars qw/$VERSION/;
use Tk;

$VERSION = '0.02';

=head1 NAME

Hints::X - Perl extension for dialog for showing hints from hints databases

=head1 SYNOPSIS

	use Tk;
	use Hints;
	use Hints::X;

	my $mw = new Tk;

	my $hints = new Hints;
	$hints->load_from_file('my.hints');

	my $xhints = new Hints::X (-hints => $hints, -mw => $mw);
	$xhints->show;

=head1 DESCRIPTION

This module use Hints(3) module for showing its database in X dialog.
For X interface is Perl/Tk used.

=head1 THE HINTS::X CLASS

=head2 new

Constructor create dialog with database and controls. You must specify
Hints(3) instance for handling hints database and widget of Tk main window.

	my $xhints = new Hints::X (-hints => $hints, -mw => $mw);

=cut

sub new {
	my $class = shift;
	my %params = @_;
	my $obj = bless { }, $class;
	$obj->{hints} = $params{-hints} if $params{-hints};	
	$obj->{mw} = $params{-mw} if $params{-mw};	
	return undef unless $obj->{hints} and $obj->{mw};
	$obj->create_window;
	return $obj;
}

sub create_window {
	my $obj = shift;

	$obj->{w} = $obj->{mw}->Toplevel;
	$obj->{w}->withdraw;
	$obj->{w}->geometry($obj->default_geometry);
	$obj->{w}->resizable(0,0);
	$obj->{w}->title('Hints');
	$obj->{w}->iconname('Hints');
	$obj->{w}->client('hints');
	$obj->{current} = "???";

	my $f = $obj->{w}->Frame()->pack(-side => 'right', -fill => 'y');
	$f->Button(-text => 'Previous', -command => sub { $obj->previous; })
		->pack(-side => 'top', -expand => 'y', -fill => 'x');
	$f->Button(-text => 'Random', -command => sub { $obj->random; })
		->pack(-side => 'top', -expand => 'y', -fill => 'x');
	$f->Button(-text => 'Next', -command => sub { $obj->next; })
		->pack(-side => 'top', -expand => 'y', -fill => 'x');

	$f = $obj->{w}->Frame(-relief => 'ridge', -borderwidth => 2,
			-background => 'white')
		->pack(-side => 'left', -expand => 'y', -fill => 'both',
			-padx => 5, -pady => 5);
	$f->Label(-textvariable => \$obj->{current}, -wraplength => 360,
			-justify => 'left', -background => 'white')
		->pack(-fill => 'both', -expand => 'y');

	$obj->random;
}

=head2 show

Show window with hints.

	$xhints->show;

=cut

sub show {
	my $obj = shift;

	$obj->create_window unless Exists($obj->{w});
	$obj->{w}->deiconify;
	$obj->{w}->raise;
}

=head2 hide

Hide window with hints.

	$xhints->hide;

=cut

sub hide {
	my $obj = shift;

	$obj->{w}->withdraw;
}

=head2 showed

Is window with hints open and visible?

	do_something() if $xhints->showed;

=cut

sub showed {
	my $obj = shift;
	return Exists($obj->{w});
}

=head2 geometry

Wrapper for Tk::Widget geometry method.

	my $geom = $xhints->geometry;

=cut

sub geometry {
	my $obj = shift;
	return $obj->{w}->geometry(@_);
}

=head2 default_geometry

Defaults values for C<geometry()>.

	$xhints->geometry($xhints->default_geometry);

=cut

sub default_geometry {
	my $obj = shift;
	return "480x120";
}

sub random {
	my $obj = shift;
	$obj->{current} = $obj->{hints}->random;
}

sub previous {
	my $obj = shift;

	$obj->{current} = $obj->{hints}->backward;
}

sub next {
	my $obj = shift;

	$obj->{current} = $obj->{hints}->forward;
}

sub DESTROY {
	my $obj = shift;

	$obj->{w}->destroy if Exists($obj->{w});
}

1;

__END__

=head1 VERSION

0.02

=head1 AUTHOR

(c) 2001 Milan Sorm, sorm@pef.mendelu.cz
at Faculty of Economics,
Mendel University of Agriculture and Forestry in Brno, Czech Republic.

This module was needed for making SchemaView Plus (C<svplus>) for making
user-friendly hints interface.

=head1 SEE ALSO

perl(1), svplus(1), Hints(3), Tk(3).

=cut

