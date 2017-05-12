# =============================================================================
package Net::SNMP::Util;
# -----------------------------------------------------------------------------
$Net::SNMP::Util::VERSION = '1.04';
# -----------------------------------------------------------------------------
use strict;
use warnings;

use constant DEBUG => 0;
do { require Data::Dumper; import Data::Dumper; } if DEBUG;


=head1 NAME

Net::SNMP::Util - Utility functions for Net::SNMP

=head1 SYNOPSIS

    @hosts = qw( host1 host2 host3 );
    %oids  = (
        'ifType'  =>   '1.3.6.1.2.1.2.2.1.3',
        'ifXData  => [ '1.3.6.1.2.1.31.1.1.1.1',    # ifName
                       '1.3.6.1.2.1.31.1.1.1.15' ], # ifHighSpeed
        'someMib' =>   '1.3.6.1.4.1.99999.12.3'
    );
    %snmpparams = (
        -version   => 2,
        -community => "comname"
    );

    # Blocking Function
    use Net::SNMP::Util;

    ($result,$error) = snmpawlk(
        hosts => \@hosts,
        oids  => \%oids,
        snmp  => \%snmpparams
    );
    die "[ERROR] $error\n" unless defined $result;

    # Non-blocking One
    use Net::SNMP::Util qw(:para);

    ($result,$error) = snmpparawalk(
        hosts => \@hosts,
        oids  => \%oids,
        snmp  => \%snmpparams
    );
    die "[ERROR] $error\n" unless defined $result;

    # output result sample
    foreach $host ( @hosts ){
        foreach $index ( sort keys %{$result->{$host}{ifType}} ){
            printf "$host - $index - type:%d - %s (%d kbps)\n",
                $result->{$host}{ifType}{$index},
                $result->{$host}{ifXData}[0]{$index},   # ifName
                $result->{$host}{ifXData}[1]{$index};   # ifHighSpeed
        }
    }


=head1 DESCRIPTION

This module, C<Net::SNMP::Util>, gives you functions of SNMP getting operation
interfaces using L<Net::SNMP> communicating with B<multiple hosts> and B<multi-OIDs>.


=head1 OVERVIEW

Functions of C<Net::SNMP::Util> are grouped by type whether using B<Blocking mode>
or B<Non-blocking mode>.


=head2 Blocking Functions

Blocking functions, C<snmpget()>, C<snmpwalk()> and C<snmpbulk()>, are exported
by defalut. These functions use C<Net::SNMP> blocking object and exchange SNMP
messages serially.


=head2 Non-blocking Functions

Using tag C<":para"> or C<":parallel">, Non-Blocking functions which use
C<Net::SNMP> B<Non-blocking object> are exported. These functions can exchange
SNMP messages to multiple hosts and treat response MIB values in order of
message receiving while the loop. These functions will apparently behave in
parallel, so they have "para" in its own names.


=head2 Arguments

The way of passing arguments is unified whether function is Non-blocking or
Blocking.
Basically pass arguments with name and following value like hash pair below;

    $r = snmpwalk( hosts => $hostsval,
                   oids  => $oidval,
                   snmp  => $snmpval );

Mostly original C<Net::SNMP> functions' arguments are able to be passed.

    $r = snmpparabulk(
        hosts => $hostsval, oids => $oidval, snmp => $snmpval
        -maxrepetitions => 20,
        -delay          => 2,
    );

But some original parameter, C<-callback>, C<-nonrepeaters> and C<-varbindlist>
are not supported by reason of a algorithm.


=head3 Argument "hosts"

By argument C<"hosts">, specify hosts to communicate. This takes a hash or
array reference or hostname.

When only hash reference using, it is possible to use prepared C<Net::SNMP>
object like below;

    # Using hash reference with prepared Net::SNMP object
    $session1 = Net::SNMP->session( -hostname=>"www.freshes.org", ... );
    $session2 = Net::SNMP->session( -hostname=>"192.168.10.8",    ... );
    $r = snmpwalk( hosts => {
                        "peach" => $session1,
                        "berry" => $session2
                   }, ...
    );

In this way, keys of hash are not specifying target hosts but just used to
classfy result.

Except such way of using prepered object like above, a temporary C<Net::SNMP>
session object will be made, used and deleted internally and automaticaly. See
the way below, this example will make temporary session with hash parameters of
C<Net::SNMP-E<gt>session()>;

    # Using hash reference with parameters
    $r = snmpwalk( hosts => {
                        "pine" => {
                            -hostname  => "192.168.10.9",
                        },
                        "passion" => {
                            -hostname  => "exchanger.local",
                            -port      => 10161,
                        }
                   }, ...
    );

More hash argument C<"snmp"> are given, it will be used as common parameters
for each temporary session making. This argument C<"snmp"> hash is not only
for hash but also for specifying by array rererence or hostname string.

    # hash "snmp" using examples
    $r = snmpwalk( hosts => {
                        "peach"   => { -hostname  => "www.freshes.org" },
                        "berry"   => { -hostname  => "192.168.10.8"    },
                        "pine"    => { -hostname  => "192.168.20.8",   },
                        "passion" => { -hostname  => "exchanger.local",
                                       -port      => 10161,            },
                   },
                   snmp  => { -community => "4leaf-clover",
                              -timeout   => 10,
                              -retries   => 2,
                   }, ...
    );

    # Using array reference or string
    $r5 = snmpwalk( hosts => [ "dream","rouge","lemonade","mint","aqua" ],
                    snmp  => { -version   => 1,
                               -community => "yes5",
                    }, ...
    );
    $r6 = snmpwalk( hosts => "milkyrose",
                    snmp  => { -version   => 2,
                               -community => "yes5gogo",
                    }, ...
    );

Note that values of arguments C<"host"> in array reference case or hostname
string are used as values of C<-hostname> parameters for C<Net::SNMP>, and
at the same, time used as classfying key of result.


=head3 Arguments "oids"

Specify OIDs to investigate by hash reference argument named C<"oids">. Keys
of this hash will be used as just classfying of result. Values must be an
array reference listing OIDs, or singular OID string. And this hash allows
that these two types are mixed into it.

    $r = snmpwalk( hosts => \@hosts,
                   oids  => {
                        "system" =>   "1.3.6.1.2.1.1",
                        "ifInfo" => [ "1.3.6.1.2.1.2.2.1.3",        # ifType
                                      "1.3.6.1.2.1.31.1.1.1.1", ]   # ifName
                   }, ...
    );

