package PEF::Front::Model;

use PEF::Front::Config;

use strict;
use warnings;

sub normalize_method_name {
	my $name = $_[0];
	if ($name =~ /^\^?PEF::Front/ || $name =~ /^\^/) {
		$name =~ s/^\^//;
	} else {
		$name = cfg_app_namespace . "Local::$name";
	}
	$name;
}

sub make_model_call {
	my ($method, $model) = @_;
	my ($model_sub, $cfg_model_sub);
	if ($model && !ref($model) && $model =~ /^\^?\w+::/) {
		$model = normalize_method_name($model);
		my $class = substr($model, 0, rindex($model, "::"));
		my $can = substr($model, rindex($model, "::") + 2);
		eval "use $class";
		$@ = "$class must contain $can function" if not $@ and not $class->can($can);
		die {
			result      => 'INTERR',
			answer      => 'Validator $1 loading model error: $2',
			answer_args => [$method, "$@"],
			}
			if $@;
		$model_sub = eval "sub { eval { $model(\@_) } }";
	} else {
		$model ||= 'rpc_site';
		$cfg_model_sub = eval {cfg_model_rpc($model)};
		$@ = "cfg_model_rpc('$model') must return code reference" if ref $cfg_model_sub ne 'CODE';
		die {
			result      => 'INTERR',
			answer      => 'Validator $1 loading model error: $2',
			answer_args => [$method, "$@"],
			}
			if $@;
		$model_sub = eval "sub { eval { \$cfg_model_sub->(\@_) } }";
	}
	return ($model, $model_sub);
}

