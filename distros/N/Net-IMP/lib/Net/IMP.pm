use strict;
use warnings;

package Net::IMP;
our $VERSION = '0.633';

use Carp 'croak';
use Scalar::Util 'dualvar';

# map set_debug into local namespace for convinience, so that one
# can call Net::IMP->set_debug instead of Net::IMP::Debug->set_debug
use Net::IMP::Debug 'set_debug';

use Exporter 'import';
our @EXPORT = qw(
    IMP_PASS
    IMP_PASS_PATTERN
    IMP_PREPASS
    IMP_DENY
    IMP_DROP
    IMP_TOSENDER
    IMP_REPLACE
    IMP_REPLACE_LATER
    IMP_PAUSE
    IMP_CONTINUE
    IMP_LOG
    IMP_PORT_OPEN
    IMP_PORT_CLOSE
    IMP_ACCTFIELD
    IMP_FATAL
    IMP_MAXOFFSET
    IMP_DATA_STREAM
    IMP_DATA_PACKET
);

my @log_levels = qw(
    IMP_LOG_DEBUG
    IMP_LOG_INFO
    IMP_LOG_NOTICE
    IMP_LOG_WARNING
    IMP_LOG_ERR
    IMP_LOG_CRIT
    IMP_LOG_ALERT
    IMP_LOG_EMERG
);
our @EXPORT_OK = (@log_levels, 'IMP_DATA','IMP_DATA_TYPES', 'IMP_PASS_IF_BUSY');
our %EXPORT_TAGS = ( log => \@log_levels );

# data types/protocols
# These two are the basic types, more application specific types might
# be defined somewhere else and be mapped to a number within supported_dtypes.
# The only important thing is, that streaming data should be <0, while
# packetized data (like HTTP header or UDP datagrams) should be > 0
# If no explicit type is given in sub data, it will assume IMP_DATA_STREAM.
use constant IMP_DATA_STREAM  => dualvar(-1,'imp.data.stream');
use constant IMP_DATA_PACKET  => dualvar(+1,'imp.data.packet');


# the numerical order of the constants describes priority when
# cascading modules, e.g. replacement has a higher value then
# pass and gets thus forwarded as the cause for the data

### information only
use constant IMP_LOG          => dualvar(0x0001,"log");
use constant IMP_PORT_OPEN    => dualvar(0x0002,"port_open");
use constant IMP_PORT_CLOSE   => dualvar(0x0003,"port_close");
use constant IMP_ACCTFIELD    => dualvar(0x0004,"acctfield");
### flow control
use constant IMP_PAUSE        => dualvar(0x0010,"pause");
use constant IMP_CONTINUE     => dualvar(0x0011,"continue");
use constant IMP_REPLACE_LATER  => dualvar(0x0012,"replace_later");
### keep data
use constant IMP_PASS         => dualvar(0x1001,"pass");
use constant IMP_PASS_PATTERN => dualvar(0x1002,"pass_pattern");
use constant IMP_PREPASS      => dualvar(0x1003,"prepass");
### change data
use constant IMP_TOSENDER     => dualvar(0x1010,"tosender");
use constant IMP_REPLACE      => dualvar(0x1011,"replace");
### affect whole connection
use constant IMP_DENY         => dualvar(0x1100,"deny");
use constant IMP_DROP         => dualvar(0x1101,"drop");
use constant IMP_FATAL        => dualvar(0x1102,"fatal");

# these return values still get sent if the data provider is busy
# the most important are on top
use constant IMP_PASS_IF_BUSY => [
    IMP_FATAL,
    IMP_DENY,
    IMP_DROP,
    IMP_PAUSE,
    IMP_CONTINUE,
    IMP_ACCTFIELD
];


# marker for (pre)pass to Infinite for IMP_PASS, IMP_PREPASS
use constant IMP_MAXOFFSET    => -1;

# log levels for IMP_LOG
# these are modeled analog to syslog levels
use constant IMP_LOG_DEBUG    => dualvar(1,'debug');
use constant IMP_LOG_INFO     => dualvar(2,'info');
use constant IMP_LOG_NOTICE   => dualvar(3,'notice');
use constant IMP_LOG_WARNING  => dualvar(4,'warning');
use constant IMP_LOG_ERR      => dualvar(5,'error');
use constant IMP_LOG_CRIT     => dualvar(6,'critical');
use constant IMP_LOG_ALERT    => dualvar(7,'alert');
use constant IMP_LOG_EMERG    => dualvar(8,'emergency');


