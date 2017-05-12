package ServiceNow::SOAP;

use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ServiceNow);

use SOAP::Lite;
use LWP::UserAgent;
use HTTP::Cookies;
use File::Basename;
use MIME::Base64;
use XML::Simple;
use Time::HiRes;
use Carp;

our $VERSION = '0.16';

=head1 NAME

ServiceNow::SOAP - A better Perl API for ServiceNow

=head1 SYNOPSIS

    # return a reference to a session object
    $sn = ServiceNow($instancename, $username, $password);
    
    # return a reference to a table object
    $table = $sn->table($tablename);

    # count records
    $count = $table->count(%parameters);
    
    # return a list of sys_ids
    @keys = $table->getKeys(%parameters);
    
    # return a single record as a hash
    $rec = $table->get(sys_id => $sys_id);
    
    # return a set of records as an array of hashes
    @recs = $table->getRecords(%parameters);

    # call getKeys and return a query object
    $qry = $table->query(%parameters);
    
    # fetch the next chunk of records
    @recs = $qry->fetch($numrecs);

    # retrieve a record based on a unique key other than sys_id
    $rec = $table->getRecord($name => $value);
    
    # insert a record
    $sys_id = $table->insert(%parameters);
    
    # insert multiple records
    @results = $table->insert(@records);
    
    # update a record
    $table->update(%parameters);
    
=head1 EXAMPLES

Create session and table objects.

    use ServiceNow::SOAP;
    
    my $sn = ServiceNow("mycompany", $username, $password);
    
    my $computer_tbl = $sn->table("cmdb_ci_computer");
    my $incident_tbl = $sn->table("incident");

Retrieve a small number of records.
 
    my @recs = $computer_tbl->getRecords(
        "location.name" => "London", 
        "operational_status" => "1",
        __order_by => "name", 
        __limit => 500);
    foreach my $rec (@recs) {
        print $rec->{name}, "\n";
    }
    
Count records.
 
    my $count = $computer_tbl->count(
        "location.name" => "London", 
        "operational_status" => "1");
    
Retrieve records in chunks.
 
    my $qry = $computer_tbl->query(
        "location.name" => "London", 
        "operational_status" => "1",
        __order_by => "name");
    while (@recs = $qry->fetch(200)) {
        foreach my $rec (@recs) {
            print $rec->{name}, "\n";
        }
    }
    
Retrieve all the records in a large table. 
 
    my @recs = $computer_tbl->query()->fetchAll();
    
Insert a record.

    my $sys_id = $incident_tbl->insert(
        assignment_group => "Network Support",
        short_description => $short_description,
        impact => 2);

Retrieve a single record based on sys_id.

    my $rec = $incident_tbl->get($sys_id);
    print "number=", $rec->{number}, "\n";

Retrieve a single record based on number.

    my $rec = $incident_tbl->getRecord(number => $number);
    print "sys_id=", $rec->{sys_id}, "\n";
    
Update a record.

    $incident_tbl->update($sys_id,
        assigned_to => "Fred Luddy",
        incident_state => 2);
    
=head1 DESCRIPTION

This module provides access to ServiceNow via SOAP Web Services.

Features of this module include:

=over 

=item *

Support for both Direct Web Services and Scripted Web Services.

=item *

Simplified API which closely mirrors ServiceNow's
L<Direct Web Services API|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API>
documentation.

=item *

Robust methods for reading large amounts of data
which adhere to ServiceNow's L<best practice recommendations|http://wiki.servicenow.com/index.php?title=Web_Services_Integrations_Best_Practices#Queries>.

=back

=cut

our $XMLNS = 'http://www.glidesoft.com/';
our $context; # global variable points to current session

sub SOAP::Transport::HTTP::Client::get_basic_credentials {
    my $user = $context->{user};
    my $pass = $context->{pass};
    warn "Username is null" unless $user;
    # warn "Password is null" unless $pass;
    return $user => $pass;
}

# Convert a list of parameters to SOAP::Data
sub _params {
    my @params;
    # if there are at least 2 parameters then they must be name/value pairs
    while (scalar(@_) > 1) {
        my $name = shift;
        my $value = shift;
        warn "Parameter name appears to be a sys_id"
            if $name =~ /^[0-9A-Fa-f]{32}$/;
        push @params, SOAP::Data->name($name, $value)->type('string');
    }
    if (@_) {
        # there is one parameter left
        $_ = shift;
        if (/^[0-9A-Fa-f]{32}$/) { 
            # it looks like a sys_id
            push @params, SOAP::Data->name(sys_id => $_); 
        }
        else {
            # assume any left over unnamed param is an encoded query
            push @params, SOAP::Data->name(__encoded_query => $_)
        }
    }
    return @params;
}

# print for debugging
sub _trace {
    print @_;
}

sub ServiceNow {
    return ServiceNow::SOAP::Session->new(@_);
}

=head1 EXPORTED FUNCTIONS

=head2 ServiceNow

This C<ServiceNow> function
(which is essentially an alias for C<ServiceNow::SOAP::Session-E<gt>new()>)
is used to obtain a reference to a Session object. 
The Session object essentially holds the URL and
connection credentials for your ServiceNow instance,
and the L<SOAP::Lite> object.

The first argument to this function is the instance,
which can be either a fully qualified URL
(I<e.g.> C<"https://mycompanydev.service-now.com">)
or an instance name (I<e.g.> C<"mycompanydev">).
The second argument is the user name.
The third argument is the password.

Various options can be specified as
name/value pairs following the password.
For a list of options refer to L</set>.

B<Syntax>

    my $sn = ServiceNow($instance, $username, $password, %options);
    
B<Examples>

The following two statements are equivalent.

    my $sn = ServiceNow("https://mycompanydev.service-now.com", "soap.perl", $password);
    my $sn = ServiceNow("mycompanydev", "soap.perl", $password);

Various options can be specified as name/value pairs following the password.
Refer to L</set> for details.

    my $sn = ServiceNow("mycompanydev", $username, $password, 
        query => 100000, trace => 1);
        
=head1 ServiceNow::SOAP::Session

=cut

package ServiceNow::SOAP::Session;

sub new {
    my ($pkg, $url, $user, $pass, @options) = @_;
    Carp::croak "Missing instance" unless $url;
    Carp::carp "Username is blank" unless $user;
    Carp::carp "Password is blank" unless $pass;
    # strip off any trailing slash
    $url =~ s/\/$//; 
    # append '.service-now.com' unless the URL contains a '.'
    $url = $url . '.service-now.com' unless $url =~ /\./;
    # prefix with 'https://' unless the URL already starts with https:
    $url = 'https://' . $url unless $url =~ /^http[s]?:/;
    # This endpoint is a stub.  Endpoint will be changed before each call.
    my $endpoint = "$url/sys_user.do?SOAP";
    my $cookiejar = HTTP::Cookies->new(ignore_discard => 1);
    my @params = (cookie_jar => $cookiejar);
    my $client = SOAP::Lite->proxy($endpoint, @params);
    my $session = {
        url => $url,
        user => $user, 
        pass => $pass,
        trace => 0,
        dv => 0,
        fetch => 250,
        query => 0,
        client => $client,
        cookiejar => $cookiejar,
        private => {}
    };
    bless $session, $pkg;
    $session->set(@options);
    my $trace = $session->{trace};
    $session->trace("url=$url; user=$user") if $trace;
    $context = $session;
    return $session;
}

