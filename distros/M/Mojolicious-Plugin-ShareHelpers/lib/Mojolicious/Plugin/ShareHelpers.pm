package Mojolicious::Plugin::ShareHelpers;

use strict;
use warnings;

use Mojo::ByteStream 'b';
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.7';

our $APP; # for app instance

has url => sub { +{
	'twitter'   => 'http://twitter.com/share',
	'facebook'  => 'http://facebook.com/sharer.php',
	'vkontakte' => 'http://vk.com/share.php',
	'mymailru'  => 'http://connect.mail.ru/share',
 	'google+'   => 'http://plus.google.com',
} };

sub register {
	my($self, $app) = @_;

	$APP = $app;

	$app->helper( share_url      => sub { $self->share_url     ( @_ ) } );
	$app->helper( share_button   => sub { $self->share_button  ( @_ ) } );
	$app->helper( share_meta     => sub { $self->share_meta    ( @_ ) } );
	$app->helper( is_share_agent => sub { $self->is_share_agent( @_ ) } );
}

sub share_url {
	my($self, $c) = (shift, shift);

	my $type = shift;
	return '' unless $self->_check_type( $type );

	my %args = @_;

	my $param;
	if ($type eq 'twitter') {
		$param->{$_} = $args{$_} for qw(url via text related count lang counturl);
	}
	elsif ($type eq 'facebook') {
		$param->{u} = $args{url };
		$param->{t} = $args{text};
	}
	elsif ($type eq 'vkontakte') {
		$param->{url} = $args{url};
	}
	elsif ($type eq 'mymailru') {
		$param->{share_url} = $args{url};
	}
	elsif ($type eq 'google+') {
		$APP->log->error("Google Plus doen't have share URL, use share_button");
		return '';
	}

	my @p = grep { $param->{$_} } sort keys %$param;
	return join '?', $self->url->{ $type },
		@p ? join '&', map { $_ . '=' . b( $param->{$_} )->url_escape } @p : ()
	;
}

sub share_button {
	my($self, $c) = (shift, shift);

	my $type = shift;
	return '' unless $self->_check_type( $type );

	my %args = @_;

	my $button;
	if ($type eq 'twitter') {
		if ($args{iframe}) {
			my $url    = $c->share_url( $type, @_ );
			my($param) = $url =~ /.*\?(.*)/;

			$button =
				qq(<iframe allowtransparency="true" frameborder="0" scrolling="no" style="width:130px; height:50px;" ) .
				qq(src="http://platform.twitter.com/widgets/tweet_button.html?$param"></iframe>)
			;
		}
		else {
			my $attr; push @$attr, qq(data-$_="$args{$_}")
				for grep { $args{$_} } qw(url via text related count lang counturl);
			my $param = join ' ', @$attr;

			$button =
				qq(<a href="http://twitter.com/share" class="twitter-share-button" $param>Tweet</a>) .
				qq(<script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>)
			;
		}
	}
	elsif ($type eq 'facebook') {
		if ($args{fb}) {
			my $attr  = { type => $args{type}, href => $args{url}, class => $args{class} };
			my $param = join ' ', map { qq($_="$attr->{$_}") } grep { $attr->{$_} } sort keys %$attr;

			$button =
				qq(<fb:share-button $param></fb:share-button>)
			;
		}
		else {
			my $attr  = { type => $args{type}, share_url => $args{url} };
			my $param = join ' ', map { qq($_="$attr->{$_}") } grep { $attr->{$_} } sort keys %$attr;

			$button =
				qq(<a name="fb_share" $param>$args{title}</a>) .
				qq(<script src="http://static.ak.fbcdn.net/connect.php/js/FB.Share" type="text/javascript"></script>)
			;
		}
	}
	elsif ($type eq 'vkontakte') {
		my $url   = $args{url} ? qq({url: "$args{url}"}) : 'false';
		my $attr  = { type => $args{type}, text => $args{title} };
		my $param = join ', ', map { qq($_: "$attr->{$_}") } grep { $attr->{$_} } sort keys %$attr;

		$button =
			qq(<script type="text/javascript" src="http://vk.com/js/api/share.js?146" charset="windows-1251"></script>) .
			qq(<script type="text/javascript">document.write(VK.Share.button($url, {$param}));</script>)
		;
	}
	elsif ($type eq 'mymailru') {
		use utf8;
		my $url = $c->share_url( $type, @_ );

		$args{type } ||= '';
		$args{title} ||= 'В Мой Мир';

		$button =
			qq(<script src="http://cdn.connect.mail.ru/js/share/2/share.js" type="text/javascript"></script>) .
			qq(<a class="mrc__share" type="$args{type}" href="$url">$args{title}</a>)
		;
	}
	elsif ($type eq 'google+') {
		my $attr  = { size => $args{size}, href => $args{url}, count => $args{count}, callback => $args{callback} };
		my $param = join ' ', 'class="g-plusone"', map { qq(data-$_="$attr->{$_}") } grep { $attr->{$_} } sort keys %$attr;

		my $script = join ', ', map { qq($_: "$args{$_}") } grep { $args{$_} } qw(lang parsetags);

		$button =
			(
				$args{noscript}
					? ''
					: qq(<script type="text/javascript" src="https://apis.google.com/js/plusone.js">) . ( $script ? "{$script}" : '' ) . qq(</script>\n)
			) .
			qq(<div $param></div>)
		;
	}

	return $button;
}

