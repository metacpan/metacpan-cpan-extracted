package SignalWire::CompatXML;

use 5.008001;
use strict;
use warnings;
use Carp 'croak';
use Scalar::Util 'blessed';

our $VERSION = '1.0';
our $AUTOLOAD;
our $NL = "\n";
our $STRICT = 0;
our %TAGS   = ();

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    $self->{_name}       = '';
    $self->{_attributes} = {};
    $self->{_parent}     = undef;
    $self->{_content}    = '';

    {
        no strict 'refs';
        my %args = @_;
        for my $arg ( keys %args ) {
            if( exists $self->{"_$arg"} ) {
                $self->$arg($args{$arg});
            }
        }
    }

    return $self;
}

sub name {
    my $self = shift;

    if( @_ ) {
        $self->{_name} = shift;
    }

    $self->{_name};
}

sub parent {
    my $self = shift;

    if( @_ ) {
        $self->{_parent} = shift;
    }

    $self->{_parent};
}

sub content {
    my $self = shift;
    my @args = grep { defined $_ } @_;

    if( @args ) {
        my $arg = shift;

        ## an object
        if( ref($arg) ) {
            $arg->parent($self);
            $self->{_content} = [ $arg ];
            return $arg;
        }

        ## http://www.w3.org/TR/REC-xml/#syntax
        $arg =~ s{\&}{&amp;}g;
        $arg =~ s{\<}{&lt;}g;
        $arg =~ s{\>}{&gt;}g;
        $arg =~ s{\"}{&quot;}g;
        $arg =~ s{\'}{&apos;}g;

        $self->{_content} = $arg;
    }

    $self->{_content};
}

sub attributes {
    my $self = shift;

    if( @_ ) {
        $self->{_attributes} = shift;
    }

    $self->{_attributes};
}

sub add_child {
    my $self = shift;
    my $child = shift;

    $child->parent($self);
    $self->{_content} ||= [];
    push @{$self->{_content}}, $child;

    return $child;
}

sub root {
    my $self = shift;

    if( $self->{_parent} ) {
        return $self->{_parent}->root;
    }

    return $self;
}

sub to_string {
    my $self = shift;
    my $hdrs = shift || {};

    my @headers = ();
    for my $hdr ( sort keys %$hdrs ) {
        push @headers, $hdr . ': ' . $hdrs->{$hdr};
    }
    push @headers, '' if scalar(@headers);

    join($NL, @headers, $self->to_list);
}

sub to_list {
    my $self = shift;
    my $sp   = shift || 0;

    my @str = ();

    ## named element
    if( $self->name ) {
        if( my $content = $self->content ) {
            push @str, (' ' x $sp) . $self->otag;

            my $is_str = 0;

            if( ref($content) eq 'ARRAY' ) {
                for my $child ( @$content ) {
                    push @str, $child->to_list($sp + ($child->parent->name ? 2 : 0));
                }
            }

            else {
                $is_str = 1;
                $str[$#str] .= $content || '';
            }

            if( $is_str ) {
                $str[$#str] .= $self->ctag;
            }
            else {
                push @str, (' ' x $sp) . $self->ctag;
            }
        }

        ## no content; make a tidy tag
        else {
            push @str, (' ' x $sp) . $self->octag;
        }
    }

    ## unnamed (root) element
    else {
        push @str, qq!<?xml version="1.0" encoding="UTF-8" ?>!;

        my $content = $self->content;

        my $is_str = 0;
        if( ref($content) eq 'ARRAY' ) {
            for my $child ( @$content ) {
                push @str, $child->to_list($sp + ($child->parent->name ? 2 : 0));
            }
        }

        else {
            $is_str = 1;
            $str[$#str] .= $content || '';
        }

        push @str, '';
    }

    return @str;
}

sub otag {
    return '<' . $_[0]->name . $_[0]->_attr_str . '>';
}

sub ctag {
    return '</' . $_[0]->name . '>';
}

sub octag {
    return '<' . $_[0]->name . $_[0]->_attr_str . ' />';
}

sub _attr_str {
    my $self = shift;
    my $str  = '';

    my %attr = %{ $self->attributes };

    for my $key ( sort keys %attr ) {
        my $val = $attr{$key} || '';
        $str .= ' ';
        $str .= qq!$key="$val"!;
    }

    return $str;
}

sub can {
    my $self = shift;
    my $method = shift;

    ## NOTE: this probably breaks inheritance
    if( $STRICT and keys %TAGS ) {
        unless( exists $TAGS{$method} ) {
            no strict 'refs';
            undef *{ $method };
            return;
        }
    }

    my $meth_ref = $self->SUPER::can($method);
    return $meth_ref if $meth_ref;

    $meth_ref = sub {
        my $me = shift;

        my $child = new blessed $me;
        $child->name($method);

        for my $arg ( @_ ) {
            if( ref($arg) ) {
                $child->attributes($arg);
            }
            else {
                $child->content($arg);
            }
        }

        $me->add_child($child);

        return $child;
    };

    no strict 'refs';
    return *{ $method } = $meth_ref;
}

sub AUTOLOAD {
    my $self = $_[0];

    my $method = $AUTOLOAD;
    $method =~ s/^(.*):://;

    my $meth_ref = $self->can($method);
    croak "Undefined subroutine $method\n"
	unless $meth_ref;

    goto &$meth_ref;
}

sub DESTROY { }

1;
__END__

=head1 NAME

SignalWire::CompatXML - Light and fast CompatXML generator

=head1 SYNOPSIS

  use SignalWire::CompatXML;

  my $sw = new SignalWire::CompatXML;
  $sw->Response->Dial("+1234567890");
  print $sw->to_string;

=head1 DESCRIPTION

B<SignalWire::CompatXML> creates SignalWire-compatible CompatXML
documents. Documents can be built by creating and nesting one element
at a time or by chaining objects. Elements can contain attributes,
text content, or other elements.

CompatXML, being XML, could be trivially generated with B<XML::LibXML> or
any number of other XML parsers/generators. Philosophically,
B<SignalWire::CompatXML> represents an I<economical> CompatXML generator. It
has a small footprint (CompatXML documents are typically small and simple)
and means to make CompatXML creation straightforward and moderately fun.

B<SignalWire::CompatXML>'s primary aim is for economy of
expression. Therefore, B<Any method you call on a CompatXML object (except
those described below) will create new CompatXML objects by the name of
the method you called.> By chaining method calls, you can create
robust CompatXML documents with very little code.

=head2 new( key => value, ... )

Creates a new CompatXML object. With no arguments, this will create a root
for your CompatXML document. You can also call B<new> with I<name>,
I<content>, or I<attributes> arguments to create unattached
elements.

The following examples all create the this CompatXML document using
different calling styles:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say voice="man">Kilroy was here</Say>
  </Response>

The upside-down, piecemeal, verbose way:

  my $say = new SignalWire::CompatXML;
  $say->name('Say');
  $say->content("Kilroy was here");
  $say->attributes({voice => "man"});

  my $resp = new SignalWire::CompatXML;
  $resp->name('Response');
  $resp->content($say);

  my $sw = new SignalWire::CompatXML;
  $sw->content($resp);
  print $sw->to_string;

The same thing, with a little more powerful constructor:

  my $say = new SignalWire::CompatXML(name => 'Say',
                                   content => "Kilroy was here",
                                   attributes => {voice => "man"});

  my $sw = new SignalWire::CompatXML;
  $sw->Response->add_child($say);
  print $sw->to_string;

The concise way:

  my $sw = new SignalWire::CompatXML;
  $sw->Response->Say({voice => "man"}, "Kilroy was here");
  print $sw->to_string;

And the obligatory one-liner (spread across 4 lines for readability):

  print SignalWire::CompatXML->new
    ->Response
    ->Say({voice => "man"}, "Kilroy was here")
    ->root->to_string;

What you don't see in the latter two examples is that both B<Response>
and B<Say> create and return objects with the names I<Response> and
I<Say> respectively. When called in this way, methods can I<chain>,
making for compact, yet readable expressions.

=head2 Any CompatXML Verb( string | { attributes } )

Constructor shortcuts. CompatXML verbs are described at
L<http://www.twilio.com/docs/api/twiml>. Some examples include
I<Connect>,I<Denoise>,I<Dial>,I<Echo>,I<Enqueue>,I<Gather>,I<Hangup>,
I<Leave>,I<Pause>,I<Play>,I<Record>,I<Redirect>,I<Refer>,I<Reject>,
I<Say>,I<Sms>,I<Stream>,I<AI>,I<Conference>,I<Number>,I<Queue>,
I<Room>,I<Sip>,I<Message> and I<Receive> (this list may be out of
date with respect to the official documentation).

See SignalWire's documentation for usage for these and other CompatXML verbs.

The B<(any CompatXML verb)> shortcut is a constructor of a CompatXML
object. When you call B<(any CompatXML verb)> on an existing CompatXML object,
the following occurs:

=over 4

=item *

A new object is created and named by the method you called. E.g., if
you called:

  $sw->Response;

a CompatXML object named 'Response' will be created.

=item *

The newly created object is attached to its parent (the object called
to create it).

=item *

The parent object has the new object added to its list of children.

=back

These last two items means the objects are "chained" to each
other. Chaining objects allows concise expressions to create CompatXML
documents. We could add another object to the chain:

  $sw->Response
    ->Say("I'm calling you.")
      ->parent
    ->Dial("+17175558309");

The B<parent> method returns the I<Say> object's parent (I<Response>
object), and we chain a I<Dial> object from it. The resulting I<$sw>
object returns:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>I&apos;m calling you.</Say>
    <Dial>+17175558309</Dial>
  </Response>

=head2 name( string )

Gives a name to an element. This is what is used when the element is
printed out. If you're generally chaining objects, you won't use this
method often.

  $elem->name('Dial');
  $elem->content("+1234567890");

becomes:

  <Dial>+1234567890</Dial>

When no string is supplied, the name of the object is returned.

  print $elem->name . "\n";

The element name may also be given with B<new> or is implicit when you
call the constructor by the name of the element you want to create.

=head2 content( string | object )

Sets the content of an element. A CompatXML object's content can be
I<either> a string or a listref of objects, but not both. If the
argument is another B<SignalWire::CompatXML> object, the content of the
element (if any) will be replaced with the object. Any other argument
will be considered string content.

  my $say = new SignalWire::CompatXML(name => 'Say');
  $say->content("Eat at Joe's!");  ## a string as content

becomes:

  <Say>Eat at Joe&apos;s!</Say>

Now we can add I<$say> to another element:

  my $parent = new SignalWire::CompatXML(name => 'Response');
  $parent->content($say);  ## an object as content

which becomes:

  <Response>
    <Say>Eat at Joe&apos;s!</Say>
  </Response>

When no argument is supplied, the existing contents are returned.

  my $content = $elem->content;
  if( ref($content) ) {
    for my $obj ( @$content ) {
      ## do something with each $obj
    }
  }

  else {
    print $content . "\n";  ## assuming a string here
  }

=head2 add_child( object )

Adds an element to the content of the CompatXML object. Returns a
reference to the added object. Unlike B<content>, B<add_child> does
not I<replace> the existing content, but I<appends> an object to the
existing content. Also unlike B<content>, B<add_child> is not
appropriate to use for setting text content of an element.

  my $sw = new SignalWire::CompatXML;
  my $resp = $sw->Response;
  $resp->add_child(new SignalWire::CompatXML(name => 'Say',
                                          content => 'Soooey!'));

  my $email = uri_escape('biff@example.com');
  my $msg = uri_escape("Heeer piiiig!");
  my $url = "http://twimlets.com/voicemail?Email=$email&Message=$msg";
  $resp->add_child(new SignalWire::CompatXML(name => 'Redirect',
                                          content => $url));

  print $sw->to_string({'Content-type' => 'text/xml'});

becomes:

  Content-type: text/xml

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>Soooey!</Say>
    <Redirect>http://twimlets.com/voicemail?Email=\
    biff%40example.com&amp;Message=Heeer%20piiiig!</Redirect>
  </Response>

=head2 attributes({ key => value })

Sets attributes for an element. If a hash reference is not supplied, a
hashref of the existing attributes is returned.

  my $elem = new SignalWire::CompatXML(name => 'Say');
  $elem->attributes({voice => 'woman'});
  $elem->content("gimme another donut");

becomes:

  <Say voice="woman">gimme another donut</Say>

=head2 root

Returns a handle to the root object.

  print SignalWire::CompatXML->new
    ->Response
    ->Say("All men are brothers,")
      ->parent
    ->Say("Like Jacob and Esau.")
    ->root->to_string;

prints:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>All men are brothers,</Say>
    <Say>Like Jacob and Esau.</Say>
  </Response>

B<root> is a convenient way to get a handle to the root CompatXML object
when you're ready to print.

=head2 to_string( { header => value } )

Returns the object as a string. Unnamed (root) elements will include
the XML declaration entity. If a hashref is supplied, those will be
emitted as RFC 822 headers followed by a blank line.

Example:

  print SignalWire::CompatXML->new->to_string;

prints:

  <?xml version="1.0" encoding="UTF-8" ?>

while this:

  print SignalWire::CompatXML->new
    ->Response
    ->Say("plugh")
    ->root->to_string;

prints:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>plugh</Say>
  </Response>

If we forget the call to B<root> in the previous example, like this:

  print SignalWire::CompatXML->new
    ->Response
    ->Say("plugh")
    ->to_string;

we get:

  <Say>plugh</Say>

because B<to_string> is being applied to the object created by B<Say>,
not B<$sw>.

By specifying a hashref, you can add RFC 822 headers to your
documents:

  $sw = new SignalWire::CompatXML;
  $sw->Response->Say('Arf!');
  $sw->to_string({'Content-type' => 'text/xml'});

which returns:

  Content-type: text/xml

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say>Arf!</Say>
  </Response>

=head2 parent( object )

Sets the parent of the object; this done automatically by B<add_child>
and B<content>. When no arguments are given, the existing parent
object is returned.

Because B<SignalWire::CompatXML> objects chain, B<parent> is useful for
getting the previous object so you can add more content to it:

  SignalWire::CompatXML->new
    ->Response
    ->Gather({action => "/process_gather.cgi", method => "GET"})
      ->Say("Please enter your account number.")
        ->parent  ## Say's parent, Gather
      ->parent    ## Gather's parent, Response
    ->Say("We didn't receive any input. Goodbye!");

becomes:

  <Response>
    <Gather action="/process_gather.cgi" method="GET">
      <Say>Please enter your account number.</Say>
    </Gather>
    <Say>We didn't receive any input. Goodbye!</Say>
  </Response>

I<A note on readability>: the author recommends indenting multi-line
chains to show the parent-child relationship. Each time B<parent> is
invoked, the next line should be outdented, as illustrated above.

=head1 PACKAGE VARIABLES

You may control the behavior of B<SignalWire::CompatXML> in several ways
by setting package variables described in this section.

=head2 Newlines

You may change the default newline from "\n" to anything else by
setting the I<$NL> package variable:

  local $SignalWire::CompatXML::NL = "\r\n";

=head2 Strict mode

B<SignalWire::CompatXML> is capable of generating well-formed but invalid
CompatXML documents. B<SignalWire::CompatXML> uses autoloaded methods to
determine the name of CompatXML elements (Response, Say, Dial, Redirect,
etc.); this means that if you specify an incorrectly named method,
your CompatXML will be incorrect:

  $sw->Response->Saay('plugh');

B<Saay> is not a valid SignalWire CompatXML tag and you will not know it until
SignalWire's CompatXML parser attempts to handle your CompatXML document.

You may enable strict checks on the CompatXML elements at runtime by
setting two package variables:

=over 4

=item $STRICT

When true, B<SignalWire::CompatXML>'s autoloader will look up the
unhandled method call in the B<%TAGS> package variable (below). If the
method name is not in that hash, the autoloader will die with an
"Undefined subroutine" error.

=item %TAGS

Empty by default. When B<$STRICT> is true, this hash will be consulted
to determine whether a method call is a valid CompatXML tag or not.

=back

For example:

  local $SignalWire::CompatXML::STRICT = 1;
  local %SignalWire::CompatXML::TAGS = (Response => 1, Say => 1, Dial => 1);

Now any methods invoked on B<SignalWire::CompatXML> objects that are not
B<Response>, B<Say>, or B<Dial> will die with an error. E.g.:

  SignalWire::CompatXML->Response->Saay("Let's play Twister!");

generates the following fatal error:

  Undefined subroutine Saay at line 1.

You may wish to use the fast hash creation with hash slices (I learned
this syntax from Damian Conway at a conference some years ago--it's
faster than B<map> over an array for building hashes):

  ## CompatXML verbs taken from http://www.twilio.com/docs/api/twiml
  my @tags = qw(Response Say Play Gather Record Sms Dial Number
                Client Conference Hangup Redirect Reject Pause);

  local @SignalWire::CompatXML::TAGS{@tags} = (1) x @tags;
  local $SignalWire::CompatXML::STRICT = 1;

  ## all method calls in this scope are now strict
  ...

=head1 EXAMPLES

This section demonstrates a few things you can do with
B<SignalWire::CompatXML>.

=head2 Example 1

  $t = new SignalWire::CompatXML;
  $t->Response->Say({voice => "woman"}, "This is Jenny");
  print $t->to_string({'Content-type' => 'text/xml'});

Output:

  Content-type: text/xml

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Say voice="woman">This is Jenny</Say>
  </Response>

=head2 Examples from signalwire.com

The following examples are from twilio.com's CompatXML documentation,
listed by the primary verb they implement. Assume a CompatXML object
I<$sw> for each of these examples has already been created:

  my $sw = new SignalWire::CompatXML;

and consequently each example would be printed with:

  print $sw->to_string;

See the F<t/signalwire.t> test file distributed with this package for
additional context for these examples.

=over 4

=item Connect

  $sw->Response
      ->Connect
      ->Room("my-room-name");

=item Denoise

  $sw->Response
      ->Denoise->parent
      ->Dial->Sip("sip:user@example.com;transport=udp");

=item Dial

  $sw->Response
      ->Dial
       ->Number("858-987-6543")->parent
       ->Number("415-123-4567")->parent
       ->Number("619-765-4321");

=item Echo

  $sw->Response
      ->Echo({timeout => "120"})->parent
       ->Hangup();

=item Enqueue

  $sw->Response
      ->Enqueue({waitUrl => "https://example.com/hold-music.xml"}, "support");

=item Gather

  $sw->Response
      ->Gather({action => "https://example.com/process_gather.php",
                method => "GET"})
       ->Say("Please enter your account number, followed by the pound sign");

=item Hangup

  $sw->Response
      ->Hangup;

=item Leave

  $sw->Response
      ->Leave;

=item Pause

  $sw->Response
      ->Say("I will pause 5 seconds starting now.")->parent
      ->Pause({length => 5})->parent
      ->Say("I just paused 5 seconds");

=item Play

  $sw->Response
      ->Play({ loop => 15 }, "rtmp://example.com:1935/my-rtmp-stream");

=item Record

  $sw->Response
      ->Say("Please leave a message at the beep. Press the star key when finished.")->parent
      ->Record({action => "http://your-application.com/handleRecording.cgi",
                method => "GET",
                maxLength => "15",
                finishOnKey => "#"});

=item Redirect

  $sw->Response
      ->Dial("310-123-0000")->parent
       ->Redirect("http://www.your-application.com/next-instructions");

=item Refer

  $sw->Response
      ->Refer({action => "https://example.com/refer-completed.xml",
               method => "GET"})
       ->Sip("sip:transfer-target\@example.com");

=item Reject

  $sw->Response
      ->Reject({reason => "busy"});

=item Say

  $sw->Response
      ->Say({voice => "woman", loop => "2"}, "Hello");


=item Sms

  $sw->Response
      ->Say("Our store is located at 123 East St.")->parent
      ->Sms({action => "/smsHandler.cgi", method => "POST"},
             "Store location: 123 East St.");

=item Stream

  $sw->Response
      ->Start
       ->Stream({url => "wss://streamer.signalwire.com"});
		
=item AI

  $sw->Response
      ->Connect()
       ->AI({ postPromptURL => "https://webhook.site/10d7acdaf140" })
        ->Prompt({ topP => '0.8', temperature => '1.0',
                   confidence => "0.6" }, "Hello, how are you today?")->parent
        ->postPrompt("Summarize the conversation.");

=item Conference

  $sw->Response
      ->Dial
       ->Conference({startConferenceOnEnter => "true",
                     endConferenceOnExit => "true"},
                     "1234");

=item Number

  $sw->Response
      ->Dial
       ->Number({sendDigits => "www56476" }, "858-987-6543");

=item Queue

  $sw->Response
      ->Dial
       ->Queue({ url="https://example.com/about_to_connect.xml" }, "support");

=item Room

  $sw->Response
      ->Connect
       ->Room("my-room-name");

=item Sip

  $sw->Response
      ->Dial
       ->Sip(sip:alice@example.com;transport=udp');

=item Message

  $sw->Response
      ->Message({ action => "https://your-application.com/followup",
                  method => "GET" },
		  "Hello from SignalWire");

=item Receive

  $sw->Response
      ->Receive({ mediaType => "image/tiff" });


=back

=head2 Other examples

Other examples may be found in the F<t> directory that came with this
package, also available on CPAN.

=head1 COMPATIBILITY

B<SignalWire::CompatXML> will likely be forward compatible with all
future revisions of SignalWire's CompatXML language. This is because method
calls are constructors which generate CompatXML objects on the fly.

For example, say SignalWire began to support a B<Belch> verb (if only!),
we could take advantage of it immediately by simply calling a B<Belch>
method like this:

  my $sw = new SignalWire::CompatXML;
  $sw->Response->Belch('Braaaaaap!');
  print $sw->to_string;

Because there is no B<Belch> method, B<SignalWire::CompatXML> assumes you
want to create a node by that name and makes one for you:

  <?xml version="1.0" encoding="UTF-8" ?>
  <Response>
    <Belch>Braaaaaap!</Belch>
  </Response>

If the B<$STRICT> package variable is enabled, all we need to do is
add B<Belch> to our B<%TAGS> hash and we're good to go.

=head1 SEE ALSO

L<SignalWire::CompatXML>

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
