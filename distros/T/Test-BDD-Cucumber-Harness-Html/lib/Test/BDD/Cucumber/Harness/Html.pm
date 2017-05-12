package Test::BDD::Cucumber::Harness::Html;

use Moose;

# ABSTRACT: html output for Test::BDD::Cucumber
our $VERSION = '1.006'; # VERSION


use Time::HiRes qw ( time );
use Time::Piece;
use Sys::Hostname;
use Template;

use IO::File;
use IO::Handle;

extends 'Test::BDD::Cucumber::Harness::Data';


has 'fh' => ( is => 'rw', isa => 'FileHandle', default => sub { \*STDOUT } );


has all_features => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has current_feature  => ( is => 'rw', isa => 'HashRef' );
has current_scenario => ( is => 'rw', isa => 'HashRef' );
has step_start_at    => ( is => 'rw', isa => 'Num' );

has 'template' => ( is => 'ro', isa => 'Template', lazy => 1,
	default => sub {
		my $self = shift;
      return Template->new(
        ABSOLUTE => 1,
        EVAL_PERL => 1,
      );
	},
);


has 'template_file' => ( is => 'rw', isa => 'Maybe[Str]' );


has 'template_content' => ( is => 'rw', isa => 'Str',
	default => sub {
		my $self = shift;
		my $c = '';
		my $h;
		if( defined $self->template_file ) {
			$h = IO::File->new($self->template_file, 'r')
				or die('error opening output template: '.$!);
		} else {
			$h = IO::Handle->new_from_fd(*DATA,'r')
				or die('error reading default template from __DATA__: '.$!);
		}
		while ( my $line = $h->getline ) {
			$c .= $line;
		}
		$h->close;
		return( $c );
	},
);


has title => ( is => 'rw', isa => 'Str', default => "Test Report");

has 'statistic' => ( is => 'ro', isa => 'HashRef', lazy => 1,
	default => sub {
		my $self = shift;
		return {
			map { $_ => 0 } values %{$self->_output_status},
		};
	},
);

sub feature {
  my ( $self, $feature ) = @_;
  $self->current_feature( $self->format_feature($feature) );
  push @{ $self->all_features }, $self->current_feature;
}

sub scenario {
  my ( $self, $scenario, $dataset ) = @_;
  $self->current_scenario( $self->format_scenario($scenario) );
  push @{ $self->current_feature->{elements} }, $self->current_scenario;
}

sub step {
  my ( $self, $context ) = @_;
  $self->step_start_at( time() );
}

sub step_done {
  my ( $self, $context, $result ) = @_;
  my $duration = time() - $self->step_start_at;
  my $step_data = $self->format_step( $context, $result, $duration );
  my $status = $step_data->{'result'}->{'status'};

  $self->current_feature->{'statistic'}->{ $status }++;
  $self->current_scenario->{'statistic'}->{ $status }++;
  $self->statistic->{ $status }++;

  push @{ $self->current_scenario->{steps} }, $step_data;
}

sub shutdown {
  my ($self) = @_;
  my $html;
  my $template = $self->template_content;
  my $vars = {
    'all_features' => $self->all_features,
    'statistic' => $self->statistic,
    'title' => $self->title,
    'time' => Time::Piece->new(),
    'hostname' => hostname(),
    'command' => join(' ', $0, @ARGV),
  };
  $self->template->process( \$template, $vars, $self->fh )
      or die $self->template->error;
}

sub get_keyword {
  my ( $self, $line_ref ) = @_;
  my ($keyword) = $line_ref->content =~ /^(\w+)/;
  return $keyword;
}

sub format_tags {
  my ( $self, $tags_ref ) = @_;
  return [ map { { name => '@' . $_ } } @$tags_ref ];
}

sub format_description {
  my ( $self, $feature ) = @_;
  return join "\n", map { $_->content } @{ $feature->satisfaction };
}

sub format_feature {
  my ( $self, $feature ) = @_;
  return {
    uri         => $feature->name_line->filename,
    keyword     => $self->get_keyword( $feature->name_line ),
    id          => "feature-" . int($feature),
    name        => $feature->name,
    line        => $feature->name_line->number,
    description => $self->format_description($feature),
    tags        => $self->format_tags( $feature->tags ),
    elements    => [],
    statistic   => { map { $_ => 0 } values %{$self->_output_status} },
  };
}