sub share_meta {
	my($self, $c) = (shift, shift);
	my %args = @_;

	$_ = b($_)->xml_escape->to_string for grep {$_} @args{qw(title description)};

	return join "\n",
		@_ ? qq(<meta name="medium" content="mult"/>) : '',

		$args{og} ? (
			$args{fb_app_id} ? qq(<meta property="fb:app_id" content="$args{fb_app_id}"/>) : (),
			qq(<meta property="og:site_name" content="$args{site_name}" />),
			qq(<meta property="og:type" content="website" />),
			map { $args{$_} ? qq(<meta property="og:$_" content="$args{$_}"/>) : () }
			qw(image title description)
		) : (),

		$args{title} ? qq(<meta name="title" content="$args{title}"/>) : (),
		$args{description} ? qq(<meta name="description" content="$args{description}"/>) : (),
		$args{image} ? qq(<link rel="image_src" href="$args{image}" />) : (),
		$args{url} ? (
			qq(<link rel="target_url" href="$args{url}"/>),
			qq(<link rel="canonical" href="$args{url}"/>),
		) : (),
	;
}

sub is_share_agent {
	my($self, $c) = (shift, shift);

	my $ua    = $c->req->headers->user_agent;
	my $range = $c->req->headers->header('Range');
	my $enc   = $c->req->headers->header('Accept-Encoding');

	my $agent =
		$ua =~ /facebookexternalhit/ &&  $range &&  $enc eq 'gzip' ? 'facebook'  :
		$ua =~ /Mozilla/             &&  $range &&  $enc =~ /gzip/ ? 'vkontakte' : # XXX: add cp1251
		''
	;

	$APP->log->debug(qq(Found the share agent "$agent")) if $agent;

	return $agent;
}

sub _check_type {
	my $self  = shift;
	my $type  = shift || '';

	if (!$type) {
		$APP->log->debug('Missed the share type');
		return;
	}
	elsif (! exists $self->url->{ $type }) {
		my $types = join ', ', sort keys %{$self->url};
		$APP->log->debug(qq(Bad share type "$type", support types of share: $types));
		return;
	}
	else {
		return $type;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ShareHelpers - A Mojolicious Plugin for generate share urls, buttons and meta for Twitter, Facebook, VKontakte, MyMailRU and Google Plus

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('share_helpers');

  # Mojolicious::Lite
  plugin 'share_helpers';

  # share urls:
  <a href="<%== share_url 'twitter',   url => $url, text => $text, via => 'sharifulin' %>">Share to Twitter</a>
  <a href="<%== share_url 'facebook',  url => $url, text => $text %>">Share to Facebook</a>
  <a href="<%== share_url 'vkontakte', url => $url %>">Share to ВКонтакте</a>
  <a href="<%== share_url 'mymailru',  url => $url %>">Share to Мой Мир</a>

  # share buttons:
  %== share_button 'twitter',   url => 'http://mojolicio.us', text => 'Viva la revolution!', via => 'sharifulin';
  %== share_button 'facebook',  url => 'http://mojolicio.us', type => 'button_count', title => 'Share it';
  %== share_button 'vkontakte', url => 'http://mojolicio.us', type => 'round', title => 'Save';
  %== share_button 'mymailru',  url => 'http://mojolicio.us', type => 'button_count', title => 'Share to Мой Мир';

  # google plus button +1:
  %== share_button 'google+', lang => 'ru'
  %== share_button 'google+', noscript => 1, size => 'tall', url => 'http://mojolicio.us'

  # generate meta for share
  %== share_meta title => 'Mojolicious', description => 'Viva la revolition!', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png'
  %== share_meta title => 'Mojolicious', description => 'Viva la revolition!', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png', og => 1, fb_app_id => 1234567890, site_name => 'Site Name'

  # check share agent, it may returns string such as 'facebook' or 'twitter' or 'vkontakte' or empty string
  %= is_share_agent

=head1 DESCRIPTION

L<Mojolicous::Plugin::ShareHelpers> is a plugin for generate share url, share button and share meta (Twitter, Facebook, VKontakte).

Plugin adds a C<share_url>, C<share_button>, C<share_meta> and C<is_share_agent> helpers to L<Mojolicious>.

=head1 SHARE API

=over 5

=item * Twitter Share L<http://dev.twitter.com/pages/tweet_button>

=item * Facebook Share L<http://developers.facebook.com/docs/share>

=item * VK Share L<http://vk.com/pages.php?act=share>

=item * MyMailRU Share L<http://api.mail.ru/sites/plugins/share/extended/>

=item * Google Plus L<http://code.google.com/intl/ru-RU/apis/+1button/>

=back

=head1 METHODS

L<Mojolicious::Plugin::ShareHelpers> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

	$plugin->register;

Register plugin hooks in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Anatoly Sharifulin <sharifulin@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-sharehelpers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.htMail?Queue=Mojolicious-plugin-sharehelpers>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=over 5

=item * Github

L<http://github.com/sharifulin/Mojolicious-plugin-sharehelpers/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.htMail?Dist=Mojolicious-plugin-sharehelpers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-plugin-sharehelpers>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/Mojolicious-plugin-sharehelpers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-plugin-sharehelpers>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-plugin-sharehelpers>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010-2013 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