# helper function to define new IMP_DATA_* types for protocols
{
    my @dualvars = ( IMP_DATA_STREAM, IMP_DATA_PACKET );
    sub IMP_DATA_TYPES { return @dualvars }

    my %atoi = map {( "$_" => $_+0 )} @dualvars;
    my %itoa = map {( $_+0 => "$_" )} @dualvars;

    # $basename - name which gets used in constant name, e.g. 'http' makes
    # IMP_DATA_HTTP_..... Best would be name of IP service.
    # - if name[number] will use number as base type number
    # - if name[other_name+number] will base types on already defined
    #   types with number added as offset
    # - if no number given it will use port name from getservbyname,
    #   multiplied with 0x10000 and die if no such service is defined
    # @def: list of defname => [+-]offset which will result in a definition
    # of IMP_DATA_BASENAME_DEFNAME => [+-](base+offset), e.g. '+' for packet
    # types and '-' for stream types
    sub IMP_DATA {
	my ($basename,@def) = @_;
	my $basenum;
	if ( $basename =~s{\[(?:(\w+)\+)?(\d+)\]$}{} ) {
	    (my $base,$basenum) = ($1,$2);
	    if ( $base ) {
		my $offset = $atoi{$base}
		    or croak("cannot find base type $base");
		$basenum += $offset;
	    }
	} else {
	    $basenum = getservbyname($basename,'tcp' )
		|| getservbyname($basename,'udp' )
		or croak("cannot determine id for $basename");
	    $basenum = $basenum << 16;
	}

	my @const;

	my $pkg = caller;
	unshift(@def,'',0);
	while (@def) {
	    my $name = shift(@def);
	    my $diff = shift(@def);
	    my $lname = $name ne '' ? "$basename.$name" : $basename;
	    croak("$lname already defined") if exists $atoi{$lname};
	    my $lnum  = $diff>=0 ? $basenum + $diff : -$basenum+$diff;
	    if ( my $s = $itoa{$lnum} || $itoa{-$lnum} ) {
		croak("id $lnum alreday used for $s");
	    }
	    $atoi{$lname} = $lnum;
	    $itoa{$lnum} = $lname;

	    my $string = "imp.data.$lname";
	    ( my $const = uc($string) )=~s{\.}{_}g;
	    push @const,$const;

	    no strict 'refs';
	    my $var = dualvar($lnum,$string);
	    *{ "${pkg}::$const" } = sub () { $var };
	    push @dualvars, $var;
	}

	return @const;
    }

}


1;

__END__

=head1 NAME

Net::IMP - Inspection and Modification Protocol

=head1 SYNOPSIS

    ######################################################################
    # implementation of plugin
    ######################################################################

    package myIMP_Plugin;
    use base 'Net::IMP::Base';
    use Net::IMP;

    # plugin global methods
    # -------------------------------------------------------------------

    sub cfg2str { ... }       # create $string from %config
    sub str2cfg { ... }       # create %config from $string
    sub validate_cfg { ... }  # validate %config

    sub new_factory {         # creates factory object
	my ($class,%factory_args) = @_;
	...
	return $factory;
    }

    # factory specific methods and calls
    # -------------------------------------------------------------------

    # used in default implementation of method interface
    sub INTERFACE {
	[ undef, [ IMP_PREPASS, IMP_ACCTFIELD ]]
    };

    sub new_analyzer {        # creates analyzer from factory
	my ($factory,%analyzer_args) = @_;
	my $analyzer = $class->SUPER::new_analyzer( %analyzer_args );
	# maybe prepass everything forever in both directions
	$analyzer->add_results(
	    [ IMP_PREPASS, 0, IMP_MAXOFFSET ],  # for dir client->server
	    [ IMP_PREPASS, 1, IMP_MAXOFFSET ];  # for dir server->client
	);
	return $analyzer;
    }

    # analyzer specific methods
    # -------------------------------------------------------------------

    # new data for analysis, $offset should only be set if there are gaps
    # (e.g. when we PASSed data with offset in the future)
    sub data {
	my ($analyzer,$dir,$data,$offset,$datatype) = @_;
	...
    }

    ######################################################################
    # use of plugin
    ######################################################################
    package main;

    # check configuration, maybe use str2cfg to get config from string before
    if (my @err = myIMP_Plugin->validate_cfg(%config)) {
	die "@err"
    }

    # create single factory object for each configuration
    my $factory = myIMP_Plugin->new_factory(%config);

    # enforce the interface the data provider will use, e.g. the input
    # protocol/types and the supported output return types
    $factory = $factory->set_interface([
	IMP_DATA_STREAM,
	[ IMP_PASS, IMP_PREPASS, IMP_LOG ]
    ]) or die;

    # create analyzer object from factory for each new analysis (e.g. for
    # each connection)
    my $analyzer = $factory->new_analyzer(...);

    # set callback, which gets called on each result
    $analyzer->set_callback(\&imp_cb,$cb_arg);

    # feed analyzer with data
    $analyzer->data(0,'data from dir 0',0,IMP_DATA_STREAM);
    .... will call imp_cb as soon as results are there ...
    $analyzer->data(0,'',0,IMP_DATA_STREAM); # eof from dir 0

    # callback for results
    sub imp_cb {
	my $cb_arg = shift;
	for my $rv (@_) {
	    my $rtype = shift(@$rv);
	    if ( $rtype == IMP_PASS ) ...
	    ...
	}
    }

    ######################################################################
    # definition of new data type suites
    ######################################################################
    package Net::IMP::HTTP;
    use Net::IMP 'IMP_DATA';
    use Exporter 'import';
    our @EXPORT = IMP_DATA('http',
	'header' => +1,   # packet type
	'body'   => -2,   # streaming type
	...
    );