Each value of this C<"oids"> hash will make one B<Var Bindings>. So singular
OID value makes Var Bindings contains one OID, and multiple OID specified by
array reference makes one contains several OIDs.

It is allowed to specify arguments C<"oids"> as array reference. In this case,
result content will not be classfied by keys of OID name but keys of
suboids. See section of "Return Values" below.


=head3 Argument "snmp"

If argument C<"hosts"> is specified, hash argument C<"snmp"> will mean common
parameters to C<Net::SNMP-E<gt>session()> mentioned above.

Well, it is possible to omit parameter C<"host">. In this case, value of
C<"snmp"> will be used to specify the target. Same as argument "hosts",
giving prepared C<Net::SNMP> session object is allowed.

    # Prepared session
    $session = Net::SNMP->session( -hostname => "blossom", ... );
    $r = snmpwalk(  snmp => $session,
                    oids => \%oids,
                    ...
    );
    # Temporary session
    $r = snmpwalk( snmp => { -hostname  => "marine",
                             -community => "heartcatchers",
                   },
                   oids => \%oids,
                   ...
    );


=head3 Forbiddings

These case below causes an error;

=over

=item *

Argument C<"snmp"> with prepared C<Net::SNMP> object and C<"hosts"> are
specified at the same time.
Chomp C<"hosts"> or let parameter C<"snmp"> a hash reference.

    # NG
    $session = Net::SNMP->session( ... );
    $r = snmpwalk(  hosts => \%something,
                    snmp  => $session,
    );

=item *

Non-blocking prepared C<Net::SNMP> object are given as C<"hosts"> or C<"snmp">
value to Blocking functions.

=item *

Blocking prepared C<Net::SNMP> object are given as C<"hosts"> or C<"snmp">
value  to Non-blocking functions.

=back


=head2 Return Values

=head3 Errors

In list context, a hash reference result value and errors string will be
returned. In scalar, only result value will be returned. In both case, critical
errors will make result value B<undef> and make errors string.

If several hosts checking and some errors occured while communicating, each
error messages will be chained to errors string. For checking errors by host
individually or in scalar context, use functions C<get_errhash()>. This function
will return a hash reference which contains error messages for each hosts.

=head3 Gained MIB Values

In success, gained MIB value will be packed into a hash and its reference will
be returned.

For example, case of C<snmpget()> and C<snmpparaget()> operations;

    snmpget( oids => { sysContact =>   "1.3.6.1.2.1.1.4.0",
                       sysInfo    => [ "1.3.6.1.2.1.1.5.0",    # sysName
                                       "1.3.6.1.2.1.1.6.0"  ], # sysLocation
             }, ...
    );

yeilds;

    {
        sysContact => "Cure Flower <k.hanasaki@heartcatchers.com>",
        sysInfo    => [ "palace", "some place, some world" ],
    }

Other functions, value will be a more hash which contains pairs of key as
sub OID and its values. 
For example;

    snmpwalk( oids => { "system" =>   "1.3.6.1.2.1.1",
                        "ifInfo" => [ "1.3.6.1.2.1.2.2.1.3",        # ifType
                                      "1.3.6.1.2.1.31.1.1.1.1", ]   # ifName
              }, ...
    );

yeilds;

    {
        "system"  => {
            "1.0" => "Testing system the fighters are strong enough",
            "2.0" => "1.3.6.1.4.1.99999.1",
            ... ,
        },
        "ifInfo" => [
            {
                "1"         => 62,          # 1.3.6.1.2.1.2.2.1.3.1
                "10101"     => 62,          # 1.3.6.1.2.1.2.2.1.3.10101
                ...
            },
            {
                "1"         => "mgmt",      # 1.3.6.1.2.1.31.1.1.1.1.1
                "10101"     => "1/1",       # 1.3.6.1.2.1.31.1.1.1.1.10101
                ...
            }
        ]
    }

As stated above, when OIDs are specified in an array, values also will be
contained in an array.

If parameter C<"snmp"> decides target host without C<"hosts">, result data
will be the same as above examples yields. If not so, parameter C<"hosts">
is specified, result data of each host will be contained to parentally
hash which key will be identified by hostname.
For example;

    $r1 = snmpget(
        hosts => [ "bloom", "eaglet" ],
        oids => {
                system => [ "1.3.6.1.2.1.1.1.0", "1.3.6.1.2.1.1.3.0" ],
        }, ...
    );

    $r2 = snmpwalk(
        hosts => {
            "kaoru"   => { -hostname => '192.168.11.10', ... },
            "michiru" => { -hostname => '192.168.12.10', ... },
        },
        oids => { "system" =>   "1.3.6.1.2.1.1",
                  "ifInfo" => [ "1.3.6.1.2.1.2.2.1.3",        # ifType
                                "1.3.6.1.2.1.31.1.1.1.1", ]   # ifName
        }, ...
    );

returns hashref;

    # $r1
    {
        "bloom"  => {                       # hostname
            "system" => [ ...VALUES... ]
        },
        "eaglet" => {                       # hostname
            "system" => [ ...VALUES... ]
        }
    }

    # $r2
    {
        "system"  => { 
            "1.0" => "...", "2.0" => "...", ... 
        },
        "ifInfo" => [
            {
                "1"         => 62,          # 1.3.6.1.2.1.2.2.1.3.1
                "10101"     => 62,          # 1.3.6.1.2.1.2.2.1.3.10101
                ...
            },
            {
                "1"         => "mgmt",      # 1.3.6.1.2.1.31.1.1.1.1.1
                "10101"     => "1/1",       # 1.3.6.1.2.1.31.1.1.1.1.10101
                ...
            }
        ]
    }

If OIDs specifying by C<"oids"> are not a hash but an array reference, values
of gained data will be not hash but array.
For example,

    snmpget( oids => [ "1.3.6.1.2.1.1.5.0",     # sysName
                       "1.3.6.1.2.1.1.6.0"  ],  # sysLocation
             }, ...
    );

yeilds;

    [ "takocafe",                               # string of sysName
      "Wakabadai-park, Tokyo" ],                # string of sysLocation


=head2 Callback function

Apart from original C<-callback> option of functions of C<Net::SNMP>,
functions of C<Net::SNMP::Util> provides another callback logic, by specifying
common option, C<-mycallback>. This option is possible to be used whether
Non-blocking or Blocking.

