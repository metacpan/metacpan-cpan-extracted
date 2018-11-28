package Reddit::Client;

our $VERSION = '1.2817';
# TODO: make ispost, iscomment and get_type static
# 1.2817-documentation update
# 1.281 -morecomments get_collapsed args
# 1.281 -get_collapsed can also return morecomments
# 1.28  -get_links_by_id
#		-get_collapsed_comments
#		-get_comments new version
#		-MoreComments objects
#		-added function get_replies to Link
#       -can change subdomain (www to old or new, etc)
#       -removed line number message on die. should this be an option instead?
#		-get_permalink renamed ro get_web_url in Link and Comment

$VERSION = eval $VERSION;

use strict;
use warnings;
use Carp;

use Data::Dumper   qw/Dumper/;
use JSON           qw/decode_json/;
use File::Spec     qw//;
use Digest::MD5    qw/md5_hex/;
use POSIX          qw/strftime/;
use File::Path::Expand qw//;

require Reddit::Client::Account;
require Reddit::Client::Comment;
require Reddit::Client::Link;
require Reddit::Client::SubReddit;
require Reddit::Client::Request;
require Reddit::Client::Message;
require Reddit::Client::MoreComments;

#===============================================================================
# Constants
#===============================================================================

use constant DEFAULT_LIMIT           => 25;

use constant VIEW_HOT                => '';
use constant VIEW_NEW                => 'new';
use constant VIEW_CONTROVERSIAL      => 'controversial';
use constant VIEW_TOP                => 'top';
use constant VIEW_RISING	         => 'rising';
use constant VIEW_DEFAULT            => VIEW_HOT;

use constant VOTE_UP                 => 1;
use constant VOTE_DOWN               => -1;
use constant VOTE_NONE               => 0;

use constant SUBMIT_LINK             => 'link';
use constant SUBMIT_SELF       	     => 'self';
use constant SUBMIT_MESSAGE          => 'message';
use constant SUBMIT_CROSSPOST        => 'crosspost';

use constant MESSAGES_INBOX	         => 'inbox';
use constant MESSAGES_UNREAD	     => 'unread';
use constant MESSAGES_SENT	         => 'sent';
use constant MESSAGES_MESSAGES       => 'messages';
use constant MESSAGES_COMMENTREPLIES => 'comments';
use constant MESSAGES_POSTREPLIES    => 'selfreply';
use constant MESSAGES_MENTIONS	     => 'mentions';

use constant SUBREDDITS_HOME         => '';
use constant SUBREDDITS_MINE         => 'subscriber';
use constant SUBREDDITS_POPULAR      => 'popular';
use constant SUBREDDITS_NEW          => 'new';
use constant SUBREDDITS_CONTRIB      => 'contributor';
use constant SUBREDDITS_MOD          => 'moderator';

use constant USER_OVERVIEW           => 'overview';
use constant USER_COMMENTS           => 'comments';
use constant USER_SUBMITTED          => 'submitted';
use constant USER_GILDED             => 'gilded';
use constant USER_UPVOTED            => 'upvoted';
use constant USER_DOWNVOTED          => 'downvoted';
use constant USER_HIDDEN             => 'hidden';
use constant USER_SAVED              => 'saved';
use constant USER_ABOUT              => 'about';

use constant API_ME                  => 0;
use constant API_INFO                => 1;
use constant API_SUB_SEARCH          => 2;
use constant API_LOGIN               => 3;
use constant API_SUBMIT              => 4;
use constant API_COMMENT             => 5;
use constant API_VOTE                => 6;
use constant API_SAVE                => 7;
use constant API_UNSAVE              => 8;
use constant API_HIDE                => 9;
use constant API_UNHIDE              => 10;
use constant API_SUBREDDITS          => 11;
use constant API_LINKS_FRONT         => 12;
use constant API_LINKS_OTHER         => 13;
use constant API_DEL                 => 14;
use constant API_MESSAGE             => 15;
use constant API_COMMENTS_FRONT	     => 16;
use constant API_COMMENTS	         => 17;
use constant API_MESSAGES	         => 18;
use constant API_MARK_READ	         => 19;
use constant API_MARKALL	         => 20;
use constant API_MY_SUBREDDITS       => 21;
use constant API_USER                => 22;
use constant API_SELECTFLAIR         => 23;
use constant API_FLAIROPTS           => 24;
use constant API_EDITWIKI            => 25;
use constant API_CREATEMULTI         => 26;
use constant API_DELETEMULTI         => 27;
use constant API_GETMULTI            => 28;
use constant API_EDITMULTI           => 29;
use constant API_SUBREDDIT_INFO      => 30;
use constant API_SEARCH              => 31;
use constant API_MODQ                => 32;
use constant API_EDIT                => 33;
use constant API_REMOVE              => 34;
use constant API_APPROVE             => 35;
use constant API_IGNORE_REPORTS      => 36;
use constant API_GETWIKI             => 37;
use constant API_GET_MODMAIL         => 38;
use constant API_BAN                 => 39;
use constant API_MORECHILDREN        => 40;
use constant API_BY_ID               => 41;

#===============================================================================
# Parameters
#===============================================================================

our $DEBUG            = 0;
our $BASE_URL         = 'https://oauth.reddit.com';
use constant BASE_URL =>'https://oauth.reddit.com';
our $LINK_URL         = 'https://www.reddit.com'; # Why are there two of these?
use constant LINK_URL =>'https://www.reddit.com'; # both are unused now?
our $UA               = sprintf 'Reddit::Client/%f', $VERSION;

our @API;
$API[API_ME            ] = ['GET',  '/api/v1/me'              ];
$API[API_INFO          ] = ['GET',  '/api/info'               ];
$API[API_SUB_SEARCH    ] = ['GET',  '/subreddits/search'      ];
$API[API_LOGIN         ] = ['POST', '/api/login/%s'           ];
$API[API_SUBMIT        ] = ['POST', '/api/submit'             ];
$API[API_COMMENT       ] = ['POST', '/api/comment'            ];
$API[API_VOTE          ] = ['POST', '/api/vote'               ];
$API[API_SAVE          ] = ['POST', '/api/save'               ];
$API[API_UNSAVE        ] = ['POST', '/api/unsave'             ];
$API[API_HIDE          ] = ['POST', '/api/hide'               ];
$API[API_UNHIDE        ] = ['POST', '/api/unhide'             ];
$API[API_SUBREDDITS    ] = ['GET',  '/subreddits/%s'          ];
$API[API_MY_SUBREDDITS ] = ['GET',  '/subreddits/mine/%s'     ];
$API[API_LINKS_OTHER   ] = ['GET',  '/%s'                     ];
$API[API_LINKS_FRONT   ] = ['GET',  '/r/%s/%s'                ];
$API[API_DEL           ] = ['POST', '/api/del'                ];
$API[API_MESSAGE       ] = ['POST', '/api/compose'            ];
$API[API_COMMENTS      ] = ['GET',  '/r/%s/comments'          ];
$API[API_COMMENTS_FRONT] = ['GET',  '/comments'               ];
$API[API_MESSAGES      ] = ['GET',  '/message/%s'             ];
$API[API_MARK_READ     ] = ['POST', '/api/read_message'       ];
$API[API_MARKALL       ] = ['POST', '/api/read_all_messages'  ];
$API[API_USER          ] = ['GET',  '/user/%s/%s'             ];
$API[API_SELECTFLAIR   ] = ['POST', '/r/%s/api/selectflair'   ];
$API[API_FLAIROPTS     ] = ['POST', '/r/%s/api/flairselector' ];
$API[API_EDITWIKI      ] = ['POST', '/r/%s/api/wiki/edit'     ];
$API[API_GETWIKI       ] = ['GET',  '/r/%s/wiki/%s'           ];
$API[API_CREATEMULTI   ] = ['POST', '/api/multi/user/%s/m/%s' ];
$API[API_GETMULTI      ] = ['GET', '/api/multi/user/%s/m/%s%s'];
$API[API_DELETEMULTI   ] = ['DELETE','/api/multi/user/%s/m/%s'];
$API[API_EDITMULTI     ] = ['PUT',  '/api/multi/user/%s/m/%s' ];
$API[API_SUBREDDIT_INFO] = ['GET',  '/r/%s/about'             ];
$API[API_SEARCH        ] = ['GET',  '/r/%s/search'            ];
$API[API_MODQ          ] = ['GET',  '/r/%s/about/%s'          ];
$API[API_EDIT          ] = ['POST', '/api/editusertext'       ];
$API[API_REMOVE        ] = ['POST', '/api/remove'             ];
$API[API_APPROVE       ] = ['POST', '/api/approve'            ];
$API[API_IGNORE_REPORTS] = ['POST', '/api/ignore_reports'     ];
$API[API_GET_MODMAIL   ] = ['GET',  '/api/mod/conversations'  ];
$API[API_BAN           ] = ['POST', '/r/%s/api/friend'        ];
$API[API_MORECHILDREN  ] = ['GET',  '/api/morechildren'       ];
$API[API_BY_ID         ] = ['GET',  '/by_id'                  ];

#===============================================================================
# Class methods
#===============================================================================

use fields (
    'modhash',      # No longer used. stored session modhash
    'cookie',       # No longer used. stored user cookie
    'session_file', # No longer used. path to session file
    'user_agent',   # user agent string
    'token',		# oauth authorization token
    'tokentype',    # unused but saved for reference
    'last_token',	# time last token was acquired
    'client_id',	# always required
    'secret',       # always required
	'username',		# now optional for web apps
	'password',		# script apps only
	'request_errors',		# print request errors, deprecated
	'print_request_errors',	# print request errors
	'print_response',		# print response content, deprecated
	'print_response_content',# print response content
	'print_request', 		# print entire request
	'print_request_on_error',# print entire request on error
	'refresh_token', 		# oauth refresh token
	'auth_type',			# 'script' or 'webapp'
	'debug',
	'subdomain',
);

