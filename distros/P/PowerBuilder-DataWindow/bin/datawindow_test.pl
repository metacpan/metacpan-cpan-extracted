
use strict;
use warnings;
use feature 'say';
use PowerBuilder::DataWindow;
use File::Slurp qw(slurp);
#use Data::Dumper::GUI;
use Data::Dumper;


my $file = shift || die "usage : $0 <file.srd>";
die unless -f $file;

my $data = slurp($file);
my $dw = PowerBuilder::DataWindow->new();
$dw->parse($data);


if($dw->select){
	say "Select from DB is: ". $dw->select;
} else {
	say "Datawindow external (no SELECT)";
}

#say Dumper(\$dw->select_columns);
my $selected = $dw->select_columns;
if ($selected){
	say "SELECTed columns are:";
	say sprintf("    #%-3d ", $selected->{$_}) . $_ foreach sort { $selected->{$a} <=> $selected->{$b} } keys %$selected;
} else {
	say "No selected column.";
}

say "Columns definitions:";
say sprintf("    #%-3d ", $_->{'#'}) . $_->{name} . " type=" . $_->{type} foreach sort { $a->{'#'} <=> $b->{'#'} } values %{$dw->column_definitions};

say "Columns controls are:";
say "    " . $_->{name} . " id=" . $_->{id} . " x=" . $_->{x} foreach sort { $a->{'id'} <=> $b->{'id'} } @{$dw->column_controls};

if ($dw->text_controls){
	say "Texts controls are:";
	say "    " . $_->{name} . " x=" . $_->{x} . " y=" . $_->{y} foreach sort { $a->{y} <=> $b->{y} || $a->{x} <=> $b->{x} } @{$dw->text_controls};
    } else {
    	say "No text control.";
    }
