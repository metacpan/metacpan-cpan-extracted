package Reddit::Client;

our $VERSION = '1.0972';  

$VERSION = eval $VERSION;

use strict;
use warnings;
use Carp;

use Data::Dumper   qw/Dumper/;
use JSON           qw//;
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

#===============================================================================
# Constants
#===============================================================================

use constant DEFAULT_LIMIT           => 25;

use constant VIEW_HOT                => '';
use constant VIEW_NEW                => 'new';
use constant VIEW_CONTROVERSIAL      => 'controversial';
use constant VIEW_TOP                => 'top';
use constant VIEW_RISING	     => 'rising';
use constant VIEW_DEFAULT            => VIEW_HOT;

use constant VOTE_UP                 => 1;
use constant VOTE_DOWN               => -1;
use constant VOTE_NONE               => 0;

use constant SUBMIT_LINK             => 'link';
use constant SUBMIT_SELF       	     => 'self';
use constant SUBMIT_MESSAGE          => 'message';

use constant MESSAGES_INBOX	     => 'inbox';
use constant MESSAGES_UNREAD	     => 'unread';
use constant MESSAGES_SENT	     => 'sent';
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
use constant API_COMMENTS	     => 17;
use constant API_MESSAGES	     => 18;
use constant API_MARK_READ	     => 19;
use constant API_MARKALL	     => 20;
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

#===============================================================================
# Parameters
#===============================================================================

our $DEBUG            = 0;
our $BASE_URL         = 'https://oauth.reddit.com';
use constant BASE_URL =>'https://oauth.reddit.com';
our $LINK_URL         = 'https://www.reddit.com';
use constant LINK_URL =>'https://www.reddit.com';
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
$API[API_CREATEMULTI   ] = ['POST', '/api/multi/user/%s/m/%s' ];
$API[API_GETMULTI      ] = ['GET', '/api/multi/user/%s/m/%s%s'];
$API[API_DELETEMULTI   ] = ['DELETE','/api/multi/user/%s/m/%s'];
$API[API_EDITMULTI     ] = ['PUT',  '/api/multi/user/%s/m/%s' ];
$API[API_SUBREDDIT_INFO] = ['GET',  '/r/%s/about'             ];
$API[API_SEARCH        ] = ['GET',  '/r/%s/search'            ];
$API[API_MODQ          ] = ['GET',  '/r/%s/about/%s'          ];
$API[API_EDIT          ] = ['POST', '/api/editusertext'       ];
#===============================================================================
# Package routines
#===============================================================================

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

#===============================================================================
# Class methods
#===============================================================================

use fields (
    	'modhash',      # store session modhash
    	'cookie',       # store user cookie
    	'session_file', # path to session file
    	'user_agent',   # user agent string
    	'token',	# oauth authorization token
    	'tokentype',    # unused but saved for reference
    	'last_token',	# time last token was acquired
    	'client_id',	# These 4 values saved for automatic token refreshing
    	'secret',
	'username',
	'password',
	'request_errors',
);

sub new {
	my ($class, %param) = @_;
	my $self = fields::new($class);

	if (not exists $param{user_agent}) {
		carp "Reddit::Client->new: user_agent required in future version.";
		$param{user_agent} = $UA;
	}
	$self->{user_agent} = $param{user_agent};
	$self->{request_errors}= $param{request_errors} || 0;

	if ($param{username} || $param{password} || $param{client_id} || $param{secret}) {
		if (!$param{username} || !$param{password} || !$param{client_id} || !$param{secret}) {
			croak "If any of username, password, client_id, or secret are provided, all are required.";
		} else {
			$self->get_token(
					client_id	=> $param{client_id},
					secret		=> $param{secret},
					username	=> $param{username},
					password	=> $param{password},	
			);
		}
	}

	#print Dumper $self;
    return $self;
}

sub version {
	my $self = shift;
	return $VERSION;
}

#===============================================================================
# Internal management
#===============================================================================

sub request {
    my ($self, $method, $path, $query, $post_data) = @_;

	if (!$self->{last_token} || $self->{last_token} <= time - 3598) {
		$self->get_token(client_id=>$self->{client_id}, secret=>$self->{secret}, username=>$self->{username}, password=>$self->{password});
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
	request_errors=> $self->{request_errors},
    );

    return $request->send;
}

