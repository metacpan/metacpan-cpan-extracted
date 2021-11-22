package Search::ESsearcher::Templates::syslog;

use 5.006;
use strict;
use warnings;

=head1 NAME

Search::ESsearcher::Templates::syslog - Provides syslog support for essearcher.

=head1 VERSION

Version 1.1.1

=cut

our $VERSION = '1.1.1';

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
					  [% IF o.srcx %]
					  {"query_string": {
						  "default_field": "logsource.keyword",
						  "query": [% o.srcx.json %]
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
					  [% IF o.program %]
					  {"query_string": {
						  "default_field": "program",
						  "query": [% aon( o.program ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.facility %]
					  {"query_string": {
						  "default_field": "facility_label",
						  "query": [% aon( o.facility ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.severity %]
					  {"query_string": {
						  "default_field": "severity_label",
						  "query": [% aon( o.severity ).json %]
					  }
					   },
					  [% END %]
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
hostx=s
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
srcx=s
';
}

sub output{
	return '[% c("cyan") %][% f.timestamp %] [% c("bright_blue") %][% f.logsource %] '.
	'[% c("bright_green") %][% f.program %][% c("bright_magenta") %][[% c("bright_yellow") %]'.
	'[% f.pid %][% c("bright_magenta") %]] [% c("white") %]'.
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
	'my $blue=color("bright_blue");'.

	'$replace=color("bright_yellow")."\'".color("cyan");'.
	'$msg=~s/\\\'([A-Za-z0-9\\.\\#\\:\\-\\/]*)\\\'/$replace$1$yellow\'$white/g;'.

	'$msg=~s/([A-Za-z\_\-]+)\=/$green$1$yellow=$white/g;'.

	'$msg=~s/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/$blue$1$white/g;'.

	'$msg=~s/(([A-f0-9:]+:+)+[A-f0-9]+)/$blue$1$white/g;'.

	'print $msg;'.
	'[% END %]';
	;
}

sub help{
	return '

--host <log host>     The syslog server.
--hostx <log host>     The syslog server, raw.
--src <src server>    The source server sending to the syslog server.
--srcx <src server>   The source server sending to the syslog server, raw.
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

A list seperated by any of those will be transformed.

These may be used with program, facility, and pid.

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
