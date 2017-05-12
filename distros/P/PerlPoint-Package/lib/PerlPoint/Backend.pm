 

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.15    |07.03.2006| JSTENZEL | the new simple dummy tokens are ignored;
# 0.14    |16.09.2004| JSTENZEL | objects declared as typed lexicals now;
# 0.13    |29.05.2003| JSTENZEL | new optional generator passing;
#         |15.06.2003| JSTENZEL | new general handler interface (DIRECTIVE_EVERY);
#         |12.09.2004| JSTENZEL | using the portable fields::new();
# 0.12    |04.02.2003| JSTENZEL | new method headlineIds2Data();
# 0.11    |08.03.2002| JSTENZEL | new method docstreams();
# 0.10    |14.08.2001| JSTENZEL | adapted to new stream data format, introduced modes;
#         |          | JSTENZEL | slight POD fixes;
#         |16.08.2001| JSTENZEL | added bind(), headlineNr() and move2chapter();
#         |17.08.2001| JSTENZEL | added unbind() and next();
#         |27.09.2001| JSTENZEL | added currentChapterNr();
#         |29.09.2001| JSTENZEL | stream position is no stored in the backend object,
#         |          |          | this will allow to have several backend objects
#         |          |          | operating on the same stream;
#         |          | JSTENZEL | added toc();
#         |11.10.2001| JSTENZEL | toc() now takes documents without headlines into acc.,
#         |14.10.2001| JSTENZEL | using new stream directive index constants,
#         |          | JSTENZEL | adapted to modified stream directive structure: the
#         |          |          | first entry is a hint hash now;
#         |          | JSTENZEL | stream parts can now be hidden or ignored on parsers cmd.;
#         |18.11.2001| JSTENZEL | extended traces
#         |23.11.2001| JSTENZEL | fixed POD bugs: I had written ==head2 ;-)
#         |24.11.2001| JSTENZEL | bugfix in toc(): special case when startup headline is the
#         |          |          | last headline in the stream;
# 0.09    |14.03.2001| JSTENZEL | added stream processing time report;
#         |          | JSTENZEL | slight code optimizations;
# 0.08    |13.03.2001| JSTENZEL | simplified code slightly;
#         |          | JSTENZEL | added visibility feature to visualize processing;
#         |14.03.2001| JSTENZEL | added mailing list hint to POD;
# 0.07    |07.12.2000| JSTENZEL | new namespace PerlPoint;
# 0.06    |19.11.2000| JSTENZEL | updated POD;
# 0.05    |13.10.2000| JSTENZEL | slight changes;
# 0.04    |30.09.2000| JSTENZEL | updated POD;
# 0.03    |27.05.2000| JSTENZEL | updated POD;
#         |          | JSTENZEL | added $VERSION;
# 0.02    |13.10.1999| JSTENZEL | added real POD;
#         |          | JSTENZEL | constants went out, so I could remove the could to generate
#         |          |          | them at compile time;
# 0.01    |11.10.1999| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Backend> - frame class to transform PerlPoint::Parser output

=head1 VERSION

This manual describes version B<0.15>.

=head1 SYNOPSIS

  # load the module:
  use PerlPoint::Backend;

  # build the backend
  my ($backend)=new PerlPoint::Backend(name=>'synopsis');

  # register handlers
  $backend->register(DIRECTIVE_BLOCK,    \&handleBlock);
  $backend->register(DIRECTIVE_COMMENT,  \&handleComment);
  $backend->register(DIRECTIVE_DOCUMENT, \&handleDocument);
  $backend->register(DIRECTIVE_HEADLINE, \&handleHeadline);
  $backend->register(DIRECTIVE_POINT,    \&handlePoint);
  $backend->register(DIRECTIVE_SIMPLE,   \&handleSimple);
  $backend->register(DIRECTIVE_TAG,      \&handleTag);
  $backend->register(DIRECTIVE_TEXT,     \&handleText);
  $backend->register(DIRECTIVE_VERBATIM, \&handleVerbatim);

  # finally run the backend
  $backend->run(\@streamData);

=head1 DESCRIPTION

After an ASCII text is parsed by an B<PerlPoint::Parser> object, the original text is transformed
into stream data hold in a Perl array. To process this intermediate stream further (mostly
to generate output in a certain document description language), a program has to walk through
the stream and to process its tokens.

Well, B<PerlPoint::Backend> provides a class which encapsulates this walk in objects which deal
with the stream, while the translator programmer is focussed on generating the final
representation of the original text. This is done by registering I<handlers> which will be
called when their target objects are discovered in the intermediate stream.

The stream walk can be performed in various ways (please see following sections for details).
The common way is to use I<run()> which walks through the stream from its first to its last
token and takes everything found into account to invoke appropriate callbacks.


=head2 Modes

By default, a backend object inspects the token stream token by token. This way everything
is handled in the original order, according to the input once parsed. But sometimes you want
to know something about the documents I<structure> which simply means about headlines only.

  For example, consider the case that you want to build
  a table of contents or a table of valid chapter references
  before the "real" slides are made. In the mentioned token
  mode this takes more time than it should, because a lot
  of additional tokens are processed besides the headlines.