sub format_scenario {
  my ( $self, $scenario, $dataset ) = @_;
  return {
    keyword => $self->get_keyword( $scenario->line ),
    id      => "scenario-" . int($scenario),
    name    => $scenario->name,
    line    => $scenario->line->number,
    tags    => $self->format_tags( $scenario->tags ),
    type    => $scenario->background ? 'background' : 'scenario',
    steps   => [],
    statistic => { map { $_ => 0 } values %{$self->_output_status} },
  };
}

sub format_step {
  my ( $self, $step_context, $result, $duration ) = @_;
  my $step = $step_context->step;
  my $rand = int( rand() * 10000000);
  return {
    keyword => $step ? $step->verb_original : $step_context->verb,
    keyword_en => $step_context->verb,
    id => "step-".$rand, 
    name => $step_context->text,
    data_text => ref($step_context->data) ? undef : $step_context->data,
    data_table => ref($step_context->data) eq 'ARRAY' ? $step_context->data : undef,
    background => $step_context->background,
    line => $step ? $step->line->number : 0,
    result => $self->format_result( $result, $duration )
  };
}

has '_output_status' => ( is => 'ro', isa => 'HashRef', lazy => 1,
  default => sub { {
    passing   => 'passed',
    failing   => 'failed',
    pending   => 'pending',
    undefined => 'skipped',
  } },
);

