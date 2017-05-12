package Plack::Middleware::FormatOutput;

use 5.006;
use strict;
use warnings FATAL => 'all';

use parent qw( Plack::Middleware );
use Plack::Util;

use HTTP::Exception '4XX';

use JSON::XS;
use YAML::Syck;
use URI::Escape::XS qw/decodeURIComponent/;
use Encode; 
our $VERSION = '0.10'; # is set automagically with Milla 

$YAML::Syck::ImplicitUnicode = 1;

### Try load library
sub _try_load {
	my $mod = shift;
	eval("use $mod; 1") ? return 1 : return 0;
}

### Set default mime types
my $MIME_TYPES = {
	'application/json'   => sub { JSON::XS->new->utf8->allow_nonref->encode($_[0]) },
	'text/yaml'          => sub { 
		local $Data::Dumper::Indent=1; local $Data::Dumper::Quotekeys=0; local $Data::Dumper::Terse=1; local $Data::Dumper::Sortkeys=1;
		Dump($_[0]) 
	},
	'text/plain'         => sub { 
		local $Data::Dumper::Indent=1; local $Data::Dumper::Quotekeys=0; local $Data::Dumper::Terse=1; local $Data::Dumper::Sortkeys=1;
		Dump($_[0]) 
	},
	'text/html'   => sub {
		my ($data, $self, $env, $header) = @_;
		if ($self->htmlvis){
			my $ret = $self->htmlvis->html($data, $env, $header); #struct, env
			return Encode::encode_utf8($ret) if $ret;
		}
		return JSON::XS->new->utf8->allow_nonref->encode($data); # Just show content
	}
};

sub prepare_app {
	my $self = shift;

	### Check mime types
	foreach my $par (keys %{$self->{mime_type}}){
		delete $self->{mime_type}{$par} if ref $self->{mime_type}{$par} ne 'CODE';
	}

	### Add default MimeTypes
	foreach my $par (keys %{$MIME_TYPES}){
		$self->{mime_type}{$par} = $MIME_TYPES->{$par} unless exists $self->{mime_type}{$par};
	}

	### Add htmlvis
	if (_try_load('Rest::HtmlVis')){
		my $params = $self->{htmlvis} if exists $self->{htmlvis};
		$self->{htmlvis} = Rest::HtmlVis->new($params);
	}
}

sub mime_type {
	return $_[0]->{mime_type};
}

sub htmlvis {
	return $_[0]->{htmlvis};
}

sub call {
	my($self, $env) = @_;

	### Run app
	my $res = $self->app->($env);

	### Get accept from request header 
	my $accept = _getAccept($self, $env);
	return $res unless $accept;

	### Return handler that manage response
	return Plack::Util::response_cb($res, sub {
		my $res = shift;
		if ( !Plack::Util::status_with_no_entity_body( $res->[0] ) && defined $res->[2] ){

			### File handler streaming body
			if ( Plack::Util::is_real_fh($res->[2]) ) {
				return 
			}

			### Set header
			if ($res->[1] && @{$res->[1]}){
				Plack::Util::header_set($res->[1], 'Content-Type', $accept);
			}else{
				$res->[1] = ['Content-Type', $accept];
			}

			### Convert data
			$res->[2] = [$self->mime_type->{$accept}->($res->[2], $self, $env, $res->[1])];
		}elsif(! defined $res->[2]){
			$res->[2] = []; # backward compatibility
		}
		return $res;
	});
}

sub _getAccept {
	my ($self, $env) = @_;

	# Get accept from url
	my $accept;
	# We parse this with reqular because we need this as quick as possible
	my $query_string  = decodeURIComponent($env->{QUERY_STRING});
	if ( $query_string=~/format=([\w\/\+]*)/){
		if (exists $self->mime_type->{$1}){
			$accept = $1;
		}
	};

	# Set accept by http header
	if (!$accept && $env->{HTTP_ACCEPT}){
		foreach (split(/,/, $env->{HTTP_ACCEPT})){
			if ($_ eq '*/*'){
				$accept = exists $self->mime_type->{'text/html'} ? 'text/html' : undef;
				last;
			}
			next unless exists $self->mime_type->{$_};
			$accept = $_;
			last;
		}
	}

	return ($accept||'application/json');
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::FormatOutput - Format output struct by Accept header.

=head1 SYNOPSIS

	use Plack::Middleware::FormatOutput;

	builder {
		enable 'FormatOutput';
		mount "/api" => sub { return [200, undef, {'link' => 'content'}] };
	};

=head1 DESCRIPTION

The Middleware formats output perl struct by "Accept" header param or by format param in URL.

You can get json when define:

=over 4

=item * Accept header application/json

or

=item * Add ?format=application/json to URL

=back

For complete RestAPI in Perl use: 

=over 4

=item * Plack::App::REST

=item * Plack::Middleware::ParseContent

=back

=head1 CONSTANTS

=head2 DEFAULT MIME TYPES

=over 4

=item * application/json

=item * text/yaml

=item * text/plain

=item * text/html - it uses Rest::HtmlVis as default formatter if installed

=back

=head1 PARAMETERS

=head2 mime_type

Specify if and how returned content should be formated in browser.

For example:

	use Plack::Middleware::FormatOutput;
	use My::HTML

	builder {
		enable 'FormatOutput', mime_type => {
			'text/html' => sub{ My::HTML::Parse(@_) }
		};
		mount "/api" => sub { return [200, undef, {'link' => 'content'}] };
	};

=head2 htmlvis (if Rest::HtmlVis is installed)

Define parameters for Rest::HtmlVis. 

For example:

	use Plack::Middleware::FormatOutput;

	builder {
		enable 'FormatOutput', htmlvis => {
			links => 'My::Links'
		};
		mount "/api" => sub { return [200, undef, {'links' => 'content'}] };
	};

=head1 TUTORIAL

L<http://psgirestapi.dovrtel.cz/>

=head1 AUTHOR

Václav Dovrtěl E<lt>vaclav.dovrtel@gmail.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to github repository.

=head1 ACKNOWLEDGEMENTS

Inspired by L<https://github.com/towhans/hochschober>

=head1 REPOSITORY

L<https://github.com/vasekd/Plack-Middleware-FormatOutput>

=head1 COPYRIGHT

Copyright 2015- Václav Dovrtěl

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
