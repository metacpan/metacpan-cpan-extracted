package Mojolicious::Plugin::I18N;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::URL;
use I18N::LangTags;
use I18N::LangTags::Detect;

our $VERSION = '1.6';

# "Can we have Bender burgers again?
#  No, the cat shelter’s onto me."
sub register {
	my ($plugin, $app, $conf) = @_;

	# Initialize
	my $namespace = $conf->{namespace} || ( (ref $app) . '::I18N' );
	my $default   = $conf->{default  } || 'en';
	$default =~ tr/-A-Z/_a-z/;
	$default =~ tr/_a-z0-9//cd;

	my $langs     = $conf->{support_url_langs};
	my $hosts     = $conf->{support_hosts    };

	# Default Handler
	my $handler   = sub {
		shift->stash->{i18n} =
			Mojolicious::Plugin::I18N::_Handler->new(namespace => $namespace, default => $default)
		;
	};

	# Add hook
	$app->hook(
		before_dispatch => sub {
			my $self = shift;

			# Handler
			$handler->( $self );

			# Header detection
			my @languages = $conf->{no_header_detect}
				? ()
				: I18N::LangTags::implicate_supers(
					I18N::LangTags::Detect->http_accept_langs(
						$self->req->headers->accept_language
					)
				)
			;

			# Host detection
			my $host = $self->req->headers->header('X-Host') || $self->req->headers->host;
			if ($conf->{support_hosts} && $host) {
				warn $host;
				$host =~ s/^www\.//; # hack
				if (my $lang = $conf->{support_hosts}->{ $host }) {
					$self->app->log->debug("Found language $lang, Host header is $host");

					unshift @languages, $lang;
				}
			}

			# Set default language
			$self->stash(lang_default => $languages[0]) if $languages[0];

			# URL detection
			if (my $path = $self->req->url->path) {
				my $part = $path->parts->[0];

				if ($part && $langs && grep { $part eq $_ } @$langs) {
					# Ignore static files
					return if $self->res->code;

					$self->app->log->debug("Found language $part in URL $path");

					unshift @languages, $part;

					# Save lang in stash
					$self->stash(lang => $part);

					# Clean path
					shift @{$path->parts};
					$path->trailing_slash(0);
				}
			}

			# Languages
			$self->languages(@languages, $default);
    	}
	);

	# Add "languages" helper
	$app->helper(languages => sub {
		my $self = shift;

		$handler->( $self ) unless $self->stash('i18n');

		$self->stash->{i18n}->languages(@_);
	});

	# Add "l" helper
	$app->helper(l => sub {
		my $self = shift;

		$handler->( $self ) unless $self->stash('i18n');

		$self->stash->{i18n}->localize(@_);
	});

	# Reimplement "url_for" helper
	my $mojo_url_for = *Mojolicious::Controller::url_for{CODE};

	my $i18n_url_for = sub {
		my $self = shift;
		my $url  = $self->$mojo_url_for(@_);

		# Absolute URL
		return $url if $url->is_abs;

		# Discard target if present
		shift if (@_ % 2 && !ref $_[0]) || (@_ > 1 && ref $_[-1]);

		# Unveil params
		my %params = @_ == 1 ? %{$_[0]} : @_;

		# Detect lang
		if (my $lang = $params{lang} || $self->stash('lang')) {
			my $path = $url->path || [];

			# Root
			if (!$path->[0]) {
				$path->parts([ $lang ]);
			}

			# No language detected
			elsif ( ref $langs ne 'ARRAY' or not scalar grep { $path->contains("/$_") } @$langs ) {
				unshift @{ $path->parts }, $lang;
			}
		}

		$url;
	};

	{
		no strict 'refs';
		no warnings 'redefine';

		*Mojolicious::Controller::url_for = $i18n_url_for;
	}
}

package Mojolicious::Plugin::I18N::_Handler;
use Mojo::Base -base;

use constant DEBUG => $ENV{MOJO_I18N_DEBUG} || 0;

# "Robot 1-X, save my friends! And Zoidberg!"
sub languages {
	my ($self, @languages) = @_;

	unless (@languages) {
		my $lang = $self->{language};

		# lang such as en-us
		$lang =~ s/_/-/g;

		return $lang;
	}

	# Handle
	my $namespace = $self->{namespace};

	# Load Lang Module
	$self->_load_module($namespace => $_) for @languages;

	if (my $handle = $namespace->get_handle(@languages)) {
		$handle->fail_with(sub { $_[1] });
		$self->{handle}   = $handle;
		$self->{language} = $handle->language_tag;
	}

	return $self;
}

