package Pingdom::Client;
{
  $Pingdom::Client::VERSION = '0.13';
}
# ABSTRACT: a perl implementation of a client for the Pingdom REST API.

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

use Carp;
use Data::Dumper;
use Try::Tiny;
use LWP::UserAgent;
use JSON;
use URI::Escape ();

# see http://www.pingdom.com/services/api-documentation-rest/

# use autodie;
# use MooseX::Params::Validate;

has '_json' => (
    'is'        => 'ro',
    'isa'       => 'JSON',
    'lazy'      => 1,
    'builder' => '_init_json',
);

has '_ua' => (
    'is'      => 'rw',
    'isa'     => 'LWP::UserAgent',
    'lazy'    => 1,
    'builder' => '_init_ua',
);

has 'username' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
);

has 'password' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
);

has 'apikey' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'required' => 1,
);

has 'apiurl' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'default' => 'https://api.pingdom.com',
);

has 'apiversion' => (
    'is'    => 'rw',
    'isa'   => 'Str',
    'default' => '2.0',
);

has 'lasterror' => (
    'is'        => 'rw',
    'isa'       => 'HashRef',
    'default'   => sub { {} },
);

sub _init_ua {
    my $self = shift;

    my $UA = LWP::UserAgent::->new();
    $UA->agent('Pingdom::Client/0.01');

    return $UA;
}

sub _init_json {
    my $self = shift;

    my $JSON = JSON::->new()->utf8();

    return $JSON;
}

sub _set_lasterror {
    my $self = shift;
    my $code = shift;
    my $msg = shift;
    my $longmsg = shift;

    $self->lasterror()->{'statuscode'} = $code;
    $self->lasterror()->{'statusdesc'} = $msg;
    $self->lasterror()->{'errormessage'} = $longmsg;

    return 1;
}

sub _validate_params {
    my $self = shift;
    my $ref = shift;
    my $params = shift;

    foreach my $key (keys %{$params}) {
        # whine on superflous params
        if(!$ref->{$key}) {
            return; # not a valid param for this operation
        }
        if(ref($ref->{$key})) {
            if(ref($ref->{$key}) eq 'Regexp') {
                if($params->{$key} !~ m/$ref->{$key}/) {
                    # RE didn't match
                    return;
                }
            }
        } else {
            # match String, Int, Bool
            if($ref->{$key} eq 'Str') {
                if($params->{$key} !~ m/^.{1,4096}$/) {
                    return; # no string
                }
            } elsif($ref->{$key} eq 'Int') {
                if($params->{$key} !~ m/^\d+$/) {
                    return; # no int
                }
            } elsif($ref->{$key} eq 'Bool') {
                if($params->{$key} !~ m/^(?:true|false)$/) {
                    return; # no bool
                }
            } elsif($ref->{$key} eq 'Ids') {
                if($params->{$key} !~ m/^(?:\d+,)*\d+$/) {
                    return; # no id list
                }
            } elsif($ref->{$key} eq 'Order') {
                if($params->{$key} !~ m/^(?:ASC|DESC)$/i) {
                    return; # not valid value for order
                }
            } elsif($ref->{$key} eq 'Checktype') {
                if($params->{$key} !~ m/^(?:http|httpcustom|tcp|ping|dns|udp|smtp|pop3|imap)$/) {
                    return; # not a valid type of check
                }
            }
        }
    }

    return 1;
}