This callback function will be called when each MIB value recieving with
passing arguments; session object, host name, key name and reference to array
of values.

For example, C<snmpget()> and C<snmpparaget()> operations, array contains
values which order is same as a member of parameter C<"oids"> specifys.

    snmpget(
        hosts => \%hosts,
        oids  => { someMIB1 => $oid1,
                   someMIB2 => [ $oid2, $oid3, $oid4 ]
        },
        -mycallback => sub {
            ($session, $host, $key, $valref) = @_;
            # $valref will be;
            #   [ $val1 ]                   when $key is "someMIB1"
            # or 
            #   [ $val2, $val3, $val4 ]     when $key is "someMIB2"
        }
    );

Other functions, passing array reference will contain more array references
which will have two value, sub OID and value. Values ordering rule is, same
as above, a member of parameter C<"oids"> specifys.

    snmpwalk(
        hosts => \%hosts,
        oids  => { someMIB1 => $oid1,
                   someMIB2 => [ $oid2, $oid3, $oid4 ]
        },
        -mycallback => sub {
            ($session, $host, $key, $valref) = @_;
            # $valref will be;
            #   [ [ $suboid1, $val1 ] ]             when $key is "someMIB1"
            # or 
            #   [ [ $suboid2,$val2 ], [ $suboid3,$val3 ], [ $suboid4,$val4 ] ]
            #                                       when $key is "someMIB2"
        }
    );


=cut

# =============================================================================

use Carp qw();
use Scalar::Util qw();
use Net::SNMP;

use base qw( Exporter );
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);
@EXPORT = qw( get_errstr get_errhash snmpget snmpwalk snmpbulk snmpbulk );
@EXPORT_OK = ();
%EXPORT_TAGS = (
    para     => [ @EXPORT,
                  qw( snmpparaget snmpparawalk snmpparabulk snmpparabulkwalk ) ],
);
Exporter::export_ok_tags( qw(para) );
$EXPORT_TAGS{all}      = [ @EXPORT, @EXPORT_OK ];
$EXPORT_TAGS{parallel} = $EXPORT_TAGS{para};

my $_error;
my $_errhash;


# ============================================================================
# private object methods
# ============================================================================
sub _getmanager
{
    my $class = shift;
    my ($command, $session, $table, $error, $host, $key, $boids, $mycb) = @_;

    # check OIDs are array and init storing value
    my @baseoids = ();
    my $vbtype = ref($boids);
    if ( $vbtype eq 'ARRAY' ){
        $table->{$host}{$key} = [];
        push @baseoids, @{$boids};
    } else {
        $table->{$host}{$key} = {};
        push @baseoids, $boids;
    }

    my $self = {
        command  => $command,   # get, get_next or get_bulk
        session  => $session,   # Net::SNMP session object
        table    => $table,     # Storing table
        error    => $error,     # hashref to storage of error
        host     => $host,      # hostname
        key      => $key,       # given keyname by oids
        baseoids => \@baseoids, # baseoid of requested
        curoids  => [@baseoids],# current digging OID
        mycb     => $mycb,      # my callback
        isMulOid => $vbtype     # given oid is plural or not
    };
    Scalar::Util::weaken($self->{session}); # Avoid for circular references
    bless $self, $class;
}

# get current grabing oids to investigate
sub _get_oids
{
    grep { defined $_ } @{$_[0]->{curoids}};
}

# stringify
sub _stringify
{
    my $self = shift;
    sprintf("%s::%s::%s",
        $self->{host}, $self->{key}, join('-',$self->_get_oids())
    );
}

# memorize error message
sub _memo_error
{
    my ($self, $flag) = @_;
    my ($host, $key) = ($self->{host}, $self->{key});
    $self->{error}{$host}{$key} = sprintf( '%s%s %s',
            defined($flag)? "($flag)": '',
            $self->_stringify(),
            $self->{session}->error()
    );
}

#return Net::SNMP getting operation function
sub _exec_operation
{
    my $self = shift;
    my $com  = $self->{command};

    printf "[DEBUG] %s) execute %s\n", $com, $self->_stringify() if DEBUG;

    return
        ( $com eq 'get'      )? $self->{session}->get_request(@_):
        ( $com eq 'get_next' )? $self->{session}->get_next_request(@_):
        ( $com eq 'get_bulk' )? $self->{session}->get_bulk_request(@_):
        undef;
}

# kicker of varBindList treator
sub _treat_varbindings
{
    my $self = shift;
    my $com  = $self->{command};

    printf "[DEBUG] %s) checking %s\n", $com, $self->_stringify() if DEBUG;

    return
        ( $com eq 'get'      )? $self->_treat_get_varbindings():
        ( $com eq 'get_next' )? $self->_treat_getnext_varbindings():
        ( $com eq 'get_bulk' )? $self->_treat_getbulk_varbindings():
        undef;
}


# treating varBindList yeilded by GetRequest
sub _treat_get_varbindings
{
    my $self = shift;
    my ($session, $host, $key) = map { $self->{$_} } qw(session host key);

    # get varBindList and names
    my $vlist = $session->var_bind_list();
    return undef unless defined $vlist; # error
    return 0 unless %{$vlist};          # if result is empty

    my @ret = map { $vlist->{$_} } $session->var_bind_names();

    # kick my callback
    if ( defined $self->{mycb} ){
        my $r = $self->{mycb}->( $session, $host, $key, \@ret);
        return 0 unless $r;             # avoiding to store
    }

    # store data
    if ( $self->{isMulOid} ){
        push @{$self->{table}{$host}{$key}}, @ret;
    } else {
        $self->{table}{$host}{$key} = $ret[0];
    }
    return 0;
}


