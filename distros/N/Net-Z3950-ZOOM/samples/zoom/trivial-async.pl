use ZOOM;
@servers = ('lx2.loc.gov:210/LCDB_MARC8',
	    'z3950.indexdata.com:210/gils',
	    'agricola.nal.usda.gov:7190/Voyager');
for ($i = 0; $i < @servers; $i++) {
    $z[$i] = new ZOOM::Connection($servers[$i], 0,
				  async => 1, # asynchronous mode
				  count => 1, # piggyback retrieval count
				  preferredRecordSyntax => "usmarc");
    $r[$i] = $z[$i]->search_pqf("mineral");
}
while (($i = ZOOM::event(\@z)) != 0) {
    $ev = $z[$i-1]->last_event();
    print("connection ", $i-1, ": ", ZOOM::event_str($ev), "\n");
    if ($ev == ZOOM::Event::ZEND) {
	$size = $r[$i-1]->size();
	print "connection ", $i-1, ": $size hits\n";
	print $r[$i-1]->record(0)->render()
	    if $size > 0;
    }
}
