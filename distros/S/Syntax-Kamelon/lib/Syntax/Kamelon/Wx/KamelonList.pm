package Syntax::Kamelon::Wx::KamelonList;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use Wx qw(:sizer :panel :window :id :listbox :dialog :filedialog wxDefaultPosition);
use base qw( Wx::Panel );
use Wx::Event qw( EVT_BUTTON EVT_LISTBOX );
use File::Copy;
use File::Basename;

sub new {
	my $class = shift;
	my $indexer = shift;
	my $filter = shift;
	my $self = $class->SUPER::new(@_);

	my $buttonbar = Wx::Panel->new($self, -1);
	my $bsiz = Wx::BoxSizer->new(wxHORIZONTAL);
	$buttonbar->SetSizer($bsiz);
	
	my $id = Wx::NewId;
	my $list = Wx::ListBox->new($self, $id, [-1,-1],[200,250], [], wxLB_NEEDED_SB | wxLB_HSCROLL | wxLB_SINGLE);
	$self->{List} = $list;
	
	EVT_LISTBOX($self, $list, \&listOpen);

	my $sizer = Wx::BoxSizer->new(wxVERTICAL);
	$sizer->Add($buttonbar, 0, wxEXPAND | wxALL, 2);
	$sizer->Add($list, 1, wxEXPAND | wxALL, 2);
	$self->SetSizer($sizer);

	$self->{ListCallback} = sub { print "opening " . shift . "\n" };
	my @l = $indexer->AvailableSyntaxes;
	my @li = ();
	for (@l) {
		unless (&$filter($_)) {
			push @li, $_
		}
	}
	$list->Set(\@li);

	return $self;
}

sub lastSel {
	my $self = shift;
	if (@_) { $self->{LastSel} = shift; }
	return $self->{LastSel}
}

sub listCallback {
	my $self = shift;
	if (@_) { $self->{ListCallback} = shift; }
	return $self->{ListCallback}
}

sub listOpen {
	my ($self, $event) = @_;
	my $lang = $event->GetString;
	my $sub = $self->listCallback;
	if (&$sub($lang)) {
		$self->lastSel($lang)
	} 
}

sub listRemove {
}

1;
__END__