# treating varBindList yeilded by GetNextRequest
sub _treat_getnext_varbindings
{
    my $self = shift;
    my ($session, $host, $key) = map { $self->{$_} } qw(session host key);

    printf "[DEBUG] %s) parsing %s\n", "get_next", $self->_stringify() if DEBUG;

    # get varBindList and names
    my $vlist = $session->var_bind_list();

#   printf "[DEBUG] %s) vlist:%s\n", "get_next", Dumper($vlist) if DEBUG;

    return undef unless defined $vlist; # error
    return 0 unless %{$vlist};          # if result is empty

    my @names = $session->var_bind_names();
    my $types = $session->var_bind_types();

    # check out of the branch of each oid in varBindList
    my @ret = ();
    my $num = @{$self->{baseoids}};
    my $c   = 0;
    for ( my $i=0; $i<$num; $i++ )
    {
        next unless defined $self->{curoids}[$i];

        my $baseoid = $self->{baseoids}[$i];
        my $name    = shift @names;
        my $type    = $types->{$name};

        if ( $name !~ /^\.?\Q$baseoid.\E(.+)$/ ||
             $type == ENDOFMIBVIEW
        ){
            # the leaf is not-exists or out of branch
            $ret[$i] = undef;
            $self->{curoids}[$i] = undef;
        }
        else {
            # the leaf is within the branch
            $ret[$i] = [ $1, $vlist->{$name} ];
            $self->{curoids}[$i] = $name;
            $c++;
        }
    }
    return 0 if !$c;    # all necessary oids are checked

    # kick my callback
    if ( defined $self->{mycb} ){
        my $r = $self->{mycb}->( $session, $host, $key, \@ret);
        return 0 unless defined $r;     # to stop operate
        return 1 unless $r;             # to avoid to store
    }

    # store data
    if ( $self->{isMulOid} ){
        for ( my $i=0; $i<$num; $i++ ){
            next unless defined $ret[$i];
            next unless @{$ret[$i]};
            my ($suboid, $val) = @{$ret[$i]};
            $self->{table}{$host}{$key}->[$i]{$suboid} = $val;
        }
    } else {
        my ($suboid, $val) = @{$ret[0]};
        $self->{table}{$host}{$key}->{$suboid} = $val;
    }

    return 1;   # return valid number for next investigation
}


# treating varBindList yeilded by GetBulkRequest
sub _treat_getbulk_varbindings
{
    my $self = shift;
    my ($session, $host, $key) = map { $self->{$_} } qw(session host key);

    # get varBindList and names
    my $vlist = $session->var_bind_list();

    return undef unless defined $vlist; # error
    return 0 unless %{$vlist};          # if result is empty

    my @names = $session->var_bind_names();
    my $types = $session->var_bind_types();

    # check out of the branch of each oid in varBindList
    my @ret = ();
    my $num0= @{$self->{baseoids}};
    my $num = @{[$self->_get_oids()]};

    my $c;
    while ( @names ){
        my @n = splice(@names,0,$num);
        for ( my $i=0,$c=0; $i<$num0; $i++ )
        {
            next unless defined $self->{curoids}[$i];

            my $baseoid = $self->{baseoids}[$i];
            my $name    = shift @n;
            my $type    = $types->{$name};

            if ( $name !~ /^\.?\Q$baseoid.\E(.+)$/ ||
                 $type == ENDOFMIBVIEW
            ){
                # the leaf is not-exists or out of branch
                $self->{curoids}[$i] = 0;
            }
            else {
                # the leaf is within the branch
                push @{$ret[$i]}, [ $1, $vlist->{$name} ];
                $self->{curoids}[$i] = $name;
                $c++;
            }
        }
        last if !$c;    # no more check
    }
    for ( my $i=0; $i<$num0; $i++ ){
        $self->{curoids}[$i] ||= undef;
    }

    # kick my callback
    if ( defined $self->{mycb} ){
        my $r = $self->{mycb}->( $session, $host, $key, \@ret);
        return 0 unless defined $r;     # to stop operate
        return 1 unless $r;             # to avoid to store
    }

    # store data
    if ( $self->{isMulOid} ){
        for ( my $i=0; $i<$num0; $i++ ){
            foreach my $leaf ( @{$ret[$i]} ){
                next unless defined $leaf;
                my ($suboid, $val) = @{$leaf};
                $self->{table}{$host}{$key}->[$i]{$suboid} = $val;
            }
        }
    } else {
        foreach my $leaf ( @{$ret[0]} ){
            next unless defined $leaf;
            my ($suboid, $val) = @{$leaf};
            $self->{table}{$host}{$key}->{$suboid} = $val;
        }
    }

    return $c;  # return valid number for next investigation
}

# =============================================================================