sub _api_call {
    my $self = shift;
    my $method = shift;
    my $url = shift;
    my $params = shift;

    $method = uc($method);
    $url = $self->apiurl().'/api/'.$self->apiversion().'/'.$url;

    my $content = '';
    if($params && ref($params) eq 'HASH' ) {
        foreach my $key (keys %{$params}) {
            my $value = $params->{$key};
            # urlencode key and value
            $key = URI::Escape::uri_escape($key);
            $value = URI::Escape::uri_escape($value);
            $content .= $key.'='.$value.'&';
        }
        if($method eq 'GET') {
            $url .= '?'.$content;
        }
    }
    my $req = HTTP::Request::->new( $method => $url, );
    if($method ne 'GET') {
        $req->content_type('application/x-www-form-urlencoded');
    $req->content($content);
    }

    $req->authorization_basic( $self->username(), $self->password() );
    $req->header( 'App-Key', $self->apikey() );

    my $res = $self->_ua()->request($req);

    if ( $res->is_success() ) {
        my $result_ref;
        try {
            $result_ref = $self->_json()->decode($res->content());
            1;
        } catch {
            my $msg = 'Unable to decode JSON: '.$_;
            $self->_set_lasterror(901,'JSON-Decode',$msg);
            carp $msg;
        };
        return $result_ref;
    }
    else {
        $self->_set_lasterror($res->code(), $res->message(), $res->content());
        carp "Request to $url failed: ".$res->code().' '.$res->message().' '.$res->content();
        return;
    }
}