#
# private method to return a private table for use by this module
#
sub private {
    my ($session, $tablename) = @_;
    my $table = $session->{private}{$tablename};
    if (!$table) {
        $table = $session->table($tablename);
        $session->{private}{$tablename} = $table;
    }
    # make sure DV is always false for private tables
    $table->setDV(0);
    return $table;
}

our $startTime;

sub trace {
    my ($session, $message) = @_;
    ServiceNow::SOAP::_trace $message, "\n" if $message;
}

sub traceBefore {
    my ($session, $methodname) = @_;
    my $trace = $session->{trace};
    return unless $trace;
    my $tablename = $session->{name};
    $| = 1;
    ServiceNow::SOAP::_trace "$methodname...";
    $startTime = Time::HiRes::time();
}

sub traceAfter {
    my ($session, $message) = @_;
    my $trace = $session->{trace};
    return unless $trace;
    my $finishTime = Time::HiRes::time();
    my $elapsed = $finishTime - $startTime;
    ServiceNow::SOAP::_trace sprintf(" %.2fs", $elapsed), 
        $message ? " $message\n" : "\n";
}

sub traceContent {
    my ($session, $content) = @_;
    my $trace = $session->{trace};
    return unless $trace > 1;
    $content = $session->{client}->transport()->http_response()->content()
        unless defined $content;
    ServiceNow::SOAP::_trace $content, "\n" if $content;
}

=head2 call

This method is deprecated and will be removed in a future release.
This is an alias for the L<execute> method described below.

=cut

sub call {
    execute(@_);
}

=head2 connect

Use of this method is optional, but sometimes you want to know up front
whether your connection credentials are valid.
This method tests them by attempting to get the user's profile
from C<sys_user> using C<getRecords>, and trapping the error.
If successful, the session object is returned.
If unsuccessful, null is returned and the error message is in $@.

B<Syntax>

    my $sn = ServiceNow($instancename, $username, $password)->connect()
        or die "Unable to connect to $instancename: $@";

=cut

sub connect {
    my $session = shift;
    my $trace = $session->{trace};
    my $username = $session->{user};
    my $user_tbl = $session->table('sys_user');
    my @recs;
    eval { @recs = $user_tbl->getRecords(user_name => $username) };
    if ($@ or scalar(@recs) != 1 or
            $recs[0]->{user_name} ne $username) {
        my $trace = $session->{trace};
        $session->trace("connect failed") if $trace;
    }
        
    return 0 if $@;
    return 0 unless scalar(@recs) == 1;
    my $rec = $recs[0];
    return 0 unless $rec->{user_name} eq $username;
    return $session;
}

=head2 execute

This method calls the "execute" function on a 
L<Scripted Web Service|http://wiki.servicenow.com/index.php?title=Scripted_Web_Services>.
The first argument is the name of the Scripted Web Service.
This may be followed by input parameters 
which can be passed in as list of key/value pairs
or as a hash reference.
In a list context this method returns the output parameters as a list of key/value pairs.
In a scalar context it returns the output parameters as a hash reference.

Use of this method requires the C<soap_script> role and activation of the 
"Web Services Provider - Scripted" plugin.

B<Syntax>

    my %outputs = $sn->execute($name, %inputs); # %inputs is a list or hash
    my $outputs = $sn->execute($name, $inputs); # $inputs is a hash reference

B<Examples>

    my %outputs = $sn->execute('GetProperty', property => 'glide.product.description');
    my $value = $outputs{'property'};

    my $outputs = $sn->execute('InstanceInfo');
    my @keys = keys %{$outputs->{result}};
    foreach my $key (@keys) {
        my $value = $outputs->{result}->{$key};
        print "$key=$value\n";
    }
    
=cut

sub execute {
    my $session = shift;
    my $function = shift;
    my $trace = $session->{trace};
    my $baseurl = $session->{url};
    my $endpoint = "$baseurl/$function.do?SOAP";
    my $client = $session->{client};
    my @params = 
        (@_ && ref $_[0] eq 'HASH') ?
        ServiceNow::SOAP::_params(%{$_[0]}) :
        ServiceNow::SOAP::_params(@_);
    $session->traceBefore($function);
    $context = $session;
    my $som = $client->endpoint($endpoint)->call('execute' => @params);
    Carp::croak $som->faultdetail if $som->fault;
    $session->traceAfter('');
    my $response = $som->body->{executeResponse};
    if (ref $response eq 'HASH') {
        return wantarray ? %{$response} : $response;
    }
    else {  
        return wantarray ? () : undef;
    }
}

=head2 loadSession

This method loads the session information (I<i.e.> cookies) from a file.
This may be required if you are running the same perl script multiple times
(each time in a separate process)
and you do not want to establish a separate ServiceNow session
each time the script is run.
Use L</saveSession> to save the session identifier to a file
and this method to load the session identifier from the file.

B<Syntax>

    $sn->loadSession($filename);
    
=cut
    
sub loadSession {
    my ($self, $filename) = @_;
    my $cookiejar = $self->{cookiejar};
    $cookiejar->load($filename);
}

=head2 saveSession

This method saves the session information (I<i.e.> cookies) to a file.  
For usage notes refer to L</loadSession> above.

B<Syntax>

    $sn->saveSession($filename);
    
=cut

sub saveSession {
    my ($self, $filename) = @_;
    my $cookiejar = $self->{cookiejar};
    $cookiejar->save($filename);
}

=head2 set

This method permits assignment of various default values and processing options.
The same options can also be specified
following the password argument of L</ServiceNow>.

The following options may be specified.

=over

=item *

C<dv> - Specify a default value for Display Values.
This can be overridden at the Table level by L</setDV>.
For an explanation of values see L</setDV>.
This option is only effective if it is changed
prior to calling the L</table> method.

=item *

C<fetch> - Specify default number of records to be retrieved
by L</fetch>. Default is 250.
This option will be ignored if it is overridden
by a parameter to L</fetch> or L</fetchAll>.

=item *

C<query> - Specify the number of keys to be retrieved by
L</query> in each call to L</getKeys>.
The default is 0,
which causes all keys to be retrieved 
in a single call.

=item *

C<timeout> - Specify a 
SOAP::Transport::HTTP::Client timeout value.

=item *

C<trace> - Specify a trace level.
Refer to L</DIAGNOSTICS> below.
Default is 0.

=back

B<Syntax>

    $sn->set(%options);
    
