#!/usr/bin/env perl
use lib qw(lib ../mojo/lib);

BEGIN { $ENV{MOJO_NO_BONJOUR}++ };
use Mojolicious::Lite;

app->log->level('error');

plugin 'share_helpers';

get '/'    => 'index';
get '/bad' => 'bad';
get "/$_"  => $_ for qw(twitter facebook vkontakte mymailru google+ google+all meta);

get '/ua'  => sub {
	my $self = shift;
	$self->render('ua', check => $self->is_share_agent);
};

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/bad')
  ->status_is(200)
  ->content_is(join "\n", ('') x 6)
;

$t->get_ok('/twitter')
  ->status_is(200)
  ->content_is(join "\n",
	q(http://twitter.com/share?text=Viva%20la%20revolution%21&url=http%3A%2F%2Fmojolicio.us),
	q(<a href="http://twitter.com/share" class="twitter-share-button" data-url="http://mojolicio.us" data-via="sharifulin" data-text="Viva la revolution!">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>),
	q(<iframe allowtransparency="true" frameborder="0" scrolling="no" style="width:130px; height:50px;" src="http://platform.twitter.com/widgets/tweet_button.html?text=Viva%20la%20revolution%21&url=http%3A%2F%2Fmojolicio.us"></iframe>),
	''
);

$t->get_ok('/facebook')
  ->status_is(200)
  ->content_is(join "\n",
	q(http://facebook.com/sharer.php?t=Viva%20la%20revolution%21&u=http%3A%2F%2Fmojolicio.us),
	q(<a name="fb_share" share_url="http://mojolicio.us" type="button_count">Share it</a><script src="http://static.ak.fbcdn.net/connect.php/js/FB.Share" type="text/javascript"></script>),
	q(<fb:share-button href="http://mojolicio.us" type="icon"></fb:share-button>),
	''
);

$t->get_ok('/vkontakte')
  ->status_is(200)
  ->content_is(join "\n",
	q(http://vk.com/share.php?url=http%3A%2F%2Fmojolicio.us),
	q(<script type="text/javascript" src="http://vk.com/js/api/share.js?146" charset="windows-1251"></script><script type="text/javascript">document.write(VK.Share.button({url: "http://mojolicio.us"}, {text: "Save", type: "round"}));</script>),
	q(<script type="text/javascript" src="http://vk.com/js/api/share.js?146" charset="windows-1251"></script><script type="text/javascript">document.write(VK.Share.button(false, {text: "Save", type: "custom"}));</script>),
	''
);

$t->get_ok('/mymailru')
  ->status_is(200)
  ->content_is(join "\n",
	q(http://connect.mail.ru/share?share_url=http%3A%2F%2Fmojolicio.us),
	q(<script src="http://cdn.connect.mail.ru/js/share/2/share.js" type="text/javascript"></script><a class="mrc__share" type="button_count" href="http://connect.mail.ru/share?share_url=http%3A%2F%2Fmojolicio.us">Save</a>),
	q(<script src="http://cdn.connect.mail.ru/js/share/2/share.js" type="text/javascript"></script><a class="mrc__share" type="button_count" href="http://connect.mail.ru/share">Save</a>),
	''
);

$t->get_ok('/google+')
  ->status_is(200)
  ->content_is(join "\n",
	q(<script type="text/javascript" src="https://apis.google.com/js/plusone.js">{lang: "ru"}</script>),
	q(<div class="g-plusone"></div>),
	q(<div class="g-plusone" data-href="http://mojolicio.us" data-size="tall"></div>),
	''
);

$t->get_ok('/google+all')
  ->status_is(200)
  ->content_is(join "\n",
	q(<script type="text/javascript" src="https://apis.google.com/js/plusone.js"></script>
<div class="g-plusone"></div>
<div class="g-plusone"></div>
<div class="g-plusone" data-href="http://mojolicio.us" data-size="tall"></div>
<div class="g-plusone" data-count="false" data-href="http://mojolicio.us" data-size="standard"></div>
<div class="g-plusone" data-callback="GooglePlusCallback" data-count="false" data-href="http://mojolicio.us" data-size="standard"></div>
<script type="text/javascript" src="https://apis.google.com/js/plusone.js">{lang: "ru"}</script>
<div class="g-plusone" data-size="small"></div>
<script type="text/javascript" src="https://apis.google.com/js/plusone.js">{lang: "ru", parsetags: "explicit"}</script>
<div class="g-plusone" data-size="small"></div>
)
);

$t->get_ok('/meta')
  ->status_is(200)
  ->content_is(join "\n",
	'',
	q(<meta name="medium" content="mult"/>
<meta name="title" content="Mojolicious"/>
<meta name="description" content="Viva la revolition!"/>
<link rel="image_src" href="http://mojolicious.org/webinabox.png" />
<link rel="target_url" href="http://mojolicio.us"/>
<link rel="canonical" href="http://mojolicio.us"/>
<meta name="medium" content="mult"/>
<meta property="fb:app_id" content="1234567890"/>
<meta property="og:site_name" content="Site Name" />
<meta property="og:type" content="website" />
<meta property="og:image" content="http://mojolicious.org/webinabox.png"/>
<meta property="og:title" content="&quot;Mojolicious&quot;"/>
<meta property="og:description" content="&quot;Viva la revolition!&quot;"/>
<meta name="title" content="&quot;Mojolicious&quot;"/>
<meta name="description" content="&quot;Viva la revolition!&quot;"/>
<link rel="image_src" href="http://mojolicious.org/webinabox.png" />
<link rel="target_url" href="http://mojolicio.us"/>
<link rel="canonical" href="http://mojolicio.us"/>
)
);

# for html test

$t->get_ok('/')
  ->status_is(200)
  ->tx->res->body
;

# check user agent

$t->get_ok('/ua')
  ->status_is(200)
  ->content_is("\n")
;

$t->get_ok('/ua', {'User-Agent' => 'facebookexternalhit', 'Range' => 1, 'Accept-Encoding' => 'gzip'})
  ->status_is(200)
  ->content_is("facebook\n", 'Facebook share agent')
;

$t->get_ok('/ua', {'User-Agent' => 'Mozilla', 'Range' => 1, 'Accept-Encoding' => 'gzip, deflate'})
  ->status_is(200)
  ->content_is("vkontakte\n", 'VKontakte share agent')
;

done_testing;

__DATA__

@@ bad.html.ep

%== share_url
%== share_url url => 'sss'

%== share_button
%== share_button 'sdsdsd'

@@ twitter.html.ep

%== share_url    'twitter', url => 'http://mojolicio.us', text => 'Viva la revolution!';
%== share_button 'twitter', url => 'http://mojolicio.us', text => 'Viva la revolution!', via => 'sharifulin';
%== share_button 'twitter', url => 'http://mojolicio.us', text => 'Viva la revolution!', iframe => 1;

@@ facebook.html.ep

%== share_url    'facebook', url => 'http://mojolicio.us', text => 'Viva la revolution!';
%== share_button 'facebook', url => 'http://mojolicio.us', type => 'button_count', title => 'Share it';
%== share_button 'facebook', url => 'http://mojolicio.us', type => 'icon', fb => 1;

@@ vkontakte.html.ep

%== share_url    'vkontakte', url => 'http://mojolicio.us';
%== share_button 'vkontakte', url => 'http://mojolicio.us', type => 'round', title => 'Save';
%== share_button 'vkontakte', type => 'custom', title => 'Save';


@@ mymailru.html.ep

%== share_url    'mymailru', url => 'http://mojolicio.us';
%== share_button 'mymailru', url => 'http://mojolicio.us', type => 'button_count', title => 'Save';
%== share_button 'mymailru', type => 'button_count', title => 'Save';

@@ google+.html.ep

%== share_button 'google+', lang => 'ru'
%== share_button 'google+', noscript => 1, size => 'tall', url => 'http://mojolicio.us'

@@ google+all.html.ep

%== share_button 'google+'
%== share_button 'google+', noscript => 1
%== share_button 'google+', noscript => 1, size => 'tall', url => 'http://mojolicio.us'
%== share_button 'google+', noscript => 1, size => 'standard', url => 'http://mojolicio.us', count => 'false'
%== share_button 'google+', noscript => 1, size => 'standard', url => 'http://mojolicio.us', count => 'false', callback => 'GooglePlusCallback'
%== share_button 'google+', size => 'small', lang => 'ru'
%== share_button 'google+', size => 'small', lang => 'ru', parsetags => 'explicit'

@@ meta.html.ep

%== share_meta;
%== share_meta title => 'Mojolicious', description => 'Viva la revolition!', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png';
%== share_meta title => '"Mojolicious"', description => '"Viva la revolition!"', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png', og => 1, fb_app_id => 1234567890, site_name => 'Site Name';

@@ index.html.ep

%== include 'meta'

% for (qw(twitter facebook vkontakte mymailru)) {
<p>
	%== include $_
</p>
% }

@@ ua.html.ep

%= $check