sub actions {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # from - Int
    # to - Int
    # limit - Int (<= 300)
    # offset - Int
    # checkids - String
    # contactids - String
    # status - String (sent,delivered,error,not_delivered,no_credits)
    # via - String (email,sms,twitter,iphone,android)
    my $ref = {
        'from' => 'Int',
        'to' => 'Int',
        'limit' => qr/^[0123]?[0-9]?[0-9]$/,
        'offset' => 'Int',
        'checkids' => 'Ids',
        'contactids' => 'Ids',
        'status' => qr/^(?:sent|delivered|error|not_delivered|no_credits)$/,
        'via' => qr/^(?:email|sms|twitter|iphone|android)$/,
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method action');
            return;
    }

    my $method = 'GET';
    my $url = 'actions';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub analysis {
    my $self = shift;
    my $checkid = shift;
    my $params = shift;

    # Valid params:
    # limit - Int
    # offset - Int
    # from - Int
    # to - Int
    my $ref = {
        'from' => 'Int',
        'to' => 'Int',
        'limit' => qr/^[0123]?[0-9]?[0-9]$/,
        'offset' => 'Int',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method analysis');
            return;
    }

    my $method = 'GET';
    my $url = 'analysis/'.$checkid;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub analysis_raw {
    my $self = shift;
    my $checkid = shift;
    my $analysisid = shift;

    # Valid params:
    # none

    my $method = 'GET';
    my $url = 'analysis/'.$checkid.'/'.$analysisid;

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

sub checks {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # limit - Int
    # offset - Int
    my $ref = {
        'limit' => qr/^[0123]?[0-9]?[0-9]$/,
        'offset' => 'Int',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method checks');
            return;
    }

    my $method = 'GET';
    my $url = 'checks';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub check_details {
    my $self = shift;
    my $checkid = shift;

    # Valid params:
    # none

    my $method = 'GET';
    my $url = 'checks/'.$checkid;

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

sub check_create {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # name - Str
    # host - Str
    # type - String (http, httpcustom,tcp,ping,dns,udp,smtp,pop3,imap)
    # paused - Bool
    # resolution - Int (1, 5, 15, 30, 60)
    # contactids - Ints
    # sendtoemail - Bool
    # sendtosms - Bool
    # sendtotwitter - Bool
    # sendtoiphone - Bool
    # sendtoandroid - Bool
    # sendnotificationwhendown - Int
    # notifyagainevery - Int
    # notifywhenbackup - Bool
    # ... (many more)
    my $ref = {
        'name' => 'Str',
        'host' => 'Str',
        'type' => 'Checktype',
        'paused' => 'Bool',
        'resolution' => 'Int',
        'contactids' => 'Ids',
        'sendtoemail' => 'Bool',
        'sendtosms' => 'Bool',
        'sendtotwitter' => 'Bool',
        'sendtoiphone' => 'Bool',
        'sendtoandroid' => 'Bool',
        'sendnotificationwhendown' => 'Int',
        'notifyagainevery' => 'Int',
        'notifywhenbackup' => 'Bool',
        'url' => 'Str',
        'encryption' => 'Bool',
        'port' => 'Int',
        'auth' => 'Str',
        'shouldcontain' => 'Str',
        'shouldnotcontain' => 'Str',
        'postdata' => 'Str',
        'additionalurls' => 'Str',
        'stringtosend' => 'Str',
        'stringtoexpect' => 'Str',
        'expectedip' => 'Str',
        'nameserver' => 'Str',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method check_create');
            return;
    }

    my $method = 'POST';
    my $url = 'checks';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub check_modify {
    my $self = shift;
    my $checkid = shift;
    my $params = shift;

    # Valid params:
    # ...
    my $ref = {
        'name' => 'Str',
        'host' => 'Str',
        'type' => 'Checktype',
        'paused' => 'Bool',
        'resolution' => 'Int',
        'contactids' => 'Ids',
        'sendtoemail' => 'Bool',
        'sendtosms' => 'Bool',
        'sendtotwitter' => 'Bool',
        'sendtoiphone' => 'Bool',
        'sendtoandroid' => 'Bool',
        'sendnotificationwhendown' => 'Int',
        'notifyagainevery' => 'Int',
        'notifywhenbackup' => 'Bool',
        'url' => 'Str',
        'encryption' => 'Bool',
        'port' => 'Int',
        'auth' => 'Str',
        'shouldcontain' => 'Str',
        'shouldnotcontain' => 'Str',
        'postdata' => 'Str',
        'additionalurls' => 'Str',
        'stringtosend' => 'Str',
        'stringtoexpect' => 'Str',
        'expectedip' => 'Str',
        'nameserver' => 'Str',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method check_modify');
            return;
    }

    my $method = 'PUT';
    my $url = 'checks/'.$checkid;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub check_modify_bulk {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # paused - Bool
    # resolution - Int (1, 5, 15, 30, 60)#
    # checkids - Str
    my $ref = {
        'paused' => 'Bool',
        'resolution' => qr/^(?:1|5|15|30|60)$/,
        'checkids' => 'Ids',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method check_modify_bulk');
            return;
    }

    my $method = 'PUT';
    my $url = 'checks';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub check_delete {
    my $self = shift;
    my $checkid = shift;

    # Valid params:
    # none

    my $method = 'DELETE';
    my $url = 'checks/'.$checkid;

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

sub contacts {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # limit - Int
    # offset - Int
    my $ref = {
        'limit' => qr/^[0123]?[0-9]?[0-9]$/,
        'offset' => 'Int',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method contacts');
        return;
    }

    my $method = 'GET';
    my $url = 'contacts';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub contact_create {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # name - Str
    # email - Str
    # cellphone - Str
    # countrycode - Str
    # countryiso - Str (iso3166)
    # defaultsmsprovider - String (clickatell,bulksms,esendex,cellsynt)
    # directtwitter - Bool
    # twitteruser - Str
    my $ref = {
        'name' => 'Str',
        'email' => 'Str',
        'cellphone' => 'Str',
        'countryiso' => 'Str',
        'countrycode' => 'Str',
        'defaultsmsprovider' => 'Str',
        'directtwitter' => 'Bool',
        'twitteruser' => 'Bool',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method contact_create');
        return;
    }

    my $method = 'POST';
    my $url = 'contacts';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub contact_modify {
    my $self = shift;
    my $contact_id = shift;
    my $params = shift;

    # Valid params:
    # name - String
    # email - String
    # cellphone - String, excl. countrycode and leading zero
    # countrycode - String, tel.
    # countryiso - String, iso3166
    # defaultsmsprovider - String (clickatell,bulksms,esendex,cellsynt)
    # paused - Boolean
    my $ref = {
        'name' => 'Str',
        'email' => 'Str',
        'cellphone' => 'Str',
        'countryiso' => 'Str',
        'countrycode' => 'Str',
        'defaultsmsprovider' => 'Str',
        'directtwitter' => 'Bool',
        'twitteruser' => 'Bool',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method contact_modify');
        return;
    }

    my $method = 'PUT';
    my $url = 'contacts/'.$contact_id;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub contact_delete {
    my $self = shift;
    my $contactid = shift;

    # Valid params:
    # none

    my $method = 'DELETE';
    my $url = 'contacts/'.$contactid;

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

sub credits {
    my $self = shift;

    # Valid params:
    # none

    my $method = 'GET';
    my $url = 'credits';

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

sub probes {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # limit - Int
    # offset - Int
    # onlyactive - Bool
    # includedeleted - Bool
    my $ref = {
        'onlyactive' => 'Bool',
        'includedeleted' => 'Bool',
        'limit' => qr/^[0123]?[0-9]?[0-9]$/,
        'offset' => 'Int',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method probes');
        return;
    }

    my $method = 'GET';
    my $url = 'probes';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

sub reference {
    my $self = shift;

    # Valid params:
    # none

    my $method = 'GET';
    my $url = 'reference';

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Get Email Report Subscription List
# Description: Returns a list of email report subscriptions.
sub reports_email {
    my $self = shift;

    # Valid params:
    # none

    my $method = 'GET';
    my $url = 'reports.email';

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Create Email Report
# Description: Creates a new email report.
sub reports_email_create {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # name - Str - req!
    # checkid - Int
    # frequency - Str (monthly,weekly,daily)
    # contactids - Str
    # additionalemails - Str
    my $ref = {
        'name' => 'Str',
        'checkid' => 'Int',
        'frequency' => qr/^(?:daily|weekly|monthly)$/,
        'contactids' => 'Ids',
        'additionalemails' => 'Str',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method reports_email_create');
        return;
    }
    if(!$params->{'name'}) {
        return; # required parameter
    }

    my $method = 'POST';
    my $url = 'reports.email';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Modify Email Report
# Description: Modify an email report.
sub reports_email_modify {
    my $self = shift;
    my $reportid = shift;
    my $params = shift;

    # Valid params:
    # name - Str
    # checkid - Str
    # frequency - Str (monthly, weekly, daily)
    # contactids - Str
    # additionalemails - Str
    my $ref = {
        'name' => 'Str',
        'checkid' => 'Int',
        'frequency' => qr/^(?:daily|weekly|monthly)$/,
        'contactids' => 'Ids',
        'additionalemails' => 'Str',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method reports_email_modify');
        return;
    }

    my $method = 'PUT';
    my $url = 'reports.email/'.$reportid;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Delete Email Report
# Description: Delete an email report.
sub reports_email_delete {
    my $self = shift;
    my $reportid = shift;

    # Valid params:
    # none

    my $method = 'DELETE';
    my $url = 'reports.email/'.$reportid;

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Get Public Report List
# Description: Returns a list of public (web-based) reports.
sub reports_public {
    my $self = shift;

    # Valid params:
    # none

    my $method = 'GET';
    my $url = 'reports.public';

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Publish Public Report
# Description: Activate public report for a specified check.
sub reports_public_create {
    my $self = shift;
    my $checkid = shift;

    # Valid params:
    # none

    my $method = 'PUT';
    my $url = 'reports.public/'.$checkid;

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Withdraw Public Report
# Description: Deactivate public report for a specified check.
sub reports_public_delete {
    my $self = shift;
    my $checkid = shift;

    # Valid params:
    # none

    my $method = 'DELETE';
    my $url = 'reports.public/'.$checkid;

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Get Shared Reports (Banners) List
# Description: Returns a list of shared reports (banners).
sub reports_shared {
    my $self = shift;

    # Valid params:
    # none

    my $method = 'GET';
    my $url = 'reports.shared';

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Create Shared Report (Banner)
# Description: Create a shared report (banner).
sub reports_shared_create {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # sharedtype - Str - req!
    # checkid - Int - req!
    # auto - Bool
    # fromyear - Int
    # frommonth - Int
    # fromday - Int
    # toyear - Int
    # tomonth - Int
    # today - Int
    # type - String (uptime, response)
    my $ref = {
        'sharedtype' => 'Str',
        'checkid' => 'Int',
        'auto' => 'Bool',
        'fromyear' => 'Int',
        'frommonth' => 'Int',
        'fromday' => 'Int',
        'toyear' => 'Int',
        'tomonth' => 'Int',
        'today' => 'Int',
        'type' => qr/^(?:uptime|response)$/,
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method reports_shared_create');
        return;
    }
    if(!$params->{'sharedtype'} || !$params->{'checkid'}) {
        return; # missing req. params
    }

    my $method = 'POST';
    my $url = 'reports.shared';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Delete Shared Report (Banner)
# Description: Delete a shared report (banner).
sub reports_shared_delete {
    my $self = shift;
    my $reportid = shift;

    # Valid params:
    # none

    my $method = 'DELETE';
    my $url = 'reports.shared/'.$reportid;

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Get Raw Check Results
# Description: Return a list of raw test results for a specified check
sub results {
    my $self = shift;
    my $checkid = shift;
    my $params = shift;

    # Valid params:
    # to - Int
    # from - Int
    # probes - Str
    # status - Str
    # limit - Int
    # offset - Int
    # includeanalysis - Bool
    # maxresponse - Int
    # minresponse - Int
    my $ref = {
        'from' => 'Int',
        'to' => 'Int',
        'limit' => qr/^[0123]?[0-9]?[0-9]$/,
        'offset' => 'Int',
        'probes' => 'Str',
        'status' => 'Str',
        'includeanalysis' => 'Bool',
        'maxresponse' => 'Int',
        'minresponse' => 'Int',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method results');
        return;
    }

    my $method = 'GET';
    my $url = 'results/'.$checkid;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Get Current Server Time
# Description: Get the current time of the API server.
sub servertime {
    my $self = shift;

    # Valid params:
    # none

    my $method = 'GET';
    my $url = 'servertime';

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Get Account Settings
# Description: Returns all account-specific settings.
sub settings {
    my $self = shift;

    # Valid params:
    # none

    my $method = 'GET';
    my $url = 'settings';

    my $result = $self->_api_call($method,$url,{});

    return $result;
}

# Method: Modify Account Settings
# Description: Modify account-specific settings.
sub settings_modify {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # firstname - Str
    # lastname - Str
    # company - Str
    # email - Str
    # cellphone - Str
    # cellcountrycode - Int
    # cellcountryiso - Str (iso3166)
    # phone - Str
    # phonecountrycode - Int
    # phonecountryiso - Str (iso3166)
    # address - Str
    # address2 - Str
    # zip - Str
    # location - Str
    # state - Str
    # countryiso - Str (iso3166)
    # vatcode - Str
    # autologout - Bool
    # regionid - Int
    # timezoneid - Int
    # datetimeformatid - Int
    # numberformatid - Int
    # pubrcustomdesign - Bool
    # pubrtextcolor - Str
    # pubrbackgroundcolor - Str
    # pubrlogourl - Str
    # pubrmonths - Str (none, all, 3)
    # pubrshowoverview - Bool
    # pubrcustomdomain - Bool
    my $ref = {
        'firstname' => 'Str',
        'lastname' => 'Str',
        'company' => 'Str',
        'email' => 'Str',
        'cellphone' => 'Str',
        'cellcountrycode' => 'Int',
        'cellcountryiso' => 'Str',
        'phone' => 'Str',
        'phonecountrycode' => 'Int',
        'phonecountryiso' => 'Str',
        'address' => 'Str',
        'address2' => 'Str',
        'zip' => 'Str',
        'location' => 'Str',
        'state' => 'Str',
        'countryiso' => 'Str',
        'vatcode' => 'Str',
        'autologout' => 'Bool',
        'regionid' => 'Int',
        'timezoneid' => 'Int',
        'datetimeformatid' => 'Int',
        'numberformatid' => 'Int',
        'pubrcustomdesign' => 'Bool',
        'pubrtextcolor' => 'Str',
        'pubrbackgroundcolor' => 'Str',
        'pubrlogourl' => 'Str',
        'pubrmonths' => qr/^(?:none|all|3)$/,
        'pubrshowoverview' => 'Bool',
        'pubrcustomdomain' => 'Bool',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method settings modify');
        return;
    }

    my $method = 'PUT';
    my $url = 'settings';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Get A Response Time / Uptime Average
# Description: Get a summarized response time / uptime value for a specified check and time period.
sub summary_average {
    my $self = shift;
    my $checkid = shift;
    my $params = shift;

    # Valid params:
    # from - Int
    # to - Int
    # probes - Str
    # includeuptime - Bool
    # bycountry - Bool
    # byprobe - Bool
    my $ref = {
        'from' => 'Int',
        'to' => 'Int',
        'probes' => 'Str',
        'includeuptime' => 'Bool',
        'bycountry' => 'Bool',
        'byprobe' => 'Bool',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method summary_average');
        return;
    }

    my $method = 'GET';
    my $url = 'summary.average/'.$checkid;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Get Response Time Averages For Each Hour Of The Day
# Description: Returns the average response time for each hour of the day (0-23) for a specific check over a selected time period. I.e. it shows you what an average day looks like during that time period.
sub summary_hoursofday {
    my $self = shift;
    my $checkid = shift;
    my $params = shift;

    # Valid params:
    # from - Int
    # to - Int
    # probes - Str
    # uselocaltime - Bool
    my $ref = {
        'from' => 'Int',
        'to' => 'Int',
        'probes' => 'Str',
        'uselocaltime' => 'Bool',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method summary_hoursofday');
        return;
    }

    my $method = 'GET';
    my $url = 'summary.hoursofday/'.$checkid;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Get Outages List
# Description: Get a list of status changes for a specified check and time period.
sub summary_outage {
    my $self = shift;
    my $checkid = shift;
    my $params = shift;

    # Valid params:
    # from - Int
    # to - Int
    # order - Str (asc, desc)
    my $ref = {
        'from' => 'Int',
        'to' => 'Int',
        'order' => 'Order',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method summary_outage');
        return;
    }

    my $method = 'GET';
    my $url = 'summary.outage/'.$checkid;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Get Intervals Of Average Response Time And Uptime
# Description: Get the average response time and uptime for a list of intervals. Useful for generating graphs.
sub summary_performance {
    my $self = shift;
    my $checkid = shift;
    my $params = shift;

    # Valid params:
    # from - Int
    # to - Int
    # resolution - Str (hour, day, week)
    # includeuptime - Bool
    # probes - Str
    # order - Str (asc, desc)
    my $ref = {
        'from' => 'Int',
        'to' => 'Int',
        'resolution' => qr/^(?:hour|day|week)$/i,
        'includeuptime' => 'Bool',
        'probes' => 'Str',
        'order' => 'Order',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method summary_performance');
        return;
    }

    my $method = 'GET';
    my $url = 'summary.performance/'.$checkid;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Get Active Probes For A Period
# Description: Get a list of probes that performed tests for a specified check during a specified period.
sub summary_probes {
    my $self = shift;
    my $checkid = shift;
    my $params = shift;

    # Valid params:
    # from - Int - req!
    # to - Int
    my $ref = {
        'from' => 'Int',
        'to' => 'Int',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method summary_probes');
        return;
    }

    my $method = 'GET';
    my $url = 'summary.probes/'.$checkid;

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Make A Single Test
# Description: Performs a single test using a specified Pingdom probe against a specified target. Please note that this method is meant to be used sparingly, not to set up your own monitoring solution.
sub single {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # host - Str - req!
    # type - Str (http, httpcustom, tcp, ping, dns, udp, smtp, pop3, imap) - req!
    # probeid - Int
    # TODO handle requestheader X ...
    my $ref = {
        'host' => 'Str',
        'type' => 'Checktype',
        'probeid' => 'Int',
        'url' => 'Str',
        'encryption' => 'Bool',
        'port' => 'Int',
        'auth' => 'Str',
        'shouldcontain' => 'Str',
        'shouldnotcontain' => 'Str',
        'postdata' => 'Str',
        'additionalurls' => 'Str',
        'stringtosend' => 'Str',
        'stringtoexpect' => 'Str',
        'expectedip' => 'Str',
        'nameserver' => 'Str',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method single');
        return;
    }
    if(!$params->{'host'} || !$params->{'type'}) {
        return; # missing req. arg host
    }

    my $method = 'GET';
    my $url = 'single';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

# Method: Make A Traceroute
# Description: Perform a traceroute to a specified target from a specified Pingdom probe.
sub traceroute {
    my $self = shift;
    my $params = shift;

    # Valid params:
    # host - Str - req!
    # probeid - Int
    my $ref = {
        'host' => 'Str',
        'probeid' => 'Int',
    };
    if(!$self->_validate_params($ref,$params)) {
        $self->_set_lasterror(902,'Validate','Failed to validate params for method traceroute');
        return;
    }
    if(!$params->{'host'}) {
        return;
    }

    my $method = 'GET';
    my $url = 'traceroute';

    my $result = $self->_api_call($method,$url,$params);

    return $result;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Pingdom::Client - a perl implementation of a client for the Pingdom REST API.

=head1 SYNOPSIS

    use Pingdom::Client;
    my $API = Pingdom::Client::->new({
        'username' => 'user',
        'password' => 'pass',
        'apikey'   => 'key',
    });
    print $API->contacts();

=head1 METHODS

=head2 actions

Returns a list of actions (alerts) that have been generated for your account.

=head2 analysis

Returns a list of the latest error analysis results for a specified check.

=head2 analysis_raw

Returns the raw result for a specified error analysis. This data is primarily intended for internal use, but you might be interested in it as well. However, there is no real documentation for this data at the moment. In the future, we may add a new API method that provides a more user-friendly format.

=head2 check_create

Creates a new check with settings specified by provided parameters.

=head2 check_delete

Deletes a check. THIS METHOD IS IRREVERSIBLE! You will lose all collected data. Be careful!

=head2 check_details

Returns a detailed description of a specified check.

=head2 check_modify

Modify settings for a check. The provided settings will overwrite previous values. Settings not provided will stay the same as before the update. To clear an existing value, provide an empty value. Please note that you cannot change the type of a check once it has been created.

=head2 check_modify_bulk

Pause or change resolution for multiple checks in one bulk call.

=head2 checks

Returns a list overview of all checks.

=head2 contact_create

Create a new contact.

=head2 contact_delete

Deletes a contact.

=head2 contact_modify

Modify a contact.

=head2 contacts

Returns a list of all contacts.

=head2 credits

Returns information about remaining checks, SMS credits and SMS auto-refill status.

=head2 probes

Returns a list of all Pingdom probe servers.

=head2 reference

Get a reference of regions, timezones and date/time/number formats and their identifiers.

=head2 reports_email

Returns a list of email report subscriptions.

=head2 reports_email_create

Creates a new email report.

=head2 reports_email_delete

Delete an email report.

=head2 reports_email_modify

Modify an email report.

=head2 reports_public

Returns a list of public (web-based) reports.

=head2 reports_public_create

Activate public report for a specified check.

=head2 reports_public_delete

Deactivate public report for a specified check.

=head2 reports_shared

Returns a list of shared reports (banners).

=head2 reports_shared_create

Create a shared report (banner).

=head2 reports_shared_delete

Delete a shared report (banner).

=head2 results

Return a list of raw test results for a specified check.

=head2 servertime

Get the current time of the API server.

=head2 settings

Returns all account-specific settings.

=head2 settings_modify

Modify account-specific settings.

=head2 single

Performs a single test using a specified Pingdom probe against a specified target. Please note that this method is meant to be used sparingly, not to set up your own monitoring solution.

=head2 summary_average

Get a summarized response time / uptime value for a specified check and time period.

=head2 summary_hoursofday

Returns the average response time for each hour of the day (0-23) for a specific check over a selected time period. I.e. it shows you what an average day looks like during that time period.

=head2 summary_outage

Get a list of status changes for a specified check and time period.

=head2 summary_performance

Get the average response time and uptime for a list of intervals. Useful for generating graphs.

=head2 summary_probes

Get a list of probes that performed tests for a specified check during a specified period.

=head2 traceroute

Perform a traceroute to a specified target from a specified Pingdom probe.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