=head1 DESCRIPTION

IMP is a protocol for inspection, modification and rejection of data between
two sides (client and server) using an analyzer implementing this interface.

=head2 Basics

IMP is an asynchronous protocol, usually used together with callbacks.

=over 4

=item *

Using the C<data> method, the data provider (e.g. proxy, IDS,... ) feeds data
from its input streams (i.e. from client or from server) into the analyzer.

=item *

The analyzer processes the data and generates results.
It might be possible, that it needs more data before generating a result or
that it can only results for part of the data and needs more data for more
results.

Each result contains a result type.
Most results also contain direction of the input stream which caused the result
and the offset of this stream.
The offset is the position in the input stream, up to which data got used in
generating the result, e.g. a result of IMP_PASS means that data up to the
offset got used in the result and thus data up to this offset can be passed.

=item *

The results usually get propagated back to the data provider using a callback
set with C<set_callback>.
If no callback is set, the data provider must poll the results with the
C<poll_results> method.

=back

=head2 Usage of Terms

=over 4

=item Data Provider

The process that receives the input streams from client and server, feeds the
analyzer, processes the results from the analyzer and forwards the resulting
streams to server and client.
Typical examples are proxies or Intrusion Detection Systems (IDS).

=item Factory

The factory object is used to create analyzers with common properties.

=item Analyzer

The analyzer is the object which does the analysis of the data within a
specific context.
It will be created by the data provider for a new context by using the factory.

=item Context

The context is the environment where the analyzer executes.
E.g. when analyzing TCP connections, a new context is created for each TCP
connection, usually providing meta information about source and destination of
the connection.
Setup of the context is done by the data provider.

=item Interface

The interface consists of the data protocols/types (e.g. stream, packet,
http...) supported by the analyzer and the return types (IMP_PASS, IMP_PREPASS,
IMP_LOG, ...).

=back

=head2 Result Types

The results returned inside the callback or via C<poll_results> can be of the
following kind:

=over 4

=item [ IMP_PASS, $dir, $offset ]

Accept all data up to C<$offset> in the data stream for direction C<$dir>.

If C<$offset> specifies data which were not yet seen by the analyzer, these data
don't need to be forwarded to analyzer.
If they were still forwarded to the analyzer (because they were already on the
way, unstoppable) the analyzer just throws them away until C<$offset> is
reached.
This feature is useful for ignoring whole subcontexts (like MIME content based
on a C<Content-length> header).

A special case is a C<$offset> of IMP_MAXOFFSET, in this case the analyzer is
not interested in further information about the connection.
In other words, no more changes on input data will be done and an eof on the
input can be forwarded to the output. This interpretation is important, when an
IMP_REPLACE tries to replace nothing with data, e.g. to add data once eof is
detected etc.

=item [ IMP_PASS_PATTERN, $dir, $regex, $len ]

