package Rest::HtmlVis;

use 5.008_005;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.13'; # Set automatically by milla

my $based = {
	'default.base' => 'Rest::HtmlVis::Base',
	'default.content' => 'Rest::HtmlVis::Content',
	'default.footer' => 'Rest::HtmlVis::Footer',
};

sub new {
	my ($class, $params) = @_;

	my $htmlVis;

	my $self = bless {}, $class;

	### Set uri path
	$self->{baseurl} = "/static";
	# Don't delete key, because of original hash
	$self->{baseurl} = $params->{'default.baseurl'} if exists $params->{'default.baseurl'};

	### Add htmlvis
	foreach my $key (sort keys %$params){
		next if $key eq 'default.baseurl';
		$self->loadVisObject($key, $params->{$key});
	}

	### Set params
	foreach my $key (sort keys %$based) {
		$self->loadVisObject($key, $based->{$key}) unless exists $params->{$key};
	}

	return $self;
}

sub baseurl {
	my ($self) = shift;
	return $self->{baseurl};
}

sub loadVisObject {
	my ($self, $key, $class) = @_;

	my ($rtrn, $err) = _try_load($class);
	if ($rtrn){
		my $vis = $class->new($self->baseurl);
		my $order = $vis->getOrder;
		push(@{$self->{htmlVis}{$order}}, {
			key => $key,
			object => $vis
		}) if $vis->isa('Rest::HtmlVis::Key');
	}else{
		print STDERR "ERROR: to load vis class: ".$err."\n";
	}
}

sub html {
	my ($self, $struct, $env, $header) = @_;

	### manage keys
	my $head_parts = '';
	my $onload_parts = '';
	my $html_parts = '';
	my $footer_parts = '';

	my $rowBlocks = 0; # count number of blocks in row

	### Add blocks
	foreach my $order (sort keys %{$self->{htmlVis}}) {
		foreach my $obj (@{$self->{htmlVis}{$order}}) {

			my $vis = $obj->{object};
			next unless $vis->setStruct($obj->{key}, $struct, $env);
			$vis->setHeader($header);

			my $head = $vis->head($self->{local});
			$head_parts .= $head if $head;

			my $onload = $vis->onload();
			$onload_parts .= $onload if $onload;

			my $html = $vis->html();
			if ($html){
				$rowBlocks += $vis->blocks();
				my $newRow = ($vis->newRow() or $rowBlocks > 12) ? 1 : 0;

				$html_parts .= '<div class="row">' if $newRow;
				$html_parts .= $html;
				$html_parts .= '</div>' if $newRow;
				$rowBlocks = 0 if $newRow;
			}
			my $footer = $vis->footer($self->{local});
			$head_parts .= $footer if $footer;
		}
	}

	return "<!DOCTYPE html>\n<html>\n<head>\n$head_parts\n</head>\n<body onload=\"$onload_parts\">\n$html_parts\n</body>\n</html>";
}

### Try load library
sub _try_load {
	my $mod = shift;

	return +(0, "Not defined module.") unless $mod;
	return 1 if ($mod->can("html")); # because of local class in psgi
	eval("use $mod; 1") ? return 1 : return (0, $@);
}

1;

=encoding utf-8

=head1 NAME

Rest::HtmlVis - Rest API visualizer in HTML

=head1 SYNOPSIS

Transform perl hash to html.
Each key in perl hash is transormed to the piece of html, js and css which are include in main html.

Example:

	use Rest::HtmlVis;

	my $htmlvis = Rest::HtmlVis->new({
		events => Rest::HtmlVis::Events
	});

	$htmlvis->html({

		events => [
		],

		links => {
			rel => 'root',
			href => /,
			name => Root resource
		}

		form => {
			GET => {
				from => {
					type => 'time',
					default => time(),
				}
			},
			POST => {
				DATA => {
					type => "text"
					temperature => 25
				},

			}
		}
	});


HtmlVis has default blocks that are show everytime:

=over 4

=item * default.baseurl

Set default prefix for links in html. Default is '/static'

=item * default.base

See L<Rest::HtmlVis::Base>.

=item * default.content

See L<Rest::HtmlVis::Content>.

=back

These blocks can be rewrite when the base or content key is set in constructor params.

=head1 SUBROUTINES/METHODS

=head2 new( params )

Create new htmlvis object. You have to specify params for keys that should be transformed.

=head3 params

Define keys in input hash and library that manage this key.

Example:

	{ events => Rest::HtmlVis::Events }   

Third-party js library are primary mapped to /static URL.
You have to manage this url by your http server and map this url to share directory.
For example in Plack:
	
	use File::ShareDir;
	my $share = File::ShareDir::dist_dir('Rest-HtmlVis') || "../Rest-HtmlVis/share/";
	mount "/static" => Plack::App::File->new(root => $share);

=cut

=head2 html( hash_struct )

Convert input hash struct to html. Return html string.

=cut

=head1 TUTORIAL

L<http://psgirestapi.dovrtel.cz/>

=head1 AUTHOR

Václav Dovrtěl E<lt>vaclav.dovrtel@gmail.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to github repository.

=head1 ACKNOWLEDGEMENTS

Inspired by L<https://github.com/towhans/hochschober>

=head1 COPYRIGHT

Copyright 2015- Václav Dovrtěl

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