sub new {
	my ($class, %param) = @_;
	my $self = fields::new($class);

	if (not exists $param{user_agent}) {
		 croak "param 'user_agent' is required.";
	}
	$self->{user_agent} 	= $param{user_agent};
	$self->{request_errors} = $param{print_request_errors} || $param{request_errors} || 0;
	$self->{print_response} = $param{print_response} || $param{print_response_conent} || 0;
	$self->{print_request}  = $param{print_request} || 0;
	$self->{debug}			= $param{debug}	|| 0;
	$self->{print_request_on_error} = $param{print_request_on_error} || 0;
	$self->{subdomain}		= $param{subdomain} || 'www';

	if ($param{password}) {
		if (!$param{username}) {
			croak "if password is provided, username is required.";
		} elsif (!$param{client_id} or !$param{secret}) {
			croak "client_id and secret are required for authorized apps.";
		} else {
			$self->{auth_type} 	= 'script';
			$self->{client_id}	= $param{client_id};
			$self->{secret} 	= $param{secret};
			$self->{username}	= $param{username};
			$self->{password}	= $param{password};

			$self->get_token();
		}
	} elsif ($param{refresh_token}) {
			croak "client_id and secret are required for authorized apps." unless $param{client_id} and $param{secret}; 
		
		$self->{auth_type} 	= 'webapp';
		$self->{client_id}	= $param{client_id};
		$self->{secret} 	= $param{secret};
		$self->{refresh_token}= $param{refresh_token};
		# will this break anything?
		$self->{username}	= $param{username} if $param{username};

		$self->get_token();
	} else {
		# optionall allow people to pass in client id and secret now, for people
		# who choose to get refresh token from an RC object
		$self->{client_id}	= $param{client_id} if $param{client_id};
		$self->{secret} 	= $param{secret} if $param{secret};
		# can this even be run without auth anymore?
		$self->{auth_type}  = 'none';
	}

    return $self;
}

sub version {
	my $self = shift;
	return $VERSION;
}

#===============================================================================
# Requests and Oauth
#===============================================================================

sub request {
    my ($self, $method, $path, $query, $post_data) = @_;

	# 401s not being caused by this. they are a new API issue apparently.
	if (!$self->{last_token} or $self->{last_token} <= ( time - 3600 + 55) ) {
		# passing in username, pass, client_id, secret here did nothing
		$self->get_token();
	}

    # Trim leading slashes off of the path
    $path =~ s/^\/+//;
    my $request = Reddit::Client::Request->new(
        user_agent => $self->{user_agent},
		   # path is sprintf'd before call, in api_json_request
		   # the calling function passes in path %s's in 'args' param 
        url        => sprintf('%s/%s', $BASE_URL, $path),
        method     => $method,
        query      => $query,
        post_data  => $post_data,
        modhash    => $self->{modhash},
        cookie     => $self->{cookie},
		token	   => $self->{token},
		tokentype  => $self->{tokentype},
		last_token => $self->{last_token},
		request_errors=> $self->{request_errors},
		print_response=> $self->{print_response},
		print_request=>  $self->{print_request},
		print_request_on_error=>$self->{print_request_on_error},
    );

    return $request->send;
}

sub get_token {
	my ($self, %param) = @_;

	# let people set auth things here. this was stupid to allow.
	# these all set $self properties then continue as normal.
	if ($param{username} or $param{password}) {
		die "get_token: if username or password are provided, all 4 script-type authentication arguments (username, password, client_id, secret) are required." unless $param{username} and $param{password} and $param{client_id} and $param{secret}; 

		$self->{auth_type} 	= 'script';
		$self->{client_id}	= $param{client_id};
		$self->{secret} 	= $param{secret};
		$self->{username}	= $param{username};
		$self->{password}	= $param{password};

	} elsif ($param{refresh_token}) {
		$self->{auth_type} 	= 'webapp';
		$self->{client_id}	= $param{client_id} || $self->{client_id} || die "get_token: 'client_id' must be set, either as a parameter to get_token or when instantiating the Reddit::Client object.";
		$self->{secret} 	= $param{secret} || $self->{secret} || die "get_token: 'secret' must be set, either as a parameter to get_token or when instantiating the Reddit::Client object.";
		$self->{refresh_token} 	= $param{refresh_token};
	}

	$self->{last_token} 	= time;

	# why don't we just pass in the whole Client object ffs
	my %p = (
		client_id	=> $self->{client_id},
		secret		=> $self->{secret},
		user_agent	=> $self->{user_agent},
		auth_type	=> $self->{auth_type},
	);

	if ($self->{auth_type} eq 'script') {
		$p{username} = $self->{username},
		$p{password} = $self->{password},
	} elsif ($self->{auth_type} eq 'webapp') {
		$p{refresh_token} = $self->{refresh_token};
	} else { die "get_token: invalid auth type"; }

	# Why is this static?
	my $message = Reddit::Client::Request->token_request(%p);
	my $j = decode_json($message);
	$self->{token} 		= $j->{access_token};
	$self->{tokentype} 	= $j->{token_type};

	if (!$self->{token}) { croak "Unable to get or parse token."; }
}

sub has_token {
	my $self = shift;
	return (!$self->{last_token} || $self->{last_token} <= time - 3595) ? 0 : 1;
}
# 
# This must be called in static context because no refresh token or user/
# pass combination exist. We would have to add a third flow and that doesn't
# seem worth it.
#
# We could call it in an empty RC object, but that would require all sorts
# of annoyoing conditions, and all other methods would be broken until
# tokens were obtained
sub get_refresh_token {
	my ($self, %param) = @_;

	my %data;
	$data{code}			= $param{code} || die "'code' is required.\n";
	$data{redirect_uri}	= $param{redirect_uri} || die "'redirect_uri' is required.\n";
	$data{client_id}	= (ref $self eq 'HASH' and $self->{client_id}  ? $self->{client_id} : undef) || $param{client_id}   || die "'client_id' is required.\n";
	$data{secret}		= (ref $self eq 'HASH' and $self->{secret}     ? $self->{secret} : undef)    || $param{secret}      || die "'secret' is required.";
	$data{ua}			= (ref $self eq 'HASH' and $self->{user_agent} ? $self->{user_agent} : undef) || $param{user_agent} || die "'user_agent' is required.";
	#$data{ua}			= $param{user_agent} || die "user_agent is required";
	$data{grant_type} 	= 'authorization_code';
	$data{duration}		= 'permanent';

	my $refresh_token = Reddit::Client::Request->refresh_token_request(%data);
	return $refresh_token;
}

sub json_request {
    my ($self, $method, $path, $query, $post_data) = @_;
    DEBUG('%4s JSON', $method);

    if ($method eq 'POST') {
        $post_data ||= {};
        $post_data->{api_type} = 'json'; # only POST enpoints require*
    } else { 
        #$path .= '.json'; # the oauth api returns json by default
    }

    my $response = $self->request($method, $path, $query, $post_data);
    my $json     = JSON::from_json($response) if $response;

    if (ref $json eq 'HASH' && $json->{json}) {
        my $result = $json->{json};
        if (@{$result->{errors}}) {
            DEBUG('API Errors: %s', Dumper($result->{errors}));
            my @errors = map {
                sprintf '[%s] %s', $_->[0], $_->[1]
            } @{$result->{errors}};
            croak sprintf("Error(s): %s", join('|', @errors));
        } else {
            return $result;
        }
    } else {
        return $json;
    }
}

sub api_json_request {
    my ($self, %param) = @_;
    my $args     = $param{args} || [];
    my $api      = $param{api};
    my $data     = $param{data};
    my $callback = $param{callback};

    croak 'Expected "api"' unless defined $api;

    DEBUG('API call %d', $api);

    my $info   = $API[$api] || croak "Unknown API: $api";
    my ($method, $path) = @$info;
    $path = sprintf $path, @$args;

    my ($query, $post_data);
    if ($method eq 'GET' or $method eq 'DELETE') {
        $query = $data;
    } else {
        $post_data = $data;
    }

    my $result = $self->json_request($method, $path, $query, $post_data);

    if (exists $result->{errors}) {
        my @errors = @{$result->{errors}};

        if (@errors) {
            DEBUG("ERRORS: @errors");
            my $message = join(' | ', map { join(', ', @$_) } @errors);
            croak $message;
        }
    }

    if (defined $callback && ref $callback eq 'CODE') {
        return $callback->($result);
    } else {
        return $result;
    }
}

# deprecated, to be removed
sub is_logged_in {
    return defined $_[0]->{modhash};
}

# deprecated, to be removed
sub require_login {
    my $self = shift;
    return;
}


#===============================================================================
# User and account management
#===============================================================================

sub me {
    my $self = shift;
    DEBUG('Request user account info');
    my $result = $self->api_json_request(api => API_ME);
    # Account has no data property like other things
    return Reddit::Client::Account->new($self, $result);
}
sub list_subreddits {
    	my ($self, %param) = @_;
	my $type = $param{view} || SUBREDDITS_HOME;
	$type = '' if lc $type eq 'home';

	my $query = $self->set_listing_defaults(%param);

	my $api = $type eq SUBREDDITS_MOD || $type eq SUBREDDITS_CONTRIB || $type eq SUBREDDITS_MINE ? API_MY_SUBREDDITS : API_SUBREDDITS; 

    my $result = $self->api_json_request(
	api => $api, 
	args => [$type],
	data => $query,
    );

    	return [
        	map {Reddit::Client::SubReddit->new($self, $_->{data})} @{$result->{data}{children}}
    	];
}

sub contrib_subreddits { 
	my ($self, %param) = @_;
	$param{view} = SUBREDDITS_CONTRIB;	
	return $_[0]->list_subreddits(%param);
}
sub home_subreddits    { 
	my ($self, %param) = @_;
	$param{view} = SUBREDDITS_HOME;
	return $_[0]->list_subreddits(%param);
}
sub mod_subreddits     { 
	my ($self, %param) = @_;
	$param{view} = SUBREDDITS_MOD;
	return $_[0]->list_subreddits(%param);
}
sub my_subreddits      { 
	my ($self, %param) = @_;
	$param{view} = SUBREDDITS_MINE;
	return $_[0]->list_subreddits(%param);
}
sub new_subreddits     { 
	my ($self, %param) = @_;
	$param{view} = SUBREDDITS_NEW;
	return $_[0]->list_subreddits(%param);
}
sub popular_subreddits { 
	my ($self, %param) = @_;
	$param{view} = SUBREDDITS_POPULAR;
	return $_[0]->list_subreddits(%param);
}

