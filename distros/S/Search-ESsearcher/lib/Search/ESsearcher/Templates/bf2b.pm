package Search::ESsearcher::Templates::bf2b;

use 5.006;
use strict;
use warnings;

=head1 NAME

Search::ESsearcher::Templates::sfail2ban - Provicdes support for fail2ban logs sucked down via beats.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

=head1 LOGSTASH

This uses a logstash configuration like below.

    input {
      beats {
        host => "10.10.10.10"
        port => 5044
        type => "beats"
      }
    }
    
    filter {
        if [fields][log] == "fail2ban" {
                grok {
                        match => {
                                "message" => "%{TIMESTAMP_ISO8601:timestamp} %{WORD:log_src}.%{WORD:src_action} *\[%{INT:fail2ban_digit}\]: %{LOGLEVEL:loglevel} *\[%{NOTSPACE:service}\] %{WORD:ban_status} %{IP:clientip}"
                        }
                }
                geoip {
                        source => "clientip"
                }
        }
    }
    
    output {
      if [type] == "beats" {
        elasticsearch {
          hosts => [ "127.0.0.1:9200" ]
        }
      }
    }

For filebeats, it is assuming this sort of configuration.

    - type: log
      paths:
        - /var/log/fail2ban.log
      fields:
         log: fail2ban

If you have type set different or are using a diffent field, you can change that via --field and --fieldv.

If you have fields.log set differently, you can set that via --field2 and --field2v.

=head1 Options

=head2 --host <host>

The machine beasts is running on feeding fail2ban info to logstash/ES.

=head2 --jail <jail>

The fail2ban jail name to query.

=head2 --country <country>

The 2 letter country code.

=head2 --region <state>

The state/province/etc to search for.

=head2 --postal <zipcode>

The postal code to search for.

=head2 --city <cide>

The city to search for.

=head2 --ip <ip>

The IP to search for.

=head2 --size <count>

The number of items to return.

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

=head2 --field2 <field2>

The term field to use for what beats is setting.

=head2 --field2v <field2v>

The value to look for in the field beats is setting.

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
[% DEFAULT o.size = "50" %]
[% DEFAULT o.field = "type" %]
[% DEFAULT o.fieldv = "beats" %]
[% DEFAULT o.field2 = "fields.log" %]
[% DEFAULT o.field2v = "fail2ban" %]
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
					  {
					   "term": { [% o.field2.json %]: [% o.field2v.json %] }
					   },
					  [% IF o.country %]
					  {"query_string": {
						  "default_field": "geoip.country_code2",
						  "query": [% aon( o.country ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.region %]
					  {"query_string": {
						  "default_field": "geoip.region_code",
						  "query": [% aon( o.region ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.city %]
					  {"query_string": {
						  "default_field": "geoip.city_name",
						  "query": [% aon( o.city ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.postal %]
					  {"query_string": {
						  "default_field": "geoip.postal_code",
						  "query": [% aon( o.postal ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.host %]
					  {"query_string": {
						  "default_field": "host",
						  "query": [% aon( o.host ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.jail %]
					  {"query_string": {
						  "default_field": "service",
						  "query": [% aon( o.jail ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.ip %]
					  {"query_string": {
						  "default_field": "clientip",
						  "query": [% aon( o.ip ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.status %]
					  {"query_string": {
						  "default_field": "ban_status",
						  "query": [% aon( o.status ).json %]
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
country=s
jail=s
region=s
postal=s
status=s
city=s
ip=s
msg=s
field=s
fieldv=s
field2=s
field2v=s
dgt=s
dgte=s
dlt=s
dlte=s
';
}

sub output{
	return '[% c("cyan") %][% f.timestamp %] [% c("bright_blue") %][% f.host %] '.
	'[% c("bright_green") %][% f.service %][% c("bright_magenta") %][[% c("bright_yellow") %]'.
	'[% f.ban_status %][% c("bright_magenta") %]] [% c("white") %][% f.clientip %]';
}

sub help{
	return '



--status <status>    The status value of the message.
--host <log host>    The system beats in question is running on.
--jail <jail>        The fail2ban jail in question.
--ip <ip>            The IP to search for.

--country <country>  The 2 letter country code.
--region <state>     The state/province/etc to search for.
--postal <zipcode>   The postal code to search for.
--city <cide>        The city to search for.

--dgt <date>         Date greater than.
--dgte <date>        Date greater than or equal to.
--dlt <date>         Date less than.
--dlte <date>        Date less than or equal to.

--msg <message>      Messages to match.

--field <field>      The term field to use for matching them all.
--field2 <field2>    The term field to use for what beats is setting.
--fieldv <fieldv>    The value of the term field to matching them all.
--field2v <field2v>  The value to look for in the field beats is setting.


AND, OR, or NOT shortcut
, OR
+ AND
! NOT

A list seperated by any of those will be transformed

These may be used with host, country, jail, region, postal, city, and ip.

example: --country CN,RU



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
