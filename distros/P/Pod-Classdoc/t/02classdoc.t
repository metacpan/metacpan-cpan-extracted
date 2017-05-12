#!/usr/bin/perl -w

# Formal testing for Pod::Classdoc

# This test script verifies Pod::Classdoc can properly process a
# hacked up version of DBI.pm with various combinations of options

use strict;
use warnings;

use Test::More tests => 10, no_diag => 1;
use Data::Dumper;
use Pod::Classdoc;
#
#	find location of the module we're using;
#	assumes test is being run from just above the t directory
#
my $file = 't/lib/DBI.pm';

mkdir 't/classdocs' unless -d 't/classdocs';

my $classdoc = Pod::Classdoc->new('t/somedocs', 'Classdocs for DBI', 1);
ok($classdoc && $classdoc->isa('Pod::Classdoc'), 'constructor');

is($classdoc->path(), 't/somedocs', 'get output path');

my $oldpath = $classdoc->path('t/classdocs');
ok(($oldpath eq 't/somedocs') && ($classdoc->path() eq 't/classdocs'), 'set output path');

$/ = undef;
open(INF, $file) or die "Can't open $file: $!";
my $txt = <INF>;
close INF;

my $doc = $classdoc->add($txt, $file);
ok(defined($doc) && $doc->isa('PPI::Document'), 'add');

if (1 == 0) {
is($classdoc->clear(), $classdoc, 'clear');

$doc = $classdoc->open($file);
ok(defined($doc) && $doc->isa('PPI::Document'), 'open');

$classdoc->clear();
is($classdoc->openProject('t/lib'), $classdoc, 'openProject');
}

my $classmap = $classdoc->render;

#****
#open(OUTF, ">t/render.out");
#print OUTF Dumper($classmap);
#close OUTF;
#****

my $expected = { 
          'DBD::_::db' => [
                            '
<html>
<head>
<title>DBD::_::db</title>
</head>
<body>
<table width=\'100%\' border=0 CELLPADDING=\'0\' CELLSPACING=\'3\'>
<TR>
<TD VALIGN=\'top\' align=left><FONT SIZE=\'-2\'>
 SUMMARY:&nbsp;CONSTR&nbsp;|&nbsp;<a href=\'#method_summary\'>METHOD</a>
 </FONT></TD>
<TD VALIGN=\'top\' align=right><FONT SIZE=\'-2\'>
DETAIL:&nbsp;CONSTR&nbsp;|&nbsp;<a href=\'#method_detail\'>METHOD</a>
</FONT></TD>
</TR>
</table><hr>
<h2>Class DBD::_::db</h2>

<hr>


Database <i>(aka Connection)</i> handle. Represents a single logical connection
to a database. Acts as a factory for Statement handle objects. Provides
methods for 
<ul>
<li>preparing queries to create Statement handles
<li>immediately executing queries (without a prepared Statement handle)
<li>transaction control
<li>metadata retrieval
</ul>


<p>

<dl>

<a name=\'members\'></a>
<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'><th colspan=2 align=left><font size=\'+2\'>Public Instance Members</font></th></tr>
<tr><td align=right valign=top><a name=\'_m_(array ref, read-only) a reference to an array of all
	statement handles created by this handle which are still accessible.  The
	contents of the array are weak-refs and will become undef when the
	handle goes out of scope. <code>undef</code> if your Perl version does not support weak
	references (check the <a href=\'http://search.cpan.org/perldoc?Scalar::Util|Scalar::Util\'>Scalar::Util|Scalar::Util</a> module).

\'></a><code>(array ref, read-only) a reference to an array of all
	statement handles created by this handle which are still accessible.  The
	contents of the array are weak-refs and will become undef when the
	handle goes out of scope. <code>undef</code> if your Perl version does not support weak
	references (check the <a href=\'http://search.cpan.org/perldoc?Scalar::Util|Scalar::Util\'>Scalar::Util|Scalar::Util</a> module).

</code></td><td align=left valign=top>(boolean) When true (the usual default), database changes executed by this handle 
	cannot be rolled-back (undone).	If false, database changes automatically occur within a "transaction", which
	must explicitly be committed or rolled back using the <code>commit</code> or <code>rollback</code>
	methods.
	<p>
	See <a href=\'#_f_commit\'>commit</a>, <a href=\'#_f_rollback\'>rollback</a>, and <a href=\'#_f_disconnect\'>disconnect</a>
	for additional information regarding use of AutoCommit.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean) when false (the default),this handle will be fully destroyed
	as normal when the last reference to it is removed. If true, this handle will be treated by 
	DESTROY as if it was no longer Active, and so the <i>database engine</i> related effects of 
	DESTROYing this handle will be skipped. Does not disable an <i>explicit</i>
	call to the disconnect method, only the implicit call from DESTROY
	that happens if the handle is still marked as <code>Active</code>. Designed for use in Unix applications
	that "fork" child processes: Either the parent or the child process
	(but not both) should set <code>InactiveDestroy</code> true on all their shared handles.
	(Note that some databases, including Oracle, don\'t support passing a
	database connection across a fork.)
	<p>
	To help tracing applications using fork the process id is shown in
	the trace log whenever a DBI or handle trace() method is called.
	The process id also shown for <i>every</i> method call if the DBI trace
	level (not handle trace level) is set high enough to show the trace
	from the DBI\'s method dispatcher, e.g. >= 9.

\'></a><code>(boolean) when false (the default),this handle will be fully destroyed
	as normal when the last reference to it is removed. If true, this handle will be treated by 
	DESTROY as if it was no longer Active, and so the <i>database engine</i> related effects of 
	DESTROYing this handle will be skipped. Does not disable an <i>explicit</i>
	call to the disconnect method, only the implicit call from DESTROY
	that happens if the handle is still marked as <code>Active</code>. Designed for use in Unix applications
	that "fork" child processes: Either the parent or the child process
	(but not both) should set <code>InactiveDestroy</code> true on all their shared handles.
	(Note that some databases, including Oracle, don\'t support passing a
	database connection across a fork.)
	<p>
	To help tracing applications using fork the process id is shown in
	the trace log whenever a DBI or handle trace() method is called.
	The process id also shown for <i>every</i> method call if the DBI trace
	level (not handle trace level) is set high enough to show the trace
	from the DBI\'s method dispatcher, e.g. >= 9.

</code></td><td align=left valign=top>(boolean) when true, this handle object has been "executed".
	Only the do() method sets this attribute. When set, also sets the parent driver
	handle\'s Executed attribute. Cleared by commit() and rollback() methods (even if they fail). 

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) Sets both <a href=\'#_m_TaintIn\'>TaintIn</a> and <a href=\'#_m_TaintOut\'>TaintOut</a>;
	returns a true value if and only if <a href=\'#_m_TaintIn\'>TaintIn</a> and <a href=\'#_m_TaintOut\'>TaintOut</a> are
	both set to true values.

\'></a><code>(boolean, inherited) Sets both <a href=\'#_m_TaintIn\'>TaintIn</a> and <a href=\'#_m_TaintOut\'>TaintOut</a>;
	returns a true value if and only if <a href=\'#_m_TaintIn\'>TaintIn</a> and <a href=\'#_m_TaintOut\'>TaintOut</a> are
	both set to true values.

</code></td><td align=left valign=top>(boolean, inherited) When false (the default), fetching a long value that
	needs to be truncated (usually due to exceeding <code>LongReadLen</code>) will cause the fetch to fail.
	(Applications should always be sure to
	check for errors after a fetch loop in case an error, such as a divide
	by zero or long field truncation, caused the fetch to terminate
	prematurely.)
	<p>
	If a fetch fails due to a long field truncation when <code>LongTruncOk</code> is
	false, many drivers will allow you to continue fetching further rows.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then all the arguments
	to most DBI method calls are checked for being tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.

\'></a><code>(boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then all the arguments
	to most DBI method calls are checked for being tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.

</code></td><td align=left valign=top>(boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then most data fetched
	from the database is considered tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.
	<p>
	Currently only fetched data is tainted. It is possible that the results
	of other DBI method calls, and the value of fetched attributes, may
	also be tainted in future versions.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true (default false), errors raise exceptions rather
	than simply returning error codes in the normal way.
	Exceptions are raised via a <code>die("$class $method failed: $DBI::errstr")</code>,
	where <code>$class</code> is the driver class and <code>$method</code> is the name of the method
	that failed.
	<p>
	If <code>PrintError</code> is also on, the <code>PrintError</code> is done first.
	<p>
	Typically <code>RaiseError</code> is used in conjunction with <code>eval { ... }</code>
	to catch the exception that\'s been thrown and followed by an
	<code>if ($@) { ... }</code> block to handle the caught exception.
	For example:
<pre>
  eval {
    ...
    $sth->execute();
    ...
  };
  if ($@) {
    # $sth->err and $DBI::err will be true if error was from DBI
    warn $@; # print the error
    ... # do whatever you need to deal with the error
  }
</pre>

\'></a><code>(boolean, inherited) When true (default false), errors raise exceptions rather
	than simply returning error codes in the normal way.
	Exceptions are raised via a <code>die("$class $method failed: $DBI::errstr")</code>,
	where <code>$class</code> is the driver class and <code>$method</code> is the name of the method
	that failed.
	<p>
	If <code>PrintError</code> is also on, the <code>PrintError</code> is done first.
	<p>
	Typically <code>RaiseError</code> is used in conjunction with <code>eval { ... }</code>
	to catch the exception that\'s been thrown and followed by an
	<code>if ($@) { ... }</code> block to handle the caught exception.
	For example:
<pre>
  eval {
    ...
    $sth->execute();
    ...
  };
  if ($@) {
    # $sth->err and $DBI::err will be true if error was from DBI
    warn $@; # print the error
    ... # do whatever you need to deal with the error
  }
</pre>

</code></td><td align=left valign=top>(boolean, inherited) When true (default false), trailing space characters are 
	trimmed from returned fixed width character (CHAR) fields. No other field types are affected, 
	even where field values have trailing spaces.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true, causes the relevant
	Statement text to be appended to the error messages generated by <code>RaiseError</code>, <code>PrintError</code>, 
	and <code>PrintWarn</code> attributes. Only applies to errors occuring on
	the prepare(), do(), and the various <code>select*()</code> methods.
	<p>
	If <code>$h-&gt;{ParamValues}</code> returns a hash reference of parameter
	(placeholder) values then those are formatted and appended to the
	end of the Statement text in the error message.


\'></a><code>(boolean, inherited) When true, causes the relevant
	Statement text to be appended to the error messages generated by <code>RaiseError</code>, <code>PrintError</code>, 
	and <code>PrintWarn</code> attributes. Only applies to errors occuring on
	the prepare(), do(), and the various <code>select*()</code> methods.
	<p>
	If <code>$h-&gt;{ParamValues}</code> returns a hash reference of parameter
	(placeholder) values then those are formatted and appended to the
	end of the Statement text in the error message.


</code></td><td align=left valign=top>(boolean, inherited) When true, forces errors to generate warnings 
	(in addition to returning error codes in the normal way)
	via a <code>warn("$class $method failed: $DBI::errstr")</code>, where <code>$class</code>
	is the driver class and <code>$method</code> is the name of the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintError</code> "on".
	<p>
	If desired, the warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true, indicates that this handle and it\'s children will 
	not make any changes to the database.
	<p>
	The exact definition of \'read only\' is rather fuzzy. See individual driver documentation for specific details.
	<p>
	If the driver can make the handle truly read-only (by issuing a statement like
	"<code>set transaction read only</code>", for example) then it should.
	Otherwise the attribute is simply advisory.
	<p>
	A driver can set the <code>ReadOnly</code> attribute itself to indicate that the data it
	is connected to cannot be changed for some reason.
	<p>
	Library modules and proxy drivers can use the attribute to influence their behavior.
	For example, the DBD::Gofer driver considers the <code>ReadOnly</code> attribute when
	making a decison about whether to retry an operation that failed.
	<p>
	The attribute should be set to 1 or 0 (or undef). Other values are reserved.

\'></a><code>(boolean, inherited) When true, indicates that this handle and it\'s children will 
	not make any changes to the database.
	<p>
	The exact definition of \'read only\' is rather fuzzy. See individual driver documentation for specific details.
	<p>
	If the driver can make the handle truly read-only (by issuing a statement like
	"<code>set transaction read only</code>", for example) then it should.
	Otherwise the attribute is simply advisory.
	<p>
	A driver can set the <code>ReadOnly</code> attribute itself to indicate that the data it
	is connected to cannot be changed for some reason.
	<p>
	Library modules and proxy drivers can use the attribute to influence their behavior.
	For example, the DBD::Gofer driver considers the <code>ReadOnly</code> attribute when
	making a decison about whether to retry an operation that failed.
	<p>
	The attribute should be set to 1 or 0 (or undef). Other values are reserved.

</code></td><td align=left valign=top>(boolean, inherited) controls printing of warnings issued
	by this handle.  When true, DBI checks method calls to see if a warning condition has 
	been set. If so, DBI effectively does a <code>warn("$class $method warning: $DBI::errstr")</code>
	where <code>$class</code> is the driver class and <code>$method</code> is the name of
	the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintWarn</code> "on" if $^W is true.
	<p>
	Warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.
	<p>
	See also <a href=\'#_f_set_err\'>set_err</a> for how warnings are recorded and <a href=\'#_m_HandleSetErr\'>HandleSetErr</a>
	for how to influence it.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) enables useful warnings (which
	can be intercepted using the <code>$SIG{__WARN__}</code> hook) for certain bad practices;

\'></a><code>(boolean, inherited) enables useful warnings (which
	can be intercepted using the <code>$SIG{__WARN__}</code> hook) for certain bad practices;

</code></td><td align=left valign=top>(boolean, inherited) used by emulation layers (such as
	Oraperl) to enable compatible behaviour in the underlying driver (e.g., DBD::Oracle) for this handle. 
	Not normally set by application code. Disables the \'quick FETCH\' of attribute
	values from this handle\'s attribute cache so all attribute values
	are handled by the drivers own FETCH method.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, read-only) when true, indicates this handle object is "active". 
	The exact meaning of active is somewhat vague at the moment. Typically means that this handle is
	connected to a database

\'></a><code>(boolean, read-only) when true, indicates this handle object is "active". 
	The exact meaning of active is somewhat vague at the moment. Typically means that this handle is
	connected to a database

</code></td><td align=left valign=top>(code ref, inherited) When set to a subroutien reference, intercepts
	the setting of this handle\'s <code>err</code>, <code>errstr</code>, and <code>state</code> values.
	<p>
	The subroutine is called the arguments that	were passed to set_err(): the handle, 
	the <code>err</code>, <code>errstr</code>, and <code>state</code> values being set, 
	and the method name. These can be altered by changing the values in the @_ array. 
	The return value affects set_err() behaviour, see <a href=\'#_f_set_err\'>set_err</a> for details.
	<p>
	It is possible to \'stack\' multiple HandleSetErr handlers by using
	closures. See <a href=\'#_m_HandleError\'>HandleError</a> for an example.
	<p>
	The <code>HandleSetErr</code> and <code>HandleError</code> subroutines differ in that
	HandleError is only invoked at the point where DBI is about to return to the application 
	with <code>err</code> set true; it is not invoked by the failure of a method that\'s 
	been called by another DBI method.  HandleSetErr is called
	whenever set_err() is called with a defined <code>err</code> value, even if false.
	Thus, the HandleSetErr subroutine may be called multiple
	times within a method and is usually invoked from deep within driver code.
	<p>
	A driver can use the return value from HandleSetErr via
	set_err() to decide whether to continue or not. If set_err() returns
	an empty list, indicating that the HandleSetErr code has \'handled\'
	the \'error\', the driver might continue instead of failing. 

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(code ref, inherited) When set to a subroutine reference, provides
	alternative behaviour in case of errors. The subroutine reference is called when an 
	error is detected (at the same point that <code>RaiseError</code> and <code>PrintError</code> are handled).
	<p>
	The subroutine is called with three parameters: the error message
	string, this handle object, and the first value returned by
	the method that failed (typically undef).
	<p>
	If the subroutine returns a false value, the <code>RaiseError</code>
	and/or <code>PrintError</code> attributes are checked and acted upon as normal.
	<p>
	For example, to <code>die</code> with a full stack trace for any error:
<pre>
  use Carp;
  $h->{HandleError} = sub { confess(shift) };
</pre>
	Or to turn errors into exceptions:
