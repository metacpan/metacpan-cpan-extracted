package Rest::HtmlVis::Base;

use 5.006;
use strict;
use warnings FATAL => 'all';

use parent qw( Rest::HtmlVis::Key );

=head1 NAME

Rest::HtmlVis::Base - Return base struct of rest html (menu, styles etc.)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.13';

sub setStruct {
	my ($self, $key, $struct, $env) = @_;
	$self->{struct} = $struct;
	$self->{env} = $env;
	return 1;
}

sub getOrder {
	return 0;
}

sub blocks {
	return 0;
}

my $style = 
'		body {
		  padding: 0px;
		  margin: 0px;
		}

		/* bootstrap-3.3.2-dist */
		.row {
		  margin: 10px 0px 0px 0px;
		}

		.form-control {
			margin-bottom: 4px;
		}

		/* Header styles */
		.header {
		  background-color: #eee;
		  display: inline-block;
		  width: 100%;
		  min-height: 38px;
		  padding: 6px 0px 5px 0px;
		  border: 1px solid #ddd
		}

		/* Header title style */
		.header .title {
		  margin: 9px;
		  display:inline;  
		  text-decoration: none;
		  color: #aaa;
		  font-size: 24px;
		}

		.title .project {
		  color: #ccc;
		}

		/* Format styles */
		.format {
		  float:right;
		  list-style-type: none;
		  margin: 5px 10px 0px 0px;
		  padding: 0px;
		}

		.format li {
		  float:left;
		  border-right: 1px solid #fff;
		  padding: 0px 7px 0px 7px;
		}

		.format li:last-child {
		  border-right: none;
		}

		.format li a {
		  margin-top: 1px;
		  text-decoration: none;
		  color: #ccc;
		  text-transform: uppercase;
		 
		  -webkit-transition: all 0.5s ease;
		  -moz-transition: all 0.5s ease;
		  -o-transition: all 0.5s ease;
		  -ms-transition: all 0.5s ease;
		  transition: all 0.5s ease;
		}
		 
		.format li a:hover {
		  color: #666;
		}
		 
		.format li.active a {
		  font-weight: bold;
		  color: #333;
		}

		/* Links ul */
		.links {
		  list-style-type: none;
		  margin: 5px 0px 0px 10px;
		  padding: 0px;
		  font: 14px/1 Helvetica, Verdana, sans-serif;
		}

		.links li {
		  padding-bottom: 1px;
		}

		.links li a {
		  margin-top: 1px;
		  text-decoration: none;
		  color: #23527c;
		 
		  -webkit-transition: all 0.5s ease;
		  -moz-transition: all 0.5s ease;
		  -o-transition: all 0.5s ease;
		  -ms-transition: all 0.5s ease;
		  transition: all 0.5s ease;
		}
		 
		.links li a:hover {
		  color: #666;
		}
		 
		.links li.active a {
		  font-weight: bold;
		  color: #333;
		}

		.method-form {
		  margin: 7px 0px 5px 0px;
		}

		.links span {
		  color: #aaa;
		}

		/* pretty print */
		pre.prettyprint {
		  padding: 10px;
		  border: 1px solid #ccc;
		}

		.kwd {
		  color: #23527c;
		}

		a {
		  color: #23527c;
		}
';

sub head {
	my ($self, $local) = @_;

	my $static = $self->baseurl;

	return '
	<meta charset="UTF-8">
	<link href="'.$static.'/google-code-prettify/prettify.css" rel="stylesheet">
	<link href="'.$static.'/bootstrap-3.3.2-dist/css/bootstrap.min.css" rel="stylesheet">
	<style>
	'.$style.'
	</style>	

	<meta name="viewport" content="width=device-width, initial-scale=1">

	<script src="'.$static.'/jquery.min.js"></script>
	<script src="'.$static.'/bootstrap-3.3.2-dist/js/bootstrap.min.js"></script>
	<script src="'.$static.'/google-code-prettify/prettify.js"></script>
	<script src="'.$static.'/google-code-prettify/lang-yaml.js"></script>
		';

}

sub html {
	my ($self) = @_;

	my $project = $self->getEnv->{'REST.class'}||$self->getEnv->{'PATH_INFO'}||'';
	my $method = $self->getEnv->{REQUEST_METHOD}||'';
	my $path = $self->getEnv->{SCRIPT_NAME}||'';

"
	<div class=\"header\">
		<div class=\"title\">
			<span class=\"project\">$project:</span>
			<span class=\"method\">$method</span>
			<span class=\"path\">$path</span>
		</div>
		<ul class=\"format\">
			<li><a href=\"?format=application/json\">json</a></li>
			<li><a href=\"?format=text/yaml\">yaml</a></li>
			<li><a href=\"?format=text/plain\">text</a></li>
		</ul>
	</div>
"
}

=encoding utf-8

=head1 AUTHOR

Václav Dovrtěl E<lt>vaclav.dovrtel@gmail.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to github repository.

=head1 ACKNOWLEDGEMENTS

Inspired by L<https://github.com/towhans/hochschober>

=head1 REPOSITORY

L<https://github.com/vasekd/Rest-HtmlVis>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Vaclav Dovrtel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Rest::HtmlVis::Base
