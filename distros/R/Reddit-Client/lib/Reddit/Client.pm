package Reddit::Client;

our $VERSION = '1.3865'; 
# Needs doc:
# report, modmail_mute, modmail_action, Modm...->archive, sticky_post

# 1.3865 fixed bug that was showing up for testers but not for me for some reason
# it was using shift ambiguously before a ternary operator. return shift ? true : false
# 1.3863 fixed bug in get_subreddit_info that prevented some pages from working

# 1.386 2/19/21
# updated get_subreddit_info, now takes second arg for specific page
# added approve_user

# 1.385 11/23/20
# added modmail_action, ModmConv...->archive
# 1.384
# added invite_mod, arg-only version of invite_moderator
# 1.384 10/11/20 update
#   added report
#
# 1.384 9/29/20 
#	added modmail_mute
#	submit_text: field 'text' is no longer required
#   added more fields to Link

# 1.383 added sticky_post

# next big version can be when we put in the new mute
# 1.382 (should be big ver?) added friend function - no we didn't

# 1.381 changed default max request from 500 to 100
# 1.38 7/27/20 
# 	added ModmailConversation and ModmailMessage classes
#	added function new_modmail_conversation 
# 1.375 7/2/20 added sr_detail to Link
# 1.374 added nsfw option to submit_link

# 1.373 2/3/20 edit now returns the edited thing's  id
# 1.372 
# -get_link now gets its links in a proper way, by calling get_links_by_ids and
#  taking the first element
# -Link class now has many more keys; should now reflect most or all of the keys
#  Reddit returns, minus 'downs' and 'ups' because they are deprecated and can
#  cause confusion


$VERSION = eval $VERSION;

use strict;
use Carp;

use Data::Dumper   qw/Dumper/;
use JSON           qw/decode_json/;
use File::Spec     qw//;
use Digest::MD5    qw/md5_hex/;
use POSIX          qw/strftime/;
#use File::Path::Expand qw//; # Does nothing?

require Reddit::Client::Account;
require Reddit::Client::Comment;
require Reddit::Client::Link;
require Reddit::Client::SubReddit;
require Reddit::Client::Request;
require Reddit::Client::Message;
require Reddit::Client::MoreComments;
require Reddit::Client::ModmailConversation;
require Reddit::Client::ModmailMessage;

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
use constant API_FLAIR               => 42;
use constant API_DELETEFLAIR         => 43;
use constant API_UNBAN               => 44;
use constant API_DISTINGUISH         => 45;
use constant API_UNDISTINGUISH       => 46;
use constant API_LOCK                => 47;
use constant API_UNLOCK              => 48;
use constant API_MARKNSFW            => 49;
use constant API_UNMARKNSFW          => 50;
use constant API_FLAIRTEMPLATE2      => 51;
use constant API_LINKFLAIRV1         => 52;
use constant API_LINKFLAIRV2         => 53;
use constant API_USERFLAIRV1         => 54;
use constant API_USERFLAIRV2         => 55;
use constant API_NEW_MM_CONV         => 56;
use constant API_FRIEND              => 57;
use constant API_STICKY_POST         => 58;
use constant API_MM_MUTE             => 59;
use constant API_REPORT              => 60;
use constant API_MM_POST_ACTION      => 61;
use constant API_MM_GET_ACTION       => 62;
use constant API_SUBINFO             => 63;
use constant API_ABOUT               => 64;

#===============================================================================
# Parameters
#===============================================================================

our $DEBUG            = 0;
our $BASE_URL         = 'https://oauth.reddit.com';
use constant BASE_URL =>'https://oauth.reddit.com';
our $LINK_URL         = 'https://www.reddit.com'; # Why are there two of these?
use constant LINK_URL =>'https://www.reddit.com'; # both are unused now?

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
$API[API_ABOUT         ] = ['GET',  '/r/%s/about'             ];
$API[API_SUBINFO       ] = ['GET',  '/r/%s/about/%s'          ];
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
$API[API_FLAIR         ] = ['POST', '/r/%s/api/flair'         ];
$API[API_DELETEFLAIR   ] = ['POST', '/r/%s/api/deleteflair'   ];
$API[API_UNBAN         ] = ['POST', '/r/%s/api/unfriend'      ];
$API[API_DISTINGUISH   ] = ['POST', '/api/distinguish'        ];
$API[API_UNDISTINGUISH ] = ['POST', '/api/distinguish'        ];
$API[API_LOCK          ] = ['POST', '/api/lock'               ]; # fullname 
$API[API_UNLOCK        ] = ['POST', '/api/unlock'             ]; # only
$API[API_MARKNSFW      ] = ['POST', '/api/marknsfw'           ]; # these
$API[API_UNMARKNSFW    ] = ['POST', '/api/unmarknsfw'         ]; # four
$API[API_FLAIRTEMPLATE2] = ['POST', '/r/%s/api/flairtemplate_v2'];
$API[API_LINKFLAIRV1   ] = ['GET',  '/r/%s/api/link_flair'    ];
$API[API_LINKFLAIRV2   ] = ['GET',  '/r/%s/api/link_flair_v2' ];
$API[API_USERFLAIRV1   ] = ['GET',  '/r/%s/api/user_flair'    ];
$API[API_USERFLAIRV2   ] = ['GET',  '/r/%s/api/user_flair_v2' ];
# Read modmail conversation uses GET on the same endpoint
$API[API_NEW_MM_CONV   ] = ['POST', '/api/mod/conversations'  ];
$API[API_FRIEND        ] = ['PUT',  '/api/v1/me/friends/%'    ];
$API[API_STICKY_POST   ] = ['POST', '/api/set_subreddit_sticky']; 
$API[API_MM_MUTE       ] = ['POST', '/api/mod/conversations/%s/mute'];
$API[API_REPORT        ] = ['POST', '/api/report'             ];
$API[API_MM_POST_ACTION] = ['POST', '/api/mod/conversations/%s/%s'];

#POST /api/mod/conversations/:conversation_id/mute
#conversation_id                 base36 modmail conversation id

#
#


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
	# request_errors does nothing?
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

	# This breaks on endpoints that return an array like flairselect v2
    if (ref $result eq 'HASH' and exists $result->{errors}) {
        my @errors = @{$result->{errors}};

        if (@errors) {
            DEBUG("ERRORS: @errors");
            my $message = join(' | ', map { join(', ', @$_) } @errors);
            croak $message;
        }
    }
	# The fuck is this?
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

	#return $result;
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

# works section 1:
# banned, muted, wikibanned, contributors, wikicontributors, moderators, edit, log

# should work but returns undef:
# rules (uses read), traffic (uses modconfig),
#
sub get_subreddit_info {
	my $self	= shift;
	my $sub		= shift || croak 'Argument 1 (subreddit name) is required.';
	$sub = subreddit($sub);
	my $page    = shift;

	my ($api, $args);
	if ($page) {
		$api  = API_SUBINFO;
		$args = [$sub, $page];
	} else {
		$api = API_ABOUT;
		$args = [$sub];
	}

	my $result = $self->api_json_request(
		api 	=> $api,
		args	=> $args,
	);
	#return $result->{data};
	return $result;
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
	my $view      = $param{view}|| VIEW_DEFAULT;

	my $query = $self->set_listing_defaults(%param);

	$subreddit = subreddit($subreddit);

	my $args = [$view];
	unshift @$args, $subreddit if $subreddit;

#$API[API_LINKS_OTHER   ] = ['GET',  '/%s'                     ];
#$API[API_LINKS_FRONT   ] = ['GET',  '/r/%s/%s'                ];
# this is backwards? front is actually a specific sub, other is front page
	my $result = $self->api_json_request(
		api      => ($subreddit ? API_LINKS_FRONT : API_LINKS_OTHER),
		args     => $args,
		data     => $query,
	);
	#return $result;

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
	# what the fuck is this?
	my $result = $self->json_request('GET', $API[API_BY_ID][1]."/$str");

	return [
		map { Reddit::Client::Link->new($self, $_->{data}) } @{$result->{data}{children}} 
	];
}