sub format_result {
  my ( $self, $result, $duration ) = @_;
  my $ret;

  if( $result ) {
    $ret = {
      status        => $self->_output_status->{ $result->result },
      error_message => $result->output,
      defined $duration
        ? ( duration => int( $duration * 1_000_000_000 ) )
        : (),    # nanoseconds
    };
  } else {
  	$ret = { status => "undefined" };
  }

  return $ret;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Cucumber::Harness::Html - html output for Test::BDD::Cucumber

=head1 VERSION

version 1.006

=head1 DESCRIPTION

A L<Test::BDD::Cucumber::Harness> subclass that generates html reports.

=head1 EXAMPLE USAGE

  $ pherkin -o Html features/ > test-report.html

=head1 EXAMPLE OUTPUT

The default template uses bootstrap CSS for formatting.

Example test reports from the L<Test::BDD::Cucumber> examples
are included in the distribution tar ball or can be viewed online at:

=over

=item Calculator example

L<https://markusbenning.de/cucumber-html-examples/calculator-report.html>

=item Digest example

L<https://markusbenning.de/cucumber-html-examples/digest-report.html>

=back

=head1 HOW IT WORKS

All report data is gathered and stored in $self->all_features.

For HTML generation a L<Template> style template file is used.

A templated based on bootstrap formating is included in the DATA section of the module
an will be used by default.

=head1 CONFIGURABLE ATTRIBUTES

=head2 fh

A filehandle to write output to; defaults to C<STDOUT>

=head2 all_features

An Array holding a data structure with the results.

=head2 template_file (default: undef)

A path to a Template Toolkit template file to use for generating the HTML report.

If no path is given the content will be read from the DATA section of the module containing
the default template.

=head2 template_content (default: undef)

The source code of the Template Toolkit template.

If no content is given it will be read from a file or the DATA section. (see template_file)

=head2 title (default: Test Report)

This could be used to set a title for the generated report.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
[% PERL -%]
$stash->set( 'map_bootstrap_class', sub {
	my $status = shift;
	my $map = {
		'passed' => 'success',
		'skipped' => 'info',
		'failed' => 'danger',
		'pending' => 'warning',
		'given' => 'success',
		'when' => 'info',
		'then' => 'warning',
	};
	return( $map->{ $status } );
} );
[% END -%]
[% BLOCK statistic_tags -%]
[% FOREACH status = [ 'passed', 'failed', 'pending', 'skipped' ] -%]
	[% IF s.$status -%]
<button type="button" class="btn [% size ? 'btn-' _ size : '' %] btn-[% map_bootstrap_class(status) %]" data-toggle="tooltip" data-placement="right" title="[% status %]">[% s.$status %]</button>
	[% END -%]
[% END -%]
[% END -%]
[% BLOCK statistic -%]
<table class="table table-bordered">
<thead>
  <th>Status</th>
  <th>Count</th>
</thead>
<tbody>
  <tr class="[% s.passed ? map_bootstrap_class('passed') : '' %]">
  	<td>Passed</td><td>[% s.passed %]</td>
  </tr>
  <tr class="[% s.failed ? map_bootstrap_class('failed') : '' %]">
  	<td>Failed</td><td>[% s.failed %]</td>
  </tr>
  <tr class="[% s.pending ? map_bootstrap_class('pending') : '' %]">
  	<td>Pending</td><td>[% s.pending %]</td>
  </tr>
  <tr class="[% s.skipped ? map_bootstrap_class('skipped') : '' %]">
  	<td>Skipped</td><td>[% s.skipped %]</td>
  </tr>
</tbody>
</table>
[% END -%]
[% BLOCK toc -%]
<ul>
[% FOREACH f = all_features -%]
  <li><a href="#[% f.id %]">[% f.name FILTER html %]</a>[% INCLUDE statistic_tags s=f.statistic size='xs' %]</li>
  <ul>
  [% FOREACH s = f.scenarios -%]
    <li><a href="#[% s.id %]">[% s.name FILTER html %]</a>[% INCLUDE statistic_tags s=s.statistic size='xs' %]</li>
  [% END -%]
  </ul>
[% END -%]
</ul>
[% END -%]
[% BLOCK scenario -%]
<h3 id="[% s.id %]">[% s.name FILTER html %]</h3>
<div class="panel-group" id="[% s.id %]-accordion">
[% FOREACH step = s.steps -%]
<div class="panel panel-[% map_bootstrap_class(step.result.status) %]">
	<div class="panel-heading"><a data-toggle="collapse" data-target="#[% step.id %]-body">
<b class="text-[% map_bootstrap_class(step.keyword_en) %]">[% step.keyword %]</b> [% step.name FILTER html %]

<div class="step-line">([% step.background ? 'background, ' : '' %]line: [% step.line %])</div>
<div class="step-result">[% step.result.status %]</div>
	</a></div>
	<div id="[% step.id %]-body" class="panel-collapse collapse[% step.result.status == 'failed' ? ' in' : '' %]"><div class="panel-body">
[% IF step.result.error_message -%]
<h4>Test Output:</h4>
<pre>[% step.result.error_message FILTER html %]</pre>
[% END -%]
[% IF step.data_text -%]
<h4>Example Data:</h4>
<pre>[% step.data_text FILTER html %]</pre>
[% END -%]
	</div></div>
</div>
[% END -%]
</div>
[% END -%]
[% BLOCK feature -%]
<h2 id="[% f.id %]">[% f.name FILTER html %] <small>([% f.uri %]) [% INCLUDE statistic_tags s=f.statistic %]</small></h2>
<pre><code>[% f.description FILTER html %]</code></pre>
[% FOREACH scenario = f.scenarios -%]
    [% INCLUDE scenario s=scenario -%]
[% END -%]
[% END -%]
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="[% title %]">

    <title>[% title %]</title>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
    <style type="text/css">
    .step-name { display: inline; text-align: left; }
    .step-line { display: inline; text-align: left; color: grey; }
    .step-result { float: right; display: inline; color: black; }
    .panel-heading a { color: black; }
    .panel-heading a:before {
        font-family: 'Glyphicons Halflings';
        content: "\e114";    
     }
     .panel-heading a.collapsed:before {
         content: "\e080";
     }
    </style>
  </head>

  <body>
    <div class="container">

      <div class="page-header"><h1>[% title %]</h1></div>

      <h2>Document meta information</h2>
      <table class="table table-bordered">
      	<thead>
	  <th>Key</th>
	  <th>Value</th>
	</thead>
	<tbody>
	  <tr><td>Hostname</td><td>[% hostname %]</td></tr>
	  <tr><td>Time</td><td>[% time %]</td></tr>
	  <tr><td>Command</td><td>[% command %]</td></tr>
	</tbody>
      </table>

      <h2>Summary</h2>
[% INCLUDE statistic s=statistic -%]
      <h2>Table of Content</h2>
[% INCLUDE toc %]

[% FOREACH feature = all_features -%]
        [% INCLUDE feature f=feature -%]
[% END -%]

    </div> <!-- /container -->
  </body>
</html>