sub _parse_params
{
    if ( @_ & 1 ){
        Carp::carp("Odd number of arguments.");
        return (undef, "Odd number of arguments.");
    }
    my %p = @_;
    my %sessions = ();
    my (%istmp,$oids,$mycb) = ();
    my $arghosts = 1;

    my $nonblocking = 0;
    if ( defined $p{nonblocking} ){
        $nonblocking = delete $p{nonblocking};
    }

    # --- checking "snmp" ---
    my $snmphash = undef;
    my $snmpobj  = undef;
    my %errhash  = ();

    if ( defined $p{snmp} ){
        my $type = ref($p{snmp});
        if ( $type eq 'HASH' ){
            $snmphash = delete $p{snmp};
        }
        elsif ( $type eq 'Net::SNMP' ){
            $snmpobj  = delete $p{snmp};
        }
        else {
            return (undef, q(Parameter "snmp" must be a hash reference or Net::SNMP object.));
        }
    }

    # --- parsing "hosts" ---
    if ( defined $p{hosts} )
    {
        if ( defined $snmpobj ){
            return ( undef, q(In case specifying parameters both "hosts" and "snmp", ).
                            q("snmp" must be not Net::SNMP object but a hash reference.) );
        }

        my $type = ref($p{hosts});

        # hosts => \%hashref;
        if ( $type eq 'HASH' ){
            #   regard key as hostname and value as Net::SNMP object or parameter
            while ( my ($host, $value) = each %{$p{hosts}} )
            {
                $type = ref($value);

                # treat value as Net::SNMP object
                if ( $type eq 'Net::SNMP' ){
                    if ( $nonblocking && !$value->nonblocking() ){
                        $errhash{$host} = "About $host, blocking Net::SNMP object ".
                                          "was specified to call non-blocking function.";
                        next;
                    }
                    if ( !$nonblocking && $value->nonblocking() ){
                        $errhash{$host} = "About $host, non-blocking Net::SNMP object ".
                                          "was specified to call blocking function.";
                        next;
                    }
                    $sessions{$host} = $value;
                }

                # if hashref, make temporary sessions.
                elsif ( $type eq 'HASH' ){
                    my ($s, $e) = Net::SNMP->session(
                        %{$snmphash},
                        -nonblocking => $nonblocking,
                        -hostname    => $host,
                        %{$value}
                    );
                    unless ( defined($s) ){
                        $errhash{$host} = "$host, session making error: $e";
                        next;
                    }
                    $sessions{$host} = $s;
                    $istmp{$host}    = 1;
                }

                # othre cases cause error.
                else {
                    # othre reference without string will be an error
                    if ( !$type && defined($value) ){
                        my ($s, $e) = Net::SNMP->session(
                            %{$snmphash},
                            -nonblocking => $nonblocking,
                            -hostname    => $value,
                        );
                        unless ( defined($s) ){
                            $errhash{$host} = "$host, session making error: $e";
                            next;
                        }
                        $sessions{$host} = $s;
                        $istmp{$host}    = 1;
                    } else {
                        return (undef, qq(Value of "$host" must be a string,).
                                       qq( an array reference or a hash reference));
                    }
                }
            }
        }

        # hosts => \@arrayref;
        elsif ( $type eq 'ARRAY' ){
            #   regard it as hostname list
            foreach my $host ( @{$p{hosts}} ){
                my ($s, $e) = Net::SNMP->session(
                    %{$snmphash},
                    -nonblocking => $nonblocking,
                    -hostname    => $host,
                );
                unless ( defined($s) ){
                    $errhash{$host} = "$host, session making error: $e";
                    next;
                }
                $sessions{$host} = $s;
                $istmp{$host}    = 1;
            }

        } else {
            # othre reference will be an error
            if ( $type ){
                return (undef, q(Parameter "hosts" must be a string, an array reference or a hash reference));
            }

            # but string is ok. it will be regards as hostname.
            else {
                my $host = $p{hosts};
                my ($s, $e) = Net::SNMP->session(
                    %{$snmphash},
                    -nonblocking => $nonblocking,
                    -hostname    => $host,
                );
                unless ( defined($s) ){
                    $errhash{$host} = "$host, session making error: $e";
                } else {
                    $sessions{$host} = $s;
                    $istmp{$host}    = 1;
                }
            }
        }
        delete $p{hosts};

        # Erase "snmp" parameter (hashref).
        # this is no longer need.
        $snmphash = undef;
    }
    else {
        $arghosts = 0;
    }

    # --- parsing "snmp" ---
    #   This parsing will be invoked when parameter "host" isn't specified.
    if ( defined $snmpobj ){
        # Net::SNMP object is given, use it as it is.
        if ( $nonblocking && !$snmpobj->nonblocking() ){
            return (undef, "Blocking Net::SNMP object was specified to call non-blocking function.");
        }
        if ( !$nonblocking && $snmpobj->nonblocking() ){
            return (undef, "Non-Blocking Net::SNMP object was specified to call blocking function.");
        }
        $sessions{$snmpobj->hostname()} = $snmpobj;
    }
    if ( defined $snmphash ){
        # Hash reference is given, use it as parameter for making temp session
        my ($s, $e) = Net::SNMP->session(
            %{$snmphash},
            -nonblocking => $nonblocking
        );
        return (undef, "Making session error; $e") unless defined $s;

        $sessions{$s->hostname()} = $s;
        $istmp{$s->hostname()}    = 1;
    }

    # --- parsing "oids" ---
    if ( exists($p{oids}) ){
        my $type = ref($p{oids});
        if ( $type eq 'HASH' ) {
            $oids = $p{oids};
        }
        else {
            $oids = {
                '_ANONY_' => $p{oids}
            };
        }
        # Check type of each oid
        foreach my $oid ( values %{$oids} ){
            unless ( defined $oid ){
                return (undef, "Undefined value specified as OID");
            }
            $type = ref($oid);
            if ( $type && $type ne 'ARRAY' ){
                return (undef, "Each OID values must be an array reference or string");
            }
        }
        delete $p{oids};
    }
    unless ( defined $oids ){
        return (undef, q(Parameter "oids" is not given));
    }

    # --- parsing "-mycallback" ---
    foreach ( qw( mycallback -mycallback ) ){
        if ( defined($p{$_}) ){
            $mycb = delete $p{$_};
            unless ( ref($mycb) eq 'CODE' ){
                Carp::carp("Non code given as -mycallback, ignored.");
                $mycb = undef;
            }
        }
    }
    foreach ( qw( callback -callback ) ){
        if ( defined($p{$_}) ){
            Carp::carp("option $_ is ignored.");
            delete $p{$_};
        }
    }

    # --- parsing end ---
    return (\%sessions,\%errhash,\%istmp,$oids,\%p,$mycb,$arghosts);

}


# =============================================================================

=head1 BLOCKING FUNCTIONS

C<Net::SNMP::Util> exports bloking functions defalut.

=cut

# -----------------------------------------------------------------------------
sub _snmpkick
{
    my $command = shift;

    _clear_error();
    my ($sessions,$error,$istmp,$oids,$opts,$mycb,$arghosts) = _parse_params(
        @_,
        nonblocking => 0
    );
    return _retresults(undef, $error) unless defined $sessions;

    my $table = {};
    while ( my ($host,$session) = each %{$sessions} )
    {
        foreach my $key ( keys %{$oids} ){

            my $oid = $oids->{$key};
            # memo: dont use "while...(each %{$oids})" here.
            #       because when $result is undef by error, not-resetted
            #       iterating counter of %{$oids} will be used at next
            #       $host's loop...
            my $manager = __PACKAGE__->_getmanager(
                $command, $session, $table, $error, $host, $key, $oid, $mycb
            );

            my $result;
            do {
                $result = $manager->_exec_operation(
                    %{$opts},
                    -varbindlist => [ $manager->_get_oids() ],
                );
                unless ( defined $result ){
                    $manager->_memo_error();
                    # if some error occuer, terminate process of
                    # error host and delete data at Blocking Mode
                    delete $table->{$host};
                    last;
                }
            } while ( $manager->_treat_varbindings() );
        }
    }

    # closing temporary session and finishing
    while ( my ($host,$session) = each %{$sessions} ){
        if ( $istmp->{$host} ){
            $session->close();
            undef $session;
        }
    }

    return _retresults($table, $error, $arghosts);
}


# =============================================================================

=head2 snmpget()

C<snmpget()> is a Blocking function which gather MIB values with SNMP
GetRequest operation via C<Net::SNMP-E<gt>get_request()>.

=cut

# -----------------------------------------------------------------------------
sub snmpget
{
    _snmpkick('get', @_);
}


# =============================================================================

=head2 snmpwalk()