sub get_link {
    my ($self, $fullname) = @_;
	die  "get_link: need arg 1 (id/fullname)" unless $fullname;

	$fullname = fullname($fullname, 't3');
	my $result = $self->json_request('GET', $API[API_BY_ID][1]."/$fullname");

	return Reddit::Client::Link->new($self, $result->{data}{children}[0]{data});
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
    	my $args = $subreddit ? [$subreddit] : [];

    	my $result = $self->api_json_request(
        	api      => ($subreddit ? API_COMMENTS : API_COMMENTS_FRONT),
        	args     => $args,
        	data     => $query,
    	);

		#return $result;
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
	my $fullname = shift || die "remove: arg 1 (fullname) is required.\n";
	
    	my $result = $self->api_json_request(
		api  => API_REMOVE,
		data => { id => $fullname, spam=> 'false' },
	);
	return $result;
}
# like remove, but sets spam flag
sub spam {
	my $self = shift;
	my $fullname = shift || croak "spam: arg 1 (fullname) is required.\n";
	
    	my $result = $self->api_json_request(
		api  => API_REMOVE,
		data => { id => $fullname, spam => 'true' },
	);
	return $result;
}
sub approve {
	my $self = shift;
	my $fullname = shift || die "approve: arg 1 (fullname) is required.\n";
	
    	my $result = $self->api_json_request(
		api  => API_APPROVE,
		data => { id => $fullname },
	);
	return $result;
}
sub ignore_reports {
	my $self = shift;
	my $fullname = shift || die "ignore_reports: arg 1 (fullname) is required.\n";
	
	my $result = $self->api_json_request(
		api  => API_IGNORE_REPORTS,
		data => { id => $fullname },
	);
	return $result;
}
sub lock {
	my ($self, $fullname, %param) = @_;
	die "lock: arg 1 (fullname) is required.\n" unless $fullname;

	if (!ispost($fullname) and !iscomment($fullname)) {
		die "lock: arg 1 must be a fullname of a post or comment.\n";
	}

	my $lock = exists $param{lock} ? $param{lock} : 1;

	my $result = $self->api_json_request(
		api	 => $lock ? API_LOCK : API_UNLOCK,
		data => { id => $fullname },
	);
	return $result;
}
sub unlock {
	my ($self, $fullname, %param) = @_;
	
	return $self->lock($fullname, lock=>0);
}
sub nsfw {
	my ($self, $fullname, %param) = @_;
	die "nsfw: arg 1 (fullname) is required.\n" unless $fullname;

	if (!ispost($fullname)) {
		die "nsfw: arg 1 must be a fullname of a post or comment.\n";
	}

	my $nsfw = exists $param{nsfw} ? $param{nsfw} : 1;

	my $result = $self->api_json_request(
		api	 => $nsfw ? API_MARKNSFW : API_UNMARKNSFW,
		data => { id => $fullname },
	);
	return $result;
}
sub unnsfw {
	my ($self, $fullname, %param) = @_;
	
	return $self->nsfw($fullname, nsfw=>0);
}
# -ban is really a call to friend, which creates relationships between accounts.
# other functions can call it and pass in a different mode (see functions below)
# this is to make it just as unreadable as Reddit's endpoint
# TODO: make this a general fn, call ban from outside like modinvite is
#
# -ban uses the "modcontributors" oauth scope EXCEPT:
#   -moderator and moderator_invite use "modothers"
#   -wikibanned and wikicontributor require both modcontributors and modwiki
# https://old.reddit.com/dev/api/#POST_api_friend
#
sub ban {
	my ($self, %param) = @_;
	my $sub	= $param{sub} || $param{subreddit} || die "subreddit is required\n";
	
	my $data = {}; 
	$data->{name} = $param{user} || $param{username} || die "username is required\n";
	# ban_context = fullname (of what?) - not required

	# Ban message
	$data->{ban_message} = $param{ban_message} if $param{ban_message};
	# Reason: short report reason
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

	if ($param{duration}){ # if 0 this never even hits which we want anyway
		if ($param{duration} > 999) {
			print "Warning: Max duration is 999. Setting to 999.\n";
			$param{duration} = 999;
		} elsif ($param{duration} < 1) {
			$param{duration} = 0;
		}
		$data->{duration} = $param{duration} if $param{duration};
	}
	# $data->{container} is not needed unless mode is friend or enemy
	# from docs for unfriend https://old.reddit.com/dev/api/#POST_api_unfriend:
	# The user can either be passed in by name (nuser) or by fullname (iuser). If type is friend or enemy, 'container' MUST be the current user's fullname; for other types, the subreddit must be set via URL (e.g., /r/funny/api/unfriend)
	# So what would the arg be? /r/<sub>/api/friend?
	# Unfriend has its own endpoint too
	# $data->{permissions} = ?

	# type is one of (friend, moderator, moderator_invite, contributor, banned, muted, wikibanned, wikicontributor)
	if ($param{mode} eq 'mute') {
		$data->{type} = 'muted';
	} elsif ($param{mode} eq 'contributor') {
		$data->{type} = 'contributor';
	} elsif ($param{mode} eq 'moderator_invite') {
		#print "modinvite\n";
		$data->{type} = 'moderator_invite';
	} else {
		$data->{type} = 'banned';
	}

	my $result = $self->api_json_request(
		api  => API_BAN, 
		args => [$sub],
		data => $data,
	);
	return $result;
}

sub mute {
	my ($self, %param) = @_;
	$param{mode} = 'mute';
	return $self->ban(%param);
}

sub add_approved_user {
	my ($self, %param) = @_;
	$param{mode} = 'contributor';
	return $self->ban(%param);
}
# more sensible version of add_approved_user
sub approve_user {
	my ($self, $user, $sub) = @_;
	my %param;
	$param{username} = $user || die "approve_user: arg 1 (username) is required.\n";
	$param{subreddit} = $sub || die "approve_user: arg 2 (sub) is required.\n";
	$param{mode} = 'contributor';
	return $self->ban(%param);
}
# Requires scope 'modothers'
sub invite_moderator {
	my ($self, %param) = @_;
	$param{mode} = 'moderator_invite';
	return $self->ban(%param);
}
# so we already had a function to do this and we wrote another one
sub invite_mod {
	my ($this, $sub, $user) = @_;

	return $this->ban( # excellent naming of that function, bravo
		user	=> $user,
		sub		=> $sub,
		mode	=> 'moderator_invite',
	);
}

sub unban {
	my ($self, %param) = @_;
	my $sub	= $param{sub} || $param{subreddit} || die "subreddit is required\n";
	
	my $data = {}; 
	$data->{name}	= $param{username} || die "username is required\n";
	# ban_context = fullname, but of what - not required

	if ($param{mode} eq 'mute') {
		$data->{type} = 'muted';
	} else {
		$data->{type} = 'banned';
	}

	my $result = $self->api_json_request(
		api  => API_UNBAN, 
		args => [$sub],
		data => $data,
	);
	return $result;
}

sub unmute {
	my ($self, %param) = @_;
	$param{mode} = 'mute';
	return $self->unban(%param);
}

sub distinguish {
	my ($self, $fullname, %param) = @_;
	my $data = {};

	if (!iscomment($fullname) and !ispost($fullname)) {
		die 'Fullname is required (comment preceeded by "t1_", post "t3_")';
	}

	if (iscomment($fullname)) {
		# only top level can be sticky
		my $sticky = exists $param{sticky} ? $param{sticky} : 0;
		$data->{sticky} = $sticky ? 'true' : 'false';
	}

	$data->{id} = $fullname;


	$data->{how} = 'yes';
	# Check manual setting of 'how'. Normal users should never set 'how'.
	if ($param{how}) {
		my @valid = qw/yes no admin special/;
		my $ok;
		for (@valid) {
			if ($param{how} eq $_) {
				$ok = 1;
				last; # because we have to save potentially TWO CYCLES, right asshole? yeah spend all day on 2 cycles, that's a good use of your time
			}
		}

		die "valid values for 'how' are: yes, no, admin, special\n" unless $ok;
	}
	
	my $result = $self->api_json_request(
		api  => API_DISTINGUISH, 
		data => $data,
	);
	return $result;
}

sub undistinguish {
	my ($self, $fullname, %param) = @_;
	my $data = {};

	if (!iscomment($fullname) and !ispost($fullname)) {
		die 'Fullname is required (comment preceeded by "t1_", post "t3_")';
	}

	$data->{id} = $fullname;
	$data->{how} = 'no';

	my $result = $self->api_json_request(
		api  => API_UNDISTINGUISH, 
		data => $data,
	);
	return $result;
}

