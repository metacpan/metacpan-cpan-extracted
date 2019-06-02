package Search::ESsearcher::Templates::syslog;

use 5.006;
use strict;
use warnings;

=head1 NAME

Search::ESsearcher::Templates::syslog - Provides syslog support for essearcher.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

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

=head1 Options

=head2 --host <log host>

The syslog server.

=head2 --src <src server>

The source server sending to the syslog server.

=head2  --program <program>

The name of the daemon/program in question.

=head2 --size <count>

The number of items to return.

=head2 --facility <facility>

The syslog facility.

=head2 --severity <severity>

The severity level of the message.

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

=head1 AND, OR, or NOT shortcut

    , OR
    + AND
    ! NOT

A list seperated by any of those will be transformed

These may be used with program, facility, pid, or host.

    example: --program postfix,spamd
    
    results: postfix OR spamd

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
[% DEFAULT o.host = "*" %]
[% DEFAULT o.src = "*" %]
[% DEFAULT o.program = "*" %]
[% DEFAULT o.facility = "*" %]
[% DEFAULT o.severity = "*" %]
[% DEFAULT o.pid = "*" %]
[% DEFAULT o.msg = "*" %]
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
					  {"query_string": {
						  "default_field": "host",
						  "query": [% aon( o.host ).json %]
					  }
					   },
					  {"query_string": {
						  "default_field": "logsource",
						  "query": [% o.src.json %]
					  }
					   },
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
					  {"query_string": {
						  "default_field": "severity_label",
						  "query": [% aon( o.severity ).json %]
					  }
					   },
					  {"query_string": {
						  "default_field": "pid",
						  "query": [% aon( o.pid ).json %]
					  }
					   },
					  {"query_string": {
						  "default_field": "message",
						  "query": [% o.msg.json %]
					  }
					   },
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
program=s
size=s
facility=s
severity=s
pid=s
dgt=s
dgte=s
dlt=s
dlte=s
msg=s
field=s
fieldv=s
';
}

sub output{
	return '[% c("cyan") %][% f.timestamp %] [% c("bright_blue") %][% f.logsource %] '.
	'[% c("bright_green") %][% f.program %][% c("bright_magenta") %][[% c("bright_yellow") %]'.
	'[% f.pid %][% c("bright_magenta") %]] [% c("white") %][% f.message %]';
}

sub help{
	return '

--host <log host>     The syslog server.
--src <src server>    The source server sending to the syslog server.
--program <program>   The name of the daemon/program in question.
--size <count>        The number of items to return.
--facility <facility> The syslog facility.
--severity <severity> The severity level of the message.
--pid <pid>           The PID that sent the message.
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