B<Example>

    $sn->set(query => 100000, trace => 1);

=cut

sub set {
    my $self = shift;
    while (@_) {
        my $key = shift;
        my $value = shift;
        Carp::croak '"fetch" must be greater than 0'
            if $key eq "fetch" and $value < 1;
        Carp::croak "option \"$key\" not recognized"
            unless $key =~ /^(dv|fetch|query|timeout|trace)$/;                       
        $self->{$key} = $value;
        if ($key eq 'timeout' and $value > 0) {
            $self->{client}->transport->timeout($value);
        }        
    }
    return $self;
}    

sub setTrace {
    my ($self, $trace) = @_;
    $self->{trace} = $trace;
    return $self;
}

=head2 soap

This method returns a reference to the underlying 
L<SOAP::Lite> object.

=cut

sub soap {
    my $self = shift;
    return $self->{client};
}

=head2 table

Used to obtain a reference to a Table object.  
The Table object is subsequently used for 
L</ServiceNow::SOAP::Table> methods described below.

B<Syntax>

    $table = $sn->table($tablename);

B<Example>

    my $computer_tbl = $sn->table("cmdb_ci_computer");
    
=cut

sub table {
    my ($self, $name) = @_;
    my $table = ServiceNow::SOAP::Table->new($self, $name);
    $table->setTrace($self->{trace}) if $self->{trace};
    return $table;
}

=head1 ServiceNow::SOAP::Table

Table objects are used for ServiceNow's
L<Direct Web Services API|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API>.

To obtain a Table object,
use the L</table> method describe above.

The following Table object methods provide access to Direct Web Services API methods of the same name:
L</deleteRecord>,
L</get>,
L</getKeys>,
L</getRecords>,
L</insert>,
L</insertMultiple>,
L</update>.

=cut

package ServiceNow::SOAP::Table;

# utility function to return true if argument is a sys_id
sub _isGUID { 
    return $_[0] =~ /^[0-9A-Fa-f]{32}$/; 
}

# utility function to truncate a string
our $TRACE_LENGTH = 100;
sub _trunc { 
    my ($str, $len) = @_;
    $len = $TRACE_LENGTH unless $len;
    return length($str) < $len ? $str : substr($str, 0, $len - 2) . "..";
}

sub _params {
    return ServiceNow::SOAP::_params @_;
}

sub new {
    my ($pkg, $session, $name) = @_;
    $context = $session;
    my $baseurl = $session->{url}; 
    my $endpoint = "$baseurl/$name.do?SOAP";
    my $new = bless {
        session => $session,
        name => $name,
        endpoint => $endpoint,
        dv => $session->{dv},
        trace => $session->{trace}
    }, $pkg;
    return $new;
}

sub callMethod {
    my $self = shift;
    my $methodname = shift;
    my $tablename = $self->{name};
    my $session = $self->{session};
    my $client = $session->{client};
    my $baseurl = $session->{url};
    my $endpoint = "$baseurl/$tablename.do?SOAP";
    if ($methodname =~ /^(get|getRecords|aggregate)$/ && $self->{dv}) {
        my $dv = $self->{dv};
        $endpoint = "$baseurl/$tablename.do?displayvalue=" . $dv . "&SOAP";
    }
    $context = $self->{session};
    my $method = SOAP::Data->name($methodname)->attr({xmlns => $XMLNS});
    # my @params = ServiceNow::SOAP::_params(@_);
    my $som = $client->endpoint($endpoint)->call($method => @_);
    Carp::croak $som->faultdetail if $som->fault;        
    return $som;
}

sub traceBefore {
    my ($table, $methodname) = @_;
    my $session = $table->{session};
    my $trace = $session->{trace};
    return unless $trace;
    my $tablename = $table->{name};
    $session->traceBefore("$methodname $tablename");
}

sub traceAfter {
    my ($table, $message, $content) = @_;
    my $session = $table->{session};
    my $trace = $session->{trace};
    return unless $trace;
    $session->traceAfter($message ? $message : '');
    return if $trace < 2;
    $session->traceContent($content);
}

=head2 addComment

This method adds a comment to a task.

See also: L</getComments>, L</getJournalEntries>

B<Syntax>

    $table->addComment($sys_id, $comment);
    
=cut

sub addComment {
    my ($self, $sysid, $comment) = @_;
    $self->update($sysid, 'comments' => $comment);
    return $self;
}

=head2 addWorkNote

This method adds a work note to a task.

See also: L</getWorkNotes>, L</getJournalEntries>

B<Syntax>

    $table->addWorkNote($sys_id, $work_note);
    
=cut

sub addWorkNote {
    my ($self, $sysid, $note) = @_;
    $self->update($sysid, 'work_notes' => $note);
    return $self;
}

=head2 asQuery

This method creates a new L<Query|/ServiceNow::SOAP::Query> object
from a list of keys.
It does not make any Web Services calls.
It simply makes a copy of the list.
Each item in the list must be a sys_id for the respective table.

B<Syntax>

    $query = $table->asQuery(@keys);

B<Example>

In this example, we assume that C<@incRecs> contains an array of C<incident> records
from a previous query.
We need an array of C<sys_user_group> records
for all referenced assignment groups.
We use C<map> to extract a list of assignment group keys from the C<@incRecs>;
C<grep> to discard the blanks; and C<uniq> to discard the duplicates.
C<@grpKeys> contains the list of C<sys_user_group> keys.
This array is then used to construct a new Query using L</asQuery>.
L</fetchAll> is used to retrieve the records.

    use List::MoreUtils qw(uniq);

    my @grpKeys = uniq grep { !/^$/ } map { $_->{assignment_group} } @incRecs;
    my @grpRecs = $sn->table("sys_user_group")->asQuery(@grpKeys)->fetchAll();
        
=cut

sub asQuery {
    my $self = shift;
    my $query = ServiceNow::SOAP::Query->new($self);
    my @keys = @_;
    $query->{keys} = \@keys;
    $query->{count} = scalar(@keys);
    $query->{params} = {};
    $query->{index} = 0;
    return $query;
}
    
=head2 attachFile

If you are using Perl to create incident tickets,
then you may have a requirement to attach files to those tickets.

This method implements the
L<attachment creator API|http://wiki.servicenow.com/index.php?title=AttachmentCreator_SOAP_Web_Service>.
The method requires C<soap_ecc> role.

When you attach a file to a ServiceNow record,
you can optionally specify an attachment name
which is different from the actual file name.
If no attachment name is specified,
this function will
assume that the attachment name is the 
the file name stripped of any directory.

You can also optionally specify a MIME type.
If no type is specified,
the function will use L<MIME::Types>
to infer the type.

This function will die if the file cannot be read.

B<Syntax>

    $table->attachFile($sys_id, $filepath);
    $table->attachFile($sys_id, $filepath, $attachment_name, $mime_type);