This is the same as IMP_PASS, except a pattern will be given instead of an
offset.
All data up to but not including the pattern don't need to be forwarded to the
analyzer.
Because C<$regex> might be complex the analyzer has to specify how many
octets the C<$regex> might match at most, so that the data provider can adjust
its buffer.

Because there might be data already on the way to the analyzer, the analyzer
needs to check all incoming data without explicit offset if they match the
pattern.
If it gets data with explicit offset, that means, that the pattern was matched
inside the client at the specified position.
In this case it should remove all data it got before (even if they included
offset already) and resync at the specified offset.

For better performance the analyzer should check any data it has already in the
buffer if they already contain the pattern.
In this case the issue can be dealt internally and there is no need to send
this reply to the data provider.

If the data provider receives this result, it should check all data it still
has in the buffer (e.g. which were not passed) whether they contain the
pattern.
If the data provider finds the pattern, it should call C<data> with an explicit
offset, so that the analyzer can resynchronize the position in the data
stream.

=item [ IMP_REPLACE, $dir, $offset, $data ]

Ignore the original data up to $offset, instead send C<$data>.
C<$offset> needs to be in the range of the data the analyzer got through
C<data> method, e.g. replacement of future data is not possible.
Neither is a replacement of already forwarded data possible, but C<$offset> can
be at the position of the last pass, replace etc to insert new data into the
data stream where before there was no data (typically at eof).

=item [ IMP_PREPASS, $dir, $offset ]

This is similar to IMP_PASS.
If <$offset> specifies data, which were already forwarded to the analyzer, they
get accepted.
If it specified not yet forwarded data, they get accepted also up to
C<$offset>, but contrary to IMP_PASS they get also forwarded to the analyzer.

Thus data can be forwarded before they get inspected, but they get inspected
nevertheless.
This might be known good data, but inspection is needed to maintain the state
or to log the data.

Or it might be potentially bad data, but a low latency is required and small
amounts of bad data are accepted.
In this case the window for bad data might be set small enough to allow high
latency while limiting impact of malicious data.
This can be done through continues updates of C<$offset>.

=item [ IMP_DENY, $dir, $reason, key1, value1,... ]

Deny any more data on this context.
If C<$reason> is given, it should be used to construct a message to the client.
After the reason extended information can be optionally added which should be 
interpreted by the data provider as key,value pairs (both strings).

Deny results by closing the context in a way visible to the client (e.g. closing
the connection with RST).

=item [ IMP_DROP ]

Deny any more data on this context and close the context.
The preferred way for closing the context is to be not visible to the client
(e.g just drop any more packets of an UDP connection).

=item [ IMP_FATAL, $reason ]

Fatal problem inside the analyzer.
While this will probably cause the analyzer to be destroyed and the connection
to be denied it is different from IMP_DROP or IMP_DENY in that it is not
triggered by the analyzed data, but by internals of the analyzer which make a
continuation of normal operations impossible.
All data providers must be able to deal with this return value.

=item [ IMP_TOSENDER, $dir, $data ]

Send data back to the sender.
This might be used to reject data, e.g. replace them with nothing and send
an error message back to the sender.
This can be useful to reject single commands in SMTP, FTP...

=item [ IMP_PAUSE,$dir ]

This is a hint to the data provider to stop feeding data for C<$dir> into the
analyzer until a matching C<IMP_CONTINUE> is received.
This should be used, if the analyzer has enough data to process, but the
processing will take some time (like with DNS lookups).
The data provider then might stop receiving data by itself.
While the data provider can ignore this result, feeding too much data into
the analyzer might result in out of memory situations.

=item [ IMP_CONTINUE,$dir ]

This signals the data provider, that the analyzer is able to process data
again, e.g. will be called after a matching C<IMP_PAUSE>.

=item [ IMP_REPLACE_LATER, $dir, $offset, $endoffset ]

This is a promise, that sometime later a replacement will be sent for the data
starting at C<$offset> and ending at C<$endoffset>. Based on this promise the
data provider might just forget the data and thus save memory.
Like with C<IMP_PAUSE> the data provider might ignore this return value.

=item [ IMP_LOG, $dir, $offset, $len, $level, $msg, key1, value1, ... ]

This contains a log message C<$msg> which is about data in direction C<$dir>
starting with C<$offset> and C<$len> octets long. After the message 
extended information can be optionally added which should be interpreted by the
data provider as key,value pairs (both strings).

