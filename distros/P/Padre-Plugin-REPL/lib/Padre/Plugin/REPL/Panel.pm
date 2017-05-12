package Padre::Plugin::REPL::Panel;

use strict;
use warnings;

our $VERSION = '0.01';

use Padre::Wx;
use Padre::Util qw/_T/;
use Wx qw/WXK_UP WXK_DOWN/;
use base 'Wx::Panel';

sub new {
	my $class      = shift;
	my $main       = shift;
	my $self       = $class->SUPER::new( Padre::Current->main->bottom );
	my $box        = Wx::BoxSizer->new(Wx::wxVERTICAL);
	my $bottom_box = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	my $output     = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_READONLY
			| Wx::wxTE_MULTILINE
			| Wx::wxTE_DONTWRAP
			| Wx::wxNO_FULL_REPAINT_ON_RESIZE,
	);
	$box->Add( $output, 2, Wx::wxGROW );
	my $input = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_PROCESS_ENTER
	);
	Wx::Event::EVT_TEXT_ENTER( $self, $input, \&Padre::Plugin::REPL::evaluate );
	Wx::Event::EVT_CHAR( $input, \&Padre::Plugin::REPL::Panel::process_key );
	my $button = Wx::Button->new( $self, -1, _T("Evaluate") );
	Wx::Event::EVT_BUTTON( $self, $button, \&Padre::Plugin::REPL::evaluate );
	$bottom_box->Add( $input, 1 );
	$bottom_box->Add($button);
	$box->Add( $bottom_box, 1, Wx::wxGROW );
	$self->SetSizer($box);
	Padre::Current->main->bottom->show($self);
	return ( $input, $output );
}

sub process_key {
	my ( $input, $event ) = @_;
	my $code = $event->GetKeyCode;

	if ( $code == WXK_UP ) {
		Padre::Plugin::REPL::History::go_previous();
	} elsif ( $code == WXK_DOWN ) {
		Padre::Plugin::REPL::History::go_next();
	}
	$event->Skip();
}

sub gettext_label {
	return "REPL";
}

1;