In such cases, the backend can be enforced to work in "headline mode". This means that I<only>
headlines are processed which accelerates things significantly.

Modes are switched by method I<mode()>. Please note that a stream can be processed more than once,
so one can process it in headline mode first, use the headline information, and then switch back
to the usual token mode and process the entire document data.


=head2 Ways of stream processing

The base model of stream processing implemented by this class is based on "events". This means
that the token stream is processed by a loop which invokes user specified callback functions
to handle certain token types. In this model, the loop is in control. This works fine in stream
translation, e.g. to produce slides/documents in a target format, and is done by invoking the
method I<run()>.

Nevertheless, there are cases when converters need to be in full control, which means in fine
grained control of token processing. In this model the calling program (the converter) initiates
the processing of each token. This is especially useful if a converter is not really a converter
but a projector which uses the stream to I<present> the slides on the fly.

This second model of fine grained control is supported as well. The appropriate method (used
as an alternative of I<run()>) is I<next()>.


=head2 Stream navigaton

Usually a stream is processed from the beginning to its end, but it is possible to set up an
arbitrary sequence of chapters as well. (This is mostly intended for use in projectors.) Two
methods are provided to do this: I<reset()> moves back to the beginning of the entire stream,
while I<move2chapter()> chooses a certain chapter to continue the processing with.

Stream navigation works both in callbacks and if walking the stream via I<next()>.


=head2 The whole picture

Modes, the stream processing method and stream navigation can be freely combined. If the defaults
are used as shown in the I<SYNOPSIS>, a backend object works in headline mode and processes the
stream by I<run()>, usually without further navigation. But this is no rule. Make use of the
features as it is necessary to build the converter you want!


=head1 METHODS

=cut


# declare package
package PerlPoint::Backend;

# declare version
$VERSION=$VERSION=0.15;

# pragmata
use strict;

# declare class members
use fields qw(
              data
              display
              flags
              generator
              handler
              hide
              ignoredDirectives
              name
              processingHeadline
              statistics
              stream
              streamControl
              trace
              vis
             );

# load modules
use Carp;
use Storable qw(dclone);
use PerlPoint::Constants 0.19 qw(:DEFAULT :stream);


=pod

=head2 new()

The constructor builds and prepares a new backend object. You may
have more than one object at a certain time, they work independently.

B<Parameters:>
All parameters except of the I<class> parameter are named (pass them by hash).

=over 4

=item class

The class name.

=item name

Because there can be more than exactly one backend object, your object
should be named. This is not necessarily a need but helpful reading traces. 

=item trace

This parameter is optional. It is intended to activate trace code while the
object methods run. You may pass any of the "TRACE_..." constants declared
in B<PerlPoint::Constants>, combined by addition as in the following example:

  trace => TRACE_NOTHING+TRACE_BACKEND,

In fact, only I<TRACE_NOTHING> and I<TRACE_BACKEND> take effect to backend
objects.

If you omit this parameter or pass TRACE_NOTHING, no traces will be displayed.

=item display

This parameter is optional. It controls the display of runtime messages
like informations or warnings in all object methods. By default, all
messages are displayed. You can suppress these informations partially
or completely by passing one or more of the "DISPLAY_..." variables
declared in B<PerlPoint::Constants>.

Constants can be combined by addition.

=item vispro

activates "process visualization" which simply means that a user will see
progress messages while the backend processes the stream. The I<numerical>
value of this setting determines how often the progress message shall be
updated by a I<chapter interval>:

  # inform every five chapters
  vispro => 5,

Process visualization is automatically suppressed unless STDERR is
connected to a terminal, if this option is omitted, I<display> was set
to C<DISPLAY_NOINFO> or backend I<trace>s are activated.

=item generator

This is an internal interface, to make backends work together with
C<PerlPoint::Generator> objects. If you build a backend manually,
you do not have to care for this, just ignore it. If you build
a C<PerlPoint::Generator> application, just pass the generator
object.

Note: Generator handling is in alpha state, so manual usage is
      standard and traditional.

=back

B<Returns:>
the new object.

B<Example:>

  my ($backend)=new PerlPoint::Backend(name=>'example');

=cut
sub new
 {
  # get parameters
  my ($class, @pars)=@_;

  # build parameter hash
  confess "[BUG] The number of parameters should be even - use named parameters, please.\n" if @pars%2;
  my %pars=@pars;

  # check parameters
  confess "[BUG] Missing class name.\n" unless $class;
  confess "[BUG] Missing name parameter.\n" unless exists $pars{name};

  # build object
  my $me=fields::new($class);

  # init object
  @{$me}{qw(handler hide ignoredDirectives name stream)}=({}, 0, [], $pars{name}, STREAM_TOKENS);

  # store trace and display settings
  $me->{trace}=defined $pars{trace} ? $pars{trace} : TRACE_NOTHING;
  $me->{display}=defined $pars{display} ? $pars{display} : DISPLAY_ALL;
  $me->{vis}=(
                  defined $pars{vispro} 
              and not $me->{display} & &DISPLAY_NOINFO
              and not $me->{trace}>TRACE_NOTHING
              and -t STDERR
             ) ? $pars{vispro} : 0;
  $me->{generator}=exists $pars{generator} ? $pars{generator} : '';

  # reply the new object
  $me;
 }



