package Ravenel;

$VERSION = 1.1;

use strict;
use Ravenel::Document;
use Ravenel::Tag;
use Data::Dumper;
use Carp qw(cluck confess);
use fields qw(documents dynamic docroot);

use 5.006;

=head1 Ravenel, yet another dynamic content engine

=head2 Immediate example.

I hate how templating engines bury the "hello world" example 4-5 clicks into their documentation.  Show me something, NOW.

	#!/usr/bin/perl

	use strict;
	use Ravenel::Document;

	sub droid {
		my Ravenel::Block $block_obj = shift;
		my $block                    = $block_obj->get_block();
		$block =~ s/o/0/g;
		return $block;
	}

	my $res = Ravenel::Document->render( {
		'data'         => qq(<r:droid>motorola</r:droid>),
		'functions'    => { 'droid' => \&droid },
	} );

	print $res . "\n"; # prints "m0t0r0la"

=head2 Code Generation

This module can generate a code to generate this page as well.  Simply point your function to an external package, give it a name attribute, and turn the dynamic option off, and you're off to the races.  <b>Let me be clear, when "dynamic" is set to 0, this module will take a template, and generate CODE, a package to be exact, that you can then run to generate a document dynamically.  The code generated is all of the work that the parser would have done on any tag it can identify off the bat.</b>

	my $res = Ravenel::Document->render( {
		'data'         => qq(<r:MyPackage:droid>motorola</r:MyPackage:droid>),
		'name'         => 'test',
		'dynamic'      => 0,
	} );

	print $res . "\n";

The value of "$res" is below:

	package test;

	use strict;
	use warnings;
	use Ravenel;
	use Ravenel::Block;
	use Ravenel::Document;
	use Data::Dumper;

	use MyPackage;

	sub get_html_content {
		my $class           = shift if ( $_[0] eq 'test' );
		my $args            = shift;
		my $dynamic_content = [];
		my $content_type    = 'html';

		$dynamic_content->[0] = Ravenel::Document->scan("r:", 'html', MyPackage->droid( new Ravenel::Block( { 
			'tag_arguments'    => { }, 
			'blocks_by_name'   => { 'default' => "motorola", }, 
			'arguments'        => $args, 
			'content_type'     => $content_type, 
			'format_arguments' => { },
		} ) ));

		my $body = <<HERE_I_AM_DONE
	$dynamic_content->[0]
	HERE_I_AM_DONE
	;

		chomp($body);
		return $body;
	}

1;

=head2 Complicated example

How about a more realistic example?

	#!/usr/bin/perl

	use strict;
	use lib qw(../lib);
	use Ravenel;
	use Ravenel::Document;

	my $res = Ravenel::Document->render( {
		'data'         => qq(
		<table>
			<r:get_rows format>
				<tr><td>{name}</td><td>{rank}</td><td>{serial_number}</td></tr>
			<block id="empty"/>
				<tr><td>No Rows returned</td></tr>
			</r:get_rows>
		</table>
		),
		'prefix'       => 'r:',
		'content_type' => 'html',
		'name'         => 'test',
		'functions'    => {
			'get_rows' => sub {
				my Ravenel::Block $block_obj = shift;

				my $row_count = int(rand(5));
				if ( $row_count ) {
					my $block = $block_obj->get_block();
					# just making this up here, pretend that I did a DB query and got an array of hashrefs
					$block_obj->format( [ map { { 'name' => 'dextius', 'rank' => 'SrA', 'serial_number' => '12345' } } 0..$row_count ] );
				} else {
					return $block_obj->get_block('empty');
				}
			},
		},
	} );

	print $res . "\n";

Not rocket science here, just showing off how a tag can have multiple "blocks", and to show off I threw in the "format" option that turns the row of data into an sprintf block.  The structure passed in will render the tag similarly to the replace function, but when done "statically" it will be faster than using a regex.  You can see that if rand happens to return a 0, then it will return the empty block, instead of returning no rows.