C<snmpwalk()> is a Blocking function which gather MIB values with SNMP
GetNextRequest operation via C<Net::SNMP-E<gt>get_next_request()>.

=cut

# -----------------------------------------------------------------------------
sub snmpwalk
{
    _snmpkick('get_next', @_);
}


# =============================================================================

=head2 snmpbulk()

C<snmpbulk()> is a Blocking function which gather MIB values with SNMP
GetBulkRequest operation via C<Net::SNMP-E<gt>get_bulk_request()>. So using
this function needs that target devices are acceptable for SNMP version 2c or
more.

Note that C<-maxrepetitions> should be passed with some value. C<Net::SNMP>
will set this parameter 0 by defalut.
Also note that reason of algorithm, -nonrepeaters is not supported.

=head2 snmpbulkwalk()

An alias of C<snmpbulk()>.

=cut

# -----------------------------------------------------------------------------
sub snmpbulk
{
    _snmpkick('get_bulk', @_, -nonrepeaters=>0 );
}

sub snmpbulkwalk { snmpbulk(@_) }


# =============================================================================

=head1 NON-BLOCKING FUNCTIONS

C<Net::SNMP::Util> gives some Non-blocking functions. Use these Non-blocking
functions, import them with ":para" tag at C<use> pragma.

=cut

# -----------------------------------------------------------------------------
sub _snmpparakick
{
    my $command = shift;

    _clear_error();
    my ($sessions,$error,$istmp,$oids,$opts,$mycb,$arghosts) = _parse_params(
        @_,
        nonblocking => 1
    );
    return _retresults(undef, $error) unless defined $sessions;

    # define callback subroutine
    my $callback = sub {
        my $s = shift;
        my ($this_cb, $m, $opts) = @_;

        # treat VarBindList
        my $r = $m->_treat_varbindings();
        $m->_memo_error() unless defined $r;    # undef means get some error
        return unless $r;                       # not true value terminates

        # request again (at get_next or get_bulk)
        $r = $m->_exec_operation(
            %{$opts},
            -varbindlist => [ $m->_get_oids() ],
            -callback    => [ $this_cb, @_ ],
        );
        $m->_memo_error() unless defined $r;
    };

    # making first request operation
    my $table = {};
    while ( my ($host,$session) = each %{$sessions} )
    {
        while ( my ($key, $oid) = each %{$oids} )
        {
            my $manager = __PACKAGE__->_getmanager(
                $command, $session, $table, $error, $host, $key, $oid, $mycb
            );
            my $result = $manager->_exec_operation(
                %{$opts},
                -varbindlist => [ $manager->_get_oids() ],
                -callback    => [ $callback, $callback, $manager, $opts ],
            );
            $manager->_memo_error() unless defined $result;
        }
    }

    # execute to communicate
    snmp_dispatcher();

    # closing temporary session and finishing
    while ( my ($host,$session) = each %{$sessions} ){
        if ( $istmp->{$host} ){
            $session->close();
            undef $session;
        }
    }

    return _retresults($table, $error, $arghosts);
}


# =============================================================================

=head2 snmpparaget()

C<snmpparaget()> is a Non-blocking function which gather MIB values with SNMP
GetRequest operation via C<Net::SNMP-E<gt>get_request()>.

=cut

# -----------------------------------------------------------------------------
sub snmpparaget
{
    _snmpparakick('get', @_);
}


# =============================================================================

=head2 snmpparawalk()

C<snmpparawalk()> is a Non-blocking function which gather MIB values with SNMP
GetNextRequest operation via C<Net::SNMP-E<gt>get_next_request()>.

=cut

# -----------------------------------------------------------------------------
sub snmpparawalk
{
    _snmpparakick('get_next', @_);
}


# =============================================================================

=head2 snmpparabulk()

C<snmpparabulk()> is a Non-blocking function which gather MIB values with SNMP
GetBulkRequest operation via C<Net::SNMP-E<gt>get_bulk_request()>. So using
this function needs that target devices are acceptable for SNMP version 2c or
more.

Note that C<-maxrepetitions> should be passwd with some value. C<Net::SNMP>
will set this parameter 0 by defalut.
Also note that reason of algorithm, -nonrepeaters is not supported.

=head2 snmpparabulkwalk()

An alias of C<snmpparabulk()>.

=cut


# -----------------------------------------------------------------------------
sub snmpparabulk
{
    _snmpparakick('get_bulk', @_, -nonrepeaters=>0 );
}

sub snmpparabulkwalk { snmpparabulk(@_) }


# =============================================================================

=head1 OTHER FUNCTIONS

=head2 get_errstr()

    $lasterror = get_errstr();

C<get_errstr()> returns last error message string that is chained all of error
messages for each hosts.

=head2 get_errhash()

    $lasterror = get_errhash();

C<get_errhash()> returns hash reference which contains last error messages
identified by host names.

=cut

# -----------------------------------------------------------------------------

sub _clear_error {
    $_error   =
    $_errhash = {};
}

sub get_errstr {
    return $_error;
}
sub get_errhash {
    return $_errhash;
}

sub _retresults {
    my ($table, $error, $arghosts) = @_;

    return unless defined wantarray;

    my %ret = ();
    if ( defined($table) && %{$table} )
    {
        while ( my ($host,$keys) = each %{$table} )
        {
            while ( my ($key, $mibvals) = each %{$keys} )
            {
                if ( $key eq '_ANONY_' ){

                    $table->{$host} = $mibvals;
                    last;
                }
            }
        }
        # No "hosts" option and specified target host by "snmp",
        # the result will not contain hash of hosts.
        $table = (values %{$table})[0] if !$arghosts;
    }

    my $message = '';
    if ( $error ){
        if ( ref($error) eq 'HASH' ){
            foreach my $h ( keys %{$error} ){
                if ( ref($error->{$h}) eq 'HASH' ){
                    $error->{$h} = join('; ', values %{$error->{$h}});
                }
            }
            if ( %{$error} ){
                $message = join("; ", (values %{$error}));
            }
        }
        else {
            $message = $error;
            $error = undef;
        }
    }

    $_error   = $message;
    $_errhash = $error;
    return wantarray? ($table, $message): $table;
}

# =============================================================================

=head1 APPENDIX

C<Net::SNMP::Util> has sub modules; C<Net::SNMP::Util::OID> and
C<Net::SNMP::Util::TC>.