=pod

=head2 register()

After building a new object by I<new()> the object can be prepared
by calls of the register method.

If the object walks through the data stream generated by B<PerlPoint::Parser>,
it will find several directives. A directive is a data struture flagging
that a certain document part (or even formatting) starts or is completed.
E.g. a headline is represented by headline start directive followed by
tokens for the headline contents followed by a headline completion directive.

By using this method, you can register directive specific functions which
should be called when the related directives are discovered. The idea is
that such a function can produce a target language construct representing
exactly the same document token that is modelled by the directive. E.g. if
your target language is HTML and you register a headline handler and a
headline start is found, this handler can generate a "<Hx>" tag. This
is quite simple.

According to this design, the object will pass the following data to
a registered function:

=over 4

=item directive

the directive detected, this should be the same the function was
registered for. See B<PerlPoint::Constants> for a list of directives.

=item start/stop flag

The document stream generated by the parser is strictly synchronous.
Everything except of plain strings is represented by an open directive
and a close directive, which may embed other parts of the document.
A headline begins, something is in, then it is complete. It's the
same for every tag or paragraph and even for the whole document.

So well, because of this structure, a handler registered for a certain
directive is called for opening directives as well as for closing
directives. To decide which case is true, a callback receives this
parameter. It's always one of the constants DIRECTIVE_START or
DIRECTIVE_COMPLETED.

For simple strings (words, spaces etc.) and line number hints, the
callback will always (and only) be called with DIRECTIVE_START.

=item directive values, if available

Certain directives provide additional data such as the headline level or the
original documents name which are passed to their callbacks additionally.
See the following list:

=over 4

=item Documents

transfer the I<basename> of the original ASCII document being parsed;

=item Headlines

transfer the headline level;

=item Ordered list points

  optionally transfer a fix point number;

=item Tags

transfer the tag name ("I", "B" etc.).

=back

=back

To express this by a prototype, all registered functions should have
an interface of "$$:@".

B<Parameters:>

=over 4

=item object

a backend object as made by I<new()>;

=item directive

the directive this handler is registered for. See B<PerlPoint::Constants> for a
list of directives.

=item handler

the function to be called if a pointed directive is entered while the
I<run()> method walks through the document stream.

=back

B<Returns:>
no certain value;

B<Example:>

  $backend->register(DIRECTIVE_HEADLINE, \&handleHeadline);

where handleHeadline could be something like

  sub handleDocument
   {
    my ($directive, $startStop, $level)=@_;
    confess "Something is wrong\n"
      unless $directive==DIRECTIVE_HEADLINE;
    if ($startStop==DIRECTIVE_START)
      {print "<head$level>";}
    else
      {print "</head>";}
   }

If I<no> handler is registered, detected items will be ignored by default except
of I<plain strings>, which will be I<printed> by default.

=cut
sub register
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($directive, $handler))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;
  confess "[BUG] Missing directive parameter.\n" unless defined $directive;
  confess "[BUG] Invalid directive parameter, use one of the directive constants.\n" unless $directive<=DIRECTIVE_SIMPLE;
  confess "[BUG] Missing handler parameter.\n" unless $handler;
  confess "[BUG] Handler parameter is no code reference.\n" unless ref($handler) and ref($handler) eq 'CODE';

  # check for an already existing handler
  warn "[Trace] Removing earlier handler setting (for directive $directive).\n" if $me->{trace} & TRACE_BACKEND and exists $me->{handler}{$directive};

  # well, all right, store the handler
  $me->{handler}{$directive}=$handler;
  warn "[Trace] Stored new handler (for directive $directive).\n" if $me->{trace} & TRACE_BACKEND;
 }

=pod

=head2 mode()

Switches the way an object inspects stream tokens. The new behaviour comes into action
with the I<next> supplied token - either within I<run()> or by invokation of I<next()>.

"Inspecting tokens" means how the object reads stream data to invoke registered handlers.

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=item new mode

All modes are declared by B<STREAM_...> constants in C<PerlPoint::Constants> (import
these constants by using the ":stream" tag).

=over 4

=item STREAM_TOKENS

The default mode. All stream tokens are inspected which takes time but enables a complete
document processing.

=item STREAM_HEADLINES

In headline mode the object only inspects headlines, which means opening and closing
headline directives and everything between. Headline mode is less complete but obviously
faster because all tokens outside headlines are ignored and headlines usually claim only
a small percentage of a document. This mode is useful to get informed about the structure
of a document, to build tables of contents or the like.

=back

=back

