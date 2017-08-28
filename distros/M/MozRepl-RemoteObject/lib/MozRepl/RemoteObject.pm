package MozRepl::RemoteObject;
use strict;
use Exporter 'import';
use JSON;
use Encode qw(decode);
use Carp qw(croak);
use Scalar::Util qw(refaddr weaken);

=head1 NAME

MozRepl::RemoteObject - treat Javascript objects as Perl objects

=head1 SYNOPSIS

  #!perl -w
  use strict;
  use MozRepl::RemoteObject;

  # use $ENV{MOZREPL} or localhost:4242
  my $repl = MozRepl::RemoteObject->install_bridge();

  # get our root object:
  my $tab = $repl->expr(<<JS);
      window.getBrowser().addTab()
  JS

  # Now use the object:
  my $body = $tab->{linkedBrowser}
              ->{contentWindow}
              ->{document}
              ->{body}
              ;
  $body->{innerHTML} = "<h1>Hello from MozRepl::RemoteObject</h1>";

  $body->{innerHTML} =~ '/Hello from/'
      and print "We stored the HTML";

  $tab->{linkedBrowser}->loadURI('https://corion.net/');

=cut

use vars qw[$VERSION $objBridge @CARP_NOT @EXPORT_OK $WARN_ON_LEAKS];
$VERSION = '0.40';

@EXPORT_OK=qw[as_list];
@CARP_NOT = (qw[MozRepl::RemoteObject::Instance
                MozRepl::RemoteObject::TiedHash
                MozRepl::RemoteObject::TiedArray
               ]);

# This should go into __setup__ and attach itself to $repl as .link()
$objBridge = <<JS;
(function(repl){
repl.link = function(obj) {
    // These values should go into a closure instead of attaching to the repl
    if (! repl.linkedVars) {
        repl.linkedVars = {};
        repl.linkedIdNext = 1;
    };

    if (obj) {
        repl.linkedVars[ repl.linkedIdNext ] = obj;
        return repl.linkedIdNext++;
    } else {
        return undefined
    }
};

repl.getLink = function(id) {
    return repl.linkedVars[ id ];
};

repl.breakLink = function() {
    var l = arguments.length;
    for(i=0;i<l;i++) {
        delete repl.linkedVars[ arguments[i] ];
    };
};

repl.purgeLinks = function() {
    repl.linkedVars = {};
    repl.linkedIdNext = 1;
};

repl.JSON_ok = function(val,context) {
    return JSON.stringify({
        "status":"ok",
        "result": repl.wrapResults(val,context)
    });
};

repl.getAttr = function(id,attr) {
    var v = repl.getLink(id)[attr];
    return v
};

repl.wrapValue = function(v,context) {
    var payload;
    if (context == "list") {
        // The caller wants a lists instead of an array ref
        // alert("Returning list " + v.length);
        var r = [];
        for (var i=0;i<v.length;i++){
            r.push(repl.wrapValue(v[i]));
        };
        payload = { "result":r, "type":"list" };
    } else if (v instanceof String
       || typeof(v) == "string"
       || v instanceof Number
       || typeof(v) == "number"
       || v instanceof Boolean
       || typeof(v) == "boolean"
       ) {
        payload = {"result":v, "type": null }
    } else {
        payload = {"result":repl.link(v),"type": typeof(v) }
    };
    return payload
}

var eventQueue = [];
repl.wrapResults = function(v,context) {
    var payload = repl.wrapValue(v,context);
    if (eventQueue.length) {
        payload.events = eventQueue;
        eventQueue = [];
    };
    return payload;
};

repl.dive = function(id,elts) {
    var obj = repl.getLink(id);
    var last = "<start object>";
    for (var idx=0;idx <elts.length; idx++) {
        var e = elts[idx];
        // because "in" doesn't seem to look at inherited properties??
        if (e in obj || obj[e]) {
            last = e;
            obj = obj[ e ];
        } else {
            throw "Cannot dive: " + last + "." + e + " is empty.";
        };
    };
    return obj
};

repl.callThis = function(id,args) {
    var obj = repl.getLink(id);
    var res = obj.apply(obj, args);
    return res
};

repl.callMethod = function(id,fn,args) {
    var obj = repl.getLink(id);
    var f = obj[fn];
    if (! f) {
        throw "Object has no function " + fn;
    }
    return f.apply(obj, args);
};


repl.makeCatchEvent = function(myid) {
        var id = myid;
        return function() {
            var myargs = arguments;
            eventQueue.push({
                cbid : id,
                ts   : Number(new Date()),
                args : repl.link(myargs)
            });
        };
};

repl.q = function (queue) {
    try {
        eval(queue);
    } catch(e) {
        // Silently eat those errors
        // alert("Error in queue: " + e.message + "["+queue+"]");
    };
};

repl.ejs = function (js,context) {
    try {
        var res = eval(js);
        return repl.JSON_ok(res,context);
    } catch(e) {
        //for (var x in e) { alert(x)};
        return JSON.stringify({
            "status":"error",
            "name": e.name,
            "message": e.message ? e.message : e,
            //"line":e.lineNumber,
            "command":js
        });
    };
};

// This should return links to all installed functions
// so we can get rid of nasty details of ->expr()
// return repl.wrapResults({});
})([% rn %]);
JS

# Take a JSON response and convert it to a Perl data structure
sub to_perl {
    my ($self,$js) = @_;
    local $_ = $js;
    #s/^(\.+\>\s*)+//; # remove Mozrepl continuation prompts
    s/^"//;
    s/"$//;

    if (/^(\.+>\s*)+/) {
        # This should now be eliminated!
        die "Continuation prompt found in [$_]";
    }

    #warn $js;
    # reraise JS errors from perspective of caller
    if (/^!!!\s+(.*)$/m) {
        croak "MozRepl::RemoteObject: $1";
    };

    if (! /\S/) {
        # We got an empty string back from the REPL ...
        warn "Got empty string from REPL";
        return;
    }

    # In the case that we don't have a unicode string
    # already, decode the string from UTF-8
    $js = decode('UTF-8', $_);
    #warn "[[$_]]";
    my $res;
    local $@;
    my $json = $self->json;
    if (! eval {

        $res = $json->decode($js);
        #use Data::Dumper;
        #warn Dumper $res;
        1
    }) {
        my $err = $@;
        my $offset;
        if ($err =~ /character offset (\d+)\b/) {
            $offset = $1
        };
        $offset -= 10;
        $offset = 0 if $offset < 0;
        warn sprintf "(Sub)string is [%s]", substr($js,$offset,20);
        die $@
    };
    $res
};