B<Example>

    $incident_tbl->attachFile($sys_id, "screenshot.png");
    
=cut

sub attachFile {
    my $self = shift;
    my $session = $self->{session};
    my $tablename = $self->{name};
    my ($sysid, $filepath, $attachname, $mimetype) = @_;
    Carp::croak "attachFile: No such record" unless $self->get($sysid);
    my ($parsename, $parsepath, $suffix ) = 
        File::Basename::fileparse($filepath, "\.[^.]*");
    if (!$attachname) {
        $attachname = $parsename . $suffix;
    }
    if (!$mimetype) {
        require MIME::Types;
        my $typer = MIME::Types->new;
        $mimetype = $typer->mimeTypeOf($suffix);
    }
    Carp::croak "Unable to read file \"$filepath\"" unless -r $filepath;
    my $ecc_queue = $session->private('ecc_queue');
    open my $fh, '<', $filepath 
        or die "Unable to open \"$filepath\"\n$!";
    binmode $fh;
    my ($buf, $base64);
    # encode in multiples of 57 bytes to ensure no padding in the middle
    while (read $fh, $buf, 60*57) {
        $base64 .= MIME::Base64::encode_base64($buf);
    }
    close $fh;
    my $len = length($base64);
    print "attachment name=$attachname:$mimetype len=$len\n";
    my $ecc_id = $ecc_queue->insert(
        topic => 'AttachmentCreator',
        name => "$attachname:$mimetype",
        source => "$tablename:$sysid",
        payload => $base64
    );
    die "attachFile failed" unless $ecc_id;
}

=head2 columns

This method returns a list of the columns in a table.
The list is retrieved from the WSDL.

B<Syntax>

    @columns = $table->columns();
    
=cut

sub columns {
    my $self = shift;
    return @{$self->{columns}} if $self->{columns};
    my %fields = $self->getFields();
    my @columns = sort keys %fields;
    $self->{columns} = \@columns;
    return @columns;
}

=head2 count

This method counts the number of records in a table, 
or the number of records that match a set of parameters.

This method requres installation of the
L<Aggregate Web Service plugin|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#aggregate>.

See also: L</countBy>

B<Syntax >

    $count = $table->count();
    $count = $table->count($encodedQuery);
    $count = $table->count(%parameters);

B<Examples>

Count the total number of users:

    my $count = $sn->table("sys_user")->count();
    
Count the number of active users:

    my $count = $sn->table("sys_user")->count(active => true);
    
=cut

sub count {
    my $self = shift;
    my @params = (COUNT => 'sys_id', @_);
    $self->traceBefore('aggregate count');
    my $som = $self->callMethod('aggregate' => _params(@params));
    my $count = $som->body->{aggregateResponse}{aggregateResult}{COUNT};
    $self->traceAfter("count=$count");
    return $count;
}

=head2 countBy

This method counts the number of records in a table
using a GROUP_BY parameter,
which must be the name of a column in the table.
As with L</count>,
an encoded query or set of filter parameters can be specified.
The method returns a list of name/value pairs.

This method requres installation of the
L<Aggregate Web Service plugin|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#aggregate>.

See also: L</count>

B<Syntax>

    %counts = $table->countBy($groupByColumn);
    %counts = $table->countBy($groupByColumn, $encodedQuery);
    %counts = $table->countBy(%groupByColumn, %parameters);

B<Example>

    my %counts = $sn->table("incident")->countBy("category");
    foreach my $key (keys %counts) {
        my $count = $counts{$key};
        print "category: $key, count: $count\n";
    }

=cut

sub countBy {
    my $self = shift;
    my $groupby = shift;
    Carp::croak "countBy missing groupby field" unless $groupby;
    my @params = (COUNT => 'sys_id', GROUP_BY => $groupby, @_);
    $self->traceBefore('aggregate count');
    my $som = $self->callMethod('aggregate' => _params(@params));
    my @aggResults = @{$som->body->{aggregateResponse}{aggregateResult}};
    my $rows = @aggResults;
    $self->traceAfter("rows=$rows");
    my %results;
    foreach my $agg (@aggResults) {
        my $key = $agg->{$groupby};
        my $count = $agg->{COUNT};
        $results{$key} = $count;
    }
    return %results;
}

=head2 deleteRecord

This method deletes a record using the sys_id.
For information on available parameters
refer to the ServiceNow documentation on the 
L<"deleteRecord" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#deleteRecord>.

B<Syntax>

    $table->deleteRecord(sys_id => $sys_id);
    $table->deleteRecord($sys_id);

=cut

sub deleteRecord {
    my $self = shift;
    if (_isGUID($_[0])) { unshift @_, 'sys_id' };
    my %values = @_;
    my $sysid = $values{sys_id};
    $self->traceBefore("deleteRecord $sysid");
    my $som = $self->callMethod('deleteRecord', _params(@_));
    $self->traceAfter();
    return $self;
}

=head2 except

This method returns a list of all columns in the table
B<except> those in the argument list.
The argument(s) to this method can be either a string 
containing a comma separated list of names
or a list of names (I<i.e.> C<qw>).
This method returns a string containing a comma separated list of names.

The [only useful] purpose of this function
is to that you can pass the result back in as an
C<__exclude_columns>
L<extended query parameter|http://wiki.servicenow.com/index.php?title=Direct_Web_Services#Extended_Query_Parameters>.

See also: L</exclude>, L</include>

B<Syntax>

    $names = $table->except(@list_of_columns);
    $names = $table->except($comma_separated_list_of_columns);
    
B<Example>

This example retrieves the columns sys_id, number and description
from the incident table.
In other words, 
the result excludes all columns B<except> sys_id, number and description.

    my $incident_tbl = $sn->table("incident");
    my @recs = $incident_tbl->getRecords(
        __encoded_query => "sys_created_on>=$datetime",
        __exclude_columns => 
            $incident_tbl->except("sys_id,number,description"),
        __limit => 250);
 
=cut

sub except {
    my $self = shift;
    my %names = map { $_ => 1 } split /,/, join(',', @_);
    my @excl = grep { !$names{$_} } $self->columns();
    return join(',', @excl);
}
=head2 get

This method retrieves a single record based on sys_id.
The result is returned as a reference to a hash.

If no matching record is found then null is returned.

For additional information refer to the ServiceNow documentation on the 
L<"get" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#get>.

B<Syntax>

    $rec = $table->get(sys_id => $sys_id);
    $rec = $table->get($sys_id);

B<Example>
    
    my $rec = $table->get($sys_id);
    print $rec->{name};
    
=cut

sub get {
    my $self = shift;
    my $tablename = $self->{name};
    Carp::croak("get $tablename: missing argument") unless @_; 
    if (_isGUID($_[0])) { unshift @_, 'sys_id' };
    $self->traceBefore('get');
    my $som = $self->callMethod('get' =>  _params(@_));
    my $result = $som->body->{getResponse};
    $self->traceAfter($result ? 'ok' : 'fail');
    return $result;
}