L<Net::SNMP::Util::OID> gives MIBname-OID converter utilities.
For example, you can specify basic OIDs when call function like below;

    use Net::SNMP::Util::OID qw(if*);   # import if* MIB name maps

    %oids  = (
        sysInfo => [
            oid( "ifDescr", "ifType" )  # equals '1.3.6.1.2.1.2.2.1.2','1.3.6.1.2.1.2.2.1.3'
        ],
        oidm("ifName")                  # equals "ifName" => "1.3.6.1.2.1.31.1.1.1.1"
    );
    ($result,$error) = snmpparaawlk(
        hosts => \@hosts,
        oids  => \%oids,
        snmp  => \%snmpparams
    );

L<Net::SNMP::Util::TC> gives MIBEnumValue-Text convertor utilities.
For example, you can convert value of ifAdminStatus, ifOperStatus and ifType
like below;

    use Net::SNMP::Util::TC;

    $tc = Net::SNMP::Util::TC->new;
    $astat  = $tc->ifAdminStatus( $value_admin_stat );  # "up", "down" or etc.
    $ostat  = $tc->ifOperStatus( $value_oper_stat  );
    $iftype = $tc->ifType( $value_iftype  );            # "ethernet-csmacd" or etc.


=head1 PRACTICAL EXAMPLES

=head2 1. Check system information simply

This example get some system entry MIB values from several hosts with C<snmpget()>.

    #!/usr/local/bin/perl
    use strict;
    use warnings;
    use Getopt::Std;
    use Net::SNMP::Util;

    my %opt;
    getopts('hv:c:r:t:', \%opt);

    sub HELP_MESSAGE {
        print "Usage: $0 [-v VERSION] [-c COMMUNITY_NAME] ".
              "[-r RETRIES] [-t TIMEOUT] HOST [,HOST2 ...]\n";
        exit 1;
    }
    HELP_MESSAGE() if ( !@ARGV || $opt{h} );

    (my $version = ($opt{v}||2)) =~ tr/1-3//cd; # now "2c" is ok
    my ($ret, $err) = snmpget(
        hosts => \@ARGV,
        snmp  => { -version   => $version,
                   -timeout   => $opt{t} || 5,
                   -retries   => $opt{r} || 1,
                   -community => $opt{c} || "public" },
        oids  => { descr    => '1.3.6.1.2.1.1.1.0',
                   uptime   => '1.3.6.1.2.1.1.3.0',
                   name     => '1.3.6.1.2.1.1.5.0',
                   location => '1.3.6.1.2.1.1.6.0',
        }
    );
    die "[ERROR] $err\n" unless defined $ret;

    foreach my $h ( @ARGV ){
        if ( $ret->{$h} ){
            printf "%s @%s (up %s) - %s\n",
                 map { $ret->{$h}{$_} or 'N/A' } qw(name location uptime descr);
        } else {
            printf "%s [ERROR]%s\n", $h, $err->{$h};
        }
    }

    __END__


=head2 2. Realtime monitor of host interfaces (SNMPv2c)

This program shows realtime traffic throughput of interfaces of a host on your
console with using C<snmpwalk()> and callbacking.

Notice: This program is for devices which can deal SNMP version 2c.

    #!/usr/local/bin/perl

    use strict;
    use warnings;
    use Getopt::Std;
    use Term::ANSIScreen qw/:color :screen :constants/;
    use Net::SNMP::Util;

    my %opt;
    getopts('hv:c:w:x:', \%opt);
    my $host = shift @ARGV;

    sub HELP_MESSAGE {
        print "Usage: $0 [-c COMMUNITY_NAME] [-w WAIT] [-x REGEXP] HOST\n";
        exit 1;
    }
    HELP_MESSAGE() if ( !$host || $opt{h} );

    my ($wait,$regexp) = ($opt{w}||5, $opt{x}? qr/$opt{x}/: '');
    my $console = Term::ANSIScreen->new();
    local $| = 1;

    # make session
    my ($ses, $err) = Net::SNMP->session(
        -hostname  => $host,
        -version   => "2",
        -community => ($opt{c} || "public")
    );
    die "[ERROR] $err\n" unless defined $ses;

    # main loop
    my (%pdata, %cdata);  # flag, previous and current octets data
    my $first = 1;
    while ( 1 ){
        %cdata = ();
        (my $ret, $err) = snmpwalk(
            snmp => $ses,
            oids => {
                sysUpTime => '1.3.6.1.2.1.1.3',
                ifTable => [
                    '1.3.6.1.2.1.31.1.1.1.1',  # [0] ifName
                    '1.3.6.1.2.1.2.2.1.7',     # [1] ifAdminStatus
                    '1.3.6.1.2.1.2.2.1.8',     # [2] ifOperStatus
                    '1.3.6.1.2.1.31.1.1.1.6',  # [3] ifHCInOctets
                    '1.3.6.1.2.1.31.1.1.1.10', # [4] ifHCOutOctets
                    '1.3.6.1.2.1.31.1.1.1.15', # [5] ifHighSpeed
                ] },
            -mycallback => sub {
                my ($s, $host, $key, $val) = @_;
                return 1 if $key ne 'ifTable';
                my $name = $val->[0][1];
                return 0 if ( $regexp && $name !~ /$regexp/ );
                # storing current octets data
                $cdata{$name}{t} = time;
                $cdata{$name}{i} = $val->[3][1];
                $cdata{$name}{o} = $val->[4][1];
                return 1;
            }
        );
        die "[ERROR] $err\n" unless $ret;

        # header
        $console->Cls();
        $console->Cursor(0, 0);

        printf "%s, up %s - %s\n\n",
            BOLD.$host.CLEAR, $ret->{sysUpTime}{0}, scalar(localtime(time));

        # matrix
        printf "%s%-30s (%-10s) %2s %2s %10s %10s %10s%s\n",
            UNDERSCORE, qw/ifName ifIndex Ad Op BW(Mbps) InBps(M) OutBps(M)/, CLEAR;

        my $iftable = $ret->{ifTable};
        foreach my $i ( sort { $a <=> $b } keys %{$iftable->[1]} )
        {
            my ($name, $astat, $ostat, $bw)
                = map { $iftable->[$_]{$i} } qw( 0 1 2 5 );
            if ( $first ){
                printf "%-30s (%-10d) %2d %2d %10.1f %10s %10s\n",
                    $name, $i, $astat, $ostat, $bw/1000, '-', '-';
                next;   # skip first
            }

            # calculate (k)bps
            my $td = $cdata{$name}{t} - $pdata{$name}{t};
            my ($inbps, $outbps) = map {
                my $delta = $cdata{$name}{$_} - $pdata{$name}{$_};
                $delta<0? 0: $delta / $td / 1000; # Kbps
            } qw( i o );

            printf "%-30s (%-10d) %2d %2d %10.1f %10.1f %10.1f\n",
                $name, $i, $astat, $ostat, map { $_/1000 } ($bw, $inbps, $outbps);
        }

        %pdata = %cdata;
        $first = 0;
        sleep $wait;
    }

    __END__


