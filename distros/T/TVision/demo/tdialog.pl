use strict;
use TVision (':commands', 'tnew');

sub createFindDialog {
    my $d = tnew(TDialog=>[ 0, 0, 38, 12 ], "Find");
    #$d->set_options ($d->get_options | ofCentered); # d->options |= ofCentered;

    my $control = tnew(TInputLine=>[3, 3, 32, 4], 80 );
    $d->insert( $control );
    $d->insert( tnew( TLabel=>[2, 2, 15, 3], "~T~ext to find", $control ));
    $d->insert( tnew( THistory=>[ 32, 3, 35, 4 ], $control, 10 ));

    $d->insert(
	    tnew( TCheckBoxes=> [ 3, 5, 35, 7 ],
		# this sebfaults:
		# tnew (TSItem=> "~C~ase sensitive", tnew (TSItem=> "~W~hole words only", 0 )) # TODO
		# this works:
		[ "~C~ase sensitive", "~W~hole words only"]
	    )
	);

    $d->insert( tnew( TButton=> [ 14, 9, 24, 11 ], "O~K~", cmOK, bfDefault ) );
    $d->insert( tnew( TButton=> [ 26, 9, 36, 11 ], "Cancel", cmCancel, bfNormal ) );

    #$d->selectNext( 0 );
    return $d;
}

sub createReplaceDialog {
    my $d = tnew (TDialog=> [ 0, 0, 40, 16 ], "Replace" );

    $d->set_options ($d->get_options | ofCentered); # d->options |= ofCentered;

    my $control = tnew(TInputLine=>[3, 3, 34, 4], 80 );
    $d->insert( $control );
    $d->insert( tnew( TLabel=>[2, 2, 15, 3], "~T~ext to find", $control ));
    $d->insert( tnew( THistory=>[ 34, 3, 37, 4 ], $control, 10 ));

    $control = tnew( TInputLine=> [ 3, 6, 34, 7 ], 80 );
    $d->insert( $control );
    $d->insert( tnew (TLabel=> [ 2, 5, 12, 6 ], "~N~ew text", $control ) );
    $d->insert( tnew (THistory=> [ 34, 6, 37, 7 ], $control, 11 ) );

    $d->insert( tnew (TCheckBoxes => [ 3, 8, 37, 12 ], [
        "~C~ase sensitive (учит. рег-р)",
        "~W~hole words only",
        "~P~rompt on replace",
        "~R~eplace all"]
        #new TSItem("~C~ase sensitive",
        #new TSItem("~W~hole words only",
        #new TSItem("~P~rompt on replace",
        #new TSItem("~R~eplace all", 0 ))))
	));

    $d->insert( tnew (TButton=> [ 17, 13, 27, 15 ], "O~K~", cmOK, bfDefault ) );
    $d->insert( tnew (TButton => [ 28, 13, 38, 15 ], "Cancel", cmCancel, bfNormal ) );

    #$d->selectNext( 0 );
    return $d;
}


my $tapp = tnew 'TVApp';
my $desktop = $tapp->deskTop;

$desktop->insert(createFindDialog);
$desktop->insert(createReplaceDialog);

$tapp->run;