B<Returns:>

the new mode.

B<Example:>

  $backend->mode(STREAM_HEADLINES);

=cut
sub mode
 {
  # get parameters
  ((my __PACKAGE__ $me), my $mode)=@_;

  # and check parameters
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;
  confess "[BUG] Missing mode parameter.\n" unless $mode;
  confess "[BUG] Invalid mode parameter $mode.\n" unless $mode eq STREAM_TOKENS or $mode eq STREAM_HEADLINES;

  # adapt internal data as necessary
  unless (defined $me->{data})
    {
     # there is no stream associated with the object yet,
     # so we do not have to set its index values
    }
  elsif ($me->{stream}==STREAM_TOKENS and $mode==STREAM_HEADLINES)
    {
     # Switching from token to headline handling, we have to
     # update the headline index - we have to find the current
     # headline entry. This is easy because this must be the
     # last headline entry containing a token number lower than
     # (or equal to) the current one.
     $me->{streamControl}{headlineIndex}++ 
       while     $me->{streamControl}{headlineIndex} < $#{$me->{data}[STREAM_HEADLINES]}
             and    $me->{data}[STREAM_HEADLINES][$me->{streamControl}{headlineIndex}+1]
                 <= $me->{streamControl}{tokenIndex};
    }
  elsif ($me->{stream}==STREAM_HEADLINES and $mode==STREAM_TOKENS)
    {
     # switching from headline to token handling - no index
     # has to be adapted because the token index keeps always
     # up to date in headline mode
    }
  elsif ($me->{stream}==$mode)
    {
     # nothing to adapt
    }
  else
    {
     # oops
     die "[BUG] Unhandled case.";
    }

  # store new mode
  $me->{stream}=$mode;
 }

=pod

=head2 run()

The stream processor. The method walks through the data stream and inspects its tokens according
to the current mode (see I<mode()>) (which may be changed on the way). For each token, C<run()>
detects the appropriate type and checks if there is a callback registered for this type (see
C<register()>). If so, the callback is invoked to handle the token. If no handler is registered,
the token will be ignored except in the case of simple tokens, which will be printed to C<STDOUT>
by default.

If all (mode according) stream data are handled <run()> finishs.

The model of this method is to perform stream data processing by an enclosing loop which is
in control and knows of callbacks to handle "events" (occurences of certainly typed data).
There is an alternative model using I<next()> to give the I<caller> control of when to process
the next token.

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=item stream data

A reference to the stream data produced by a C<PerlPoint::Parser> call. Stream data are not
stored in an object (yet?), but nevertheless nothing but a data structure as supplied by the
parser will be accepted.

=back

B<Returns:>

nothing specific.

B<Example:>

  $backend->run($streamData);

