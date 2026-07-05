package Test::CPAN::Health::Reporter::JSON;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);
use JSON::MaybeXS qw(JSON);
use Params::Validate::Strict qw(validate_strict);
use Scalar::Util qw(blessed);

our $VERSION = '0.1.0';

=head1 NAME

Test::CPAN::Health::Reporter::JSON - Render a health report as a JSON document

=head1 SYNOPSIS

    use Test::CPAN::Health::Reporter::JSON;

    my $reporter = Test::CPAN::Health::Reporter::JSON->new(pretty => 1);
    print $reporter->render($report);

=head1 DESCRIPTION

Serialises a L<Test::CPAN::Health::Report> to a JSON document via
L<JSON::MaybeXS>.  Suitable for piping to other tools, CI artifact storage,
or consuming from scripts.

The emitted structure mirrors C<< $report->as_hash >>.

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {
			pretty    => { type => 'scalar', optional => 1, default => 0 },
			canonical => { type => 'scalar', optional => 1, default => 1 },
		},
		input => \%args,
	) };

	my $json = JSON()->new->utf8(1)
		->canonical($args{canonical})
		->pretty($args{pretty});

	my $self = bless {
		_json => $json,
	}, $class;

	return $self;
}

=head2 render

=head3 PURPOSE

Serialise a Report to a JSON string.

=head3 API SPECIFICATION

=head4 INPUT

  report  Test::CPAN::Health::Report  required

=head4 OUTPUT

Scalar string: valid JSON (UTF-8 encoded).

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  JSN01 | FATAL    | report must be a Report object     | Pass a Report instance

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  RenderOp
  report : Report
  json!  : String
  -------------------------------------------------------
  valid_json(json!)
  decode_json(json!).overall_score = report.overall_score

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    my $json_str = $reporter->render($report);
    write_file('report.json', $json_str);

=cut

sub render {
	my ($self, $report) = @_;

	croak 'report must be a Test::CPAN::Health::Report'
		unless blessed($report) && $report->isa('Test::CPAN::Health::Report');

	return $self->{_json}->encode($report->as_hash);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut

1;
