package Search::ESsearcher::Templates::postfix;

use 5.006;
use strict;
use warnings;

=head1 NAME

Search::ESsearcher::Templates::syslog - Provides postfix support for essearcher.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

=head1 LOGSTASH

This uses a logstash configuration below.

    input {
      syslog {
        host => "10.10.10.10"
        port => 11514
        type => "syslog"
      }
    }
    
    filter { }
    
    output {
      if [type] == "syslog" {
        elasticsearch {
          hosts => [ "127.0.0.1:9200" ]
        }
      }
    }

The important bit is "type" being set to "syslog". If that is not used,
use the command line options field and fieldv.

Install L<https://github.com/whyscream/postfix-grok-patterns> for pulling apart
the postfix messages. These files are included with this as well. You will likely
not want to use 51-filter-postfix-aggregate.conf as that is a bit buggy.


=head1 Options

=head2 --host <log host>

The syslog server.

The search is done with .keyword appended to the field name.

=head2 --hostx <log host>

The syslog server.

Does not run the it through aonHost.

The search is done with .keyword appended to the field name.

=head2 --src <src server>

The source server sending to the syslog server.

The search is done with .keyword appended to the field name.

=head2 --srcx <src server>

The source server sending to the syslog server.

Does not run the it through aonHost.

The search is done with .keyword appended to the field name.

=head2 --size <count>

The number of items to return.

=head2 --pid <pid>

The PID that sent the message.

=head2 --dgt <date>

Date greater than.

=head2 --dgte <date>

Date greater than or equal to.

=head2 --dlt <date>

Date less than.

=head2 --dlte <date>

Date less than or equal to.

=head2 --msg <message>

Messages to match.

=head2 --field <field>

The term field to use for matching them all.

=head2 --fieldv <fieldv>

The value of the term field to matching them all.

=head2 --mid <msg id>

Search based on the message ID.

=head2 --from <address>

The from address to search for.

=head2 --to <address>

The to address to search for.

=head2 --oto <address>

The original to address to search for.

=head2 --noq

Search for rejected messages, NOQUEUE.

=head2 --ip <ip>

The client IP to search for.

=head2 --chost <host>

The client hostname to search for.

=head2 --status <status>

Search using SMTP status codes.

=head2 --nocountry

Do not display the country code for the client IP.

=head2 --noregion

Do not display the region code for the client IP.

=head2 --nocity

Do not display the city name for the client IP.

=head2 --nopostal

Do not display the postal code for the client IP.

=head2 --aliaswarn

Show alias warnings.

=head2 --showkeys

Show the parsed out /postfix\_.*/ keys.

=head2 --nomsg

Do not show the message.

=head2 --showprogram

Show the syslog program name as well.

=head2 --showpid

Show the syslog PID as well.

=head1 AND, OR, or NOT shortcut

    , OR
    + AND
    ! NOT

A list seperated by any of those will be transformed

These may be used with program, facility, pid, or host.

    example: --program postfix,spamd
    
    results: postfix OR spamd

=head1 HOST AND, OR, or NOT shortcut

    , OR
    + AND
    ! NOT

A list of hosts seperated by any of those will be transformed.
A host name should always end in a period unless it is a FQDN.

These may be used with host and src.

example: --src foo.,mail.bar.

results: /foo./ OR /mail.bar./

=head1 date

date

/^-/ appends "now" to it. So "-5m" becomes "now-5m".

/^u\:/ takes what is after ":" and uses Time::ParseDate to convert it to a
unix time value.

Any thing not matching maching any of the above will just be passed on.

=cut