=cut
sub run
 {
  # get parameters
  ((my __PACKAGE__ $me), my $stream)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;
  confess "[BUG] Missing stream parameter.\n" unless $stream;
  confess "[BUG] Stream parameter is no PerlPoint stream data structure.\n" unless ref($stream) and ref($stream) eq 'ARRAY' and $stream->[STREAM_IDENT] eq '__PerlPoint_stream__';

  # welcome user
  warn "[Info] Perl Point backend \"$me->{name}\" starts.\n" unless $me->{display} & DISPLAY_NOINFO;

  # declare variables
  my ($started)=(time);

  # init counter
  $me->{statistics}{&DIRECTIVE_HEADLINE}=0;

  # bind to the stream
  $me->bind($stream);

  # now start your walk
  while ($me->{streamControl}{tokenIndex} < $#{$stream->[STREAM_TOKENS]})
    {last unless $me->_next($stream);}

  # we are done with this stream for now
  $me->unbind;

  # inform user, if necessary
  warn(
       ($me->{vis} ? "\n" : ''), "       Stream processed in ", time-$started, " seconds.\n\n",
                                 "[Info] Backend \"$me->{name}\" is ready.\n\n"
      ) unless $me->{display} & DISPLAY_NOINFO;
 }


=pod

=head2 next()

This is an alternative stream data processing method to I<run()>. While I<run()> processes
all data completely, C<next()> handles exactly I<one> token. The most important difference
of these two approaches is that with C<next()> a caller is in full control of what happens.
This enables to move freely between chapters, to switch modes or to abort processing dependend
on current needs which might be expressed by a users input. In fact, C<next()> was introduced
to enable the implementation of projectors working on base of the token stream data directly.

Processing a I<token> works equally to I<run()> by type detection and handler invokation,
see there for details.

Please note that different to I<run()> a stream must be bound to a backend object before using
C<next()>. This is necessary to store processing states between various C<next()> calls and is
done by I<bind()>. After processing all data, I<unbind()> may be used to detach the stream.

To avoid confusion, C<next()> cannot be called from a callback invoked by I<run()>. In other
words, both approaches cannot be mixed.

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=back

B<Returns:>

A true value if there is more to process, a false value otherwise. It is up to the caller
to handle these cases appropriately.

B<Example:>

  # This example emulates run() by next().
  $backend->bind($streamData);
  {redo while $backend->next;}
  $backend->unbind;

=cut
sub next
 {
  # get parameters
  (my __PACKAGE__ $me)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;

  # data already provided?
  confess "[BUG] Please use bind() first to associate data.\n" unless defined $me->{data};

  # perform next step, supply the "there may be more" result code
  # so a user can check it (and call unbind() if he prefers)
  $me->_next($me->{data});
 }

# intended for internal use - walk one step in stream
sub _next
 {
  # get parameters (do not check them for reasons of performance - this function
  # is intended to be called internally *only* (quite often))
  ((my __PACKAGE__ $me), my $stream)=@_;

  # flag that we are invoked
  $me->{flags}{_nextInvokation}++;
  
  # check invokation level
  confess "[BUG] Method next() was called from a backend callback.\n" if $me->{flags}{_nextInvokation}>1;

  {
   # declare variables
   my ($token)=(0);

   # update counters
   if (
          $me->{stream}==STREAM_TOKENS
       or ($me->{stream}==STREAM_HEADLINES and $me->{processingHeadline})
      )
     {
      # we might have handled all tokens
      $me->{flags}{_nextInvokation}--, return 0
        if $me->{streamControl}{tokenIndex}==$#{$stream->[STREAM_TOKENS]};

      # update token index (headline index is handled later)
      $me->{streamControl}{tokenIndex}++;
     }
   elsif ($me->{stream}==STREAM_HEADLINES)
     {
      # we might have handled all headlines
      $me->{flags}{_nextInvokation}--, return 0
        if $me->{streamControl}{headlineIndex}==$#{$stream->[STREAM_HEADLINES]};

      # update headline index
      $me->{streamControl}{headlineIndex}++;

      # update token index
      $me->{streamControl}{tokenIndex}=$stream->[STREAM_HEADLINES][$me->{streamControl}{headlineIndex}];
     }
   else
     {
      # oops!
      die "[BUG] Unhandled case.\n";
     }

   # get token
   $token=$stream->[STREAM_TOKENS][$me->{streamControl}{tokenIndex}];

   # should this token be skipped?
   if ($me->{hide} or @{$me->{ignoredDirectives}})
     {
      # Directive? This could finish skipping.
      if (ref($token))
        {
         # Is this the finishing token? (Note that the final token is skipped as well.)
         # Check "hide all" before "ignore certain tokens" because the first is of higher precedence.
         $me->{hide}=0, redo if $me->{hide} and $token->[STREAM_DIR_HINTS]{nr}==$me->{hide};
         pop(@{$me->{ignoredDirectives}}), redo if @{$me->{ignoredDirectives}} and $token->[STREAM_DIR_HINTS]{nr}==$me->{ignoredDirectives}[-1];
        }

      # whatever token this is, it has to be hidden in hiding mode
      redo if $me->{hide};
     }

   # check token type
   unless (ref($token))
     {
      # trace, if necessary
      warn "[Trace] Token $me->{streamControl}{tokenIndex} is a simple string.\n" if $me->{trace} & TRACE_BACKEND;

      # dummy tokens are ignored, all other tokens are processed
      unless ($token eq DUMMY_TOKEN)
       {
        # now check if there was a handler declared
        if (exists $me->{handler}{DIRECTIVE_SIMPLE()})
         {
          # trace, if necessary
          warn "[Trace] Using user defined handler.\n" if $me->{trace} & TRACE_BACKEND;

          # call the handler passing the string
          &{$me->{handler}{DIRECTIVE_SIMPLE()}}($me->{generator} ? $me->{generator} : (), DIRECTIVE_SIMPLE, DIRECTIVE_START, $token);
         }
        else
         {
          # trace, if necessary
          warn "[Trace] Using default handler.\n" if $me->{trace} & TRACE_BACKEND;

          # well, the default is to just print it out
          print $token;
         }
       }
     }
   else
     {
      # trace, if necessary
      warn "[Trace] Token $me->{streamControl}{tokenIndex} is a directive (", $token->[STREAM_DIR_TYPE], ").\n" if $me->{trace} & TRACE_BACKEND;

      # process parser hints, if any
      push(@{$me->{ignoredDirectives}}, $token->[STREAM_DIR_HINTS]{nr}), redo
        if exists $token->[STREAM_DIR_HINTS]{ignore};
      $me->{hide}=$token->[STREAM_DIR_HINTS]{nr}, redo
        if exists $token->[STREAM_DIR_HINTS]{hide};

      # headline?
      if ($token->[STREAM_DIR_TYPE]==DIRECTIVE_HEADLINE)
        {
         if ($token->[STREAM_DIR_STATE]==DIRECTIVE_START)
           {
            # update headline index, if necessary
            $me->{streamControl}{headlineIndex}++ if $me->{stream}==STREAM_TOKENS;

            # update "statistics"
            $me->{statistics}{&DIRECTIVE_HEADLINE}++ if $token->[STREAM_DIR_TYPE]==DIRECTIVE_HEADLINE;

            # let the user know that something is going on
            print STDERR "\r", ' ' x length('[Info] '), '... ', $me->{statistics}{&DIRECTIVE_HEADLINE}, " chapters processed."
              if $me->{vis} and not $me->{statistics}{&DIRECTIVE_HEADLINE} % $me->{vis};

            # update headline flag
            $me->{processingHeadline}=1;
           }
         else
           {
            # update headline flag
            $me->{processingHeadline}=0;
           }
        }

      # call the general handler, if any
      &{$me->{handler}{DIRECTIVE_EVERY()}}($me->{generator} ? $me->{generator} : (), @{$token}[1..$#{$token}]) if exists $me->{handler}{DIRECTIVE_EVERY()};

      # now check if there was a handler declared
      if (exists $me->{handler}{$token->[STREAM_DIR_TYPE]})
        {
         # trace, if necessary
         warn "[Trace] Using user defined handler.\n" if $me->{trace} & TRACE_BACKEND;

         # call the handler passing additional informations, if any
         &{$me->{handler}{$token->[STREAM_DIR_TYPE]}}($me->{generator} ? $me->{generator} : (), @{$token}[1..$#{$token}]);
        }
      else
        {
         # trace, if necessary
         warn "[Trace] Acting by default (ignoring token).\n" if $me->{trace} & TRACE_BACKEND;

         # well, the default is to ignore it
        }
     }
  }

  # update invokation level
  $me->{flags}{_nextInvokation}--;

  # flag that there's still more to process probably
  1;
 }

=pod

=head2 bind()

Binds a stream data structure to a backend object. If I<run()> is used to process a stream,
there is no need to use C<bind()> because it is called by C<run()> implicitly.

If there was already a stream connected to the backend object, the new connection will replace
the old one.

Binding a stream I<resets> stream processing (see I<reset()>). I<Do not call this method
from a handler unless you know exactly what is going on.>

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=item stream data

A reference to the stream data produced by a C<PerlPoint::Parser> call. Stream data are not
stored in an object (yet?), but nevertheless nothing but a data structure as supplied by the
parser will be accepted.

=back

B<Returns:>

nothing significant.

B<Example:>

  $backend->bind($streamData);

=cut
sub bind
 {
  # get parameters
  ((my __PACKAGE__ $me), my $stream)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;
  confess "[BUG] Missing stream parameter.\n" unless $stream;
  confess "[BUG] Stream parameter is no PerlPoint stream data structure.\n" unless ref($stream) and ref($stream) eq 'ARRAY' and $stream->[STREAM_IDENT] eq '__PerlPoint_stream__';

  # store data reference to make it accessible by other methods
  $me->{data}=$stream;

  # reset stream processing
  $me->reset;
 }

=pod

=head2 unbind()

Detaches a stream data structure bound to the backend object.

Unbinding a stream I<resets> stream processing (see I<reset()>) - if the stream is rebound
to the object and furtherly processed, it will be processed from its beginning.

I<Do not call this method from a handler unless you know exactly what is going on.>

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=back

B<Returns:>

nothing significant.

B<Example:>

  $backend->unbind();

=cut
sub unbind
 {
  # get parameters
  (my __PACKAGE__ $me)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;

  # reset stream processing, detach data
  $me->reset;
  $me->{data}=$me->{streamControl}=undef;
 }

# METHODS INTENDED TO BE CALLED FROM HANDLERS. ################################################

=pod

=head2 reset()

Resets processing of a stream associated with (or bound to) the backend object. This means
that further processing will start with the very first token matching the current mode (see
I<mode()>).

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=back

B<Returns:>

nothing significant.

B<Example:>

  $backend->reset;

=cut
sub reset
 {
  # get parameters
  (my __PACKAGE__ $me)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;

  # reset stream, if necessary
  @{$me->{streamControl}}{qw(tokenIndex headlineIndex)}=(-1, -1) if defined $me->{data};
 }


=pod

=head2 move2chapter()

Causes stream processing to continue with a certain chapter.

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=item chapter

The number of the target chapter to process next. This is an I<absolute> number - the first
headline is headline B<1>, the second B<2> etc., regardless of headline hierachies. The highest
valid number is equal to the result of I<headlineNr()>.

=back

B<Returns:>

nothing significant.

B<Example:>

  $backend->move2chapter(15);

=cut
sub move2chapter
 {
  # get parameters
  ((my __PACKAGE__ $me), my $chapter)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;
  confess "[BUG] There is no stream associated to this backend object yet, use bind() or run().\n" unless defined $me->{data};
  confess "[BUG] Missing chapter parameter.\n" unless $chapter;
  confess "[BUG] Chapter parameter \"$chapter\" is no (valid) number.\n" unless $chapter=~/^\d+$/;
  confess "[BUG] Chapter parameter \"$chapter\" exceeds chapter range.\n" unless $chapter>0 and $chapter<=@{$me->{data}[STREAM_HEADLINES]};

  # reset headline flag (if we are currently processing a headline)
  $me->{processingHeadline}=0;

  # go to the headline stream entry right before the wished one (run() will increment
  # first assuming it processed straight forward) - note that for reasons of convenience,
  # we allow the user to provide a chapter *number* (beginning with 1), while we have to
  # use an index (beginning with 0), so the final decreasing value is 2
  $me->{streamControl}{headlineIndex}=$chapter-2;

  # go to the last token *before* the new chapter
  $me->{streamControl}{tokenIndex}=$me->{data}[STREAM_HEADLINES][$chapter-1]-1;
 }



=pod

=head2 headlineNr()

Replies the number of headlines in the stream associated with the object. If no stream is
associated, an undefined value is supplied.

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=back

B<Returns:>

The number of headlines in the stream if a stream is associated, an undefined value otherwise.

B<Example:>

  $backend->headlineNr;

=cut
sub headlineNr
 {
  # get parameters
  (my __PACKAGE__ $me)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;

  # provide number of headlines, if possible
  defined $me->{data} ? scalar(@{$me->{data}[STREAM_HEADLINES]}) : undef;
 }


=pod

=head2 headlineIds2Data()


B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=item list of headline ids

A list of ids. An id is an I<absolute> headline number, starting with 1.

=back

B<Returns:>

The number of headlines in the stream if a stream is associated, an undefined value otherwise.

B<Example:>

  $backend->headlineIds2Data;

=cut
sub headlineIds2Data
 {
  # get parameters
  ((my __PACKAGE__ $me), my $ids)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;
  confess "[BUG] Missing headline id parameter.\n" unless $ids;
  confess "[BUG] Headline id parameter is no array reference.\n" unless ref $ids and ref $ids eq 'ARRAY';

  # data already provided?
  confess "[BUG] Please use bind() first to associate data.\n" unless defined $me->{data};

  # declare variables
  my (@results);

  # handle all ids
  foreach my $id (@$ids)
    {
     # check id
     confess qq([BUG] Invalid id "$id".\n) unless $id=~/^\d+$/ and $id>0 and $id<=@{$me->{data}[STREAM_HEADLINES]};

     # get data
     push(@results, $me->{data}[STREAM_TOKENS][$me->{data}[STREAM_HEADLINES][$id-1]]);
    }

  # supply results
  \@results;
 }


=pod

=head2 currentChapterNr()

Replies the number of the currently processed chapter - in the stream associated with the object.
If no stream is associated, an undefined value is supplied.

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=back

B<Returns:>

The number of the currently handled headline in the stream if a stream is associated, an
undefined value otherwise.

B<Example:>

  $backend->currentChapterNr;

=cut
sub currentChapterNr
 {
  # get parameters
  (my __PACKAGE__ $me)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and ref $me eq __PACKAGE__;

  # provide number of headlines, if possible
  # (provide an incremented number for reasons of convenience)
  defined $me->{data} ? $me->{streamControl}{headlineIndex}+1 : undef;
 }


=pod

=head2 toc()

This method provides a convenient way to get a list of subchapters related
to a certain "parent" chapter. More, it can be used to get a complete table of
contents as well. Each subchapter is presented by its headline (hierarchy)
level and its title in plain text.

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=item chapter of interest

This is an absolute number as used in various other methods as well. The first
headline in the document is number 1, the next headline number 2 and so on.
(The number of the chapter currently processed is always provided by
I<currentChapterNr()>.)

If this parameter is omitted or 0, the whole documents hierarchy will be reported. 

=item result depth

There may be a deep hierarchy of subchapters. If only a certain depth is of
interest, supply it here. If this parameter is omitted or set to 0, I<all>
subchapters will be reported.

=back

B<Returns:>

a reference to an array of arrays, where each entry describes a subchapter by
its headline level and its title (as plain text - tags etc. are stripped off).

B<Example:>

  $subchapters=$backend->toc(5, 2);

=cut
sub toc
 {
  # get parameters
  ((my __PACKAGE__ $me), my ($start, $depth))=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n"  unless ref $me and ref $me eq __PACKAGE__;
  confess "[BUG] There is no stream associated to this backend object yet, use bind() or run().\n" unless defined $me->{data};
  confess "[BUG] Start parameter \"$start\" is no (valid) number.\n"  if defined $start and $start!~/^\d+$/;
  confess "[BUG] Start parameter \"$start\" exceeds chapter range.\n" if defined $start and $start>@{$me->{data}[STREAM_HEADLINES]};
  confess "[BUG] Depth parameter \"$depth\" is no (valid) number.\n"  if $depth and $depth!~/^\d+$/;

  # by default, we process the complete document
  $start=0 unless $start;

  # anything to do?
  return [] unless     @{$me->{data}[STREAM_HEADLINES]}
                   and $start<scalar(@{$me->{data}[STREAM_HEADLINES]});

  # declare variables
  my ($c, $completed, $results)=(-1, 0, []);

  # get startup headline level
  my $startupLevel=$start ? $me->{data}[STREAM_TOKENS][$me->{data}[STREAM_HEADLINES][$start-1]][3] : 0;

  # make a simple helper object
  my $helper=new(
                 __PACKAGE__,
                 name    => 'helper backend',
                 display => DISPLAY_NOINFO+DISPLAY_NOWARN,
                 trace   => TRACE_NOTHING,
                );

  # register headline handler
  $helper->register(DIRECTIVE_HEADLINE,
                    sub
                     {
                      # get parameters
                      my ($opcode, $mode, $level)=@_;

                      # act mode dependend
                      if ($mode==DIRECTIVE_START)
                        {
                         # check headline level
                         if ($level<=$startupLevel)
                           {
                            # task completed, stop handling
                            $completed=1;
                           }
                         elsif ($depth and $level>$startupLevel+$depth)
                           {
                            # immediately jump to the next chapter, if any
                            my $ccn=$helper->currentChapterNr;
                            if ($ccn==@{$me->{data}[STREAM_HEADLINES]})
                              {$completed=1;}
                            else
                              {$helper->move2chapter($ccn+1);}
                           }
                         else
                           {
                            # increment buffer index, store headline level
                            $results->[++$c][0]=$level;
                           }
                        }
                     },
                   );

  # register plain text handler to get the headlines text
  $helper->register(DIRECTIVE_SIMPLE,
                    sub
                     {
                      # get parameters
                      my ($opcode, $mode, @contents)=@_;

                      # update headline string (use of .= operator avoids warnings)
                      $results->[$c][1].=join('', @contents)
                     }
                   );

  # switch helper object into headline mode, move behind the startup
  # headline and run it (it will stop automatically when it will have
  # been handled all subchapters)
  $helper->bind($me->{data});
  $helper->mode(STREAM_HEADLINES);
  $helper->move2chapter($start+1);
  {redo while not $completed and $helper->_next($helper->{data});}

  # supply result
  $results;
 }


=pod

=head2 docstreams()

Supplies the names of all document streams in the data stream.
A data streams needs to be bound to the object.

B<Parameters:>

=over 4

=item object

An object as built by I<new()>.

=back

B<Returns:>

A list of document stream titles in list context, the number of document
streams in scalar context.

B<Example:>

  @docstreams=$backend->docstreams;

=cut
sub docstreams
 {
  # get parameters
  (my __PACKAGE__ $me)=@_;

  # and check them
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n"  unless ref $me and ref $me eq __PACKAGE__;
  confess "[BUG] There is no stream associated to this backend object yet, use bind() or run().\n" unless defined $me->{data};

  # build an array of docstream titles
  my @docstreams=keys %{$me->{data}[STREAM_DOCSTREAMS]};

  # supply result as wished
  wantarray ? @docstreams : scalar(@docstreams);
 }


1;


# = POD TRAILER SECTION =================================================================

=pod

=head1 SEE ALSO

=over 4

=item B<PerlPoint::Parser>

A parser for Perl Point ASCII texts.

=item B<PerlPoint::Constants>

Public PerlPoint::... module constants.

=back


=head1 SUPPORT

A PerlPoint mailing list is set up to discuss usage, ideas,
bugs, suggestions and translator development. To subscribe,
please send an empty message to perlpoint-subscribe@perl.org.

If you prefer, you can contact me via perl@jochen-stenzel.de
as well.

=head1 AUTHOR

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 1999-2002.
All rights reserved.

This module is free software, you can redistribute it and/or modify it
under the terms of the Artistic License distributed with Perl version
5.003 or (at your option) any later version. Please refer to the
Artistic License that came with your Perl distribution for more
details.

The Artistic License should have been included in your distribution of
Perl. It resides in the file named "Artistic" at the top-level of the
Perl source tree (where Perl was downloaded/unpacked - ask your
system administrator if you dont know where this is).  Alternatively,
the current version of the Artistic License distributed with Perl can
be viewed on-line on the World-Wide Web (WWW) from the following URL:
http://www.perl.com/perl/misc/Artistic.html


=head1 DISCLAIMER

This software is distributed in the hope that it will be useful, but
is provided "AS IS" WITHOUT WARRANTY OF ANY KIND, either expressed or
implied, INCLUDING, without limitation, the implied warranties of
MERCHANTABILITY and FITNESS FOR A PARTICULAR PURPOSE.

The ENTIRE RISK as to the quality and performance of the software
IS WITH YOU (the holder of the software).  Should the software prove
defective, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION.

IN NO EVENT WILL ANY COPYRIGHT HOLDER OR ANY OTHER PARTY WHO MAY CREATE,
MODIFY, OR DISTRIBUTE THE SOFTWARE BE LIABLE OR RESPONSIBLE TO YOU OR TO
ANY OTHER ENTITY FOR ANY KIND OF DAMAGES (no matter how awful - not even
if they arise from known or unknown flaws in the software).

Please refer to the Artistic License that came with your Perl
distribution for more details.

=cut