#===============================================================================
# Inbox and messages
#===============================================================================
sub get_inbox {
	my ($self, %param) = @_;
    	my $limit     	= $param{limit}		|| DEFAULT_LIMIT;
	my $mode	= $param{mode}		|| MESSAGES_INBOX;	
	my $view	= $param{view}		|| MESSAGES_INBOX;

	# this before and after business is stupid and needs to be fixed
	# in 3 separate places
	my $query = {};
	$query->{mark}   = $param{mark} ? 'true' : 'false';
	$query->{sr_detail} = $param{sr_detail} if $param{sr_detail};
        $query->{before} = $param{before} if $param{before};
        $query->{after}  = $param{after}  if $param{after};
	if (exists $param{limit}) { $query->{limit} = $param{limit} || 500; }
	else 			  { $query->{limit} = DEFAULT_LIMIT;	    }
	
	my $result = $self->api_json_request(
		api	=> API_MESSAGES,
		args	=> [$view],
		data	=> $query,
	);

	return [
		map { Reddit::Client::Message->new($self, $_->{data}) } @{$result->{data}{children}}
	];
}

# TODO
sub mark_read {
	my ($self, %param) = @_;

}

sub mark_inbox_read {
	my $self = shift;
	my ($method, $path) = @{$API[API_MARKALL]};
	# Why does this error without api_type? json_request is adding it anyway?
	my $post_data = {api_type => 'json'};
	my $result = $self->request($method, $path, {}, $post_data);
}

#===============================================================================
# Subreddits and listings
#===============================================================================

sub get_subreddit_info {
	my $self	= shift;
	my $sub		= shift || croak 'Argument 1 (subreddit name) is required.';
	$sub = subreddit($sub);

	my $result = $self->api_json_request(
		api 	=> API_SUBREDDIT_INFO,
		args	=> [$sub],
	);
	return $result->{data};
}

sub info {
    my ($self, $id) = @_;
    defined $id || croak 'Expected $id';
    my $query->{id} = $id;
    
    my $info = $self->api_json_request(
		api => API_INFO, 
		data=>$query
	);
	#return $info;
    my $rtn = $info->{data}->{children}[0]->{data};
    $rtn->{kind} = $info->{data}->{children}[0]->{kind} if $rtn;
    return $rtn;
}

sub search {
	my ($self, %param) = @_;
	my $sub = $param{subreddit} || $param{sub} || croak "'subreddit' or 'sub' is required.";

	my $query = $self->set_listing_defaults(%param);
	$query->{q} = $param{q} || croak "'q' (search string) is required."; 

	# things the user should be able to choose but we're hard coding
	$query->{restrict_sr} 	= 'on';
	$query->{include_over18}= 'on';
	$query->{t} 		= 'all';
	$query->{syntax} 	= 'cloudsearch';
	$query->{show} 		= 'all';
	$query->{type}		= 'link'; # return Link objects
	$query->{sort}		= 'top';
	
	my $args = [$sub];

    	my $result = $self->api_json_request(
		api => API_SEARCH, 
		args=> $args, 
		data => $query,
	);

	#return $result->{data};
    	return [
        	map {Reddit::Client::Link->new($self, $_->{data})} @{$result->{data}{children}}
    	       ];
}
sub get_permalink {
	# This still makes an extra request. Why?
	my ($self, $commentid, $post_fullname) = @_;

	if (substr ($commentid, 0, 3) eq "t1_") { $commentid = substr $commentid, 3; } 
	if (substr ($post_fullname, 0, 3) ne "t3_") { $post_fullname = "t3_" . $post_fullname; } 

	my $info = $self->info($post_fullname);
	return sprintf "%s%s%s", $LINK_URL, $info->{permalink}, $commentid;
}

sub find_subreddits {
    	my ($self, %param) = @_;

	my $query 	= $self->set_listing_defaults(%param);
	$query->{q} 	= $param{q} || croak "expected 'q'";
	$query->{sort} 	= $param{sort} || 'relevance';

    	my $result = $self->api_json_request(
		api => API_SUB_SEARCH, 
		data => $query,
	);
    	return [
        	map { Reddit::Client::SubReddit->new($self, $_->{data}) } @{$result->{data}{children}}
    	];
}

sub fetch_links {
    	my ($self, %param) = @_;
    	my $subreddit = $param{sub} || $param{subreddit} || '';
    	my $view      = $param{view}      || VIEW_DEFAULT;

	my $query = $self->set_listing_defaults(%param);

    	$subreddit = subreddit($subreddit);

    	my $args = [$view];
    	unshift @$args, $subreddit if $subreddit;

    	my $result = $self->api_json_request(
        	api      => ($subreddit ? API_LINKS_FRONT : API_LINKS_OTHER),
        	args     => $args,
        	data     => $query,
    	);

    	return [
        	map { Reddit::Client::Link->new($self, $_->{data}) } @{$result->{data}{children}} 
    	];
}

sub get_links { # alias for fetch_links to make naming convention consistent
    my ($self, %param) = @_;
	return $self->fetch_links(%param);
}
# Is this a better way to get a single link than a call to info?
sub get_links_by_id {
	my ($self, @fullnames) = @_;
	die "get_links_by_id: argument 1 (\@fullnames) is required.\n" unless @fullnames;
	@fullnames = map { fullname($_, 't3') } @fullnames;
	my $str = join ",", @fullnames;	
	#my $result = $self->api_json_request(
	$self->{print_request_on_error} = 1;
	my $result = $self->json_request('GET', $API[API_BY_ID][1]."/$str");

	return [
		map { Reddit::Client::Link->new($self, $_->{data}) } @{$result->{data}{children}} 
	];
}

sub get_link {
    	my ($self, $fullname) = @_;
	croak "expected argument 1: id or fullname" unless $fullname;

	$fullname = fullname($fullname, 't3');
	my $info = $self->info($fullname);
	return unless $info;

	return Reddit::Client::Link->new($self, $info);
}

sub get_comment {
    my ($self, $fullname, %param) = @_;
	croak "expected argument 1: id or fullname" unless $fullname;

	$fullname = fullname($fullname, 't1');
	my $info = $self->info($fullname);
	return unless $info;

	my $cmt = Reddit::Client::Comment->new($self, $info);
	if ($param{include_children} and $cmt->{permalink}) {
		$cmt = $self->get_comments(permalink=>$cmt->{permalink});
		$cmt = $$cmt[0];
	} 
	return $cmt;
}

sub get_subreddit_comments {
	my ($self, %param) = @_;
	my $subreddit 	= $param{sub} || $param{subreddit} || '';
	my $view 	= $param{view} 		|| VIEW_DEFAULT;

	my $query = {};
        $query->{before} = $param{before} if $param{before};
        $query->{after}  = $param{after}  if $param{after};
	if (exists $param{limit}) { $query->{limit} = $param{limit} || 500; }
	else 			  { $query->{limit} = DEFAULT_LIMIT;	    }

	$subreddit = subreddit($subreddit); # remove slashes and leading r/
    	#my $args = [$view]; # this did nothing
    	my $args = $subreddit ? [$subreddit] : [];

    	my $result = $self->api_json_request(
        	api      => ($subreddit ? API_COMMENTS : API_COMMENTS_FRONT),
        	args     => $args,
        	data     => $query,
    	);

		#return $result->{data}{children}[0]->{data};
    	return [
        	 map {Reddit::Client::Comment->new($self, $_->{data})} @{$result->{data}{children}} 
    	];
}

#=============================================================
# Moderation
#=============================================================
sub remove {
	my $self = shift;
	my $fullname = shift || croak "arg 1 (fullname) is required.";
	
    	my $result = $self->api_json_request(
		api  => API_REMOVE,
		data => { id => $fullname, spam=> 'false' },
	);
	return $result;
}
# like remove, but sets spam flag
sub spam {
	my $self = shift;
	my $fullname = shift || croak "arg 1 (fullname) is required.";
	
    	my $result = $self->api_json_request(
		api  => API_REMOVE,
		data => { id => $fullname, spam => 'true' },
	);
	return $result;
}
sub approve {
	my $self = shift;
	my $fullname = shift || croak "arg 1 (fullname) is required.";
	
    	my $result = $self->api_json_request(
		api  => API_APPROVE,
		data => { id => $fullname },
	);
	return $result;
}
sub ignore_reports {
	my $self = shift;
	my $fullname = shift || croak "arg 1 (fullname) is required.";
	
	my $result = $self->api_json_request(
		api  => API_IGNORE_REPORTS,
		data => { id => $fullname },
	);
	return $result;
}
# ban uses the "modcontributors" oauth scope
sub ban {
	my ($self, %param) = @_;
	my $sub	= $param{sub} || $param{subreddit} || die "subreddit is required\n";
	
	my $data = {}; 
	$data->{name}	= $param{username} || die "username is required\n";
	# ban_context = fullname, but of what - not required

	# Ban message
	$data->{ban_message} = $param{ban_message} if $param{ban_message};
	# Reason: matches short report reason
	if ($param{reason}) { 
		if (length $param{reason} > 100) {
			print "Warning: 'reason' longer than 100 characters. Truncating.\n";
			$param{reason} = substr $param{reason}, 0, 100;
		}
		$data->{ban_reason} = $param{reason};
	}

	if ($param{note}) {
		if (length $param{note} > 300) {
			print "Warning: 'note' longer than 300 characters. Truncating.\n";
			$param{note} = substr $param{note}, 0, 300;
		}
		$data->{note} = $param{note};
	}

	# $data->{container} not needed unless mode is friend or enemy
	if ($param{duration}){
		if ($param{duration} > 999) {
			print "Warning: Max duration is 999. Setting to 999.\n";
			$param{duration} = 999;
		} elsif ($param{duration} < 1) {
			print "Warning: min duration is 1. Setting to indefinite.\n";
			$param{duration} = 0;
		}
		$data->{duration} = $param{duration} if $param{duration};
	}
	# $data->{permissions} = ?
	# type: one of (friend, moderator, moderator_invite, contributor, banned, muted, wikibanned, wikicontributor)
	$data->{type} = 'banned';

	my $result = $self->api_json_request(
		api  => API_BAN, 
		args => [$sub],
		data => $data,
	);
	return $result;
}
sub get_modlinks {
    my ($self, %param) = @_;

	my $query = $self->set_listing_defaults(%param);
	my $sub   = $param{sub} || $param{subreddit} || 'mod';
	my $mode  = $param{mode} || 'modqueue';

	my $result = $self->api_json_request(
		api  => API_MODQ, 
		args => [$sub, $mode],
		data => $query,
	);

	#return $result->{data};

	return [
		map {

		$_->{kind} eq "t1" ? 
			Reddit::Client::Comment->new($self, $_->{data}) :
			Reddit::Client::Link->new($self, $_->{data})
		} 

		@{$result->{data}{children}} 
	];
}
sub get_modqueue { 
    my ($self, %param) = @_;
	$param{mode} = 'modqueue';
	return $self->get_modlinks(%param);
}

