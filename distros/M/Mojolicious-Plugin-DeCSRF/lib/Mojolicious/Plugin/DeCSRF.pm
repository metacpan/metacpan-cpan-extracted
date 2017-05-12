package Mojolicious::Plugin::DeCSRF;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.94';

sub register {
	my ($self, $app, $conf) = @_;

	my $base = Mojolicious::Plugin::DeCSRF::Base->new;
	$base->{token_length} = $conf->{token_length} if $conf->{token_length};
	$base->{token_name} = $conf->{token_name} if $conf->{token_name};
	$base->{on_mismatch} = $conf->{on_mismatch} if $conf->{on_mismatch};
	push @{$base->urls}, $conf->{urls} if $conf->{urls};

	$app->helper(decsrf => sub { $base->c(shift) });

	$app->hook(before_dispatch => sub {
			my $c = shift;
			return $c if $base->c($c)->check;
			if ($base->on_mismatch && ref($base->on_mismatch) eq 'CODE') {
				$base->on_mismatch->($c);
			} else {
				$c->render(
					text => "Forbidden!",
					status => 403,
				);
			}
		}
	);
}

package Mojolicious::Plugin::DeCSRF::Base;

use Mojo::Base -base;

my $_token_checked = 1;
has c => undef;
has token_length => 4;
has token_name => 'token';
has on_mismatch => undef;
has urls => sub { [] };

sub check {
	my $self = shift;
	my $c = $self->c;
	my $token = $c->session($self->token_name);
	$_token_checked = 1;
	if ($self->_match($c->req->url)) 
	{
		return 0 unless (
				$c->req->param($self->token_name) 
				&& $c->req->param($self->token_name) eq $token
			);
	};
	return 1;
}

sub url {
	my $self = shift;
	my $url = shift // '';
	my $c = $self->c;
	if ($_token_checked) {
		$c->session($self->token_name => $self->_token);
		$_token_checked = 0;
	}
	if ($self->_match($url)) {
		return $c->url_for($url)->query([$self->token_name => $c->session($self->token_name)]);
	}
	return $c->url_for($url);
}

sub _match {
	my ($self, $url) = @_;
	if (@{$self->urls} && $url) {
		foreach (@{$self->urls}) {
			return 1 if $self->c->url_for($url)->path =~ m;^$_$;;
		}
	}
	return 0;
}

sub _token {
	my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9, qw(@ $ - _) );
	return join("", @chars[ map { rand @chars } ( 1 .. shift->token_length ) ]);
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::DeCSRF - Defend from CSRF attacks centrally.

=head1 SYNOPSIS

  # Mojolicious::Lite
  #!/usr/bin/env perl
  
  use Mojolicious::Lite;

  plugin 'DeCSRF' => {
    on_mismatch => sub {
      shift->render(template => '503', status => 503);
    },
    token_length => 8,
    token_name => 'csrf',
    urls => qw~/protected~
  };
  
  get '/' => sub {
    my $self = shift;
  } => 'index';
  
  get '/protected' => sub {
    my $self = shift;
  } => 'protected';

  app->start();
  
  __DATA__
  @@ layouts/default.html.ep
  <html>
    <body><%= content %></body>
  </html>
  @@ protected.html.ep
  % layout 'default';
  <a href="<%= decsrf->url('index') %>">Home</a>
  @@ index.html.ep
  % layout 'default';
  <a href="<%= decsrf->url('protected') %>">Protected</a>
  @@ 503.html.ep
  Service error!

=head1 DESCRIPTION

L<Mojolicious::Plugin::DeCSRF> is a L<Mojolicious> plugin that defend the framework from CSRF attacks centrally. With "good" strategy you have flexible control of the urls. "Good" strategy is wrap all of the urls with decsrf->url(URL) and control all urls that must be protected at one place with decsrf->urls(). 

=head1 OPTIONS

Options can change at any time.

=head2 C<< decsrf->on_mismatch >>

Set custom mismatch handling callback. Default is $self->render( text => "Forbidden!", status => 403);     

  decsrf->on_mismatch( sub {
    shift->render(template => '503', status => 503);
  } );

=head2 C<< decsrf->token_length >>

Set custom token length. Default length is 4 symbols from 'A-Z', 'a-z', '0-9', '@', '$', '-', '_' ranges.

  decsrf->token_length(40);

=head2 C<< decsrf->token_name >>

Set custom token name in url and session parameters. Default name is 'token'.

  decsrf->token_name('csrf');

=head2 C<< decsrf->urls >>

Set urls that must be protected. perlre can used.

  decsrf->urls([qw~/protected /.*?ected~]);
  push @{decsrf->urls}, qw~/protected /.*?ected~;

=head1 METHODS

L<Mojolicious::Plugin::DeCSRF> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register();

Register plugin in L<Mojolicious> application.

=head2 C<< decsrf->url >>

Add 'token' param to url that match with decsrf->urls.

  #/protected?token=XXXX
  decsrf->url('/protected');
  
  #/protected?foo=bar&token=XXXX
  decsrf->url('/protected?foo=bar');
  
=head1 AUTHOR

Ilya Tokarev <sysadm@cpan.org>

=head1 COPYRIGHT AND LICENSE 

Copyright (C) 2013, Ilya Tokarev.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
