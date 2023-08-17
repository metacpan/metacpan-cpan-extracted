#-*- mode: cperl -*-#
use Test::More tests => 26;
use SignalWire::CompatXML;

#########################

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Connect()
      ->Room("my-room-name");

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Connect>
    <Room>my-room-name</Room>
  </Connect>
</Response>
!, "Connect example" );
}

{
    my $sw = new SignalWire::CompatXML;
  $sw->Response
      ->Denoise->parent
      ->Dial->Sip("sip:user@example.com;transport=udp");

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Denoise />
  <Dial>
    <Sip>sip:user.com;transport=udp</Sip>
  </Dial>
</Response>
!, "Denoise example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Dial
       ->Number("858-987-6543")->parent
       ->Number("415-123-4567")->parent
       ->Number("619-765-4321");

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Number>858-987-6543</Number>
    <Number>415-123-4567</Number>
    <Number>619-765-4321</Number>
  </Dial>
</Response>
!, "Dial example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Echo({timeout => "120"})->parent
       ->Hangup();

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Echo timeout="120" />
  <Hangup />
</Response>
!, "Echo example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Enqueue({waitUrl => "https://example.com/hold-music.xml"}, "support");

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Enqueue waitUrl="https://example.com/hold-music.xml">support</Enqueue>
</Response>
!, "Enqueue example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Dial
	->Number("858-987-6543")->parent
	->Number("415-123-4567")->parent
	->Number("619-765-4321");

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Number>858-987-6543</Number>
    <Number>415-123-4567</Number>
    <Number>619-765-4321</Number>
  </Dial>
</Response>
!, "Dial example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Gather({action => "https://example.com/process_gather.php",
		method => "GET"})
      ->Say("Please enter your account number, followed by the pound sign");

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Gather action="https://example.com/process_gather.php" method="GET">
    <Say>Please enter your account number, followed by the pound sign</Say>
  </Gather>
</Response>
!, "Gather example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Hangup;

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Hangup />
</Response>
!, "Hangup example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response->Hangup;

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Hangup />
</Response>
!, "Hangup example" );
}

{

    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Leave;

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Leave />
</Response>
!, "Leave example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Say("I will pause 5 seconds starting now.")->parent
      ->Pause({length => 5})->parent
      ->Say("I just paused 5 seconds");

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>I will pause 5 seconds starting now.</Say>
  <Pause length="5" />
  <Say>I just paused 5 seconds</Say>
</Response>
!, "Pause example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Play({ loop => 15 }, "rtmp://example.com/my-rtmp-stream");

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Play loop="15">rtmp://example.com/my-rtmp-stream</Play>
</Response>
!, "Play example" );
}

{
    my $sw = new SignalWire::CompatXML;
    $sw->Response
      ->Say("Please leave a message at the beep. Press the star key when finished.")->parent
      ->Record({action => "http://your-application.com/handleRecording.cgi",
		method => "GET",
		maxLength => "15",
		finishOnKey => "#"});


    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Please leave a message at the beep. Press the star key when finished.</Say>
  <Record action="http://your-application.com/handleRecording.cgi" finishOnKey="#" maxLength="15" method="GET" />
</Response>
!, "Recod example" );
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Dial("310-123-0000")->parent
    ->Redirect("http://www.your-application.com/next-instructions");

  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>310-123-0000</Dial>
  <Redirect>http://www.your-application.com/next-instructions</Redirect>
</Response>
!, "Redirect example" );
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
      ->Refer({action => "https://example.com/refer-completed.xml",
	       method => "GET"})
      ->Sip('sip:transfer-target@example.com');
  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Refer action="https://example.com/refer-completed.xml" method="GET">
    <Sip>sip:transfer-target@example.com</Sip>
  </Refer>
</Response>
!, "Refer example" );
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Reject({reason => "busy"});

  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Reject reason="busy" />
</Response>
!, "Reject example" );
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Say({voice => "woman", loop => "2"}, "Hello");

  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say loop="2" voice="woman">Hello</Say>
</Response>
!, "Say example" );
}

{
	my $sw = new SignalWire::CompatXML;
	$sw->Response
	  ->Say("Our store is located at 123 East St.")->parent
	  ->Sms({action => "/smsHandler.cgi", method => "POST"},
		"Store location: 123 East St.");
	is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Our store is located at 123 East St.</Say>
  <Sms action="/smsHandler.cgi" method="POST">Store location: 123 East St.</Sms>
</Response>
!, "Sms example" );
}

{
	my $sw = new SignalWire::CompatXML;
	$sw->Response
	  ->Start
	  ->Stream({url => "wss://streamer.signalwire.com"});

	is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Start>
    <Stream url="wss://streamer.signalwire.com" />
  </Start>
</Response>
!, "Stream example" );
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Connect()
    ->AI({ postPromptURL => "https://webhook.site/10d7acdaf140" })
    ->Prompt({ topP => '0.8', temperature => '1.0',
	       confidence => "0.6" }, "Hello, how are you today?" )->parent
		 ->postPrompt("Summarize the conversation.");

  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Connect>
    <AI postPromptURL="https://webhook.site/10d7acdaf140">
      <Prompt confidence="0.6" temperature="1.0" topP="0.8">Hello, how are you today?</Prompt>
      <postPrompt>Summarize the conversation.</postPrompt>
    </AI>
  </Connect>
</Response>
!, "AI example");
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Dial
    ->Conference({startConferenceOnEnter => "true",
		  endConferenceOnExit => "true"},
		 "1234");

  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Conference endConferenceOnExit="true" startConferenceOnEnter="true">1234</Conference>
  </Dial>
</Response>
!, "Conference example");
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Dial
    ->Number({sendDigits => "www56476" }, "858-987-6543");

  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Number sendDigits="www56476">858-987-6543</Number>
  </Dial>
</Response>
!, "Number example");
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Connect
    ->Room("my-room-name");

  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Connect>
    <Room>my-room-name</Room>
  </Connect>
</Response>
!, "Room example");
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Dial
    ->Sip('sip:alice@example.com;transport=udp');

  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Sip>sip:alice@example.com;transport=udp</Sip>
  </Dial>
</Response>
!, "Sip example");
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Message({ action => "https://your-application.com/followup",
		method => "GET" },
	      "Hello from SignalWire");

  is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Message action="https://your-application.com/followup" method="GET">Hello from SignalWire</Message>
</Response>
!, "Message example");
}

{
  my $sw = new SignalWire::CompatXML;
  $sw->Response
    ->Receive({ mediaType => "image/tiff" });

    is( $sw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Receive mediaType="image/tiff" />
</Response>
!, "Receive example");
}

