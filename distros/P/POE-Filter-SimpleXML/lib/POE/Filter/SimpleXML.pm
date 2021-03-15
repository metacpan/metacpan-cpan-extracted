package POE::Filter::SimpleXML;

use 5.024;
use utf8;
use strictures 2;

use English qw(-no_match_vars);

#ABSTRACT: Simple XML parsing for POE

use Moose qw(has extends);
use MooseX::NonMoose;

extends 'Moose::Object', 'POE::Filter';

use Carp;
use XML::LibXML;

our $VERSION = '1.000';

has 'buffer' => (
	'is'      => 'ro',
	'traits'  => ['Array'],
	'isa'     => 'ArrayRef',
	'lazy'    => 1,
	'clearer' => '_clear_buffer',
	'default' => sub { [] },
	'handles' => {
		'has_buffer'     => 'count',
		'all_buffer'     => 'elements',
		'push_buffer'    => 'push',
		'shift_buffer'   => 'shift',
		'unshift_buffer' => 'unshift',
		'join_buffer'    => 'join',
	},
);

has 'callback' => (
	'is'      => 'ro',
	'isa'     => 'CodeRef',
	'lazy'    => 1,
	'default' => sub {
		sub { Carp::confess('Parsing error happened: ' . join "\n", @_); };
	},
);

has 'parser' => (
	'is'      => 'ro',
	'isa'     => 'XML::LibXML',
	'lazy'    => 1,
	'builder' => '_build_parser',
	'clearer' => '_clear_parser',
);

sub _build_parser {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	return XML::LibXML->new('no_blanks' => 1);
}

sub get_one_start {
	my ($self, $raw) = @_;

	if (defined $raw) {
		foreach my $raw_data (@{$raw}) {
			$self->push_buffer($raw_data);
		}
	}

	return;
} ## end sub get_one_start

sub get_one {
	my ($self) = @_;

	my $buf = q{};

	my $nodes = [];

	while ($self->has_buffer) {
		my $eppframe = $self->shift_buffer;

		eval {
			push @{$nodes}, $self->parser->load_xml('string' => $eppframe);
			1;
		} or do {
			my $err = $EVAL_ERROR || 'Zombie error';
			$self->callback->($err);
		};
	} ## end while ($self->has_buffer)

	return $nodes;
} ## end sub get_one

sub put {
	my ($self, $nodes) = @_;
	my $output = [];

	foreach my $node (@{$nodes}) {
		push @{$output}, $node->toString;
	}

	return $output;
} ## end sub put

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=pod
=encoding utf8

=head1 NAME

POE::Filter::SimpleXML - Simple XML parsing for the POE framework

=head1 VERSION

version 1.140700

=head1 SYNOPSIS

 use POE::Filter::SimpleXML;
 my $filter = POE::Filter::SimpleXML->new;

 my $wheel = POE::Wheel:ReadWrite->new(
 	Filter		=> $filter,
	InputEvent	=> 'input_event',
 );

=head1 DESCRIPTION

POE::Filter::SimpleXML provides POE with a XML parsing strategy for
POE::Wheels that will be dealing with Complete XML documents.

The parser is XML::LibXML

=head1 PRIVATE_ATTRIBUTES

=head2 buffer

    is: ro, isa: ArrayRef, traits: Array

buffer holds the raw data to be parsed, there should be one XML document per
entry. Access to this attribute is provided by the following methods:

    handles =>
    {
        has_buffer => 'count',
        all_buffer => 'elements',
        push_buffer => 'push',
        shift_buffer => 'shift',
        unshift_buffer => 'unshift',
        join_buffer => 'join',
    }

=head2 callback

    is: ro, isa: CodeRef

callback holds the CodeRef to be call in the event that there is an exception
generated while parsing content. By default it holds a CodeRef that simply
calls Carp::confess.

=head2 parser

    is: ro, isa: XML::LibXML

parser holds an instance of the XML::LibXML parser.

=head1 PUBLIC_METHODS

=head2 get_one_start

    (ArrayRef $raw?)

This method is part of the POE::Filter API. See L<POE::Filter/get_one_start>
for an explanation of its usage.

=head2 get_one

    returns (ArrayRef)

This method is part of the POE::Filter API. See L<POE::Filter/get_one> for an
explanation of its usage.

=head2 put

    (ArrayRef $nodes) returns (ArrayRef)

This method is part of the POE::Filter API. See L<POE::Filter/put> for an
explanation of its usage.

=head1 PRIVATE_METHODS

=head1 AUTHOR

Mathieu Arnold <mat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Mathieu Arnold <mat@cpan.org>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