sub get_token {
	my ($self, %param) = @_;
	$self->{client_id} 	= $param{client_id} || croak "need client_id"; 
	$self->{secret} 	= $param{secret}    || croak "need secret";
	$self->{username}	= $param{username}  || croak "need username";
	$self->{password}	= $param{password}  || croak "need password";
	$self->{last_token} 	= time;

	my $message = Reddit::Client::Request->token_request($self->{client_id}, $self->{secret}, $self->{username}, $self->{password}, $self->{user_agent});
	my $j = JSON::decode_json($message);
	$self->{token} 		= $j->{access_token};
	$self->{tokentype} 	= $j->{token_type};

	if (!$self->{token}) { croak "Unable to get or parse token."; }
}

sub has_token {
	my $self = shift;
	return (!$self->{last_token} || $self->{last_token} <= time - 3598) ? 0 : 1;
}

sub json_request {
    my ($self, $method, $path, $query, $post_data) = @_;
    DEBUG('%4s JSON', $method);

    if ($method eq 'POST') {
        $post_data ||= {};
        $post_data->{api_type} = 'json';
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
    	my $query  = {};
        $query->{before} = $param{before} if $param{before};
        $query->{after}  = $param{after}  if $param{after};
	if (exists $param{limit}) { $query->{limit} = $param{limit} || 500; }
	else 			  { $query->{limit} = DEFAULT_LIMIT;	    }

	DEBUG('List subreddits [%s]', $type);
	defined $type || croak 'Expected $type"';

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
	my $post_data = {api_type=>'json'};
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
	data=>$query);
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
	return "wtf in Client";

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

# reports spam modqueue unmoderated edited
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

sub get_link {
    	my ($self, $fullname) = @_;
	croak "expected argument 1: id or fullname" unless $fullname;

	$fullname = "t3_$fullname" if $self->get_type($fullname) ne "t3";
	my $info = $self->info($fullname);

	return $info if !$info;
	return Reddit::Client::Link->new($self, $info);
}

sub get_comment {
    	my ($self, $fullname) = @_;
	croak "expected argument 1: id or fullname" unless $fullname;

	$fullname = "t1_$fullname" if $self->get_type($fullname) ne "t1";
	my $info = $self->info($fullname);

	return $info if !$info;
	return Reddit::Client::Comment->new($self, $info);
}

sub get_subreddit_comments {
	my ($self, %param) = @_;
	my $subreddit 	= $param{subreddit} 	|| '';
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

    	return [
        	 map {Reddit::Client::Comment->new($self, $_->{data})} @{$result->{data}{children}} 
    	];
}

# Get information about a user
sub get_user {
    	my ($self, %param) = @_;
	my $view	= $param{view} || 'overview';
	my $user	= $param{user} || croak "expected 'user'";

    	my $query  = {};
        $query->{before} = $param{before} if $param{before};
        $query->{after}  = $param{after}  if $param{after};
	if (exists $param{limit}) { $query->{limit} = $param{limit} || 500; }
	else 			  { $query->{limit} = DEFAULT_LIMIT;	    }

    	my $args = [$user, $view];

	my $result = $self->api_json_request(
		api      => API_USER,
		args     => $args,
		data     => $query,
	);

	return [
		map {

		$_->{kind} eq "t1" ? 
			Reddit::Client::Comment->new($self, $_->{data}) :
			Reddit::Client::Link->new($self, $_->{data})
		} 

		@{$result->{data}{children}} 
	];
}
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
    my $subreddit = $param{subreddit} || '';
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

sub submit_text {
    my ($self, %param) = @_;
    my $subreddit = $param{subreddit} || '';
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
	my $post_id 	= $param{post_id};
	my $user	= $param{username};
	my $data	= {};

	# what happens when both are sent?
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

sub edit_wiki {
	my ($self, %param) = @_;
	my $page 	= $param{page} || croak "Need 'page'";
	my $content	= defined $param{content} ? $param{content} : croak "Need 'content'";
	# Reddit maximum length is 524,288
	if (length $content > 524288) { croak "Maximum length for 'content' is 524288 bytes."; }
	my $sub		= $param{subreddit} || croak "Need 'subreddit'";
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

sub get_comments { # currently broken
    my ($self, %param) = @_;
    my $permalink = $param{permalink} || croak 'Expected "permalink"';

    DEBUG('Retrieve comments for %s', $permalink);

    my $result   = $self->json_request('GET', $permalink);
    my $comments = $result->[1]{data}{children};
    return [ map { Reddit::Client::Comment->new($self, $_->{data}) } @$comments ];
}

sub submit_comment {
    my ($self, %param) = @_;
    my $parent_id = $param{parent} || $param{parent_id} || croak 'Expected "parent"';
    my $comment   = $param{text}      || croak 'Expected "text"';

    croak '$fullname must be a post or comment' if !$self->ispost($parent_id) && !$self->iscomment($parent_id);
    DEBUG('Submit comment under %s', $parent_id);

    my $result = $self->api_json_request(api => API_COMMENT, data => {
        thing_id => $parent_id,
        text     => $comment,
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
	$data->{multipath} = "/user/$self->{username}/m/$model->{display_name}";

	my $result = $self->api_json_request( 
		api => $param{edit} ? API_EDITMULTI : API_CREATEMULTI, 
		args => [$self->{username}, $model->{display_name}],
		data => $data,
	);

	return $result->{data};
}

sub get_multi {
	my ($self, %param) = @_;
	my $name	= $param{name} || croak "expected 'name'";
	my $username 	= $param{user} || $self->{username};
	my $expand	= $param{expand} ? '?expand_srs=true' : '';

	my $result = $self->api_json_request( 
		api => API_GETMULTI, 
		args => [$username, $name, $expand],
	);

	# The result looks like a Subreddit object, but is not.
	# By returning just the data we lose the 'kind' key,
	# which is just the string "LabeledMulti"
	return $result->{data};
	return $result;
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
# Internal
#==============================================================================

sub ispost {
	my ($self, $name) = @_;
    	my $type = substr $name, 0, 2;
	return $type eq 't3';
}

sub iscomment {
	my ($self, $name) = @_;
    	my $type = substr $name, 0, 2;
	return $type eq 't1';
}
sub get_type {
	my ($self, $name) = @_;
    	return lc substr $name, 0, 2;
}

1;

__END__

=pod

=head1 NAME

Reddit::Client - A Perl wrapper for the Reddit API.

Up to date, nicely-formatted documentation can be found at L<http://redditclient.readthedocs.org/en/latest/>. 

=head1 SYNOPSIS

    use Reddit::Client;

    my $client_id  	= "DFhtrhBgfhhRTd";
    my $secret     	= "KrDNsbeffdbILOdgbgSvSBsbfFs";
    my $username   	= "reddit_username";
    my $password   	= "reddit_password";


    # Create a Reddit::Client object and authorize in one step
    my $reddit = new Reddit::Client(
	user_agent 	=> 'MyScriptName 1.0 by /u/earth-tone',
	client_id	=> $client_id,
	secret		=> $secret,
	username	=> $username,
	password	=> $password,
    );
	
    # Or create object then authorize.
    # Useful if you need to switch between accounts, for example if you were to check the inboxes of several accounts.
    my $reddit = Reddit::Client->new(
        user_agent   	=> 'MyApp/1.0 by /u/earth-tone',
    );

    $reddit->get_token(
	client_id	=> $client_id,
	secret		=> $secret,
	username	=> $username,
	password	=> $password,
    );

    # Check your inbox
    my $me = $reddit->me();
    print "You've got mail!" if $me->{has_mail};

    # Submit a link
    $reddit->submit_link(
        subreddit 	=> 'test',
        title     	=> 'Perl is still alive!',
        url       	=> 'http://www.perl.org'
    );

    # Submit a text post
    $reddit->submit_text(
	subreddit 	=> 'test',
	title		=> 'my test',
	text		=> 'a test'
    );

    # Get posts from a subreddit or multi
    my $posts = $reddit->fetch_links(subreddit=>'test', limit=>5);
    foreach my $post (@$posts) {
	print $post->{title} . "\n";
	if (!$post->{is_self}) { # Is it a self post or a link?
		print $post->{url};
	} else {
		print $post->{selftext};
	}
    }

    # Get comments from a subreddit or multi
    my $cmts = $reddit->get_subreddit_comments('test');
    foreach my $cmt (@$cmts) {
	print "$cmt->{author} says: $cmt->{body}\n";
    }


=head1 DESCRIPTION

Reddit::Client provides methods and object wrappers for objects exposed
. This module handles HTTP communication, oauth session management, and communication with Reddit's external API. For more information about the Reddit API, see L<https://github.com/reddit/reddit/wiki/API>.

Beginning August 3rd, 2015, the Reddit API requires Oauth authentication. This amounts to two extra arguments at the beginning of your script; in exchange you you twice as many requests per minute as before (60 vs 30) and some added convenience on the back end.

To get Oauth keys, visit your apps page: L<https://www.reddit.com/prefs/apps>. Choose a "script" type app. None of the other fields are needed for a script type app; you can put in C<127.0.0.1> for the URLs or whatever you like.

Every account that uses this script must have permission to use it. So for example if you were to check the inboxes of your various accounts, each one would need permission. To add accounts click "add developer" on the right, after you've created the app.

=head1 Constants

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

=head1 Methods

These are the methods of the Reddit::Client class.

Two notes about methods that return lists of things:

1. All methods that return lists of things return them as a Perl list-- that is, a reference to an anonymous array. In practice this means that you get at the values with C<@$array> instead of C<@array>.

2. All methods that return lists of things accept three optional parameters: I<limit>, I<before>, and I<after>. You may recognize them from your address bar when viewing pages after the front page. I<limit> defaults to 25 with a maximum of 100. (If I<limit> is present but false, this is interpreted as "no limit" and the maximum is returned.) I<before> and I<after> limit results to those posted before I<before> and after I<after>.


=head1 Methods

=over

=item comment

    comment ( $fullname, $text )
	
Make a comment under I<$fullname>, which must be either a post or a comment. Return the fullname of the new comment.

This function is an alias for C<submit_comment>, and is equivalent to

    submit_comment ( parent_id => $fullname, text => $text )

=item create_multi

    create_multi ( name => $multi_name, [ description => $description, ] [ visibility => $visibility, ]
                 [ subreddits => [ subreddits ], ] [ icon_name => $icon_name, ] [ key_color => $hex_code, ]
                 [ weighting_scheme => $weighting_scheme, ] )

Create a multireddit. The only required argument is the name. A multi can also be created with C<edit_multi>, the only difference being that C<create_multi> will fail with a HTTP 409 error if a multi with that name already exists.

Returns a hash of information about the newly created multireddit.

I<name> The name of the multireddit. Maximum 50 characters. Only letters, numbers and underscores are allowed. Required.

I<description> Description of the multi. This can contain markdown.

I<visibility> One of 'private', 'public', or 'hidden'. Default 'private'.

I<subreddits> or I<subs>: An array reference.

The remaining arguments don't currently do anything. It seems like at least some of them are intended for future mobile updates.

I<icon_name> If provided, must be one of the following values: 'art and design', 'ask', 'books', 'business', 'cars', 'comics', 'cute animals', 'diy', 'entertainment', 'food and drink', 'funny', 'games', 'grooming', 'health', 'life advice', 'military', 'models pinup', 'music', 'news', 'philosophy', 'pictures and gifs', 'science', 'shopping', 'sports', 'style', 'tech', 'travel', 'unusual stories', 'video', '', 'None'.

I<weighting_scheme> If provided, must be either 'classic' or 'fresh'.

I<key_color> A 6-character hex code. Defaults to CEE3F8.

=item delete 

    delete ( $fullname )

Delete a post or comment.

=item delete_multi

    delete_multi ( $multireddit_name )
	
Delete a multireddit.

=item edit_multi

Edit a multireddit. Will create a new multireddit if one with that name doesn't exist. The arguments are identical to C<create_multi>.

=item edit_wiki

    edit_wiki ( subreddit => $subreddit, page => $page, content => $content,
              [ previous => $previous_version_number,] [ reason => $edit_reason, ] )
	
I<page> is the page being edited.

I<content> is the new page content. Can be empty but must be defined. Maximum 524,288 characters.

I<reason> is the edit reason. Max 256 characters, will be truncated if longer. Optional.
	
I<previous> is the ID of the intended previous version of the page; if provided, that is the version the page will be rolled back to in a rollback. However, there's no way to find out what this should be from the Reddit website, or currently from Reddit::Client either. Use it only if you know what you're doing. Optional.

=item find_subreddits

    find_subreddits ( q => $query, [ sort => 'relevance' ,] 
                    [ limit => DEFAULT_LIMIT ,] [ before => undef ,] [ after => undef ,] )

Returns a list of Subreddit objects matching the search string I<$query>. Optionally sort them by I<sort>, which can be "relevance" or "activity".

=item get_comment 

    get_comment ( $fullname )

Returns a Comment object for I<$fullname>.

=item get_flair_options

    get_flair_options( subreddit => $subreddit, post_id => $post_id_or_fullname, username => $username )
	
Get the flair options for either the post or the user provided.

Returns a hash containing two keys:

1. I<choices> is an array of hash references containing the flair options. Most important is I<flair_template_id>, which is used to set the flair of a post or user with C<set_post_flair> or C<set_user_flair>. I<flair_text> contains the text of the flair.

2. I<current> is a hash of the post or user's existing flair.

=item get_inbox 

    get_inbox ( [ view => MESSAGES_INBOX ,] [ limit => DEFAULT_LIMIT ,]
                [ before => undef ,] [ after => undef ,] )
				
Returns a list of Message objects, where I<view> is one of the MESSAGE constants. All arguments are optional. If all are omitted your default inbox will be returned-- what you would see if you went to reddit.com and clicked the mailbox icon.

Checking your inbox via the API doesn't mark it as read. To do that you'll need to call C<mark_inbox_read>: L<http://redditclient.readthedocs.org/en/latest/main-methods/#mark_inbox_read>

=item get_link 

    get_link ( $fullname )

Returns a Link object for I<$fullname>.

=item get_links

    get_links ( [ subreddit => undef ,] [ view => VIEW_DEFAULT ,] [ limit => DEFAULT_LIMIT ,]
                [ before => undef ,] [ after => undef ,] )

Returns a list of Link objects. All arguments are optional.

I<subreddit> can be a subreddit or multi (ex: "pics+science"). If omitted, results from the user's front page will be returned-- i.e. what you would see if you visited reddit.com as that user. 

I<view> is a feed type constant-- i.e. VIEW_HOT, VIEW_NEW, etc.
		
fetch_links is an alias for get_links.

=item get_multi

    get_multi ( name => $multi_name, [ user => $username, ] [ expand => 0, ] )
	
Get a hash of information about a multireddit. I<$username> defaults to your username.

If I<expand> is true, returns more detailed information about the subreddits in the multi. This can be quite a bit of information, comparable to the amount of information contained in a Subreddit object, however it's not I<exactly> the same, and if you try to create a Subreddit object out of it you'll fail.

=item get_permalink

    get_permalink ( $comment_id, $post_id )
	
Returns a permalink for I<$comment_id>. B<If you already have a Comment object, use its get_permalink function instead>, ala C<$comment->get_permalink()>. 

This version causes an extra request because it has to ask Reddit for the parent post's URL first, while a Comment object already has that information. It's provided for backwards compatibility, and for the rare case when you may have a comment's ID but not a comment object (perhaps you have a list of IDs stored in a database). It may be deprecated in the future.

I<$comment_id> and I<$post_id> can be either fullnames or short IDs.

=item get_subreddit_comments

    get_subreddit_comments ( [ subreddit => '' ,] [ view => VIEW_DEFAULT ,] [ limit => DEFAULT_LIMIT ,]
                             [ before => undef ,] [ after => undef ,]  )

Returns a list of Comment objects from a subreddit or multi.

All arguments are optional. If subreddit is omitted the account's "front page" subreddits are returned (i.e. what you see when you visit reddit.com and are logged in). 

I<view> is a feed type constant-- i.e. VIEW_HOT, VIEW_NEW, etc.

=item get_token

    get_token ( client_id => $client_id, secret => $secret, username => $username, password => $password )

Get an Oauth token from Reddit. This is analogous to the old login function, and can be considered identical, with the exception that, if your script runs continuously for more than an hour, a new token will be obtained hourly.

=item get_user

    get_user ( [ user => $username ,] [ view => USER_OVERVIEW ,]
               [ limit => DEFAULT_LIMIT ,][ before => undef ,] [ after => undef ,]  )
			   
Get information about a user, where I<view> is one of the USER constants: overview, comments, submitted, gilded, upvoted, downvoted, hidden, or saved. Defaults to overview, which shows the user's most recent comments and posts.

Note that if you try to get the upvoted, downvoted, hidden, or saved activity for a user other than yourself, Reddit will return a 403 error, so be sure to wrap requests in a try/catch (L<http://redditclient.readthedocs.org/en/latest/examples/#catch-exceptions>) if there's any chance that might happen. (Of course, all requests should be wrapped in a try/catch anyway, the internet being an unpredictable place.)

The result can be a list of Links, Comments, or a mix of both, depending on what I<view> you requested. You can determine which is which by looking at the type property, which is "t1" for comments and "t3" for posts.

=item has_token

    has_token()

Return true if a valid Oauth token exists.

=item hide

    hide ( $fullname )

Hide a post.

=item info 

    info ( $fullname )

Returns a hash of information about I<$fullname>. I<$fullname> can be any of the 8 types of thing.

=item list_subreddits

    list_subreddits ( [ view => SUBREDDITS_HOME ,] [ limit => DEFAULT_LIMIT ,]
                      [ before => undef ,] [ after => undef ,]  )

Returns a list of subreddits, where I<view> is one of the SUBREDDIT constants. 

An alias function is provided for each view type, which is the same as calling C<list_subreddits> with the view already provided:

=over

C<contrib_subreddits ( [ limit => DEFAULT_LIMIT ,] [ before => undef ,] [ after => undef ,] )>

C<home_subreddits ( [ limit => DEFAULT_LIMIT ,] [ before => undef ,] [ after => undef ,] )>

C<mod_subreddits ( [ limit => DEFAULT_LIMIT ,] [ before => undef ,] [ after => undef ,] )>

C<my_subreddits ( [ limit => DEFAULT_LIMIT ,] [ before => undef ,] [ after => undef ,] )>

C<new_subreddits ( [ limit => DEFAULT_LIMIT ,] [ before => undef ,] [ after => undef ,] )>

C<popular_subreddits ( [ limit => DEFAULT_LIMIT ,] [ before => undef ,] [ after => undef ,] )>

=back

=item mark_inbox_read

    mark_inbox_read()

Mark everything in your inbox as read. May take some time to complete.

=item me

    me()

Return an Account object that contains information about the logged in account. Aside from static account information it contains the I<has_mail> property, which will be true if there is anything in your inbox.

=item new 

    new ( user_agent => $user_agent, [ client_id => $client_id, secret => $secret, 
          username => $username, password => $password ] )

Instantiate a Reddit::Client object. Optionally get an Oauth token (analogous to logging in) at the same time. If any of the four optional arguments are used, all are required.

I<$user_agent> is always required, and should be something descriptive that uniquely identifies your app. The API Rules (L<https://github.com/reddit/reddit/wiki/API#rules>) say it should be "something unique and descriptive, including the target platform, a unique application identifier, a version string, and your username as contact information".

It also includes this warning: "**NEVER lie about your user-agent.** This includes spoofing popular browsers and spoofing other bots. We will ban liars with extreme prejudice."

=item save 

    save ( $fullname )

Save a post or comment. 

=item send_message 

    send_message ( to => $username, subject => $subject, text => $message )

Send a private message to I<$username>. I<$subject> is limited to 100 characters.

=item set_post_flair

    set_post_flair ( subreddit => $subreddit, post_id => $post_id_or_fullname, flair_template_id => $flair_id )
	
Set the flair on a post. The 'flair_template_id' is acquired via I<get_flair_options>.

=item set_user_flair

    set_user_flair ( subreddit => $subreddit, username => $username, flair_template_id => $flair_id )
	
Set the flair for a user. The 'flair_template_id' is acquired via I<get_flair_options>.

=item submit_comment 

    submit_comment ( parent_id => $fullname, text => $text)

Submit a comment under I<$fullname>, which must be a post or comment. Returns fullname of the new comment.

=item submit_link 

    submit_link ( subreddit => $subreddit, title => $title, url => $url, [ inbox_replies => 1, [repost => 0] )

Submit a link. Returns the fullname of the new post. If I<inbox_replies> is defined and is false, disable inbox replies for that post. If I<repost> is true, the link is allowed to be a repost. (Otherwise, if it is a repost, the request will fail with the error "That link has already been submitted".)

=item submit_text 

    submit_text ( subreddit => $subreddit, title => $title, text => $text, [ inbox_replies => 1 ] )

Submit a text post. Returns the fullname of the new post. If I<inbox_replies> is defined and is false, disable inbox replies for that post.

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

Vote on a post or comment. Direction must be 1, 0, or -1 (0 to clear votes).

=back

=head1 AUTHOR

L<mailto:earthtone.rc@gmail.com>

=head1 LICENSE

BSD license

=cut