# Unwrap the result, will in the future also be used
# to handle async events
sub unwrap_json_result {
    my ($self,$data) = @_;
    if (my $events = delete $data->{events}) {
        my @ev = @$events;
        for my $ev (@ev) {
            $self->{stats}->{callback}++;
            ($ev->{args}) = $self->link_ids($ev->{args});
            $self->dispatch_callback($ev);
            undef $ev; # release the memory early!
        };
    };
    my $t = $data->{type} || '';
    if ($t eq 'list') {
        return map {
            $_->{type}
            ? $self->link_ids( $_->{result} )
            : $_->{result}
        } @{ $data->{result} };
    } elsif ($data->{type}) {
        return ($self->link_ids( $data->{result} ))[0]
    } else {
        return $data->{result}
    };
};

# Call JS and return the unwrapped result
sub unjson {
    my ($self,$js,$context) = @_;
    my $data = $self->js_call_to_perl_struct($js,$context);
    return $self->unwrap_json_result($data);
};

=head1 BRIDGE SETUP

=head2 C<< MozRepl::RemoteObject->install_bridge %options >>

Installs the Javascript C<< <-> >> Perl bridge. If you pass in
an existing L<MozRepl> instance, it must have L<MozRepl::Plugin::JSON2>
loaded if you're running on a browser without native JSON support.

If C<repl> is not passed in, C<$ENV{MOZREPL}> will be used
to find the ip address and portnumber to connect to. If C<$ENV{MOZREPL}>
is not set, the default of C<localhost:4242> will be used.

If C<repl> is not a reference, it will be used instead of C<$ENV{MOZREPL}>.

To replace the default JSON parser, you can pass it in using the C<json>
option.

=over 4

=item *

C<repl> - a premade L<MozRepl> instance to use, or alternatively a
connection string to use

=item *

C<use_queue> - whether to queue destructors until the next command. This
reduces the latency and amount of queries sent via L<MozRepl> by half,
at the cost of a bit delayed release of objects on the remote side. The
release commands get queued until the next "real" command gets sent
through L<MozRepl>.

=item *

C<launch> - the command line to launch the program that runs C<mozrepl>.

=back

=head3 Connect to a different machine

If you want to connect to a Firefox instance on a different machine,
call C<< ->install_bridge >> as follows:

    MozRepl::RemoteObject->install_bridge(
        repl => "$remote_machine:4242"
    );

=head3 Using an existing MozRepl

If you want to pass in a preconfigured L<MozRepl> object,
call C<< ->install_bridge >> as follows:

    my $repl = MozRepl->new;
    $repl->setup({
        log => [qw/ error info /],
        plugins => { plugins => [qw[ JSON2 ]] },
    });
    my $bridge = MozRepl::RemoteObject->install_bridge(repl => $repl);

=head3 Launch a mozrepl program if it's not found running

If you want to launch Firefox if it's not already running,
call C<< ->install_bridge >> as follows:

    MozRepl::RemoteObject->install_bridge(
        launch => 'iceweasel' # that program must be in the path
    );

=head3 Using a custom command line

By default the launched program will be launched with the C<-repl>
command line switch to start up C<mozrepl>. If you need to provide
the full command line, pass an array reference to the
C<launch> option:

    MozRepl::RemoteObject->install_bridge(
        launch => ['iceweasel','-repl','666']
    );

=head3 Using a custom Mozrepl class

By default, any class named in C<$ENV{MOZREPL}> will get loaded and used
as the MozRepl backend. That value will get untainted!
If you want to prevent C<$ENV{MOZREPL}>
from getting used, pass an explicit class name using the C<repl_class>
option.

    MozRepl::RemoteObject->install_bridge(
        repl_class => 'MozRepl::AnyEvent',
    );

=head3 Preventing/forcing native JSON

The Javascript part of MozRepl::RemoteObject will try to detect whether
to use the native Mozilla C<JSON> object or whether to supply its own
JSON encoder from L<MozRepl::Plugin::JSON2>. To prevent the autodetection,
pass the C<js_JSON> option:

  js_JSON => 'native', # force to use the native JSON object

  js_JSON => '', # force the json2.js encoder

The autodetection detects whether the connection has a native JSON
encoder and whether it properly transports UTF-8.

=cut

