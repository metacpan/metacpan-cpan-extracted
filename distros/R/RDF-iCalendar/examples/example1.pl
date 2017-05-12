use HTML::Microformats;
use RDF::TrineX::Functions -shortcuts;
use RDF::iCalendar::Exporter;

my $hcalendar = <<'HTML';

	<div class="hentry" id="fooble">
		<span class="entry-title">Foo</span>
		<span class="published updated">2011-02-02</span>
	</div>
	
	<div class="vfreebusy">
		<b class="summary">I'm busy some times</b>
		<i class="freebusy">
			<u class="fbtype">busy</u>
			<b class="value">19980415T133000Z/19980415T170000Z</b>
			<b class="value">19990415T133000Z/19990415T170000Z</b>
		</i>
	</div>

  <div class="vevent">
    <h1 class="uid" id="xmas">
      <span class="summary">Christmas</span> Schedule
    </h1>
    <abbr class="dtstart" title="0001-12-25" style="display:none"></abbr>
    <p class="comment rrule"><span class="freq">Yearly</span>
    period of festive merriment.</p>
    <div class="attendee vcard">
      <b class="role">
        <abbr title="REQ-PARTICIPANT">Required for merriment:</abbr>
      </b><br>
      <span class="fn">
        <span class="honorific-prefix nickname">Santa</span>
        <span class="given-name">Claus</span>
      </span>
      (<span class="adr><span class="region">North Pole</span></span>)
    </div>
	 <p class="location geo">12;34</p>
  </div>
  
    <div class="vtodo">
      <h2 class="uid" id="shopping">Shopping</h2>
      <abbr class="dtstart" title="2008-12-01">In December</abbr>, don't forget
      to <span class="summary">buy everyone their presents</span> before the
      shops shut on <abbr class="due" title="2008-12-24T16:00:00">Christmas
      Eve</abbr>!
      <a class="attach" rel="enclosure" href="data:,Perl%20is%20good">attachment</a>
		<div class="valarm">
			<span class="summary">Reminder!</span>
			<span class="trigger">-PT12H</span>
		</div>
    </div>
    
    <div class="vevent">
      <h2 id="jones" class="uid summary">Jones' Christmas Lunch</h2>
      <p class="comment">The Joneses have been having a wonderful lunch 
      <abbr class="rrule" title="FREQ=YEARLY">every year</abbr> at
      <abbr class="dtstart" title="2003-12-25T13:00:00Z">1pm for the last
      few years</abbr>.</p>
      <p><span class="attendee">Everyone</span>'s invited.</p>
      <i class="category">Foo</i>
      <i class="category">Bar</i>
      <i class="category">Baz</i>
      <a rel="tag" href="/tag/Foo">Foo</a>
		<div class="location vcard">
			 <p class="adr">
				<span class="fn extended-address">Jones Household</span>
				<span class="locality">Lewes</span>
				<span class="region">East Sussex</span>
			 </p>
		 </div>
    </div>
  
  <div class="vevent">
    <h2 class="summary">Boxing Day</h2>
    <p class="comment">
      <abbr class="rrule" title="FREQ=YEARLY">Every year</abbr>
      <abbr class="dtstart" title="0001-12-26">the day after</abbr>
      <a class="related-to" href="#xmas" rel="vcalendar-sibling">Christmas</a>
      is Boxing Day. Nobody knows quite why this day is called that.
    </p>
	 <p class="contact organizer attendee vcard">
		<a class="fn email" href="mailto:alice@example.net">Alice Jones</a>
		<span class="role">required</span>
		<span class="sent-by vcard">
			<a class="fn email" href="mailto:bob@example.net">Bob Jones</a>
		</span>
	 </p>
	 <p class="location adr">
		<span class="locality">Lewes</span>
		<span class="region">East Sussex</span>
	 </p>
  </div>
  
  <div class="vevent">
  <p>Our organisation has been offering a series of <span class="summary"
  >summer lectures</span> since
  <abbr class="dtstart" title="19970105T083000">January 1997</abbr>. They
are
  <span class="rrule">
    held <span class="freq">yearly</span>,
    every <span class="interval">2</span>nd year (1999, 2001, etc),
    every <span class="byday">Sunday</span>
    in January <abbr class="bymonth" title="1" style="display:none"></abbr>
    at <span class="byhour">8</span>:<span class="byminute">30</span> and
    repeated at <span class="byhour">9</span>:30.
  </span>
</p>
</div>

HTML

my $doc = HTML::Microformats->new_document($hcalendar, 'http://hcal.example.net/')->assume_all_profiles;
my @objects = $doc->objects('hCalendar');
print $objects[0]->to_icalendar;

#print rdf_string($doc->model =>'RDFXML');
#print "========\n";
#my @cals = RDF::iCalendar::Exporter->new->export_calendars($doc->model);
#print "========\n";
#print $_ foreach @cals ;