=head2 getComments

This method retrieves all comments for a task.
It returns an array of records, each of which contains a C<value> field.

See also: L</addComment>, L</getJournalEntries>

B<Example>

    my @comments = $incident_tbl->getComments($sys_id);
    foreach my $comment (@comments) {
        print $comment->{value}, "\n";
    }
    
=cut

sub getComments {
    my ($self, $sysid) = @_;
    return $self->getJournalEntries($sysid, 'comments');
}

=head2 getJournalEntries

This method retrieves journal fields
(I<i.e.> Work Notes, Comments) for a ticket.

See also: L</getComments>, L</getWorkNotes>

B<Syntax>

    @notes = $table->getJournalEntries($sys_id, $fieldname);
    
B<Example>

    my @notes = $incident_tbl->getJournalEntries($sys_id, 'work_notes');
    foreach my $note (@notes) {
        print $note->{value}, "\n";
    }
    
=cut

sub getJournalEntries {
    my ($self, $sysid, $fieldname) = @_;
    my $session = $self->{session};
    my $sys_journal_field = $session->private('sys_journal_field');
    $fieldname = 'work_notes' unless $fieldname;
    my @params = (element_id => $sysid);
    push @params, 'element' => $fieldname if $fieldname;
    push @params, '__limit' => 1000;
    my @recs = $sys_journal_field->getRecords(@params);
    return @recs;
}

=head2 getKeys

This method returns a list of keys.

Note that this method returns a list of keys, B<NOT> a comma delimited string.

For additional information on available parameters
refer to the ServiceNow documentation on the 
L<"getKeys" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#getKeys>.

B<Syntax>

    @keys = $table->getKeys(%parameters);
    @keys = $table->getKeys($encodedquery);

B<Examples>

    my $cmdb_ci_computer = $sn->table("cmdb_ci_computer");
    
    my @keys = $cmdb_ci_computer->getKeys(operational_status => 1, virtual => "false");
    # or
    my @keys = $cmdb_ci_computer->getKeys("operational_status=1^virtual=false");
    
=cut

sub getKeys {
    my $self = shift;
    $self->traceBefore('getKeys');
    my $som = $self->callMethod('getKeys', _params(@_));
    my @keys = split /,/, $som->result;
    my $count = @keys;
    $self->traceAfter("$count keys");
    return @keys;
}

=head2 getRecord

This method returns a single qualifying records.  
The method returns null if there are no qualifying records.
The method will B<die> if there are multiple qualifying records.

This method is typically used to retrieve a record
based on number or name.

B<Syntax>

    $rec = $table->getRecord(%parameters);
    $rec = $table->getRecord($encodedquery);
    
B<Example>

This example retrieves a B<change_request> record based on B<number>.

    my $chgRec = $sn->table("change_request")->getRecord(number => $number);
    if ($chgRec) {
        print "Short description = ", $chgRec->{short_description}, "\n";
    }
    else {
        print "$number not found\n";
    }

The following two equivalent examples 
illustrate the relationship between 
L</getRecord> and L</getRecords>.

    my @recs = $table->getRecords(%parameters);
    die "Too many records" if scalar(@recs) > 1;
    my $rec = $recs[0];

    my $rec = $table->getRecord(%parameters);

=cut

sub getRecord {
    my $self = shift;
    my $tablename = $self->{name};
    my @recs = $self->getRecords(@_);
    Carp::croak("get $tablename: multiple records returned") if @recs > 1;
    return $recs[0];
}

=head2 getRecords

This method returns a list of records. Actually, it returns a list of hash references.
You may pass this method either a single encoded query string,
or a list of name/value pairs.

For additional information on available parameters
refer to the ServiceNow documentation on the 
L<"getRecords" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#getRecords>.

B<Important Note>: This method will return at most 250 records, unless
you specify a C<__limit> parameter as documented in the ServiceNow wiki under
L<Extended Query Parameters|http://wiki.servicenow.com/index.php?title=Direct_Web_Services#Extended_Query_Parameters>.
For reading large amounts of data,
it is recommended that you use the 
L<Query Object|/ServiceNow::SOAP::Query> 
described below.

B<Syntax>

    @recs = $table->getRecords(%parameters);
    @recs = $table->getRecords($encodedquery);

B<Example>

    my $sys_user_group = $sn->table("sys_user_group");
    my @grps = $sys_user_group->getRecords(
        active => true, __limit => 500, __order_by => "name");
    foreach my $grp (@grps) {
        print $grp->{name}, "\n";
    }
    
=cut

sub getRecords {
    my $self = shift;
    $self->traceBefore('getRecords');
    my $som = $self->callMethod('getRecords', _params(@_));
    my $response = $som->body->{getRecordsResponse};
    unless (ref $response eq 'HASH') {
        $self->traceAfter("0 records");
        return ();
    }
    my $result = $response->{getRecordsResult};
    my $type = ref($result);
    die "getRecords: Unexpected $type" 
        unless ($type eq 'ARRAY' || $type eq 'HASH');
    my @records = ($type eq 'ARRAY') ? @{$result} : ($result);
    my $count = @records;
    $self->traceAfter("$count records");
    return @records;
}

=head2 getName

This method returns the name of this table from L</table>.

=cut

sub getName {
    return shift->{name};
}

=head2 getVariables

This method returns a list of hashes 
of the variables attached to a Requested Item (RITM).

B<Note>: This function currently works only for the C<sc_req_item> table.
This function requires read access to the three tables 
C<item_option_new>,
C<sc_item_option> and
C<sc_item_option_mtom>.

Each hash contains the following five fields:

=over

=item *

name - Name of the variable.

=item *

question - The question text.

=item *

reference - If the variable is a reference, then the name of the table.
Otherwise blank.

=item *

value - Value of the question response.
If the variable is a reference, then value will contain a sys_id.

=item *

order - Order (useful for sorting).

=back

B<Syntax>

    $sc_req_item = $sn->table("sc_req_item");
    @vars = $sc_req_item->getVariables($sys_id);
    
B<Example>

    my $sc_req_item = $sn->table("sc_req_item");
    my $ritmRec = $sc_req_item->getRecord(number => $ritm_number);
    my @vars = $sc_req_item->getVariables($ritmRec->{sys_id});
    foreach my $var (sort { $a->{order} <=> $b->{order} } @vars) {
        my $name = $var->{name};
        my $value = $var->{value};
        print "$name = $value\n";
    }

=cut

