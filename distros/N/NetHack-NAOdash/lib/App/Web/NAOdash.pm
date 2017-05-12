package App::Web::NAOdash;

use 5.014000;
use strict;
use warnings;
use re '/saa';
use parent qw/Plack::Component/;

our $VERSION = '0.003';

use Digest::SHA qw/sha256_base64/;
use File::Slurp;
use HTML::TreeBuilder;
use JSON::MaybeXS qw/encode_json/;
use NetHack::NAOdash qw/naodash_user/;
use Plack::Request;

my ($dash, $css, $css_hash);

{
	$css = read_file 'web/dash.css';
	$css =~ y/\n\t//d;
	$css =~ s/([):]) /$1/g;
	$css =~ s/ ([{(])/$1/g;
	$css_hash = 'sha256-' . sha256_base64($css) . '=';
	my $tb = HTML::TreeBuilder->new;
	$tb->ignore_unknown(0);
	$dash = $tb->parse_file('web/dash.html');
	$dash->find('link')->postinsert([style => $css])->detach;
}

sub format_time {
	my ($time) = @_;
	return unless defined $time;
	my %units = (
		s => 60,
		m => 60,
		h => 24,
		d => 7,
		w => 1e9,
	);
	my @parts;
	for (qw/s m h d w/) {
		use integer;
		last unless $time;
		unshift @parts, ($time % $units{$_}) . $_;
		$time /= $units{$_};
	}
	join ' ', @parts;
}

sub make_html {
	my ($name, $query, $result) = @_;
	my @checks = @{$result->{checks}};
	my %numbers = %{$result->{numbers}};
	$numbers{totalrealtime} = format_time $numbers{totalrealtime};
	$numbers{minrealtime} = format_time $numbers{minrealtime};

	my $tree = $dash->clone;
	$tree->find('title')->delete_content->push_content("Dashboard for $name");
	$tree->find('a')->attr(href => $tree->find('a')->attr('href') . $name);
	$tree->find('a')->delete_content->push_content($name);
	for (@checks) {
		my $el = $tree->look_down(id => $_);
		warn "No element for check $_" unless $el; ## no critic (RequireCarping)
		$el->attr(class => 'done') if $el;
	}
	while (my ($id, $num) = each %numbers) {
		next unless defined $num;
		my $el = $tree->look_down(id => $id);
		warn "No element for check $id" unless $el; ## no critic (RequireCarping)
		$el->delete_content->push_content($num);
	}
	my $ahref = $tree->look_down(href => "?$query");
	$ahref->replace_with(join '', $ahref->content_list) if $ahref;
	$tree->as_HTML;
}

sub reply {
	my ($code, $message, $type) = @_;
	$type //= 'text/plain';
	[$code, [
		'Cache-Control' => ($code < 500 ? 'max-age=86400' : 'no-cache'),
		'Content-Type' => "$type; charset=utf-8",
		'Content-Length' => length $message,
# Safari implements CSP Level 1 but not CSP Level 2
#		'Content-Security-Policy' => "default-src 'none'; style-src '$css_hash';",
	], [$message]]
}

sub call {
	my ($self, $env) = @_;
	my $req = Plack::Request->new($env);
	return reply 400, 'Bad request: user contains characters outside [a-zA-Z0-9_]' unless $req->path =~ m{^/(\w+)$};
	my $name = $1;
	my %args = (
		include_versions => [$req->query_parameters->get_all('include_versions')],
		exclude_versions => [$req->query_parameters->get_all('exclude_versions')],
	);
	my $result = eval { naodash_user \%args, $name } or return reply 500, $@;

	return reply 200, encode_json($result), 'application/json' if $self->{json};
	return reply 200, make_html($name, $req->query_string, $result), 'text/html';
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Web::NAOdash - Analyze NetHack xlogfiles and extract statistics (web interface)

=head1 SYNOPSIS

  # In app.psgi
  use App::Web::NAOdash;
  use Plack::Builder;

  builder {
    mount '/dash/' => App::Web::NAOdash->new->to_app;
    mount '/json/' => App::Web::NAOdash->new(json => 1)->to_app;
    ...
  }

=head1 DESCRIPTION

App::Web::NAOdash is a web interface to L<NetHack::NAOdash>.

It handles URLs of the form C</username>, where I<username> is a NAO
username. It retrieves the xlogfile from NAO and returns the result of
the analysis.

Two query parameters are accepted: include_versions and
exclude_versions, both of which can take multiple values by
specifiying them multiple times. They are passed directly to the
B<naodash_user> function, see the documentation of L<NetHack::NAOdash>
for an explanation of their function.

The constructor takes a single named parameter, I<json>, that is false
by default. The result will be returned as HTML is I<json> is false,
as JSON if I<json> is true.

=head1 SEE ALSO

L<NetHack::NAOdash>, L<App::NAOdash>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