# after: conversation id
# entity: comma-delimited list of subreddit names
# limit
# sort: one of (recent, mod, user, unread)
# state: one of (new, inprogress, mod, notifications, archived, highlighted, all
sub get_modmail {
    	my ($self, %param) = @_;

	my $data	= {};
	$data->{sort}	= $param{sort} || 'unread';
	$data->{state}	= $param{state} || 'all';
	$data->{after}	= $param{after} if $param{after};
	$data->{limit}	= exists $param{limit} ? ( $param{limit} ? $param{limit} : 500 )  : DEFAULT_LIMIT;

	my $subs	= $param{entity} || $param{subreddits} || $param{subs};
	if ($subs) {
		$subs		= join ",", @$subs if ref $subs eq 'ARRAY';	
		$data->{entity} = $subs if $subs;
	}
	my $result = $self->api_json_request(
		api	=> API_GET_MODMAIL,
		data	=> $data,
	);
	return $result;
}
sub get_modmail_raw {
    	my ($self, %param) = @_;

	my $data	= {};
	$data->{sort}	= $param{sort} || 'unread';
	$data->{state}	= $param{state} || 'all';
	$data->{after}	= $param{after} if $param{after};
	$data->{limit}	= exists $param{limit} ? ( $param{limit} ? $param{limit} : 500 )  : DEFAULT_LIMIT;

	my $subs	= $param{entity} || $param{subreddits} || $param{subs};
	if ($subs) {
		$subs		= join ",", @$subs if ref $subs eq 'ARRAY';	
		$data->{entity} = $subs if $subs;
	}
	my $result = $self->api_json_request(
		api	=> API_GET_MODMAIL,
		data	=> $data,
	);
	return $result;
}

#=============================================================
# Users
#=============================================================
sub get_user {
    	my ($self, %param) = @_;
	my $view	= $param{view} || 'overview';
	my $user	= $param{user} || croak "expected 'user'";

	my $query = $self->set_listing_defaults(%param);

    	my $args = [$user, $view];

	my $result = $self->api_json_request(
		api      => API_USER,
		args     => $args,
		data     => $query,
	);

	if ($view eq 'about') {
		#return $result->{data};
		return Reddit::Client::Account->new($self, $result->{data});
	}
	return [
		map {

		$_->{kind} eq "t1" ? 
			Reddit::Client::Comment->new($self, $_->{data}) :
			Reddit::Client::Link->new($self, $_->{data})
		} 

		@{$result->{data}{children}} 
	];
}
# Remember that this will return a new hash and any key not from here will be
# wuped out
sub set_listing_defaults {
    	my ($self, %param) = @_;
	my $query = {};
    	$query->{before} = $param{before} if $param{before};
    	$query->{after}  = $param{after}  if $param{after};
	$query->{only}   = $param{only}   if $param{only};
	$query->{count}  = $param{count}  if $param{count};
	$query->{show}	 = 'all' 	  if $param{show} or $param{show_all};
	$query->{sr_detail} = 'true' 	  if $param{sr_detail};
   	if (exists $param{limit}) { $query->{limit} = $param{limit} || 500; }
	else 			  { $query->{limit} = DEFAULT_LIMIT;	    }
	
	return $query;
}
#===============================================================================
# Change posts or comments
#===============================================================================

sub edit {
    	my ($self, $name, $text) = @_;
    	my $type = substr $name, 0, 2;
    	croak 'Argument 1 ($fullname) must be a post or comment.' if $type ne 't1' && $type ne 't3';
	croak 'Argument 2 (text) is required. Empty strings are allowed.' unless defined $text;

	my $data = {
		thing_id	=> $name,
		text		=> $text
	};

	my $result = $self->api_json_request(
		api	=> API_EDIT,
		data	=> $data,
	);
	return $result;
}

sub delete {
    	my ($self, $name) = @_;
    	croak 'Expected $fullname' if !$name;
    	my $type = substr $name, 0, 2;
    	croak '$fullname must be a post or comment' if $type ne 't1' && $type ne 't3';

    	DEBUG('Delete post/comment %s', $name);

    	my $result = $self->api_json_request(api => API_DEL, data => { id => $name });
    	return 1;
}

#===============================================================================
# Submitting links
#===============================================================================

sub submit_link {
    my ($self, %param) = @_;
	# why is sub allowed to be empty?
    my $subreddit = $param{subreddit} || $param{sub} || '';
    my $title     = $param{title}     || croak 'Expected "title"';
    my $url       = $param{url}       || croak 'Expected "url"';
    my $replies = exists $param{inbox_replies} ? ($param{inbox_replies} ? "true" : "false") : "true";
    my $repost = exists $param{repost} ? ($param{repost} ? "true" : "false") : "false";

    DEBUG('Submit link to %s: %s', $subreddit, $title, $url);

    $subreddit = subreddit($subreddit);

    my $result = $self->api_json_request(api => API_SUBMIT, data => {
        title       => $title,
        url         => $url,
        sr          => $subreddit,
        kind        => SUBMIT_LINK,
		sendreplies => $replies,
		resubmit    => $repost,
    });

    return $result->{data}{name};
}

sub submit_crosspost {
    my ($self, %param) = @_;
	# why is subreddit allowed to be empty?
    my $subreddit = $param{subreddit} || $param{sub} || die "expected 'subreddit'\n";
    my $title     = $param{title}     || die "Expected 'title'\n";
	my $source_id = $param{source_id} || die "Expected 'source_id'\n";
	$source_id = "t3_$source_id" if lc substr($source_id, 0, 3) ne 't3_';
    #my $url       = $param{url}       || croak 'Expected "url"';
    my $replies = exists $param{inbox_replies} ? ($param{inbox_replies} ? "true" : "false") : "true";
    my $repost = exists $param{repost} ? ($param{repost} ? "true" : "false") : "false";

    $subreddit = subreddit($subreddit);

    my $result = $self->api_json_request(api => API_SUBMIT, data => {
        title       		=> $title,
        #url         => $url,
		crosspost_fullname 	=> $source_id, 
        sr          		=> $subreddit,
        kind        		=> SUBMIT_CROSSPOST,
		sendreplies 		=> $replies,
		resubmit    		=> $repost,
    });

    return $result->{data}{name};
}

sub submit_text {
    my ($self, %param) = @_;
    my $subreddit = $param{subreddit} || $param{sub} || die "expected 'subreddit'\n";
    my $title     = $param{title}     || croak 'Expected "title"';
    my $text      = $param{text}      || croak 'Expected "text"';
    # true and false have to be the strings "true" or "false"
    my $replies = exists $param{inbox_replies} ? ($param{inbox_replies} ? "true" : "false") : "true";

    DEBUG('Submit text to %s: %s', $subreddit, $title);

    $subreddit = subreddit($subreddit);

    my $result = $self->api_json_request(api => API_SUBMIT, data => {
        title    => $title,
        text     => $text,
        sr       => $subreddit,
        kind     => SUBMIT_SELF,
	sendreplies=>$replies,
    });

    return $result->{data}{name};
}
# This could go in the user section or here, but it seems like it will be
# more commonly used for flairing posts
sub set_post_flair {
    	my ($self, %param) = @_;
	my $sub 	= $param{subreddit} || croak "Expected 'subreddit'";
	my $post_id 	= $param{post_id} || croak "Need 'post_id'";
	my $flairid	= $param{flair_template_id} || croak "need 'flair template id'";
	my $data	= {};

	if (!$self->ispost($post_id)) { $post_id = "t3_".$post_id; }
	$data->{link} = $post_id;
	$data->{flair_template_id} = $flairid;

	my $result = $self->api_json_request(
		api 	=> API_SELECTFLAIR,
		args 	=> [$sub],
		data	=> $data
	);

	#return @{$result->{data}{children}};
}
sub set_user_flair {
    	my ($self, %param) = @_;
	my $sub 	= $param{subreddit} || croak "Expected 'subreddit'";
	my $user 	= $param{username} || croak "Need 'username'";
	my $flairid	= $param{flair_template_id} || croak "need 'flair template id'";
	my $data	= {};

	$data->{name} = $user;
	$data->{flair_template_id} = $flairid;

	my $result = $self->api_json_request(
		api 	=> API_SELECTFLAIR,
		args 	=> [$sub],
		data	=> $data
	);

	#return @{$result->{data}{children}};
}

# Return a hash reference with keys 'choices' and 'current'
# 'choices' is array of hashes with flair options
# 'current' is the post's current flair
sub get_flair_options {
    	my ($self, %param) = @_;
	my $sub 	= $param{subreddit} || croak "Expected 'subreddit'";
	my $post_id = $param{post_id};
	my $user	= $param{username};
	my $data	= {};

	if ($post_id) {
		if (!$self->ispost($post_id)) { $post_id = "t3_".$post_id; }
		$data->{link} = $post_id;
	} elsif ($user) {
		$data->{user} = $user;
	} else {
		croak "Need 'post_id' or 'username'";
	}


	my $result = $self->api_json_request(
		api 	=> API_FLAIROPTS,
		args 	=> [$sub],
		data	=> $data,
	);

	if ($result->{choices}) {
		for (my $i=0; $result->{choices}[$i]; $i++) {
			$result->{choices}[$i]->{flair_text_editable} = $result->{choices}[$i]->{flair_text_editable} ? 1 : 0;

		}
	}

	return $result;
}

#==============================================================================
# Subreddit management
#==============================================================================

