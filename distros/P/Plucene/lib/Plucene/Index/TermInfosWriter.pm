package Plucene::Index::TermInfosWriter;

=head1 NAME 

Plucene::Index::TermInfosWriter - write to the term infos file

=head1 SYNOPSIS

	my $writer = Plucene::Index::TermInfosWriter->new(
		$dir_name, $segment, $field_infos);

	$writer->add(Plucene::Index::Term $term, 
			Plucene::Index::TermInfo $term_info);

	$writer->write_term(Plucene::Index::Term $term);

=head1 DESCRIPTION

This will allow for the writing and adding to a term infos file for a 
particular segment. It also writes the term infos index.

=head1 METHODS

=cut

use strict;
use warnings;

use constant INDEX_INTERVAL => 128;

use Carp qw(confess carp);

use Plucene::Store::OutputStream;
use Plucene::Index::Term;
use Plucene::Index::TermInfo;

=head2 new

	my $writer = Plucene::Index::TermInfosWriter->new(
		$dir_name, $segment, $field_infos);

This will create a new Plucene::Index::TermInfosWriter object.
		
=cut

sub new {
	my ($class, $d, $segment, $fis, $is_i) = @_;

	my $self = bless {
		field_infos    => $fis,
		is_index       => $is_i,
		size           => 0,
		last_term      => Plucene::Index::Term->new({ field => "", text => "" }),
		last_ti        => Plucene::Index::TermInfo->new,
		last_index_ptr => 0,
		output         => Plucene::Store::OutputStream->new(
			"$d/$segment.ti" . ($is_i ? "i" : "s")
		),
	}, $class;
	confess("No field_infos!") unless $self->{field_infos};
	$self->{output}->write_int(0);    # Will be filled in when DESTROYed
	if (!$is_i) {
		$self->{other} = $class->new($d, $segment, $fis, 1);
		$self->{other}->{other} = $self;    # My enemy's enemy is my friend
	}
	return $self;
}

=head2 break_ref

This will break a circular reference.

=cut

# Damned circular references.
sub break_ref { undef shift->{other} }

=head2 add

	$writer->add(Plucene::Index::Term $term, 
			Plucene::Index::TermInfo $term_info);

This will add the term and term info to the term infos file.
			
=cut

sub add {
	my ($self, $term, $ti) = @_;
	no warnings 'uninitialized';
	carp sprintf "Can't add out-of-order term %s lt %s (%s lt %s)", $term->text,
		$self->{last_term}->text, $term->field, $self->{last_term}->{field}
		if !$self->{is_index} && $term->lt($self->{last_term});
	carp "Frequency pointer out of order"
		if $ti->freq_pointer < $self->{last_ti}->freq_pointer;
	carp "Proximity pointer out of order"
		if $ti->prox_pointer < $self->{last_ti}->prox_pointer;

	$self->{other}->add($self->{last_term}, $self->{last_ti})
		if !$self->{is_index}
		and (($self->{size} % INDEX_INTERVAL) == 0);

	$self->write_term($term);
	$self->{output}->write_vint($ti->doc_freq);
	$self->{output}
		->write_vlong($ti->freq_pointer - $self->{last_ti}->freq_pointer);
	$self->{output}
		->write_vlong($ti->prox_pointer - $self->{last_ti}->prox_pointer);

	if ($self->{is_index}) {    # I bet Tony will think about subclassing
		                          # at this point
		$self->{output}->write_vlong(
			$self->{other}->{output}->tell - $self->{last_index_pointer});
		$self->{last_index_pointer} = $self->{other}->{output}->tell;
	}

	$self->{last_ti} = $ti->clone;
	$self->{size}++;
}

=head2 write_term

	$writer->write_term(Plucene::Index::Term $term);

This will write the term to the term infos file.
	
=cut

sub write_term {
	my ($self, $term) = @_;
	my $text = $term->text || "";
	no warnings 'uninitialized';

	# Find longest common prefix
	($text ^ $self->{last_term}->text) =~ /^(\0*)/;
	my $start = length $1;

	$self->{output}->write_vint($start);
	$self->{output}->write_string(substr($text, $start));
	$self->{output}
		->write_vint($self->{field_infos}->field_number($term->field));
	$self->{last_term} = $term;
}

sub DESTROY {
	my $self = shift;
	$self->{output}->seek(0, 0);
	$self->{output}->write_int($self->{size});
}

1;