C<$level> might specify a log level like debug, info, warn... .
C<$level> is one of LOG_IMP_*, which are similar to syslog levels,
e.g. IMP_LOG_DEBUG, IMP_LOG_INFO,...
These level constants can be imported with C<< use Net::IMP ':log' >>.

The data provider should just log the information in this case.

=item [ IMP_PORT_OPEN|IMP_PORT_CLOSE, $dir, $offset, ... ]

Some protocols like FTP, SIP, H.323 dynamically allocate ports.
These results detect when port allocation/destruction is done and should provide
enough information for the data provider to open/close the ports and track the
data through additional analyzers.

TODO: details will be specified when this feature is needed.

=item [ IMP_ACCTFIELD, $key, $value ]

This specifies a tuple which should be used for accounting (like name of
logfile, URL...)

=back

If there are multiple return values outstanding the data provider or the
analyzer might reorder the data, as long as the order is not changed within
types involving an offset, e.g. IMP_DENY or IMP_FATAL might be prefered
compared to IMP_PASS.

=head2 API Definition

The following API needs to be implemented by all IMP plugins.
C<$class>, C<$factory> and C<$analyzer>, as seen below, might be (objects of)
different classes, but don't need to.
The C<Net::IMP::Base> implementation uses the same class for plugin, factory and
analyzer.

=over 4

=item $class->str2cfg($string) => %config

This creates a config hash from a given string.
No verification of the config is done.

=item $class->cfg2str(%config) => $string

This creates a string from a config hash.
No verification of the config is done.

=item $class->validate_cfg(%config) -> @error

This validates the config and returns a list of errors.
Config is valid, if no errors are returned.

=item $class->new_factory(%args) => $factory

This creates a new factory object which is later used to create the analyzer.
C<%args> are used to describe the properties common for all analyzers created by
the same factory.

=item $factory->get_interface(@provider_if) => @plugin_if

This matches the interfaces supported by the factory with the
interfaces supported by the data provider.
Each interface consists of C<< [ $input_type, \@output_types ] >>, where

=over 8

=item $input_type

is either a single input data type (like IMP_DATA_STREAM, IMP_DATA_PACKET) or a
protocol type (like IMP_DATA_HTTP) which includes multiple data types.

=item @output_types

is a list of the result types, which are used by the interface, e.g. IMP_PASS,
IMP_LOG,... .
If \@output_types inside the data providers interface C<@provider_if> is not
given or if it is an empty list, it will be assumed, that the data provider
supports any result types for the given C<$input_type>.

=back

If called without arguments, e.g. with an empty C<@provider_if>, the method will
return all the interfaces supported by the factory.
Only in this case an interface description with no <$input_type>
might be returned, which means, that all data types are supported.

If called with a list of interfaces the data provider supports, it will return
the subset of these interfaces, which are also supported by the plugin.

=item $factory->set_interface($want_if) => $new_factory

This will return a factory object supporting the given interface.
This factory might be the same as the original factory, but might also be
a different factory, which translates data types.

If the interface is not supported it will return undef.

=item $factory->new_analyzer(%context) => $analyzer|undef

Creates a new analyzer object.
The details for C<%context> depend on the analyzed protocol and the requirements
of the analyzer, but usually these are things like source and destination ip
and port, URL, mime type etc.

With a key of C<cb> the callback can already be set here as
C<<[$code,@args]>> instead of later with C<set_callback>.

The factory might decide based on the given context information, that no
analysis is needed.
In this case it will return C<undef>, otherwise the new analyzer object.

=item $analyzer->set_callback($code,@args)

Sets or changes the callback of the analyzer object.
If results are outstanding, they might be delivered to this callback before
the method returns.

C<$code> is a coderef while C<@args> are additional user specified arguments
which should be used in the callback (typically object reference or similar).
The callback is called with C<< $code->(@args,@results) >> whenever new results
are available.

If $code is undef, an existing callback will be removed.

If no callback is given, the results need to be polled with C<poll_results>.

=item $analyzer->data($dir,$data,$offset,$type)

Forwards new data to the analyzer.
C<$dir> is the direction, e.g. 0 from client and 1 from server.
C<$data> is the data.
C<$data> of '' means end of data.