sub get_wiki {
	my ($self, %param) = @_;
	my $page 	= $param{page} || croak "Need 'page'";
	my $sub 	= $param{sub} || $param{subreddit} || die "need subreddit\n";

	my $data 	= {};
	$data->{v}	= $param{v}   if $param{v};
	$data->{v2}	= $param{v2}  if $param{v2};

	
	my $result = $self->api_json_request(
		api 	=> API_GETWIKI,
		args 	=> [$sub, $page],
		data	=> $data,
	);
	return $param{data} ? $result->{data} : $result->{data}->{content_md};
}
sub get_wiki_data {
	my ($self, %param) = @_;
	$param{data} = 1;
	return $self->get_wiki(%param);
}

sub edit_wiki {
	my ($self, %param) = @_;
	my $page 	= $param{page} || croak "Need 'page'";
	my $content	= defined $param{content} ? $param{content} : croak "Need 'content'";
	# Reddit maximum length is 524,288
	if (length $content > 524288) { croak "Maximum length for 'content' is 524288 bytes."; }
	my $sub		= $param{sub} || $param{subreddit} || croak "Need 'sub' or 'subreddit'";
	my $previous	= $param{previous};
	my $reason	= $param{reason};

	my $data	= {};
	$data->{page}	= $page;
	$data->{content}= $content;	
	if ($previous) 	{ $data->{previous} = $previous; }
	if ($reason) 	{ $data->{reason} = substr $reason, 0, 256; }

	my $result = $self->api_json_request(
		api 	=> API_EDITWIKI,
		args 	=> [$sub],
		data	=> $data,
	);

	return $result;
}

#===============================================================================
# Comments
#===============================================================================
sub get_comments { 
    my ($self, %param) = @_;
    my $permalink;
	my $sub		= $param{sub} || $param{subreddit};

	if ($param{permalink}) {
		$permalink = $param{permalink};
	} elsif ($sub and $param{comment_id} and $param{link_id}) {
		my $id = id($param{link_id});
		my $cmtid = id($param{comment_id});
		$permalink = "/r/$sub/comments/$id//$cmtid";
	} elsif ($sub and $param{id}) {
		my $id = id($param{id});
		$permalink = "/r/$sub/comments/$id";
	} elsif ($param{url}) {
		$permalink = $param{url};
		$permalink =~ s/^https?:\/\/([a-zA-Z]{1,3}\.)?reddit\.com//i;
	} else {
		die "get_comments: Either 'permalink' OR 'url' OR 'subreddit' and 'link_id' OR 'subreddit' and 'link_id' and 'comment_id' are required.\n";
	}

    my $result  = $self->json_request('GET', $permalink);
	my $link_id	= $result->[0]{data}{children}[0]{data}{name};
	# result->[0] is a listing with 1 element, the link, even if you requested a cmt
    my $comments = $result->[1]{data}{children};

	my $return = [];
	for my $cmt (@$comments) {
		if ($cmt->{kind} eq 't1') {
			push @$return, Reddit::Client::Comment->new($self, $cmt->{data});
		} elsif ($cmt->{kind} eq 'more') {
			my $more = Reddit::Client::MoreComments->new($self, $cmt->{data});
			$more->{link_id} = $link_id;
			push @$return, $more;
		}
	}
	return $return;
}
# limit_children: get these comments and their descendants
sub get_collapsed_comments {
    my ($self, %param) = @_;
	my $link_id		= fullname($param{link_id},'t3') || die "load_more_comments: 'link_id' is required.\n";
	my $children	= $param{children} || die "get_collapsed_comments: 'children' is required.\n";
	my $limit		= exists $param{limit_children} ? ($param{limit_children} ? 'true' : 'false') : 'false';
	my $ids;

	if (ref $children eq 'ARRAY') { 
		$ids = join ",", @$children;
		die "'children' must be non-empty array reference" unless $ids;
	} else {
		die "get_collapsed_comments: 'children' must be array reference\n"; 
	}

	my $data = {
		link_id			=> $link_id,
		children		=> $ids,	
		limit_children	=> $limit, 
		api_type		=> 'json', # This is the only GET endpoint that requires
	};							   # api_type=json to be set.

	$data->{sort} 		= $param{sort} if $param{sort};
	$data->{id}			= $param{id} if $param{id};

	my $result = $self->api_json_request(
		api		=> API_MORECHILDREN,
		data	=> $data,
	);
	my $comments = $result->{data}->{things};

	my $return = [];
	for my $cmt (@$comments) {
		if ($cmt->{kind} eq 't1') {
			push @$return, Reddit::Client::Comment->new($self, $cmt->{data});
		} elsif ($cmt->{kind} eq 'more') {
			my $more = Reddit::Client::MoreComments->new($self, $cmt->{data});
			$more->{link_id} = $link_id;
			push @$return, $more;
		}
	}
	return $return;
}

sub submit_comment {
    my ($self, %param) = @_;
    my $parent_id = $param{parent} || $param{parent_id} || croak 'Expected "parent"';
    my $comment   = $param{text}      || croak 'Expected "text"';
	# the replies option, it does nothing
    #my $replies = exists $param{inbox_replies} ? ($param{inbox_replies} ? "true" : "false") : "true";

    croak '$fullname must be a post or comment' if !$self->ispost($parent_id) && !$self->iscomment($parent_id);
    DEBUG('Submit comment under %s', $parent_id);

    my $result = $self->api_json_request(api => API_COMMENT, data => {
        thing_id => $parent_id,
        text     => $comment,
		#sendreplies=>$replies,
    });

    return $result->{data}{things}[0]{data}{id};
}

sub comment {
	my($self, $parent, $text) = @_;
	return $self->submit_comment(parent_id=>$parent, text=>$text);
}

#===============================================================================
# Private messages
#===============================================================================

sub send_message {
    	my ($self, %param) = @_;
	my $to		= $param{to}	 	|| croak 'Expected "to"';
	my $subject	= $param{subject}	|| croak 'Expected "subject"';
	my $text	= $param{text}		|| croak 'Expected "text"';

	croak '"subject" cannot be longer than 100 characters' if length $subject > 100;
    	
	#$self->require_login;
    	DEBUG('Submit message to %s: %s', $to, $subject);

    	my $result = $self->api_json_request(api => API_MESSAGE, data => {
       	 to    		=> $to,
       	 subject  	=> $subject,
       	 text		=> $text,
       	 kind   	=> SUBMIT_MESSAGE,
    	});

	return $result;
}

#===============================================================================
# Voting
#===============================================================================

sub vote {
    my ($self, $name, $direction) = @_;
    defined $name      || croak 'Expected $name';
    defined $direction || croak 'Expected $direction';
    croak '$fullname must be a post or comment' if !$self->ispost($name) && !$self->iscomment($name);
    croak 'Invalid vote direction' unless "$direction" =~ /^(-1|0|1)$/;
    DEBUG('Vote %d for %s', $direction, $name);
    $self->api_json_request(api => API_VOTE, data => { dir => $direction, id  => $name });
}

#===============================================================================
# Saving and hiding
#===============================================================================

sub save {
    my $self = shift;
    my $name = shift || croak 'Expected $fullname';
    croak '$fullname must be a post or comment' if !$self->ispost($name) && !$self->iscomment($name);
    DEBUG('Save %s', $name);
    $self->api_json_request(api => API_SAVE, data => { id => $name });
}

sub unsave {
    my $self = shift;
    my $name = shift || croak 'Expected $fullname';
    croak '$fullname must be a post or comment' if !$self->ispost($name) && !$self->iscomment($name);
    DEBUG('Unsave %s', $name);
    $self->api_json_request(api => API_UNSAVE, data => { id => $name });
}

sub hide {
    my $self = shift;
    my $name = shift || croak 'Expected $fullname';
    croak '$fullname must be a post' if !$self->ispost($name);
    DEBUG('Hide %s', $name);
    $self->api_json_request(api => API_HIDE, data => { id => $name });
}

sub unhide {
    my $self = shift;
    my $name = shift || croak 'Expected $fullname';
    croak '$fullname must be a post' if !$self->ispost($name);
    DEBUG('Unhide %s', $name);
    $self->api_json_request(api => API_UNHIDE, data => { id => $name });
}

#==============================================================================
# Multireddits
#==============================================================================

sub edit_multi {
        my ($self, %param) = @_;
	$param{edit} = 1;
	$self->create_multi(%param);
}
sub create_multi {
        my ($self, %param) = @_;
	my $data 	= {};
        my $model 	= {};
	my $username    = $param{username} || $self->{username} || die "'username' is required.";

        $model->{display_name}  = $param{name} || croak "Expected 'name'.";
        if (length($model->{display_name}) > 50) { croak "max length of 'name' is 50."; }

        $model->{description_md} = $param{description} if $param{description};

        if ($param{icon_name}) {
		$model->{icon_name} = $param{icon_name};
		my @iconnames = ('art and design', 'ask', 'books', 'business', 'cars', 'comics', 'cute animals', 'diy', 'entertainment', 'food and drink', 'funny', 'games', 'grooming', 'health', 'life advice', 'military', 'models pinup', 'music', 'news', 'philosophy', 'pictures and gifs', 'science', 'shopping', 'sports', 'style', 'tech', 'travel', 'unusual stories', 'video', '', 'None');
		my $match = 0;
		foreach my $i (@iconnames) {
			$match = 1 if $i eq $model->{icon_name};
		}
		my $iconstr = join ", ", @iconnames;
		if (!$match) {croak "if 'icon_name' is provided, it must be one of the following values: $iconstr. Note that the purpose of icon_str is unclear and you should not use it unless you know what you're doing."; }
        }

        if ($param{key_color}) {
        	$model->{key_color} = "#".$param{key_color};
		if (length($model->{key_color}) != 7) { croak "'key_color' must be a 6-character color code"; }
	}

        if ($param{visibility}) {
		    $model->{visibility} = $param{visibility};
        	if ($model->{visibility} ne 'private' and
 	   	    $model->{visibility} ne 'public'  and
                    $model->{visibility} ne 'hidden') {
                	croak "if provided, 'visibility' must be either 'public', 'private', or 'hidden'.";
        	}
	}

        if ($param{weighting_scheme}) {
		$model->{weighting_scheme} = $param{weighting_scheme};
		if ($model->{weighting_scheme} ne 'classic' and $model->{weighting_scheme} ne 'fresh') { croak "if 'weighting_scheme' is provided, it must be either 'classic' or 'fresh'"; }
	}
		
	if ($param{subreddits} or $param{subs}) {
		$param{subreddits} = $param{subs} || $param{subreddits};
        	if (ref $param{subreddits} ne 'ARRAY') { croak "'subreddits' must be an array reference."; }

		$model->{subreddits} = [ map { { name=> $_ } } @{$param{subreddits}} ];
	}

	# Put a ribbon on it
	$data->{model} = JSON::encode_json($model); 
	$data->{multipath} = "/user/$username/m/$model->{display_name}";

	my $result = $self->api_json_request( 
		api => $param{edit} ? API_EDITMULTI : API_CREATEMULTI, 
		args => [$username, $model->{display_name}],
		data => $data,
	);

	return $result->{data};
}

