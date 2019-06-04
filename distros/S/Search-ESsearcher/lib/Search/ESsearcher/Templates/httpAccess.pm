package Search::ESsearcher::Templates::httpAccess;

use 5.006;
use strict;
use warnings;

=head1 NAME

Search::ESsearcher::Templates::httpAccess - Provicdes support for HTTP access logs sucked down via beats.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 LOGSTASH / FILEBEAT

This uses a logstath beasts input akin to below.

The important bit below is setting the "type" to "beats" and "fields.log" to "apache-access".

If you are using something different than "type" and "beats" you can specify that via "--field" and
"--fieldv" respectively.

If you are using something different than "fields.log" and "apache-access" you can specify that via "--field2" and
"--field2v" respectively.

    input {
      beats {
        host => "192.168.14.3"
        port => 5044
        type => "beats"
      }
    }
    
    filter {
        if [fields][log] == "apache-access" {
                    grok {
                            match => {
                                    "message" => "%{HTTPD_COMBINEDLOG}+%{GREEDYDATA:extra_fields}"
                            }
                            overwrite => [ "message" ]
                    }
    
                    mutate {
                            convert => ["response", "integer"]
                            convert => ["bytes", "integer"]
                            convert => ["responsetime", "float"]
                    }
                    geoip {
                            source => "clientip"
                            target => "geoip"
                            add_tag => [ "apache-geoip" ]
                    }
                    date {
                            match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
                            remove_field => [ "timestamp" ]
                    }
                    useragent {
                            source => "agent"
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

Then for file beats, something akin to below. The really important bits here the various
values for "fields".

For "fields.vhost" and "fields.vhost_port" if you are using somethind different, you can
specify that via "--field3" and "--field4" respectively.

    - type: log
      enabled: true
      paths:
        - /var/log/apache/foo.bar:80-access.log
      fields:
         log: apache-access
         vhost: foo.bar
         vhost_port: 80


=head1 Options

=head2 --host <host>

The machine beasts is running on feeding info to logstash/ES.

=head2 --response <code>

The response code from the HTTP server.

=head2 --verb <verb>

The verb used with the request.

=head2 --vhost <vhost>

The domain served up.

=head2 --port <port>

The port for the vhost.

=head2 --ip <ip>

The client IP that made the request.

=head2 --os <os>

The supplied OS value that made the request.

=head2 --showos

Shows the OS value.

=head2 --req <req>

The HTTP request.

=head2 --ref <ref>

The supplied referrer for the request.

=head2 --agent <agent>

The supplied agent value that made the request.

=head2 --noagent

Do not show the agent field.

=head2 --auth <auth>

The authed user for the request.

=head2 --bgt <bytes>

Response bytes greater than.

=head2 --bgte <bytes>

Response bytes greater than or equal to.

=head2 --blt <bytes>

Response bytes less than.

=head2 --blte <bytes>

Response bytes less than or equal to.

=head2 --geoip

Require GEO IP to have worked.

=head2 --country <country>

The 2 letter country code.

=head2 --showcountry

Show country code.

=head2 --region <state>

The state/province/etc to search for.

=head2 --showregion

Show region code.

=head2 --postal <zipcode>

The postal code to search for.

=head2 --showpostal

Show postal code.

=head2 --city <cide>

The city to search for.

=head2 --showcity

Show city name.

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
[% DEFAULT o.field2v = "apache-access" %]
[% DEFAULT o.field3 = "fields.vhost" %]
[% DEFAULT o.field4 = "fields.vhost_port" %]
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
						  "default_field": [% o.field2.json %],
						  "query": [% o.field2v.json %]
					  }
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
					  [% IF o.msg %]
					  {"query_string": {
						  "default_field": "message",
						  "query": [% o.msg.json %]
					  }
					   },
					  [% END %]
					  [% IF o.response %]
					  {"query_string": {
						  "default_field": "response",
						  "query": [% aon( o.response ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.geoip %]
					  {"query_string": {
						  "default_field": "geoip.country_code2",
						  "query": "*"
					  }
					   },
					  [% END %]
					  [% IF o.verb %]
					  {"query_string": {
						  "default_field": "verb",
						  "query": [% aon( o.verb ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.vhost %]
					  {"query_string": {
						  "default_field": "fields.vhost",
						  "query": [% aon( o.vhost ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.port %]
					  {"query_string": {
						  "default_field": "fields.vhost_port",
						  "query": [% aon( o.port ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.os %]
					  {"query_string": {
						  "default_field": "os",
						  "query": [% aon( o.os ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.agent %]
					  {"query_string": {
						  "default_field": "agent",
						  "query": [% aon( o.agent ).json %]
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
					  [% IF o.auth %]
					  {"query_string": {
						  "default_field": "auth",
						  "query": [% aon( o.auth ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.req %]
					  {"query_string": {
						  "default_field": "request",
						  "query": [% aon( o.req ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.ref %]
					  {"query_string": {
						  "default_field": "referrer",
						  "query": [% aon( o.ref ).json %]
					  }
					   },
					  [% END %]
					  [% IF o.bgt %]
					  {"range": {
						  "bytes": {
							  "gt": [% pd( o.bgt ).json %]
						  }
					  }
					   },
					  [% END %]
					  [% IF o.bgte %]
					  {"range": {
						  "bytes": {
							  "gte": [% pd( o.bgte ).json %]
						  }
					  }
					   },
					  [% END %]
					  [% IF o.blt %]
					  {"range": {
						  "bytes": {
							  "lt": [% pd( o.blt ).json %]
						  }
					  }
					   },
					  [% END %]
					  [% IF o.blte %]
					  {"range": {
						  "bytes": {
							  "lte": [% pd( o.blte ).json %]
						  }
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
response=s
verb=s
vhost=s
port=s
ip=s
os=s
agent=s
auth=s
req=s
showos
geoip
country=s
ref=s
bgt=s
bgte=s
blt=s
blte=s
showcountry
showregion
showpostal
showcity
region=s
postal=s
city=s
msg=s
size=s
field=s
fieldv=s
field2=s
field2v=s
field3=s
field4=s
noagent
dgt=s
dgte=s
dlt=s
dlte=s
';
}

sub output{
	return '[% c("cyan") %][% f.timestamp %] '.
	'[% c("bright_blue") %][% f.fields.vhost %][% c("bright_yellow") %]:[% c("bright_magenta") %][% f.fields.vhost_port %] '.
	'[% c("bright_cyan") %][% f.clientip %]'.

	'[% IF o.showcountry %]'.
	'[% IF f.geoip.country_code2 %]'.
	'[% c("yellow") %]('.
	'[% c("bright_green") %][% f.geoip.country_code2 %]'.
	'[% c("yellow") %])'.
	'[% END %]'.
	'[% END %]'.

	'[% IF o.showregion %]'.
	'[% IF f.geoip.region_code %]'.
	'[% c("yellow") %]('.
	'[% c("bright_green") %][% f.geoip.region_code %]'.
	'[% c("yellow") %])'.
	'[% END %]'.
	'[% END %]'.

	'[% IF o.showcity %]'.
	'[% IF f.geoip.city_name %]'.
	'[% c("yellow") %]('.
	'[% c("bright_green") %][% f.geoip.city_name %]'.
	'[% c("yellow") %])'.
	'[% END %]'.
	'[% END %]'.

	'[% IF o.showpostal %]'.
	'[% IF f.geoip.postal_code %]'.
	'[% c("yellow") %]('.
	'[% c("bright_green") %][% f.geoip.postal_code %]'.
	'[% c("yellow") %])'.
	'[% END %]'.
	'[% END %]'.

	' [% c("bright_red") %][% f.auth %] '.
	'[% c("bright_yellow") %][% f.verb %] '.
	'[% c("bright_magenta") %][% f.request %] '.
	'[% c("bright_blue") %][% f.response %] '.
	'[% c("bright_green") %][% f.bytes %] '.
	'[% c("cyan") %][% f.referrer %] '.

	'[% IF o.showos %]'.
	'[% c("green") %][% f.os %] '.
	'[% END %]'.

	'[% IF ! o.noagent %]'.
	'[% c("magenta") %][% f.agent %]'.
	'[% END %]'.
	''
;
}

sub help{
	return '



--host <log host>    The system beats in question is running on.
--response <code>    The response code from the HTTP server.
--verb <verb>        The verb used with the request.
--vhost <vhost>      The domain served up.
--port <port>        The port for the vhost.
--ip <ip>            The client IP that made the request.
--os <os>            The supplied OS value that made the request.
--showos             Shows the OS value.
--req <req>          The HTTP request.
--ref <ref>          The supplied referrer for the request.
--agent <agent>      The supplied agent value that made the request.
--noagent            Do not show the agent field.
--auth <auth>        The authed user for the request.

--bgt <bytes>        Response bytes greater than.
--bgte <bytes>       Response bytes greater than or equal to.
--blt <bytes>        Response bytes less than.
--blte <bytes>       Response bytes less than or equal to.

--geoip              Require GEO IP to have worked.
--country <country>  The 2 letter country code.
--showcountry        Show country code.
--region <state>     The state/province/etc to search for.
--showregion         Show region code.
--postal <zipcode>   The postal code to search for.
--showpostal         Show postal code.
--city <cide>        The city to search for.
--showcity         Show city name.

--dgt <date>          Date greater than.
--dgte <date>         Date greater than or equal to.
--dlt <date>          Date less than.
--dlte <date>         Date less than or equal to.

--msg <message>       Messages to match.
--size <size>         The max number of matches to return.

--field <field>       The term field to use for matching them all.
--field2 <field2>     The term field to use for what beats is setting.
--fieldv <fieldv>     The value of the term field to matching them all.
--field2v <field2v>   The value to look for in the field beats is setting.



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