sub localize {
	my $self = shift;
	my $key  = shift;
	return $key unless my $handle = $self->{handle};
	return $handle->maketext($key, @_);
}

sub _load_module {
	my $self = shift;

	my($namespace, $lang) = @_;
	return unless $namespace && $lang;

	# lang such as en-us
	$lang =~ s/-/_/g;

	unless ($namespace->can('new')) {
		DEBUG && warn("Load default namespace $namespace");

		(my $file = $namespace) =~ s{::|'}{/}g;
		eval qq(require "$file.pm");

		if ($@) {
			DEBUG && warn("Create default namespace $namespace");

			eval "package $namespace; use base 'Locale::Maketext'; 1;";
			die qq/Couldn't initialize I18N default class "$namespace": $@/ if $@;
		}
	}

	for ($self->{default}, $lang) {
		my $module = "${namespace}::$_";
		unless ($module->can('new')) {
			DEBUG && warn("Load the I18N class $module");

			(my $file = $module) =~ s{::|'}{/}g;
			eval qq(require "$file.pm");

			my $default = $self->{default};
			if ($@ || not eval "\%${module}::Lexicon") {
				if ($_ eq $default) {
					DEBUG && warn("Create the I18N class $module");

					eval "package ${module}; use base '$namespace';" . 'our %Lexicon = (_AUTO => 1); 1;';
					die qq/Couldn't initialize I18N class "$namespace": $@/ if $@;
				}
			}
		}
	}
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::I18N - Internationalization Plugin for Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('I18N');
  % languages 'de';
  %=l 'hello'

  # Mojolicious::Lite (detect language from URL, i.e. /en/ or /de/)
  plugin I18N => {namespace => 'MyApp::I18N', support_url_langs => [qw(en de)]};
  %=l 'hello'

  # Lexicon
  package MyApp::I18N::de;
  use Mojo::Base 'MyApp::I18N';

  our %Lexicon = (hello => 'hallo');

  1;

=head1 DESCRIPTION

L<Mojolicious::Plugin::I18N> is internationalization plugin for Mojolicious
It works with Mojolicious 4.0+.

Old namespace is L<Mojolicious::Plugin::I18N2>.

=head1 OPTIONS

L<Mojolicious::Plugin::I18N> supports the following options.

=head2 C<support_url_langs>

  plugin I18N => {support_url_langs => [qw(en de)]};

Detect language from URL.

=head2 C<support_hosts>

  plugin I18N => {support_hosts => { 'mojolicious.ru' => 'ru', 'mojolicio.us' => 'en' }};

Detect Host header and use language for that host.

=head2 C<no_header_detect>

  plugin I18N => {no_header_detect => 1};

Off header detect.

=head2 C<default>

  plugin I18N => {default => 'en'};

Default language for i18n, defaults to C<en>.

=head2 C<namespace>

  plugin I18N => {namespace => 'MyApp::I18N'};

Lexicon namespace, defaults to the application class followed by C<::I18N>.

=head1 HELPERS

L<Mojolicious::Plugin::I18N> implements helpers same as L<Mojolicious::Plugin::I18N>.

=head2 C<l>

  %=l 'hello'
  $self->l('hello');

Translate sentence.

=head2 C<languages>

  % languages 'de';
  $self->languages('de');

Change languages.

=head1 METHODS

L<Mojolicious::Plugin::I18N> inherits all methods from L<Mojolicious::Plugin::I18N>
and reimplements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin hooks and helpers in L<Mojolicious> application.

=head1 DEBUG MODE

L<Mojolicious::Plugin::I18N> has debug mode.

  # debug mode on
  BEGIN { $ENV{MOJO_I18N_DEBUG} = 1 };

  # or
  MOJO_I18N_DEBUG=1 perl script.pl

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHORS

2011-2014 Anatoly Sharifulin <sharifulin@gmail.com>

2010-2012 Sebastian Riedel <kraihx@googlemail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-i18n at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.htMail?Queue=Mojolicious-Plugin-I18N>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=over 5

=item * Github

L<http://github.com/sharifulin/mojolicious-plugin-i18n/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.htMail?Dist=Mojolicious-Plugin-I18N>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-I18N>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/Mojolicious-Plugin-I18N>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-I18N>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-I18N>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2014 by Anatoly Sharifulin.
Copyright (C) 2008-2012, Sebastian Riedel.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