sub require_module($) {
    local $_ = shift;
    s{::|'}{/}g;
    require "$_.pm"; # dies if the file is not found
};

sub install_bridge {
    my ($package, %options) = @_;
    $options{ repl } ||= $ENV{MOZREPL};
    my $repl_class = delete $options{ repl_class } || $ENV{MOZREPL_CLASS} || 'MozRepl';
    # Untaint repl class
    $repl_class =~ /^((?:\w+::)+\w+)$/
        and $repl_class = $1;
    $options{ constants } ||= {};
    $options{ log } ||= [qw/ error/];
    $options{ queue } ||= [];
    $options{ bufsize } ||= 10_240_000;
    $options{ use_queue } ||= 0; # > 0 means enqueue
    # mozrepl
    # / Net::Telnet don't like too large commands
    $options{ max_queue_size } ||= 1000;

    $options{ command_sep } ||= "\n--end-remote-input\n";

    if (! ref $options{repl}) { # we have host:port
        my @host_port;
        if (defined $options{repl}) {
            $options{repl} =~ /^(.*):(\d+)$/
                or croak "Couldn't find host:port from [$options{repl}].";
            push @host_port, host => $1
                if defined $1;
            push @host_port, port => $2
                if defined $2;
        };
        require_module $repl_class;
        $options{repl} = $repl_class->new();
        RETRY: {
            my $ok = eval {
                $options{repl}->setup({
                    client => {
                        @host_port,
                        extra_client_args => {
                            binmode => 1,
                        }
                    },
                    log => $options{ log },
                    plugins => { plugins => [] },
                });

                if (my $bufsize = delete $options{ bufsize }) {
                    if ($options{ repl }->can('client')) {
                        $options{ repl }->client->telnet->max_buffer_length($bufsize);
                    };
                };

                1;
            };
            if (! $ok ) {
                if( $options{ launch }) {
                    require IPC::Run;
                    my $cmd = delete $options{ launch };
                    if (! ref $cmd) {
                        $cmd = [$cmd,'-repl']
                    };
                    IPC::Run::start($cmd);
                    sleep 2; # to give the process a chance to launch
                    redo RETRY
                } else {
                    die "Failed to connect to @host_port, $@";
                }
            }
        };
    };

    if(! exists $options{ js_JSON }) {
        # Autodetect whether we need the custom JSON serializer

        # It's required on Firefox 3.0 only
        my $capabilities = $options{ repl }->execute(
          join "",
              # Extract version
              'Components.classes["@mozilla.org/xre/app-info;1"].',
              'getService(Components.interfaces.nsIXULAppInfo).version+"!"',
              # Native JSON object available?
              q{+eval("var r;try{r=JSON.stringify('\u30BD');}catch(e){r=''};r")},
               # UTF-8 transport detection
              '+"!\u30BD"',
              ";\n"
        );
        $capabilities =~ s/^"(.*)"\s*$/$1/;
        $capabilities =~ s/^"//;
        $capabilities =~ s/"$//;
        #warn "Capabilities: [$capabilities]";
        my ($version, $have_native, $unicode) = split /!/, $capabilities;

        #warn $unicode;
        #warn sprintf "%02x",$_ for map{ord} split //, $unicode;
        if ($have_native eq '') {
            $options{ js_JSON } ||= "json2; No native JSON object found ($version)";
        };
        if( lc $have_native eq lc q{"\u30bd"} # values get escaped
            or $have_native eq qq{"\x{E3}\x{82}\x{BD}"} # values get encoded as UTF-8
          ) {
            # so we can transport unicode properly
            $options{ js_JSON } ||= 'native';
        } else {
            $options{ js_JSON } ||= "json2; Transport not UTF-8-safe";
        };
    };

    if ($options{ js_JSON } ne 'native') {
        # send our own JSON encoder
        #warn "Installing custom JSON encoder ($options{ native_JSON })";
        require MozRepl::Plugin::JSON2;

        my $json2 = MozRepl::Plugin::JSON2->new()->process('setup');
        $options{ repl }->execute($json2);

        # Now, immediately check whether our transport is UTF-8 safe:
        my $utf8 = $options{ repl }->execute(
              q{JSON.stringify('\u30BD')}.";\n"
        );
        $utf8 =~ s/\s*$//;
        lc $utf8 eq lc q{""\u30bd""}
            or warn "Transport still not UTF-8 safe: [$utf8].\nDo you have mozrepl 1.1.0 or later installed?";
    };

    my $rn = $options{repl}->repl;
    $options{ json } ||= JSON->new->allow_nonref->ascii; # We talk ASCII
    # Is this still true? It seems to be even when we find an UTF-8 safe
    # transport above. This needs some investigation.

    # Switch the Perl-repl to multiline input mode
    # Well, better use a custom interactor and pass JSON messages that
    # are self-delimited and contain no newlines. Newline for a new message.

    # Switch the JS-repl to multiline input mode
    $options{repl}->execute("$rn.setenv('inputMode','multiline');undefined;\n");

    # Load the JS side of the JS <-> Perl bridge
    my $c = $objBridge; # make a copy
    $c =~ s/\[%\s+rn\s+%\]/$rn/g; # cheap templating
    #warn $c;

    $package->execute_command($c, %options);

    $options{ functions } = {}; # cache
    $options{ constants } = {}; # cache
    $options{ callbacks } = {}; # active callbacks

    bless \%options, $package;
};

sub execute_command {
    my ($self, $command, %options) = @_;
    $options{ repl } ||= $self->repl;
    $options{ command_sep } ||= $self->command_sep
        unless exists $options{ command_sep };
    $command =~ s/\s+$//;
    $command .= $options{ command_sep };
    $options{repl}->execute($command);
};

=head2 C<< $bridge->expr( $js, $context ) >>

Runs the Javascript passed in through C< $js > and links
the returned result to a Perl object or a plain
value, depending on the type of the Javascript result.

This is how you get at the initial Javascript object
in the object forest.

  my $window = $bridge->expr('window');
  print $window->{title};

You can also create Javascript functions and use them from Perl:

  my $add = $bridge->expr(<<JS);
      function (a,b) { return a+b }
  JS
  print $add->(2,3);
  # prints 5

The C<context> parameter allows you to specify that you
expect a Javascript array and want it to be returned
as list. To do that, specify C<'list'> as the C<$context> parameter:

  for ($bridge->expr(<<JS,'list')) { print $_ };
      [1,2,3,4]
  JS

This is slightly more efficient than passing back an array reference
and then fetching all elements.

=cut

# This is used by ->declare() so can't use it itself
sub expr {
    my ($self,$js,$context) = @_;
    return $self->unjson($js,$context);
}

# the queue stuff is left undocumented because it's
# not necessarily useful. The destructors use it to
# bundle the destruction of objects when run through
# ->queued()
sub exprq {
    my ($self,$js) = @_;
    if (defined wantarray) {
        croak "->exprq cannot return a result yet";
    };
    if ($self->{use_queue}) {
        # can we fake up a result here? Maybe hand out a fictional
        # object id and tell the JS to construct an object here,
        # just in case we need it?
        # later
        push @{ $self->{queue} }, $js;
        if (@{ $self->{queue} } > $self->{ max_queue_size }) {
            # flush queue
            $self->poll;
        };
    } else {
        $self->js_call_to_perl_struct($js);
        # but we're not really interested in the result
    };
}

=head2 C<< as_list( $array ) >>

    for $_ in (as_list $array) {
        print $_->{innerHTML},"\n";
    };

Efficiently fetches all elements from C< @$array >. This is
functionally equivalent to writing

    @$array

except that it involves much less roundtrips between Javascript
and Perl. If you find yourself using this, consider
declaring a Javascript function with C<list> context
by using C<< ->declare >> instead.

=cut

sub as_list {
    my ($array) = @_;
    my $repl = $array->bridge;
    my $as_array = $repl->declare(<<'JS','list');
        function(a){return a}
JS
    $as_array->($array)
};

sub queued {
    my ($self,$cb) = @_;
    if (defined wantarray) {
        croak "->queued cannot return a result yet";
    };
    $self->{use_queue}++;
    $cb->();
    # ideally, we would gather the results here and
    # also return those, if wanted.
    if (--$self->{use_queue} == 0) {
        # flush the queue
        #my $js = join "//\n;//\n", @{ $self->queue };
        my $js = join "\n", map { /;$/? $_ : "$_;" } @{ $self->queue };
        # we don't want a result here!
        # This is where we would do ->execute_async on AnyEvent
        $self->execute_command($js);
        @{ $self->queue } = ();
    };
};

sub DESTROY {
    my ($self) = @_;
    local $@;
    #warn "Repl cleaning up";
    delete @{$self}{ qw( constants functions callbacks )};
    if ($self->{use_queue} and $self->queue and @{ $self->queue }) {
        $self->poll;
    };
    #warn "Repl cleaned up";
};

=head2 C<< $bridge->declare( $js, $context ) >>

Shortcut to declare anonymous JS functions
that will be cached in the bridge. This
allows you to use anonymous functions
in an efficient manner from your modules
while keeping the serialization features
of MozRepl::RemoteObject:

  my $js = <<'JS';
    function(a,b) {
        return a+b
    }
  JS
  my $fn = $self->bridge->declare($js);
  $fn->($a,$b);

The function C<$fn> will remain declared
on the Javascript side
until the bridge is torn down.

If you expect an array to be returned and want the array
to be fetched as list, pass C<'list'> as the C<$context>.
This is slightly more efficient than passing an array reference
to Perl and fetching the single elements from Perl.

=cut

sub declare {
    my ($self,$js,$context) = @_;
    if (! $self->{functions}->{$js}) {
        $self->{functions}->{$js} = $self->expr("var f=$js;\n;f");
        # Weaken the backlink of the function
        my $res = $self->{functions}->{$js};
        my $ref = ref $res;
        bless $res, "$ref\::HashAccess";
        weaken $res->{bridge};
        $res->{return_context} = $context;
        bless $res => $ref;
    };
    $self->{functions}->{$js}
};

sub link_ids {
    my $self = shift;
    map {
        $_ ? MozRepl::RemoteObject::Instance->new( $self, $_ )
           : undef
    } @_
}

=head2 C<< $bridge->constant( $NAME ) >>

    my $i = $bridge->constant( 'Components.interfaces.nsIWebProgressListener.STATE_STOP' );

Fetches and caches a Javascript constant. If you use this to fetch
and cache Javascript objects, this will create memory leaks, as these objects
will not get released.

=cut

sub constant {
    my ($self, $name) = @_;
    if (! exists $self->{constants}->{$name}) {
        $self->{constants}->{$name} = $self->expr($name);
        if (ref $self->{constants}->{$name}) {
            #warn "*** $name is an object.";
            # Need to weaken the backlink of the constant-object
            my $res = $self->{constants}->{$name};
            my $ref = ref $res;
            bless $res, "$ref\::HashAccess";
            weaken $res->{bridge};
            bless $res => $ref;
        };
    };
    $self->{constants}->{ $name }
};

=head2 C<< $bridge->appinfo() >>

Returns the C<nsIXULAppInfo> object
so you can inspect what application
the bridge is connected to:

    my $info = $bridge->appinfo();
    print $info->{name}, "\n";
    print $info->{version}, "\n";
    print $info->{ID}, "\n";

=cut

sub appinfo {
    $_[0]->expr(<<'JS');
    Components.classes["@mozilla.org/xre/app-info;1"]
        .getService(Components.interfaces.nsIXULAppInfo);
JS
};

=head2 C<< $bridge->js_call_to_perl_struct( $js, $context ) >>

Takes a scalar with JS code, executes it, and returns
the result as a Perl structure.

This will not (yet?) cope with objects on the remote side, so you
will need to make sure to call C<< $rn.link() >> on all objects
that are to persist across the bridge.

This is a very low level method. You are better advised to use
C<< $bridge->expr() >> as that will know
to properly wrap objects but leave other values alone.

C<$context> is passed through and tells the Javascript side
whether to return arrays as objects or as lists. Pass
C<list> if you want a list of results instead of a reference
to a Javascript C<array> object.

=cut

sub repl_API {
    my ($self,$call,@args) = @_;
    return sprintf q<%s.%s(%s);>, $self->repl->repl, $call, join ",", map { $self->json->encode($_) } @args;
};

sub js_call_to_perl_struct {
    my ($self,$js,$context) = @_;
    $context ||= '';
    $self->{stats}->{roundtrip}++;
    my $repl = $self->repl;
    if (! $repl) {
        # Likely during global destruction
        return
    };
    my $queue = join '',
                     map( { /;$/? $_ : "$_;" } map { s/\s*$//; $_ } @{ $self->queue });

    @{ $self->queue } = ();

    #warn "<<$js>>";
    my @js;
    if ($queue) {
        push @js, $self->repl_API('q', $queue);
    };
    push @js, $self->repl_API('ejs', $js, $context );
    $js = join ";", @js;

    if (defined wantarray) {
        #warn $js;
        # When going async, we would want to turn this into a callback
        my $res = $self->execute_command($js);
        $res =~ s/^(?:\.+\>\s+)+//g;
        my $i=0;
        while ($res !~ /\S/) {
            # Gobble up continuation prompts
            warn "No result yet from repl";
            $res = $self->execute_command(";"); # no-op
            $res =~ s/^(?:\.+\>\s+)+//g;
            $i++;
            last if ($i == 25);
        };
        my $d = $self->to_perl($res);
        if ($d->{status} eq 'ok') {
            return $d->{result}
        } else {
            no warnings 'uninitialized';
            croak ((ref $self).": $d->{name}: $d->{message}");
        };
    } else {
        #warn "Executing $js";
        # When going async, we would want to turn this into a callback
        # This produces additional, bogus prompts...
        $self->execute_command($js);
        ()
    };
};

sub repl {$_[0]->{repl}};
sub command_sep {$_[0]->{command_sep}};
sub json {$_[0]->{json}};
sub name {$_[0]->{repl}?$_[0]->{repl}->repl:undef};
sub queue {$_[0]->{queue}};

sub make_callback {
    my ($self,$cb) = @_;
    my $cbid = refaddr $cb;
    my $makeCatchEvent = $self->declare(<<'JS');
    function(repl,id) {
        return repl.makeCatchEvent(id);
    };
JS
    my $res = $makeCatchEvent->($self,$cbid);
    croak "Couldn't create a callback"
        if (! $res);

    # Need to weaken the backlink of the constant-object
    my $ref = ref $res;
    bless $res, "$ref\::HashAccess";
    weaken $res->{bridge};
    bless $res => $ref;

    $self->{callbacks}->{$cbid} = {
        callback => $cb, jsproxy => $res, where => [caller(1)],
    };
    $res
};

sub dispatch_callback {
    my ($self,$info) = @_;
    my $cbid = $info->{cbid};
    if (! $cbid) {
        croak "Unknown callback fired with values @{ $info->{ args }}";
    };
    if (exists $self->{callbacks}->{$cbid} and my $cb = $self->{callbacks}->{$cbid}->{callback}) {
        # Replace with goto &$cb ?
        my @args = as_list $info->{args};
        $cb->(@args);
    } else {
        #warn "Unknown callback id $cbid (created in @{$self->{removed_callbacks}->{$cbid}->{where}})";
    }
};

=head2 C<< $bridge->remove_callback( $callback ) >>

    my $onload = sub {
        ...
    };
    $js_object->{ onload } = $onload;
    $bridge->remove_callback( $onload )

If you want to remove a callback that you instated,
this is the way.

This will release the resources associated with the callback
on both sides of the bridge.

=cut

sub remove_callback {
    my ($self,@callbacks) = @_;
    for my $cb (@callbacks) {
        my $cbid = refaddr $cb;
        $self->{removed_callbacks}->{$cbid} = $self->{callbacks}->{$cbid}->{where};
        delete $self->{callbacks}->{$cbid};
        # and if you don't have memory cycles, all will be fine
    };
};

=head2 C<< $bridge->poll >>

A crude no-op that can be used to just look if new events have arrived.

=cut

sub poll {
    $_[0]->expr('1==1');
};

package # hide from CPAN
    MozRepl::RemoteObject::Instance;
use strict;
use Carp qw(croak);
use Scalar::Util qw(blessed refaddr);
use MozRepl::RemoteObject::Methods;
use vars qw(@CARP_NOT);
@CARP_NOT = 'MozRepl::RemoteObject::Methods';

use overload '%{}' => 'MozRepl::RemoteObject::Methods::as_hash',
             '@{}' => 'MozRepl::RemoteObject::Methods::as_array',
             '&{}' => 'MozRepl::RemoteObject::Methods::as_code',
             '=='  => 'MozRepl::RemoteObject::Methods::object_identity',
             '""'  => sub { overload::StrVal $_[0] };

#sub TO_JSON {
#    sprintf "%s.getLink(%d)", $_[0]->bridge->name, $_[0]->__id
#};

=head1 HASH access

All MozRepl::RemoteObject objects implement
transparent hash access through overloading, which means
that accessing C<< $document->{body} >> will return
the wrapped C<< document.body >> object.

This is usually what you want when working with Javascript
objects from Perl.

Setting hash keys will try to set the respective property
in the Javascript object, but always as a string value,
numerical values are not supported.

=head1 ARRAY access

Accessing an object as an array will mainly work. For
determining the C<length>, it is assumed that the
object has a C<.length> method. If the method has
a different name, you will have to access the object
as a hash with the index as the key.

Note that C<push> expects the underlying object
to have a C<.push()> Javascript method, and C<pop>
gets mapped to the C<.pop()> Javascript method.

=cut

=head1 OBJECT IDENTITY

Object identity is currently implemented by
overloading the C<==> operator.
Two objects are considered identical
if the javascript C<===> operator
returns true.

  my $obj_a = MozRepl::RemoteObject->expr('window.document');
  print $obj_a->__id(),"\n"; # 42
  my $obj_b = MozRepl::RemoteObject->expr('window.document');
  print $obj_b->__id(), "\n"; #43
  print $obj_a == $obj_b; # true

=head1 CALLING METHODS

Calling methods on a Javascript object is supported.

All arguments will be autoquoted if they contain anything
other than ASCII digits (C<< [0-9] >>). There currently
is no way to specify that you want an all-digit parameter
to be put in between double quotes.

Passing MozRepl::RemoteObject objects as parameters in Perl
passes the proxied Javascript object as parameter to the Javascript method.

As in Javascript, functions are first class objects, the following
two methods of calling a function are equivalent:

  $window->loadURI('http://search.cpan.org/');

  $window->{loadURI}->('http://search.cpan.org/');

=cut

sub AUTOLOAD {
    my $fn = $MozRepl::RemoteObject::Instance::AUTOLOAD;
    $fn =~ s/.*:://;
    my $self = shift;
    return $self->MozRepl::RemoteObject::Methods::invoke($fn,@_)
}

=head1 EVENTS / CALLBACKS

This module also implements a rudimentary asynchronous
event dispatch mechanism. Basically, it allows you
to write code like this and it will work:

  $window->addEventListener('load', sub {
       my ($event) = @_;
       print "I got a " . $event->{type} . " event\n";
       print "on " . $event->{originalTarget};
  });
  # do other things...

Note that you cannot block the execution of Javascript that way.
The Javascript code has long continued running when you receive
the event.

Currently, only busy-waiting is implemented and there is no
way yet for Javascript to tell Perl it has something to say.
So in absence of a real mainloop, you have to call

  $repl->poll;

from time to time to look for new events. Note that I<any>
call to Javascript will carry all events back to Perl and trigger
the handlers there, so you only need to use poll if no other
activity happens.


In the long run,
a move to L<AnyEvent> would make more sense, but currently,
MozRepl::RemoteObject is still under heavy development on
many fronts so that has been postponed.

=head1 OBJECT METHODS

These methods are considered to be internal. You usually
do not want to call them from your code. They are
documented here for the rare case you might need to use them directly
instead of treating the objects as Perl structures. The
official way to access these functions is by using
L<MozRepl::RemoteObject::Methods> instead.

=head2 C<< $obj->__invoke(METHOD, ARGS) >>

The C<< ->__invoke() >> object method is an alternate way to
invoke Javascript methods. It is normally equivalent to
C<< $obj->$method(@ARGS) >>. This function must be used if the
METHOD name contains characters not valid in a Perl variable name
(like foreign language characters).
To invoke a Javascript objects native C<< __invoke >> method (if such a
thing exists), please use:

    $object->MozRepl::RemoteObject::Methods::invoke::invoke('__invoke', @args);

The same method can be used to call the Javascript functions with the
same name as other convenience methods implemented
by this package:

    __attr
    __setAttr
    __xpath
    __click
    ...

=cut

*__invoke = \&MozRepl::RemoteObject::Methods::invoke;

=head2 C<< $obj->__transform_arguments(@args) >>

This method transforms the passed in arguments to their JSON string
representations.

Things that match C< /^(?:[1-9][0-9]*|0+)$/ > get passed through.

MozRepl::RemoteObject::Instance instances
are transformed into strings that resolve to their
Javascript global variables. Use the C<< ->expr >> method
to get an object representing these.

It's also impossible to pass a negative or fractional number
as a number through to Javascript, or to pass digits as a Javascript string.

=cut

*__transform_arguments = \&MozRepl::RemoteObject::Methods::transform_arguments;

=head2 C<< $obj->__id >>

Readonly accessor for the internal object id
that connects the Javascript object to the
Perl object.

=cut

*__id = \&MozRepl::RemoteObject::Methods::id;

=head2 C<< $obj->__on_destroy >>

Accessor for the callback
that gets invoked from C<< DESTROY >>.

=cut

*__on_destroy = \&MozRepl::RemoteObject::Methods::on_destroy;

=head2 C<< $obj->bridge >>

Readonly accessor for the bridge
that connects the Javascript object to the
Perl object.

=cut

*bridge =
*bridge =
\&MozRepl::RemoteObject::Methods::bridge;

=head2 C<< $obj->__release_action >>

Accessor for Javascript code that gets executed
when the Perl object gets released.

=cut

sub __release_action {
    my $class = ref $_[0];
    bless $_[0], "$class\::HashAccess";
    if (2 == @_) {
        $_[0]->{release_action} = $_[1];
    };
    my $release_action = $_[0]->{release_action};
    bless $_[0], $class;
    $release_action
};

sub DESTROY {
    my $self = shift;
    local $@;
    my $id = $self->__id();
    return unless $self->__id();
    my $release_action;
    if ($release_action = ($self->__release_action || '')) {
        $release_action =~ s/\s+$//mg;
        $release_action = join '',
            'var self = repl.getLink(id);',
            $release_action,
            ';self = null;',
        ;
    };
    if (my $on_destroy = $self->__on_destroy) {
        #warn "Calling on_destroy";
        $on_destroy->($self);
    };
    if ($self->bridge) { # not always there during global destruction
        my $rn = $self->bridge->name;
        if ($rn) { # not always there during global destruction
            # we don't want a result here!
            $self->bridge->exprq(<<JS);
(function(repl,id){${release_action}repl.breakLink(id)})($rn,$id)
JS
        } else {
            warn "Repl '$rn' has gone away already";
        };
        1
    } else {
        if ($MozRepl::RemoteObject::WARN_ON_LEAKS) {
            warn "Can't release JS part of object $self / $id ($release_action)";
        };
    };
}

=head2 C<< $obj->__attr( $attribute ) >>

Read-only accessor to read the property
of a Javascript object.

    $obj->__attr('foo')

is identical to

    $obj->{foo}

=cut

sub __attr {
    my ($self,$attr,$context) = @_;
    my $id = MozRepl::RemoteObject::Methods::id($self)
        or die "No id given";

    my $bridge = MozRepl::RemoteObject::Methods::bridge($self);
    $bridge->{stats}->{fetch}++;
    my $rn = $bridge->name;
    my $json = $bridge->json;
    $attr = $json->encode($attr);
    return $bridge->unjson(<<JS,$context);
$rn.getAttr($id,$attr)
JS
}

=head2 C<< $obj->__setAttr( $attribute, $value ) >>

Write accessor to set a property of a Javascript
object.

    $obj->__setAttr('foo', 'bar')

is identical to

    $obj->{foo} = 'bar'

=cut

sub __setAttr {
    my ($self,$attr,$value) = @_;
    my $id = MozRepl::RemoteObject::Methods::id($self)
        or die "No id given";
    my $bridge = $self->bridge;
    $bridge->{stats}->{store}++;
    my $rn = $bridge->name;
    my $json = $bridge->json;
    $attr = $json->encode($attr);
    ($value) = $self->__transform_arguments($value);
    $self->bridge->js_call_to_perl_struct(<<JS);
$rn.getLink($id)[$attr]=$value
JS
}

=head2 C<< $obj->__dive( @PATH ) >>

B<DEPRECATED> - this method will vanish somewhere after 0.23.
Use L<MozRepl::RemoteObject::Methods::dive> instead.

Convenience method to quickly dive down a property chain.

If any element on the path is missing, the method dies
with the error message which element was not found.

This method is faster than descending through the object
forest with Perl, but otherwise identical.

  my $obj = $tab->{linkedBrowser}
                ->{contentWindow}
                ->{document}
                ->{body}

  my $obj = $tab->__dive(qw(linkedBrowser contentWindow document body));

=cut

*__dive = \&MozRepl::RemoteObject::Methods::dive;

=head2 C<< $obj->__keys() >>

Please use instead:

    keys %$obj

The function returns the names of all properties
of the javascript object as a list, just like the C<keys>
Perl function.

  $obj->__keys()

is identical to

  keys %$obj

=cut

sub __keys { # or rather, __properties
    my ($self,$attr) = @_;
    die unless $self;

    # We do not want to rely on the object actually supporting
    # .hasOwnProperty, so we support both, it having .hasOwnProperty
    # and using Object.hasOwnProperty
    my $getKeys = $self->bridge->declare(<<'JS', 'list');
    function(obj){
        var res = [];
        var hop = // obj.hasOwnProperty
                  Object.hasOwnProperty
                  ;
        for (var el in obj) {
            if (hop.apply(obj, [el])){
                res.push(el);
            };
        }
        return res
    }
JS
    return $getKeys->($self)
}

=head2 C<< $obj->__values() >>

Please use instead:

    values %$obj

Returns the values of all properties
as a list.

  $obj->values()

is identical to

  values %$obj

=cut

sub __values { # or rather, __properties
    my ($self,$attr) = @_;
    die unless $self;
    my $getValues = $self->bridge->declare(<<'JS','list');
    function(obj){
        var res = [];
        for (var el in obj) {
            res.push(obj[el]);
        }
        return res
    }
JS
    return $getValues->($self);
}

=head2 C<< $obj->__xpath( $query [, $ref ] ) >>

B<DEPRECATED> - this method will vanish somewhere after 0.23.
Use L<MozRepl::RemoteObject::Methods::xpath> instead:

  $obj->MozRepl::RemoteObject::Methods::xpath( $query )

Executes an XPath query and returns the node
snapshot result as a list.

This is a convenience method that should only be called
on HTMLdocument nodes.

The optional C<$ref> parameter can be a DOM node relative to which a
relative XPath expression will be evaluated. It defaults to C<undef>.

The optional C<$cont> parameter can be a Javascript function that
will get applied to every result. This can be used to directly map
each DOM node in the XPath result to an attribute. For example
for efficiently fetching the text value of an XPath query resulting in
textnodes, the two snippets are equivalent, but the latter executes
less roundtrips between Perl and Javascript:

    my @text = map { $_->{nodeValue} }
        $obj->MozRepl::RemoteObject::Methods::xpath( '//p/text()' )


    my $fetch_nodeValue = $bridge->declare(<<JS);
        function (e){ return e.nodeValue }
    JS
    my @text = map { $_->{nodeValue} }
        $obj->MozRepl::RemoteObject::Methods::xpath( '//p/text()', undef, $fetch_nodeValue )

=cut

*__xpath = \&MozRepl::RemoteObject::Methods::xpath;

=head2 C<< $obj->__click >>

Sends a Javascript C<click> event to the object.

This is a convenience method that should only be called
on HTMLdocument nodes or their children.

=cut

sub __click {
    my ($self, @args) = @_; # $self is a HTMLdocument or a descendant!
    $self->__event('click', @args);
}

=head2 C<< $obj->__change >>

Sends a Javascript C<change> event to the object.

This is a convenience method that should only be called
on HTMLdocument nodes or their children.

=cut

sub __change {
    my ($self) = @_; # $self is a HTMLdocument or a descendant!
    $self->__event('change');
}

=head2 C<< $obj->__event TYPE >>

Sends a Javascript event of type C<TYPE> to the object.

This is a convenience method that should only be called
on HTMLdocument nodes or their children.

=head3 Send a C<focus>, C<change> and C<blur> event to an element

The following code simulates the events sent by the
user entering a value into a field:

  $elt->__event('focus');
  $elt->{value} = 'Hello';
  $elt->__event('change');
  $elt->__event('blur');

=cut

sub __event {
    my ($self,$type,@args) = @_;
    my $fn;
    if ($type eq 'click') {
        $fn = $self->bridge->declare(<<'JS');
        function(target,name,x,y) {
            if(!x) x= 0;
            if(!y) y= 0;
            var r= target.getBoundingClientRect();
            x+= r.left;
            y+= r.top;
            var d= target.ownerDocument;
            var container= d.defaultView || window;
            var event = d.createEvent('MouseEvents');
            event.initMouseEvent(name, true, true, container,
                                 null, 0, 0, x, y, false, false, false,
                                 false, 0, null);
            target.dispatchEvent(event);
        }
JS
    } else {
        $fn = $self->bridge->declare(<<'JS');
        function(target,name) {
        var event = target.ownerDocument.createEvent('Events');
        event.initEvent(name, true, true);
        target.dispatchEvent(event);
    }
JS
    };
    $fn->($self,$type,@args);
};

=head2 C<< MozRepl::RemoteObject::Instance->new( $bridge, $ID, $onDestroy ) >>

This creates a new Perl object that's linked to the
Javascript object C<ID>. You usually do not call this
directly but use C<< $bridge->link_ids @IDs >>
to wrap a list of Javascript ids with Perl objects.

The C<$onDestroy> parameter should contain a Javascript
string that will be executed when the Perl object is
released.
The Javascript string is executed in its own scope
container with the following variables defined:

=over 4

=item *

C<self> - the linked object

=item *

C<id> - the numerical Javascript object id of this object

=item *

C<repl> - the L<MozRepl> Javascript C<repl> object

=back

This method is useful if you want to automatically
close tabs or release other resources
when your Perl program exits.

=cut

sub new {
    my ($package,$bridge, $id,$release_action) = @_;
    #warn "Created object $id";
    my $self = {
        id => $id,
        bridge => $bridge,
        release_action => $release_action,
        stats => {
            roundtrip => 0,
            fetch => 0,
            store => 0,
            callback => 0,
        },
    };
    bless $self, ref $package || $package;
};

package # don't index this on CPAN
  MozRepl::RemoteObject::TiedHash;
use strict;

sub TIEHASH {
    my ($package,$impl) = @_;
    my $tied = { impl => $impl };
    bless $tied, $package;
};

sub FETCH {
    my ($tied,$k) = @_;
    my $obj = $tied->{impl};
    $obj->__attr($k)
};

sub STORE {
    my ($tied,$k,$val) = @_;
    my $obj = $tied->{impl};
    $obj->__setAttr($k,$val);
    () # force __setAttr to return nothing
};

sub FIRSTKEY {
    my ($tied) = @_;
    my $obj = $tied->{impl};
    $tied->{__keys} ||= [$tied->{impl}->__keys()];
    $tied->{__keyidx} = 0;
    $tied->{__keys}->[ $tied->{__keyidx}++ ];
};

sub NEXTKEY {
    my ($tied,$lastkey) = @_;
    my $obj = $tied->{impl};
    $tied->{__keys}->[ $tied->{__keyidx}++ ];
};

sub EXISTS {
    my ($tied,$key) = @_;
    my $obj = $tied->{impl};
    my $exists = $obj->bridge->declare(<<'JS');
    function(elt,prop) {
        return (prop in elt && elt.hasOwnProperty(prop))
    }
JS
    $exists->($obj,$key);
}

sub DELETE {
    my ($tied,$key) = @_;
    my $obj = $tied->{impl};
    my $delete = $obj->bridge->declare(<<'JS');
    function(elt,prop) {
        var r=elt[prop];
        delete elt[prop];
        return r
    }
JS
    $delete->($obj,$key);
}

sub CLEAR  {
    my ($tied,$key) = @_;
    my $obj = $tied->{impl};
    my $clear = $obj->bridge->declare(<<'JS');
    function(obj) {
        var del = [];
        for (var prop in obj) {
            if (obj.hasOwnProperty(prop)) {
                del.push(prop);
            };
        };
        for (var i=0;i<del.length;i++) {
            delete obj[del[i]]
        };
        return del
    }
JS
    $clear->($obj);
};

1;

package # don't index this on CPAN
  MozRepl::RemoteObject::TiedArray;
use strict;

sub TIEARRAY {
    my ($package,$impl) = @_;
    my $tied = { impl => $impl };
    bless $tied, $package;
};

sub FETCHSIZE {
    my ($tied) = @_;
    my $obj = $tied->{impl};
    $obj->{length};
}

sub FETCH {
    my ($tied,$k) = @_;
    my $obj = $tied->{impl};
    $obj->__attr($k)
};

sub STORE {
    my ($tied,$k,$val) = @_;
    my $obj = $tied->{impl};
    $obj->__setAttr($k,$val);
    (); # force void context on __setAttr
};

sub PUSH {
    my $tied = shift;
    my $obj = $tied->{impl};
    for (@_) {
        $obj->push($_);
    };
};

sub POP {
    my $tied = shift;
    my $obj = $tied->{impl};
    $obj->pop();
};

sub SPLICE {
    my ($tied,$from,$count) = (shift,shift,shift);
    my $obj = $tied->{impl};
    $from ||= 0;
    $count ||= $obj->{length};
    MozRepl::RemoteObject::as_list $obj->splice($from,$count,@_);
};

sub CLEAR {
    my $tied = shift;
    my $obj = $tied->{impl};
    $obj->splice(0,$obj->{length});
    ()
};

sub EXTEND {
    # we acknowledge the advice
};

1;

__END__

=head1 ENCODING

The communication with the MozRepl plugin is done
through 7bit safe ASCII. The received bytes are supposed
to be UTF-8, but this seems not always to be the case,
so the JSON encoder on the Javascript side also
uses a 7bit safe encoding.

Currently there is no way to specify a different encoding
on the fly. You have to replace or reconfigure
the JSON object in the constructor.

=head1 TODO

=over 4

=item *

For tests that connect to the outside world,
check/ask whether we're allowed to. If running
automated, skip.

=item *

Think more about how to handle object identity.
Should C<Scalar::Util::refaddr> return true whenever
the Javascript C<===> operator returns true?

Also see L<https://perlmonks.org/?node_id=802912>

=item *

Consider whether MozRepl actually always delivers
UTF-8 as output.

=item *

Properly encode all output that gets send towards
L<MozRepl> into the proper encoding.

=item *

Can we find a sensible implementation of string
overloading for JS objects? Should it be the
respective JS object type?

=item *

Add truely lazy objects that don't allocate their JS counterparts
until an C<< __attr() >> is requested or a method call is made.

This is an optimization and hence gets postponed.

=item *

Potentially do away with attaching to the repl object and keep
all elements as anonymous functions referenced only by Perl variables.

This would have the advantage of centralizing the value wrapping/unwrapping
in one place, C<__invoke>, and possibly also in C<__as_code>. It would
also keep the precompiled JS around instead of recompiling it on
every access.

C<repl.wrapResults> would have to be handed around in an interesting
manner then though.

=item *

Add proper event wrappers and find a mechanism to send such events.

Having C<< __click() >> is less than desireable. Maybe blindly adding
the C<< click() >> method is preferrable.

=item *

Implement fetching of more than one property at once through __attr()

=item *

Implement automatic reblessing of JS objects into Perl objects
based on a typemap instead of blessing everything into
MozRepl::RemoteObject::Instance.

=item *

Find out how to make MozRepl actively send responses instead
of polling for changes.

This would lead to implementing a full two-way message bus.

C<repl.print()> can create arbitrary output, but L<Net::Telnet>
is not prepared to consume it.

On the Javascript side, C<yield> can be used to implement
continuations in a way that could maybe allow us to "suspend" the currently
executing Javascript callback to introduce synchronous callbacks from
Javascript into Perl.

=item *

Consider using/supporting L<AnyEvent> for better compatibility
with other mainloops.

This would lead to implementing a full two-way message bus.

=item *

Should I make room for promises as well?

  my ($foo,$bar);
  $bridge->transaction(sub {
      $foo = $obj->promise;
      $bar = $obj2->promise;
  });

The JS could instantiate another level of proxy objects
that would have to get filled by a batch of JS statements
sent from Perl to fill in all those promises.

  $bridge->promise( 'window' )
  could return
  sub { $bridge->expr('window') }

but that wouldn't allow for coalescing these promises into Javascript.

=item *

Create synchronous Javascript callbacks by blocking
the current FireFox thread. This shouldn't block the
rest of FireFox:

      /**
       * Netscape compatible WaitForDelay function.
       * You can use it as an alternative to Thread.Sleep() in any major programming language
       * that support it while JavaScript it self doesn't have any built-in function to do such a thing.
       * parameters:
       * (Number) delay in millisecond
      */
      function nsWaitForDelay(delay) {
          /**
            * Just uncomment this code if you're building an extention for Firefox.
            * Since FF3, we'll have to ask for user permission to execute XPCOM objects.
            */
          // netscape.security.PrivilegeManager.enablePrivilege("UniversalXPConnect");

          // Get the current thread.
          var thread = Components.classes["@mozilla.org/thread-manager;1"].getService(Components.interfaces.nsIThreadManager).currentThread;

          // Create an inner property to be used later as a notifier.
          this.delayed = true;

          /* Call JavaScript setTimeout function
            * to execute this.delayed = false
            * after it finish.
            */
          setTimeout("this.delayed = false;", delay);

          /**
            * Keep looping until this.delayed = false
            */
          while (this.delayed) {
          /**
            * This code will not freeze your browser as it's documented in here:
            * https://developer.mozilla.org/en/Code_snippets/Threads#Waiting_for_a_background_task_to_complete
            */
          thread.processNextEvent(true);
          }
      }

=back

=head1 SEE ALSO

L<Win32::OLE> for another implementation of proxy objects

L<https://wiki.github.com/bard/mozrepl> - the MozRepl
FireFox plugin homepage

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/mozrepl-remoteobject>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2009-2012 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