sub search{
return '
[% USE JSON ( pretty => 1 ) %]
[% DEFAULT o.program = "postfix" %]
[% DEFAULT o.facility = "mail" %]
[% DEFAULT o.size = "50" %]
[% DEFAULT o.field = "type" %]
[% DEFAULT o.fieldv = "syslog" %]
{
 "index": "logstash-*",
 "body": {
	 "size": [% o.size.json %],
	 "query": {
		 "bool": {
			 "must": [
					  {
					   "term": { [% o.field.json %]: [% o.fieldv.json %] }
					   },
                      [% IF o.host %]
					  {"query_string": {
						  "default_field": "host.keyword",
						  "query": [% aonHost( o.host ).json %]
					  }
					   },
                      [% END %]
                      [% IF o.hostx %]
					  {"query_string": {
						  "default_field": "host.keyword",
						  "query": [% o.hostx.json %]
					  }
					   },
                      [% END %]
                      [% IF o.src %]
					  {"query_string": {
						  "default_field": "logsource.keyword",
						  "query": [% aonHost( o.src ).json %]
					  }
					   },
                      [% END %]
                      [% IF o.srcx %]
					  {"query_string": {
						  "default_field": "logsource.keyword",
						  "query": [% o.srcx.json %]
					  }
					   },
                      [% END %]
					  {"query_string": {
						  "default_field": "program",
						  "query": [% aon( o.program ).json %]
					  }
					   },
					  {"query_string": {
						  "default_field": "facility_label",
						  "query": [% aon( o.facility ).json %]
					  }
					   },
					  [% IF o.pid %]
					  {"query_string": {
						  "default_field": "pid",
						  "query": [% aon( o.pid ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.msg %]
					  {"query_string": {
						  "default_field": "message",
						  "query": [% o.msg.json %]
					  }
					   },
					  [% END %]
					  [% IF o.from %]
					  {"query_string": {
						  "default_field": "postfix_from",
						  "query": [% aon( o.from ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.to %]
					  {"query_string": {
						  "default_field": "postfix_to",
						  "query": [% aon( o.to ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.oto %]
					  {"query_string": {
						  "default_field": "postfix_orig_to",
						  "query": [% aon( o.oto ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.mid %]
					  {"query_string": {
						  "default_field": "postfix_message-id",
						  "query": [% aon( o.mid ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.qid %]
					  {"query_string": {
						  "default_field": "postfix_queueid",
						  "query": [% aon( o.qid ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.ip %]
					  {"query_string": {
						  "default_field": "postfix_client_ip",
						  "query": [% aon( o.ip ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.chost %]
					  {"query_string": {
						  "default_field": "postfix_client_hostname",
						  "query": [% aon( o.chost ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.status %]
					  {"query_string": {
						  "default_field": "postfix_status_code",
						  "query": [% aon( o.status ).json %]
					  }
					   },
					  [% END %]
					  [% IF ! o.aliaswarn %]
					  {"query_string": {
						  "default_field": "message",
						  "query": "NOT \"is older than source file\""
					  }
					   },
					  [% END %]
					  [% IF o.noq %]
					  {"query_string": {
						  "default_field": "message",
						  "query": "NOQUEUE"
					  }
					   },
					  [% END %]
					  [% IF o.dgt %]
					  {"range": {
						  "@timestamp": {
							  "gt": [% pd( o.dgt ).json %]
						  }
					  }
					   },
					  [% END %]
					  [% IF o.dgte %]
					  {"range": {
						  "@timestamp": {
							  "gte": [% pd( o.dgte ).json %]
						  }
					  }
					   },
					  [% END %]
					  [% IF o.dlt %]
					  {"range": {
						  "@timestamp": {
							  "lt": [% pd( o.dlt ).json %]
						  }
					  }
					   },
					  [% END %]
					  [% IF o.dlte %]
					  {"range": {
						  "@timestamp": {
							  "lte": [% pd( o.dlte ).json %]
						  }
					  }
					   },
					  [% END %]
					  ]
		 }
	 },
	 "sort": [
			  {
			   "@timestamp": {"order" : "desc"}}
			  ]
 }
 }
';
}

sub options{
return '
host=s
src=s
hostx=s
srcx=s
size=s
showpid
mid=s
showprogram
showpid
nocountry
noregion
nocity
nopostal
aliaswarn
from=s
to=s
oto=s
ip=s
status=s
chost=s
pid=s
dgt=s
dgte=s
dlt=s
dlte=s
msg=s
pid=s
field=s
fieldv=s
showkeys
nomsg
noq
qid=s
';
}

sub output{
	return '[% c("cyan") %][% f.timestamp %] [% c("bright_blue") %][% f.logsource %]'.

	'[% IF o.showprogram %]'.
	' [% c("bright_green") %][% f.program %]'.
	'[% END %]'.

	'[% IF o.showpid %]'.
	' [% c("bright_magenta") %][[% c("bright_yellow") %][% f.pid %][% c("bright_magenta") %]]'.
	'[% END %]'.
	
	'[% IF ! o.nocountry %]'.
	'[% IF f.geoip.country_code2 %]'.
	' [% c("yellow") %]('.
	'[% c("bright_green") %][% f.geoip.country_code2 %]'.
	'[% c("yellow") %])'.
	'[% END %]'.
	'[% END %]'.

	'[% IF ! o.region %]'.
	'[% IF f.geoip.region_code %]'.
	' [% c("yellow") %]('.
	'[% c("bright_green") %][% f.geoip.region_code %]'.
	'[% c("yellow") %])'.
	'[% END %]'.
	'[% END %]'.

	'[% IF ! o.nocity %]'.
	'[% IF f.geoip.city_name %]'.
	' [% c("yellow") %]('.
	'[% c("bright_green") %][% f.geoip.city_name %]'.
	'[% c("yellow") %])'.
	'[% END %]'.
	'[% END %]'.

	'[% IF ! o.nopostal %]'.
	'[% IF f.geoip.postal_code %]'.
	' [% c("yellow") %]('.
	'[% c("bright_green") %][% f.geoip.postal_code %]'.
	'[% c("yellow") %])'.
	'[% END %]'.
	'[% END %]'.

	' '.
	'[% PERL %]'.
	'use Term::ANSIColor;'.
	'my $f=$stash->get("f");'.	
	'if (defined( $f->{postfix_queueid} ) ){'.
	'    print color("bright_magenta").$f->{postfix_queueid};'.
	'    my $qid=$f->{postfix_queueid};'.
	'    delete($f->{postfix_queueid});'.
	'    $f->{message}=~s/^$qid\://;'.
	'    $stash->set("f", $f);'.
	'}'.
	'[% END %]'.
	
	'[% IF o.showkeys %]'.

	'[% PERL %]'.
	'use Term::ANSIColor;'.
	'my $f=$stash->get("f");'.
	'my @pkeys=grep(/^postfix/, keys( %{$f} ) );'.
	'if (defined( $f->{postfix_queueid} ) ){'.
	'    delete($f->{postfix_queueid})'.
	'}'.
	'foreach my $pkey (@pkeys){'.
	'    my $name=$pkey;'.
	'    $name=~s/^postfix\_//;'.
	'    if (defined( $f->{$pkey} ) ){'.
	'        print " ".color("bright_cyan").$name.color("bright_yellow")."=".color("bright_green").$f->{$pkey};'.
	'    }'.
	'}'.
	'print " "'.
	'[% END %]'.
	'[% END %]'.

	'[% IF ! o.nomsg %]'.
	'[% PERL %]'.
	'use Term::ANSIColor;'.
	'my $f=$stash->get("f");'.

	'my $msg=color("white").$f->{message};'.

	'my $replace=color("cyan")."<".color("bright_magenta");'.
	'$msg=~s/\</$replace/g;'.
	'$replace=color("cyan").">".color("white");'.
	'$msg=~s/\>/$replace/g;'.

	'$replace=color("bright_green")."(".color("cyan");'.
	'$msg=~s/\(/$replace/g;'.
	'$replace=color("bright_green").")".color("white");'.
	'$msg=~s/\)/$replace/g;'.

	'my $green=color("bright_green");'.
	'my $white=color("white");'.
	'my $yellow=color("bright_yellow");'.
	'$msg=~s/([A-Za-z\_\-]+)\=/$green$1$yellow=$white/g;'.

	'my $blue=color("bright_blue");'.
	'$msg=~s/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/$blue$1$white/g;'.
	
	'$replace=color("bright_red")."NOQUEUE".color("white");'.
	'$msg=~s/NOQUEUE/$replace/g;'.

	'$replace=color("bright_red")."failed".color("white");'.
	'$msg=~s/failed/$replace/g;'.

	'$replace=color("bright_red")."warning".color("white");'.
	'$msg=~s/warning/$replace/g;'.

	'$replace=color("bright_red")."disconnect from".color("white");'.
	'$msg=~s/disconnect\ from/$replace/g;'.

	'$replace=color("bright_red")."connect from".color("white");'.
	'$msg=~s/connect\ from/$replace/g;'.

	'$replace=color("bright_red")."SASL LOGIN".color("white");'.
	'$msg=~s/SASL LOGIN/$replace/g;'.

	'$replace=color("bright_red")."authentication".color("white");'.
	'$msg=~s/authentication/$replace/g;'.

	'$replace=color("bright_red")."blocked using".color("white");'.
	'$msg=~s/blocked using/$replace/g;'.

	'$replace=color("bright_red")."Service unavailable".color("white");'.
	'$msg=~s/Service unavailable/$replace/g;'.
	
	'print $msg;'.
	'[% END %]'.
	'[% END %]'
	;
}

sub help{
	return '

--host <log host>     The syslog server.
--hostx <log host>    The syslog server. This is passed raw.
--src <src server>    The source server sending to the syslog server.
--srcx <src server>   The source server sending to the syslog server. This is passed raw.
--size <count>        The number of items to return.
--pid <pid>           The PID that sent the message.

--mid <msg id>        Search based on the message ID.
--qid <queue id>      Search based on the queue ID.
--from <address>      The from address to search for.
--to <address>        The to address to search for.
--oto <address>       The original to address to search for.
--noq                 Search for rejected messages, NOQUEUE.
--ip <ip>             The client IP to search for.
--chost <host>        The client hostname to search for.
--status <status>     Search using SMTP status codes.

--nocountry           Do not display the country code for the client IP.
--noregion            Do not display the region code for the client IP.
--nocity              Do not display the city name for the client IP.
--nopostal            Do not display the postal code for the client IP.

--aliaswarn           Show alias warnings.

--showkeys            Show the parsed out /postfix\_.*/ keys.
--nomsg               Do not show the message.

--showprogram         Show the syslog program name as well.
--showpid             Show the syslog PID as well.

--dgt <date>          Date greater than.
--dgte <date>         Date greater than or equal to.
--dlt <date>          Date less than.
--dlte <date>         Date less than or equal to.

--msg <message>       Messages to match.

--field <field>       The term field to use for matching them all.
--fieldv <fieldv>     The value of the term field to matching them all.



AND, OR, or NOT shortcut
, OR
+ AND
! NOT

A list seperated by any of those will be transformed

These may be used with program, facility, pid, or host.

example: --program postfix,spamd



HOST AND, OR, or NOT shortcut
, OR
+ AND
! NOT

A list of hosts seperated by any of those will be transformed.
A host name should always end in a period unless it is a FQDN.

These may be used with host and src.

example: --src foo.,mail.bar.

results: /foo./ OR /mail.bar./



field and fieldv

The search template is written with the expectation that logstash is setting
"type" with a value of "syslog". If you are using like "tag" instead of "type"
or the like, this allows you to change the field and value.



date

/^-/ appends "now" to it. So "-5m" becomes "now-5m".

/^u\:/ takes what is after ":" and uses Time::ParseDate to convert it to a
unix time value.

Any thing not matching maching any of the above will just be passed on.
';


}