sub getVariables {
    my $self = shift;
    Carp::croak "getVariables: invalid table" unless $self->{name} eq 'sc_req_item';
    my $sysid = shift;
    Carp::croak "getVariables: invalid sys_id: $sysid" unless _isGUID($sysid);
    my $session = $self->{session};
    my $sc_item_option      = $session->private('sc_item_option');
    my $sc_item_option_mtom = $session->private('sc_item_option_mtom');
    my $item_option_new     = $session->private('item_option_new');
    my @vmtom = $sc_item_option_mtom->getRecords('request_item', $sysid);
    my $vrefkeys = join ',', map { $_->{sc_item_option} } @vmtom;
    my @vref = $sc_item_option->getRecords('sys_idIN' . $vrefkeys);
    my $vvalkeys = join ',', map { $_->{item_option_new} } @vref;
    my @vval = $item_option_new->getRecords('sys_idIN' . $vvalkeys);
    my %vvalhash = map { $_->{sys_id} => $_ } @vval;
    my @result;
    foreach my $v (@vref) {
        next unless _isGUID($v->{item_option_new});
        my $n = $vvalhash{$v->{item_option_new}};
        my $var = {
            name      => $n->{name},
            reference => $n->{reference},
            question  => $n->{question_text},
            value     => $v->{value},
            order     => $n->{order}
        };
        push @result, $var;
    }
    return @result;
}

=head2 getWorkNotes

This method retrieves all work notes for a task.
It returns an array of records, each of which contains a C<value> field.

See also: L</addWorkNote>, L</getJournalEntries>

B<Example>

    my @notes = $incident_tbl->getWorkNotes($sys_id);
    foreach my $note (@notes) {
        print $note->{value}, "\n";
    }
    
=cut

sub getWorkNotes {
    my ($self, $sysid) = @_;
    return $self->getJournalEntries($sysid, 'work_notes');
}

=head2 insert

This method inserts a record.
In a scalar context, this method returns a sys_id only.
In a list context, this method returns a list of name/value pairs.

For information on available parameters
refer to the ServiceNow documentation on the 
L<"insert" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#insert>.

B<Syntax>

    $sys_id = $table->insert(%values);
    %result = $table->insert(%values);
    
B<Examples>

    my $incident_tbl = $sn->table("incident");

In a scalar context, the function returns a sys_id.

    my $sys_id = $incident_tbl->insert(
        short_description => $short_description,
        assignment_group => "Network Support",
        impact => 3);
    print "sys_id=", $sys_id, "\n";

In a list context, the function returns a list of name/value pairs.

    my %result = $incident_tbl->insert(
        short_description => $short_description,
        assignment_group => "Network Support",
        impact => 3);
    print "number=", $result{number}, "\n";
    print "sys_id=", $result{sys_id}, "\n";

You can also call it this way:

    my %rec;
    $rec{short_description} = $short_description;
    $rec{assignment_group} = "Network Support";
    $rec{impact} = 3;
    my $sys_id = $incident_tbl->insert(%rec);

Note that for reference fields (e.g. assignment_group, assigned_to)
you may pass in either a sys_id or a display value.

=cut

sub insert {
    my $self = shift;
    $self->traceBefore('insert');
    my $som = $self->callMethod('insert', _params(@_));
    my $response = $som->body->{insertResponse};
    my $sysid = $response->{sys_id};
    $self->traceAfter();
    return wantarray ? %{$response} : $sysid;
}

=head2 insertMultiple

This method inserts multiple records.
The input is an array of hash references.
It returns an array of hash references.

This method requires installation of the 
L<ServiceNow Insert Multiple Web Services Plugin|http://wiki.servicenow.com/index.php?title=Web_Service_Import_Sets#Inserting_Multiple_Records>.

For additional information 
refer to the ServiceNow documentation on the 
L<"insertMultiple" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#insertMultiple>.

B<Syntax>

    @results = $table->insertMultiple(@records);

B<Example>

    my $incident_tbl = $sn->table("incident");
    my @allrecs;
    foreach my $descr (@descriptions) {
        my $newrec = {
            short_description => $desc,
            assignment_group => $groupName,
            description => $desc,
            impact => 3};
        push @allrecs, $newrec;
    }
    my @results = $incident_tbl->insertMultiple(@allrecs);
    foreach my $result (@results) {
        print "inserted ", $result->{number}, "\n";
    }

=cut

sub insertMultiple {
    my $self = shift;
    $self->traceBefore('insertMultiple');
    my @params;
    foreach my $rec (@_) {
        Carp::croak "Expected array of hashs" unless ref $rec eq 'HASH';
        push @params, SOAP::Data->name('record' => $rec);
    }
    my $som = $self->callMethod('insertMultiple', @params);
    my $response = $som->body->{insertMultipleResponse};
    my $insertResponse = $response->{insertResponse};
    my @status = @{$insertResponse};
    my $count = scalar(@status);
    $self->traceAfter("$count records inserted");
    return @status;
}

=head2 query

This method creates a new L<Query|/ServiceNow::SOAP::Query> object
by calling L</getKeys>.
You can then use L</fetch> or L</fetchAll>
to retrieve the actual record.

This method normally fetches all keys using a single 
call to L</getKeys>.
However, if the number of keys is too large you may
encounter timeout errors. In this situation the recommendation
is to fetch the keys in chunks by specifying 
a C<query> option in the L</ServiceNow> function.
The suggested initial setting is C<query =E<gt> 100000>.
If timeouts are still a problem then reduce the value further.

B<Syntax>

    $query = $table->query(%parameters);
    $query = $table->query($encodedquery);
    
B<Example>

The following example builds a list of all Incidents 
created between 1/1/2014 and 2/1/2014 sorted by creation date/time.
The L</fetchAll> method fetches chunks of records 
until all records have been retrieved.

    my $filter = "sys_created_on>=2014-01-01^sys_created_on<2014-02-01";
    my $qry = $sn->table("incident")->query(
        __encoded_query => $filter,
        __order_by => "sys_created_on");
    my @recs = $qry->fetchAll();

The following example retrieves all keys for the C<cmdb_ci>
table in chunks of 100,000 at a time.

    my $sn = ServiceNow($instance, $user, $pass, query => 100000);
    my $cmdb_ci_tbl = $sn->table("cmdb_ci");
    my $qry = $cmdb_ci_tbl->query();

=cut

sub query {
    my $table = shift;
    my $session = $table->{session};
    my $limit = $session->{query};
    my $query = ServiceNow::SOAP::Query->new($table);
    # if there is a single parameter it must be an encoded query
    if (@_ == 1) { unshift @_, '__encoded_query' };
    my %params = @_;
    my @keys;
    if ($limit) {
        my $first = 0;
        my $last = $limit;
        while ($first <= @keys) {
            my %p = %params;
            $p{__first_row} = $first;
            $p{__last_row} = $last;
            my @k = $table->getKeys(%p);
            push @keys, @k;
            $first += $limit;
            $last = $first + $limit;
        }
    }
    else {
        @keys = $table->getKeys(%params);
    }
    # parameters which affect order or columns must be preserved
    # so that they can be passed to getRecords
    for my $k (keys %params) {
        delete $params{$k} unless $k =~ /^(__order|__exclude|__use_view)/;
    }
    $query->{keys} = \@keys;
    $query->{count} = scalar(@keys);
    $query->{params} = \%params;
    $query->{index} = 0;
    return $query;
}