C<$offset> is the current position (octet) in the data stream.
It must be set to a value greater than 0 after data got omitted as a result of
PASS or PASS_PATTERN, so that the analyzer can resynchronize the internal
position value with the original position in the data stream.
In any other case it should be set to 0.

C<$type> is the type of the data.
There are two global data type definitions:

=over 4

=item IMP_DATA_STREAM (-1)

This is for generic streaming data, e.g. chunks from these datatypes can be
concatenated and analyzed together, parts can be replaced etc.

=item IMP_DATA_PACKET (+1)

This is for generic packetized data, where each chunk (e.g. call to C<data>)
contains a single packet, which should be analyzed as a separate entity.
This means no concatenating with previous or future chunks and no replacing of
only parts of the packet.

Also, any offsets given in calls to C<data> or in the results should be at
packet boundary (or IMP_MAX_OFFSET), at least for data modifications.
It will ignore (pre)pass which are not a packet boundary in the hope, that more
(pre)pass will follow.
A (pre)pass for some parts of a packet followed by a replacement is not allowed
and will probably cause an exception.

=back

All other data types are considered either subtypes of IMP_DATA_PACKET
(value >0) or of IMP_DATA_STREAM (value<0) and share their restrictions.
Also only streaming data of the same type can be concatenated and
analyzed together.

Results will be delivered through the callback or via C<poll_results>.

=item $analyzer->poll_results => @results

Returns outstanding results.
If a callback is attached, no results will be delivered this way.

=item $analyzer->busy($dir,0|1)

Reports to the analyzer if the data provider is busy and cannot process all
requests. This is usually the case, if the upstream cannot keep up with the
data, so sending gets stalled.
While the data provider is busy the analyzer might still send return values,
which might resolve the busy state, like IMP_DENY, IMP_FATAL etc

=item Net::IMP->set_debug

This is just a convenient way to call C<< Net::IMP::Debug->set_debug >>.
See L<Net::IMP::Debug> for more information.

=back

=head1 TODO

=over 4

=item * sample integration into relayd

=item * protocol to add remote analyzers

=item * add more return types like IMP_PORT_*

Specify IMP_PORT_* and have sample implementation which uses it.
Should be used to inform data provider, that inside that protocol it found
dynamic port allocations (like for FTP data streams or SIP RTP streams) and
that caller should track these connections too.

=back

=head2 Helper Functions

The function C<IMP_DATA> is provided to simplify definition of new data types,
for example:

    our @EXPORT = IMP_DATA('http',
	'header'  => +1,   # packet type
	'body'    => -2,   # streaming type
	...
    );
    push @EXPORT = IMP_DATA('httprq[http+10]',
	'header'  => +1,   # packet type
	'content' => -2,   # streaming type
	...
    );

This call of IMP_DATA is equivalent to the following perl declaration:

    use Scalar::Util 'dualvar';
    our @EXPORT = (
	'IMP_DATA_HTTP', 'IMP_DATA_HTTP_HEADER','IMP_DATA_HTTP_BODY',...
	'IMP_DATA_HTTPRQ', 'IMP_DATA_HTTPRQ_HEADER','IMP_DATA_HTTPRQ_BODY',...
    );

    # getservbyname('http','tcp') -> 80
    use constant IMP_DATA_HTTP
	=> dualvar(80 << 16,'imp.data.http');
    use constant IMP_DATA_HTTP_HEADER
	=> dualvar((80 << 16) + 1,'imp.data.http.header');
    use constant IMP_DATA_HTTP_BODY
	=> dualvar( -( (80 << 16) + 2 ), 'imp.data.http.body');
    ...
    use constant IMP_DATA_HTTPRQ
	=> dualvar((80 << 16) + 10,'imp.data.httprq');
    use constant IMP_DATA_HTTPRQ_HEADER
	=> dualvar((80 << 16) + 10 + 1,'imp.data.httprq.header');
    use constant IMP_DATA_HTTPRQ_CONTENT
	=> dualvar( -( (80 << 16) + 10 + 2 ),'imp.data.httprq.content');
    ...

The function C<IMP_DATA_TYPES> returns all known types, e.g. the primary types
C<IMP_DATA_STREAM> and C<IMP_DATA_PACKET> and all types created with IMP_DATA.

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

Thanks to everybody who helped with time, ideas, reviews or bug reports,
notably Alexander Bluhm and others at genua.de.

=head1 COPYRIGHT

Copyright 2012,2013 Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