sub get_multi {
	my ($self, %param) = @_;
	my $name	= $param{name} || croak "expected 'name'";
	my $username= $param{user} || $param{username} || $self->{username} || die "'username' is required.\n";
	my $expand	= $param{expand} ? '?expand_srs=true' : '';

	my $result = $self->api_json_request( 
		api => API_GETMULTI, 
		args => [$username, $name, $expand],
	);

	# The result looks like a Subreddit object, but is not.
	# By returning just the data we lose only the 'kind' key,
	# which is just the string "LabeledMulti"
	return $result->{data};
}

sub delete_multi {
	my $self = shift;
	my $name = shift || croak "expected arg 1 (name)";

	my $result = $self->api_json_request( 
		api => API_DELETEMULTI,
		args => [$self->{username}, $name],
	);
	return $result->{data};
}
#==============================================================================
# Misc
#==============================================================================
sub get_origin { 
	my $self = shift;
	return "https://$self->{subdomain}.reddit.com";	
}

#==============================================================================
# Internal and static
#==============================================================================

# Strip the type portion of a filname (i.e. t3_), if it exists
sub id {
	my $id	= shift;
	$id 	=~ s/^[tT]\d_//;
	return $id;
}
# accept id or fullname, always return fullname
sub fullname {
	my $id 		= shift || return;
	my $type	= shift || die "fullname: 'type' is required";
	$id = $type."_".$id if substr($id, 0, 3) ne $type."_";
	return $id;
}

sub ispost { # todo: make this static function
	my ($self, $name) = @_;
    	my $type = substr $name, 0, 2;
	return $type eq 't3';
}

sub iscomment { # todo: make this static
	my ($self, $name) = @_;
    	my $type = substr $name, 0, 2;
	return $type eq 't1';
}
sub get_type { # ditto
	my ($self, $name) = @_;
    	return lc substr $name, 0, 2;
}
sub DEBUG {
    if ($DEBUG) {
        my ($format, @args) = @_;
        my $ts  = strftime "%Y-%m-%d %H:%M:%S", localtime;
        my $msg = sprintf $format, @args;
        chomp $msg;
        printf STDERR "[%s] [ %s ]\n", $ts, $msg;
    }
}

sub subreddit {
    my $subject = shift;
    $subject =~ s/^\/r//; # trim leading /r
    $subject =~ s/^\///;  # trim leading slashes
    $subject =~ s/\/$//;  # trim trailing slashes

    if ($subject !~ /\//) {   # no slashes in name - it's probably good
        if ($subject eq '') { # front page
            return '';
        } else {              # subreddit
            return $subject;
        }
    } else { # fail
        return;
    }
}

1;

__END__

=pod

=head1 NAME

Reddit::Client - A Perl wrapper for the Reddit API.

=head1 DESCRIPTION

Reddit::Client handles Oauth session management and HTTP communication with Reddit's external API. For more information about the Reddit API, see L<https://github.com/reddit/reddit/wiki/API>. 

=head1 SYNOPSIS

    use Reddit::Client;
    
    my $client_id   = "DFhtrhBgfhhRTd";
    my $secret      = "KrDNsbeffdbILOdgbgSvSBsbfFs";
    
    # Create a Reddit::Client object and authorize in one step: "script" app
    my $reddit = new Reddit::Client(
        user_agent  => "Test script 1.0 by /u/myusername",
        client_id   => $client_id,
        secret      => $secret,
        username    => "reddit_username",
        password    => "reddit_password",
    );
    
    # Create a Reddit::Client object and authorize in one step: "web" app
    my $reddit = new Reddit::Client(
        user_agent    => "Test script 1.0 by /u/myusername",
        client_id     => $client_id,
        secret        => $secret,
        refresh_token => "refresh_token",
    );	
    
    # Check your inbox
    my $me = $reddit->me();
    print "You've got mail!" if $me->{has_mail};
    
    # Submit a link
    $reddit->submit_link(
        subreddit   => "test",
        title       => "Change is bad, use Perl",
        url         => "http://www.perl.org",
    );
    
    # Get posts from a subreddit or multi
    my $posts = $reddit->get_links(subreddit=>'test', limit=>5);
    
    foreach my $post (@$posts) {
        print $post->{is_self} ? $post->{selftext} : $post->{url};
        print $post->get_web_url();

        if ($post->{title} =~ /some phrase/) {
            $post->reply("hi, I'm a bot");
        }
    }

=head1 OAUTH

Reddit::Client uses Oauth to communicate with Reddit. To get Oauth keys, visit your apps page on Reddit, located at L<https://www.reddit.com/prefs/apps>, and create an app. There are three types of apps available. Reddit::Client supports "script" and "web" type apps.

=over

=item Script apps

