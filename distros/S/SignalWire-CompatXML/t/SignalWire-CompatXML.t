#-*- mode: cperl -*-#
use Test::More tests => 13;
BEGIN { use_ok('SignalWire::CompatXML') };

#########################

my $sw;

##
## simple response
##
$sw = new SignalWire::CompatXML;
$sw->Response({version => '2010-04-01'})->Say('hi');

is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response version="2010-04-01">
  <Say>hi</Say>
</Response>
!, "basic response" );


##
## multiple children
##
$sw = new SignalWire::CompatXML;
my $resp = $sw->Response({version => '2010-04-01'});
$resp->Say("Humpty dumpty");
$resp->Play("http://api.twilio.com/Cowbell.mp3");

is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response version="2010-04-01">
  <Say>Humpty dumpty</Say>
  <Play>http://api.twilio.com/Cowbell.mp3</Play>
</Response>
!, "multiple children" );


##
## deeper nesting
##
is( SignalWire::CompatXML->new->Response->Dial->Conference('1234')
    ->parent->parent->Say("Thanks for conferencing.")
    ->root->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Conference>1234</Conference>
  </Dial>
  <Say>Thanks for conferencing.</Say>
</Response>
!, "deeper nesting" );

is( SignalWire::CompatXML->new->Response({version => "2010-04-01"})
    ->Gather({method => "POST", finishOnKey => "#", action => "/cgi-bin/test"})
    ->Say("Enter the conference room number.")
    ->parent->parent->Say("Sorry you're having trouble.")
    ->root->to_string,

    q!<?xml version="1.0" encoding="UTF-8" ?>
<Response version="2010-04-01">
  <Gather action="/cgi-bin/test" finishOnKey="#" method="POST">
    <Say>Enter the conference room number.</Say>
  </Gather>
  <Say>Sorry you&apos;re having trouble.</Say>
</Response>
!, "deeper nesting" );


##
## built from nodes
##
$sw = new SignalWire::CompatXML;
$resp = new SignalWire::CompatXML(name => 'Response');
my $say = new SignalWire::CompatXML(name => 'Say');
$say->content("Bag o' doorknobs.");
$resp->add_child($say);
$sw->add_child($resp);

my $comp_tw = new SignalWire::CompatXML;
$comp_tw->Response->Say("Bag o' doorknobs.");

is_deeply($comp_tw, $sw, "build via add_child" );


##
## complex constructor
##
$resp = SignalWire::CompatXML->new->Response;
$resp->Say("Barbara Ann", {voice => 'woman'});  ## content and attributes
is( $resp->root->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say voice="woman">Barbara Ann</Say>
</Response>
!, "complex constructor" );


##
## more complex node
##
$sw = new SignalWire::CompatXML;
$resp = $sw->Response;
for my $i ( qw(foo bar baz) ) {
    my $s = new SignalWire::CompatXML(name => 'Say');
    $s->content("I say $i");
    $s->attributes({voice => "woman"});
    $resp->add_child($s);
}
is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say voice="woman">I say foo</Say>
  <Say voice="woman">I say bar</Say>
  <Say voice="woman">I say baz</Say>
</Response>
!, "build via add_child" );


##
## one-liner
##
is( SignalWire::CompatXML->new->Response->Say("Hi mom")->root->to_string,
    q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Hi mom</Say>
</Response>
!, "one-liner" );


##
## headers
##
is( SignalWire::CompatXML->new->Response->Say("Plugh")->root
    ->to_string({"Content-type" => "text/xml", "Bumbly-feely" => "Bessy" }),

    q!Bumbly-feely: Bessy
Content-type: text/xml

<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Plugh</Say>
</Response>
!, "content-type header" );


##
## strict
##
{
    my @tags = qw(Response Say Play Dial Conference);

    ok( SignalWire::CompatXML->can('Barf'), "can method" );

    local $SignalWire::CompatXML::STRICT = 1;
    local %SignalWire::CompatXML::TAGS = ();
    @SignalWire::CompatXML::TAGS{@tags} = (1) x @tags;

    ok( ! SignalWire::CompatXML->can('Barf'), "can method strict" );

    eval { SignalWire::CompatXML->new->Response->Barf('chunky') };
    like( $@, qr(^Undefined subroutine Barf), "strict method" );
}