# https://old.reddit.com/dev/api/#POST_api_report
# Send a report. Don't know what most of these fields do. made them all optional
sub report {
	my ($this, %param) = @_;

	# Nearly all optional until we know what they do lol
	my $data = {};
	# is sub required, tho? Not for a sitewide report
	# required here so we don't accidentally send a sitewide report
	$data->{custom_text} 	= $param{custom_text} if $param{custom_text};
	$data->{from_help_desk} = bool($param{from_help_desk}) if exists $param{from_help_desk};
	$data->{from_modmail} 	= bool($param{from_modmail}) if exists $param{from_modmail};

	$data->{modmail_conv_id}= $param{modmail_conv_id} if $param{modmail_conv_id};
	$data->{other_reason} 	= $param{other_reason} if $param{other_reason};
	$data->{reason} 		= $param{reason} if $param{reason};
	$data->{rule_reason} 	= $param{rule_reason} if $param{rule_reason};
	$data->{site_reason} 	= $param{site_reason} if $param{site_reason};
	#$data->{sr_name} 		= $param{sub} || $param{subreddit} || croak "sub or subreddit is required."; # API says sr_name can be 1000 characters?
	$data->{sr_name} 		= $param{sub}||$param{subreddit} if $param{sub}||$param{subreddit}; 
	my $id 					= $param{id}||$param{fullname} || croak "fullname (alias id) is required";
	croak "fullname (alias id) must be a fullname" unless $id =~ /^t[0-9]_/;
	$data->{thing_id}		= $id;
	
	#$data->{strict_freeform_reports} = bool($param{strict_freeform_reports}) if exists $param{strict_freeform_reports};
	$data->{strict_freeform_reports} = "true"; # see docs
	$data->{usernames} 		= $param{usernames} if $param{usernames}; # a comma-delimited list

	return $this->api_json_request(
		api  => API_REPORT, 
		data => $data,
	);
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

# Get new modmail. This returns metadata and the first message for each conver-
# sation. Full conversations must be loaded separately with get_conversation

# after: conversation id
# entity: comma-delimited list of subreddit names
# limit
# sort: one of (recent, mod, user, unread)
# state: one of (new, inprogress, mod, notifications, archived, highlighted, all

# Returns: 
#  conversationIds, array of conversation IDs
#  conversations, hash of data about the conversation, keys are conversation IDs
#   -subject
#   -numMessages
#   -state - corresponds to state arg?
#   -authors, array of hashes of information about each author
#   -participant, hash of info about the user from the top message?
#   -owner, hash of info about the sub
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

# GET /api/mod/conversations/:conversation_id
#   Returns all messages, mod actions and conversation metadata for id
#     conversation_id   base36 modmail conversation id
#     markRead          boolean

sub get_conversation {
	my ($this, $id, %param) = @_;

}

# "This endpoint will create a ModmailConversation object as well as the first ModmailMessage within the ModmailConversation object."
sub new_modmail_conversation {
	my ($this, %param) = @_;
	my $data = {};

	$data->{body} = $param{body} || croak "new_modmail_conversation: body is required.";
	# Unlike Reddit's functionality, this hides the author name by default
	my $auth = exists $param{isAuthorHidden} ? $param{isAuthorHidden} : 
			 ( exists $param{hide_author} ? $param{hide_author} : 1 );
	#$data->{isAuthorHidden} = exists $param{isAuthorHidden} ? ( $param{isAuthorHidden} ? "true" : "false" ) : "true"; 
	$data->{isAuthorHidden} = $auth ? "true" : "false"; 
	$data->{srName}  = $param{subreddit} || $param{sub} || $param{srName} || croak "new_modmail_conversation: subreddit is required (also accepts aliases 'sub' and 'srName')";
	my $subj = $param{subject} || croak "new_modmail_conversation: subject is required";
	if (length $subj > 100) {
		print "new_modmail_conversation: subject truncated to 100 characters.\n";
		$subj = substr $subj, 0, 100;
	}
	$data->{subject} = $subj;

	# users only or can subreddit be target?
	$data->{to} = $param{to} || croak "new_modmail_conversation: fullname is required.";
	#$fullname = fullname 
	# body, isAuthorHidden, srName, subject=100 chars, to=fullname
	# documentation is WRONG. to is not a fullname, it's just a username
	my $result = $this->api_json_request(
		api	 => API_NEW_MM_CONV,
		data => $data, 
	);
	if (ref $result eq 'HASH') {
		return new Reddit::Client::ModmailConversation($this, $result->{conversation}, $result->{messages}, $result->{modActions});
	}
	return $result;
}

sub sticky_post {
	my ($this, $id, %opt) = @_;
	my $data = {};
	# docs say id but maybe they mean fullname
	$id = fullname($id, 't3') || die "sticky_post: arg 1 (id) is required.\n";
	$data->{id} = $id;

	if ($opt{num}) {
		if ($opt{num} =~ /^[1234]$/) {
			$data->{num} = $opt{num};
		} else {
			print "sticky_post: option 'num' must be an integer from 1-4. Unsetting.\n";
		}
	}
	
	$data->{state} = exists $opt{sticky} ? ($opt{sticky} ? "true" : "false") : "true";
	$data->{to_profile} = exists $opt{to_profile} ? ($opt{to_profile} ? "true" : "false") : "false";

	return $this->api_json_request(
		api	 => API_STICKY_POST,
		data => $data, 
	);

}

#=============================================================
# New modmail functions
# most use the same URL format so we should make a central function

# Sub for many modmail actions
# these actions take no args, just the action
# TODO: call these from ModmailConversation
sub modmail_action {
	my ($this, $action, $id) = @_;
	croak "args 1 and 2 (action and id) are required" unless $action and $id;
	$action = lc $action;

	# Choose MM_POST_ACTION or MM_GET_ACTION
	# POST: bulk_read, approve (?), archive, disapprove (?), highlight,
	# unarchive, unban, unmute

	# POST: read and unread take single arg

	# POST: mute takes hours, has own function
	# POST: temp_ban takes duration, support elsehwere

	# only hightlight uses DELETE, not supporting
	my @post_actions = qw/bulk_read approve archive disapprove highlight unarchive unban unmute /;
	my $api;
	for (@post_actions) {
		if ($action eq $_) { 
			$api = API_MM_POST_ACTION;
 			last; 
		}
	}
	croak "'$action' is not a recognized action. only POST actions are implemented at this time." unless $api;


	return $this->api_json_request(
		api	 => $api,
		args => [$id, $action],
	);
}


# num_hours                               one of (72, 168, 672)
sub modmail_mute {
	my ($this, $id, $length) = @_;
	$length ||= 72;

	# We should accept days too
	if ($length == 3 or $length == 7 or $length == 28) {
		$length *= 24;
	} elsif ($length != 72 and $length != 168 and $length != 672) {
		die "arg 2 (length) must be 3, 7, or 28 days (or 72, 168, or 672 hours)\n";
	} 

	my $data = { num_hours => $length };
	my $args = [ $id ];

	return $this->api_json_request(
		api	 => API_MM_MUTE,
		args => $args,
		data => $data, 
	);
}

#=============================================================
# Users
#=============================================================
sub get_user { 
	#my ($self, %param) = @_;
	#$user	= $param{user} || $param{username} || croak "expected 'user'";
	#$view	= $param{view} || 'overview';
	my $self = shift;
	my ($user, $view, %param);

	# old ver: user=>$user, view=>$view
	# what if someone passes in another key?
	# this fails with unpredictable results lol

	# even elements = old way, odd = new way
	my $odd = scalar(@_) % 2;
	if (!$odd or $_[0] eq 'user' or $_[0] eq 'username' or $_[0] eq 'view') {
		print "This form of get_user is deprecated. A future version will take the following simplified argument structure: get_user(\$username, \%params)\n";
		%param = @_;
		$user  = $param{user} || $param{username} || croak "expected 'user'";
	} else {
	# new ver: $user, %params
		$user = shift;
		%param= @_;
	}

	$view	= $param{view} || 'overview';

	# This can accept limit as data? are all GET string args sent as data?
	my $data = $self->set_listing_defaults(%param);

    my $args = [$user, $view];

	# $API[API_USER          ] = ['GET',  '/user/%s/%s'             ];
	# view is different here; would need third arg, 'sort=new' 
	# /user/TheUser/submitted?sort=new
	my $result = $self->api_json_request(
		api      => API_USER,
		args     => $args,
		data     => $data,
	);

	if ($view eq 'about') {
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
	return $result->{data}{things}[0]{data}{name};
}

sub delete {
    	my ($self, $name) = @_;
    	croak 'Expected $fullname' if !$name;
    	my $type = substr $name, 0, 2;
    	croak '$fullname must be a post or comment' if $type ne 't1' && $type ne 't3';

    	DEBUG('Delete post/comment %s', $name);

    	my $result = $self->api_json_request(api => API_DEL, data => { id => $name });
    	return $result;
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
    my $replies   = exists $param{inbox_replies} ? ($param{inbox_replies} ? "true" : "false") : "true";
    my $repost    = exists $param{repost} ? ($param{repost} ? "true" : "false") : "false";
	my $nsfw      = exists $param{nsfw} ? ($param{nsfw} ? "true" : "false") : "false";

    DEBUG('Submit link to %s: %s', $subreddit, $title, $url);

    $subreddit = subreddit($subreddit);

    my $result = $self->api_json_request(api => API_SUBMIT, data => {
        title       => $title,
        url         => $url,
        sr          => $subreddit,
        kind        => SUBMIT_LINK,
		sendreplies => $replies,
		resubmit    => $repost,
		nsfw		=> $nsfw,
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
    my $text      = $param{text}      || "";#croak 'Expected "text"';
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
# These could go in the user section or here, but it seems like it will be
# more commonly used for flairing posts
sub template {
   	my ($self, %param) = @_;
	my $data = {}; # POST data
	my $url_arg;   # arguments that get interpolated into the URL
	
	my $result = $self->api_json_request(
		api		=> API_FLAIR,
		args	=> [$url_arg],
		data	=> $data
	);
}

# flair a post, not using an existing template, just manually providing the
# text and CSS class 
sub flair_post {
   	my ($self, %param) = @_;
	my $link_fullname = $param{link_id} || $param{post_id} || die "flair_post: need 'link_id'\n";
	$link_fullname = fullname($link_fullname, 't3');
	my $subreddit = $param{sub} || $param{subreddit} || die "flair_post: need 'subreddit'\n";
	# Initializing $text to '' here was accidentally preventing a concatenation
	# warning from Request
	my $text = $param{text} ? substr($param{text}, 0, 64) : '';
	my $css_class = $param{css_class}; # optional

	my $data = { link => $link_fullname };
	$data->{text} = $text if $text;
	$data->{css_class} = $css_class if $css_class;

	my $result = $self->api_json_request(
		api		=> API_FLAIR,
		args	=> [$subreddit],
		data	=> $data
	);
}
sub flair_link {
   	my ($self, %param) = @_;
	return $self->flair_post(%param);
}

# flair a user, not using an existing template, just manually providing the
# text and CSS class 
sub flair_user {
   	my ($self, %param) = @_;
	my $username = $param{username} || die "flair_user: need 'link_id'\n";
	my $text = $param{text} ? substr($param{text}, 0, 64) : '';
	my $css_class = $param{css_class}; #optional
	my $subreddit = $param{sub} || $param{subreddit} || die "flair_user: need 'subreddit'\n";

	my $data = { name => $username };
	$data->{text} = $text if $text;
	$data->{css_class} = $css_class if $css_class;

	my $result = $self->api_json_request(
		api		=> API_FLAIR,
		args	=> [$subreddit],
		data	=> $data
	);

}

sub set_post_flair { # select_flair alias
#sub select_flair {
    my ($self, %param) = @_;
	#return $self->set_post_flair(%param);
	return $self->select_flair(%param);
}
# select_flair can apply flair which appears styled in multi views (such as
# r/all, your homepage, and both kinds of multis).
# Flair applied through other methods has no style in multi views.
#								view sub newred | sub oldred | multi view
#	Apply manually new reddit				x						x
#	API										x						x
#	Automod applies							x			x!			x
#
# -New reddit and multis always ignore CSS class
# -Old reddit will have the new style IF it is applied by Automod and IF it has
# no css_class. Otherwise it uses old styles like usual.
#	-If a css_class is added by any means, old reddit will lose new styles.
#   -If you alter the flair in any way through either the old or new interface,
#    old reddit will lose the new style. 
#   -If text is altered with flair_link, old reddit will lose new styles.
# - Multi view (same as r/all view) seems to show whatever new reddit does.
# - text_color and background_color seem to have no effect on anything.
#
# Flair will use values from the flair selection as defaults. Some can only be
# set through the new interface or the API.
#
# It looks like flair templates with a background_color attempt to hard code the
# background color - that is, they use style="" tags. There is no way to do this
# with old reddit, only API and new. The override_css option in /r/api/flairtemplate2 may be related. 
#sub set_post_flair { # select_flair alias
sub select_flair {
   	my ($self, %param) = @_;
	my $errmsg  = "select_flair: 'subreddit' and 'flair_template_id' (or alias 'flair_id') are required.\n";
	my $sub 	= $param{sub} || $param{subreddit} || die $errmsg;
	my $flairid	= $param{flair_template_id} || $param{flair_id} || die $errmsg;
	my $post_id	= $param{link_id} || $param{post_id};

	# This doesn't use LINK_FLAIR or USER_FLAIR, it watches for link id or usern
	if (!$post_id and !$param{username}) {
		die "select_flair: either 'link_id' or 'username' is required.\n";
	} elsif ($post_id) {
		$post_id = fullname($post_id, 't3');
	}

	my $textcol = $param{text_color};
	# putting an actual color here will be a common mistake
	if ($textcol) {
		$textcol = lc $textcol;
		if ($textcol ne 'light' and $textcol ne 'dark') {
			die "select_flair: if provided, text_color must be 'light' or 'dark'.\n";
		}
	}

	my $data	= {};

	$data->{background_color} = $param{background_color} if $param{background_color};
	$data->{css_class} = $param{css_class} if $param{css_class};
	$data->{flair_template_id} = $flairid;
	$data->{link} = $post_id if $post_id;
	$data->{name} = $param{username} if $param{username};
	$data->{return_rtjson} = $param{return_rtjson} if $param{return_rtjson};
	$data->{text_color} = $textcol if $textcol;
	# if given empty string Reddit ignores the parameter-- i.e. you can't do 
	# tricks like invisibly flair something, like you could with v1
	# Also passing undef here gives a concatenation error in Request
	$data->{text} = $param{text} || '';

	my $result = $self->api_json_request(
		api 	=> API_SELECTFLAIR,
		args 	=> [$sub],
		data	=> $data
	);

	return $result;
}
sub select_user_flair {
    my ($self, %param) = @_;
	return $self->set_user_flair(%param);
}
sub set_user_flair {
	my $errmsg  = "select_user_flair: keys 'subreddit', 'username', and 'flair_template_id' (or alias 'flair_id') are required.\n";
    	my ($self, %param) = @_;
	my $sub 	= $param{subreddit} || die $errmsg;
	my $user 	= $param{username} || die $errmsg;
	my $flairid	= $param{flair_template_id} || $param{flair_id} || die $errmsg;
	my $data	= {};

	$data->{name} = $user;
	$data->{flair_template_id} = $flairid;

	my $result = $self->api_json_request(
		api 	=> API_SELECTFLAIR,
		args 	=> [$sub],
		data	=> $data
	);

	return $result;
}

# Return a hash reference with keys 'choices' and 'current'
# 'choices' is array of hashes with flair options
# 'current' is the post's current flair
sub get_flair_options {
   	my ($self, %param) = @_;
	my $sub 	= $param{sub} || $param{subreddit} || die "get_flair_options: 'subreddit' (or alias 'sub') is required.\n";
	my $post_id = $param{link_id} || $param{post_id};
	my $user	= $param{username};
	my $data	= {};

	if ($post_id) {
		$post_id = fullname($post_id, 't3');
		$data->{link} = $post_id;
	} elsif ($user) {
		$data->{user} = $user;
	} else {
		die "get_flair_options: Need 'post_id' or 'username'";
	}

	my $result = $self->api_json_request(
		api 	=> API_FLAIROPTS,
		args 	=> [$sub],
		data	=> $data,
	);

	# What's this? Fixing the booleans?
	if ($result->{choices}) {
		for (my $i=0; $result->{choices}[$i]; $i++) {
			$result->{choices}[$i]->{flair_text_editable} = $result->{choices}[$i]->{flair_text_editable} ? 1 : 0;

		}
	}

	return $result;
}
sub get_link_flair_options { # v2: default now
	my $self = shift;
	my $sub  = shift || die "get_link_flair_options: Need arg 1 (subreddit)\n";

	my $result = $self->api_json_request(
		api 	=> API_LINKFLAIRV2,
		args 	=> [$sub],
	);
	return $result;
}
sub get_link_flair_options_v1 { # v1
	my $self = shift;
	my $sub  = shift || die "get_link_flair_options: Need arg 1 (subreddit)\n";

	my $result = $self->api_json_request(
		api 	=> API_LINKFLAIRV1,
		args 	=> [$sub],
	);
	return $result;
}
sub get_user_flair_options { # v2: default now
	my $self = shift;
	my $sub  = shift || die "get_link_flair_options: Need arg 1 (subreddit)\n";

	my $result = $self->api_json_request(
		api 	=> API_USERFLAIRV2,
		args 	=> [$sub],
	);
	return $result;
}
sub get_user_flair_options_v1 { # v1
	my $self = shift;
	my $sub  = shift || die "get_link_flair_options: Need arg 1 (subreddit)\n";

	my $result = $self->api_json_request(
		api 	=> API_USERFLAIRV1,
		args 	=> [$sub],
	);
	return $result;
}
# uses flairtemplate_v2 endpoint, which is for new but works for old
sub flairtemplate {
   	my ($self, %param) = @_;
	my $sub 	= $param{sub} || $param{subreddit} || die "flairtemplate: 'subreddit' (or alias 'sub') is required.\n";
	my $bg 		= $param{background_color} if $param{background_color};
	my $flairid	= $param{flair_template_id} || $param{flair_id} || $param{id} || undef;
	#my $type 	= $param{flair_type} || die $err;
	my $modonly = exists $param{mod_only} ? ($param{mod_only} ? 'true' : 'false') : 'false';
	my $editable= exists $param{text_editable} ? ($param{text_editable} ? 'true' : 'false') : 'false';
	my $textcol = $param{text_color};
	# putting an actual color here will be a common mistake
	if ($textcol) {
		$textcol = lc $textcol;
		if ($textcol ne 'light' and $textcol ne 'dark') {
			die "flairtemplate: if provided, text_color must be one of (light, dark).\n";
		}
	}
	# override_css is undocumented and not returned by get_link_flair_options
	# $override is unused here as yet
	#my $override= exists $param{override_css} ? ($param{override_css}   ? 'true' : 'false') : 'false'; 

	if ($bg and substr($bg, 0, 1) ne '#') { $bg = "#$bg"; } #requires hash

	my $data = {};
	$data->{allowable_content} = $param{allowable_content} if $param{allowable_content};
	$data->{background_color} = $bg if $bg;
	$data->{css_class} = $param{css_class} if $param{css_class};
	$data->{max_emojis} = $param{max_emojis} if $param{max_emojis};
	# No documentation; presumably required for editing
	$data->{flair_template_id} = $flairid if $flairid;
	# api defaults to USER_FLAIR, we default to LINK_FLAIR
	$data->{flair_type} = $param{flair_type} || 'LINK_FLAIR';
	$data->{mod_only} = $modonly if exists $param{mod_only};
	# No documentation. Probably wants "true or "false".
	$data->{override_css} = $param{override_css} if $param{override_css};
	$data->{text} = $param{text} if $param{text};
	$data->{text_color} = $textcol if $textcol;
	$data->{text_editable} = $editable if exists $param{text_editable};

	my $result = $self->api_json_request(
		api 	=> API_FLAIRTEMPLATE2,
		args 	=> [$sub],
		data	=> $data,
	);
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

    croak '$fullname must be a post or comment' if !ispost($parent_id) && !iscomment($parent_id);
    DEBUG('Submit comment under %s', $parent_id);

    my $result = $self->api_json_request(api => API_COMMENT, data => {
        thing_id => $parent_id,
        text     => $comment,
		#sendreplies=>$replies,
    });

    return $result->{data}{things}[0]{data}{name};
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
    croak '$fullname must be a post or comment' if !ispost($name) && !iscomment($name);
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
    croak '$fullname must be a post or comment' if !ispost($name) && !iscomment($name);
    DEBUG('Save %s', $name);
    $self->api_json_request(api => API_SAVE, data => { id => $name });
}

sub unsave {
    my $self = shift;
    my $name = shift || croak 'Expected $fullname';
    croak '$fullname must be a post or comment' if !ispost($name) && !iscomment($name);
    DEBUG('Unsave %s', $name);
    $self->api_json_request(api => API_UNSAVE, data => { id => $name });
}

sub hide {
    my $self = shift;
    my $name = shift || croak 'Expected $fullname';
    croak '$fullname must be a post' if !ispost($name);
    DEBUG('Hide %s', $name);
    $self->api_json_request(api => API_HIDE, data => { id => $name });
}

sub unhide {
    my $self = shift;
    my $name = shift || croak 'Expected $fullname';
    croak '$fullname must be a post' if !ispost($name);
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
		#print Dumper($model->{subreddits});
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
	$id 	=~ s/^t\d_//;
	return $id;
}
# accept id or fullname, always return fullname
sub fullname {
	my $id 		= shift || return;
	my $type	= shift || die "fullname: 'type' is required";
	$id = $type."_".$id if substr($id, 0, 3) ne $type."_";
	return $id;
}
sub bool {
	return $_[0] ? "true" : "false";
}
sub ispost { 
	my $name = shift;
    my $type = substr $name, 0, 2;
	return $type eq 't3';
}
sub iscomment {
	my $name = shift;
    my $type = substr($name, 0, 2);
	return $type eq 't1';
}
sub get_type { 
	my $name = shift;
    return lc substr($name, 0, 2) if $name;
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

# Remember that this returns a new hash and any key not from here will be
# wiped out
sub set_listing_defaults {
   	my ($self, %param) = @_;
	my $query = {};
   	$query->{before} = $param{before} if $param{before};
   	$query->{after}  = $param{after}  if $param{after};
	$query->{only}   = $param{only}   if $param{only};
	$query->{count}  = $param{count}  if $param{count};
	$query->{show}	 = 'all' 	      if $param{show} or $param{show_all};
	$query->{sort}   = $param{sort}   if $param{sort};
	$query->{sr_detail} = 'true' 	  if $param{sr_detail};
																#  500?
   	if (exists $param{limit}) { $query->{limit} = $param{limit} || 100; }
	else                      { $query->{limit} = DEFAULT_LIMIT;        }
	
	return $query;
}

1;

__END__

=pod

=head1 NAME

Reddit::Client - A Perl wrapper for the Reddit API.

=head1 DESCRIPTION

Reddit::Client handles Oauth session management and HTTP communication with Reddit's external API. For more information about the Reddit API, see L<https://github.com/reddit/reddit/wiki/API>. 

=head1 EXAMPLE

    use Reddit::Client;
    
    # Create a Reddit::Client object and authorize: "script"-type app
    my $reddit = new Reddit::Client(
        user_agent  => "Test script 1.0 by /u/myusername",
        client_id   => "client_id_string",
        secret      => "secret_string",
        username    => "reddit_username",
        password    => "reddit_password",
    );
    
    # Create a Reddit::Client object and authorize: "web"-type app
    # Authorization can also be done separately with get_token()
    my $reddit = new Reddit::Client(
        user_agent    => "Test script 1.0 by /u/myusername",
        client_id     => "client_id_string",
        secret        => "secret_string",
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
    
    for my $post (@$posts) {
        print $post->{is_self} ? $post->{selftext} : $post->{url};
        print $post->get_web_url();

        if ($post->{title} =~ /some phrase/) {
            $post->reply("hi, I'm a bot, oops I'm banned already, harsh");
        }
    }

=head1 OAUTH

Reddit::Client uses Oauth to communicate with Reddit. To get Oauth keys, visit your apps page on Reddit, located at L<https://www.reddit.com/prefs/apps>, and create an app. There are three types of apps available. Reddit::Client supports "script" and "web" type apps.

=over

=item Script apps

Most new users will want a "script"-type app. This is an app intended for personal use that uses a username and password to authenticate. The I<description> and I<about url> fields can be empty, and the I<redirect URI> can be any valid URL (script apps don't use them). Once created, you can give other users permission to use it by adding them in the "add developer" field. Each account uses its own username and password to authenticate.

Use the app's client id and secret along with your username and password to create a L<new|https://metacpan.org/pod/Reddit::Client#new> Reddit::Client object.

=item Web apps

As of v1.20, Reddit::Client also supports "web"-type apps. These are apps that can take actions on behalf of any user that grants them permission. (They use the familiar "ThisRedditApp wants your permission to..." screen.)

While they are fully supported, there is not yet a setup guide, so getting one running is left as an exercise for the reader. You will need a web server, which you will use to direct users to Reddit's authorization page, where the user will be asked to grant the app permissions. Reddit's authorization page will then redirect the user back to the app's redirect URI. This process generates a refresh token, which is a unique string that your app will use to authenticate instead of a username and password. You will probably want to store refresh tokens locally, otherwise you will have to get permission from the user every time the app runs.

Documentation for the web app flow can be found at L<https://github.com/reddit-archive/reddit/wiki/OAuth2>.

=back

=head1 V1 vs. V2

v1 is "old" Reddit (the one you see if you use the subdomain old.reddit.com), v2 new (the one you see with new.reddit.com). Reddit's API has some endpoints that are for one or the other. This guide has labeled most of the v2 functions as such, but some may be missing. (Both labels and functions. Or rather: some functions are definitely missing, and some labels I<may> be missing.)

When in doubt, use v2. It's usually the same as v1 but with more options, like flair, which can have extra colors and styles in New Reddit.

=head1 TERMINOLOGY

Reddit's API is slightly inconsistent in its naming. To avoid confusion, this guide will always use the following terms in the following ways:

=over

=item id

A thing's short ID without prefix. Example: 3npkj4. Seen in your address bar when viewing, for example, a post or comment. 

=item fullname

A thing's complete ID with prefix. Example: t1_3npkj4. When Reddit returns data, the fullname is usually found in the "name" field. The type of thing can be determined by the prefix; for example, t1 for comments and t3 for links.

=back

=head1 LISTINGS

Lists of things returned by the Reddit API are called I<listings>. Endpoints that return listings accept several optional parameters:

=over

C<limit>: Integer. How many things to return. Default 25, maximum 100. If I<limit> is 0, this is interpreted as "no limit" and the maximum is returned.

C<after>: Fullname. Return results that occur after I<fullname> in the listing.

C<before>: Fullname. Return results that occur before I<fullname> in the listing. 

C<only>: The string "links" or "comments". Return only links or only comments. (Obviously only relevant to listings that could contain both.)

C<show_all>: Boolean. Return items that would have been omitted, for example posts you have hidden, or have reported, or are hidden from you because you are using the option to hide posts after you've upvoted/downvoted them. Default false.

C<count>: Integer. Appears to be used by the Reddit website to number listings after the first page. Listings returned by the API are not numbered, so it does not seem to have a use in the API.

=back

Note that 'before' and 'after' mean before and after I<in the listing>, not necessarily in time. It's best to think of Reddit as a database where new lines are constantly inserted at the top, because that's basically what it is.

=head1 MISC

Most functions that take the parameter C<subreddit> also accept the alias C<sub>, likewise for C<username> and C<user>.

Optional arguments are indicated by a hard-coded default value:

    function ( $required, $optional = 'default_value' )

Most methods accept options as a hash, after normal arguments (and sometimes replacing them). These may be provided as an actual hash, or with C<key =<gt> value> shorthand.
    
    function ( $required, %options ) # as an actual hash
    function ( $required, option2 => 'default_value' ) # with hash shorthand

Required options are indicated as a scalar. 

    function ( option1 => $is_required, option2 => 'is_optional' )

=head1 METHODS

=over

=item approve

    approve ( $fullname )

Approve a comment or post (moderator action).

=item approve_user

    approve_user ( $username, $subreddit )

Add an approved user to a subreddit (moderator action). Replaces deprecated function add_approved_user.

=item ban

    ban ( username => $username, subreddit => $subreddit,
          duration => 0, ban_message => undef, reason => undef, note => undef )

Ban a user from a subreddit. C<username> and C<subreddit> are required. Optional arguments:

=over

C<duration>: Duration in days. Range 1-999. If false or not provided, the ban is indefinite.

C<ban_message>: The message sent to the banned user. Markdown is allowed.

C<reason>: A short ban reason, 100 characters max. On the website ban page, this in equivalent to the ban reason you would select from the dropdown menu. (For example, "Spam".) It is arbitrary: it doesn't have to match up with the reasons from the menu and can be blank. Only visible to moderators.

C<note>: An optional note, 300 characters max. Only visible to moderators. Will be concatenated to the `reason` on the subreddit's ban page. 

=back

A ban will overwrite any existing ban for that user. For example, to change the duration, you can call C<ban()> again with a new duration.

=item comment

    comment ( $fullname, $text )
	
Make a comment under C<$fullname>, which must be a post or a comment. Return the fullname of the new comment.
	
=item create_multi

    create_multi ( name => $multi_name, 
                   description => undef, visibility => 'private', subreddits => [ ],
                   icon_name => undef, key_color => 'CEE3F8', weighting_scheme => undef, 
                   username => undef )

Create a multireddit. The only required argument is the name. A multi can also be created with C<edit_multi>, the only difference being that C<create_multi> will fail with a HTTP 409 error if a multi with that name already exists. As of March 2019, trying to add a banned sub to a multi will fail with a 403 Unauthorized. 

Requires a username, which script apps have by default, but if you're using a web app, you'll need to either pass it in explicitly, or set the username property on your Reddit::Client object. 

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

=item distinguish

    distinguish ( $fullname, sticky => 0, how => 'yes' )

Distinguish a comment or post (moderator action). Options:

=over

C<sticky> Distinguish and sticky a comment. Only works for top-level comments.

C<how> This option should probably be left untouched. Valid values are "yes", "no", "admin", "special". Admin is for Reddit admins only; the rest are unexplained.

=back

=item edit

    edit ( $fullname, $text )
	
Edit a text post or comment. Unlike on the website, C<$text> can be an empty string. (It must be defined but can be a false value.)

=item edit_multi

Edit a multireddit. Will create a new multireddit if one with that name doesn't exist. The arguments are identical to L<create_multi|https://metacpan.org/pod/Reddit::Client#create_multi>.	

=item edit_wiki

    edit_wiki ( subreddit => $subreddit, page => $page, 
                content => '', previous => undef, reason => undef )

subreddit and page are required. Optional:

=over

C<content> is the new page content. Can be empty but must be defined. Maximum 524,288 characters.

C<reason> is the edit reason. Max 256 characters, will be truncated if longer. Optional.

C<previous> is the ID of the intended previous version of the page; if provided, that is the version the page will be rolled back to in a rollback. However, there's no way to find out what this should be from the Reddit website, or currently from Reddit::Client either. Use it only if you know what you're doing.

Note that if you are updating your sub's automod (which you can do using the page "config/automoderator"), and it has syntax errors, it will fail with the message "HTTP 415 Unsupported Media Type".

=back

=item find_subreddits

    find_subreddits ( q => $query, sort => 'relevance' )

Returns a list of Subreddit objects matching the search string C<$query>. Optionally sort them by C<sort>, which can be "relevance" or "activity".

=item flair_link

    flair_link ( subreddit => $subreddit, link_id => $link_id_or_fullname, 
                 text => undef, css_class => undef )

Flair a post with arbitrary text and css class. 

C<text> and C<css_class> are optional. If not provided, they will remove the existing text and/or css class. One advantage of doing this through the API (as opposed to the Reddit website) is that a css class can be applied with no text at all, not even an empty string. This allows you to have automoderator react to a thread or user in ways that are completely invisible to users.

=over

C<css_class> can be anything; it does not have to match an existing flair template. To select a flair template from the sub's list of flair, use L<select_post_flair|https://metacpan.org/pod/Reddit::Client#select_post_flair>.

C<text> will be truncated to 64 characters if longer.

=back

=item flair_post

Alias for flair_link.

=item flair_user

    flair_user ( username => $username, text => $text, 
                 css_class => undef, subreddit => undef )

Flair a user with arbitrary text and css class. Behaves exactly as L<flair_post|https://metacpan.org/pod/Reddit::Client#flair_post> except that it is given a username instead of a link ID. To select a flair template from the sub's list of flair, use L<select_user_flair|https://metacpan.org/pod/Reddit::Client#select_user_flair>.

=item flairtemplate (v2)

    flairtemplate( subreddit => $subreddit, 
                   allowable_content => 'all', background_color => undef, flair_template_id => undef, 
                   flair_type => 'LINK_FLAIR', text => undef, text_color => undef, text_editable => 1,
                   max_emojis => undef, mod_only => 0, override_css => undef )

Create or edit a v2 flair template. Can be used from the old (v1) interface; the V2 options will simply not be present.

Every argument except C<subreddit> is optional. If you supply C<flair_template_id>, it will edit the flair with that id, otherwise it will create a new one.

=over

C<subreddit>: Required. Accepts alias 'sub'.

C<allowable_content>: "all", "emoji", or "text". Default all.

C<background_color>: 6 digit hex code, with or without a hash mark.

C<flair_template_id> or C<id>: Accepts alias 'id'. 

C<flair_type>: 'LINK_FLAIR' or 'USER_FLAIR'. Defaults to LINK_FLAIR (this differs from the API, which defaults to URER_FLAIR).

C<max_emojis>: An integer from 1 to 10, default 10.

C<mod_only>: Whether it can be edited by non-moderators. Default false.

C<text>: A string up to 64 characters long.

C<text_color>: 'dark' or 'light'. Default dark. To prevent confusion that this option might want an actual color, Reddit::Client will die with an error if given any other value.

C<text_editable>: Whether the flair's text is editable. Default true.

C<override_css>: This has no documentation and preliminary tests haven't shown it to do anything. In certain cases, Reddit's V2 flair style will override V1 flair CSS, for example when applied by Automod; it may be intended to control this behavior.

=back

Reddit will return a hash reference with some information about the new or edited flair. The returned keys do not match the input keys in all cases, unfortunately.

=item get_comment 

    get_comment ( $id_or_fullname, include_children => 0 )

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

Get the comment tree for the selected subreddit/link_id, subreddit/link_id/comment_id, permalink, or URL. This will be a mix of Comment and MoreComments objects, which are placeholders for collapsed comments. They correspond to the "show more comments" links on the website.

If you already have a Link or Comment object, it's best to call its own C<get_comments> method, which takes no arguments and supplies all of the necessary information for you. If you do decide to use this version:

=over

C<permalink> is the value found in the C<permalink> field of a Link or Comment. It is the URL minus the protocol and hostname, i.e. "/r/subreddit/comments/link_id/optional_title/comment_id". This is somewhat awkward but it's just how Reddit works. It's not intended to be something you contruct yourself; this option is intended for passing in the C<permalink> from an existing Link or Comment.

C<url> is a complete URL for a link or comment, as seen in address bar on the website.

C<subreddit>, C<link_id> and C<comment_id> should be self explanatory. It accepts either short IDs or fullnames, and like all functions that take C<subreddit> as an argument, it can be appreviated to C<sub>.

=back

Internally, all of these options simply create a permalink and pass it on to Reddit's API, because that is the only argument that this endpoint accepts.

B<MoreComments>

When iterating a list of Comments (for example from get_comments), you may come across objects with type "more".  They correspond to the comments on the website that are not initially expanded (you have to click "show more comments" to see them). It is a MoreComments object. Use its get_collapsed_comments method to get a list of the Comments it contains.

    my $cmts = $r->get_comments( url => $url );

    for my $cmt ( @$cmts ) {
        if ( $cmt->type eq 'more' ) {
            print "This is a MoreComments object. Expanding children.\n";
            my $more = $cmt->get_collapsed_comments();
			# $more is now an array reference containing Comments and possibly more MoreComments
        }
    }

This example shows the functionality but is not very useful, because each MoreComment may contain even more MoreComments, which themselves may contain even more MoreComments. That means to get at every last comment, you need a recursive function or similar.

=item get_flair_options

    get_flair_options( subreddit => $subreddit, link_id => $link_id_or_fullname )

    get_flair_options( subreddit => $subreddit, username => $username )

Get the link or user's current flair, and options for flair that may be applied. Return flair options for the post or the user provided. Returns a hash containing two keys:

=over

C<choices> is an array of hash references containing the flair options. Most important is C<flair_template_id>, which is used to set the flair of a post or user with set_post_flair or set_user_flair. C<flair_text> contains the text of the flair.

C<current> is a hash of the post or user's existing flair.

=back

This endpoint seems to be the only way to retrieve a link or user's I<current> flair template ID. 

To get a link or user's v2 flair list, which includes values like background color and text color (but does B<not> include the current flair template ID), use L<get_link_flair_options|https://metacpan.org/pod/Reddit::Client#get_link_flair_options> or L<get_user_flair_options|https://metacpan.org/pod/Reddit::Client#get_link_flair_options>.

=item get_inbox 

    get_inbox ( view => 'inbox' )
				
Returns a listing of Message objects, where C<view> is one of the MESSAGE L<constants|https://metacpan.org/pod/Reddit::Client#CONSTANTS>. All arguments are optional. If all are omitted your default inbox will be returned-- what you would see if you went to reddit.com and clicked the mailbox icon.

Checking your inbox via the API doesn't mark it as read. To do that you'll need to call C<mark_inbox_read>.

=item get_link 

    get_link ( $id_or_fullname )

Returns a Link object for C<$id_or_fullname>.

=item get_link_flair_options (v2)

    get_link_flair_options ( $subreddit ) 

Get a list of the subreddit's link flairs. Uses the V2 endpoint, which includes values like background color and text color. (The V1 endpoint is still available through get_link_flair_options_v1, however its return values are a subset of the V2 options so there is not much reason to use it.)

=item get_links

    get_links ( subreddit => undef, view => VIEW_DEFAULT )

Returns a listing of Link objects. All arguments are optional.

C<subreddit> can be a subreddit or multi (ex: "pics+funny"). If omitted, results from the user's front page will be returned-- i.e. what you would see if you visited reddit.com as that user. 
		
C<fetch_links()> is an alias for C<get_links()>.

=item get_links_by_id

    get_links_by_id ( @ids_or_fullnames )

Return an array of Link objects.

=item get_modlinks

    get_modlinks ( subreddit => 'mod', mode => 'modqueue' )
	
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

    get_modqueue ( subreddit => 'mod' )

Get the modqueue, i.e. the listing of links and comments you get by visiting /r/mod/about/modqueue. Optionally supply a subreddit. Defaults to 'mod', which is all subreddits you moderate. Identical to calling C<get_modlinks (subreddit => 'mod', mode => 'modqueue')>.

=item get_multi

    get_multi ( name => $multi_name, 
                user => $username, expand => 0 )
	
Get a hash of information about a multireddit. C<$username> defaults to your username.

If C<expand> is true, returns more detailed information about the subreddits in the multi. This can be quite a bit of information, comparable to the amount of information contained in a Subreddit object, however it's not I<exactly> the same, and if you try to create a Subreddit object out of it you'll fail.

=item new_modmail_conversation

    new_modmail_conversation ( body => $markdown, subject => $subject, subreddit => $subreddit,
                               to => $username, hide_author => 1 )

Creates a new modmail conversation and sends the first message in it. Returns a new ModmailConversation object, which will contain the first message as a ModmailMessage object.

All keys are required except for hide_author, which defaults to true. This is different than the behavior of the Reddit website, which shows the name of the moderator by default. hide_author is an alias for isAuthorHidden, the field's proper name, which you can use instead.

Reddit's documentation incorrectly says that C<to> should be a fullname. It is actually just a username. (A user's fullname would be something like t2_xxxxx.)

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

    get_subreddit_comments ( subreddit => undef )

Returns a list of Comment objects from a subreddit or multi. If subreddit is omitted the account's "front page" subreddits are returned (i.e. what you see when you visit reddit.com and are logged in).

=item get_subreddit_info

    get_subreddit_info ( $subreddit, $page = undef )
	
Returns a hash of information about subreddit C<$subreddit>. If $page is provided, return that page.

$page can be one of (this list may not be complete): banned, muted, contributors, wikibanned, wikicontributors, moderators, edit (returns the subreddit's settings), log, modqueue, unmoderated, reports, edited. 'rules' and 'traffic' are accepted by Reddit but always return undefined (as of 2/15/2021). 'flair' will cause an error.

=item get_token

    get_token ( client_id => $client_id, secret => $secret, username => $username, password => $password )

or

    get_token ( client_id => $client_id, secret => $secret, refresh_token => $refresh_token )

or

    get_token

Get an authentication token from Reddit. Normally a user has no reason to call this function themselves. If you pass in your authentication info when creating a new Reddit::Client onject, C<get_token> will be called automatically using the information provided. If your script runs continuously for more than an hour, a new token will be obtained automatically. C<get_token> is exposed in case you need to refresh your authorization token manually for some reason, for example if you want to switch to a different user within the same Reddit::Client instance.

If any arguments are provided, all of the appropriate arguments are required. If none are provided, it will use the information from the previous call.

=item get_user

    get_user ( user => $username, view => 'overview' )
			   
Get information about a user, where C<view> is one of the user L<constants|https://metacpan.org/pod/Reddit::Client#CONSTANTS>: overview, comments, submitted, gilded, upvoted, downvoted, hidden, saved, or about. Defaults to 'overview', which shows the user's most recent comments and posts.

The result will be a listing of Links and/or Comments, except in the 'about' view, in which case it will be a single Account object.

=item get_user_flair_options (v2)

    get_user_flair_options ( $subreddit ) 

Get a list of the subreddit's user flairs. Uses the V2 endpoint, which includes values like background color and text color. (The V1 endpoint is still available through get_user_flair_options_v1, however its return values are a subset of the V2 options so there is not much reason to use it.)

=item get_wiki

    get_wiki ( sub => $subreddit, page => $page, 
               data => 0, v => undef, v2 => undef )

Get the content of a wiki page. If C<data> is true, fetch the full data hash for the page. If C<v> is given, show the wiki page as it was at that version. If both C<v> and C<v2> are given, show a diff of the two.

=item get_wiki_data

    get_wiki_data ( sub => $subreddit, page => $page, 
                    v => undef, v2 => undef )

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

Returns a hash of information about C<$fullname>. This will be the raw information hash from Reddit, not loaded into an object of the appropriate class (because classes don't exist for every type of thing, and because Reddit periodically updates the API, creating new fields, so it's nice to have a way to look at the raw data it's returning). C<$fullname> can be any of the 8 types of thing.

=item list_subreddits

    list_subreddits ( view => undef )

Returns a list of subreddits, where C<view> is one of the subreddit L<constants|https://metacpan.org/pod/Reddit::Client#CONSTANTS>: '' (i.e. home), 'subscriber', 'popular', 'new', 'contributor', or 'moderator'. Note that as of January 2018 some views, such as the default, are limited to 5,000 results. 'new' still gives infinite results (i.e. a list of all subreddits in existence). Others are untested.

=item lock

    lock ( $fullname, lock => 1 )

Lock a post's comment section or individual comment (moderator action). Will fail with a 400 if used on an archived (over 6 months old) post.

Using optional argument C<lock =E<gt> 0> is the same as calling L<unlock|https://metacpan.org/pod/Reddit::Client#unlock> on the fullname.

=item mark_inbox_read

    mark_inbox_read()

Mark everything in your inbox as read. May take some time to complete.

=item me

    me()

Return an Account object that contains information about the logged in account. Aside from static account information it contains the C<has_mail> property, which will be true if there is anything in your inbox.

=item mute

    mute ( username => $username, subreddit => $subreddit, [ note => $note ] )

Mute a user (moderator action). Optionally leave a note that only moderators can see.

=item new 

    # script-type app
    new ( user_agent => $user_agent, client_id => $client_id, secret => $secret,
          username => $username, password => $password, 
          print_request_errors => 0, print_response => 0, print_request => 0, print_request_on_error => 0,
          subdomain => 'www' )

or

    # web-type app
    new ( user_agent => $user_agent, client_id => $client_id, secret => $secret,
          refresh_token => $refresh_token,
          print_request_errors => 0, print_response => 0, print_request => 0, print_request_on_error => 0,
          subdomain => 'www', username => undef )

Instantiate a new Reddit::Client object. Optionally authenticate at the same time. (Unless you have some reason not to, this is the recommended way to do it.) For "script"-type apps, this is done by passing in a username, password, client_id and secret. For "web"-type apps, this is done by passing in a refresh_token, client_id and secret.

C<user_agent> is a string that uniquely identifies your app. The L<API rules|https://github.com/reddit/reddit/wiki/API#rules> say it should be "something unique and descriptive, including the target platform, a unique application identifier, a version string, and your username as contact information". It also includes this warning: "NEVER lie about your user-agent. This includes spoofing popular browsers and spoofing other bots. We will ban liars with extreme prejudice." C<user_agent> is required as of version 1.2 (before, Reddit::Client would provide one if you didn't).

C<subdomain> is the subdomain in links generated by Reddit::Client (for example with C<get_web_url>). You can use this to generate links to old.reddit.com to force the old version of Reddit, for example, or new.reddit.com for the new. Default www.

C<username> is optional for web apps. Unlike a script app, at no point does a web app know your username unless you explicitly provide it. This means that if you're using a function that requires a username (L<create_multi|https://metacpan.org/pod/Reddit::Client#create_multi> and L<edit_multi|https://metacpan.org/pod/Reddit::Client#edit_multi> are two), and you haven't either passed it into the function directly or set the property in your Reddit::Client object, it will fail. 

B<Error handling>

By default, if there is an error, Reddit::Client will print the HTTP status line and then die. You can change this behavior with the following variables:

=over

C<print_request_errors>: If there was an error, print some information about it before dying.

Reddit will usually return some JSON in the case of an error. If it has, Reddit::Client will add some of its own information to it, encode it all to a JSON string, print it, and die. It will contain the keys C<code>, C<status_line>, C<error> (which will always be 1), and C<data>, which will contain Reddit's JSON data. The fields in Reddit's return JSON are unpredictable and vary from endpoint to endpoint.

Sometimes Reddit will not return valid JSON; for example, if the request fails because Reddit's CDN was unable to reach their servers, you'll get a complete webpage. If Reddit did not return valid JSON for this or some other reason, Reddit::Client will print the HTTP status line and the content portion of the response.

C<print_response_content>: Print the content portion of Reddit's HTTP response. 

C<print_request>: Print the entire HTTP request and response.

C<print_request_on_error>: If there is a request error, print the entire HTTP request and response.

=back

=item nsfw

    nsfw ( $fullname, nsfw => 1 )

Flag a post as NSFW (moderator action).

Using optional argument C<nsfw =E<gt> 0> is the same as calling L<unnsfw|https://metacpan.org/pod/Reddit::Client#unnsfw> on the fullname.

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

=item select_flair (v2)

    select_flair ( link_id => $id_or_fullname, subreddit => $subreddit, flair_id => $flair_template_id, 
                   background_color => 'cccccc', css_class => '', text_color => 'dark', text => '' )

or

    select_flair ( username => $username, subreddit => $subreddit, flair_id => $flair_template_id, 
                   background_color => 'cccccc', css_class=> '', text_color => 'dark', text => '' )

Select flair for a user or link from among the sub's flair templates. To flair a post without an existing template, use L<flair_post|https://metacpan.org/pod/Reddit::Client#flair_post> (v1 only).

=over

C<background_color> Hex code, with or without hash mark. Defaults to light grey.

C<css_class> The CSS class to be used in the v1 interface. No effect on v2 interface.

C<flair_template_id> is acquired via L<get_link_flair_options|https://metacpan.org/pod/Reddit::Client#get_link_flair_options> or L<get_user_flair_options|https://metacpan.org/pod/Reddit::Client#get_user_flair_options>. It can also be copied from the v2 flair interface on the website. C<flair_id> may be used as an alias for C<flair_template_id>. Required.

C<link_id> The link to apply flair to. Either it or C<username> is required.

C<return_rtjson> all|only|none. "all" saves attributes and returns json (default), "only" only returns json, "none" only saves attributes.

C<subreddit> The subreddit.

C<text> The flair text. 64 characters max.

C<text_color> The text color on the v2 interface. Can be "dark" (default) or "light". To help prevent mistaking this option for an actual color, select_flair will die with an error if given anything else.

C<username> Username to apply flair to. Either it or C<link_id> is required.

=back


=item set_post_flair and select_post_flair

Deprecated. Use L<select_flair|https://metacpan.org/pod/Reddit::Client#select_flair> or L<flair_post|https://metacpan.org/pod/Reddit::Client#flair_post>.

=item set_user_flairs

Deprecated. Use L<select_user_flair|https://metacpan.org/pod/Reddit::Client#select_user_flair> or L<flair_user|https://metacpan.org/pod/Reddit::Client#flair_user>.

=item submit_comment 

    submit_comment ( parent_id => $fullname, text => $text)

Deprecated in favor of L<comment|https://metacpan.org/pod/Reddit::Client#comment>. Submit a comment under C<$fullname>, which must be a post or comment. Returns fullname of the new comment.

=item submit_crosspost

    submit_crosspost ( subreddit => $subreddit, title => $title, source_id => $fullname, 
                       inbox_replies => 1, repost => 0 )

Submit a crosspost. Returns the fullname of the new post. 

C<source_id> is the id or fullname of an existing post. This function is identical to C<submit_link>, but with C<source_id> replacing C<url>.  

If C<inbox_replies> is defined and is false, disable inbox replies for that post. If C<repost> is true, the link is allowed to be a repost. (Otherwise, if it is a repost, the request will fail with the error "That link has already been submitted".) C<sub> can be used as an alias for C<subreddit>.


=item submit_link 

    submit_link ( subreddit => $subreddit, title => $title, url => $url, 
                [ inbox_replies => 1, ] [ repost => 0, ] [ nsfw => 0, ] )

Submit a link. Returns the fullname of the new post. 

If C<inbox_replies> is defined and is false, disable inbox replies for that post. If C<repost> is true, the link is allowed to be a repost. (Otherwise, if it is a repost, the request will fail with the error "That link has already been submitted".) C<sub> can be used as an alias for C<subreddit>.

=item submit_text 

    submit_text ( subreddit => $subreddit, title => $title,  
                [ text => $text, inbox_replies => 1 ] )

Submit a text post. Returns the fullname of the new post. If C<inbox_replies> is defined and is false, disable inbox replies for that post.

=item unban

    unban ( username => $username, subreddit => $subreddit )

Un-ban a user (moderator action).

=item undistinguish

    undistinguish ( $fullname )

Un-distinguish a comment or post (moderator action).

=item unhide 

    unhide ( $fullname )

Unhide a post.

=item unlock

    unlock ( $fullname )

Unlock a post's comment section or individual comment (moderator action).

Equivalent to calling L<lock|https://metacpan.org/pod/Reddit::Client#lock>(C<$fullname>, C<lock=E<gt>0>).

=item unmute

    unmute ( username => $username, subreddit => $subreddit )

Un-mute a user (moderator action).

=item unnsfw

    unnsfw ( $fullname )

Remove the NSFW flag from a post (moderator action). Equivalent to calling L<nsfw|https://metacpan.org/pod/Reddit::Client#nsfw>(C<$fullname>, C<nsfw=E<gt>0>).

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

=head1 CHANGELOG

Reddit::Client has tracked changes with comments at the head of the main module for years now, but this is obviously not ideal for users who just want to know what is new. A changelog text file, function, or something more nicely-formatted is planned; for now, this section will have a cut-and-paste of recent changes from the comments.

    # 1.386 2/19/21
    # updated get_subreddit_info, now takes second arg for specific page
    # added approve_user
    
    # 1.385 11/23/20
    # added modmail_action, ModmConv...->archive
    # 1.384
    # added invite_mod, arg-only version of invite_moderator
    # 1.384 10/11/20 update
    #   added report
    #
    # 1.384 9/29/20
    #   added modmail_mute
    #   submit_text: field 'text' is no longer required
    #   added more fields to Link
    
    # 1.383 added sticky_post
    
    # next big version can be when we put in the new mute
    # 1.382 (should be big ver?) added friend function - no we didn't
    
    # 1.381 changed default max request from 500 to 100
    
    # 1.38 7/27/20
    #   added ModmailConversation and ModmailMessage classes
    #   added function new_modmail_conversation


    # 1.375 7/2/20 added sr_detail to Link
    # 1.374 added nsfw option to submit_link
    
    # 1.373 edit now returns the edited thing's id
    # 1.372
    # -get_link now gets its links in a proper way, by calling get_links_by_ids and
    #  taking the first element
    # -Link class now has many more keys; should now reflect most or all of the keys
    #  Reddit returns, minus 'downs' and 'ups' because they are deprecated and can
    #  cause confusion


    # 1.37 01/09/20
    # -added select_flair (v2)
    # -added flairtemplate, creates or edits a v2 flair template
    # -added get_link_flair_options. Gets link flair for a sub. uses v2 endpoint.
    # -added get_link_flair_options_v1, which uses the v1 endpoint and is instantly deprecated
    # -added get_user_flair_options. Gets link flair for a sub. uses v2 endpoint.
    # -added get_user_flair_options_v1, which uses the v1 endpoint and is instantly deprecated
    # -select_post_flair is renamed select_flair, now accepts v2 arguments, and can
    # accept a username instead to flair a user. See the documentation for description

    
    # 1.36 12/22/19: new functions lock, unlock, nsfw, unnsfw

    # 1.352 10/25/19: iscomment, ispost and get_type are now static
    # added functions distinguish, undistinguish
    
    # 10/05/19 1.351 delete now returns result
    # 10/02/19 1.35 add_approved_user, minor housekeeping
    # 1.341 7/30 removed warnings, they're stupid
    # 7/30 mute and unmute
    # 1.33 7/10 corrected 'edited' to not be boolean
    # 5/29 1.32 unban
    # 5/3 .315 submit_comment now returns fullname not id
    # 4/25 .314 4/8 1.313
    #  .314 added locked key to Comment, was this a recent Reddit change?
    # 1.313 changed the behavior of print_request_errors
    # 1.312 requests that fail with print_request_errors as true now die instead of
    #       croak, which lets you capture the error message

=head1 AUTHOR

L<mailto:earthtone.rc@gmail.com>

=head1 LICENSE

BSD license

=cut