=head2 setDV

Used to enable (or disable) display values in queries.
All subsequent calls to L</get>, L</getRecords> or L</getRecord> 
for this table will be affected.
This method returns the modified Table object.

For additional information regarding display values refer to the ServiceNow documentation on
L<"Return Display Value for Reference Variables"|http://wiki.servicenow.com/index.php?title=Direct_Web_Services#Return_Display_Value_for_Reference_Variables>.

B<Syntax>

    $table->setDv("");     # return sys_id only (default)
    $table->setDV("true"); # return display value instead of sys_id
    $table->setDV("all");  # return both sys_id and display value
    $table->setDV(0);      # same as ""
    $table->setDV(1);      # same as "true"
    $table->setDV(2);      # same as "all"

B<Examples>

C<setDV("true")> causes display values to be returned
for all fields instead of original values.

    my $sys_user_group = $sn->table("sys_user_group")->setDV("true");
    my $grp = $sys_user_group->getRecord(name => "Network Support");
    print "manager=", $grp->{manager}, "\n";

C<setDV("all")> causes display values to be returned
in addition to original values. 
Display value fields have a "dv_" prefix.

    my $sys_user_group = $sn->table("sys_user_group")->setDV("all");
    my $grp = $sys_user_group->getRecord(name => "Network Support");
    print "manager=", $grp->{dv_manager}, "\n";

Note that L</setDV> is a Table method, B<not> a Query method.

    @recs = $table->setDV(1)->query()->fetchAll(); # Correct
    @recs = $table->query()->setDV(1)->fetchAll(); # INCORRECT!
    
=cut

sub setDV {
    my ($self, $dv) = @_;
    if ($dv eq '0') { $dv = '' }
    elsif ($dv eq '1') { $dv = 'true' }
    elsif ($dv eq '2') { $dv = 'all' };
    $self->{dv} = $dv;
    return $self;
}

sub getSession {
    return $_[0]->{session};
}

sub setTrace {
    my ($self, $trace) = @_;
    $self->{trace} = $trace;
    return $self;
}

sub getSchema {
    my $self = shift;
    return $self->{wsdl} if $self->{wsdl};
    my $session = $self->{session};
    my $user = $session->{user};
    my $pass = $session->{pass};
    my $baseurl = $session->{url};
    my $host = $baseurl; $host =~ s!^https?://!!;
    my $useragent = LWP::UserAgent->new();
    $useragent->credentials("$host:443", "Service-now", $user, $pass);
    my $tablename = $self->{name};
    $self->traceBefore('wsdl');
    my $response = $useragent->get("$baseurl/$tablename.do?WSDL");
    die $response->status_line unless $response->is_success;
    $self->traceAfter('', $response->content);
    my $wsdl = XML::Simple::XMLin($response->content);
    $self->{wsdl} = $wsdl;
    return $wsdl;
}

sub getFields {
    my ($self, $schematype) = @_;
    my $wsdl = $self->getSchema();
    $schematype = 'getResponse' unless $schematype;
    my $elements = $wsdl->
        {'wsdl:types'}{'xsd:schema'}{'xsd:element'}{$schematype}
        {'xsd:complexType'}{'xsd:sequence'}{'xsd:element'};
    my %result = map { $_ => $elements->{$_}{'type'} } keys %{$elements};
    return %result;
}

    
=head2 update

This method updates a record.
For information on available parameters
refer to the ServiceNow documentation on the 
L<"update" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#update>.

B<Syntax>

    $table->update($sys_id, %parameters);
    $table->update(%parameters);

Note: 
If the first syntax is used, then the C<sys_id>
must be the first parameter.
If the second syntax is used, 
then the C<sys_id> must be included among the parameters.

For reference fields (I<e.g.> assignment_group, assigned_to)
you may pass in either a sys_id or a display value.

B<Examples>

The following three examples are equivalent.

    $incident_tbl->update(
        sys_id => $sys_id, 
        assigned_to => "5137153cc611227c000bbd1bd8cd2005",
        incient_state => 2);
        
    $incident_tbl->update(
        sys_id => $sys_id, 
        assigned_to => "Fred Luddy", 
        incident_state => 2);
    
    $incident_tbl->update($sys_id, 
        assigned_to => "Fred Luddy", 
        incident_state => 2);

=cut

sub update {
    my $self = shift;
    if (_isGUID($_[0])) { unshift @_, 'sys_id' };
    my %values = @_;
    my $sysid = $values{sys_id};
    $self->traceBefore("update");
    my $som = $self->callMethod('update', _params(@_));
    $self->traceAfter();
    return $self;
}

package ServiceNow::SOAP::Query;

=head1 ServiceNow::SOAP::Query
  
Query objects and the related functions implement the ServiceNow's
L<best practice recommendation|http://wiki.servicenow.com/index.php?title=Web_Services_Integrations_Best_Practices#Queries>
for using Web Services to retrieve a large number of records.

A Query object is essentially a list of keys (sys_ids) for a particular table,
and a pointer to the current position in that list.  To construct a new Query object use the L</query> or L</asQuery> Table method.

=over

=item *

L</query> makes a Web Services call (L</getKeys>) to retrieve a list of keys.

=item *

L</asQuery> simply converts an exsiting list of keys into a Query object.

=back

Once the Query is constructed, the L</fetch> and L</fetchAll> functions
can be used to get the actual records in chunks.

B<Example>

This example illustrates the use of Query objects to traverse 
the C<cmdb_rel_ci> table.
The example involves two tables:
C<cmdb_ci> and C<cmdb_rel_ci>.

    my $cmdb_ci_tbl = $sn->table("cmdb_ci");
    my $cmdb_rel_ci_tbl = $sn->table("cmdb_rel_ci");
    
We assume that C<$parentKey> is the sys_id of a known configuration item.
The objective is to print a list of all other configuration items 
on which this item immediately depends.
In otherwords, all items which are one level downstream.

First we query C<cmdb_rel_ci> to retrieve a list of 
records for which this item is the parent.
C<@relData> is this list of C<cmdb_rel_ci> records.
If there are more than 250 records, C<fetchAll> will loop internally 
until all records have been retrieved.

    my @relData = $cmdb_rel_ci_tbl->query(parent => $parentKey)->fetchAll();

Next we extract the C<child> field from each of these C<cmdb_rel_ci>
records to create a new list of sys_ids.

    my @childKeys = map { $_->{child} } @relData;

C<@childKeys> now contains a lists of sys_ids for configuration items.
We convert this list of keys into a query object
and fetch the records from the C<cmdb_ci> table.
    
    @childRecs = $cmdb_ci_tbl->asQuery(@childKeys)->fetchAll();
    foreach my $childRec (@childRecs) {
        print $childRec->{name}, "\n";            
    }

=cut