=head1 Now you're just showing off..

	#!/usr/bin/perl

	use strict;
	use Ravenel::Document;

	our $random_value; 

	my $res = Ravenel::Document->render( {
		'data'         => qq(
		<r:switch depth="1" format>
			<r:{func} depth="2">this should be upper case!</r:{func}>
		</r:switch>
		<r:random depth="0"/>
		),
		'dynamic'      => 0,
		'prefix'       => 'r:',
		'functions' => {
			'switch' => sub {
				my Ravenel::Block $block_obj = shift;
				my $t = ( $random_value ? 'upper' : 'reverse' );
				return $block_obj->format( { 'func' => $t } );
			},
			'upper' => sub {
				my Ravenel::Block $block_obj = shift;
				return uc($block_obj->get_block());
			},
			'reverse' => sub {
				my Ravenel::Block $block_obj = shift;
				return reverse($block_obj->get_block());
			},
			'random' => sub {
				my Ravenel::Block $block_obj = shift;
				$random_value = int(rand(2));
				return;
			},
		},
	} );
	print $res . "\n";

Ok, the depth attribute on the "random" tag, allows you to define the order which the tags will render.  So, the "random" tag renders, and sets the "random_value" global variable.  Next, the switch tag renders, that will SET the tag to be rendered inside it's block.  Then either the upper or reverse tags will render.  Lots of rope to hang yourself, or, in my case, lots of neat tricks to avoid gross hacks that pollute your templates when you're doing something hard.  Anyway, the above code will generate the following package.

	# DYNAMICALLY GENERATED CONTENT BELOW

	package test;

	use strict;
	use warnings;
	use Ravenel;
	use Ravenel::Block;
	use Ravenel::Document;
	use Data::Dumper;


	sub random {
				my Ravenel::Block $block_obj = shift;
				$random = int(rand(2));
				return '';
			}

	sub upper {
				my Ravenel::Block $block_obj = shift;
				return uc($block_obj->get_block());
			}

	sub switch {
		my Ravenel::Block $block_obj = shift;
		my $t = ( $random ? 'upper' : 'reverse' );
		return $block_obj->format( { 'func' => $t } );
	}

	sub reverse {
				my Ravenel::Block $block_obj = shift;
				return reverse($block_obj->get_block());
			}

	sub get_html_content {
		my $class           = shift if ( $_[0] eq 'test' );
		my $args            = shift;
		my $dynamic_content = [];
		my $content_type    = 'html';

		$dynamic_content->[0] = Ravenel::Document->scan("r:", 'html', random( new Ravenel::Block( { 
			'tag_arguments'    => { }, 
			'blocks_by_name'   => { 'default' => "", }, 
			'arguments'        => $args, 
			'content_type'     => $content_type, 
			'format_arguments' => { },
		} ) ), undef, 'test');
		$dynamic_content->[1] = Ravenel::Document->scan("r:", 'html', switch( new Ravenel::Block( { 
			'tag_arguments'    => { 'format' => "1", }, 
			'blocks_by_name'   => { 'default' => "
			<r:%s depth=\"2\">this should be upper case!</r:%s>
		", }, 
			'arguments'        => $args, 
			'content_type'     => $content_type, 
			'format_arguments' => { 'default' => [ "func", "func",  ], },
		} ) ), undef, 'test');

		my $body = <<HERE_I_AM_DONE

		$dynamic_content->[1]
		$dynamic_content->[0]
		
	HERE_I_AM_DONE
	;

		chomp($body);
		return $body;
	}


	1;

	# DYNAMICALLY GENERATED CONTENT ABOVE

=head1 Ok, enough examples, let's get some background on this...

Under the hood of this monster, sits a templating engine with two facades.  The first is the dynamic content generator.  It is a fairly simple engine, that is capable of recursing on itself to render tags that match it's prefix.  Next is a static generator, it will generate perl code, in the form of a package, that will take arguments, and generate content.  Any tags generated by the "initial" tags will then be rendered by the dynamic engine.  For example:

	<r:my_tag>
		<r:my_nested_tag/>
	</r:my_tag>

If handed to the static generator, it will be able to turn that into a function call immediately.  However, the static generator doesn't know what is going to be returned by thsi outer tag.  It could be the tag inside, or it could be something else entirely (or more than one of those things).  Because of that, it will hand the output of the outer tag to the dynamic rendering engine to handle.

Tag arguments will parsed and be made as part of the tag structure as a hash reference.  There is no restriction on how many arguments you throw on a tag.

	<r:my_nested_tag team="Patriots" league="NFL"/>

As you saw in the example, you can make tags, and their arguments dynamic as well.  Think of the inner block as just text until the outer tag renders.

	<r:tag_changer>
		<r:{FUNCTION} arg="{TEMP}"/>
	</r:tag_changer>

	This could render a tag with a function name and an argument, or nothing at all.

=head1 Tags

Tags can be local to the program, or external in modules.  

	<r:MyPackage:myMethod/>

This will render into calling MyPackage::myMethod();
This will work for any level of depth.

	<r:MyPackage:SubPackage:AnotherPackage:my_method/>

This will render into MyPackage::SubPackage::AnotherPackage::my_method();

=head1 Built in tags

I only have two that matter, the other three are sort of useless at this point

=head2 include

This is your basic include function, it allows you to pull in content from another source, and include it into your document.  If the static generator sees include tags that can be rendered, it will do so immediately, and any of the included content that is eligible for static generation will be done so.  Include's can show up at any time, and they will be rendered accordingly.

=head2 replace

Ahh yes, the general purpose replace logic.  It reminds me of HTML::Template's tmpl_var and tmpl_loop rolled into one, but with a few twists.  It will look in it's "argument" structure when you created the document for it's input.  You simply give it a key, or not, and it will render the block accordingly.

=head1 Post directives

I started getting a little REST in this thing.  I decided for version 1.0 I won't go down that path.  But, I am reserving the names NOW :-)
These are callback functions, so if you want to have a basic callback function for any of these HTTP requests, they can be registered within the page.  Of course, the entire linkage to a CGI or mod_perl/mod_perllite system is entirely up in the air at this point.

  post

  delete

  put

=head1 Tag modifiers

So, I am sure you figured out that you just dumps xml looking tags all over the place, and it's up to you to write whatever it's calling.  Not much else to it, except for a few options.

=head2 depth

Depth allows you to define when something should be rendered.  Lowest goes first.  Any tag on the same level as another tag will be rendered in the order in which it shows up (top to bottom).  Tags without a depth argument are given a value of 100 (they execute last, unless you define a depth beyond 100).  Here's an example:

	<r:drop depth="0">
		<r:foo depth="3">
			<r:blah depth="1"/>
			<r:bar depth="2"/>
		</r:foo>
	</r:drop>

	The "drop" tag will render first.  This could of course, could return anything.  Let's just say that returns...

		<r:foo depth="3">
			<r:blah depth="1"/>
			<r:bar depth="2"/>
		</r:foo>

	Next up is blah... Let's say this tag returns some content, AND a tag..

		<r:foo depth="3">
			BLAH!!! <r:more_blah depth="0"/>
			<r:bar depth="2"/>
		</r:foo>

	So, a tag just got injected, and it has a depth lower than the other tags.  "more_blah" will render next, and so on and so on until there are no other tags left to render.

=head2 format

Format is an that allows you to turn your "inner block" of a tag, into a big sprintf format line, replacing anything with curly braces into a %s.  

	<r:foo format>{a}, {b}</r:foo>

So, when the tag renders, the "foo" function will be given an inner block of.

	%s, %s

=head1 Block

The "Ravenel::Block" object is the first parameter passed to any tag.  For more information on it, and it's methods, see Ravenel::Block

=head1 Errors

I use Carp::confess, a LOT.  I call confess during the rending process, at nearly every stage.  If you have mismatched, misaligned, or malformed tags, it'll blow up, at compile time if using the static generator.  

=head1 Constructor / render 

=head2 Ravenel::Document->render($obj)
=head2 my $doc = new Ravenel::Document($obj); $doc->parse();

There are two ways to parse a document, you can call render directly, or you can instantiate a document, and then call it's parse function. (will be used more with functionality provided with Ravenel.pm, which will eventually become somewhat of a "controller".

So, let's see what kinds of stuff we can put in the argument structure of $obj (which is a hash ref).

=head3 dynamic

This is the most important parameter.  If it is set to 1, (which is the default), when parsed or rendered, it will expand all of the tags, and generate content.
If it is set to 0, then when it is parsed or rendered, it will generate a perl package that can generate your content.

=head3 docroot 

Where to load content from, and documents that you "include" within the document

=head3 data

As you've seen from the examples, you can pass the content directly into the template engine.

=head3 content_type

If you use "data", then we'll need to know the content type.  If you don't supply it, I'll just assume it's html.  This is only really needed when "dynamic" is set to 0

=head3 name

The name of the package that you'll be creating.  If not supplied I'll make one up based on the filename.  Again, this is only needed if "dynamic" is set to 0.

=head3 prefix

All of the tags I have shown using in this document have a "prefix" of 'r:'.  You can make this whatever you want.
I have dark thoughts of changing the prefix at runtime, to further complicate the "depth" tree of tags, muahah..

=head3 arguments

This is ONLY valid when 'dynamic' = 1.  This structure is what will be given to each tag in it's "Block" object (will be described later on).
Arguments can be passed to tags in a statically generated document by simply passing them directly when calling the "get_[CONTENT_TYPE]_content()" function of the generated pacakge.

=head3 functions

As you saw above, you can have local functions that your document can use as tags.  This will work with both dynamic settings (courtesy of PPI).
Your functions should expect be be given a block object as your first argument.

=head1 Background...

"Why, Mr. Dietrich? Why, why, why? Why do you do it? Why? Why get up? Why keep fighting? Do you believe you're fighting for something? For more than your survival? Can you tell me what it is? Do you even know? Is it freedom or truth? Perhaps peace? Could it be for love? Illusions, Mr. Dietrich. Vagaries of perception. Temporary constructs of a feeble human intellect trying desperately to justify an existance that is without meaning or purpose! And all of them as artificial as the Matrix itself... although only a human mind could invent something as insipid as love. You must be able to see it, Mr. Dietrich. You must know it by now. You can't win. It's pointless to keep fighting. Why, Mr. Dietrich, why? Why do you persist?" --Agent Smith, from Matrix Revolutions (well, close enough)
 
Because Smith, I'm an idiot who just HAD to write YET ANOTHER templating system written in Perl.

Imagine HTML::Template ran into Apache::ASP's taglib's, and hooked up with HTML::Template::Compiled, all in the spirit of an un-released template engine Chip Turner wrote called PXT.
 
When I was contracting for Redhat, I met (heck, I interviewed him and gave the thumbs up for the hiring decision) Chip Turner.  Chip is a crazy smart guy (who isn't afraid of putting you in your place, without mercy) who looked at Apache::ASP with disdain.  He wrote his own templating system, he called PXT, which I was given permission to use in future projects.  I loved PXT.  It had clean separation, simple callbacks, and very little configuration.  It had problems though.  It re-parsed the document on every pass, even though it knew exactly where most of the tags were from the last time it received a request.  It also required lots of "snippets" of HTML strewn about to build a page, to force the separation of the rendering code from the template.  Lastly, it was practically hard coded to work with mod_perl.
 
Years later, I ended up doing some Java development (ugh).  I did see some of the advantages to the approach taken with Servlets, JSP, and Struts, and some ideas started forming in my head. I liked the idea of complicated taglibs and embedded code being boiled down to a pure source servlet, loaded into memory, and ready to take whatever arguments were given (either from the URL, session, or post form) to produce output content.  I saw this in a greater extent when I did some Cold Fusion development.  Too bad Cold Fusion, as an abstraction to JSP/Servlets is bloated and slow.  I have some friends who are die hard Cold Fusion people, and I pray for them daily ;-)
 
So, at my last job, I was tasked to write a web application to control Perl programs that decided when to buy our sell on the stock market.  I decided to write the back end of the web application in Perl (of course).  My timeline was short, so I had to decide which templating system I would go with.  At the time, I thoguht "Hey, I should write that templating system I always wanted to build, since I can't drag mod_perl in here and use PXT".  Of course, I didn't.  I ended up choosing HTML::Template, because it looked like it had the smallest barrier of entry.  I ran into issues years later with this decision, as my projects grew, HTML::Template didn't scale with the complexity of my applications terribly well.  (And to my old team I apologize for the mess). 
 
So, here I am at yet another new job.  Not wanting to repeat my mistake at the last place, I decided to go finally sit down and pound this thing out.  Call it a 10 year itch (literally).  Call me crazy, but I found some purpose in finally bringing this to fruition... 

"But, as you well know appearances can be decieving, which brings me back to the reason why we're here. We are not here because we're free, we're here because we are not free. There is no escaping reason, no denying purpose, because as we both know, without purpose, we would not exist.  It is purpose that created us. Purpose that connects us. Purpose that pulls us, that guides us, that drive us. It is purpose that defines, purpose that binds us." --Agent Smith(s), from Matrix Reloaded
 
Perl Rites of passage #2 completed (thankfully I found Getopt::Long, and HTML::Parser earlier in life).  Sql::Simple was out of frustration, as I knew how I wanted the program to work, but couldn't find an existing abstraction layer that suited my style (or lack thereof).  So, I guess that's it, I can no move forward with real modules that will actually help people ;-)
 
I have no intention of attempting to compete with Catalyst, Jifty, or Dancer in the framework space.  Those guys are doing a great job.  I think I'm allergic to frameworks anyway.

=head1 Why Ravenel?!

I like bridges.  I practically moved to Charleston because of seeing this bridge while flying in for an interview.  http://images.google.com/images?hl=en&source=hp&q=ravenel%20bridge&aql=&oq=&um=1&ie=UTF-8&sa=N&tab=wi

=head1 COPYRIGHT:

The Ravenel module is Copyright (c) 2010 Ryan Alan Dietrich. The Ravenel module is free software; you can redistribute it and/or modify it under the same terms as Perl itself with the exception that it cannot be placed on a CD-ROM or similar media for commercial distribution without the prior approval of the author.

=head1 Author Ravenel by Ryan Alan Dietrich <ryan@dietrich.net>

=cut

our $debug;
our $debug2;
our $service_type; # mod_perl / cgi / standalone

sub new {
	my Ravenel $self = shift;
	my $option       = shift || {};

	
	unless ( ref($self) ) {
		$self               = fields::new($self);
		$self->{'dynamic'}  = ( defined($option->{'dynamic'}) ? $option->{'dynamic'} : 1 );
		$self->{'docroot'}  = $option->{'docroot'};
		$self->{'docroot'} .= '/' if ( substr($self->{'docroot'}, -1) ne '/' );

		# XXX docroot only required if not dynamic
		#confess("docroot not defined") if ( not $option->{'docroot'} );

		$debug              = $option->{'debug'};
		$debug2             = $option->{'debug2'};
	}

	return $self;
}

sub add_document {
	my Ravenel $self = shift;
	my $option       = shift;
	
	confess("Option hash required") if ( not $option or not ref($option) );
	#confess("'name' required") if ( not $option->{'name'} );

	# XXX if we have a CGI environment, we should be able to figure this out
	$option->{'docroot'} = $self->{'docroot'} if ( $self->{'docroot'} );
	$option->{'dynamic'} = $self->{'dynamic'} if ( defined($self->{'dynamic'}) );
	$option->{'document_is_totally_dynamic'} = $self->{'dynamic'};

	my Ravenel::Document $document = new Ravenel::Document($option);
	$document->{'dynamic'} = $self->{'dynamic'} if ( defined($self->{'dynamic'}) );
	$self->{'documents'}->{$option->{'name'}} = $document;

	return $document;
}

# Class method for handling post responses
sub handle_post_response {
	my $class = shift;
}

1;