=head2 3. Tiny MRTG with RRDTool (SNMPv2c)

With installing Tobias Oetiker's RRDTool and RRD::Simple, this sample will do
like MRTG. (It is better to execute this by cron.)

If Environmental variables, PATH2DATADIR and URL2HTMLDIR, are defined, files will
be stored under PATH2DATADIR and URL pathes will include URL2HTMLDIR in html.
Or Modify $datadir and $htmldir to decide these path and URL where browser can
access through your http service.

Notice: This program is for devices which can deal SNMP version 2c.

    #!/usr/local/bin/perl
    use strict;
    use warnings;
    use Getopt::Std;
    use CGI qw(:html);
    use RRD::Simple;        # install the "RRDTool" and RRD::Simple
    use Net::SNMP::Util qw(:para);

    my %opt;
    getopts('hc:x:', \%opt);
    my @hosts = @ARGV;

    sub HELP_MESSAGE {
        print "Usage: $0 [-c COMMUNITY_NAME] [-x REGEXP] HOST [HOST [...]]\n";
        exit 1;
    }
    HELP_MESSAGE() if ( !@hosts || $opt{h} );

    my $datadir = $ENV{PATH2DATADIR} || "/path/to/datadir";   # !!! Modify !!!
    my $htmldir = $ENV{URL2HTMLDIR}  || "/path/to/htmldir";   # !!! Modify !!!
    my $regexp  = $opt{x}? qr/$opt{x}/: '';
    my %sesopts = ( -version => 2, -community=> ($opt{c} || 'public') );

    sub escname {
        my $n = shift;
        $n =~ tr/\\\/\*\?\|"<>:,;%/_/;
        return $n;
    }

    # gather traffic data and store to RRD
    my ($result, $error) = snmpparawalk(
        hosts => \@hosts,
        snmp  => \%sesopts,
        oids  => {
            ifData => [ '1.3.6.1.2.1.31.1.1.1.1',   # ifName
                        '1.3.6.1.2.1.31.1.1.1.6',   # ifHCInOctets
                        '1.3.6.1.2.1.31.1.1.1.10' ] # ifHCOutOctets
        },

        # this callback will work everything of necessary
        -mycallback => sub {
            my ($s, $host, $key, $val) = @_;
            # val=[[index,name], [index,inOcts], [index,outOcts]]
            my ($index, $name) = @{$val->[0]};

            # check necessarity by ifName
            return 0 if ( $regexp && $name !~ /$regexp/ );

            my $basename = "$host.".escname($name);
            my $rrdfile  = "$datadir/$basename.rrd";

            # treat RRD
            my $rrd = RRD::Simple->new( file => $rrdfile );

            #eval { # wanna catch an error, uncomment here.

            $rrd->create($rrdfile, 'mrtg',
                'in'  => 'COUNTER', 'out' => 'COUNTER'
            ) unless -e $rrdfile;

            $rrd->update( $rrdfile, time,
                'in'  => $val->[1][1], 'out' => $val->[2][1]
            );

            $rrd->graph( $rrdfile,
                destination => $datadir,
                basename    => $basename,
                title       => "$host :: $name",
                sources          => [ qw( in       out      ) ],
                source_labels    => [ qw( incoming outgoing ) ],
                source_colors    => [ qw( 00cc00   0000ff   ) ],
                source_drawtypes => [ qw( AREA     LINE1    ) ]
            );

            #}; warn "[EVAL ERROR] $@" if $@;

            return 1;
        }
    );
    die "[ERROR] $error\n" unless $result;

    # make html
    sub mkimgtag {
        my ($host, $name, $type) = @_;
        my $basename = escname($name);
        img({ -src   => "$htmldir/$host.$basename-$type.png",
              -alt   => "$host $name $type",
              -title => "$type graph of $host $name",
              -border=> 0 });
    }

    open(HTML,"> $datadir/index.html") or die "$!";
    print HTML start_html(
        -title=> 'Traffic Monitor',
        -head => meta({ -http_equiv => 'refresh',
                        -content    => 300 })
    ), h1('Traffic Monitor');

    foreach my $host ( sort @hosts ){
        print HTML h2($host);
        foreach my $i ( sort keys %{$result->{$host}{ifData}[0]} ){
            my $name     = $result->{$host}{ifData}[0]{$i};
            my $subhtml  = "$host.".escname($name).".html";

            printf HTML a( {-href=>"$htmldir/$subhtml"},
                mkimgtag($host, $name, 'daily')
            );

            if ( open(HTML2,"> $datadir/$subhtml") ){
                print HTML2 start_html(
                        -title=> 'Traffic Monitor',
                        -head => meta({ -http_equiv => 'refresh',
                                        -content    => 300 }) ),
                    h1("$host $name"),
                    (map { h2($_).p(mkimgtag($host, $name, $_)) }
                        qw(daily weekly monthly annual)),
                    end_html();
                close(HTML2);
            } else {
                warn "$!";
            }
        }
    }

    print HTML end_html();
    close(HTML);

    __END__


=head1 REQUIREMENTS

See C<Net::SNMP>.

=head1 AUTHOR

t.onodera, C<< <cpan :: garakuta.net> >>

=head1 TO DO

- Implementation of simple trapping functions

=head1 SEE ALSO

=over

=item *

L<Net::SNMP> - Core module of C<Net::SNMP::Util> which brings us good SNMP
implementations.

=item *

L<Net::SNMP::Util::OID> - Sub module of C<Net::SNMP::Util> which provides
easy and simple functions to treat OID.

=item *

L<Net::SNMP::Util::TC> - Sub module of C<Net::SNMP::Util> which provides
easy and simple functions to treat textual conversion.

=back

=head1 LICENSE AND COPYRIGHT

Copyright(C) 2011- Takahiro Ondoera.

This program is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; # End of Net::SNMP::Util