sub new {
    my ($pkg, $table) = @_;
    my $session = $table->{session};
    return bless {
        table => $table,
        count => 0,
        index => 0
    }, $pkg;
}

=head2 exclude

This method will affect any subsequent calls to L</fetch>.
Any columns not specified in the argument(s)
will be excluded from the returned result.
By excluding unneeded columns from the query result, 
it is possible to significantly improve the performance of large queries.
For a simpler way to achieve this objective, refer to the L</include> method below.

You may pass this method either a list of column names, 
or a string containing a comma delimited list of names.
It will override any prior calls to L</exclude> or L</include>.
It returns a reference to the modified Query object.

See also: L</except>, L</include>

B<Syntax>

    $query->exclude(@list_of_columns);
    $query->exclude($comma_delimited_list_of_columns);
    
=cut

sub exclude {
    my $self = shift;
    my $table = $self->{table};
    my $excl = join(',', @_);
    $self->{params}{__exclude_columns} = $excl;
    return $self;
}

=head2 fetch

Fetch the next chunk of records from a table.
Returns a list of hash references.

This method calls L</getRecords> to retrieve the records.
An optional parameter allows specification of the number of records to be retrieved.
If not specified, then the number of records will be based on 
the default chunk size for this Query object.
If there are no remaining records, then an empty list will be returned.

B<Syntax>
    
    @recs = $query->fetch();
    @recs = $query->fetch($numrecs);

B<Example>

This example prints the names of all active users.
Each call to L</getRecords> returns up to 100 users.

    my $sys_user = $sn->table("sys_user);
    $sys_user->query(active => "true", __order_by => "name");
    while (@recs = $query->fetch(100)) {
        foreach my $rec (@recs) {
            print $rec->{name}, "\n";
        }
    }

=cut

sub fetch {
    my ($self, $chunk) = @_;
    my $table = $self->{table};
    my $session = $table->{session};    
    $chunk = $session->{fetch} unless $chunk;
    my @result;
    my $first = $self->{index};
    my $count = $self->{count};
    if ($first < $count) {
        my $last = $first + $chunk - 1;
        my %params = %{$self->{params}};
        $params{__limit} = $chunk if $chunk;
        $last = $count - 1 if $last >= $count;
        my $encodedquery = "sys_idIN" . join(",", @{$self->{keys}}[$first .. $last]);
        @result = $table->getRecords(__encoded_query => $encodedquery, %params);
        $self->{index} = $last + 1;
    }
    return @result;
}

=head2 fetchAll

This method fetches all the records in a Query by calling L</fetch> repeatedly
until there are no more records.
It takes an optional argument which is the number of records 
to be retrieved B<per fetch>.
It returns a list of hash references.

B<Syntax>

    @recs = $query->fetchAll();
    @recs = $query->fetchAll($numrecs);
    
B<Example>

This example prints the names of all active users.
Each call to L</getRecords> returns up to 250 records
since no fetch size was specified and 250 is the default.

    my $sys_user = $sn->table("sys_user);
    my @recs = $sys_user->query(active => "true", __order_by => "name")->fetchAll();
    foreach my $rec (@recs) {
         print $rec->{name}, "\n";
    }

=cut

sub fetchAll {
    my ($self, $chunk) = @_;
    my @result = ();
    while (my @recs = $self->fetch($chunk)) {
        push @result, @recs;
    }
    return @result; 
}

=head2 getCount 

This method returns the total number of keys in the Query.

=cut

sub getCount {
    my $self = shift;
    return $self->{count};
}

=head2 getKeys

This method returns a list of the keys included in the Query.

B<Example>

The following example calls L</getKeys> to create a new query,
and then makes of copy of the query using the same list of keys.

    my $query1 = $table->query($encoded_query);
    my $query2 = $table->asQuery($query1->getKeys());

=cut

sub getKeys {
    my $self = shift;
    return @{$self->{keys}};
}

=head2 include

This method will affect any subsequent calls to L</fetch>
by limiting which columns are returned.
This method utilizes the L</except> method documented above.
By including only the needed columns in the query result,
it is possible to significantly improve the performance of large queries.

You may pass this method either a list of column names,
or a string containing a comma delimited list of names.
It will override any prior calls to L</exclude> or L</include>.
It returns a reference to the modified Query object.

For some reason the Direct Web Services API allows you to specify a 
list of columns to be excluded from the query result,
but there is no similar out-of-box capability 
to specify only the columns to be included.
This function implements the more obviously needed behavior 
by inverting the list.
It uses the WSDL to generate a list of columns returned by L</getRecords>,
and subtracts the specified names to create an C<"__exclude_columns">
extended query parameter.

See also: L</except>, L</exclude>

B<Syntax>

    $query->include(@list_of_columns);
    $query->include($comma_delimited_list_of_columns);
    
B<Example>

This example returns a list of all records in the C<cmdb_ci_computer> table,
but only 5 columns are returned.

    my $tbl = $sn->table("cmdb_ci_computer");
    my $qry = $tbl->query()->include(
        qw(sys_id name sys_class_name operational_status sys_updated_on));
    my @recs = $qry->fetchAll();    

=cut

sub include {
    my $self = shift;
    my $table = $self->{table};
    my $excl = $table->except(split /,/, join(',', @_));
    $self->exclude($excl);
    return $self;
}

sub setIndex {
    my $self = shift;
    $self->{index} = shift;
    return $self;
}

1;

=head1 PROXY

You may have trouble using the SOAP API if you are running Perl behind
a proxy server.  
The easiest solution is to configure the proxy with environment variables
as in this example.

    use ServiceNow::SOAP;
    $ENV{HTTP_PROXY} = "http://my.proxy.server";
    $ENV{HTTPS_PROXY} = $ENV{HTTP_PROXY};
    $ENV{PERL_LWP_ENV_PROXY} = 1;
    my $sn = ServiceNow($instance, $username, $password);

This works because ServiceNow::SOAP is built on top of SOAP::Lite
which is built on top of LWP.
For more information refer to:
L<http://search.cpan.org/dist/libwww-perl/lib/LWP.pm#ENVIRONMENT>

=head1 DIAGNOSTICS

Sometimes, when you are developing a new script,
it seems to hang at a certain point, 
and you just want to know what it is doing.
You can enable tracing of Web Service calls
by setting the C<trace> option
in the L</ServiceNow> function as follows.

    my $sn = ServiceNow($instance, $username, $password, trace => 1);

Set trace to 1 to print a single line for each Web Services call.
Set trace to 2 to print the complete XML result for each call.

If you want even more, then add the following to your code.
This will cause L<SOAP::Lite> to dump the HTTP headers
and content for all messages, both sent and received.

    SOAP::Lite->import(+trace => 'debug');

=head1 AUTHOR

Giles Lewis <gflewis@cpan.org>

=head1 ACKNOWLEDGEMENTS

Greg George, author of L<ServiceNow::Simple>,
from which a number of ideas were sourced. 

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