Most users will want a "script"-type app. This is an app intended for personal use that uses a username and password to authenticate. The I<description> and I<about url> fields can be empty, and the I<redirect URI> can be any valid URL (script apps don't use them). Once created, you can give other users permission to use it by adding them in the "add developer" field. (They each use their own username and password to authenticate.)

Use the app's client id and secret along with your username and password to create a L<new|https://metacpan.org/pod/Reddit::Client#new> Reddit::Client object.

=item Web apps

As of v1.20, Reddit::Client also supports "web" apps. These are apps that can take actions on behalf of any user that grants them permission. (If you have ever seen a permission screen for a Reddit app that says "SomeRedditApp wants your permission to...", that's a web app.)

While they are fully supported, there is not yet a setup guide, so getting one running is left as an exercise for the reader. You will need a web server, which you will use to direct users to Reddit's authorization page, which will get the user's permission to do whatever the app has asked to do. It will then redirect the user back to the app's I<redirect URI>. This process generates a refresh token, which is a unique string that your app will use to authenticate instead of a username and password. You will probably want to store refresh tokens locally, otherwise you will have to get permission from the user every time the app runs.

Documentation for the web app flow can be found at L<https://github.com/reddit-archive/reddit/wiki/OAuth2>.

=back

=head1 TERMINOLOGY

Reddit's API is slightly inconsistent in its naming. To avoid confusion, this guide will always use the following terms in the following ways:

=over

=item fullname

A thing's complete ID with prefix. Example: t1_3npkj4. Whe Reddit returns data, the fullname is usually found in the "name" field. The type of thing can be determined by the prefix; for example, t1 for comments and t3 for links.

=item id

A thing's short ID without prefix. Example: 3npkj4. Seen in your address bar when viewing, for example, a post or comment. 

=back

=head1 LISTINGS

Methods that return listings can accept several optional parameters:

=over

C<limit>: Integer. How many things to return. Default 25, maximum 100. If I<limit> is present but false, this is interpreted as "no limit" and the maximum is returned.

C<before>: Fullname. Return results that occur before I<fullname> in the listing. 

C<after>: Fullname. Return results that occur after I<fullname> in the listing.

C<count>: Integer. Appears to be used by the Reddit website to number listings after the first page. Listings returned by the API are not numbered, so it does not seem to have a use in the API.

C<only>: The string "links" or "comments". Return only links or only comments. Only relevant to listings that could contain both.

C<show_all>: Boolean. Return items that would have been omitted, for example posts you have hidden, or have reported, or are hidden from you because you are using the option to hide posts after you've upvoted/downvoted them. Default false.

=back

Note that 'before' and 'after' mean before and after I<in the listing>, not necessarily in time. It's best to think of Reddit as a database where new lines are constantly inserted at the top, because that's basically what it is.

=head1 MISC

All functions that take the parameter 'subreddit' also accept the alias 'sub'.

This guide indicates optional arguments with brackets ([]), a convention we borrowed from from PHP's online manual. This creates some slight overlap with Perl's brackets, which are used to indicate an anonymous array reference, however which of the two is intended should be clear from the context.

=head1 METHODS

=over

=item approve

    approve ( $fullname )

Approve a comment or post (moderator action).

=item ban

    ban ( username => $username, subreddit => $subreddit,
        [ duration => $duration, ] [ ban_message => $message, ] [ reason => $reason, ] [ note => $note ] )

Ban a user from a subreddit. C<username> and C<subreddit> are required. Optional arguments include:

=over

C<duration>: Duration in days. Range 1-999. If false or not provided, the ban is indefinite.

C<ban_message>: The message sent to the banned user. (Markdown is allowed.)

C<reason>: A short ban reason (100 characters max). On the website ban page, this matches the ban reason you would select from the dropdown menu. It is arbitrary: it doesn't have to match up with the reasons from the menu and can be blank. Only visible to moderators.

C<note>: An optional note, 300 characters max. Only visible to moderators. Will be concatenated to the `reason` on the subreddit's ban page.

=back

A ban will overwrite any existing ban for that user. For example, to change the duration, you can call C<ban()> again with a new duration.

=item comment

    comment ( $fullname, $text )
	
Make a comment under C<$fullname>, which must be either a post or a comment. Return the fullname of the new comment.

This function is an alias for C<submit_comment>, and is equivalent to

    submit_comment ( parent_id => $fullname, text => $text )
	
=item create_multi

    create_multi ( name => $multi_name, 
                 [ description => $description, ] [ visibility => $visibility, ] [ subreddits => [ subreddits ], ]
                 [ icon_name => $icon_name, ] [ key_color => $hex_code, ] [ weighting_scheme => $weighting_scheme, ] )

Create a multireddit. The only required argument is the name. A multi can also be created with C<edit_multi>, the only difference being that C<create_multi> will fail with a HTTP 409 error if a multi with that name already exists.

Returns a hash of information about the newly created multireddit.

=over

C<name> The name of the multireddit. Maximum 50 characters. Only letters, numbers and underscores are allowed (and underscores cannot be the first character). Required.

C<description> Description of the multi. This can contain markdown.

C<visibility> One of 'private', 'public', or 'hidden'. Default 'private'.

C<subreddits> or C<subs>: An array reference.

=back

The remaining arguments don't currently do anything. It seems like at least some of them are intended for future mobile updates.

=over

C<icon_name>: If provided, must be one of the following values: 'art and design', 'ask', 'books', 'business', 'cars', 'comics', 'cute animals', 'diy', 'entertainment', 'food and drink', 'funny', 'games', 'grooming', 'health', 'life advice', 'military', 'models pinup', 'music', 'news', 'philosophy', 'pictures and gifs', 'science', 'shopping', 'sports', 'style', 'tech', 'travel', 'unusual stories', 'video', '', 'None'.

C<weighting_scheme>: If provided, must be either 'classic' or 'fresh'.

C<key_color>: A 6-character hex code. Defaults to CEE3F8.

=back

=item delete 

    delete ( $fullname )

Delete a post or comment.

=item delete_multi

    delete_multi ( $multireddit_name )
	
Delete a multireddit.

=item edit

    edit ( $fullname, $text )
	
Edit a text post or comment. Unlike on the website, C<$text> can be an empty string, although to prevent accidental wipeouts it must be defined.

=item edit_multi

Edit a multireddit. Will create a new multireddit if one with that name doesn't exist. The arguments are identical to [create_multi](#create_multi).

=item edit_wiki

    edit_wiki ( subreddit => $subreddit, page => $page, content => $content,
              [ previous => $previous_version_id, ] [ reason => $edit_reason, ] )

=over
	
C<page> is the page being edited.

C<content> is the new page content. Can be empty but must be defined. Maximum 524,288 characters.

C<reason> is the edit reason. Max 256 characters, will be truncated if longer. Optional.

C<previous> is the ID of the intended previous version of the page; if provided, that is the version the page will be rolled back to in a rollback. However, there's no way to find out what this should be from the Reddit website, or currently from Reddit::Client either. Use it only if you know what you're doing.

=back

=item find_subreddits

    find_subreddits ( q => $query, [ sort => 'relevance', ]  )

Returns a list of Subreddit objects matching the search string C<$query>. Optionally sort them by C<sort>, which can be "relevance" or "activity".

=item get_collapsed_comments

    get_collapsed_comments ( link_id => $link_id, children => $children,
                           [ limit_children => 0, ] [ sort => $sort, ] )

Expand a list of collapsed comments found in a MoreComments object. Return a flat list of Comment objects.

=over

C<link_id> is the ID of the link the comments are under. 

C<children> is a reference to an array containing the comment IDs. 

If C<limit_children> is true, return only the requested comments, not replies to them. Otherwise return as many replies as possible (possibly resulting in more MoreComments objects down the line).

C<sort> is one of 'confidence', 'top', 'new', 'controversial', 'old', 'random', 'qa', 'live'. Default seems to be 'confidence'.

=back

=item get_comment 

    get_comment ( $id_or_fullname, [ include_children => 0 ] )

Returns a Comment object for C<$id_or_fullname>. Note that by default, this only includes the comment itself and not replies. This is by Reddit's design; there isn't a way to return a comment and its replies in one request, using only the comment's id. 

You can get its replies at the same time by setting C<include_children> to a true value, which will cause Reddit::Client to make a second request before getting back to you.

=item get_comments

    get_comments ( subreddit => $subreddit, link_id => $link_id_or_fullname )

or 

    get_comments ( subreddit => $subreddit, link_id => $link_id_or_fullname, comment_id => $comment_id_or_fullname )

or

    get_comments ( permalink => $permalink )

or

    get_comments ( url => $url )

Get the comment tree for the selected subreddit/link\_id, subreddit/link\_id/comment_id, permalink, or URL. This will be a mix of Comment and MoreComments objects, which are placeholders for collapsed comments. This is analogous to the "show more comments" links on the website.

If you already have a Link or Comment object, it's best to call its own C<get_comments> method, which takes no arguments and supplies all of the necessary information for you. If you do decide to use this version:

=over

C<permalink> is the value found in the C<permalink> field of a Link or Comment. It is the URL minus the protocol and hostname, i.e. "/r/subreddit/comments/link_id/optional_title/comment_id". This is somewhat awkward but it's just how Reddit works. It's not intended to be something you contruct yourself; this option is intended for passing in the C<permalink> from an existing Link or Comment.

C<url> is a complete URL for a link or comment, i.e. what would be in address bar on the website.

C<subreddit>, C<link_id> and C<comment_id> should be self explanatory. It accepts either short IDs or fullnames, and like all functions that take C<subreddit> as an argument, it can be appreviated to C<sub>.

=back

Interally, all of these options simply create a permalink and pass it on to Reddit's API, because that is the only argument that this endpoint accepts.

=item get_flair_options

    get_flair_options( subreddit => $subreddit, post_id => $post_id_or_fullname )

    get_flair_options( subreddit => $subreddit, username => $username )
	
Return the flair options for either the post or the user provided.

Returns a hash containing two keys:

=over

C<choices> is an array of hash references containing the flair options. Most important is C<flair_template_id>, which is used to set the flair of a post or user with set_post_flair or set_user_flair. C<flair_text> contains the text of the flair.

C<current> is a hash of the post or user's existing flair.

=back

=item get_inbox 

    get_inbox ( [ view => MESSAGES_INBOX ] )
				
Returns a listing of Message objects, where C<view> is one of the MESSAGE L<constants|https://metacpan.org/pod/Reddit::Client#CONSTANTS>. All arguments are optional. If all are omitted your default inbox will be returned-- what you would see if you went to reddit.com and clicked the mailbox icon.

Checking your inbox via the API doesn't mark it as read. To do that you'll need to call C<mark_inbox_read>.

=item get_link 

    get_link ( $id_or_fullname )

Returns a Link object for C<$id_or_fullname>.

=item get_links

    get_links ( [ subreddit => undef, ] [ view => VIEW_DEFAULT, ] )

Returns a listing of Link objects. All arguments are optional.

C<subreddit> can be a subreddit or multi (ex: "pics+funny"). If omitted, results from the user's front page will be returned-- i.e. what you would see if you visited reddit.com as that user. 
		
C<fetch_links()> is an alias for C<get_links()>.

=item get_links_by_id

    get_links_by_id ( @ids_or_fullnames )

Return an array of Link objects.

=item get_modlinks

    get_modlinks ( [ subreddit => 'mod', ] [ mode => 'modqueue' ] )
	
Return links related to subreddit moderation. C<subreddit> defaults to 'mod', which is subreddits you moderate. C<mode> can be one of 5 values: reports, spam, modqueue, unmoderated, and edited. It defaults to 'modqueue'. Using both defaults will get you the same result as clicking the "modqueue" link that RES places in the upper left of the page, or /r/mod/about/modqueue.

Here is an explanation of the C<mode> options from the API site:

=over

reports: Things that have been reported.

spam: Things that have been marked as spam or otherwise removed.

modqueue: Things requiring moderator review, such as reported things and items caught by the spam filter. Default.

unmoderated: Things that have yet to be approved/removed by a mod.

edited: Things that have been edited recently.

=back

C<num_reports> contains the total number of reports. Reports themselves can be found in the C<mod_reports> and C<user_reports> properties. These are arrays of arrays, i.e.

    [ [ "Spam",  3 ], [ "report #2", 1 ] ]    # user_reports
    [ [ "mod report", "moderator_name" ] ]    # mod_reports
	
The number with C<user_reports> is the number of times that particular report has been sent. This is mainly for duplicates that users have selected from the menu, for example "Spam".

=item get_modqueue

    get_modqueue ( [ subreddit => 'mod' ] )

Get the modqueue, i.e. the listing of links and comments you get by visiting /r/mod/about/modqueue. Optionally supply a subreddit. Defaults to 'mod', which is all subreddits you moderate. Identical to calling C<get_modlinks (subreddit => 'mod', mode => 'modqueue')>.

=item get_multi

    get_multi ( name => $multi_name, 
              [ user => $username, ] [ expand => 0, ] )
	
Get a hash of information about a multireddit. C<$username> defaults to your username.

If C<expand> is true, returns more detailed information about the subreddits in the multi. This can be quite a bit of information, comparable to the amount of information contained in a Subreddit object, however it's not I<exactly> the same, and if you try to create a Subreddit object out of it you'll fail.

=item get_permalink

    get_permalink ( $comment_id, $post_id )
	
Returns a permalink for C<$comment_id>. B<If you already have a Comment object, use its C<get_permalink()> function instead>. This version causes an extra request because it has to ask Reddit for the parent post's URL first, while a Comment object already has that information. It's provided for backwards compatibility, and for the rare case when you may have a comment's ID but not a comment object (perhaps you have a list of IDs stored in a database). It may be deprecated in the future.

C<$comment_id> and C<$post_id> can be either fullnames or short IDs.

=item get_refresh_token

    Reddit::Client->get_refresh_token ( $code, $redirect_uri, $client_id, $secret, $user_agent )

Get a permanent refresh token for use in "web" apps. All arguments are required*. Returns the refresh token.

This is best called in static context, just as it's written above, rather than by instantiating an RC object first. The reason is that it's completely separate from every other program flow and you only create extra work for yourself by using an existing RC object. If you choose to use an existing RC object, you'll need to create it and then call C<get_token> with your new refresh_token as a parameter. (C<client_id> and C<secret> will need to be passed in either on object creation or when calling get_token.)

C<code> is the one-time use code returned by Reddit after a user authorizes your app. For an explanation of that and C<redirect_uri>, see the token retrieval code flow: L<https://github.com/reddit-archive/reddit/wiki/OAuth2#token-retrieval-code-flow>.

=item get_subreddit_comments

    get_subreddit_comments ( [ subreddit => '', ] )

Returns a list of Comment objects from a subreddit or multi. If subreddit is omitted the account's "front page" subreddits are returned (i.e. what you see when you visit reddit.com and are logged in).

=item get_subreddit_info

    get_subreddit_info ( $subreddit )
	
Returns a hash of information about subreddit C<$subreddit>.

=item get_token

    get_token ( client_id => $client_id, secret => $secret, username => $username, password => $password )

or

    get_token ( client_id => $client_id, secret => $secret, refresh_token => $refresh_token )

or

    get_token

Get an authentication token from Reddit. Normally a user has no reason to call this function themselves. If you pass in your authentication info when creating a new Reddit::Client onject, C<get_token> will be called automatically using the information provided. Similarly, if your script runs continuously for more than an hour, a new token will be obtained automatically. C<get_token> is exposed in case you need to refresh your authorization token manually for some reason, for example if you want to switch to a different user within the same Reddit::Client instance.

If any arguments are provided, all of the appropriate arguments are required. If none are provided, it will use the information from the previous call.

=item get_user

    get_user ( user => $username, [ view => USER_OVERVIEW, ] )
			   
Get information about a user, where C<view> is one of the user L<constants|https://metacpan.org/pod/Reddit::Client#CONSTANTS>: overview, comments, submitted, gilded, upvoted, downvoted, hidden, saved, or about. Defaults to 'overview', which shows the user's most recent comments and posts.

The result will be a listing of Links or Comments or a mix of both, except in the case of the 'about' view, in which case it will be a single Account object.

=item get_wiki

    get_wiki ( sub => $subreddit, page => $page, 
             [ data => 0, ] [ v => $version, ] [ v2 => $diff_version ] )

Get the content of a wiki page. If C<data> is true, fetch the full data hash for the page. If C<v> is given, show the wiki page as it was at that version. If both C<v> and C<v2> are given, show a diff of the two.

=item get_wiki_data

    get_wiki_data ( sub => $subreddit, page => $page, 
                  [ v => $version, ] [ v2 => $diff_version ] )

Get a data hash for wiki page I<$page>. This function is the same as calling C<get_wiki> with C<data=>1>.

=item has_token

    has_token()

Return true if a valid Oauth token exists.

=item hide

    hide ( $fullname )

Hide a post.

=item ignore_reports

    ignore_reports ( $fullname )

	Ignore reports for a comment or post (moderator action).

=item info 

    info ( $fullname )

Returns a hash of information about C<$fullname>. C<$fullname> can be any of the 8 types of thing.

=item list_subreddits

    list_subreddits ( [ view => SUBREDDITS_HOME ] )

Returns a list of subreddits, where C<view> is one of the subreddit L<constants|https://metacpan.org/pod/Reddit::Client#CONSTANTS>: '' (i.e. home), 'subscriber', 'popular', 'new', 'contributor', or 'moderator'. Note that as of January 2018 some views, such as the default, are limited to 5,000 results. 'new' still gives infinite results (i.e. a list of all subreddits in existence). Others are untested.

=item mark_inbox_read

    mark_inbox_read()

Mark everything in your inbox as read. May take some time to complete.

=item me

    me()

Return an Account object that contains information about the logged in account. Aside from static account information it contains the C<has_mail> property, which will be true if there is anything in your inbox.

=item new 

    new ( user_agent => $user_agent, 
        [ client_id => $client_id, secret => $secret, username => $username, password => $password, ]
        [ print_request_errors => 0, ]  [ print_response => 0, ] [ print_request => 0, ] [ print_request_on_error => 0 ] 
        [ subdomain => 'www', ] )

or

    new ( user_agent => $user_agent, 
        [ client_id => $client_id, secret => $secret, refresh_token => $refresh_token ]
        [ print_request_errors => 0, ]  [ print_response => 0, ] [ print_request => 0, ] [ print_request_on_error => 0 ]
        [ subdomain => 'www', ] )

Instantiate a new Reddit::Client object. Optionally authenticate at the same time. (Unless you have some reason not to, this is the recommended way to do it.) For "script"-type apps, this is done by passing in a username, password, client_id and secret. For "web"-type apps, this is done by passing in a refresh_token, client_id and secret.

C<user_agent> is a string that uniquely identifies your app. The API Rules (L<https://github.com/reddit/reddit/wiki/API#rules>) say it should be "something unique and descriptive, including the target platform, a unique application identifier, a version string, and your username as contact information". It also includes this warning: "NEVER lie about your user-agent. This includes spoofing popular browsers and spoofing other bots. We will ban liars with extreme prejudice." C<user_agent> is required as of version 1.2 (before, Reddit::Client would provide one if you didn't).

Optional arguments:

=over

C<subdomain>: The subdomain in links generated by Reddit::Client (for example with C<get_web_url>). You can use this to generate links to old.reddit.com to force the old version of Reddit, for example, or new.reddit.com for the new. Default www.

C<print_response_content>: Print the content portion of Reddit's HTTP response. Default is print nothing on success and an error code on failure. The content will usually be a blob of JSON, but for certain 500 errors, it may be an entre web page.

C<print_request_errors>: If there is an error, print the content portion of Reddit's response. Not very useful as Reddit's response is usually just a text string repeating the error code.

C<print_request>: Print the I<entire> HTTP request and response for every request.

C<print_request_on_error>: If there is a request error, print the I<entire> HTTP request and response.

=back

=item remove

    remove ( $fullname )

Remove a post or comment (moderator action). Link and Comment objects also have their own C<remove> method, which doesn't require a fullname.

Note on the mechanics of Reddit: removing is different than flagging as spam, although both have the end result of hiding a thing from view of non-moderators. Flagging as spam also trains the spam filter and will cause further posts from that user to be automatically removed.
	
=item save 

    save ( $fullname )

Save a post or comment. 

=item send_message 

    send_message ( to => $username, subject => $subject, text => $message )

Send a private message to C<$username>. C<$subject> is limited to 100 characters.

=item set_post_flair

    set_post_flair ( subreddit => $subreddit, post_id => $post_id_or_fullname, flair_template_id => $flair_id )
	
Set the flair on a post. C<flair_template_id> is acquired via C<get_flair_options()>.

=item set_user_flair

    set_user_flair ( subreddit => $subreddit, username => $username, flair_template_id => $flair_id )
	
Set the flair for a user. C<flair_template_id> is acquired via C<get_flair_options()>.

=item submit_comment 

    submit_comment ( parent_id => $fullname, text => $text)

Submit a comment under C<$fullname>, which must be a post or comment. Returns fullname of the new comment.

=item submit_crosspost

    submit_crosspost ( subreddit => $subreddit, title => $title, source_id => $fullname, 
                     [ inbox_replies => 1, ] [ repost => 0, ] )

Submit a crosspost. Returns the fullname of the new post. You must be subscribed to or a moderator of the subreddit you are crossposting to, otherwise it will fail with the error message "subreddit not found". (This message seems to be an error itself, or is possibly referring to Reddit's internal logic. For example, when crossposting, maybe Reddit selects the subreddit from your list of subscribed/moderated subreddits, and "subreddit not found" means it can't be found in this list.)

C<source_id> is the id or fullname of an existing post. This function is identical to C<submit_link>, but with C<source_id> replacing C<url>.  

If C<inbox_replies> is defined and is false, disable inbox replies for that post. If C<repost> is true, the link is allowed to be a repost. (Otherwise, if it is a repost, the request will fail with the error "That link has already been submitted".) C<sub> can be used as an alias for C<subreddit>.


=item submit_link 

    submit_link ( subreddit => $subreddit, title => $title, url => $url, 
                [ inbox_replies => 1, ] [ repost => 0, ] )

Submit a link. Returns the fullname of the new post. 

If C<inbox_replies> is defined and is false, disable inbox replies for that post. If C<repost> is true, the link is allowed to be a repost. (Otherwise, if it is a repost, the request will fail with the error "That link has already been submitted".) C<sub> can be used as an alias for C<subreddit>.

=item submit_text 

    submit_text ( subreddit => $subreddit, title => $title, text => $text, 
                [ inbox_replies => 1 ] )

Submit a text post. Returns the fullname of the new post. If C<inbox_replies> is defined and is false, disable inbox replies for that post.

=item unhide 

    unhide ( $fullname )

Unhide a post.

=item unsave 

    unsave ( $fullname )

Unsave a post or comment.

=item version

    version()

Return the Reddit::Client version.

=item vote 

    vote ( $fullname, $direction )

Vote on a post or comment. C<$direction> can be 1, 0, or -1 (0 to clear votes).

=back

=head1 CONSTANTS

    DEFAULT_LIMIT           => 25

    VIEW_HOT                => ''
    VIEW_NEW                => 'new'
    VIEW_CONTROVERSIAL      => 'controversial'
    VIEW_TOP                => 'top'
    VIEW_RISING             => 'rising'
    VIEW_DEFAULT            => VIEW_HOT

    VOTE_UP                 => 1
    VOTE_DOWN               => -1
    VOTE_NONE               => 0

    SUBMIT_LINK             => 'link'
    SUBMIT_SELF             => 'self'
    SUBMIT_MESSAGE          => 'message'
    SUBMIT_CROSSPOST        => 'crosspost'

    MESSAGES_INBOX          => 'inbox'
    MESSAGES_UNREAD         => 'unread'
    MESSAGES_SENT           => 'sent'
    MESSAGES_MESSAGES       => 'messages'
    MESSAGES_COMMENTREPLIES => 'comments'
    MESSAGES_POSTREPLIES    => 'selfreply'
    MESSAGES_MENTIONS       => 'mentions'

    SUBREDDITS_HOME         => ''
    SUBREDDITS_MINE         => 'subscriber'
    SUBREDDITS_POPULAR      => 'popular'
    SUBREDDITS_NEW          => 'new'
    SUBREDDITS_CONTRIB      => 'contributor'
    SUBREDDITS_MOD          => 'moderator'

    USER_OVERVIEW           => 'overview'
    USER_COMMENTS           => 'comments'
    USER_SUBMITTED          => 'submitted'
    USER_GILDED             => 'gilded'
    USER_UPVOTED            => 'upvoted'
    USER_DOWNVOTED          => 'downvoted'
    USER_HIDDEN             => 'hidden'
    USER_SAVED              => 'saved'
    USER_ABOUT              => 'about'

=head1 AUTHOR

L<mailto:earthtone.rc@gmail.com>

=head1 LICENSE

BSD license

=cut