sub _chain_links_sub {
	my $links = $_[0];
	$links = [$links] if not ref $links or ref $links ne 'ARRAY';
	my @handlers;
	for my $link (@$links) {
		if (not ref $link) {
			push @handlers, normalize_method_name($link);
		} elsif (ref $link eq 'HASH') {
			push @handlers, map {[normalize_method_name($_), $link->{$_}]} keys %$link;
		}
	}
	my $sub_str = <<EOS;
sub {
	my (\$req, \$context) = \@_;
	my \$response;
EOS
	for (my $i = 0; $i < @handlers; ++$i) {
		if (ref $handlers[$i]) {
			$sub_str .= "\t\$response = $handlers[$i][0](\$req, \$context, \$response, \$handlers[$i][1]);\n";
		} else {
			$sub_str .= "\t\$response = $handlers[$i](\$req, \$context, \$response);\n";
		}
	}
	$sub_str .= "\t\$response;\n}\n";
	if (wantarray) {
		my $sub = eval $sub_str;
		return ($sub, $sub_str);
	} else {
		return $sub_str;
	}
}

sub chain_links {
	my ($sub, $sub_str) = _chain_links_sub($_[0]);
	return $sub;
}

1;

__END__

=encoding utf8
 
=head1 PEF::Front model methods description

This is the crucial feature of PEF::Font.

=head1 SYNOPSIS

  /submitUserLogin
  
  # model/UserLogin.yaml

  ---
  params:
    ip:
      value: context.ip
    login:
      min-size: 1
      max-size: 40
    password:
      min-size: 4
      max-size: 40
  model: User::login
  result:
    OK:
      set-cookie:
        auth:
          value: TT response.auth
          expires: TT response.expires
      redirect: /me
    DEFAULT:
      unset-cookie: auth

  /ajaxGetArticles
  
  # model/GetArticles.yaml
  ---
  params:
    ip:
      value: context.ip
    limit:
      regex: ^\d+$        
      max-size: 3
    offset:
      regex: ^\d+$
      max-size: 10
  model: Article::get_articles


 
=head1 DESCRIPTION

For every internal API method there's one YAML-file describing its
parameters, handler method, caching and result processing. 

There're two sources to call these methods from: templates and HTTP requests.

To call this method from template you write it like this:

  [% articles = "get articles".model(offset => articles_offset, limit => 5) %]

To call this method from AJAX you send HTTP request like this:

  GET /ajaxGetArticles?offset=0&limit=5

"Normal" method name is lowercased phrase with spaces. 
Model methods description file name is made up from
method name transformed to CamelCase with '.yaml' extension: 
"get articles" -> "GetArticles.yaml". HTTP request method name is
made up concatenating one of prefixes '/ajax', '/submit', '/get' and CamelCase
form of method name.

=head1 INPUT PARAMETERS

Section "params" describes method input parameters, their sources, 
types and checks. There're two parameter's attribute to set source:
B<value> and B<default>. B<value> means unconditionally set value;
B<default> means that value will be set only if it was not set from
request query or form data parameter. 

Framework automatically decodes input data into internal Perl UTF-8 and
automatically encodes output to UTF-8. This is the only supported encoding.

=head2 Possible sources

=over

=item from query string or form data

This is the default. There's no difference between parameters from query 
string and form data. But when the same parameter is in query and form data
then value from query has precedence. 

There's also special parameter B<json> that has to be encoded JSON value.
When it's present, then parameters are overwritten from this decoded JSON.

Request parsing detects JSON or XML content-types and can parse them.

=item Direct value

B<value> and B<default> can be string or integer.

  ---
  params:
    ip:
      default: 127.0.0.1
    is_active:
      default: 0

=item from context data

B<context> is a hash with some data for handlers. 
It is created after initial routing processing before template or 
API method processing. There're some data:

=over

=item B<ip>

IP address of the client.

=item B<lang>

Short (ISO 639-1) language code. 
There's automatic language detection based on URL, HTTP headers and cookies
and Geo IP. You can turn it off. It's written to 'lang' cookie.

=item B<hostname>

Hostname of current request.

=item B<path>

Current URI path.

=item B<path_info>

Initial URI path.

=item B<method>

Method name.

=item B<scheme>

URL scheme. One of: 'http', 'https'.

=item B<src>

"Source" of the request. One of: 'app', 'ajax', 'submit', 'get'.

=item B<form>, B<headers>, B<cookies>, B<session> and B<request> 

They are also parts of context but they can't be used as values by themselves.
They are used in handlers. 

C<session> is loaded only if it was used for parameter value. 

=item B<template>

For template processing "method" is replaced with "template" 
which is template name.

=item B<time>, B<gmtime>, B<localtime>

These are additional fields for template processing. 
C<time> is current UNIX-time, C<gmtime> - 9-element list with the time in GMT,
C<localtime> - 9-element list with the time for the local time zone. 
See C<perldoc -f> for these functions. 

=back 

Example:

  ---
  params:
    ip:
      value: context.ip
    lang:
      default: context.lang

=item from request parameters

By default parameter "param1" is set from "param1" query/form data,
but it's possible to set it from another request parameter, 
like "another_param". B<form> is meant for this.

  ---
  params:
    ip:
      value: context.ip
    lang:
      default: context.lang
    login:
      value: form.username

=item from headers

  ---
  params:
    ip:
      value: context.ip
    back_url:
      default: headers.referer

=item from cookies

  ---
  params:
    ip:
      value: context.ip
    auth:
      default: cookies.auth

=item from request notes

Routing subroutines can set some notes on request object. Notes are just any
key-value pairs.

  ---
  params:
    ip:
      value: context.ip
    subsection:
      default: notes.subsection


=item from session data

From request parameters or from cookies using B<cfg_session_request_field> 
is possible to automatically load value from session data.

  ---
  params:
    ip:
      value: context.ip
    user_last_name:
      default: session.user_last_name

=item from configuration parameter

You can specify any configuration parameter of framework or your application.

  ---
  params:
    path:
      value: config.avatar_images_path


=back

=head2 Checks

Ther're several types of input data checks. 

=over

=item Perl regular expressions

This is the mostly used method. L<Regexp::Common> with option 'RE_ALL'
is already loaded. When you write an expressions as parameter value 
then it means regexp check. 

  ---
  params:
    positive_integer: ^\d+$
    integer_or_empty: ^\d+$|^$
    any_integer: ^$RE{num}{int}$
    money: ^$RE{num}{decimal}{-places=>"0,2"}$

When you need to add some other attribute then attribute 'regex' is used:

  ---
  params:
    lang:
      default: context.lang
      regex: ^[a-z]{2}$

=item Possible values

Atributes C<can>, C<can_string> and C<can_number> describes set of possible 
values. C<can> and C<can_string> are synonyms.

  ---
  params:
    bool:
      can_number: [0, 1]
      default: 0
    lang:
      can: [en, de]
      default: de

=item Type

Parameter can have type 'array', 'hash' or 'file'. You can specify this with
last symbol of the parameter name '@', '%' or '*' or with attribute 'type'
as 'array', 'hash' or 'file'. To submit array you can use PHP-syntax:

  <!-- HTML -->
  <select name="select[]" multiple="multiple">
  
  # YAML
  ---
  params:
    select@:

Another way to submit array or hash is to use C<json> form data field or 
to post JSON or XML content.

Array of files has type 'array'.

=item Maximum or minimum size

This checks are working according to parameter type: 

=over

=item string length for scalars

=item array size for arrays

=item file size for files

=back

Min/max values are included in allowed range.

  ---
  params:
    limit40str:
      max-size: 40
    limit4_40str:
      min-size: 4
      max-size: 40

=item Maximum or minimum value

Numerical checks. Min/max values are included in allowed range.

  ---
  params:
    speed:
      max: 140
      min: 20

=item captcha

Captcha validation process usually removes information from captcha database
and this check can be done only once. Validation process makes all needed 
checks. 

This works following way. One parameter contains entered captcha 
code and another parameter contains hashed data of the right captcha code.
Attribute C<captcha> specifies parameter with hashed data of the right captcha 
code. Validator checks whether the code is right. If entered captcha is
equal to 'B<nocheck>' then it means to validator 'no need to check captcha' and 
no check is done. If captcha is required then handler must check that entered
captcha code is not equal to 'B<nocheck>'.

=item Optional flag

Attribute C<optional> specifies whether parameter is optional.  
Special value 'empty' means parameter is optional even when passed but 
contains only empty string.

=item Custom filter

Filter can be a Perl subroutine, regular expression substitution or array
of regular expression substitutions.

  ---
  params:
    auth:
      default: cookies.auth
      max-size: 40
      filter: Auth::required
    comment:
      max-size: 1000
      filter: [ s/</&lt;/g, s/>/&gt;/g ]

Recognized substitution operators are: C<s>, C<tr> and C<y>.

C<Auth::required> actually means subroutine C<required($value, $context)>
from your module C<${YourApplicationNamespace}::InFilter::Auth>.

I.e.:

    + $project_dir/
      + $app/
        + $Project/
          - AppFrontConfig.pm
          + InFilter/
            - Auth.pm

Your subroutine recieves 2 arguments: value of the parameter and request 
context.

  package MyApp::InFilter::Auth;
  use DBIx::Struct;
  use MyApp::Common;

  sub required {
    my ($value, $context) = @_;
    my $author = get_author_from_auth($value);
    die {
      result => "NEED_LOGIN",
      answer => 'You have to login for this operation'
    } unless $author;
    $value;
  }

When filter dies for optional parameter then this parameter is deleted from
request as if it was not provided. For required fields this means failed 
validation. 

=item Kind of inheritance

There's special YAML-file B<-base-.yaml> in your B<cfg_model_dir> where you
can write all common requests parameters and just use these descriptions
in your model methods description files.

  -base-.yaml
  ---
  params:
    ip:
      value: context.ip
    auth:
      default: cookies.auth
      max-size: 40
    auth_required:
      base: auth
      filter: Auth::required
    limit:
      regex: ^\d+$        
      max-size: 3
    offset:
      regex: ^\d+$
      max-size: 10
    positive_integer: ^\d+$
    integer_or_empty: ^\d+$|^$
    any_integer: ^$RE{num}{int}$
    bool:
      can_number: [0, 1]
      default: 0
    money: ^$RE{num}{decimal}{-places=>"0,2"}$

Attribute C<base> allows to specify "inheritance" of the properties for
corresponding parameter from B<-base-.yaml>. 
It works even inside B<-base-.yaml>. When you write an expressions 
with leading C<$> as parameter value then it means "inheritance".

  ---
  params:
    ip: $ip
    auth: 
      base: $auth
      optional: true
    id_article: $positive_integer
    id_comment_parent:
      base: $integer_or_empty
      filter: Empty::to_undef
    author:
      base: $limit40str
      min-size: 1
      filter: Default::auth_to_author

=back

=head2 Extra parameters

Special key C<extra_params> controls what to do when there're more
parameters as required: B<ignore> - all extra parameters will be 
silently deleted; B<pass> - all extra parameters will be passed 
without validation; B<disallow> - validation fails when extra parameters
passed.

  ---
  params:
    ip: $ip
  extra_params: pass

=head2 Output result

Handlers are supposed to return hash like these.

  {
    result => "OK",
  } 

or

  {
    result => "SOMEERRCODE",
    answer => 'Some $1 Error $2 Message $3',
    answer_args => [$some, $error, $params],
  }

C<result> is required in every answer, other keys are optional.

Following keys have some meaning:

=over

=item B<result>

Is symbolic result state. 

=over

=item "OK" means everything is good

=item "INTERR" means some internal application error

=item "OAUTHERR" means Oauth protocol error

=item "BADPARAM" means validation error

=back

Application can use its own codes.

=item B<answer>

Message from application. If calling type is C</ajax> and 
C<answer_no_nls> is not present or false then this message
will be automatically localized.

When calling type is C</get> or C</submit> then value of this 
key can be open file handle or code reference. If value of this
key is code reference then it is "streaming function". 
See L<PSGI/"Delayed Response and Streaming Body">.

=item B<answer_args>

Array of arguments to the message.

=item B<answer_headers>

Array of key-value pairs that will be set as output HTTP headers and their 
values. Key-value pairs can be list ($header => $value), 
array [$header => $value] or hash {$header => $value}.

  [
    {'X-Hr' => 'x-hr'},
    ['X-Ar' => 'x-ar'],
    'X-Header' => 'x-value'
  ]

=item B<answer_cookies>

Array of key-value pairs that will be set as output HTTP cookies and their 
values. Key-value pairs can be list ($cookie => $value), 
array [$cookie => $value] or hash {$cookie => $value}.

  [
    {ch => 'Chv'},
    [ca => 'Cav'],
    Cookie => 'cookie_value'
  ]

=item B<answer_no_nls>

If present and true then C<answer> will be send as is, without localization 
attempt.

=item B<answer_status>

Sets HTTP status code. If C<answer_status> is between 300 and 400 then 
C<Location> headers specifys new location for redirect.

=item B<answer_content_type>

Sets Content-Type header.

=item B<answer_data>

Replaces answer hash with C<answer_data> field before encoding to JSON. 
It can be only B<ARRAY> or B<HASH> reference.

=item B<answer_http_response>

Uses supplied HTTP response object as handler response.

=back

When method is called like C</ajax> then it means JSON format answer. 
When you need another output format, use C</get> or C</submit> type calls.

=head2 Response caching

Some methods can return constant or rarely changing data, 
it makes perfect sense to cache them.
Key C<cache> manages caching for responses. It has to attributes:
C<key> - one value or array defining caching key; 
C<expires> - how long data can be retained in cache. 
This value is parsed by L<Time::Duration::Parse>.

  ---
  params:
    id_user: $positive_integer
  cache:
    key: [method, id_user]
    expires: 1m

=head2 Result processing

Response key C<result> defines C<result>'s section to execute some actions. 
When no section is found then it looks for C<DEFAULT> section. 
Following actions are supported:

=over

=item B<redirect> 

Temporary browser redirect (302) for C</get> or C</submit> request types.
Can be array or values - it finds first non-empty.

=item B<set-cookie> - set cookie. 

Possible attributes: C<value>, C<expires>, C<domain>, C<path>, C<secure>, 
C<max-age>, C<httponly>.

C<secure> attribute can be calculated automatically from request's scheme 
when setting or unsetting cookie if not explicitly set in attributes.

=item B<unset-cookie>

Unsets cookie. It can be one cookie name, list of cookies or hash of cookies 
with their attributes as for C<set-cookie>.

Cookie with attributes can be required when cookie was set with some
attributes like C<domain>, C<path>, C<secure>. 
In this case you have to nail the right cookie.

Usually you don't need to set any attributes and then unset will work 
automatically.

=item B<filter>

Specifies output filter.

=item B<answer>

Sets answer content.

=item B<set-header>

Sets response header. This action ensures that there's only one header 
with given name in response.

=item B<add-header>

Adds response header. This action allows to have multiple headers 
with the same name.

=back

  ---
  params:
    back_url:
      default: headers.referer
  result:
    OK:
      set-cookie:
        auth:
          value: TT response.auth
          expires: TT response.expires
      redirect: /me
    DEFAULT:
      unset-cookie: auth
      redirect: TT request.back_url

Prefix C<TT> means "process this expression with Template-Toolkit language".
This prefix can be used for any attribute value in C<result> section. 

Stash for this processing contains following data fields: 
C<response>, C<form>, C<cookies>, C<context>, C<request>, C<result>.

There're two additional helper functions: C<uri_unescape($uri)> 
and C<session($key)>. $key is optional. 

=head2 Output filter

It's possible to specify filtering function for sending content. 
Attribute C<filter> for given C<result code> in C<result> section 
specifies function that accepts two parameters: ($response, $context).

  ---
  result:
    OK:
      filter: Export::toXML


C<Export::toXML> actually means subroutine C<toXML($response, $context)>
from your module C<${YourApplicationNamespace}::OutFilter::Export>.

$response must be modified "in-place", return value of subroutine is ignored.

Intended application is to transform response to external form, 
like XML, CSV, XLS and so on.

=head2 Model handler

Key C<model> sets calling model handler. 
Model can be "local" or "remote". "Local" means that handler is right 
inside loaded application. "Remote" can mean everything, like 
"call database method". "Remote" model is handled by 
C<cfg_model_rpc($model_handler)>. "Local" is located in some module inside
C<${YourApplicationNamespace}::Local::$Module>.

When you need to call some handler outside of "Local::" namespace, 
prepend its name with 'B<^>', like C<^Some::Lib::Module::handler>.

  ---
  params:
    ip: $ip
    login:
      base: limit40str
      min-size: 1
    password: $limit4_40str
  model: Author::login

#  $project_dir/$app/$Project/Local/Author.pm

  package MyApp::Local::Author;
  sub login {
    my ($req, $context) = @_;
    my $author = one_row(author => {hash_ref_slice $req, qw(login password)})
      or return {result => "PASS"};
    my $auth = PEF::Front::Session::_secure_value;
    new_row( 'author_auth',
      id_author => $author->id_author,
      auth      => $auth,
      expires   => [\"now() + ?::interval", $expires]
    );
    return { 
      result  => "OK",
      expires => $expires,
      auth    => $auth
    };
  }

Model handler that matches /^\^?\w+::/ is "local" otherwise it is "remote".

By default, C<cfg_model_rpc($model_handler)> calls C<PEF::Front::Model::chain_links>
which accepts list of handler functions to execute with optional parameters.
These functions receive C<($req, $context, $previous_response[, $optional_params])>.
Return value from last function is the return value from model handler.

=head2 Method call types

Model method can be called from AJAX or template. 
URI path prefix (C<src> in B<context>) defines how method was called 
and what type of result is expected.

=over

=item B</ajax>

Answer will be in JSON format and redirects from C<result> section are ignored.

=item B</submit>

Answer can be in any format and usually redirects to new location.

=item B</get>

Works like B</submit> but by default parses rest of the path to parameters.
See B<cfg_parse_extra_params($src, $params, $form)> in L<PEF::Front::Config>.

=back

Method that is called from templates has C<src> equal to 'app'.

Key C<allowed_source> can restrict call types: C<template> - for templates;
C<submit> - for C</submit> or C</get>; C<ajax> for C</ajax>. Really useful
distinction is when some method are allowed to be called only from templates.

When this key is absent then there's no restrictions.

=head2 Captcha

It's supposed to be used like this. You make method making captcha images:

Captcha.yaml:

  ---
  params:
    width:
        default: 35
    height:
        default: 40
    size:
        default: 5
  extra_params: ignore
  model: PEF::Front::Captcha::make_captcha

You use it in some template like this: 

  <form method="post" action="/submitSendMessage">
  Captcha:
  [% captcha="captcha".model %]
  <input type="hidden" name="captcha_hash" value="[% captcha.code %]">
  <img src="[% config('www_static_captchas_path') %][% captcha.code %].jpg">
  <input type="text" maxlength="5" name="captcha_code">
   ...
  </form>


SendMessage.yaml:

  ---
  params:
    ip: $ip
    email: $email
    lang: $lang
    captcha_code:
        min-size: 5
        captcha: captcha_hash
    captcha_hash:
        min-size: 5
    subject: $subject
    message: $message
  result:
    OK:
        redirect: /appSentIsOk
  model: Article::add_comment
  allowed_source: [ajax, submit]

Your MyApp::Local::Article::add_comment subroutine must check that 
C<captcha_code> is not equal to 'nocheck' if captcha is required. 
For example, if user is already logged in then it makes little sense to 
enter captcha.

Capthcha image is made by 
C<PEF::Front::Captcha::make_captcha($request, $context)> function. 
This function writes generated images in B<cfg_www_static_captchas_dir>,
stores some information in its own database in B<cfg_captcha_db> and
returns generated md5 sum. When form is submitted, 
validator checks the entered code and when it is right, 
passes to the model method B<"send message">. Captcha code checks are 
destructive: the code is not valid anymore after successful check.

To change generation image class see B<cfg_captcha_image_class> in 
L<PEF::Front::Config>.

=head2 File upload

Uploaded files are stored in some subdirectory in B<cfg_upload_dir>.
Corresponding parameter value is object of L<PEF::Front::File>. 
This parameter can have attribute type 'file' to pass validation.
Array of files can have attribute 'array'. 

Uploaded file should be copied to some permanent storage. Usually you
can just C<link> it to new place. Uploaded files will be deleted
after request destruction. 

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