<pre>
  use Exception; # or your own favourite exception module
  $h->{HandleError} = sub { Exception->new(\'DBI\')->raise($_[0]) };
</pre>
	It is possible to \'stack\' multiple HandleError handlers by using closures:
<pre>
  sub your_subroutine {
    my $previous_handler = $h->{HandleError};
    $h->{HandleError} = sub {
      return 1 if $previous_handler and &$previous_handler(@_);
      ... your code here ...
    };
  }
</pre>
	The error message that will be used by <code>RaiseError</code> and <code>PrintError</code>
	can be altered by changing the value of <code>$_[0]</code>.
	<p>
	Errors may be suppressed, to a limited extent, by using <a href=\'#_f_set_err\'>set_err</a> to 
	reset $DBI::err and $DBI::errstr, and altering the return value of the failed method:
<pre>
  $h->{HandleError} = sub {
    return 0 unless $_[0] =~ /^\\S+ fetchrow_arrayref failed:/;
    return 0 unless $_[1]->err == 1234; # the error to \'hide\'
    $h->set_err(undef,undef);	# turn off the error
    $_[2] = [ ... ];	# supply alternative return value
    return 1;
  };
</pre>

\'></a><code>(code ref, inherited) When set to a subroutine reference, provides
	alternative behaviour in case of errors. The subroutine reference is called when an 
	error is detected (at the same point that <code>RaiseError</code> and <code>PrintError</code> are handled).
	<p>
	The subroutine is called with three parameters: the error message
	string, this handle object, and the first value returned by
	the method that failed (typically undef).
	<p>
	If the subroutine returns a false value, the <code>RaiseError</code>
	and/or <code>PrintError</code> attributes are checked and acted upon as normal.
	<p>
	For example, to <code>die</code> with a full stack trace for any error:
<pre>
  use Carp;
  $h->{HandleError} = sub { confess(shift) };
</pre>
	Or to turn errors into exceptions:
<pre>
  use Exception; # or your own favourite exception module
  $h->{HandleError} = sub { Exception->new(\'DBI\')->raise($_[0]) };
</pre>
	It is possible to \'stack\' multiple HandleError handlers by using closures:
<pre>
  sub your_subroutine {
    my $previous_handler = $h->{HandleError};
    $h->{HandleError} = sub {
      return 1 if $previous_handler and &$previous_handler(@_);
      ... your code here ...
    };
  }
</pre>
	The error message that will be used by <code>RaiseError</code> and <code>PrintError</code>
	can be altered by changing the value of <code>$_[0]</code>.
	<p>
	Errors may be suppressed, to a limited extent, by using <a href=\'#_f_set_err\'>set_err</a> to 
	reset $DBI::err and $DBI::errstr, and altering the return value of the failed method:
<pre>
  $h->{HandleError} = sub {
    return 0 unless $_[0] =~ /^\\S+ fetchrow_arrayref failed:/;
    return 0 unless $_[1]->err == 1234; # the error to \'hide\'
    $h->set_err(undef,undef);	# turn off the error
    $_[2] = [ ... ];	# supply alternative return value
    return 1;
  };
</pre>

</code></td><td align=left valign=top>(handle) the parent driver handle object.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(hash ref) a reference to the cache (hash) of
	statement handles created by the <a href=\'#_f_prepare_cached\'>prepare_cached</a> method.

\'></a><code>(hash ref) a reference to the cache (hash) of
	statement handles created by the <a href=\'#_f_prepare_cached\'>prepare_cached</a> method.

</code></td><td align=left valign=top>(integer) A hint to the driver indicating the size of the local row cache that the
	application would like the driver to use for data returning statements.
	Ignored (returning <code>undef</code>) if a row cache is not implemented.
	<p>
	The following values have special meaning:
	<ul>
	<li>0 - Automatically determine a reasonable cache size for each data returning
	<li>1 - Disable the local row cache
	<li>&gt;1 - Cache this many rows
 	<li>&lt;0 - Cache as many rows that will fit into this much memory for each data returning.
	</ul>
	Note that large cache sizes may require a very large amount of memory
	(<i>cached rows * maximum size of row</i>). Also, a large cache will cause
	a longer delay not only for the first fetch, but also whenever the
	cache needs refilling.
	<p>
	See <a href=\'#_m_RowsInCache\'>RowsInCache</a>.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(integer, inherited) the trace level and flags for this handle. May be used
	to set the trace level and flags. 

\'></a><code>(integer, inherited) the trace level and flags for this handle. May be used
	to set the trace level and flags. 

</code></td><td align=left valign=top>(integer, read-only) the number of currently existing statement handles
	created from this handle that are <code>Active</code>.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(integer, read-only) the number of currently existing statement handles
	created from this handle.

\'></a><code>(integer, read-only) the number of currently existing statement handles
	created from this handle.

</code></td><td align=left valign=top>(scalar, read-only) "db" (the type of this handle object)

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(string) the "name" of the database. Usually (and recommended to be) the
	same as the DSN string used to connect to the database
	with the leading "<code>dbi:DriverName:</code>" removed.

\'></a><code>(string) the "name" of the database. Usually (and recommended to be) the
	same as the DSN string used to connect to the database
	with the leading "<code>dbi:DriverName:</code>" removed.

</code></td><td align=left valign=top>(string) the username used to connect to the database.
</td></tr>
<tr><td align=right valign=top><a name=\'_m_(string, inherited) Specifies the case conversion applied to the 
	the field names used for the hash keys returned by fetchrow_hashref().
	Defaults to \'<code>NAME</code>\' but it is recommended to set it to either \'<code>NAME_lc</code>\'
	or \'<code>NAME_uc</code>\'.

\'></a><code>(string, inherited) Specifies the case conversion applied to the 
	the field names used for the hash keys returned by fetchrow_hashref().
	Defaults to \'<code>NAME</code>\' but it is recommended to set it to either \'<code>NAME_lc</code>\'
	or \'<code>NAME_uc</code>\'.

</code></td><td align=left valign=top>(string, read-only) the statement string passed to the most 
	recent <a href=\'#_f_prepare\'>prepare</a> method call by this database handle, 
	even if that method failed. 

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(unsigned integer) the count of calls to set_err() on this handle that recorded an error
	(excluding warnings or information states). It is not reset by the DBI at any time.

\'></a><code>(unsigned integer) the count of calls to set_err() on this handle that recorded an error
	(excluding warnings or information states). It is not reset by the DBI at any time.

</code></td><td align=left valign=top>(unsigned integer, inherited) Sets the maximum
	length of \'long\' type fields (LONG, BLOB, CLOB, MEMO, etc.) which the driver will
	read from the database automatically when it fetches each row of data.
	The <code>LongReadLen</code> attribute only relates to fetching and reading
	long values; it is not involved in inserting or updating them.
	<p>
	A value of 0 means not to automatically fetch any long data.
	Drivers may return undef or an empty string for long fields when
	<code>LongReadLen</code> is 0.
	<p>
	The default is typically 0 (zero) bytes but may vary between drivers.
	Applications fetching long fields should set this value to slightly
	larger than the longest long field value to be fetched.
	<p>
	Some databases return some long types encoded as pairs of hex digits.
	For these types, <code>LongReadLen</code> relates to the underlying data
	length and not the doubled-up length of the encoded string.
	<p>
	Changing the value of <code>LongReadLen</code> for a statement handle after it
	has been <code>prepare</code>\'d will typically have no effect, so it\'s common to
	set <code>LongReadLen</code> on the database or driver handle before calling <code>prepare</code>.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_Active\'></a><code>Active</code></td><td align=left valign=top>ActiveKids</td></tr>
<tr><td align=right valign=top><a name=\'_m_AutoCommit\'></a><code>AutoCommit</code></td><td align=left valign=top>CachedKids</td></tr>
<tr><td align=right valign=top><a name=\'_m_ChildHandles\'></a><code>ChildHandles</code></td><td align=left valign=top>ChopBlanks</td></tr>
<tr><td align=right valign=top><a name=\'_m_CompatMode\'></a><code>CompatMode</code></td><td align=left valign=top>Driver</td></tr>
<tr><td align=right valign=top><a name=\'_m_ErrCount\'></a><code>ErrCount</code></td><td align=left valign=top>Executed</td></tr>
<tr><td align=right valign=top><a name=\'_m_FetchHashKeyName\'></a><code>FetchHashKeyName</code></td><td align=left valign=top>HandleError</td></tr>
<tr><td align=right valign=top><a name=\'_m_HandleSetErr\'></a><code>HandleSetErr</code></td><td align=left valign=top>InactiveDestroy</td></tr>
<tr><td align=right valign=top><a name=\'_m_Kids\'></a><code>Kids</code></td><td align=left valign=top>LongReadLen</td></tr>
<tr><td align=right valign=top><a name=\'_m_LongTruncOk\'></a><code>LongTruncOk</code></td><td align=left valign=top>Name</td></tr>
<tr><td align=right valign=top><a name=\'_m_PrintError\'></a><code>PrintError</code></td><td align=left valign=top>PrintWarn</td></tr>
<tr><td align=right valign=top><a name=\'_m_RaiseError\'></a><code>RaiseError</code></td><td align=left valign=top>ReadOnly</td></tr>
<tr><td align=right valign=top><a name=\'_m_RowCacheSize\'></a><code>RowCacheSize</code></td><td align=left valign=top>ShowErrorStatement</td></tr>
<tr><td align=right valign=top><a name=\'_m_Statement\'></a><code>Statement</code></td><td align=left valign=top>Taint</td></tr>
<tr><td align=right valign=top><a name=\'_m_TaintIn\'></a><code>TaintIn</code></td><td align=left valign=top>TaintOut</td></tr>
<tr><td align=right valign=top><a name=\'_m_TraceLevel\'></a><code>TraceLevel</code></td><td align=left valign=top>Type</td></tr>
<tr><td align=right valign=top><a name=\'_m_Username\'></a><code>Username</code></td><td align=left valign=top>Warn</td></tr>

</table>
<p>

<a name=\'summary\'></a>

<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'><th align=left><font size=\'+2\'>Method Summary</font></th></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_begin_work\'>begin_work</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Start a transaction on this database handle
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_can\'>can</a>($method_name)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Does this driver or the DBI implement this method ?


</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_clone\'>clone</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Duplicate this database handle object\'s connection by connecting
with the same parameters as used to create this database handle object
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_column_info\'>column_info</a>($catalog, $schema, $table, $column)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

  $sth = $dbh->column_info( $catalog, $schema, $table, $column );

Create an active statement handle to return column metadata
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_commit\'>commit</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Commit (make permanent) the most recent series of database changes
if the database supports transactions and AutoCommit is off
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_data_sources\'>data_sources</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Get the list of data sources (databases) available via this database
handle object
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_disconnect\'>disconnect</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Disconnects the database from the database handle
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_do\'>do</a>($statement)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Prepare and immediately execute a single statement
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_err\'>err</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the error code from the last driver method called
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_errstr\'>errstr</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the error message from the last driver method called
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_foreign_key_info\'>foreign_key_info</a>($pk_catalog, $pk_schema, $pk_table, $fk_catalog, $fk_schema, $fk_table)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Create an active statement handle to return metadata
about foreign keys in and/or referencing the specified table(s)
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_func\'>func</a>(@func_arguments, $func)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Call the specified driver private method
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_get_info\'>get_info</a>($info_type)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return metadata about the driver and data source capabilities, restrictions etc
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_last_insert_id\'>last_insert_id</a>($catalog, $schema, $table, $field)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the database server assigned unique identifier for the
prior inserted row
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_parse_trace_flag\'>parse_trace_flag</a>($trace_flag_name)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the bit flag value for the specified trace flag name
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_parse_trace_flags\'>parse_trace_flags</a>($trace_settings)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Parse a string containing trace settings
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_ping\'>ping</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Is this database handle still connected to the database server ?
<p>
Attempts to determine, in a reasonably efficient way, if the database
server is still running and the connection to it is still working
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_prepare\'>prepare</a>($statement)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Prepare a statement for later execution by the database
engine
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_prepare_cached\'>prepare_cached</a>($statement)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Locate a matching statement handle object in this object\'s
statement handle cache; if no match is found, prepare the statement 
and store the resulting statement handle object in
this database handle\'s statement cache
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_primary_key\'>primary_key</a>($catalog, $schema, $table)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Get the column names that comprise the primary key of the specified table
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_primary_key_info\'>primary_key_info</a>($catalog, $schema, $table)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Create an active statement handle to return metadata about columns that 
make up the primary key for a table
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_quote\'>quote</a>($value)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Quote a string literal for use as a literal value in an SQL statement
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_quote_identifier\'>quote_identifier</a>($catalog)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Quote a database object identifier (table name etc
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_rollback\'>rollback</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Rollback (undo) the most recent series of uncommitted database
changes if the database supports transactions and AutoCommit is off
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_selectall_arrayref\'>selectall_arrayref</a>($statement)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Immediately execute a data returning statement, returning all result rows
as an array reference
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_selectall_hashref\'>selectall_hashref</a>($statement, $key_field)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Immediately execute a data returning statement, returning all result rows
as a hash reference
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_selectcol_arrayref\'>selectcol_arrayref</a>($statement)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Immediately execute a data returning statement, returning all result rows
as a hash reference
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_selectrow_array\'>selectrow_array</a>($statement)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Immediately execute a data returning statement, returning the first row of results
as an array
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_selectrow_arrayref\'>selectrow_arrayref</a>($statement)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Immediately execute a data returning statement, returning the first row of results
as an array reference
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_selectrow_hashref\'>selectrow_hashref</a>($statement)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Immediately execute a data returning statement, returning the first row of results
as a hash reference
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_set_err\'>set_err</a>($err, $errstr)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Set the <code>err</code>, <code>errstr</code>, and <code>state</code> values for the handle
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_state\'>state</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the standard SQLSTATE five character format code for the prior driver
method
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_statistics_info\'>statistics_info</a>($catalog, $schema, $table, $unique_only, $quick)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Create an active statement handle returning statistical
information about a table and its indexes
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_swap_inner_handle\'>swap_inner_handle</a>($h2)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Swap the internals of 2 handle objects
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_table_info\'>table_info</a>($catalog, $schema, $table, $type)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Create an active statement handle to return table metadata
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_tables\'>tables</a>($catalog, $schema, $table, $type)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Get the list of matching table names
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_take_imp_data\'>take_imp_data</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Leaves this Database handle object in an almost dead, zombie-like, state
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_trace\'>trace</a>($trace_setting)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Set the trace settings for the handle object
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_trace_msg\'>trace_msg</a>($message_text)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Write a trace message to the handle object\'s current trace output
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_type_info\'>type_info</a>($data_type)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Get the data type metadata for the specified <code>$data_type</code>
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_type_info_all\'>type_info_all</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return metadata for all supported data types
</td></tr>
</table>
<p>

<a name=\'method_detail\'></a>
<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'>
	<th align=left><font size=\'+2\'>Method Details</font></th>
</tr></table>

<a name=\'_f_begin_work\'></a>
<h3>begin_work</h3>
<pre>
begin_work()
</pre><p>
<dl>
<dd>
Start a transaction on this database handle.
Enables transaction (by turning <a href=\'#_m_AutoCommit\'>AutoCommit</a> off) until the next call
to <a href=\'#_f_commit\'>commit</a> or <a href=\'#_f_rollback\'>rollback</a>. After the next 
<a href=\'#_f_commit\'>commit</a> or <a href=\'#_f_rollback\'>rollback</a>,
<a href=\'#_m_AutoCommit\'>AutoCommit</a> will automatically be turned on again.
<p>


<p>
<dd><dl>
<dt><b>Returns:</b><dd><code>undef</code> if <a href=\'#_m_AutoCommit\'>AutoCommit</a> is already off when this method is called,
	or the driver does not support transactions; otherwise, returns true.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Transactions\'>Transactions</a> in the DBI manual.</dd>
</dl></dd></dl><hr>

<a name=\'_f_can\'></a>
<h3>can</h3>
<pre>
can($method_name)
</pre><p>
<dl>
<dd>

Does this driver or the DBI implement this method ?


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>true if $method_name is implemented by the driver or a non-empty default method is provided by DBI;
	otherwise false (i.e., the driver hasn\'t implemented the method and DBI does not
	provide a non-empty default).
</dd>
</dl></dd></dl><hr>

<a name=\'_f_clone\'></a>
<h3>clone</h3>
<pre>
clone()
</pre><p>
<dl>
<dd>
Duplicate this database handle object\'s connection by connecting
with the same parameters as used to create this database handle object.
<p>
The attributes for the cloned connect are the same as those used
for the original connect, with some other attribute merged over
them depending on the \\%attr parameter.
<p>
If \\%attr is given then the attributes it contains are merged into
the original attributes and override any with the same names.
<p>
If \\%attr is not given then it defaults to a hash containing all
the attributes in the attribute cache of this database handle object,
excluding any non-code references, plus the main boolean attributes (RaiseError, PrintError,
AutoCommit, etc.). This behaviour is subject to change.
<p>
This method can be used even if the database handle is disconnected.


<p>
<dd><dl>
<dt><b>Since:</b></dt><dd>1.33
</dd>
</dl></dd></dl><hr>

<a name=\'_f_column_info\'></a>
<h3>column_info</h3>
<pre>
column_info($catalog, $schema, $table, $column)
</pre><p>
<dl>
<dd>

  $sth = $dbh->column_info( $catalog, $schema, $table, $column );

Create an active statement handle to return column metadata.
<p>
The arguments $catalog, $schema, $table, and column may accept search patterns
according to the database/driver, for example: $table = \'%FOO%\';
The underscore character (\'<code>_</code>\') matches any single character,
while the percent character (\'<code>%</code>\') matches zero or more
characters.
<p>
Drivers which do not support one or more of the selection filter
parameters may return metadata for more tables than requested, which may
require additional filtering by the application.
<p>
If the search criteria do not match any columns, the returned statement handle may return no rows.
<p>
Some drivers may provide additional metadata beyond that listed below.
using lowercase field names with the driver-specific prefix. 
Such fields should be accessed by name, not by column number.
<p>
Note: There is some overlap with statement attributes (in Perl) and
SQLDescribeCol (in ODBC). However, SQLColumns provides more metadata.



<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd><code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present),
	ordered by TABLE_CAT, TABLE_SCHEM, TABLE_NAME, and ORDINAL_POSITION:

<ol>
<li>TABLE_CAT: The catalog identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>TABLE_SCHEM: The schema identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>TABLE_NAME: The table identifier.
Note: A driver may provide column metadata not only for base tables, but
also for derived objects like SYNONYMS etc.

<li>COLUMN_NAME: The column identifier.

<li>DATA_TYPE: The concise data type code.

<li>TYPE_NAME: A data source dependent data type name.

<li>COLUMN_SIZE: The column size.
This is the maximum length in characters for character data types,
the number of digits or bits for numeric data types or the length
in the representation of temporal types.
See the relevant specifications for detailed information.

<li>BUFFER_LENGTH: The length in bytes of transferred data.

<li>DECIMAL_DIGITS: The total number of significant digits to the right of
the decimal point.

<li>NUM_PREC_RADIX: The radix for numeric precision.
The value is 10 or 2 for numeric data types and NULL (<code>undef</code>) if not
applicable.

<li>NULLABLE: Indicates if a column can accept NULLs.
The following values are defined:
<ul>
<li>SQL_NO_NULLS (0)
<li>SQL_NULLABLE (1)
<li>SQL_NULLABLE_UNKNOWN (2)
</ul>

<li>REMARKS: A description of the column.

<li>COLUMN_DEF: The default value of the column.

<li>SQL_DATA_TYPE: The SQL data type.

<li>SQL_DATETIME_SUB: The subtype code for datetime and interval data types.

<li>CHAR_OCTET_LENGTH: The maximum length in bytes of a character or binary
data type column.

<li>ORDINAL_POSITION: The column sequence number (starting with 1).

<li>IS_NULLABLE: Indicates if the column can accept NULLs.
Possible values are: \'NO\', \'YES\' and \'\'.
</ol>

SQL/CLI defines the following additional columns:
<pre>
  CHAR_SET_CAT
  CHAR_SET_SCHEM
  CHAR_SET_NAME
  COLLATION_CAT
  COLLATION_SCHEM
  COLLATION_NAME
  UDT_CAT
  UDT_SCHEM
  UDT_NAME
  DOMAIN_CAT
  DOMAIN_SCHEM
  DOMAIN_NAME
  SCOPE_CAT
  SCOPE_SCHEM
  SCOPE_NAME
  MAX_CARDINALITY
  DTD_IDENTIFIER
  IS_SELF_REF
</pre>
Drivers capable of supplying any of those values should do so in
the corresponding column and supply undef values for the others.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Standards_Reference_Information\'>Standards Reference Information</a> in the DBI manual</dd>
</dl></dd></dl><hr>

<a name=\'_f_commit\'></a>
<h3>commit</h3>
<pre>
commit()
</pre><p>
<dl>
<dd>

Commit (make permanent) the most recent series of database changes
if the database supports transactions and AutoCommit is off.
<p>
If <code>AutoCommit</code> is on, issues
a "commit ineffective with AutoCommit" warning.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>true on success, <code>undef</code> on failure.
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Transactions\'>Transactions</a> in the DBI manual.</dd>
</dl></dd></dl><hr>

<a name=\'_f_data_sources\'></a>
<h3>data_sources</h3>
<pre>
data_sources()
</pre><p>
<dl>
<dd>
Get the list of data sources (databases) available via this database
handle object. 


<p>
<dd><dl>
<dt><b>Returns:</b><dd>(the names of data sources (databases) in a form suitable for passing to the
	<a href=\'DBI/connect.html#_f_DBI::connect\'>method</a> method (including the "<code>dbi:$driver:</code>" prefix).
	The list is the result of the parent driver object\'s <a href=\'DBD/_/dr/data_sources.html#_f_DBD::_::dr::data_sources\'>method</a>, plus 
	any extra data sources the driver can discover via this connected database handle.

)</dd>
<dt><b>Since:</b></dt><dd>1.38
</dd>
</dl></dd></dl><hr>

<a name=\'_f_disconnect\'></a>
<h3>disconnect</h3>
<pre>
disconnect()
</pre><p>
<dl>
<dd>

Disconnects the database from the database handle. Typically only used
before exiting the program. The handle is of little use after disconnecting.
<p>
The transaction behaviour of the <code>disconnect</code> method is
undefined.  Some database systems will
automatically commit any outstanding changes; others will rollback any outstanding changes.
Applications not using <code>AutoCommit</code> should explicitly call <code>commit</code> or 
<code>rollback</code> before calling <code>disconnect</code>.
<p>
The database is automatically disconnected by the <code>DESTROY</code> method if
still connected when there are no longer any references to the handle.
<p>
A warning is issued if called while some statement handles are active
(e.g., SELECT statement handles that have more data to fetch), 
The warning may indicate that a fetch loop terminated early, perhaps due to an uncaught error.
To avoid the warning, call the <code>finish</code> method on the active handles.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>true on success, <code>undef</code> on failure.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_do\'></a>
<h3>do</h3>
<pre>
do($statement)
</pre><p>
<dl>
<dd>
Prepare and immediately execute a single statement. 
Typically used for <i>non</i>-data returning statements that
either cannot be prepared in advance (due to a limitation of the
driver) or do not need to be executed repeatedly. It should not
be used for data returning statements because it does not return a statement
handle (so you can\'t fetch any data).
<p>
Using placeholders and <code>@bind_values</code> with the <code>do</code> method can be
useful because it avoids the need to correctly quote any variables
in the <code>$statement</code>. Statements that will be executed many
times should <code>prepare()</code> it once and call
<code>execute()</code> many times instead.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the number of rows affected by the statement execution,
	or <code>undef</code> on error. A return value of <code>-1</code> means the
	number of rows is not known, not applicable, or not available.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_err\'></a>
<h3>err</h3>
<pre>
err()
</pre><p>
<dl>
<dd>

Return the error code from the last driver method called. 


<p>
<dd><dl>
<dt><b>Returns:</b><dd>the <i>native</i> database engine error code; may be zero
	to indicate a warning condition. May be an empty string
	to indicate a \'success with information\' condition. In both these
	cases the value is false but not undef. The errstr() and state()
	methods may be used to retrieve extra information in these cases.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'#_f_set_err\'>set_err</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_errstr\'></a>
<h3>errstr</h3>
<pre>
errstr()
</pre><p>
<dl>
<dd>

Return the error message from the last driver method called.
<p>
Should not be used to test for errors as some drivers may return 
\'success with information\' or warning messages via errstr() for 
methods that have not \'failed\'.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>One or more native database engine error messages as a single string;
	multiple messages are separated by newline characters.
	May be an empty string if the prior driver method returned successfully.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'#_f_set_err\'>set_err</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_foreign_key_info\'></a>
<h3>foreign_key_info</h3>
<pre>
foreign_key_info($pk_catalog, $pk_schema, $pk_table, $fk_catalog, $fk_schema, $fk_table)
</pre><p>
<dl>
<dd>

Create an active statement handle to return metadata
about foreign keys in and/or referencing the specified table(s).
The arguments don\'t accept search patterns (unlike table_info()).
<p>
If both the primary key and foreign key table parameters are specified,
the resultset contains the foreign key metadata, if
any, in foreign key table that refers to the primary (unique) key of primary key table.
(Note: In SQL/CLI, the result is implementation-defined.)
<p>
If only primary key table parameters are specified, the result set contains 
the primary key metadata of that table and all foreign keys that refer to it.
<p>
If only foreign key table parameters are specified, the result set contains 
all foreign keys metadata in that table and the primary keys to which they refer.
(Note: In SQL/CLI, the result includes unique keys too.)
<p>
Note: The support for the selection criteria, such as <code>$catalog</code>, is
driver specific.  If the driver doesn\'t support catalogs and/or
schemas, it may ignore these criteria.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd><code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present):
	(Because ODBC never includes unique keys, they define different columns in the
	result set than SQL/CLI. SQL/CLI column names are shown in parentheses)
<ol>
<li>PKTABLE_CAT    ( UK_TABLE_CAT      ):

The primary (unique) key table catalog identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>PKTABLE_SCHEM  ( UK_TABLE_SCHEM    ):

The primary (unique) key table schema identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>PKTABLE_NAME   ( UK_TABLE_NAME     ):

The primary (unique) key table identifier.

<li>PKCOLUMN_NAME  (UK_COLUMN_NAME    ):

The primary (unique) key column identifier.

<li>FKTABLE_CAT    ( FK_TABLE_CAT      ):

The foreign key table catalog identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>FKTABLE_SCHEM  ( FK_TABLE_SCHEM    ):

The foreign key table schema identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>FKTABLE_NAME   ( FK_TABLE_NAME     ):

The foreign key table identifier.

<li>FKCOLUMN_NAME  ( FK_COLUMN_NAME    ):

The foreign key column identifier.

<li>KEY_SEQ        ( ORDINAL_POSITION  ):

The column sequence number (starting with 1).

<li>UPDATE_RULE    ( UPDATE_RULE       ):

The referential action for the UPDATE rule.
The following codes are defined:
<ul>
<li>CASCADE (0)
<li>RESTRICT (1)
<li>SET NULL (2)
<li>NO ACTION (3)
<li>SET DEFAULT (4)
</ul>

<li>DELETE_RULE    ( DELETE_RULE       ):

The referential action for the DELETE rule.
The codes are the same as for UPDATE_RULE.

<li>FK_NAME        ( FK_NAME           ):

The foreign key name.

<li>PK_NAME        ( UK_NAME           ):

The primary (unique) key name.

<li>DEFERRABILITY  ( DEFERABILITY      ):

The deferrability of the foreign key constraint.
The following codes are defined:

<ul>
<li>INITIALLY DEFERRED   (5)
<li>INITIALLY IMMEDIATE  (6)
<li>NOT DEFERRABLE       (7)
</ul>

<li>               ( UNIQUE_OR_PRIMARY ):

This column is necessary if a driver includes all candidate (i.e. primary and
alternate) keys in the result set (as specified by SQL/CLI).
The value of this column is UNIQUE if the foreign key references an alternate
key and PRIMARY if the foreign key references a primary key, or it
may be undefined if the driver doesn\'t have access to the information.
</ol>

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Standards_Reference_Information\'>Standards Reference Information</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_func\'></a>
<h3>func</h3>
<pre>
func(@func_arguments, $func)
</pre><p>
<dl>
<dd>

Call the specified driver private method.
<p>
Note that the function
name is given as the <i>last</i> argument.
<p>
Also note that this method does not clear
a previous error ($DBI::err etc.), nor does it trigger automatic
error detection (RaiseError etc.), so the return
status and/or $h->err must be checked to detect errors.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>any value(s) returned by the specified function
</dd>
<dt><b>See Also:</b></dt><dd><code>install_method</code> in <a href=\'http://search.cpan.org/perldoc?DBI::DBD\'>DBI::DBD</a>, <a href=\'../../for directly installing and accessing driver-private methods..html\'>for directly installing and accessing driver-private methods.</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_get_info\'></a>
<h3>get_info</h3>
<pre>
get_info($info_type)
</pre><p>
<dl>
<dd>

Return metadata about the driver and data source capabilities, restrictions etc. 
For example
<pre>
  $database_version  = $dbh->get_info(  18 ); # SQL_DBMS_VER
  $max_select_tables = $dbh->get_info( 106 ); # SQL_MAXIMUM_TABLES_IN_SELECT
</pre>
The <a href=\'http://search.cpan.org/perldoc?DBI::Const::GetInfoType\'>DBI::Const::GetInfoType</a> module exports a <code>%GetInfoType</code>
hash that can be used to map info type names to numbers. For example:
<pre>
  use DBI::Const::GetInfoType qw(%GetInfoType);
  $database_version = $dbh->get_info( $GetInfoType{SQL_DBMS_VER} );
</pre>
The names are a merging of the ANSI and ODBC standards (which differ
in some cases).


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>a type and driver specific value, or <code>undef</code> for
	unknown or unimplemented information types.
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?DBI::Const::GetInfoType\'>DBI::Const::GetInfoType</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_last_insert_id\'></a>
<h3>last_insert_id</h3>
<pre>
last_insert_id($catalog, $schema, $table, $field)
</pre><p>
<dl>
<dd>

Return the database server assigned unique identifier for the
prior inserted row.
<p>
NOTE:
<ul>
<li>For some drivers the value may only available immediately after
the insert statement has executed (e.g., mysql, Informix).

<li>For some drivers the $catalog, $schema, $table, and $field parameters
are required, for others they are ignored (e.g., mysql).

<li>Drivers may return an indeterminate value if no insert has
been performed yet.

<li>For some drivers the value may only be available if placeholders
have <i>not</i> been used (e.g., Sybase, MS SQL). In this case the value
returned would be from the last non-placeholder insert statement.

<li>Some drivers may need driver-specific hints about how to get
the value. For example, being told the name of the database \'sequence\'
object that holds the value. Any such hints are passed as driver-specific
attributes in the \\%attr parameter.

<li>If the underlying database offers nothing better, some
drivers may attempt to implement this method by executing
"<code>select max($field) from $table</code>". Drivers using any approach
like this should issue a warning if <code>AutoCommit</code> is true because
it is generally unsafe - another process may have modified the table
between your insert and the select. For situations where you know
it is safe, such as when you have locked the table, you can silence
the warning by passing <code>Warn</code> => 0 in \\%attr.

<li>If no insert has been performed yet, or the last insert failed,
then the value is implementation defined.
</ul>


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>a value \'identifying\' the row just inserted. Typically a value assigned by 
	the database server to a column with an <i>auto_increment</i> or <i>serial</i> type.
	Returns undef if the driver does not support the method or can\'t determine the value.

</dd>
<dt><b>Since:</b></dt><dd>1.38.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_parse_trace_flag\'></a>
<h3>parse_trace_flag</h3>
<pre>
parse_trace_flag($trace_flag_name)
</pre><p>
<dl>
<dd>

Return the bit flag value for the specified trace flag name.
<p>
Drivers should override this method and
check if $trace_flag_name is a driver specific trace flag and, if
not, then call the DBI\'s default parse_trace_flag().


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>if $trace_flag_name is a valid flag name, the corresponding bit flag; otherwise, undef

</dd>
<dt><b>Since:</b></dt><dd>1.42
</dd>
</dl></dd></dl><hr>

<a name=\'_f_parse_trace_flags\'></a>
<h3>parse_trace_flags</h3>
<pre>
parse_trace_flags($trace_settings)
</pre><p>
<dl>
<dd>

Parse a string containing trace settings.
Uses the parse_trace_flag() method to process
trace flag names.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the corresponding integer value used internally by the DBI and drivers.

</dd>
<dt><b>Since:</b></dt><dd>1.42
</dd>
</dl></dd></dl><hr>

<a name=\'_f_ping\'></a>
<h3>ping</h3>
<pre>
ping()
</pre><p>
<dl>
<dd>
Is this database handle still connected to the database server ?
<p>
Attempts to determine, in a reasonably efficient way, if the database
server is still running and the connection to it is still working.
Individual drivers should implement this function in the most suitable
manner for their database engine.
<p>
The <i>default</i> implementation always returns true without
actually doing anything. Actually, it returns "<code>0 but true</code>" which is
true but zero. That way you can tell if the return value is genuine or
just the default.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>true if the connection is still usable; otherwise, false.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?Apache::DBI\'>Apache::DBI</a> one example usage.</dd>
</dl></dd></dl><hr>

<a name=\'_f_prepare\'></a>
<h3>prepare</h3>
<pre>
prepare($statement)
</pre><p>
<dl>
<dd>

Prepare a statement for later execution by the database
engine. Creates a Statement handle object ot be used to execute and
manage the resulting query.
<p>
Drivers for databases which cannot prepare a
statement will typically store the statement in the returned
handle and process it when on a later Statement handle <code>execute</code> call. Such drivers are
unlikely to provide statement metadata until after <code>execute()</code>
has been called.
<p>
Portable applications should not assume that a new statement can be
prepared and/or executed while still fetching results from a previous
statement.
<p>
Some command-line SQL tools require statement terminators, like a semicolon,
to indicate the end of a statement; such terminators should not normally
be required with the DBI.
<p>
The returned statement handle can be used to get the
statement metadata and invoke the <a href=\'DBD/_/st/execute.html#_f_DBD::_::st::execute\'>method</a> method. 


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>on success, a Statement handle object; otherwise, <code>undef</code>, with error information
	available via the err(), errstr(), and state() methods.
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'st.htmlst\'>package</a> package</dd>
</dl></dd></dl><hr>

<a name=\'_f_prepare_cached\'></a>
<h3>prepare_cached</h3>
<pre>
prepare_cached($statement)
</pre><p>
<dl>
<dd>
Locate a matching statement handle object in this object\'s
statement handle cache; if no match is found, prepare the statement 
and store the resulting statement handle object in
this database handle\'s statement cache.
<p>
If another call is made to <code>prepare_cached</code> with the same 
<code>$statement</code> and <code>%attr</code> parameter values,
the corresponding cached statement handle object will be returned without 
contacting the database server.
<p>
<i>Caveat emptor:</i> This caching can be useful in some applications,
but it can also cause problems and should be used with care.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>on success, a statement handle object; on failure, <code>undef</code>, with the error
	indication available via <a href=\'#_f_err\'>err</a>, <a href=\'#_f_errstrr\'>errstrr</a>, and <a href=\'#_f_state\'>state</a>.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI;pod.html#prepare_cached\'>prepare_cached()</a> in the DBI manual</dd>
</dl></dd></dl><hr>

<a name=\'_f_primary_key\'></a>
<h3>primary_key</h3>
<pre>
primary_key($catalog, $schema, $table)
</pre><p>
<dl>
<dd>
Get the column names that comprise the primary key of the specified table.
A simple interface to <a href=\'#_f_primary_key_info\'>primary_key_info</a>. 


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>(the column names that comprise the primary key of the specified table.
	The list is in primary key column sequence order.
	If there is no primary key, an empty list is returned.
)</dd>
</dl></dd></dl><hr>

<a name=\'_f_primary_key_info\'></a>
<h3>primary_key_info</h3>
<pre>
primary_key_info($catalog, $schema, $table)
</pre><p>
<dl>
<dd>

Create an active statement handle to return metadata about columns that 
make up the primary key for a table.
The arguments don\'t accept search patterns (unlike table_info()).
<p>
The statement handle will return one row per column.
If there is no primary key, the statement handle will fetch no rows.
<p>
Note: The support for the selection criteria, such as $catalog, is
driver specific.  If the driver doesn\'t support catalogs and/or
schemas, it may ignore these criteria.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd><code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present),
	ordered by TABLE_CAT, TABLE_SCHEM, TABLE_NAME, and KEY_SEQ:

<ol>
<li>TABLE_CAT: The catalog identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>TABLE_SCHEM: The schema identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>TABLE_NAME: The table identifier.

<li>COLUMN_NAME: The column identifier.

<li>KEY_SEQ: The column sequence number (starting with 1).
Note: This field is named B<ORDINAL_POSITION> in SQL/CLI.

<li>PK_NAME: The primary key constraint identifier.
This field is NULL (<code>undef</code>) if not applicable to the data source.
</ol>

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Standards_Reference_Information\'>Standards Reference Information</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_quote\'></a>
<h3>quote</h3>
<pre>
quote($value)
</pre><p>
<dl>
<dd>
Quote a string literal for use as a literal value in an SQL statement.
Special characters (such as quotation marks) are escaped,
and the required type of outer quotation marks are added.
<p>
Quote will probably <i>not</i> be able to deal with all possible input
(such as binary data or data containing newlines), and is not related in
any way with escaping or quoting shell meta-characters.
<p>
It is valid for the quote() method to return an SQL expression that
evaluates to the desired string. For example:
<pre>
  $quoted = $dbh->quote("one\\ntwo\\0three")
</pre>
may return something like:
<pre>
  CONCAT(\'one\', CHAR(12), \'two\', CHAR(0), \'three\')
</pre>
The quote() method should <i>not</i> be used with placeholders and bind values.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the properly quoted/escaped version of hte input parameter; if the input
	parameter was <code>undef</code>, the string <code>NULL</code> (without
	single quotation marks)
</dd>
</dl></dd></dl><hr>

<a name=\'_f_quote_identifier\'></a>
<h3>quote_identifier</h3>
<pre>
quote_identifier($catalog)
</pre><p>
<dl>
<dd>
Quote a database object identifier (table name etc.) for use in an SQL statement.
Special characters (such as double quotation marks) are escaped,
and the required type of outer quotation mark are added.
<p>
Undefined names are ignored and the remainder are quoted and then
joined together, typically with a dot (<code>.</code>) character.
<p>
If three names are supplied, the first is assumed to be a
catalog name and special rules may be applied based on what <a href=\'#_f_get_info\'>get_info</a>
returns for SQL_CATALOG_NAME_SEPARATOR (41) and SQL_CATALOG_LOCATION (114).


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the properly quoted/escaped object identifier string
</dd>
</dl></dd></dl><hr>

<a name=\'_f_rollback\'></a>
<h3>rollback</h3>
<pre>
rollback()
</pre><p>
<dl>
<dd>

Rollback (undo) the most recent series of uncommitted database
changes if the database supports transactions and AutoCommit is off.
<p>
If <code>AutoCommit</code> is on, issues a "rollback ineffective with AutoCommit" warning.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>true on success, <code>undef</code> on failure.
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Transactions\'>Transactions</a> in the DBI manual.</dd>
</dl></dd></dl><hr>

<a name=\'_f_selectall_arrayref\'></a>
<h3>selectall_arrayref</h3>
<pre>
selectall_arrayref($statement)
</pre><p>
<dl>
<dd>
Immediately execute a data returning statement, returning all result rows
as an array reference.
Combines <a href=\'#_f_prepare\'>prepare</a>, <a href=\'DBD/_/st/execute.html#_f_DBD::_::st::execute\'>method</a> and
<a href=\'DBD/_/st/fetchall_arrayref.html#_f_DBD::_::st::fetchall_arrayref\'>method</a> into a single call.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd><code>undef</code> on failure; otherwise, an array reference containing an array reference
	(or hash reference, if the <code>Slice</code> attribute is specified as an empty hash reference)
	for each row of data fetched. If <a href=\'DBD/_/st/fetchall_arrayref.html#_f_DBD::_::st::fetchall_arrayref\'>method</a> fails, returns with whatever data
	has been fetched thus far. Check <code>$sth-&gt;err</code>
	afterwards (or use the <a href=\'#_m_RaiseError\'>RaiseError</a> attribute) to discover if the data is
	complete or was truncated due to an error.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBD/_/st/fetchall_arrayref.html#_f_DBD::_::st::fetchall_arrayref\'>method</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_selectall_hashref\'></a>
<h3>selectall_hashref</h3>
<pre>
selectall_hashref($statement, $key_field)
</pre><p>
<dl>
<dd>
Immediately execute a data returning statement, returning all result rows
as a hash reference.
Combines <a href=\'#_f_prepare\'>prepare</a>, <a href=\'DBD/_/st/execute.html#_f_DBD::_::st::execute\'>method</a> and
<a href=\'DBD/_/st/fetchall_hashref.html#_f_DBD::_::st::fetchall_hashref\'>method</a> into a single call.

If a row has the same key as an earlier row then it replaces the earlier row.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd><code>undef</code> on failure; on success, a hash reference containing one entry, 
	at most, for each row, as returned by <a href=\'DBD/_/st/fetchall_hashref.html#_f_DBD::_::st::fetchall_hashref\'>method</a>.
	If <a href=\'DBD/_/st/fetchall_hashref.html#_f_DBD::_::st::fetchall_hashref\'>method</a> fails and
	<a href=\'#_m_RaiseError\'>RaiseError</a> is not set, returns with whatever data it
	has fetched thus far, with the error indication in <code>$DBI::err</code>.
	If multiple <code>$key_fields</code> were specified, the returned hash is a tree of
	nested hashes.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBD/_/st/fetchall_hashref.html#_f_DBD::_::st::fetchall_hashref\'>method</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_selectcol_arrayref\'></a>
<h3>selectcol_arrayref</h3>
<pre>
selectcol_arrayref($statement)
</pre><p>
<dl>
<dd>
Immediately execute a data returning statement, returning all result rows
as a hash reference.
Combines <a href=\'#_f_prepare\'>prepare</a>, <a href=\'DBD/_/st/execute.html#_f_DBD::_::st::execute\'>method</a>, and 
<a href=\'DBD/_/st/fetchrow_array.html#_f_DBD::_::st::fetchrow_array\'>method</a> (fetching only one column from all the rows),
into a single call.
<p>
This method defaults to pushing a single column
value (the first) from each row into the result array. However, 
if the \'<code>Columns</code>\' attribute is specified, it can
also push additional columns per row into the result array.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd><code>undef</code> on failure; on success, an array reference containing the values 
	of the first column from each row. If <a href=\'DBD/_/st/fetchrow_array.html#_f_DBD::_::st::fetchrow_array\'>method</a> fails and
	<a href=\'#_m_RaiseError\'>RaiseError</a> is not set, returns with whatever data it
	has fetched thus far, with the error indication in <code>$DBI::err</code>.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_selectrow_array\'></a>
<h3>selectrow_array</h3>
<pre>
selectrow_array($statement)
</pre><p>
<dl>
<dd>
Immediately execute a data returning statement, returning the first row of results
as an array.
Combines <a href=\'#_f_prepare\'>prepare</a>, <a href=\'DBD/_/st/execute.html#_f_DBD::_::st::execute\'>method</a> and
<a href=\'DBD/_/st/fetchrow_array.html#_f_DBD::_::st::fetchrow_array\'>method</a> into a single call.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>In scalar context, returns:</b><dd>either the value of the first or last column of the first returned row (don\'t do that);
	<code>undef</code> if there are no more rows <b>OR</B> if an error occurred. 
	As those <code>undef</code> cases can\'t be distinguished from an <code>undef</code> returned as
	a NULL first(or last) field value, this method should not be used in scalar context.
</dd>
<dt><b>In list context, returns:</b><dd>(on failure, <code>undef</code>; otherwise, an array reference of the row values.	
	Note that the array may be empty if no rows were returned.

)</dd>
</dl></dd></dl><hr>

<a name=\'_f_selectrow_arrayref\'></a>
<h3>selectrow_arrayref</h3>
<pre>
selectrow_arrayref($statement)
</pre><p>
<dl>
<dd>
Immediately execute a data returning statement, returning the first row of results
as an array reference.
Combines <a href=\'#_f_prepare\'>prepare</a>, <a href=\'DBD/_/st/execute.html#_f_DBD::_::st::execute\'>method</a> and
<a href=\'DBD/_/st/fetchrow_arrayref.html#_f_DBD::_::st::fetchrow_arrayref\'>method</a> into a single call.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>on failure, <code>undef</code>; otherwise, an array reference of the row values.	
	Note that the array may be empty if no rows were returned.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_selectrow_hashref\'></a>
<h3>selectrow_hashref</h3>
<pre>
selectrow_hashref($statement)
</pre><p>
<dl>
<dd>
Immediately execute a data returning statement, returning the first row of results
as a hash reference.
Combines <a href=\'#_f_prepare\'>prepare</a>, <a href=\'DBD/_/st/execute.html#_f_DBD::_::st::execute\'>method</a> and
<a href=\'DBD/_/st/fetchrow_hashref.html#_f_DBD::_::st::fetchrow_hashref\'>method</a> into a single call.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>on failure, <code>undef</code>; otherwise, a hash reference mapping field names to their row values.	
	Note that the hash may be empty if no rows were returned.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_set_err\'></a>
<h3>set_err</h3>
<pre>
set_err($err, $errstr)
</pre><p>
<dl>
<dd>

Set the <code>err</code>, <code>errstr</code>, and <code>state</code> values for the handle.
If the <a href=\'#_m_HandleSetErr\'>HandleSetErr</a> attribute holds a reference to a subroutine
it is called first. The subroutine can alter the $err, $errstr, $state,
and $method values. See <a href=\'#_m_HandleSetErr\'>HandleSetErr</a> for full details.
If the subroutine returns a true value then the handle <code>err</code>,
<code>errstr</code>, and <code>state</code> values are not altered and set_err() returns
an empty list (it normally returns $rv which defaults to undef, see below).
<p>
Setting <code>$err</code> to a <i>true</i> value indicates an error and will trigger
the normal DBI error handling mechanisms, such as <code>RaiseError</code> and
<code>HandleError</code>, if they are enabled, when execution returns from
the DBI back to the application.
<p>
Setting <code>$err</code> to <code>""</code> indicates an \'information\' state, and setting
it to <code>"0"</code> indicates a \'warning\' state. Setting <code>$err</code> to <code>undef</code>
also sets <code>$errstr</code> to undef, and <code>$state</code> to <code>""</code>, irrespective
of the values of the $errstr and $state parameters.
<p>
The $method parameter provides an alternate method name for the
<code>RaiseError</code>/<code>PrintError</code>/<code>PrintWarn</code> error string instead of
the fairly unhelpful \'<code>set_err</code>\'.
<p>
Some special rules apply if the <code>err</code> or <code>errstr</code>
values for the handle are <i>already</i> set.
<p>
If <code>errstr</code> is true then: "<code> [err was %s now %s]</code>" is appended if $err is
true and <code>err</code> is already true and the new err value differs from the original
one. Similarly "<code> [state was %s now %s]</code>" is appended if $state is true and <code>state</code> is
already true and the new state value differs from the original one. Finally
"<code>\\n</code>" and the new $errstr are appended if $errstr differs from the existing
errstr value. Obviously the <code>%s</code>\'s above are replaced by the corresponding values.
<p>
The handle <code>err</code> value is set to $err if: $err is true; or handle
<code>err</code> value is undef; or $err is defined and the length is greater
than the handle <code>err</code> length. The effect is that an \'information\'
state only overrides undef; a \'warning\' overrides undef or \'information\',
and an \'error\' state overrides anything.
<p>
The handle <code>state</code> value is set to $state if $state is true and
the handle <code>err</code> value was set (by the rules above).
<p>
This method is typically only used by DBI drivers and DBI subclasses.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the $rv value, if specified; else undef.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_state\'></a>
<h3>state</h3>
<pre>
state()
</pre><p>
<dl>
<dd>

Return the standard SQLSTATE five character format code for the prior driver
method.
The success code <code>00000</code> is translated to any empty string
(false). If the driver does not support SQLSTATE (and most don\'t),
then state() will return <code>S1000</code> (General Error) for all errors.
<p>
The driver is free to return any value via <code>state</code>, e.g., warning
codes, even if it has not declared an error by returning a true value
via the err() method described above.
<p>
Should not be used to test for errors as drivers may return a 
\'success with information\' or warning state code via state() for 
methods that have not \'failed\'.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>if state is currently successful, an empty string; else,
	a five character SQLSTATE code.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_statistics_info\'></a>
<h3>statistics_info</h3>
<pre>
statistics_info($catalog, $schema, $table, $unique_only, $quick)
</pre><p>
<dl>
<dd>

Create an active statement handle returning statistical
information about a table and its indexes.
<p>
<b>Warning:</b> This method is experimental and may change.
<p>
The arguments don\'t accept search patterns (unlike <a href=\'#_f_table_info\'>table_info</a>).
<p>
The statement handle will return at most one row per column name per index,
plus at most one row for the entire table itself, ordered by NON_UNIQUE, TYPE,
INDEX_QUALIFIER, INDEX_NAME, and ORDINAL_POSITION.
<p>
Note: The support for the selection criteria, such as $catalog, is
driver specific.  If the driver doesn\'t support catalogs and/or
schemas, it may ignore these criteria.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd><code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present):

<ol>
<li>TABLE_CAT: The catalog identifier.

This field is NULL (<code>undef</code>) if not applicable to the data source,
which is often the case.  This field is empty if not applicable to the
table.

<li>TABLE_SCHEM: The schema identifier.

This field is NULL (<code>undef</code>) if not applicable to the data source,
and empty if not applicable to the table.

<li>TABLE_NAME: The table identifier.

<li>NON_UNIQUE: Unique index indicator.

Returns 0 for unique indexes, 1 for non-unique indexes

<li>INDEX_QUALIFIER: Index qualifier identifier.

The identifier that is used to qualify the index name when doing a
<code>DROP INDEX</code>; NULL (<code>undef</code>) is returned if an index qualifier is not
supported by the data source.
If a non-NULL (defined) value is returned in this column, it must be used
to qualify the index name on a <code>DROP INDEX</code> statement; otherwise,
the TABLE_SCHEM should be used to qualify the index name.

<li>INDEX_NAME: The index identifier.

<li>TYPE: The type of information being returned.  Can be any of the
following values: \'table\', \'btree\', \'clustered\', \'content\', \'hashed\',
or \'other\'.

In the case that this field is \'table\', all fields
other than TABLE_CAT, TABLE_SCHEM, TABLE_NAME, TYPE,
CARDINALITY, and PAGES will be NULL (<code>undef</code>).

<li>ORDINAL_POSITION: Column sequence number (starting with 1).

<li>COLUMN_NAME: The column identifier.

<li>ASC_OR_DESC: Column sort sequence.

<code>A</code> for Ascending, <code>D</code> for Descending, or NULL (<code>undef</code>) if
not supported for this index.

<li>CARDINALITY: Cardinality of the table or index.

For indexes, this is the number of unique values in the index.
For tables, this is the number of rows in the table.
If not supported, the value will be NULL (<code>undef</code>).

<li>PAGES: Number of storage pages used by this table or index.

If not supported, the value will be NULL (<code>undef</code>).

<li>FILTER_CONDITION: The index filter condition as a string.

If the index is not a filtered index, or it cannot be determined
whether the index is a filtered index, this value is NULL (<code>undef</code>).
If the index is a filtered index, but the filter condition
cannot be determined, this value is the empty string <code>\'\'</code>.
Otherwise it will be the literal filter condition as a string,
such as <code>SALARY <= 4500</code>.
</ol>

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Standards_Reference_Information\'>Standards Reference Information</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_swap_inner_handle\'></a>
<h3>swap_inner_handle</h3>
<pre>
swap_inner_handle($h2)
</pre><p>
<dl>
<dd>

Swap the internals of 2 handle objects.
Brain transplants for handles. You don\'t need to know about this
unless you want to become a handle surgeon.
<p>
A DBI handle is a reference to a tied hash. A tied hash has an
<i>inner</i> hash that actually holds the contents.  This
method swaps the inner hashes between two handles. The $h1 and $h2
handles still point to the same tied hashes, but what those hashes
are tied to is swapped.  In effect $h1 <i>becomes</i> $h2 and
vice-versa. This is powerful stuff, expect problems. Use with care.
<p>
As a small safety measure, the two handles, $h1 and $h2, have to
share the same parent unless $allow_reparent is true.
<p>
Here\'s a quick kind of \'diagram\' as a worked example to help think about what\'s
happening:
<pre>
    Original state:
            dbh1o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh2o -> dbh2i

    swap_inner_handle dbh1o with dbh2o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i

    create new sth from dbh1o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthBo -> sthBi(dbh2i)

    swap_inner_handle sthAo with sthBo:
            dbh2o -> dbh1i
            sthBo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthAo -> sthBi(dbh2i)
</pre>


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>true if the swap succeeded; otherwise, undef
</dd>
<dt><b>Since:</b></dt><dd>1.44
</dd>
</dl></dd></dl><hr>

<a name=\'_f_table_info\'></a>
<h3>table_info</h3>
<pre>
table_info($catalog, $schema, $table, $type)
</pre><p>
<dl>
<dd>

Create an active statement handle to return table metadata.
<p>
The arguments $catalog, $schema and $table may accept search patterns
according to the database/driver, for example: $table = \'%FOO%\';
The underscore character (\'<code>_</code>\') matches any single character,
while the percent character (\'<code>%</code>\') matches zero or more
characters.
<p>
Some drivers may return additional information:
<ul>
<li>If the value of $catalog is \'%\' and $schema and $table name
are empty strings, the result set contains a list of catalog names.
For example:
<pre>
  $sth = $dbh->table_info(\'%\', \'\', \'\');
</pre>

<li>If the value of $schema is \'%\' and $catalog and $table are empty
strings, the result set contains a list of schema names.

<li>If the value of $type is \'%\' and $catalog, $schema, and $table are all
empty strings, the result set contains a list of table types.
</ul>

Drivers which do not support one or more of the selection filter
parameters may return metadata for more tables than requested, which may
require additional filtering by the application.
<p>
Note that this method can be expensive, and may return a large amount of data.
Best practice is to apply the most specific filters possible.
Also, some database might not return rows for all tables, and,
if the search criteria do not match any tables, the returned statement handle may return no rows.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd><code>undef</code> on failure; on success, a Statement handle object. The returned statement handle 
	has at least the following fields (other fields, following these, may also be present):
<ol>
<li>TABLE_CAT: Table catalog identifier. This field is NULL (<code>undef</code>) if not
applicable to the data source, which is usually the case. This field
is empty if not applicable to the table.

<li>TABLE_SCHEM: The name of the schema containing the TABLE_NAME value.
This field is NULL (<code>undef</code>) if not applicable to data source, and
empty if not applicable to the table.

<li>TABLE_NAME: Name of the table (or view, synonym, etc).

<li>TABLE_TYPE: One of the following: "TABLE", "VIEW", "SYSTEM TABLE",
"GLOBAL TEMPORARY", "LOCAL TEMPORARY", "ALIAS", "SYNONYM" or a type
identifier that is specific to the data source.

<li>REMARKS: A description of the table. May be NULL (<code>undef</code>).
</ol>

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Standards_Reference_Information\'>Standards Reference Information</a> in the DBI manual</dd>
</dl></dd></dl><hr>

<a name=\'_f_tables\'></a>
<h3>tables</h3>
<pre>
tables($catalog, $schema, $table, $type)
</pre><p>
<dl>
<dd>
Get the list of matching table names.
A simple interface to <a href=\'#_f_table_info\'>table_info</a>. 
<p>
If <code>$dbh-&gt;get_info(SQL_IDENTIFIER_QUOTE_CHAR)</code> returns true,
the table names are constructed and quoted by <a href=\'#_f_quote_identifier\'>quote_identifier</a>
to ensure they are usable even if they contain whitespace or reserved
words etc.; therefore. the returned table names  may include quote characters.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>(the matching table names, possibly including a catalog/schema prefix.
)</dd>
</dl></dd></dl><hr>

<a name=\'_f_take_imp_data\'></a>
<h3>take_imp_data</h3>
<pre>
take_imp_data()
</pre><p>
<dl>
<dd>

Leaves this Database handle object in an almost dead, zombie-like, state.
Detaches the underlying database API connection data from the DBI handle.
After calling this method, all other methods except <code>DESTROY</code>
will generate a warning and return undef.
<p>
Why would you want to do this? You don\'t, forget I even mentioned it.
Unless, that is, you\'re implementing something advanced like a
multi-threaded connection pool. See <a href=\'http://search.cpan.org/perldoc?DBI::Pool\'>DBI::Pool</a>.
<p>
The returned value can be passed as a <code>dbi_imp_data</code> attribute
to a later <a href=\'DBI/connect.html#_f_DBI::connect\'>method</a> call, even in a separate thread in the same
process, where the driver can use it to \'adopt\' the existing
connection that the implementation data was taken from.
<p>
Some things to keep in mind...
<ul>
<li>the returned value holds the only reference to the underlying
database API connection data. That connection is still \'live\' and
won\'t be cleaned up properly unless the value is used to create
a new database handle object which is then allowed to disconnect() normally.

<li>using the same returned value to create more than one other new
database handle object at a time may well lead to unpleasant problems. Don\'t do that.

<li>Any child statement handles are effectively destroyed when take_imp_data() is
called.
</ul>


<p>
<dd><dl>
<dt><b>Returns:</b><dd>a binary string of raw implementation data from the driver which
	describes the current database connection. 

</dd>
<dt><b>Since:</b></dt><dd>1.36
</dd>
</dl></dd></dl><hr>

<a name=\'_f_trace\'></a>
<h3>trace</h3>
<pre>
trace($trace_setting)
</pre><p>
<dl>
<dd>

Set the trace settings for the handle object. 
Also can be used to change where trace output is sent.
<p>
A similar method, <code>DBI-&gt;trace</code>, sets the global default trace
settings.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the previous $trace_setting value
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?DBI\'>DBI</a> manual TRACING section for full details about DBI\'s, <a href=\'../../tracing facilities..html\'>tracing facilities.</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_trace_msg\'></a>
<h3>trace_msg</h3>
<pre>
trace_msg($message_text)
</pre><p>
<dl>
<dd>

Write a trace message to the handle object\'s current trace output.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?DBI\'>DBI</a> manual TRACING section for full details about DBI\'s, <a href=\'../../tracing facilities..html\'>tracing facilities.</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_type_info\'></a>
<h3>type_info</h3>
<pre>
type_info($data_type)
</pre><p>
<dl>
<dd>
Get the data type metadata for the specified <code>$data_type</code>.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>In scalar context, returns:</b><dd>the first (best) matching metadata element is returned as a hash reference

</dd>
<dt><b>In list context, returns:</b><dd>(the hash references containing metadata about one or more
	variants of the specified type. The list is ordered by <code>DATA_TYPE</code> first and
	then by how closely each type maps to the corresponding ODBC SQL data
	type, closest first. If <code>$data_type</code> is <code>undef</code> or <code>SQL_ALL_TYPES</code>, 
	all data type variants supported by the database and driver are returned.
	If <code>$data_type</code> is an array reference, returns the metadata for the <i>first</i> 
	type in the array that has any matches.
	The keys of the returned hash follow the same letter case conventions as the
	rest of the DBI 
	(see <a href=\'DBI.pod.html#Naming_Conventions_and_Name_Space\'>Naming Conventions and Name Space</a>). The
	following uppercase items should always exist, though may be undef:
	<ul>
	<li>TYPE_NAME (string)

	Data type name for use in CREATE TABLE statements etc.

	<li>DATA_TYPE (integer)

	SQL data type number.

	<li>COLUMN_SIZE (integer)

	For numeric types, this is either the total number of digits (if the
	NUM_PREC_RADIX value is 10) or the total number of bits allowed in the
	column (if NUM_PREC_RADIX is 2).
	<p>
	For string types, this is the maximum size of the string in characters.
	<p>
	For date and interval types, this is the maximum number of characters
	needed to display the value.

	<li>LITERAL_PREFIX (string)

	Characters used to prefix a literal. A typical prefix is "<code>\'</code>" for characters,
	or possibly "<code>0x</code>" for binary values passed as hexadecimal.  NULL (<code>undef</code>) is
	returned for data types for which this is not applicable.

	<li>LITERAL_SUFFIX (string)

	Characters used to suffix a literal. Typically "<code>\'</code>" for characters.
	NULL (<code>undef</code>) is returned for data types where this is not applicable.

	<li>CREATE_PARAMS (string)

	Parameter names for data type definition. For example, <code>CREATE_PARAMS</code> for a
	<code>DECIMAL</code> would be "<code>precision,scale</code>" if the DECIMAL type should be
	declared as <code>DECIMAL(</code><i>precision,scale</i><code>)</code> where <i>precision</i> and <i>scale</i>
	are integer values.  For a <code>VARCHAR</code> it would be "<code>max length</code>".
	NULL (<code>undef</code>) is returned for data types for which this is not applicable.

	<li>NULLABLE (integer)

	Indicates whether the data type accepts a NULL value:
	<ul>
	<li>0 or an empty string = no
	<li>1 = yes
	<li>2  = unknown
	</ul>

	<li>CASE_SENSITIVE (boolean)

	Indicates whether the data type is case sensitive in collations and
	comparisons.

	<li>SEARCHABLE (integer)

	Indicates how the data type can be used in a WHERE clause, as
	follows:
	<ul>
	<li>0 - Cannot be used in a WHERE clause
	<li>1 - Only with a LIKE predicate
	<li>2 - All comparison operators except LIKE
	<li>3 - Can be used in a WHERE clause with any comparison operator
	</ul>

	<li>UNSIGNED_ATTRIBUTE (boolean)

	Indicates whether the data type is unsigned.  NULL (<code>undef</code>) is returned
	for data types for which this is not applicable.

	<li>FIXED_PREC_SCALE (boolean)

	Indicates whether the data type always has the same precision and scale
	(such as a money type).  NULL (<code>undef</code>) is returned for data types
	for which this is not applicable.

	<li>AUTO_UNIQUE_VALUE (boolean)

	Indicates whether a column of this data type is automatically set to a
	unique value whenever a new row is inserted.  NULL (<code>undef</code>) is returned
	for data types for which this is not applicable.

	<li>LOCAL_TYPE_NAME (string)

	Localized version of the <code>TYPE_NAME</code> for use in dialog with users.
	NULL (<code>undef</code>) is returned if a localized name is not available (in which
	case <code>TYPE_NAME</code> should be used).

	<li>MINIMUM_SCALE (integer)

	The minimum scale of the data type. If a data type has a fixed scale,
	then <code>MAXIMUM_SCALE</code> holds the same value.  NULL (<code>undef</code>) is returned for
	data types for which this is not applicable.

	<li>MAXIMUM_SCALE (integer)

	The maximum scale of the data type. If a data type has a fixed scale,
	then <code>MINIMUM_SCALE</code> holds the same value.  NULL (<code>undef</code>) is returned for
	data types for which this is not applicable.

	<li>SQL_DATA_TYPE (integer)

	This column is the same as the <code>DATA_TYPE</code> column, except for interval
	and datetime data types.  For interval and datetime data types, the
	<code>SQL_DATA_TYPE</code> field will return <code>SQL_INTERVAL</code> or <code>SQL_DATETIME</code>, and the
	<code>SQL_DATETIME_SUB</code> field below will return the subcode for the specific
	interval or datetime data type. If this field is NULL, then the driver
	does not support or report on interval or datetime subtypes.

	<li>SQL_DATETIME_SUB (integer)

	For interval or datetime data types, where the <code>SQL_DATA_TYPE</code>
	field above is <code>SQL_INTERVAL</code> or <code>SQL_DATETIME</code>, this field will
	hold the <i>subcode</i> for the specific interval or datetime data type.
	Otherwise it will be NULL (<code>undef</code>).
	<p>
	Although not mentioned explicitly in the standards, it seems there
	is a simple relationship between these values:
	<pre>
	DATA_TYPE == (10 * SQL_DATA_TYPE) + SQL_DATETIME_SUB
	</pre>

	<li>NUM_PREC_RADIX (integer)

	The radix value of the data type. For approximate numeric types,
	<code>NUM_PREC_RADIX</code>
	contains the value 2 and <code>COLUMN_SIZE</code> holds the number of bits. For
	exact numeric types, <code>NUM_PREC_RADIX</code> contains the value 10 and <code>COLUMN_SIZE</code> holds
	the number of decimal digits. NULL (<code>undef</code>) is returned either for data types
	for which this is not applicable or if the driver cannot report this information.

	<li>INTERVAL_PRECISION (integer)

	The interval leading precision for interval types. NULL is returned
	either for data types for which this is not applicable or if the driver
	cannot report this information.
	</ul>

)</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Standards_Reference_Information\'>Standards Reference Information</a> in the DBI manual</dd>
</dl></dd></dl><hr>

<a name=\'_f_type_info_all\'></a>
<h3>type_info_all</h3>
<pre>
type_info_all()
</pre><p>
<dl>
<dd>

Return metadata for all supported data types.
<p>
The type_info_all() method is not normally used directly.
The <a href=\'#_f_type_info\'>type_info</a> method provides a more usable and useful interface
to the data.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>an (read-only) array reference containing information about each data
	type variant supported by the database and driver.
	The array element is a reference to an \'index\' hash of <code>Name =</code>&gt; <code>Index</code> pairs.
	Subsequent array elements are references to arrays, one per supported data type variant. 
	The leading index hash defines the names and order of the fields within the arrays that follow it.
	For example:
<pre>
  $type_info_all = [
    {   TYPE_NAME         => 0,
	DATA_TYPE         => 1,
	COLUMN_SIZE       => 2,     # was PRECISION originally
	LITERAL_PREFIX    => 3,
	LITERAL_SUFFIX    => 4,
	CREATE_PARAMS     => 5,
	NULLABLE          => 6,
	CASE_SENSITIVE    => 7,
	SEARCHABLE        => 8,
	UNSIGNED_ATTRIBUTE=> 9,
	FIXED_PREC_SCALE  => 10,    # was MONEY originally
	AUTO_UNIQUE_VALUE => 11,    # was AUTO_INCREMENT originally
	LOCAL_TYPE_NAME   => 12,
	MINIMUM_SCALE     => 13,
	MAXIMUM_SCALE     => 14,
	SQL_DATA_TYPE     => 15,
	SQL_DATETIME_SUB  => 16,
	NUM_PREC_RADIX    => 17,
	INTERVAL_PRECISION=> 18,
    },
    [ \'VARCHAR\', SQL_VARCHAR,
	undef, "\'","\'", undef,0, 1,1,0,0,0,undef,1,255, undef
    ],
    [ \'INTEGER\', SQL_INTEGER,
	undef,  "", "", undef,0, 0,1,0,0,0,undef,0,  0, 10
    ],
  ];
</pre>
Multiple elements may use the same <code>DATA_TYPE</code> value
if there are different ways to spell the type name and/or there
are variants of the type with different attributes (e.g., with and
without <code>AUTO_UNIQUE_VALUE</code> set, with and without <code>UNSIGNED_ATTRIBUTE</code>, etc).
<p>
The datatype entries are ordered by <code>DATA_TYPE</code> value first, then by how closely each
type maps to the corresponding ODBC SQL data type, closest first.
<p>
The meaning of the fields is described in the documentation for
the <a href=\'#_f_type_info\'>type_info</a> method.
<p>
An \'index\' hash is provided so you don\'t need to rely on index
values defined above.  However, using DBD::ODBC with some old ODBC
drivers may return older names, shown as comments in the example above.
Another issue with the index hash is that the lettercase of the
keys is not defined. It is usually uppercase, as show here, but
drivers may return names with any lettercase.
<p>
Drivers may return extra driver-specific data type entries.
</dd>
</dl></dd></dl><hr>

<small>
<center>
<i>Generated by POD::ClassDoc 1.01 on Sat Aug  4 14:56:18 2007</i>
</center>
</small>
</body>
</html>
',
                            't/lib/DBI.pm',
                            2663,
                            {
                              'errstr' => [
                                            't/lib/DBI.pm',
                                            2668
                                          ],
                              'parse_trace_flag' => [
                                                      't/lib/DBI.pm',
                                                      2668
                                                    ],
                              'get_info' => [
                                              't/lib/DBI.pm',
                                              2668
                                            ],
                              'take_imp_data' => [
                                                   't/lib/DBI.pm',
                                                   2668
                                                 ],
                              'err' => [
                                         't/lib/DBI.pm',
                                         2668
                                       ],
                              'disconnect' => [
                                                't/lib/DBI.pm',
                                                2668
                                              ],
                              'state' => [
                                           't/lib/DBI.pm',
                                           2668
                                         ],
                              'selectrow_array' => [
                                                     't/lib/DBI.pm',
                                                     4019
                                                   ],
                              'trace' => [
                                           't/lib/DBI.pm',
                                           2668
                                         ],
                              'quote_identifier' => [
                                                      't/lib/DBI.pm',
                                                      3796
                                                    ],
                              'tables' => [
                                            't/lib/DBI.pm',
                                            4376
                                          ],
                              'clone' => [
                                           't/lib/DBI.pm',
                                           3741
                                         ],
                              'quote' => [
                                           't/lib/DBI.pm',
                                           3864
                                         ],
                              'statistics_info' => [
                                                     't/lib/DBI.pm',
                                                     2668
                                                   ],
                              'selectrow_arrayref' => [
                                                        't/lib/DBI.pm',
                                                        3991
                                                      ],
                              'begin_work' => [
                                                't/lib/DBI.pm',
                                                4314
                                              ],
                              'type_info' => [
                                               't/lib/DBI.pm',
                                               4564
                                             ],
                              'last_insert_id' => [
                                                    't/lib/DBI.pm',
                                                    2668
                                                  ],
                              'foreign_key_info' => [
                                                      't/lib/DBI.pm',
                                                      2668
                                                    ],
                              'primary_key' => [
                                                 't/lib/DBI.pm',
                                                 4342
                                               ],
                              'commit' => [
                                            't/lib/DBI.pm',
                                            2668
                                          ],
                              'ping' => [
                                          't/lib/DBI.pm',
                                          4286
                                        ],
                              'selectall_arrayref' => [
                                                        't/lib/DBI.pm',
                                                        4076
                                                      ],
                              'type_info_all' => [
                                                   't/lib/DBI.pm',
                                                   2668
                                                 ],
                              'trace_msg' => [
                                               't/lib/DBI.pm',
                                               2668
                                             ],
                              'do' => [
                                        't/lib/DBI.pm',
                                        3926
                                      ],
                              'selectcol_arrayref' => [
                                                        't/lib/DBI.pm',
                                                        4174
                                                      ],
                              'prepare_cached' => [
                                                    't/lib/DBI.pm',
                                                    4241
                                                  ],
                              'rollback' => [
                                              't/lib/DBI.pm',
                                              2668
                                            ],
                              'column_info' => [
                                                 't/lib/DBI.pm',
                                                 2668
                                               ],
                              'table_info' => [
                                                't/lib/DBI.pm',
                                                2668
                                              ],
                              'primary_key_info' => [
                                                      't/lib/DBI.pm',
                                                      2668
                                                    ],
                              'parse_trace_flags' => [
                                                       't/lib/DBI.pm',
                                                       2668
                                                     ],
                              'prepare' => [
                                             't/lib/DBI.pm',
                                             2668
                                           ],
                              'swap_inner_handle' => [
                                                       't/lib/DBI.pm',
                                                       2668
                                                     ],
                              'data_sources' => [
                                                  't/lib/DBI.pm',
                                                  4629
                                                ],
                              'selectall_hashref' => [
                                                       't/lib/DBI.pm',
                                                       4125
                                                     ],
                              'set_err' => [
                                             't/lib/DBI.pm',
                                             2668
                                           ],
                              'can' => [
                                         't/lib/DBI.pm',
                                         2668
                                       ],
                              'selectrow_hashref' => [
                                                       't/lib/DBI.pm',
                                                       3966
                                                     ],
                              'func' => [
                                          't/lib/DBI.pm',
                                          2668
                                        ]
                            }
                          ],
          'DBD::_::dr' => [
                            '
<html>
<head>
<title>DBD::_::dr</title>
</head>
<body>
<table width=\'100%\' border=0 CELLPADDING=\'0\' CELLSPACING=\'3\'>
<TR>
<TD VALIGN=\'top\' align=left><FONT SIZE=\'-2\'>
 SUMMARY:&nbsp;CONSTR&nbsp;|&nbsp;<a href=\'#method_summary\'>METHOD</a>
 </FONT></TD>
<TD VALIGN=\'top\' align=right><FONT SIZE=\'-2\'>
DETAIL:&nbsp;CONSTR&nbsp;|&nbsp;<a href=\'#method_detail\'>METHOD</a>
</FONT></TD>
</TR>
</table><hr>
<h2>Class DBD::_::dr</h2>

<hr>


Driver handle. The parent object for database handles; acts as a factory
for database handles.


<p>

<dl>

<a name=\'members\'></a>
<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'><th colspan=2 align=left><font size=\'+2\'>Public Instance Members</font></th></tr>
<tr><td align=right valign=top><a name=\'_m_(array ref, read-only) a reference to an array of all
	connection handles created by this handle which are still accessible.  The
	contents of the array are weak-refs and will become undef when the
	handle goes out of scope. <code>undef</code> if your Perl version does not support weak
	references (check the <a href=\'http://search.cpan.org/perldoc?Scalar::Util|Scalar::Util\'>Scalar::Util|Scalar::Util</a> module).

\'></a><code>(array ref, read-only) a reference to an array of all
	connection handles created by this handle which are still accessible.  The
	contents of the array are weak-refs and will become undef when the
	handle goes out of scope. <code>undef</code> if your Perl version does not support weak
	references (check the <a href=\'http://search.cpan.org/perldoc?Scalar::Util|Scalar::Util\'>Scalar::Util|Scalar::Util</a> module).

</code></td><td align=left valign=top>(boolean, inherited) Sets both <a href=\'#_m_TaintIn\'>TaintIn</a> and <a href=\'#_m_TaintOut\'>TaintOut</a>;
	returns a true value if and only if <a href=\'#_m_TaintIn\'>TaintIn</a> and <a href=\'#_m_TaintOut\'>TaintOut</a> are
	both set to true values.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When false (the default), fetching a long value that
	needs to be truncated (usually due to exceeding <code>LongReadLen</code>) will cause the fetch to fail.
	(Applications should always be sure to
	check for errors after a fetch loop in case an error, such as a divide
	by zero or long field truncation, caused the fetch to terminate
	prematurely.)
	<p>
	If a fetch fails due to a long field truncation when <code>LongTruncOk</code> is
	false, many drivers will allow you to continue fetching further rows.

\'></a><code>(boolean, inherited) When false (the default), fetching a long value that
	needs to be truncated (usually due to exceeding <code>LongReadLen</code>) will cause the fetch to fail.
	(Applications should always be sure to
	check for errors after a fetch loop in case an error, such as a divide
	by zero or long field truncation, caused the fetch to terminate
	prematurely.)
	<p>
	If a fetch fails due to a long field truncation when <code>LongTruncOk</code> is
	false, many drivers will allow you to continue fetching further rows.

</code></td><td align=left valign=top>(boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then all the arguments
	to most DBI method calls are checked for being tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then most data fetched
	from the database is considered tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.
	<p>
	Currently only fetched data is tainted. It is possible that the results
	of other DBI method calls, and the value of fetched attributes, may
	also be tainted in future versions.

\'></a><code>(boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then most data fetched
	from the database is considered tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.
	<p>
	Currently only fetched data is tainted. It is possible that the results
	of other DBI method calls, and the value of fetched attributes, may
	also be tainted in future versions.

</code></td><td align=left valign=top>(boolean, inherited) When true (default false), errors raise exceptions rather
	than simply returning error codes in the normal way.
	Exceptions are raised via a <code>die("$class $method failed: $DBI::errstr")</code>,
	where <code>$class</code> is the driver class and <code>$method</code> is the name of the method
	that failed.
	<p>
	If <code>PrintError</code> is also on, the <code>PrintError</code> is done first.
	<p>
	Typically <code>RaiseError</code> is used in conjunction with <code>eval { ... }</code>
	to catch the exception that\'s been thrown and followed by an
	<code>if ($@) { ... }</code> block to handle the caught exception.
	For example:
<pre>
  eval {
    ...
    $sth->execute();
    ...
  };
  if ($@) {
    # $sth->err and $DBI::err will be true if error was from DBI
    warn $@; # print the error
    ... # do whatever you need to deal with the error
  }
</pre>

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true (default false), trailing space characters are 
	trimmed from returned fixed width character (CHAR) fields. No other field types are affected, 
	even where field values have trailing spaces.

\'></a><code>(boolean, inherited) When true (default false), trailing space characters are 
	trimmed from returned fixed width character (CHAR) fields. No other field types are affected, 
	even where field values have trailing spaces.

</code></td><td align=left valign=top>(boolean, inherited) When true, forces errors to generate warnings 
	(in addition to returning error codes in the normal way)
	via a <code>warn("$class $method failed: $DBI::errstr")</code>, where <code>$class</code>
	is the driver class and <code>$method</code> is the name of the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintError</code> "on".
	<p>
	If desired, the warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true, indicates that this handle and it\'s children will 
	not make any changes to the database.
	<p>
	The exact definition of \'read only\' is rather fuzzy. See individual driver documentation for specific details.
	<p>
	If the driver can make the handle truly read-only (by issuing a statement like
	"<code>set transaction read only</code>", for example) then it should.
	Otherwise the attribute is simply advisory.
	<p>
	A driver can set the <code>ReadOnly</code> attribute itself to indicate that the data it
	is connected to cannot be changed for some reason.
	<p>
	Library modules and proxy drivers can use the attribute to influence their behavior.
	For example, the DBD::Gofer driver considers the <code>ReadOnly</code> attribute when
	making a decison about whether to retry an operation that failed.
	<p>
	The attribute should be set to 1 or 0 (or undef). Other values are reserved.
\'></a><code>(boolean, inherited) When true, indicates that this handle and it\'s children will 
	not make any changes to the database.
	<p>
	The exact definition of \'read only\' is rather fuzzy. See individual driver documentation for specific details.
	<p>
	If the driver can make the handle truly read-only (by issuing a statement like
	"<code>set transaction read only</code>", for example) then it should.
	Otherwise the attribute is simply advisory.
	<p>
	A driver can set the <code>ReadOnly</code> attribute itself to indicate that the data it
	is connected to cannot be changed for some reason.
	<p>
	Library modules and proxy drivers can use the attribute to influence their behavior.
	For example, the DBD::Gofer driver considers the <code>ReadOnly</code> attribute when
	making a decison about whether to retry an operation that failed.
	<p>
	The attribute should be set to 1 or 0 (or undef). Other values are reserved.
</code></td><td align=left valign=top>(boolean, inherited) controls printing of warnings issued
	by this handle.  When true, DBI checks method calls to see if a warning condition has 
	been set. If so, DBI effectively does a <code>warn("$class $method warning: $DBI::errstr")</code>
	where <code>$class</code> is the driver class and <code>$method</code> is the name of
	the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintWarn</code> "on" if $^W is true.
	<p>
	Warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.
	<p>
	See also <a href=\'#_f_set_err\'>set_err</a> for how warnings are recorded and <a href=\'#_m_HandleSetErr\'>HandleSetErr</a>
	for how to influence it.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) enables useful warnings (which
	can be intercepted using the <code>$SIG{__WARN__}</code> hook) for certain bad practices;

\'></a><code>(boolean, inherited) enables useful warnings (which
	can be intercepted using the <code>$SIG{__WARN__}</code> hook) for certain bad practices;

</code></td><td align=left valign=top>(boolean, inherited) forces errors to generate warnings (using
	<code>warn</code>) in addition to returning error codes in the normal way.  When true,
	any method which results in an error causes DBI to effectively do a 
	<code>warn("$class $method failed: $DBI::errstr")</code> where <code>$class</code>
	is the driver class and <code>$method</code> is the name of the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintError</code> "on".
	<p>
	If desired, the warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) used by emulation layers (such as
	Oraperl) to enable compatible behaviour in the underlying driver (e.g., DBD::Oracle) for this handle. 
	Not normally set by application code. Disables the \'quick FETCH\' of attribute
	values from this handle\'s attribute cache so all attribute values
	are handled by the drivers own FETCH method.

\'></a><code>(boolean, inherited) used by emulation layers (such as
	Oraperl) to enable compatible behaviour in the underlying driver (e.g., DBD::Oracle) for this handle. 
	Not normally set by application code. Disables the \'quick FETCH\' of attribute
	values from this handle\'s attribute cache so all attribute values
	are handled by the drivers own FETCH method.

</code></td><td align=left valign=top>(code ref, inherited) When set to a subroutien reference, intercepts
	the setting of this handle\'s <code>err</code>, <code>errstr</code>, and <code>state</code> values.
	<p>
	The subroutine is called the arguments that	were passed to set_err(): the handle, 
	the <code>err</code>, <code>errstr</code>, and <code>state</code> values being set, 
	and the method name. These can be altered by changing the values in the @_ array. 
	The return value affects set_err() behaviour, see <a href=\'#_f_set_err\'>set_err</a> for details.
	<p>
	It is possible to \'stack\' multiple HandleSetErr handlers by using
	closures. See <a href=\'#_m_HandleError\'>HandleError</a> for an example.
	<p>
	The <code>HandleSetErr</code> and <code>HandleError</code> subroutines differ in that
	HandleError is only invoked at the point where DBI is about to return to the application 
	with <code>err</code> set true; it is not invoked by the failure of a method that\'s 
	been called by another DBI method.  HandleSetErr is called
	whenever set_err() is called with a defined <code>err</code> value, even if false.
	Thus, the HandleSetErr subroutine may be called multiple
	times within a method and is usually invoked from deep within driver code.
	<p>
	A driver can use the return value from HandleSetErr via
	set_err() to decide whether to continue or not. If set_err() returns
	an empty list, indicating that the HandleSetErr code has \'handled\'
	the \'error\', the driver might continue instead of failing. 

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(code ref, inherited) When set to a subroutine reference, provides
	alternative behaviour in case of errors. The subroutine reference is called when an 
	error is detected (at the same point that <code>RaiseError</code> and <code>PrintError</code> are handled).
	<p>
	The subroutine is called with three parameters: the error message
	string, this handle object, and the first value returned by
	the method that failed (typically undef).
	<p>
	If the subroutine returns a false value, the <code>RaiseError</code>
	and/or <code>PrintError</code> attributes are checked and acted upon as normal.
	<p>
	For example, to <code>die</code> with a full stack trace for any error:
<pre>
  use Carp;
  $h->{HandleError} = sub { confess(shift) };
</pre>
	Or to turn errors into exceptions:
<pre>
  use Exception; # or your own favourite exception module
  $h->{HandleError} = sub { Exception->new(\'DBI\')->raise($_[0]) };
</pre>
	It is possible to \'stack\' multiple HandleError handlers by using closures:
<pre>
  sub your_subroutine {
    my $previous_handler = $h->{HandleError};
    $h->{HandleError} = sub {
      return 1 if $previous_handler and &$previous_handler(@_);
      ... your code here ...
    };
  }
</pre>
	The error message that will be used by <code>RaiseError</code> and <code>PrintError</code>
	can be altered by changing the value of <code>$_[0]</code>.
	<p>
	Errors may be suppressed, to a limited extent, by using <a href=\'#_f_set_err\'>set_err</a> to 
	reset $DBI::err and $DBI::errstr, and altering the return value of the failed method:
<pre>
  $h->{HandleError} = sub {
    return 0 unless $_[0] =~ /^\\S+ fetchrow_arrayref failed:/;
    return 0 unless $_[1]->err == 1234; # the error to \'hide\'
    $h->set_err(undef,undef);	# turn off the error
    $_[2] = [ ... ];	# supply alternative return value
    return 1;
  };
</pre>

\'></a><code>(code ref, inherited) When set to a subroutine reference, provides
	alternative behaviour in case of errors. The subroutine reference is called when an 
	error is detected (at the same point that <code>RaiseError</code> and <code>PrintError</code> are handled).
	<p>
	The subroutine is called with three parameters: the error message
	string, this handle object, and the first value returned by
	the method that failed (typically undef).
	<p>
	If the subroutine returns a false value, the <code>RaiseError</code>
	and/or <code>PrintError</code> attributes are checked and acted upon as normal.
	<p>
	For example, to <code>die</code> with a full stack trace for any error:
<pre>
  use Carp;
  $h->{HandleError} = sub { confess(shift) };
</pre>
	Or to turn errors into exceptions:
<pre>
  use Exception; # or your own favourite exception module
  $h->{HandleError} = sub { Exception->new(\'DBI\')->raise($_[0]) };
</pre>
	It is possible to \'stack\' multiple HandleError handlers by using closures:
<pre>
  sub your_subroutine {
    my $previous_handler = $h->{HandleError};
    $h->{HandleError} = sub {
      return 1 if $previous_handler and &$previous_handler(@_);
      ... your code here ...
    };
  }
</pre>
	The error message that will be used by <code>RaiseError</code> and <code>PrintError</code>
	can be altered by changing the value of <code>$_[0]</code>.
	<p>
	Errors may be suppressed, to a limited extent, by using <a href=\'#_f_set_err\'>set_err</a> to 
	reset $DBI::err and $DBI::errstr, and altering the return value of the failed method:
<pre>
  $h->{HandleError} = sub {
    return 0 unless $_[0] =~ /^\\S+ fetchrow_arrayref failed:/;
    return 0 unless $_[1]->err == 1234; # the error to \'hide\'
    $h->set_err(undef,undef);	# turn off the error
    $_[2] = [ ... ];	# supply alternative return value
    return 1;
  };
</pre>

</code></td><td align=left valign=top>(hash ref) a reference to the cache (hash) of database handles created by 
	the <a href=\'../../DBI/connect_cached.html#_f_DBI::connect_cached\'>method</a> method.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(integer, inherited) the trace level and flags for this handle. May be used
	to set the trace level and flags. 

\'></a><code>(integer, inherited) the trace level and flags for this handle. May be used
	to set the trace level and flags. 

</code></td><td align=left valign=top>(integer, read-only) the number of currently existing database
	handles created from that driver handle.
	
</td></tr>
<tr><td align=right valign=top><a name=\'_m_(scalar, read-only) "dr" (the type of this handle object)

\'></a><code>(scalar, read-only) "dr" (the type of this handle object)

</code></td><td align=left valign=top>(string, inherited) Specifies the case conversion applied to the 
	the field names used for the hash keys returned by fetchrow_hashref().
	Defaults to \'<code>NAME</code>\' but it is recommended to set it to either \'<code>NAME_lc</code>\'
	or \'<code>NAME_uc</code>\'.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(unsigned integer) the count of calls to set_err() on this handle that recorded an error
	(excluding warnings or information states). It is not reset by the DBI at any time.

\'></a><code>(unsigned integer) the count of calls to set_err() on this handle that recorded an error
	(excluding warnings or information states). It is not reset by the DBI at any time.

</code></td><td align=left valign=top>(unsigned integer, inherited) Sets the maximum
	length of \'long\' type fields (LONG, BLOB, CLOB, MEMO, etc.) which the driver will
	read from the database automatically when it fetches each row of data.
	The <code>LongReadLen</code> attribute only relates to fetching and reading
	long values; it is not involved in inserting or updating them.
	<p>
	A value of 0 means not to automatically fetch any long data.
	Drivers may return undef or an empty string for long fields when
	<code>LongReadLen</code> is 0.
	<p>
	The default is typically 0 (zero) bytes but may vary between drivers.
	Applications fetching long fields should set this value to slightly
	larger than the longest long field value to be fetched.
	<p>
	Some databases return some long types encoded as pairs of hex digits.
	For these types, <code>LongReadLen</code> relates to the underlying data
	length and not the doubled-up length of the encoded string.
	<p>
	Changing the value of <code>LongReadLen</code> for a statement handle after it
	has been <code>prepare</code>\'d will typically have no effect, so it\'s common to
	set <code>LongReadLen</code> on the database or driver handle before calling <code>prepare</code>.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_CachedKids\'></a><code>CachedKids</code></td><td align=left valign=top>ChildHandles</td></tr>
<tr><td align=right valign=top><a name=\'_m_ChopBlanks\'></a><code>ChopBlanks</code></td><td align=left valign=top>CompatMode</td></tr>
<tr><td align=right valign=top><a name=\'_m_ErrCount\'></a><code>ErrCount</code></td><td align=left valign=top>FetchHashKeyName</td></tr>
<tr><td align=right valign=top><a name=\'_m_HandleError\'></a><code>HandleError</code></td><td align=left valign=top>HandleSetErr</td></tr>
<tr><td align=right valign=top><a name=\'_m_Kids\'></a><code>Kids</code></td><td align=left valign=top>LongReadLen</td></tr>
<tr><td align=right valign=top><a name=\'_m_LongTruncOk\'></a><code>LongTruncOk</code></td><td align=left valign=top>PrintError</td></tr>
<tr><td align=right valign=top><a name=\'_m_PrintError\'></a><code>PrintError</code></td><td align=left valign=top>PrintWarn</td></tr>
<tr><td align=right valign=top><a name=\'_m_RaiseError\'></a><code>RaiseError</code></td><td align=left valign=top>ReadOnly</td></tr>
<tr><td align=right valign=top><a name=\'_m_Taint\'></a><code>Taint</code></td><td align=left valign=top>TaintIn</td></tr>
<tr><td align=right valign=top><a name=\'_m_TaintOut\'></a><code>TaintOut</code></td><td align=left valign=top>TraceLevel</td></tr>
<tr><td align=right valign=top><a name=\'_m_Type\'></a><code>Type</code></td><td align=left valign=top>Warn</td></tr>

</table>
<p>

<a name=\'summary\'></a>

<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'><th align=left><font size=\'+2\'>Method Summary</font></th></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_can\'>can</a>($method_name)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Does this driver or the DBI implement this method ?


</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_default_user\'>default_user</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<*** NO CLASSDOC ***>

</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_err\'>err</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the error code from the last driver method called
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_errstr\'>errstr</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the error message from the last driver method called
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_func\'>func</a>(@func_arguments, $func)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Call the specified driver private method
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_parse_trace_flag\'>parse_trace_flag</a>($trace_flag_name)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the bit flag value for the specified trace flag name
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_parse_trace_flags\'>parse_trace_flags</a>($trace_settings)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Parse a string containing trace settings
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_set_err\'>set_err</a>($err, $errstr)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Set the <code>err</code>, <code>errstr</code>, and <code>state</code> values for the handle
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_state\'>state</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the standard SQLSTATE five character format code for the prior driver
method
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_swap_inner_handle\'>swap_inner_handle</a>($h2)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

  $rc = $h1->swap_inner_handle( $h2 );
  $rc = $h1->swap_inner_handle( $h2, $allow_reparent );

Swap the internals of 2 handle objects
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_trace\'>trace</a>($trace_setting)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Set the trace settings for the handle object
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_trace_msg\'>trace_msg</a>($message_text)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Write a trace message to the handle object\'s current trace output
</td></tr>
</table>
<p>

<a name=\'method_detail\'></a>
<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'>
	<th align=left><font size=\'+2\'>Method Details</font></th>
</tr></table>

<a name=\'_f_can\'></a>
<h3>can</h3>
<pre>
can($method_name)
</pre><p>
<dl>
<dd>

Does this driver or the DBI implement this method ?


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>true if $method_name is implemented by the driver or a non-empty default method is provided by DBI;
	otherwise false (i.e., the driver hasn\'t implemented the method and DBI does not
	provide a non-empty default).
</dd>
</dl></dd></dl><hr>

<a name=\'_f_default_user\'></a>
<h3>default_user</h3>
<pre>
default_user()
</pre><p>
<dl>
<dd><*** NO CLASSDOC ***>

<p>
<dd><dl>
</dl></dd></dl><hr>

<a name=\'_f_err\'></a>
<h3>err</h3>
<pre>
err()
</pre><p>
<dl>
<dd>

Return the error code from the last driver method called. 


<p>
<dd><dl>
<dt><b>Returns:</b><dd>the <i>native</i> database engine error code; may be zero
	to indicate a warning condition. May be an empty string
	to indicate a \'success with information\' condition. In both these
	cases the value is false but not undef. The errstr() and state()
	methods may be used to retrieve extra information in these cases.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'#_f_set_err\'>set_err</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_errstr\'></a>
<h3>errstr</h3>
<pre>
errstr()
</pre><p>
<dl>
<dd>

Return the error message from the last driver method called.
<p>
Should not be used to test for errors as some drivers may return 
\'success with information\' or warning messages via errstr() for 
methods that have not \'failed\'.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>One or more native database engine error messages as a single string;
	multiple messages are separated by newline characters.
	May be an empty string if the prior driver method returned successfully.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'#_f_set_err\'>set_err</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_func\'></a>
<h3>func</h3>
<pre>
func(@func_arguments, $func)
</pre><p>
<dl>
<dd>

Call the specified driver private method.
<p>
Note that the function
name is given as the <i>last</i> argument.
<p>
Also note that this method does not clear
a previous error ($DBI::err etc.), nor does it trigger automatic
error detection (RaiseError etc.), so the return
status and/or $h->err must be checked to detect errors.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>any value(s) returned by the specified function
</dd>
<dt><b>See Also:</b></dt><dd><code>install_method()</code> in <a href=\'http://search.cpan.org/perldoc?DBI::DBD\'>DBI::DBD</a>, <a href=\'../../for directly installing and accessing driver-private methods..html\'>for directly installing and accessing driver-private methods.</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_parse_trace_flag\'></a>
<h3>parse_trace_flag</h3>
<pre>
parse_trace_flag($trace_flag_name)
</pre><p>
<dl>
<dd>

Return the bit flag value for the specified trace flag name.
<p>
Drivers should override this method and
check if $trace_flag_name is a driver specific trace flag and, if
not, then call the DBI\'s default parse_trace_flag().


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>if $trace_flag_name is a valid flag name, the corresponding bit flag; otherwise, undef

</dd>
<dt><b>Since:</b></dt><dd>1.42
</dd>
</dl></dd></dl><hr>

<a name=\'_f_parse_trace_flags\'></a>
<h3>parse_trace_flags</h3>
<pre>
parse_trace_flags($trace_settings)
</pre><p>
<dl>
<dd>

Parse a string containing trace settings.
Uses the parse_trace_flag() method to process
trace flag names.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the corresponding integer value used internally by the DBI and drivers.

</dd>
<dt><b>Since:</b></dt><dd>1.42
</dd>
</dl></dd></dl><hr>

<a name=\'_f_set_err\'></a>
<h3>set_err</h3>
<pre>
set_err($err, $errstr)
</pre><p>
<dl>
<dd>

Set the <code>err</code>, <code>errstr</code>, and <code>state</code> values for the handle.
If the <a href=\'#_m_HandleSetErr\'>HandleSetErr</a> attribute holds a reference to a subroutine
it is called first. The subroutine can alter the $err, $errstr, $state,
and $method values. See <a href=\'#_m_HandleSetErr\'>HandleSetErr</a> for full details.
If the subroutine returns a true value then the handle <code>err</code>,
<code>errstr</code>, and <code>state</code> values are not altered and set_err() returns
an empty list (it normally returns $rv which defaults to undef, see below).
<p>
Setting <code>$err</code> to a <i>true</i> value indicates an error and will trigger
the normal DBI error handling mechanisms, such as <code>RaiseError</code> and
<code>HandleError</code>, if they are enabled, when execution returns from
the DBI back to the application.
<p>
Setting <code>$err</code> to <code>""</code> indicates an \'information\' state, and setting
it to <code>"0"</code> indicates a \'warning\' state. Setting <code>$err</code> to <code>undef</code>
also sets <code>$errstr</code> to undef, and <code>$state</code> to <code>""</code>, irrespective
of the values of the $errstr and $state parameters.
<p>
The $method parameter provides an alternate method name for the
<code>RaiseError</code>/<code>PrintError</code>/<code>PrintWarn</code> error string instead of
the fairly unhelpful \'<code>set_err</code>\'.
<p>
Some special rules apply if the <code>err</code> or <code>errstr</code>
values for the handle are <i>already</i> set.
<p>
If <code>errstr</code> is true then: "<code> [err was %s now %s]</code>" is appended if $err is
true and <code>err</code> is already true and the new err value differs from the original
one. Similarly "<code> [state was %s now %s]</code>" is appended if $state is true and <code>state</code> is
already true and the new state value differs from the original one. Finally
"<code>\\n</code>" and the new $errstr are appended if $errstr differs from the existing
errstr value. Obviously the <code>%s</code>\'s above are replaced by the corresponding values.
<p>
The handle <code>err</code> value is set to $err if: $err is true; or handle
<code>err</code> value is undef; or $err is defined and the length is greater
than the handle <code>err</code> length. The effect is that an \'information\'
state only overrides undef; a \'warning\' overrides undef or \'information\',
and an \'error\' state overrides anything.
<p>
The handle <code>state</code> value is set to $state if $state is true and
the handle <code>err</code> value was set (by the rules above).
<p>
This method is typically only used by DBI drivers and DBI subclasses.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the $rv value, if specified; else undef.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_state\'></a>
<h3>state</h3>
<pre>
state()
</pre><p>
<dl>
<dd>

Return the standard SQLSTATE five character format code for the prior driver
method.
The success code <code>00000</code> is translated to any empty string
(false). If the driver does not support SQLSTATE (and most don\'t),
then state() will return <code>S1000</code> (General Error) for all errors.
<p>
The driver is free to return any value via <code>state</code>, e.g., warning
codes, even if it has not declared an error by returning a true value
via the err() method described above.
<p>
Should not be used to test for errors as drivers may return a 
\'success with information\' or warning state code via state() for 
methods that have not \'failed\'.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>if state is currently successful, an empty string; else,
	a five character SQLSTATE code.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_swap_inner_handle\'></a>
<h3>swap_inner_handle</h3>
<pre>
swap_inner_handle($h2)
</pre><p>
<dl>
<dd>

  $rc = $h1->swap_inner_handle( $h2 );
  $rc = $h1->swap_inner_handle( $h2, $allow_reparent );

Swap the internals of 2 handle objects.
Brain transplants for handles. You don\'t need to know about this
unless you want to become a handle surgeon.
<p>
A DBI handle is a reference to a tied hash. A tied hash has an
<i>inner</i> hash that actually holds the contents.  This
method swaps the inner hashes between two handles. The $h1 and $h2
handles still point to the same tied hashes, but what those hashes
are tied to is swapped.  In effect $h1 <i>becomes</i> $h2 and
vice-versa. This is powerful stuff, expect problems. Use with care.
<p>
As a small safety measure, the two handles, $h1 and $h2, have to
share the same parent unless $allow_reparent is true.
<p>
Here\'s a quick kind of \'diagram\' as a worked example to help think about what\'s
happening:
<pre>
    Original state:
            dbh1o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh2o -> dbh2i

    swap_inner_handle dbh1o with dbh2o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i

    create new sth from dbh1o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthBo -> sthBi(dbh2i)

    swap_inner_handle sthAo with sthBo:
            dbh2o -> dbh1i
            sthBo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthAo -> sthBi(dbh2i)
</pre>


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>true if the swap succeeded; otherwise, undef
</dd>
<dt><b>Since:</b></dt><dd>1.44
</dd>
</dl></dd></dl><hr>

<a name=\'_f_trace\'></a>
<h3>trace</h3>
<pre>
trace($trace_setting)
</pre><p>
<dl>
<dd>

Set the trace settings for the handle object. 
Also can be used to change where trace output is sent.
<p>
A similar method, <code>DBI-&gt;trace</code>, sets the global default trace
settings.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the previous $trace_setting value
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?DBI\'>DBI</a> manual TRACING section for full details about DBI\'s, <a href=\'../../tracing facilities..html\'>tracing facilities.</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_trace_msg\'></a>
<h3>trace_msg</h3>
<pre>
trace_msg($message_text)
</pre><p>
<dl>
<dd>

Write a trace message to the handle object\'s current trace output.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?DBI\'>DBI</a> manual TRACING section for full details about DBI\'s, <a href=\'../../tracing facilities..html\'>tracing facilities.</a></dd>
</dl></dd></dl><hr>

<small>
<center>
<i>Generated by POD::ClassDoc 1.01 on Sat Aug  4 14:56:18 2007</i>
</center>
</small>
</body>
</html>
',
                            't/lib/DBI.pm',
                            1989,
                            {
                              'errstr' => [
                                            't/lib/DBI.pm',
                                            1994
                                          ],
                              'parse_trace_flag' => [
                                                      't/lib/DBI.pm',
                                                      1994
                                                    ],
                              'default_user' => [
                                                  't/lib/DBI.pm',
                                                  2285
                                                ],
                              'swap_inner_handle' => [
                                                       't/lib/DBI.pm',
                                                       1994
                                                     ],
                              'trace_msg' => [
                                               't/lib/DBI.pm',
                                               1994
                                             ],
                              'err' => [
                                         't/lib/DBI.pm',
                                         1994
                                       ],
                              'set_err' => [
                                             't/lib/DBI.pm',
                                             1994
                                           ],
                              'can' => [
                                         't/lib/DBI.pm',
                                         1994
                                       ],
                              'state' => [
                                           't/lib/DBI.pm',
                                           1994
                                         ],
                              'trace' => [
                                           't/lib/DBI.pm',
                                           1994
                                         ],
                              'parse_trace_flags' => [
                                                       't/lib/DBI.pm',
                                                       1994
                                                     ],
                              'func' => [
                                          't/lib/DBI.pm',
                                          1994
                                        ]
                            }
                          ],
          'DBD::_::st' => [
                            '
<html>
<head>
<title>DBD::_::st</title>
</head>
<body>
<table width=\'100%\' border=0 CELLPADDING=\'0\' CELLSPACING=\'3\'>
<TR>
<TD VALIGN=\'top\' align=left><FONT SIZE=\'-2\'>
 SUMMARY:&nbsp;CONSTR&nbsp;|&nbsp;<a href=\'#method_summary\'>METHOD</a>
 </FONT></TD>
<TD VALIGN=\'top\' align=right><FONT SIZE=\'-2\'>
DETAIL:&nbsp;CONSTR&nbsp;|&nbsp;<a href=\'#method_detail\'>METHOD</a>
</FONT></TD>
</TR>
</table><hr>
<h2>Class DBD::_::st</h2>

<hr>


Statement handle object. Provides methods and members
for executing and fetching the results of prepared statements.


<p>

<dl>

<a name=\'members\'></a>
<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'><th colspan=2 align=left><font size=\'+2\'>Public Instance Members</font></th></tr>
<tr><td align=right valign=top><a name=\'_m_(array-ref, read-only) an array reference containing the integer scale values for each column.
	<code>undef</code> values indicate columns where scale is not applicable.

\'></a><code>(array-ref, read-only) an array reference containing the integer scale values for each column.
	<code>undef</code> values indicate columns where scale is not applicable.

</code></td><td align=left valign=top>(array-ref, read-only) an array reference indicating the "nullability" of each
	column returning a null.  Possible values are 
	<ul>
	<li>0 (or an empty string) = the column is never NULL
	<li>1 = the column may return NULL values
	<li>2 = unknown
	</ul>

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(array-ref, read-only) an array reference of integer values for each
	column. Each value indicates the data type of the corresponding column.
	The values correspond to the international standards (ANSI X3.135
	and ISO/IEC 9075) which, in general terms, means ODBC. Driver-specific
	types that don\'t exactly match standard types will generally return
	the same values as an ODBC driver supplied by the makers of the
	database, which might include private type numbers in ranges the vendor
	has officially registered with the <a href=\'ftp://sqlstandards.org/SC32/SQL_Registry/\'>ISO working group</a>.
	<p>
	If there is no compatible vendor-supplied ODBC driver,
	the driver may return type numbers in the range
	reserved for use by the DBI: -9999 to -9000.
	<p>
	All <code>TYPE</code> values returned by a driver should be described in the
	output of the <a href=\'../../DBD/_/db/type_info_all.html#_f_DBD::_::db::type_info_all\'>method</a> method.

\'></a><code>(array-ref, read-only) an array reference of integer values for each
	column. Each value indicates the data type of the corresponding column.
	The values correspond to the international standards (ANSI X3.135
	and ISO/IEC 9075) which, in general terms, means ODBC. Driver-specific
	types that don\'t exactly match standard types will generally return
	the same values as an ODBC driver supplied by the makers of the
	database, which might include private type numbers in ranges the vendor
	has officially registered with the <a href=\'ftp://sqlstandards.org/SC32/SQL_Registry/\'>ISO working group</a>.
	<p>
	If there is no compatible vendor-supplied ODBC driver,
	the driver may return type numbers in the range
	reserved for use by the DBI: -9999 to -9000.
	<p>
	All <code>TYPE</code> values returned by a driver should be described in the
	output of the <a href=\'../../DBD/_/db/type_info_all.html#_f_DBD::_::db::type_info_all\'>method</a> method.

</code></td><td align=left valign=top>(array-ref, read-only) an array reference of integer values for each column.
	For numeric columns, the value is the maximum number of displayed digits
	(without considering a sign character or decimal point). Note that
	the "display size" for floating point types (REAL, FLOAT, DOUBLE)
	can be up to 7 characters greater than the precision (for the
	sign + decimal point + the letter E + a sign + 2 or 3 digits).
	<p>
	For character type columns, the value is the OCTET_LENGTH,
	in other words the number of <b>bytes</b>, <b>not</b> characters.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(array-ref, read-only) an array reference of lowercased names for each returned column. The
	names may contain spaces but should not be truncated or have any
	trailing space.

\'></a><code>(array-ref, read-only) an array reference of lowercased names for each returned column. The
	names may contain spaces but should not be truncated or have any
	trailing space.

</code></td><td align=left valign=top>(array-ref, read-only) an array reference of names for each returned column. The
	names may contain spaces but should not be truncated or have any
	trailing space. Note that the names have the letter case (upper, lower
	or mixed) as returned by the driver being used. Portable applications
	should use <a href=\'#_m_NAME_lc\'>NAME_lc</a> or <a href=\'#_m_NAME_uc\'>NAME_uc</a>.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(array-ref, read-only) an array reference of uppercased names for each returned column. The
	names may contain spaces but should not be truncated or have any
	trailing space.

\'></a><code>(array-ref, read-only) an array reference of uppercased names for each returned column. The
	names may contain spaces but should not be truncated or have any
	trailing space.

</code></td><td align=left valign=top>(boolean) when false (the default),this handle will be fully destroyed
	as normal when the last reference to it is removed. If true, this handle will be treated by 
	DESTROY as if it was no longer Active, and so the <i>database engine</i> related effects of 
	DESTROYing this handle will be skipped. Designed for use in Unix applications
	that "fork" child processes: Either the parent or the child process
	(but not both) should set <code>InactiveDestroy</code> true on all their shared handles.
	(Note that some databases, including Oracle, don\'t support passing a
	database connection across a fork.)
	<p>
	To help tracing applications using fork the process id is shown in
	the trace log whenever a DBI or handle trace() method is called.
	The process id also shown for <i>every</i> method call if the DBI trace
	level (not handle trace level) is set high enough to show the trace
	from the DBI\'s method dispatcher, e.g. >= 9.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean) when true, this handle object has been "executed".
	Currently only execute(), execute_array(), and execute_for_fetch() methods set 
	this attribute. When set, also sets the parent connection handle Executed attribute
	at the same time. Never cleared by the DBI under any circumstances.

\'></a><code>(boolean) when true, this handle object has been "executed".
	Currently only execute(), execute_array(), and execute_for_fetch() methods set 
	this attribute. When set, also sets the parent connection handle Executed attribute
	at the same time. Never cleared by the DBI under any circumstances.

</code></td><td align=left valign=top>(boolean, inherited) Sets both <a href=\'#_m_TaintIn\'>TaintIn</a> and <a href=\'#_m_TaintOut\'>TaintOut</a>;
	returns a true value if and only if <a href=\'#_m_TaintIn\'>TaintIn</a> and <a href=\'#_m_TaintOut\'>TaintOut</a> are
	both set to true values.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When false (the default), fetching a long value that
	needs to be truncated (usually due to exceeding <code>LongReadLen</code>) will cause the fetch to fail.
	(Applications should always be sure to
	check for errors after a fetch loop in case an error, such as a divide
	by zero or long field truncation, caused the fetch to terminate
	prematurely.)
	<p>
	If a fetch fails due to a long field truncation when <code>LongTruncOk</code> is
	false, many drivers will allow you to continue fetching further rows.

\'></a><code>(boolean, inherited) When false (the default), fetching a long value that
	needs to be truncated (usually due to exceeding <code>LongReadLen</code>) will cause the fetch to fail.
	(Applications should always be sure to
	check for errors after a fetch loop in case an error, such as a divide
	by zero or long field truncation, caused the fetch to terminate
	prematurely.)
	<p>
	If a fetch fails due to a long field truncation when <code>LongTruncOk</code> is
	false, many drivers will allow you to continue fetching further rows.

</code></td><td align=left valign=top>(boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then all the arguments
	to most DBI method calls are checked for being tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then most data fetched
	from the database is considered tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.
	<p>
	Currently only fetched data is tainted. It is possible that the results
	of other DBI method calls, and the value of fetched attributes, may
	also be tainted in future versions.

\'></a><code>(boolean, inherited) When true (default false), <i>and</i> Perl is running in
	taint mode (e.g., started with the <code>-T</code> option), then most data fetched
	from the database is considered tainted. <i>This may change.</i>
	If Perl is not running in taint mode, this attribute has no effect.
	<p>
	Currently only fetched data is tainted. It is possible that the results
	of other DBI method calls, and the value of fetched attributes, may
	also be tainted in future versions.

</code></td><td align=left valign=top>(boolean, inherited) When true (default false), errors raise exceptions rather
	than simply returning error codes in the normal way.
	Exceptions are raised via a <code>die("$class $method failed: $DBI::errstr")</code>,
	where <code>$class</code> is the driver class and <code>$method</code> is the name of the method
	that failed.
	<p>
	If <code>PrintError</code> is also on, the <code>PrintError</code> is done first.
	<p>
	Typically <code>RaiseError</code> is used in conjunction with <code>eval { ... }</code>
	to catch the exception that\'s been thrown and followed by an
	<code>if ($@) { ... }</code> block to handle the caught exception.
	For example:
<pre>
  eval {
    ...
    $sth->execute();
    ...
  };
  if ($@) {
    # $sth->err and $DBI::err will be true if error was from DBI
    warn $@; # print the error
    ... # do whatever you need to deal with the error
  }
</pre>

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true (default false), trailing space characters are 
	trimmed from returned fixed width character (CHAR) fields. No other field types are affected, 
	even where field values have trailing spaces.

\'></a><code>(boolean, inherited) When true (default false), trailing space characters are 
	trimmed from returned fixed width character (CHAR) fields. No other field types are affected, 
	even where field values have trailing spaces.

</code></td><td align=left valign=top>(boolean, inherited) When true, causes the relevant
	Statement text to be appended to the error messages generated by <code>RaiseError</code>, <code>PrintError</code>, 
	and <code>PrintWarn</code> attributes.
	<p>
	If <code>$h-&gt;{ParamValues}</code> returns a hash reference of parameter
	(placeholder) values then those are formatted and appended to the
	end of the Statement text in the error message.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) When true, forces errors to generate warnings 
	(in addition to returning error codes in the normal way)
	via a <code>warn("$class $method failed: $DBI::errstr")</code>, where <code>$class</code>
	is the driver class and <code>$method</code> is the name of the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintError</code> "on".
	<p>
	If desired, the warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.

\'></a><code>(boolean, inherited) When true, forces errors to generate warnings 
	(in addition to returning error codes in the normal way)
	via a <code>warn("$class $method failed: $DBI::errstr")</code>, where <code>$class</code>
	is the driver class and <code>$method</code> is the name of the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintError</code> "on".
	<p>
	If desired, the warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.

</code></td><td align=left valign=top>(boolean, inherited) When true, indicates that this handle and it\'s children will 
	not make any changes to the database.
	<p>
	The exact definition of \'read only\' is rather fuzzy. See individual driver documentation for specific details.
	<p>
	If the driver can make the handle truly read-only (by issuing a statement like
	"<code>set transaction read only</code>", for example) then it should.
	Otherwise the attribute is simply advisory.
	<p>
	A driver can set the <code>ReadOnly</code> attribute itself to indicate that the data it
	is connected to cannot be changed for some reason.
	<p>
	Library modules and proxy drivers can use the attribute to influence their behavior.
	For example, the DBD::Gofer driver considers the <code>ReadOnly</code> attribute when
	making a decison about whether to retry an operation that failed.
	<p>
	The attribute should be set to 1 or 0 (or undef). Other values are reserved.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) controls printing of warnings issued
	by this handle.  When true, DBI checks method calls to see if a warning condition has 
	been set. If so, DBI effectively does a <code>warn("$class $method warning: $DBI::errstr")</code>
	where <code>$class</code> is the driver class and <code>$method</code> is the name of
	the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintWarn</code> "on" if $^W is true.
	<p>
	Warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.
	<p>
	See also <a href=\'#_f_set_err\'>set_err</a> for how warnings are recorded and <a href=\'#_m_HandleSetErr\'>HandleSetErr</a>
	for how to influence it.

\'></a><code>(boolean, inherited) controls printing of warnings issued
	by this handle.  When true, DBI checks method calls to see if a warning condition has 
	been set. If so, DBI effectively does a <code>warn("$class $method warning: $DBI::errstr")</code>
	where <code>$class</code> is the driver class and <code>$method</code> is the name of
	the method which failed.
	<p>
	By default, <code>DBI-&gt;connect</code> sets <code>PrintWarn</code> "on" if $^W is true.
	<p>
	Warnings can be caught and processed using a <code>$SIG{__WARN__}</code>
	handler or modules like CGI::Carp and CGI::ErrorWrap.
	<p>
	See also <a href=\'#_f_set_err\'>set_err</a> for how warnings are recorded and <a href=\'#_m_HandleSetErr\'>HandleSetErr</a>
	for how to influence it.

</code></td><td align=left valign=top>(boolean, inherited) enables useful warnings (which
	can be intercepted using the <code>$SIG{__WARN__}</code> hook) for certain bad practices;

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(boolean, inherited) used by emulation layers (such as
	Oraperl) to enable compatible behaviour in the underlying driver (e.g., DBD::Oracle) for this handle. 
	Not normally set by application code. Disables the \'quick FETCH\' of attribute
	values from this handle\'s attribute cache so all attribute values
	are handled by the drivers own FETCH method.

\'></a><code>(boolean, inherited) used by emulation layers (such as
	Oraperl) to enable compatible behaviour in the underlying driver (e.g., DBD::Oracle) for this handle. 
	Not normally set by application code. Disables the \'quick FETCH\' of attribute
	values from this handle\'s attribute cache so all attribute values
	are handled by the drivers own FETCH method.

</code></td><td align=left valign=top>(boolean, read-only) when true, indicates this handle object is "active". 
	The exact meaning of active is somewhat vague at the moment. Typically means this handle is a 
	data returning statement that may have more data to fetch.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(code ref, inherited) When set to a subroutien reference, intercepts
	the setting of this handle\'s <code>err</code>, <code>errstr</code>, and <code>state</code> values.
	<p>
	The subroutine is called the arguments that	were passed to set_err(): the handle, 
	the <code>err</code>, <code>errstr</code>, and <code>state</code> values being set, 
	and the method name. These can be altered by changing the values in the @_ array. 
	The return value affects set_err() behaviour, see <a href=\'#_f_set_err\'>set_err</a> for details.
	<p>
	It is possible to \'stack\' multiple HandleSetErr handlers by using
	closures. See <a href=\'#_m_HandleError\'>HandleError</a> for an example.
	<p>
	The <code>HandleSetErr</code> and <code>HandleError</code> subroutines differ in that
	HandleError is only invoked at the point where DBI is about to return to the application 
	with <code>err</code> set true; it is not invoked by the failure of a method that\'s 
	been called by another DBI method.  HandleSetErr is called
	whenever set_err() is called with a defined <code>err</code> value, even if false.
	Thus, the HandleSetErr subroutine may be called multiple
	times within a method and is usually invoked from deep within driver code.
	<p>
	A driver can use the return value from HandleSetErr via
	set_err() to decide whether to continue or not. If set_err() returns
	an empty list, indicating that the HandleSetErr code has \'handled\'
	the \'error\', the driver might continue instead of failing. 

\'></a><code>(code ref, inherited) When set to a subroutien reference, intercepts
	the setting of this handle\'s <code>err</code>, <code>errstr</code>, and <code>state</code> values.
	<p>
	The subroutine is called the arguments that	were passed to set_err(): the handle, 
	the <code>err</code>, <code>errstr</code>, and <code>state</code> values being set, 
	and the method name. These can be altered by changing the values in the @_ array. 
	The return value affects set_err() behaviour, see <a href=\'#_f_set_err\'>set_err</a> for details.
	<p>
	It is possible to \'stack\' multiple HandleSetErr handlers by using
	closures. See <a href=\'#_m_HandleError\'>HandleError</a> for an example.
	<p>
	The <code>HandleSetErr</code> and <code>HandleError</code> subroutines differ in that
	HandleError is only invoked at the point where DBI is about to return to the application 
	with <code>err</code> set true; it is not invoked by the failure of a method that\'s 
	been called by another DBI method.  HandleSetErr is called
	whenever set_err() is called with a defined <code>err</code> value, even if false.
	Thus, the HandleSetErr subroutine may be called multiple
	times within a method and is usually invoked from deep within driver code.
	<p>
	A driver can use the return value from HandleSetErr via
	set_err() to decide whether to continue or not. If set_err() returns
	an empty list, indicating that the HandleSetErr code has \'handled\'
	the \'error\', the driver might continue instead of failing. 

</code></td><td align=left valign=top>(code ref, inherited) When set to a subroutine reference, provides
	alternative behaviour in case of errors. The subroutine reference is called when an 
	error is detected (at the same point that <code>RaiseError</code> and <code>PrintError</code> are handled).
	<p>
	The subroutine is called with three parameters: the error message
	string, this handle object, and the first value returned by
	the method that failed (typically undef).
	<p>
	If the subroutine returns a false value, the <code>RaiseError</code>
	and/or <code>PrintError</code> attributes are checked and acted upon as normal.
	<p>
	For example, to <code>die</code> with a full stack trace for any error:
<pre>
  use Carp;
  $h->{HandleError} = sub { confess(shift) };
</pre>
	Or to turn errors into exceptions:
<pre>
  use Exception; # or your own favourite exception module
  $h->{HandleError} = sub { Exception->new(\'DBI\')->raise($_[0]) };
</pre>
	It is possible to \'stack\' multiple HandleError handlers by using closures:
<pre>
  sub your_subroutine {
    my $previous_handler = $h->{HandleError};
    $h->{HandleError} = sub {
      return 1 if $previous_handler and &$previous_handler(@_);
      ... your code here ...
    };
  }
</pre>
	The error message that will be used by <code>RaiseError</code> and <code>PrintError</code>
	can be altered by changing the value of <code>$_[0]</code>.
	<p>
	Errors may be suppressed, to a limited extent, by using <a href=\'#_f_set_err\'>set_err</a> to 
	reset $DBI::err and $DBI::errstr, and altering the return value of the failed method:
<pre>
  $h->{HandleError} = sub {
    return 0 unless $_[0] =~ /^\\S+ fetchrow_arrayref failed:/;
    return 0 unless $_[1]->err == 1234; # the error to \'hide\'
    $h->set_err(undef,undef);	# turn off the error
    $_[2] = [ ... ];	# supply alternative return value
    return 1;
  };
</pre>

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(dbh, read-only) the parent database handle of this statement handle.

\'></a><code>(dbh, read-only) the parent database handle of this statement handle.

</code></td><td align=left valign=top>(hash ref, read-only) a hash reference containing values currently bound
	to placeholders (or <code>undef</code> if not supported by the driver).
	The keys of the hash are the \'names\' of the placeholders, typically integers starting at 1.  
	When no values have been bound, all the values will be undef
	(some drivers may return a ref to an empty hash in that instance).
	<p>
	Values in the hash may not be <i>exactly</i> the same as those passed to bind_param() or execute(),
	as the driver may modify values based on the bound TYPE specificication.
	The hash values can be passed to another bind_param() method with the same TYPE and will be seen by the
	database as the same value.
	Similary, depending on the driver\'s parameter naming requirements, keys in the hash may not 
	be exactly the same as those implied by the prepared statement.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(hash ref, read-only) a reference to a hash containing the type information
	currently bound to placeholders.  The keys of the hash are the \'names\' of the placeholders: 
	either integers starting at 1, or, for drivers that support named placeholders, the actual parameter
	name string. The hash values are hashrefs of type information in the same form as that provided 
	to bind_param() methods (See <a href=\'#_f_bind_param\'>bind_param</a>), plus anything else that was passed 
	as the third argument to bind_param().
	<p>
	If no values have been bound yet, returns a hash with the placeholder name
	keys, but all the values undef (some drivers may return
	a ref to an empty hash, or, provide type information supplied by the database.
	If not supported by the driver, returns <code>undef</code>.
	<p>
	The values in the hash may not be <i>exactly</i> the same as those passed to bind_param() or execute(),
	as the driver may modify type information based	on the bound values, other hints provided by the prepare()\'d
	SQL statement, or alternate type mappings required by the driver or target database system.
	Similarly, depending on the driver\'s parameter naming requirements, keys in the hash may not be 
	exactly the same as those implied by the prepared statement

\'></a><code>(hash ref, read-only) a reference to a hash containing the type information
	currently bound to placeholders.  The keys of the hash are the \'names\' of the placeholders: 
	either integers starting at 1, or, for drivers that support named placeholders, the actual parameter
	name string. The hash values are hashrefs of type information in the same form as that provided 
	to bind_param() methods (See <a href=\'#_f_bind_param\'>bind_param</a>), plus anything else that was passed 
	as the third argument to bind_param().
	<p>
	If no values have been bound yet, returns a hash with the placeholder name
	keys, but all the values undef (some drivers may return
	a ref to an empty hash, or, provide type information supplied by the database.
	If not supported by the driver, returns <code>undef</code>.
	<p>
	The values in the hash may not be <i>exactly</i> the same as those passed to bind_param() or execute(),
	as the driver may modify type information based	on the bound values, other hints provided by the prepare()\'d
	SQL statement, or alternate type mappings required by the driver or target database system.
	Similarly, depending on the driver\'s parameter naming requirements, keys in the hash may not be 
	exactly the same as those implied by the prepared statement

</code></td><td align=left valign=top>(hash ref, read-only) a reference to a hash containing the values currently bound to
	placeholders via <a href=\'#_f_execute_array\'>execute_array</a> or <a href=\'#_f_bind_param_array\'>bind_param_array</a>.
	The keys of the hash are the \'names\' of the placeholders, typically integers starting at 1.  
	May be undef if not supported by the driver or no arrays of parameters are bound.
	<p>
	Each key value is an array reference containing a list of the bound
	parameters for that column. For example:
<pre>
  $sth = $dbh->prepare("INSERT INTO staff (id, name) values (?,?)");
  $sth->execute_array({},[1,2], [\'fred\',\'dave\']);
  if ($sth->{ParamArrays}) {
      foreach $param (keys %{$sth->{ParamArrays}}) {
	  printf "Parameters for %s : %s\\n", $param,
	  join(",", @{$sth->{ParamArrays}->{$param}});
      }
  }
</pre>
	The values in the hash may not be <i>exactly</i> the same as those passed to 
	<a href=\'#_f_bind_param_array\'>bind_param_array</a> or	<a href=\'#_f_execute_array\'>execute_array</a>, as
	the driver may use modified values in some way based on the bound TYPE value.
	Similarly, depending on the driver\'s parameter naming requirements, keys in the hash may not be 
	exactly the same as those implied by the prepared statement.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(hash-ref, read-only) a hash reference of column name information.
	Keys of the hash are the (possibly mixed case) names of the columns.
	Values are the Perl index number of the corresponding column (counting from 0).

\'></a><code>(hash-ref, read-only) a hash reference of column name information.
	Keys of the hash are the (possibly mixed case) names of the columns.
	Values are the Perl index number of the corresponding column (counting from 0).

</code></td><td align=left valign=top>(hash-ref, read-only) a hash reference of column name information.
	Keys of the hash are the lowercased names of the columns.
	Values are the Perl index number of the corresponding column (counting from 0).

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(hash-ref, read-only) a hash reference of column name information.
	Keys of the hash are the uppercased names of the columns.
	Values are the Perl index number of the corresponding column (counting from 0).

\'></a><code>(hash-ref, read-only) a hash reference of column name information.
	Keys of the hash are the uppercased names of the columns.
	Values are the Perl index number of the corresponding column (counting from 0).

</code></td><td align=left valign=top>(inherited) Enables the collection and reporting of method call timing statistics.
	See the <a href=\'http://search.cpan.org/perldoc?DBI::Profile\'>DBI::Profile</a> module documentation for <i>much</i> more detail.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(integer, inherited) the trace level and flags for this handle. May be used
	to set the trace level and flags. 

\'></a><code>(integer, inherited) the trace level and flags for this handle. May be used
	to set the trace level and flags. 

</code></td><td align=left valign=top>(integer, read-only) always zero

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(integer, read-only) always zero.

\'></a><code>(integer, read-only) always zero.

</code></td><td align=left valign=top>(integer, read-only) number of fields (columns) the prepared statement may return.
	Returns zero for statements that don\'t return data (e.g., <code>DELETE</code>, <code>CREATE</code>, etc. statements)
	(some drivers may return <code>undef</undef>).

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(integer, read-only) number of parameters (placeholders) in the prepared statement.

\'></a><code>(integer, read-only) number of parameters (placeholders) in the prepared statement.

</code></td><td align=left valign=top>(integer, read-only) the number of un-fetched rows in the local row cache; <code>undef</code>
	if the driver doesn\'t support a local row cache. See <a href=\'#_m_RowCacheSize\'>RowCacheSize</a>.
</td></tr>
<tr><td align=right valign=top><a name=\'_m_(scalar, read-only) "st" (the type of this handle object)

\'></a><code>(scalar, read-only) "st" (the type of this handle object)

</code></td><td align=left valign=top>(string, inherited, read-only) Specifies the case conversion applied to the 
	the field names used for the hash keys returned by fetchrow_hashref().
	Defaults to \'<code>NAME</code>\' but it is recommended to set it to either \'<code>NAME_lc</code>\'
	or \'<code>NAME_uc</code>\'.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(string, read-only) the name of the cursor associated with this statement handle
	(if available); <code>undef</code> if not available or if the database driver does not support the
	<code>"where current of ..."</code> SQL syntax.

\'></a><code>(string, read-only) the name of the cursor associated with this statement handle
	(if available); <code>undef</code> if not available or if the database driver does not support the
	<code>"where current of ..."</code> SQL syntax.

</code></td><td align=left valign=top>(string, read-only) the statement string passed to the <a href=\'../../DBD/_/db/prepare.html#_f_DBD::_::db::prepare\'>method</a> method.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_(unsigned integer) the count of calls to set_err() on this handle that recorded an error
	(excluding warnings or information states). It is not reset by the DBI at any time.

\'></a><code>(unsigned integer) the count of calls to set_err() on this handle that recorded an error
	(excluding warnings or information states). It is not reset by the DBI at any time.

</code></td><td align=left valign=top>(unsigned integer, inherited) Sets the maximum
	length of \'long\' type fields (LONG, BLOB, CLOB, MEMO, etc.) which the driver will
	read from the database automatically when it fetches each row of data.
	The <code>LongReadLen</code> attribute only relates to fetching and reading
	long values; it is not involved in inserting or updating them.
	<p>
	A value of 0 means not to automatically fetch any long data.
	Drivers may return undef or an empty string for long fields when
	<code>LongReadLen</code> is 0.
	<p>
	The default is typically 0 (zero) bytes but may vary between drivers.
	Applications fetching long fields should set this value to slightly
	larger than the longest long field value to be fetched.
	<p>
	Some databases return some long types encoded as pairs of hex digits.
	For these types, <code>LongReadLen</code> relates to the underlying data
	length and not the doubled-up length of the encoded string.
	<p>
	Changing the value of <code>LongReadLen</code> on this handle will typically have no effect, so it\'s common to
	set <code>LongReadLen</code> on the database or driver handle before calling <code>prepare</code>.

</td></tr>
<tr><td align=right valign=top><a name=\'_m_Active\'></a><code>Active</code></td><td align=left valign=top>ActiveKids</td></tr>
<tr><td align=right valign=top><a name=\'_m_ChopBlanks\'></a><code>ChopBlanks</code></td><td align=left valign=top>CompatMode</td></tr>
<tr><td align=right valign=top><a name=\'_m_CursorName\'></a><code>CursorName</code></td><td align=left valign=top>Database</td></tr>
<tr><td align=right valign=top><a name=\'_m_ErrCount\'></a><code>ErrCount</code></td><td align=left valign=top>Executed</td></tr>
<tr><td align=right valign=top><a name=\'_m_FetchHashKeyName\'></a><code>FetchHashKeyName</code></td><td align=left valign=top>HandleError</td></tr>
<tr><td align=right valign=top><a name=\'_m_HandleSetErr\'></a><code>HandleSetErr</code></td><td align=left valign=top>InactiveDestroy</td></tr>
<tr><td align=right valign=top><a name=\'_m_Kids\'></a><code>Kids</code></td><td align=left valign=top>LongReadLen</td></tr>
<tr><td align=right valign=top><a name=\'_m_LongTruncOk\'></a><code>LongTruncOk</code></td><td align=left valign=top>NAME</td></tr>
<tr><td align=right valign=top><a name=\'_m_NAME_hash\'></a><code>NAME_hash</code></td><td align=left valign=top>NAME_lc</td></tr>
<tr><td align=right valign=top><a name=\'_m_NAME_lc_hash\'></a><code>NAME_lc_hash</code></td><td align=left valign=top>NAME_uc</td></tr>
<tr><td align=right valign=top><a name=\'_m_NAME_uc_hash\'></a><code>NAME_uc_hash</code></td><td align=left valign=top>NULLABLE</td></tr>
<tr><td align=right valign=top><a name=\'_m_NUM_OF_FIELDS\'></a><code>NUM_OF_FIELDS</code></td><td align=left valign=top>NUM_OF_PARAMS</td></tr>
<tr><td align=right valign=top><a name=\'_m_PRECISION\'></a><code>PRECISION</code></td><td align=left valign=top>ParamArrays</td></tr>
<tr><td align=right valign=top><a name=\'_m_ParamTypes\'></a><code>ParamTypes</code></td><td align=left valign=top>ParamValues</td></tr>
<tr><td align=right valign=top><a name=\'_m_PrintError\'></a><code>PrintError</code></td><td align=left valign=top>PrintWarn</td></tr>
<tr><td align=right valign=top><a name=\'_m_Profile\'></a><code>Profile</code></td><td align=left valign=top>RaiseError</td></tr>
<tr><td align=right valign=top><a name=\'_m_ReadOnly\'></a><code>ReadOnly</code></td><td align=left valign=top>RowsInCache</td></tr>
<tr><td align=right valign=top><a name=\'_m_SCALE\'></a><code>SCALE</code></td><td align=left valign=top>ShowErrorStatement</td></tr>
<tr><td align=right valign=top><a name=\'_m_Statement\'></a><code>Statement</code></td><td align=left valign=top>TYPE</td></tr>
<tr><td align=right valign=top><a name=\'_m_Taint\'></a><code>Taint</code></td><td align=left valign=top>TaintIn</td></tr>
<tr><td align=right valign=top><a name=\'_m_TaintOut\'></a><code>TaintOut</code></td><td align=left valign=top>TraceLevel</td></tr>
<tr><td align=right valign=top><a name=\'_m_Type\'></a><code>Type</code></td><td align=left valign=top>Warn</td></tr>

</table>
<p>

<a name=\'summary\'></a>

<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'><th align=left><font size=\'+2\'>Method Summary</font></th></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_bind_col\'>bind_col</a>($column_number, \\$var_to_bind)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Bind a Perl variable to an output column(field) of a data returning statement
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_bind_columns\'>bind_columns</a>(@list_of_refs_to_vars_to_bind)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Calls <a href=\'#_f_bind_col\'>bind_col</a> for each column of the data returning statement
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_bind_param\'>bind_param</a>($p_num, $bind_value)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Bind a copy of <code>$bind_value</code>
to the specified placeholder in this statement object
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_bind_param_array\'>bind_param_array</a>($p_num, $array_ref_or_value)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Bind an array of values to the specified placeholder in this statement object
for use with a subsequent <a href=\'#_f_execute_array\'>execute_array</a>
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_bind_param_inout\'>bind_param_inout</a>($p_num, \\$bind_value)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Bind (<i>aka, associate</i>) a scalar reference of <code>$bind_value</code>
to the specified placeholder in this statement object
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_can\'>can</a>($method_name)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Does this driver or the DBI implement this method ?


</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_dump_results\'>dump_results</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Dump all the rows from this statement in a human-readable format
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_err\'>err</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the error code from the last driver method called
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_errstr\'>errstr</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the error message from the last driver method called
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_execute\'>execute</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Execute this statement object\'s statement
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_execute_array\'>execute_array</a>(\\%attr)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Execute the prepared statement once for each parameter tuple
(group of values) provided either in <code>@bind_values</code>, or by prior
calls to <a href=\'#_f_bind_param_array\'>bind_param_array</a>, or via a reference passed in 
<code>\\%attr</code>
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_execute_for_fetch\'>execute_for_fetch</a>($fetch_tuple_sub)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Perform a bulk operation using parameter tuples collected from the
supplied subroutine reference or statement handle
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_fetch\'>fetch</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<B>Deprecated.</B>&nbsp;<i>1
</i></td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_fetchall_arrayref\'>fetchall_arrayref</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Fetch all the data (or a slice of all the data) to be returned from this statement handle
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_fetchall_hashref\'>fetchall_hashref</a>($key_field)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Fetch all the data returned by this statement handle
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_fetchrow_array\'>fetchrow_array</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Fetch the next row of data
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_fetchrow_arrayref\'>fetchrow_arrayref</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Fetch the next row of data
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_fetchrow_hashref\'>fetchrow_hashref</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Fetch the next row of data
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_finish\'>finish</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Indicate that no more data will be fetched from this statement handle
before it is either executed again or destroyed
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_func\'>func</a>(@func_arguments, $func)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Call the specified driver private method
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_parse_trace_flag\'>parse_trace_flag</a>($trace_flag_name)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

  $bit_flag = $h->parse_trace_flag($trace_flag_name);

Return the bit flag value for the specified trace flag name
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_parse_trace_flags\'>parse_trace_flags</a>($trace_settings)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Parse a string containing trace settings
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_private_attribute_info\'>private_attribute_info</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

  $hash_ref = $h->private_attribute_info();

Return the list of driver private attributes for this handle object
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_rows\'>rows</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Get the number of rows affected by the last row affecting command
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_set_err\'>set_err</a>($err, $errstr)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Set the <code>err</code>, <code>errstr</code>, and <code>state</code> values for the handle
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_state\'>state</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Return the standard SQLSTATE five character format code for the prior driver
method
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_swap_inner_handle\'>swap_inner_handle</a>($h2)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

  $rc = $h1->swap_inner_handle( $h2 );
  $rc = $h1->swap_inner_handle( $h2, $allow_reparent );

Swap the internals of 2 handle objects
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_trace\'>trace</a>($trace_setting)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Set the trace settings for the handle object
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_trace_msg\'>trace_msg</a>($message_text)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Write a trace message to the handle object\'s current trace output
</td></tr>
</table>
<p>

<a name=\'method_detail\'></a>
<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'>
	<th align=left><font size=\'+2\'>Method Details</font></th>
</tr></table>

<a name=\'_f_bind_col\'></a>
<h3>bind_col</h3>
<pre>
bind_col($column_number, \\$var_to_bind)
</pre><p>
<dl>
<dd>

Bind a Perl variable to an output column(field) of a data returning statement.
<p>
Note that columns do not need to be bound in order to fetch data.
For maximum portability between drivers, bind_col() should be called
<b>after</b> execute().
<p>
Whenever a row is fetched from this statement handle, <code>$var_to_bind</code> appears
to be automatically updated,
The binding is performed at a low level using Perl aliasing,
so that the bound variable refers to the same
memory location as the corresponding column value, thereby making
bound variables very efficient.
<p>
Binding a tied variable is not currently supported.
<p>
The data type for a bind variable cannot be changed after the first
<code>bind_col</code> call.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#DBI_Constants\'>DBI Constants</a> for more information.</dd>
</dl></dd></dl><hr>

<a name=\'_f_bind_columns\'></a>
<h3>bind_columns</h3>
<pre>
bind_columns(@list_of_refs_to_vars_to_bind)
</pre><p>
<dl>
<dd>
Calls <a href=\'#_f_bind_col\'>bind_col</a> for each column of the data returning statement.
<p>
For maximum portability between drivers, this method should be called
<b>after</b> <a href=\'#_f_execute\'>execute</a>.


<p>
<dd><dl>
<dt><b>Parameters:</b>
</dl></dd></dl><hr>

<a name=\'_f_bind_param\'></a>
<h3>bind_param</h3>
<pre>
bind_param($p_num, $bind_value)
</pre><p>
<dl>
<dd>
Bind a copy of <code>$bind_value</code>
to the specified placeholder in this statement object.
Placeholders within a statement string are normally indicated with 
a question mark character (<code>?</code>); some drivers may support alternate
placeholder syntax.
<p>
The data type for a placeholder cannot be changed after the first
<code>bind_param</code> call, after which the driver
may ignore the $bind_type parameter for that placeholder.
<p>
Perl only has string and number scalar data types. All database types
that aren\'t numbers are bound as strings and must be in a format the
database will understand except where the bind_param() TYPE attribute
specifies a type that implies a particular format.
<p>
As an alternative to specifying the data type in the <code>bind_param</code> call,
consider using the default type (<code>VARCHAR</code>) and
use an SQL function to convert the type within the statement.
For example:
<pre>
  INSERT INTO price(code, price) VALUES (?, CONVERT(MONEY,?))
</pre>


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Placeholders_and_Bind_Values\'>Placeholders and Bind Values</a> for more information.</dd>
</dl></dd></dl><hr>

<a name=\'_f_bind_param_array\'></a>
<h3>bind_param_array</h3>
<pre>
bind_param_array($p_num, $array_ref_or_value)
</pre><p>
<dl>
<dd>
Bind an array of values to the specified placeholder in this statement object
for use with a subsequent <a href=\'#_f_execute_array\'>execute_array</a>.
<p>
Placeholders within a statement string are normally indicated with 
a question mark character (<code>?</code>); some drivers may support alternate
placeholder syntax.
<p>
The data type for a placeholder cannot be changed after the first
<code>bind_param_array</code> call, after which the driver
may ignore the $bind_type parameter for that placeholder.
<p>
Perl only has string and number scalar data types. All database types
that aren\'t numbers are bound as strings and must be in a format the
database will understand except where the bind_param() TYPE attribute
specifies a type that implies a particular format.
<p>
As an alternative to specifying the data type in the <code>bind_param</code> call,
consider using the default type (<code>VARCHAR</code>) and
use an SQL function to convert the type within the statement.
For example:
<pre>
  INSERT INTO price(code, price) VALUES (?, CONVERT(MONEY,?))
</pre>
<p>
Note that bind_param_array() can <i>not</i> be used to expand a
placeholder into a list of values for a statement like "SELECT foo
WHERE bar IN (?)".  A placeholder can only ever represent one value
per execution.
<p>
Scalar values, including <code>undef</code>, may also be bound by
<code>bind_param_array</code>, in which case the same value will be used for each
<a href=\'#_f_execute\'>execute</a> call. Driver-specific implementations may behave
differently, e.g., when binding to a stored procedure call, some
databases may permit mixing scalars and arrays as arguments.
<p>
The default implementation provided by DBI (for drivers that have
not implemented array binding) is to iteratively call <a href=\'#_f_execute\'>execute</a> for
each parameter tuple provided in the bound arrays.  Drivers may
provide optimized implementations using any bulk operation
support the database API provides. The default driver behaviour should
match the default DBI behaviour. Refer to the driver\'s
documentation for any related driver specific issues.
<p>
The default implementation currently only supports non-data
returning statements (e.g., INSERT, UPDATE, but not SELECT). Also,
<code>bind_param_array</code> and <a href=\'#_f_bind_param\'>bind_param</a> cannot be mixed in the same
statement execution, and <code>bind_param_array</code> must be used with
<a href=\'#_f_execute_array\'>execute_array</a>; using <code>bind_param_array</code> will have no effect
for <a href=\'#_f_execute\'>execute</a>.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Since:</b></dt><dd>1.22
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Placeholders_and_Bind_Values\'>Placeholders and Bind Values</a> for more information.</dd>
</dl></dd></dl><hr>

<a name=\'_f_bind_param_inout\'></a>
<h3>bind_param_inout</h3>
<pre>
bind_param_inout($p_num, \\$bind_value)
</pre><p>
<dl>
<dd>

Bind (<i>aka, associate</i>) a scalar reference of <code>$bind_value</code>
to the specified placeholder in this statement object.
Placeholders within a statement string are normally indicated with question
mark character (<code>?</code>); some drivers permit alternate placeholder
syntax.
<p>
This method acts like <a href=\'#_f_bind_param\'>bind_param</a>, but enables values to be
updated by the statement. The statement is typically
a call to a stored procedure. The <code>$bind_value</code> must be passed as a
reference to the actual value to be used.
Undefined values or <code>undef</code> are used to indicate null values.
<p>
Note that unlike <a href=\'#_f_bind_param\'>bind_param</a>, the <code>$bind_value</code> variable is not
copied when <code>bind_param_inout</code> is called. Instead, the value in the
variable is read at the time <a href=\'#_f_execute\'>execute</a> is called.
<p>
The data type for a placeholder cannot be changed after the first
<code>bind_param</code> call, after which the driver
may ignore the $bind_type parameter for that placeholder.
<p>
Perl only has string and number scalar data types. All database types
that aren\'t numbers are bound as strings and must be in a format the
database will understand except where the bind_param() TYPE attribute
specifies a type that implies a particular format.
<p>
As an alternative to specifying the data type in this call,
consider using the default type (<code>VARCHAR</code>) and
use an SQL function to convert the type within the statement.
For example:
<pre>
  INSERT INTO price(code, price) VALUES (?, CONVERT(MONEY,?))
</pre>


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>See Also:</b></dt><dd><a href=\'DBI.pod.html#Placeholders_and_Bind_Values\'>Placeholders and Bind Values</a> for more information.</dd>
</dl></dd></dl><hr>

<a name=\'_f_can\'></a>
<h3>can</h3>
<pre>
can($method_name)
</pre><p>
<dl>
<dd>

Does this driver or the DBI implement this method ?


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>true if $method_name is implemented by the driver or a non-empty default method is provided by DBI;
	otherwise false (i.e., the driver hasn\'t implemented the method and DBI does not
	provide a non-empty default).
</dd>
</dl></dd></dl><hr>

<a name=\'_f_dump_results\'></a>
<h3>dump_results</h3>
<pre>
dump_results()
</pre><p>
<dl>
<dd>

Dump all the rows from this statement in a human-readable format.
Fetches all the rows, calling <a href=\'DBI/neat_list.html#_f_DBI::neat_list\'>method</a> for each row, and
printing the formatted rows to <code>$fh</code> separated by <code>$lsep</code>, with
fields separated by <code>$fsep</code>.
<p>
This method is a handy utility for prototyping and
testing queries. Since it uses <a href=\'#_f_neat_list\'>neat_list</a> to
format and edit the string for reading by humans, it is not recomended
for data transfer applications.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>the number of rows dumped
</dd>
</dl></dd></dl><hr>

<a name=\'_f_err\'></a>
<h3>err</h3>
<pre>
err()
</pre><p>
<dl>
<dd>

Return the error code from the last driver method called. 


<p>
<dd><dl>
<dt><b>Returns:</b><dd>the <i>native</i> database engine error code; may be zero
	to indicate a warning condition. May be an empty string
	to indicate a \'success with information\' condition. In both these
	cases the value is false but not undef. The errstr() and state()
	methods may be used to retrieve extra information in these cases.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'#_f_set_err\'>set_err</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_errstr\'></a>
<h3>errstr</h3>
<pre>
errstr()
</pre><p>
<dl>
<dd>

Return the error message from the last driver method called.
<p>
Should not be used to test for errors as some drivers may return 
\'success with information\' or warning messages via errstr() for 
methods that have not \'failed\'.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>One or more native database engine error messages as a single string;
	multiple messages are separated by newline characters.
	May be an empty string if the prior driver method returned successfully.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'#_f_set_err\'>set_err</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_execute\'></a>
<h3>execute</h3>
<pre>
execute()
</pre><p>
<dl>
<dd>

Execute this statement object\'s statement.
<p>
If any <code>@bind_value</code> arguments are given, this method will effectively call
<a href=\'#_f_bind_param\'>bind_param</a> for each value before executing the statement. Values
bound in this way are usually treated as <code>SQL_VARCHAR</code> types unless
the driver can determine the correct type, or unless a prior call to
<code>bind_param</code> (or <code>bind_param_inout</code>) has been used to
specify the type.
<p>
If called on a statement handle that\'s still active,
(<a href=\'#_m_Active\'>Active</a> is true), the driver should effectively call 
<a href=\'#_f_finish\'>finish</a> to tidy up the previous execution results before starting the new
execution.
<p>
For data returning statements, this method starts the query within the
database engine. Use one of the fetch methods to retrieve the data after
calling <code>execute</code>.  This method does <i>not</i> return the number of
rows that will be returned by the query, because most databases can\'t
tell in advance.
<p>
The <a href=\'#_m_NUM_OF_FIELDS\'>NUM_OF_FIELDS</a> attribute can be used to determine if the 
statement is a data returning statement (it should be greater than zero).


<p>
<dd><dl>
<dt><b>Returns:</b><dd><code>undef</code> on failure. On success, returns true regardless of the 
	number of rows affected, even if it\'s zero. For a <i>non</i>-data returning statement, 
	returns the number of rows affected, if known. If no rows were affected, returns
	"<code>0E0</code>", which Perl will treat as 0 but will regard as true.
	If the number of rows affected is not known, returns -1.
	For data returning statements, returns a true (but not meaningful) value.
	<p>
	The error, warning, or informational status of this method is available 
	via the <a href=\'#_f_err\'>err</a>, <a href=\'#_f_errstr\'>errstr</a>,
	and <a href=\'#_f_state\'>state</a> methods.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_execute_array\'></a>
<h3>execute_array</h3>
<pre>
execute_array(\\%attr)
</pre><p>
<dl>
<dd>
Execute the prepared statement once for each parameter tuple
(group of values) provided either in <code>@bind_values</code>, or by prior
calls to <a href=\'#_f_bind_param_array\'>bind_param_array</a>, or via a reference passed in 
<code>\\%attr</code>.
<p>
Bind values are supplied column-wise in the <code>@bind_values</code> argument, or via prior calls to
<a href=\'#_f_bind_param_array\'>bind_param_array</a>.
Alternately, bind values may be supplied row-wise via the <code>ArrayTupleFetch</code> attribute.
<p>
Where column-wise binding is used, the maximum number of elements in
any one of the bound value arrays determines the number of tuples
executed. Placeholders with fewer values in their parameter arrays
are treated as if padded with undef (NULL) values.
If a scalar value (rather than array reference) is bound, it is
treated as a <i>variable</i> length array with all elements having the
same value. It does not influence the number of tuples executed;
if all bound arrays have zero elements then zero tuples will
be executed. If <i>all</i> bound values are scalars, one tuple
will be executed, making execute_array() act like execute().
<p>
The <code>ArrayTupleFetch</code> attribute can be used to specify a reference
to a subroutine that will be called to provide the bind values for
each tuple execution. The subroutine should return a reference to
an array which contains the appropriate number of bind values, or
return an undef if there is no more data to execute.
<p>
As a convienience, the <code>ArrayTupleFetch</code> attribute can also 
specify a statement handle, in which case the <a href=\'#_f_fetchrow_arrayref\'>fetchrow_arrayref</a>
method will be called on the given statement handle to retrieve
bind values for each tuple execution.
<p>
The values specified via <a href=\'#_f_bind_param_array\'>bind_param_array</a> or the @bind_values
parameter may be either scalars, or arrayrefs.  If any <code>@bind_values</code>
are given, then <code>execute_array</code> will effectively call <a href=\'#_f_bind_param_array\'>bind_param_array</a>
for each value before executing the statement.  Values bound in
this way are usually treated as <code>SQL_VARCHAR</code> types unless the
driver can determine the correct type, or unless
<a href=\'#_f_bind_param\'>bind_param</a>, <a href=\'#_f_bind_param_inout\'>bind_param_inout</a>, <a href=\'#_f_bind_param_array\'>bind_param_array</a>, or
<a href=\'#_f_bind_param_inout_array\'>bind_param_inout_array</a> has already been used to specify the type.
<p>
The <code>ArrayTupleStatus</code> attribute can be used to specify a
reference to an array which will receive the execute status of each
executed parameter tuple. Note the <code>ArrayTupleStatus</code> attribute was
mandatory until DBI 1.38.
<p>
For tuples which are successfully executed, the element at the same
ordinal position in the status array is the resulting rowcount.
If the execution of a tuple causes an error, the corresponding
status array element will be set to an array reference containing
the error code and error string set by the failed execution.
<p>
If <b>any</b> tuple execution returns an error, <a href=\'#_f_execute_array\'>execute_array</a> will
return <code>undef</code>. In that case, the application should inspect the
status array to determine which parameter tuples failed.
Some databases may not continue executing tuples beyond the first
failure, in which case the status array will either hold fewer
elements, or the elements beyond the failure will be undef.
<p>
Support for data returning statements such as SELECT is driver-specific
and subject to change. At present, the default implementation
provided by DBI only supports non-data returning statements.
<p>
Transaction semantics when using array binding are driver and
database specific.  If <a href=\'DBD/_/db/AutoCommit.html#_m_DBD::_::db::AutoCommit\'>member</a> is on, the default DBI
implementation will cause each parameter tuple to be inidividually
committed (or rolled back in the event of an error). If <a href=\'DBD/_/db/AutoCommit.html#_m_DBD::_::db::AutoCommit\'>member</a>
is off, the application is responsible for explicitly committing
the entire set of bound parameter tuples.  Note that different
drivers and databases may have different behaviours when some
parameter tuples cause failures. In some cases, the driver or
database may automatically rollback the effect of all prior parameter
tuples that succeeded in the transaction; other drivers or databases
may retain the effect of prior successfully executed parameter
tuples.
<p>
Note that performance will usually be better with
<a href=\'DBD/_/db/AutoCommit.html#_m_DBD::_::db::AutoCommit\'>member</a> turned off, and using explicit 
<a href=\'DBD/_/db/commit.html#_f_DBD::_::db::commit\'>method</a> after each
<a href=\'#_f_execute_array\'>execute_array</a> call.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>In scalar context, returns:</b><dd>returns the number of tuples executed, or <code>undef</code> if an error occured.
	Like <a href=\'#_f_execute\'>execute</a>, a successful execute_array() always returns true regardless
	of the number of tuples executed, even if it\'s zero. Any
	errors are reported in the <code>ArrayTupleStatus</code> array.

</dd>
<dt><b>In list context, returns:</b><dd>(the number of tuples executed (as for calling in scalar context), 
	and the sum of the number of rows affected for each tuple, if available, or -1 
	if the driver cannot determine this.
	Note that certain operations (e.g., UPDATE, DELETE) may report multiple 
	affected rows for one or more of the supplied parameter tuples. 
	Some drivers may not yet support the list context
	call, in which case the reported rowcount will be <code>undef</code>; 
	if a driver is not be able to provide 
	the number of rows affected when performing this batch operation, 
	the returned rowcount will be -1.

)</dd>
<dt><b>Since:</b></dt><dd>1.22
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'#_f_bind_param_array\'>bind_param_array</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_execute_for_fetch\'></a>
<h3>execute_for_fetch</h3>
<pre>
execute_for_fetch($fetch_tuple_sub)
</pre><p>
<dl>
<dd>
Perform a bulk operation using parameter tuples collected from the
supplied subroutine reference or statement handle.
Most often used via the <a href=\'#_f_execute_array\'>execute_array</a> method, not directly.
<p>
If the driver detects an error that it knows means no further tuples can be
executed then it may return with an error status, even though $fetch_tuple_sub
may still have more tuples to be executed.
<p>
Although each tuple returned by $fetch_tuple_sub is effectively used
to call <a href=\'#_f_execute\'>execute</a>, the exact timing may vary.
Drivers are free to accumulate sets of tuples to pass to the
database server in bulk group operations for more efficient execution.
However, the $fetch_tuple_sub is specifically allowed to return
the same array reference each time (as <a href=\'#_f_fetchrow_arrayref\'>fetchrow_arrayref</a>
usually does).


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>In scalar context, returns:</b><dd><code>undef</code> if there were any errors; otherwise,
	the number of tuples executed. Like <method>execute<method> and
	<method>execute_array<method>, a zero tuple count is returned as 
	"0E0". If there were any errors, the @tuple_status array
	can be used to discover which tuples failed and with what errors.

</dd>
<dt><b>In list context, returns:</b><dd>(the tuple execution count, and the sum of the number of rows 
	affected for each tuple, if available, or -1 if the driver cannot determine the
	affected rowcount.
	Certain operations (e.g., UPDATE, DELETE) may cause multiple affected rows
	for a single parameter tuple.
	Some drivers may not yet support list context, in which case
	the returned rowcount will be undef.

)</dd>
<dt><b>Since:</b></dt><dd>1.38
</dd>
</dl></dd></dl><hr>

<a name=\'_f_fetch\'></a>
<h3>fetch</h3>
<pre>
fetch()
</pre><p>
<dl>
<dd>

Fetch the next row of data.
<p>
This is a deprecated alias for <a href=\'#_f_fetchrow_arrayref\'>fetchrow_arrayref</a>.


<p>
<dd><dl>
</dl></dd></dl><hr>

<a name=\'_f_fetchall_arrayref\'></a>
<h3>fetchall_arrayref</h3>
<pre>
fetchall_arrayref()
</pre><p>
<dl>
<dd>
Fetch all the data (or a slice of all the data) to be returned from this statement handle. 
<p>
A standard <code>while</code> loop with column binding is often faster because
the cost of allocating memory for the batch of rows is greater than
the saving by reducing method calls. It\'s possible that the DBI may
provide a way to reuse the memory of a previous batch in future, which
would then shift the balance back towards this method.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>an array reference containing one array reference per row.
	If there are no rows to return, returns a reference
	to an empty array. If an error occurs, returns the data fetched thus far, 
	which may be none, with the error indication available via the
	<a href=\'#_f_err\'>err</a> method (or use the <a href=\'#_m_RaiseError\'>RaiseError</a> attribute).
</dd>
</dl></dd></dl><hr>

<a name=\'_f_fetchall_hashref\'></a>
<h3>fetchall_hashref</h3>
<pre>
fetchall_hashref($key_field)
</pre><p>
<dl>
<dd>
Fetch all the data returned by this statement handle. 
Normally used only where the key fields values for each row are unique.  
If multiple rows are returned with the same values for the key fields, then 
later rows overwrite earlier ones.
<p>
<a href=\'#_f_err\'>err</a> can be called to discover if the returned data is 
complete or was truncated due to an error.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>a hash reference mapping each distinct returned value of the $key_field column(s) to
	a hash reference containing all the selected columns and their values (as returned by 
	<a href=\'#_f_fetchrow_hashref\'>fetchrow_hashref</a>). If there are no rows to return,
	returns an empty hash reference. If an error occurs, returns the
	data fetched thus far, which may be none. If $key_field was specified as a multicolumn
	key, the returned hash reference values will be a hash reference keyed by
	the next column value in the key, iterating until the key is completely specified,
	with the final key column hash reference containing the selected columns hash.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_fetchrow_array\'></a>
<h3>fetchrow_array</h3>
<pre>
fetchrow_array()
</pre><p>
<dl>
<dd>

Fetch the next row of data.
An alternative to <a href=\'#_f_fetchrow_arrayref\'>fetchrow_arrayref</a>.


<p>
<dd><dl>
<dt><b>In scalar context, returns:</b><dd>the value of the first column or the last column (depending on the driver).
	Returns <code>undef</code> if there are no more rows or if an error occurred,
	which is indistinguishable from a NULL returned field value.
	For these reasons, <b>avoid calling this method in scalar context.</b>
</dd>
<dt><b>In list context, returns:</b><dd>(the row\'s field values.  Null fields
	are returned as <code>undef</code> values in the list.
	If there are no more rows or if an error occurs, returns an empty list. 
	Any error indication is available via the <a href=\'#_f_err\'>err</a> method.

)</dd>
</dl></dd></dl><hr>

<a name=\'_f_fetchrow_arrayref\'></a>
<h3>fetchrow_arrayref</h3>
<pre>
fetchrow_arrayref()
</pre><p>
<dl>
<dd>

Fetch the next row of data.
This is the fastest way to fetch data, particularly if used with
<a href=\'#_f_bind_columns\'>bind_columns</a>.
<p>
Note that the same array reference is returned for each fetch, and so 
should not be stores and reused after a later fetch.  Also, the
elements of the array are also reused for each row, so take care if you
want to take a reference to an element.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>an array reference containing the current row\'s field values.
	Null fields are returned as <code>undef</code> values in the array.
	If there are no more rows or if an error occurs, returns <code>undef</code>.
	Any error indication is available via the <a href=\'#_f_err\'>err</a> method.

</dd>
<dt><b>See Also:</b></dt><dd><a href=\'#_f_bind_columns\'>bind_columns</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_fetchrow_hashref\'></a>
<h3>fetchrow_hashref</h3>
<pre>
fetchrow_hashref()
</pre><p>
<dl>
<dd>

Fetch the next row of data.
An alternative to <code>fetchrow_arrayref</code>.
<p>
This method is not as efficient as <code>fetchrow_arrayref</code> or <code>fetchrow_array</code>.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>a hash reference mapping the statement\'s field names to the row\'s field
	values.  Null fields are returned as <code>undef</code> values in the hash.
	If there are no more rows or if an error occurs, returns <code>undef</code>. 
	Any error indication is available via the <a href=\'#_f_err\'>err</a> method.
	<p>
	The keys of the hash are the same names returned by <code>$sth-&gt;{$name}</code>. If
	more than one field has the same name, there will only be one entry in
	the returned hash for those fields.
	<p>
	By default a reference to a new hash is returned for each row.
	It is likely that a future version of the DBI will support an
	attribute which will enable the same hash to be reused for each
	row. This will give a significant performance boost, but it won\'t
	be enabled by default because of the risk of breaking old code.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_finish\'></a>
<h3>finish</h3>
<pre>
finish()
</pre><p>
<dl>
<dd>

Indicate that no more data will be fetched from this statement handle
before it is either executed again or destroyed.  This method
is rarely needed, and frequently overused, but can sometimes be
helpful in a few very specific situations to allow the server to free
up resources (such as sort buffers).
<p>
When all the data has been fetched from a data returning statement, the
driver should automatically call this method; therefore, calling this
method explicitly should not be needed, <i>except</i> when all rows
have not benn fetched from this statement handle.
<p>
Resets the <a href=\'#_m_Active\'>Active</a> attribute for this statement, and
may also make some statement handle attributes (such as <a href=\'#_m_NAME\'>NAME</a> and <a href=\'#_m_TYPE\'>TYPE</a>)
unavailable if they have not already been accessed (and thus cached).
<p>
This method does not affect the transaction status of the
parent database connection.  


<p>
<dd><dl>
<dt><b>See Also:</b></dt><dd><a href=\'#_m_Active\'>Active</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_func\'></a>
<h3>func</h3>
<pre>
func(@func_arguments, $func)
</pre><p>
<dl>
<dd>

Call the specified driver private method.
<p>
Note that the function
name is given as the <i>last</i> argument.
<p>
Also note that this method does not clear
a previous error ($DBI::err etc.), nor does it trigger automatic
error detection (RaiseError etc.), so the return
status and/or $h->err must be checked to detect errors.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>any value(s) returned by the specified function
</dd>
<dt><b>See Also:</b></dt><dd><code>install_method</code> in <a href=\'http://search.cpan.org/perldoc?DBI::DBD\'>DBI::DBD</a>, <a href=\'../../for directly installing and accessing driver-private methods..html\'>for directly installing and accessing driver-private methods.</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_parse_trace_flag\'></a>
<h3>parse_trace_flag</h3>
<pre>
parse_trace_flag($trace_flag_name)
</pre><p>
<dl>
<dd>

  $bit_flag = $h->parse_trace_flag($trace_flag_name);

Return the bit flag value for the specified trace flag name.
<p>
Drivers should override this method and
check if $trace_flag_name is a driver specific trace flag and, if
not, then call the DBI\'s default parse_trace_flag().


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>if $trace_flag_name is a valid flag name, the corresponding bit flag; otherwise, undef

</dd>
<dt><b>Since:</b></dt><dd>1.42
</dd>
</dl></dd></dl><hr>

<a name=\'_f_parse_trace_flags\'></a>
<h3>parse_trace_flags</h3>
<pre>
parse_trace_flags($trace_settings)
</pre><p>
<dl>
<dd>

Parse a string containing trace settings.
Uses the parse_trace_flag() method to process
trace flag names.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the corresponding integer value used internally by the DBI and drivers.

</dd>
<dt><b>Since:</b></dt><dd>1.42
</dd>
</dl></dd></dl><hr>

<a name=\'_f_private_attribute_info\'></a>
<h3>private_attribute_info</h3>
<pre>
private_attribute_info()
</pre><p>
<dl>
<dd>

  $hash_ref = $h->private_attribute_info();

Return the list of driver private attributes for this handle object.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>a hash reference mapping attribute name as keys to <code>undef</code>
	(the attribute\'s current values may be supplied in future)
</dd>
</dl></dd></dl><hr>

<a name=\'_f_rows\'></a>
<h3>rows</h3>
<pre>
rows()
</pre><p>
<dl>
<dd>

Get the number of rows affected by the last row affecting command.
Generally, you can only rely on a row count after a <i>non</i>-data-returning
<a href=\'#_f_execute\'>execute</a> (for some specific operations like <code>UPDATE</code> and <code>DELETE</code>), or
after fetching all the rows of a data returning statement.
<p>
For data returning statements, it is generally not possible to know how many
rows will be returned except by fetching them all.  Some drivers will
return the number of rows the application has fetched so far, but
others may return -1 until all rows have been fetched; therefore, use of this
method (or <code>$DBI::rows</code>) with data returning statements is not
recommended.
<p>
An alternative method to get a row count for a data returning statement is to execute a
<code>"SELECT COUNT(*) FROM ..."</code> SQL statement with the same predicate, grouping, etc.
as this statement\'s query.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>the number of rows affected by the last row affecting command.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_set_err\'></a>
<h3>set_err</h3>
<pre>
set_err($err, $errstr)
</pre><p>
<dl>
<dd>

Set the <code>err</code>, <code>errstr</code>, and <code>state</code> values for the handle.
If the <a href=\'#_m_HandleSetErr\'>HandleSetErr</a> attribute holds a reference to a subroutine
it is called first. The subroutine can alter the $err, $errstr, $state,
and $method values. See <a href=\'#_m_HandleSetErr\'>HandleSetErr</a> for full details.
If the subroutine returns a true value then the handle <code>err</code>,
<code>errstr</code>, and <code>state</code> values are not altered and set_err() returns
an empty list (it normally returns $rv which defaults to undef, see below).
<p>
Setting <code>$err</code> to a <i>true</i> value indicates an error and will trigger
the normal DBI error handling mechanisms, such as <code>RaiseError</code> and
<code>HandleError</code>, if they are enabled, when execution returns from
the DBI back to the application.
<p>
Setting <code>$err</code> to <code>""</code> indicates an \'information\' state, and setting
it to <code>"0"</code> indicates a \'warning\' state. Setting <code>$err</code> to <code>undef</code>
also sets <code>$errstr</code> to undef, and <code>$state</code> to <code>""</code>, irrespective
of the values of the $errstr and $state parameters.
<p>
The $method parameter provides an alternate method name for the
<code>RaiseError</code>/<code>PrintError</code>/<code>PrintWarn</code> error string instead of
the fairly unhelpful \'<code>set_err</code>\'.
<p>
Some special rules apply if the <code>err</code> or <code>errstr</code>
values for the handle are <i>already</i> set.
<p>
If <code>errstr</code> is true then: "<code> [err was %s now %s]</code>" is appended if $err is
true and <code>err</code> is already true and the new err value differs from the original
one. Similarly "<code> [state was %s now %s]</code>" is appended if $state is true and <code>state</code> is
already true and the new state value differs from the original one. Finally
"<code>\\n</code>" and the new $errstr are appended if $errstr differs from the existing
errstr value. Obviously the <code>%s</code>\'s above are replaced by the corresponding values.
<p>
The handle <code>err</code> value is set to $err if: $err is true; or handle
<code>err</code> value is undef; or $err is defined and the length is greater
than the handle <code>err</code> length. The effect is that an \'information\'
state only overrides undef; a \'warning\' overrides undef or \'information\',
and an \'error\' state overrides anything.
<p>
The handle <code>state</code> value is set to $state if $state is true and
the handle <code>err</code> value was set (by the rules above).
<p>
This method is typically only used by DBI drivers and DBI subclasses.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the $rv value, if specified; else undef.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_state\'></a>
<h3>state</h3>
<pre>
state()
</pre><p>
<dl>
<dd>

Return the standard SQLSTATE five character format code for the prior driver
method.
The success code <code>00000</code> is translated to any empty string
(false). If the driver does not support SQLSTATE (and most don\'t),
then state() will return <code>S1000</code> (General Error) for all errors.
<p>
The driver is free to return any value via <code>state</code>, e.g., warning
codes, even if it has not declared an error by returning a true value
via the err() method described above.
<p>
Should not be used to test for errors as drivers may return a 
\'success with information\' or warning state code via state() for 
methods that have not \'failed\'.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>if state is currently successful, an empty string; else,
	a five character SQLSTATE code.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_swap_inner_handle\'></a>
<h3>swap_inner_handle</h3>
<pre>
swap_inner_handle($h2)
</pre><p>
<dl>
<dd>

  $rc = $h1->swap_inner_handle( $h2 );
  $rc = $h1->swap_inner_handle( $h2, $allow_reparent );

Swap the internals of 2 handle objects.
Brain transplants for handles. You don\'t need to know about this
unless you want to become a handle surgeon.
<p>
A DBI handle is a reference to a tied hash. A tied hash has an
<i>inner</i> hash that actually holds the contents.  This
method swaps the inner hashes between two handles. The $h1 and $h2
handles still point to the same tied hashes, but what those hashes
are tied to is swapped.  In effect $h1 <i>becomes</i> $h2 and
vice-versa. This is powerful stuff, expect problems. Use with care.
<p>
As a small safety measure, the two handles, $h1 and $h2, have to
share the same parent unless $allow_reparent is true.
<p>
Here\'s a quick kind of \'diagram\' as a worked example to help think about what\'s
happening:
<pre>
    Original state:
            dbh1o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh2o -> dbh2i

    swap_inner_handle dbh1o with dbh2o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i

    create new sth from dbh1o:
            dbh2o -> dbh1i
            sthAo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthBo -> sthBi(dbh2i)

    swap_inner_handle sthAo with sthBo:
            dbh2o -> dbh1i
            sthBo -> sthAi(dbh1i)
            dbh1o -> dbh2i
            sthAo -> sthBi(dbh2i)
</pre>


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>true if the swap succeeded; otherwise, undef
</dd>
<dt><b>Since:</b></dt><dd>1.44
</dd>
</dl></dd></dl><hr>

<a name=\'_f_trace\'></a>
<h3>trace</h3>
<pre>
trace($trace_setting)
</pre><p>
<dl>
<dd>

Set the trace settings for the handle object. 
Also can be used to change where trace output is sent.
<p>
A similar method, <code>DBI-&gt;trace</code>, sets the global default trace
settings.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the previous $trace_setting value
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?DBI\'>DBI</a> manual TRACING section for full details about DBI\'s, <a href=\'../../tracing facilities..html\'>tracing facilities.</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_trace_msg\'></a>
<h3>trace_msg</h3>
<pre>
trace_msg($message_text)
</pre><p>
<dl>
<dd>

Write a trace message to the handle object\'s current trace output.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?DBI\'>DBI</a> manual TRACING section for full details about DBI\'s, <a href=\'../../tracing facilities..html\'>tracing facilities.</a></dd>
</dl></dd></dl><hr>

<small>
<center>
<i>Generated by POD::ClassDoc 1.01 on Sat Aug  4 14:56:18 2007</i>
</center>
</small>
</body>
</html>
',
                            't/lib/DBI.pm',
                            5035,
                            {
                              'errstr' => [
                                            't/lib/DBI.pm',
                                            5712
                                          ],
                              'parse_trace_flag' => [
                                                      't/lib/DBI.pm',
                                                      5712
                                                    ],
                              'fetchall_hashref' => [
                                                      't/lib/DBI.pm',
                                                      5661
                                                    ],
                              'trace_msg' => [
                                               't/lib/DBI.pm',
                                               5712
                                             ],
                              'finish' => [
                                            't/lib/DBI.pm',
                                            5712
                                          ],
                              'err' => [
                                         't/lib/DBI.pm',
                                         5712
                                       ],
                              'execute_for_fetch' => [
                                                       't/lib/DBI.pm',
                                                       5516
                                                     ],
                              'rows' => [
                                          't/lib/DBI.pm',
                                          5712
                                        ],
                              'state' => [
                                           't/lib/DBI.pm',
                                           5712
                                         ],
                              'trace' => [
                                           't/lib/DBI.pm',
                                           5712
                                         ],
                              'fetchrow_hashref' => [
                                                      't/lib/DBI.pm',
                                                      5712
                                                    ],
                              'parse_trace_flags' => [
                                                       't/lib/DBI.pm',
                                                       5712
                                                     ],
                              'execute_array' => [
                                                   't/lib/DBI.pm',
                                                   5385
                                                 ],
                              'private_attribute_info' => [
                                                            't/lib/DBI.pm',
                                                            5712
                                                          ],
                              'fetch' => [
                                           't/lib/DBI.pm',
                                           5712
                                         ],
                              'dump_results' => [
                                                  't/lib/DBI.pm',
                                                  5712
                                                ],
                              'bind_param_array' => [
                                                      't/lib/DBI.pm',
                                                      5183
                                                    ],
                              'swap_inner_handle' => [
                                                       't/lib/DBI.pm',
                                                       5712
                                                     ],
                              'set_err' => [
                                             't/lib/DBI.pm',
                                             5712
                                           ],
                              'fetchrow_array' => [
                                                    't/lib/DBI.pm',
                                                    5712
                                                  ],
                              'can' => [
                                         't/lib/DBI.pm',
                                         5712
                                       ],
                              'execute' => [
                                             't/lib/DBI.pm',
                                             5712
                                           ],
                              'fetchall_arrayref' => [
                                                       't/lib/DBI.pm',
                                                       5586
                                                     ],
                              'bind_col' => [
                                              't/lib/DBI.pm',
                                              5712
                                            ],
                              'fetchrow_arrayref' => [
                                                       't/lib/DBI.pm',
                                                       5712
                                                     ],
                              'bind_columns' => [
                                                  't/lib/DBI.pm',
                                                  5242
                                                ],
                              'bind_param_inout' => [
                                                      't/lib/DBI.pm',
                                                      5712
                                                    ],
                              'func' => [
                                          't/lib/DBI.pm',
                                          5712
                                        ],
                              'bind_param' => [
                                                't/lib/DBI.pm',
                                                5088
                                              ]
                            }
                          ],
          'DBI' => [
                     '
<html>
<head>
<title>DBI</title>
</head>
<body>
<table width=\'100%\' border=0 CELLPADDING=\'0\' CELLSPACING=\'3\'>
<TR>
<TD VALIGN=\'top\' align=left><FONT SIZE=\'-2\'>
 SUMMARY:&nbsp;CONSTR&nbsp;|&nbsp;<a href=\'#method_summary\'>METHOD</a>
 </FONT></TD>
<TD VALIGN=\'top\' align=right><FONT SIZE=\'-2\'>
DETAIL:&nbsp;CONSTR&nbsp;|&nbsp;<a href=\'#method_detail\'>METHOD</a>
</FONT></TD>
</TR>
</table><hr>
<h2>Class DBI</h2>

<p>
<dl>
<dt><b>Inherits from:</b>
<dd><a href=\'../DynaLoader.html\'>DynaLoader</a></dd>
<dd><a href=\'../Exporter.html\'>Exporter</a></dd>
</dt>
</dl>

<hr>


Perl Database Interface. Base class for Perl\'s standard database access
API.


<p>

<dl>

<dt><b>Author:</b></dt>
	<dd><a href=\'http://www.linkedin.com/in/timbunce\'>Tim Bunce</a></dd>

<dt><b>Since:</b></dt>
	<dd>1994-01-01
</dd>

<dt><b>See Also:</b></dt>
	<dd><a href=\'http://books.perl.org/book/154\'>Programming the Perl DBI</a>, <a href=\'../by Alligator Descartes and Tim Bunce..html\'>by Alligator Descartes and Tim Bunce.</a></dd>

<a name=\'exports\'></a>
<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'><th colspan=2 align=left><font size=\'+2\'>Exported Symbols</font></th></tr>
<tr><td align=right valign=top><a name=\'_e_:sql_cursor_types\'></a><code>:sql_cursor_types</code></td><td align=left valign=top>:sql_types</td></tr>
<tr><td align=right valign=top><a name=\'_e_List of standard SQL cursor types, mapped to the ISO-XXX values
\'></a><code>List of standard SQL cursor types, mapped to the ISO-XXX values
</code></td><td align=left valign=top>List of standard SQL type names, mapped to their ISO-XXX values
</td></tr>

</table>
<p>

<a name=\'members\'></a>
<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'><th colspan=2 align=left><font size=\'+2\'>Public Instance Members</font></th></tr>
<tr><td align=right valign=top><a name=\'_m_$DBI::err\'></a><code>$DBI::err</code></td><td align=left valign=top>$DBI::errstr</td></tr>
<tr><td align=right valign=top><a name=\'_m_$DBI::lasth\'></a><code>$DBI::lasth</code></td><td align=left valign=top>$DBI::rows</td></tr>
<tr><td align=right valign=top><a name=\'_m_$DBI::state\'></a><code>$DBI::state</code></td><td align=left valign=top>DBI object handle used for the most recent DBI method call.
	If the last DBI method call was DESTROY, returns the destroyed handle\'s parent.
</td></tr>
<tr><td align=right valign=top><a name=\'_m_Equivalent to <code>$h-&gt;err</code>.
\'></a><code>Equivalent to <code>$h-&gt;err</code>.
</code></td><td align=left valign=top>Equivalent to <code>$h-&gt;errstr</code>.
</td></tr>
<tr><td align=right valign=top><a name=\'_m_Equivalent to <code>$h-&gt;rows</code>.
\'></a><code>Equivalent to <code>$h-&gt;rows</code>.
</code></td><td align=left valign=top>Equivalent to <code>$h-&gt;state</code>.
</td></tr>

</table>
<p>

<a name=\'summary\'></a>

<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'><th align=left><font size=\'+2\'>Method Summary</font></th></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_available_drivers\'>available_drivers</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Return a list of all available drivers
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_connect\'>connect</a>($data_source, $username, $password)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Establishes a database connection
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_connect_cached\'>connect_cached</a>($data_source, $username, $password)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Establish a database connection using a cached connection (if available)
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_data_diff\'>data_diff</a>($a, $b)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>(class method)</i> 
Return an informal description of the difference between two strings
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_data_sources\'>data_sources</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Return a list of data sources (databases) available via the named
driver
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_data_string_desc\'>data_string_desc</a>($string)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>(class method)</i> 
Return an informal description of the string
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_data_string_diff\'>data_string_diff</a>($a, $b)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>(class method)</i> 
Return an informal description of the first character difference
between two strings
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_disconnect_all\'>disconnect_all</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Disconnect all connections on all installed DBI drivers
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_hash\'>hash</a>($buffer)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>(class method)</i> 

Return a 32-bit integer \'hash\' value computed over the contents of $buffer
using the $type hash algorithm
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_installed_drivers\'>installed_drivers</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<*** NO CLASSDOC ***>

</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_installed_versions\'>installed_versions</a>()</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Returns a list of available drivers and their current installed versions
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_looks_like_number\'>looks_like_number</a>(@array)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>(class method)</i> 

Do the parameter values look like numbers ?


</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_neat\'>neat</a>($value)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>(class method)</i> 

Return a string containing a neat (and tidy) representation of the
supplied value
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_neat_list\'>neat_list</a>(\\@listref)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>(class method)</i> 
Calls <code>neat()</code> on each element of a list, 
returning a single string of the results joined with <code>$field_sep</code>
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_parse_dsn\'>parse_dsn</a>($dsn)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Breaks apart a DBI Data Source Name (DSN) and returns the individual
parts
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_trace\'>trace</a>($trace_setting)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Set the <i>global default</i> trace settings
</td></tr>

<tr><td align=left valign=top>
<code><a href=\'#_f_trace_msg\'>trace_msg</a>($message_text)</code>

<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

Write a message to the trace output
</td></tr>
</table>
<p>

<a name=\'method_detail\'></a>
<table border=1 cellpadding=3 cellspacing=0 width=\'100%\'>
<tr bgcolor=\'#9800B500EB00\'>
	<th align=left><font size=\'+2\'>Method Details</font></th>
</tr></table>

<a name=\'_f_available_drivers\'></a>
<h3>available_drivers</h3>
<pre>
available_drivers()
</pre><p>
<dl>
<dd>
Return a list of all available drivers.
Searches for <code>DBD::*</code> modules
within the directories in <code>@INC</code>.
<p>
By default, a warning is issued if some drivers are hidden by others of the same name in earlier
directories. Passing a true value for <code>$quiet</code> will inhibit the warning.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>(a list of all available DBI driver modules.
)</dd>
</dl></dd></dl><hr>

<a name=\'_f_connect\'></a>
<h3>connect</h3>
<pre>
connect($data_source, $username, $password)
</pre><p>
<dl>
<dd>
Establishes a database connection.
<p>
If <code>$username</code> or <code>$password</code> are undefined (rather than just empty),
then the DBI will substitute the values of the <code>DBI_USER</code> and <code>DBI_PASS</code>
environment variables, respectively.  The DBI will warn if the
environment variables are not defined.  However, the everyday use
of these environment variables is not recommended for security
reasons. The mechanism is primarily intended to simplify testing.
See below for alternative way to specify the username and password.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>a DBI::_::db object (<i>aka</i> database handle) if the connection succeeds; otherwise, undef
	and sets both <code>$DBI::err</code> and <code>$DBI::errstr</code>.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_connect_cached\'></a>
<h3>connect_cached</h3>
<pre>
connect_cached($data_source, $username, $password)
</pre><p>
<dl>
<dd>
Establish a database connection using a cached connection (if available).
Behaves identically to <a href=\'#_m_connect\'>connect</a>, except that the database handle
returned is also stored in a hash associated with the given parameters and attribute values.
If another call is made to <code>connect_cached</code> with the same parameter and attribute values, a
corresponding cached <code>$dbh</code> will be returned if it is still valid.
The cached database handle is replaced with a new connection if it
has been disconnected or if the <code>ping</code> method fails.
<p>
Caching connections can be useful in some applications, but it can
also cause problems, such as too many connections, and so should
be used with care. In particular, avoid changing the attributes of
a database handle created via connect_cached() because it will affect
other code that may be using the same handle.
<p>
The connection cache can be accessed (and cleared) via the <code>CachedKids</code> attribute:
<pre>
  my $CachedKids_hashref = $dbh->{Driver}->{CachedKids};
  %$CachedKids_hashref = () if $CachedKids_hashref;
</pre>


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>a DBI::_::db object (<i>aka</i> database handle) if the connection succeeds; otherwise, undef
	and sets both <code>$DBI::err</code> and <code>$DBI::errstr</code>.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_data_diff\'></a>
<h3>data_diff</h3>
<pre>
data_diff($a, $b)
</pre><p>
<dl>
<dd><i>(class method)</i> 
Return an informal description of the difference between two strings.
Calls <a href=\'#_f_data_string_desc\'>data_string_desc</a> and <a href=\'#_f_data_string_diff\'>data_string_diff</a>
and returns the combined results as a multi-line string.
<p>
For example, <code>data_diff("abc", "ab\\x{263a}")</code> will return:
<pre>
  a: UTF8 off, ASCII, 3 characters 3 bytes
  b: UTF8 on, non-ASCII, 3 characters 5 bytes
  Strings differ at index 2: a[2]=c, b[2]=\\x{263A}
</pre>
If $a and $b are identical in both the characters they contain <i>and</i>
their physical encoding then data_diff() returns an empty string.
If $logical is true then physical encoding differences are ignored
(but are still reported if there is a difference in the characters).


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Since:</b></dt><dd>1.46
</dd>
</dl></dd></dl><hr>

<a name=\'_f_data_sources\'></a>
<h3>data_sources</h3>
<pre>
data_sources()
</pre><p>
<dl>
<dd>
Return a list of data sources (databases) available via the named
driver.
<p>
Data sources are returned in a form suitable for passing to the
<a href=\'#_f_connect\'>connect</a> method with the "<code>dbi:$driver:</code>" prefix.
<p>
Note that many drivers have no way of knowing what data sources might
be available for it. These drivers return an empty or incomplete list
or may require driver-specific attributes.


<p>
<dd><dl>
<dt><b>Returns:</b><dd>(a list of complete DSN strings available via the specified driver.
)</dd>
<dt><b>See Also:</b></dt><dd><a href=\'#_f_data_sources\'>data_sources</a> for database handles.</dd>
</dl></dd></dl><hr>

<a name=\'_f_data_string_desc\'></a>
<h3>data_string_desc</h3>
<pre>
data_string_desc($string)
</pre><p>
<dl>
<dd><i>(class method)</i> 
Return an informal description of the string. For example:
<pre>
  UTF8 off, ASCII, 42 characters 42 bytes
  UTF8 off, non-ASCII, 42 characters 42 bytes
  UTF8 on, non-ASCII, 4 characters 6 bytes
  UTF8 on but INVALID encoding, non-ASCII, 4 characters 6 bytes
  UTF8 off, undef
</pre>
The initial <code>UTF8</code> on/off refers to Perl\'s internal UTF8 flag.
If $string has the UTF8 flag set but the sequence of bytes it
contains are not a valid UTF-8 encoding then data_string_desc()
will report <code>UTF8 on but INVALID encoding</code>.
<p>
The <code>ASCII</code> vs <code>non-ASCII</code> portion shows <code>ASCII</code> if <i>all</i> the
characters in the string are ASCII (have code points <= 127).


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>a string describing the properties of the string 

</dd>
<dt><b>Since:</b></dt><dd>1.46

</dd>
</dl></dd></dl><hr>

<a name=\'_f_data_string_diff\'></a>
<h3>data_string_diff</h3>
<pre>
data_string_diff($a, $b)
</pre><p>
<dl>
<dd><i>(class method)</i> 
Return an informal description of the first character difference
between two strings. For example:
<pre>
 Params a & b     Result
 ------------     ------
 \'aaa\', \'aaa\'     \'\'
 \'aaa\', \'abc\'     \'Strings differ at index 2: a[2]=a, b[2]=b\'
 \'aaa\', undef     \'String b is undef, string a has 3 characters\'
 \'aaa\', \'aa\'      \'String b truncated after 2 characters\'
</pre>
Unicode characters are reported in <code>\\x{XXXX}</code> format. Unicode
code points in the range U+0800 to U+08FF are unassigned and most
likely to occur due to double-encoding. Characters in this range
are reported as <code>\\x{08XX}=\'C\'</code> where <code>C</code> is the corresponding
latin-1 character.
<p>
The data_string_diff() function only considers logical <i>characters</i>
and not the underlying encoding. See <a href=\'#_f_data_diff\'>data_diff</a> for an alternative.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>If both $a and $b contain the same sequence of characters, an empty string. Otherwise,
	a description of the first difference between the strings.
</dd>
<dt><b>Since:</b></dt><dd>1.46
</dd>
</dl></dd></dl><hr>

<a name=\'_f_disconnect_all\'></a>
<h3>disconnect_all</h3>
<pre>
disconnect_all()
</pre><p>
<dl>
<dd>
Disconnect all connections on all installed DBI drivers.

<p>
<dd><dl>
</dl></dd></dl><hr>

<a name=\'_f_hash\'></a>
<h3>hash</h3>
<pre>
hash($buffer)
</pre><p>
<dl>
<dd><i>(class method)</i> 

Return a 32-bit integer \'hash\' value computed over the contents of $buffer
using the $type hash algorithm.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the hashvalue
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'http://www.isthe.com/chongo/tech/comp/fnv/\'>Type 1 hash information</a>.</dd>
</dl></dd></dl><hr>

<a name=\'_f_installed_drivers\'></a>
<h3>installed_drivers</h3>
<pre>
installed_drivers()
</pre><p>
<dl>
<dd><*** NO CLASSDOC ***>

<p>
<dd><dl>
</dl></dd></dl><hr>

<a name=\'_f_installed_versions\'></a>
<h3>installed_versions</h3>
<pre>
installed_versions()
</pre><p>
<dl>
<dd>
Returns a list of available drivers and their current installed versions.
Note that this loads <b>all</b> available drivers.
<p>
When called in a void context the installed_versions() method will
print out a formatted list of the hash contents, one per line.
<p>
Due to the potentially high memory cost and unknown risks of loading
in an unknown number of drivers that just happen to be installed
on the system, this method is not recommended for general use.
Use <a href=\'#_f_available_drivers\'>available_drivers</a> instead.
<p>
The installed_versions() method is primarily intended as a quick
way to see from the command line what\'s installed. For example:
<pre>
  perl -MDBI -e \'DBI->installed_versions\'
</pre>


<p>
<dd><dl>
<dt><b>In scalar context, returns:</b><dd>in scalar context, a hash reference mapping driver names (without the \'DBD::\' prefix) to versions,
	as well as other entries for the <code>DBI</code> version, <code>OS</code> name, etc.

</dd>
<dt><b>In list context, returns:</b><dd>(the list of successfully loaded drivers (without the \'DBD::\' prefix)
)</dd>
<dt><b>Since:</b></dt><dd>1.38.
</dd>
</dl></dd></dl><hr>

<a name=\'_f_looks_like_number\'></a>
<h3>looks_like_number</h3>
<pre>
looks_like_number(@array)
</pre><p>
<dl>
<dd><i>(class method)</i> 

Do the parameter values look like numbers ?


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>(true for each element that looks like a number,
	false for each element that does not look like a number, and
	<code>undef</code> for each element that is undefined or empty.
)</dd>
</dl></dd></dl><hr>

<a name=\'_f_neat\'></a>
<h3>neat</h3>
<pre>
neat($value)
</pre><p>
<dl>
<dd><i>(class method)</i> 

Return a string containing a neat (and tidy) representation of the
supplied value.
<p>
Strings will be quoted, although internal quotes will <i>not</i> be escaped.
Values known to be numeric will be unquoted. Undefined (NULL) values
will be shown as <code>undef</code> (without quotes).
<p>
If the string is flagged internally as UTF-8 then double quotes will
be used, otherwise single quotes are used and unprintable characters
will be replaced by dot (.).
<p>
This function is designed to format values for human consumption.
It is used internally by the DBI for <a href=\'#_f_trace\'>trace</a> output. It should
typically <i>not</i> be used for formatting values for database use.
(See also <a href=\'#_f_quote\'>quote</a>.)


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the neatly formatted string
</dd>
</dl></dd></dl><hr>

<a name=\'_f_neat_list\'></a>
<h3>neat_list</h3>
<pre>
neat_list(\\@listref)
</pre><p>
<dl>
<dd><i>(class method)</i> 
Calls <code>neat()</code> on each element of a list, 
returning a single string of the results joined with <code>$field_sep</code>. 


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>a single string of the neatened strings joined with <code>$field_sep</code>. 
</dd>
</dl></dd></dl><hr>

<a name=\'_f_parse_dsn\'></a>
<h3>parse_dsn</h3>
<pre>
parse_dsn($dsn)
</pre><p>
<dl>
<dd>
Breaks apart a DBI Data Source Name (DSN) and returns the individual
parts.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>(undef on failure, otherwise, <code>($scheme, $driver, $attr_string, $attr_hash, $driver_dsn)</code>,
	where
	<ul>
	<li>$scheme is the first part of the DSN and is currently always \'dbi\'.
	<li>$driver is the driver name, possibly defaulted to $ENV{DBI_DRIVER},	and may be undefined.
	<li>$attr_string is the contents of the optional attribute string, which may be undefined. 
	<li>$attr_hash is a reference to a hash containing the parsed attribute names and values if $attr_string is not empty.
	<li>$driver_dsn is any trailing part of the DSN string
	</ul>
)</dd>
<dt><b>Since:</b></dt><dd>1.43.

</dd>
</dl></dd></dl><hr>

<a name=\'_f_trace\'></a>
<h3>trace</h3>
<pre>
trace($trace_setting)
</pre><p>
<dl>
<dd>

Set the <i>global default</i> trace settings. 
Also can be used to change where trace output is sent.
<p>
A similar method, <code>$h-&gt;trace</code>, sets the trace
settings for the specific handle it\'s called on.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>Returns:</b><dd>the previous $trace_setting value
</dd>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?DBI\'>DBI</a> manual TRACING section for full details about DBI\'s, <a href=\'../tracing facilities..html\'>tracing facilities.</a></dd>
</dl></dd></dl><hr>

<a name=\'_f_trace_msg\'></a>
<h3>trace_msg</h3>
<pre>
trace_msg($message_text)
</pre><p>
<dl>
<dd>

Write a message to the trace output.


<p>
<dd><dl>
<dt><b>Parameters:</b>
<dt><b>See Also:</b></dt><dd><a href=\'http://search.cpan.org/perldoc?DBI\'>DBI</a> manual TRACING section for full details about DBI\'s, <a href=\'../tracing facilities..html\'>tracing facilities.</a></dd>
</dl></dd></dl><hr>

<small>
<center>
<i>Generated by POD::ClassDoc 1.01 on Sat Aug  4 14:56:18 2007</i>
</center>
</small>
</body>
</html>
',
                     't/lib/DBI.pm',
                     41,
                     {
                       'trace_msg' => [
                                        't/lib/DBI.pm',
                                        151
                                      ],
                       'data_string_desc' => [
                                               't/lib/DBI.pm',
                                               1457
                                             ],
                       'disconnect_all' => [
                                             't/lib/DBI.pm',
                                             865
                                           ],
                       'looks_like_number' => [
                                                't/lib/DBI.pm',
                                                151
                                              ],
                       'trace' => [
                                    't/lib/DBI.pm',
                                    151
                                  ],
                       'connect' => [
                                      't/lib/DBI.pm',
                                      693
                                    ],
                       'available_drivers' => [
                                                't/lib/DBI.pm',
                                                1125
                                              ],
                       'neat' => [
                                   't/lib/DBI.pm',
                                   151
                                 ],
                       'parse_dsn' => [
                                        't/lib/DBI.pm',
                                        568
                                      ],
                       'data_sources' => [
                                           't/lib/DBI.pm',
                                           1249
                                         ],
                       'neat_list' => [
                                        't/lib/DBI.pm',
                                        1275
                                      ],
                       'installed_drivers' => [
                                                't/lib/DBI.pm',
                                                311
                                              ],
                       'data_string_diff' => [
                                               't/lib/DBI.pm',
                                               1382
                                             ],
                       'hash' => [
                                   't/lib/DBI.pm',
                                   151
                                 ],
                       'data_diff' => [
                                        't/lib/DBI.pm',
                                        1331
                                      ],
                       'installed_versions' => [
                                                 't/lib/DBI.pm',
                                                 1190
                                               ],
                       'connect_cached' => [
                                             't/lib/DBI.pm',
                                             635
                                           ]
                     }
                   ]
        };

#
#	due to embedded date/time, we have to normalize
#
$_->[0]=~s/<i>Generated by POD::ClassDoc [^<]+<\/i>/<i>Generated by POD::ClassDoc ***<\/i>/
	foreach (values %$expected);

if ($classmap) {
	$_->[0]=~s/<i>Generated by POD::ClassDoc [^<]+<\/i>/<i>Generated by POD::ClassDoc ***<\/i>/
		foreach (values %$classmap);
}

# *** is_deeply($classmap, $expected, 'render returns classmap'); 

$expected->{$_}[0] = 't/classdocs/' . join('/', split(/\:\:/)) . '.html'
	foreach (qw(DBI DBD::_::db DBD::_::dr DBD::_::st));

$classmap = $classdoc->writeClassdocs;

if ($classmap) {
	# *** is_deeply($classmap, $expected, 'writeClassdocs returns classmap'); 
}
else {
	fail("writeClassdocs returns classmap: $@");
}
#
#	!!!NEED TO IMPROVE THESE TESTS
#	should compare file content to expected content...but
#	just check existance for now
#
foreach (qw(DBI.html DBD/_/db.html DBD/_/dr.html DBD/_/st.html)) {
	fail('writeClassdocs output file'), 
	last
		unless (-e "t/classdocs/$_")

#	open(INF, 't/classdocs/DBI.pm.html');
#	$txt = <INF>;
#	close INF;
#	is($txt, $expected, 'writeClassdocs output file');
}

my $container = $classdoc->getFrameContainer('DBI.html');
$expected = <<'EODOC';
<html><head><title>Classdocs for DBI</title></head>
<frameset cols='15%,85%'>
<frame name='navbar' src='toc.html' scrolling=auto frameborder=0>
<frame name='mainframe' src='DBI.html'>
</frameset>
</html>
EODOC

is($container, $expected, 'getFrameContainer');

is($classdoc->writeFrameContainer('index.html', 'DBI.html'), $classdoc, 'writeFrameContainer');

unless (-e 't/classdocs/index.html') {
	fail('writeFrameContainer output file');
}
else {
	open(INF, 't/classdocs/index.html');
	$txt = <INF>;
	close INF;
	is($txt, $expected, 'writeFrameContainer output file');
}

my $toc = $classdoc->getTOC;
$expected = << 'EOTOC';
<html>
<body>
<small>
<!-- INDEX BEGIN -->
<ul>
<li><a href='DBD/_/db.html' target='mainframe'>DBD::_::db</a>
		<ul>
		<li><a href='DBD/_/db.html#summary' target='mainframe'>Summary</a></li>
		<li><a href='DBD/_/db.html#members' target='mainframe'>Public Members</a>
			<ul>
			<li><a href='DBD/_/db.html#_m_Active' target='mainframe'>Active</a></li>
<li><a href='DBD/_/db.html#_m_ActiveKids' target='mainframe'>ActiveKids</a></li>
<li><a href='DBD/_/db.html#_m_AutoCommit' target='mainframe'>AutoCommit</a></li>
<li><a href='DBD/_/db.html#_m_CachedKids' target='mainframe'>CachedKids</a></li>
<li><a href='DBD/_/db.html#_m_ChildHandles' target='mainframe'>ChildHandles</a></li>
<li><a href='DBD/_/db.html#_m_ChopBlanks' target='mainframe'>ChopBlanks</a></li>
<li><a href='DBD/_/db.html#_m_CompatMode' target='mainframe'>CompatMode</a></li>
<li><a href='DBD/_/db.html#_m_Driver' target='mainframe'>Driver</a></li>
<li><a href='DBD/_/db.html#_m_ErrCount' target='mainframe'>ErrCount</a></li>
<li><a href='DBD/_/db.html#_m_Executed' target='mainframe'>Executed</a></li>
<li><a href='DBD/_/db.html#_m_FetchHashKeyName' target='mainframe'>FetchHashKeyName</a></li>
<li><a href='DBD/_/db.html#_m_HandleError' target='mainframe'>HandleError</a></li>
<li><a href='DBD/_/db.html#_m_HandleSetErr' target='mainframe'>HandleSetErr</a></li>
<li><a href='DBD/_/db.html#_m_InactiveDestroy' target='mainframe'>InactiveDestroy</a></li>
<li><a href='DBD/_/db.html#_m_Kids' target='mainframe'>Kids</a></li>
<li><a href='DBD/_/db.html#_m_LongReadLen' target='mainframe'>LongReadLen</a></li>
<li><a href='DBD/_/db.html#_m_LongTruncOk' target='mainframe'>LongTruncOk</a></li>
<li><a href='DBD/_/db.html#_m_Name' target='mainframe'>Name</a></li>
<li><a href='DBD/_/db.html#_m_PrintError' target='mainframe'>PrintError</a></li>
<li><a href='DBD/_/db.html#_m_PrintWarn' target='mainframe'>PrintWarn</a></li>
<li><a href='DBD/_/db.html#_m_RaiseError' target='mainframe'>RaiseError</a></li>
<li><a href='DBD/_/db.html#_m_ReadOnly' target='mainframe'>ReadOnly</a></li>
<li><a href='DBD/_/db.html#_m_RowCacheSize' target='mainframe'>RowCacheSize</a></li>
<li><a href='DBD/_/db.html#_m_ShowErrorStatement' target='mainframe'>ShowErrorStatement</a></li>
<li><a href='DBD/_/db.html#_m_Statement' target='mainframe'>Statement</a></li>
<li><a href='DBD/_/db.html#_m_Taint' target='mainframe'>Taint</a></li>
<li><a href='DBD/_/db.html#_m_TaintIn' target='mainframe'>TaintIn</a></li>
<li><a href='DBD/_/db.html#_m_TaintOut' target='mainframe'>TaintOut</a></li>
<li><a href='DBD/_/db.html#_m_TraceLevel' target='mainframe'>TraceLevel</a></li>
<li><a href='DBD/_/db.html#_m_Type' target='mainframe'>Type</a></li>
<li><a href='DBD/_/db.html#_m_Username' target='mainframe'>Username</a></li>
<li><a href='DBD/_/db.html#_m_Warn' target='mainframe'>Warn</a></li>
</ul>
</li>
<li><a href='DBD/_/db.html#method_detail' target='mainframe'>Methods</a>
			<ul>
			<li><a href='DBD/_/db.html#_f_begin_work' target='mainframe'>begin_work</a></li>
<li><a href='DBD/_/db.html#_f_can' target='mainframe'>can</a></li>
<li><a href='DBD/_/db.html#_f_clone' target='mainframe'>clone</a></li>
<li><a href='DBD/_/db.html#_f_column_info' target='mainframe'>column_info</a></li>
<li><a href='DBD/_/db.html#_f_commit' target='mainframe'>commit</a></li>
<li><a href='DBD/_/db.html#_f_data_sources' target='mainframe'>data_sources</a></li>
<li><a href='DBD/_/db.html#_f_disconnect' target='mainframe'>disconnect</a></li>
<li><a href='DBD/_/db.html#_f_do' target='mainframe'>do</a></li>
<li><a href='DBD/_/db.html#_f_err' target='mainframe'>err</a></li>
<li><a href='DBD/_/db.html#_f_errstr' target='mainframe'>errstr</a></li>
<li><a href='DBD/_/db.html#_f_foreign_key_info' target='mainframe'>foreign_key_info</a></li>
<li><a href='DBD/_/db.html#_f_func' target='mainframe'>func</a></li>
<li><a href='DBD/_/db.html#_f_get_info' target='mainframe'>get_info</a></li>
<li><a href='DBD/_/db.html#_f_last_insert_id' target='mainframe'>last_insert_id</a></li>
<li><a href='DBD/_/db.html#_f_parse_trace_flag' target='mainframe'>parse_trace_flag</a></li>
<li><a href='DBD/_/db.html#_f_parse_trace_flags' target='mainframe'>parse_trace_flags</a></li>
<li><a href='DBD/_/db.html#_f_ping' target='mainframe'>ping</a></li>
<li><a href='DBD/_/db.html#_f_prepare' target='mainframe'>prepare</a></li>
<li><a href='DBD/_/db.html#_f_prepare_cached' target='mainframe'>prepare_cached</a></li>
<li><a href='DBD/_/db.html#_f_primary_key' target='mainframe'>primary_key</a></li>
<li><a href='DBD/_/db.html#_f_primary_key_info' target='mainframe'>primary_key_info</a></li>
<li><a href='DBD/_/db.html#_f_quote' target='mainframe'>quote</a></li>
<li><a href='DBD/_/db.html#_f_quote_identifier' target='mainframe'>quote_identifier</a></li>
<li><a href='DBD/_/db.html#_f_rollback' target='mainframe'>rollback</a></li>
<li><a href='DBD/_/db.html#_f_selectall_arrayref' target='mainframe'>selectall_arrayref</a></li>
<li><a href='DBD/_/db.html#_f_selectall_hashref' target='mainframe'>selectall_hashref</a></li>
<li><a href='DBD/_/db.html#_f_selectcol_arrayref' target='mainframe'>selectcol_arrayref</a></li>
<li><a href='DBD/_/db.html#_f_selectrow_array' target='mainframe'>selectrow_array</a></li>
<li><a href='DBD/_/db.html#_f_selectrow_arrayref' target='mainframe'>selectrow_arrayref</a></li>
<li><a href='DBD/_/db.html#_f_selectrow_hashref' target='mainframe'>selectrow_hashref</a></li>
<li><a href='DBD/_/db.html#_f_set_err' target='mainframe'>set_err</a></li>
<li><a href='DBD/_/db.html#_f_state' target='mainframe'>state</a></li>
<li><a href='DBD/_/db.html#_f_statistics_info' target='mainframe'>statistics_info</a></li>
<li><a href='DBD/_/db.html#_f_swap_inner_handle' target='mainframe'>swap_inner_handle</a></li>
<li><a href='DBD/_/db.html#_f_table_info' target='mainframe'>table_info</a></li>
<li><a href='DBD/_/db.html#_f_tables' target='mainframe'>tables</a></li>
<li><a href='DBD/_/db.html#_f_take_imp_data' target='mainframe'>take_imp_data</a></li>
<li><a href='DBD/_/db.html#_f_trace' target='mainframe'>trace</a></li>
<li><a href='DBD/_/db.html#_f_trace_msg' target='mainframe'>trace_msg</a></li>
<li><a href='DBD/_/db.html#_f_type_info' target='mainframe'>type_info</a></li>
<li><a href='DBD/_/db.html#_f_type_info_all' target='mainframe'>type_info_all</a></li>
</ul>
</li>
</ul>
</li>
<li><a href='DBD/_/dr.html' target='mainframe'>DBD::_::dr</a>
		<ul>
		<li><a href='DBD/_/dr.html#summary' target='mainframe'>Summary</a></li>
		<li><a href='DBD/_/dr.html#members' target='mainframe'>Public Members</a>
			<ul>
			<li><a href='DBD/_/dr.html#_m_CachedKids' target='mainframe'>CachedKids</a></li>
<li><a href='DBD/_/dr.html#_m_ChildHandles' target='mainframe'>ChildHandles</a></li>
<li><a href='DBD/_/dr.html#_m_ChopBlanks' target='mainframe'>ChopBlanks</a></li>
<li><a href='DBD/_/dr.html#_m_CompatMode' target='mainframe'>CompatMode</a></li>
<li><a href='DBD/_/dr.html#_m_ErrCount' target='mainframe'>ErrCount</a></li>
<li><a href='DBD/_/dr.html#_m_FetchHashKeyName' target='mainframe'>FetchHashKeyName</a></li>
<li><a href='DBD/_/dr.html#_m_HandleError' target='mainframe'>HandleError</a></li>
<li><a href='DBD/_/dr.html#_m_HandleSetErr' target='mainframe'>HandleSetErr</a></li>
<li><a href='DBD/_/dr.html#_m_Kids' target='mainframe'>Kids</a></li>
<li><a href='DBD/_/dr.html#_m_LongReadLen' target='mainframe'>LongReadLen</a></li>
<li><a href='DBD/_/dr.html#_m_LongTruncOk' target='mainframe'>LongTruncOk</a></li>
<li><a href='DBD/_/dr.html#_m_PrintError' target='mainframe'>PrintError</a></li>
<li><a href='DBD/_/dr.html#_m_PrintWarn' target='mainframe'>PrintWarn</a></li>
<li><a href='DBD/_/dr.html#_m_RaiseError' target='mainframe'>RaiseError</a></li>
<li><a href='DBD/_/dr.html#_m_ReadOnly' target='mainframe'>ReadOnly</a></li>
<li><a href='DBD/_/dr.html#_m_Taint' target='mainframe'>Taint</a></li>
<li><a href='DBD/_/dr.html#_m_TaintIn' target='mainframe'>TaintIn</a></li>
<li><a href='DBD/_/dr.html#_m_TaintOut' target='mainframe'>TaintOut</a></li>
<li><a href='DBD/_/dr.html#_m_TraceLevel' target='mainframe'>TraceLevel</a></li>
<li><a href='DBD/_/dr.html#_m_Type' target='mainframe'>Type</a></li>
<li><a href='DBD/_/dr.html#_m_Warn' target='mainframe'>Warn</a></li>
</ul>
</li>
<li><a href='DBD/_/dr.html#method_detail' target='mainframe'>Methods</a>
			<ul>
			<li><a href='DBD/_/dr.html#_f_can' target='mainframe'>can</a></li>
<li><a href='DBD/_/dr.html#_f_default_user' target='mainframe'>default_user</a></li>
<li><a href='DBD/_/dr.html#_f_err' target='mainframe'>err</a></li>
<li><a href='DBD/_/dr.html#_f_errstr' target='mainframe'>errstr</a></li>
<li><a href='DBD/_/dr.html#_f_func' target='mainframe'>func</a></li>
<li><a href='DBD/_/dr.html#_f_parse_trace_flag' target='mainframe'>parse_trace_flag</a></li>
<li><a href='DBD/_/dr.html#_f_parse_trace_flags' target='mainframe'>parse_trace_flags</a></li>
<li><a href='DBD/_/dr.html#_f_set_err' target='mainframe'>set_err</a></li>
<li><a href='DBD/_/dr.html#_f_state' target='mainframe'>state</a></li>
<li><a href='DBD/_/dr.html#_f_swap_inner_handle' target='mainframe'>swap_inner_handle</a></li>
<li><a href='DBD/_/dr.html#_f_trace' target='mainframe'>trace</a></li>
<li><a href='DBD/_/dr.html#_f_trace_msg' target='mainframe'>trace_msg</a></li>
</ul>
</li>
</ul>
</li>
<li><a href='DBD/_/st.html' target='mainframe'>DBD::_::st</a>
		<ul>
		<li><a href='DBD/_/st.html#summary' target='mainframe'>Summary</a></li>
		<li><a href='DBD/_/st.html#members' target='mainframe'>Public Members</a>
			<ul>
			<li><a href='DBD/_/st.html#_m_Active' target='mainframe'>Active</a></li>
<li><a href='DBD/_/st.html#_m_ActiveKids' target='mainframe'>ActiveKids</a></li>
<li><a href='DBD/_/st.html#_m_ChopBlanks' target='mainframe'>ChopBlanks</a></li>
<li><a href='DBD/_/st.html#_m_CompatMode' target='mainframe'>CompatMode</a></li>
<li><a href='DBD/_/st.html#_m_CursorName' target='mainframe'>CursorName</a></li>
<li><a href='DBD/_/st.html#_m_Database' target='mainframe'>Database</a></li>
<li><a href='DBD/_/st.html#_m_ErrCount' target='mainframe'>ErrCount</a></li>
<li><a href='DBD/_/st.html#_m_Executed' target='mainframe'>Executed</a></li>
<li><a href='DBD/_/st.html#_m_FetchHashKeyName' target='mainframe'>FetchHashKeyName</a></li>
<li><a href='DBD/_/st.html#_m_HandleError' target='mainframe'>HandleError</a></li>
<li><a href='DBD/_/st.html#_m_HandleSetErr' target='mainframe'>HandleSetErr</a></li>
<li><a href='DBD/_/st.html#_m_InactiveDestroy' target='mainframe'>InactiveDestroy</a></li>
<li><a href='DBD/_/st.html#_m_Kids' target='mainframe'>Kids</a></li>
<li><a href='DBD/_/st.html#_m_LongReadLen' target='mainframe'>LongReadLen</a></li>
<li><a href='DBD/_/st.html#_m_LongTruncOk' target='mainframe'>LongTruncOk</a></li>
<li><a href='DBD/_/st.html#_m_NAME' target='mainframe'>NAME</a></li>
<li><a href='DBD/_/st.html#_m_NAME_hash' target='mainframe'>NAME_hash</a></li>
<li><a href='DBD/_/st.html#_m_NAME_lc' target='mainframe'>NAME_lc</a></li>
<li><a href='DBD/_/st.html#_m_NAME_lc_hash' target='mainframe'>NAME_lc_hash</a></li>
<li><a href='DBD/_/st.html#_m_NAME_uc' target='mainframe'>NAME_uc</a></li>
<li><a href='DBD/_/st.html#_m_NAME_uc_hash' target='mainframe'>NAME_uc_hash</a></li>
<li><a href='DBD/_/st.html#_m_NULLABLE' target='mainframe'>NULLABLE</a></li>
<li><a href='DBD/_/st.html#_m_NUM_OF_FIELDS' target='mainframe'>NUM_OF_FIELDS</a></li>
<li><a href='DBD/_/st.html#_m_NUM_OF_PARAMS' target='mainframe'>NUM_OF_PARAMS</a></li>
<li><a href='DBD/_/st.html#_m_PRECISION' target='mainframe'>PRECISION</a></li>
<li><a href='DBD/_/st.html#_m_ParamArrays' target='mainframe'>ParamArrays</a></li>
<li><a href='DBD/_/st.html#_m_ParamTypes' target='mainframe'>ParamTypes</a></li>
<li><a href='DBD/_/st.html#_m_ParamValues' target='mainframe'>ParamValues</a></li>
<li><a href='DBD/_/st.html#_m_PrintError' target='mainframe'>PrintError</a></li>
<li><a href='DBD/_/st.html#_m_PrintWarn' target='mainframe'>PrintWarn</a></li>
<li><a href='DBD/_/st.html#_m_Profile' target='mainframe'>Profile</a></li>
<li><a href='DBD/_/st.html#_m_RaiseError' target='mainframe'>RaiseError</a></li>
<li><a href='DBD/_/st.html#_m_ReadOnly' target='mainframe'>ReadOnly</a></li>
<li><a href='DBD/_/st.html#_m_RowsInCache' target='mainframe'>RowsInCache</a></li>
<li><a href='DBD/_/st.html#_m_SCALE' target='mainframe'>SCALE</a></li>
<li><a href='DBD/_/st.html#_m_ShowErrorStatement' target='mainframe'>ShowErrorStatement</a></li>
<li><a href='DBD/_/st.html#_m_Statement' target='mainframe'>Statement</a></li>
<li><a href='DBD/_/st.html#_m_TYPE' target='mainframe'>TYPE</a></li>
<li><a href='DBD/_/st.html#_m_Taint' target='mainframe'>Taint</a></li>
<li><a href='DBD/_/st.html#_m_TaintIn' target='mainframe'>TaintIn</a></li>
<li><a href='DBD/_/st.html#_m_TaintOut' target='mainframe'>TaintOut</a></li>
<li><a href='DBD/_/st.html#_m_TraceLevel' target='mainframe'>TraceLevel</a></li>
<li><a href='DBD/_/st.html#_m_Type' target='mainframe'>Type</a></li>
<li><a href='DBD/_/st.html#_m_Warn' target='mainframe'>Warn</a></li>
</ul>
</li>
<li><a href='DBD/_/st.html#method_detail' target='mainframe'>Methods</a>
			<ul>
			<li><a href='DBD/_/st.html#_f_bind_col' target='mainframe'>bind_col</a></li>
<li><a href='DBD/_/st.html#_f_bind_columns' target='mainframe'>bind_columns</a></li>
<li><a href='DBD/_/st.html#_f_bind_param' target='mainframe'>bind_param</a></li>
<li><a href='DBD/_/st.html#_f_bind_param_array' target='mainframe'>bind_param_array</a></li>
<li><a href='DBD/_/st.html#_f_bind_param_inout' target='mainframe'>bind_param_inout</a></li>
<li><a href='DBD/_/st.html#_f_can' target='mainframe'>can</a></li>
<li><a href='DBD/_/st.html#_f_dump_results' target='mainframe'>dump_results</a></li>
<li><a href='DBD/_/st.html#_f_err' target='mainframe'>err</a></li>
<li><a href='DBD/_/st.html#_f_errstr' target='mainframe'>errstr</a></li>
<li><a href='DBD/_/st.html#_f_execute' target='mainframe'>execute</a></li>
<li><a href='DBD/_/st.html#_f_execute_array' target='mainframe'>execute_array</a></li>
<li><a href='DBD/_/st.html#_f_execute_for_fetch' target='mainframe'>execute_for_fetch</a></li>
<li><a href='DBD/_/st.html#_f_fetch' target='mainframe'>fetch</a></li>
<li><a href='DBD/_/st.html#_f_fetchall_arrayref' target='mainframe'>fetchall_arrayref</a></li>
<li><a href='DBD/_/st.html#_f_fetchall_hashref' target='mainframe'>fetchall_hashref</a></li>
<li><a href='DBD/_/st.html#_f_fetchrow_array' target='mainframe'>fetchrow_array</a></li>
<li><a href='DBD/_/st.html#_f_fetchrow_arrayref' target='mainframe'>fetchrow_arrayref</a></li>
<li><a href='DBD/_/st.html#_f_fetchrow_hashref' target='mainframe'>fetchrow_hashref</a></li>
<li><a href='DBD/_/st.html#_f_finish' target='mainframe'>finish</a></li>
<li><a href='DBD/_/st.html#_f_func' target='mainframe'>func</a></li>
<li><a href='DBD/_/st.html#_f_parse_trace_flag' target='mainframe'>parse_trace_flag</a></li>
<li><a href='DBD/_/st.html#_f_parse_trace_flags' target='mainframe'>parse_trace_flags</a></li>
<li><a href='DBD/_/st.html#_f_private_attribute_info' target='mainframe'>private_attribute_info</a></li>
<li><a href='DBD/_/st.html#_f_rows' target='mainframe'>rows</a></li>
<li><a href='DBD/_/st.html#_f_set_err' target='mainframe'>set_err</a></li>
<li><a href='DBD/_/st.html#_f_state' target='mainframe'>state</a></li>
<li><a href='DBD/_/st.html#_f_swap_inner_handle' target='mainframe'>swap_inner_handle</a></li>
<li><a href='DBD/_/st.html#_f_trace' target='mainframe'>trace</a></li>
<li><a href='DBD/_/st.html#_f_trace_msg' target='mainframe'>trace_msg</a></li>
</ul>
</li>
</ul>
</li>
<li><a href='DBI.html' target='mainframe'>DBI</a>
		<ul>
		<li><a href='DBI.html#summary' target='mainframe'>Summary</a></li>
		<li><a href='DBI.html#exports' target='mainframe'>Exports</a>
			<ul>
			<li><a href='DBI.html#_e_:sql_cursor_types' target='mainframe'>:sql_cursor_types</a></li>
<li><a href='DBI.html#_e_:sql_types' target='mainframe'>:sql_types</a></li>
</ul>
</li>
<li><a href='DBI.html#members' target='mainframe'>Public Members</a>
			<ul>
			<li><a href='DBI.html#_m_$DBI::err' target='mainframe'>$DBI::err</a></li>
<li><a href='DBI.html#_m_$DBI::errstr' target='mainframe'>$DBI::errstr</a></li>
<li><a href='DBI.html#_m_$DBI::lasth' target='mainframe'>$DBI::lasth</a></li>
<li><a href='DBI.html#_m_$DBI::rows' target='mainframe'>$DBI::rows</a></li>
<li><a href='DBI.html#_m_$DBI::state' target='mainframe'>$DBI::state</a></li>
</ul>
</li>
<li><a href='DBI.html#method_detail' target='mainframe'>Methods</a>
			<ul>
			<li><a href='DBI.html#_f_available_drivers' target='mainframe'>available_drivers</a></li>
<li><a href='DBI.html#_f_connect' target='mainframe'>connect</a></li>
<li><a href='DBI.html#_f_connect_cached' target='mainframe'>connect_cached</a></li>
<li><a href='DBI.html#_f_data_diff' target='mainframe'>data_diff</a></li>
<li><a href='DBI.html#_f_data_sources' target='mainframe'>data_sources</a></li>
<li><a href='DBI.html#_f_data_string_desc' target='mainframe'>data_string_desc</a></li>
<li><a href='DBI.html#_f_data_string_diff' target='mainframe'>data_string_diff</a></li>
<li><a href='DBI.html#_f_disconnect_all' target='mainframe'>disconnect_all</a></li>
<li><a href='DBI.html#_f_hash' target='mainframe'>hash</a></li>
<li><a href='DBI.html#_f_installed_drivers' target='mainframe'>installed_drivers</a></li>
<li><a href='DBI.html#_f_installed_versions' target='mainframe'>installed_versions</a></li>
<li><a href='DBI.html#_f_looks_like_number' target='mainframe'>looks_like_number</a></li>
<li><a href='DBI.html#_f_neat' target='mainframe'>neat</a></li>
<li><a href='DBI.html#_f_neat_list' target='mainframe'>neat_list</a></li>
<li><a href='DBI.html#_f_parse_dsn' target='mainframe'>parse_dsn</a></li>
<li><a href='DBI.html#_f_trace' target='mainframe'>trace</a></li>
<li><a href='DBI.html#_f_trace_msg' target='mainframe'>trace_msg</a></li>
</ul>
</li>
</ul>
</li>

</ul>
<!-- INDEX END -->
</small>
</body>
</html>
EOTOC

is($toc, $expected, 'getTOC');

is($classdoc->writeTOC, $classdoc, 'writeTOC');
unless (-e 't/classdocs/toc.html') {
	fail('writeTOC output file');
}
else {
	open(INF, 't/classdocs/toc.html');
	$txt = <INF>;
	close INF;
	is($txt, $expected, 'writeTOC output file');
}
#
#	clean up after ourselves
#
unlink 't/classdocs/toc.html';
unlink 't/classdocs/index.html';
unlink 't/classdocs/DBI.html';
unlink 't/classdocs/DBD/_/db.html';
unlink 't/classdocs/DBD/_/dr.html';
unlink 't/classdocs/DBD/_/st.html';
rmdir 't/classdocs/DBD/_';
rmdir 't/classdocs/DBD';
rmdir 't/classdocs';
