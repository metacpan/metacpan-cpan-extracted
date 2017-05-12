package Plucene::Index::DocumentWriter;

=head1 NAME 

Plucene::Index::DocumentWriter - the document writer

=head1 SYNOPSIS

	my $writer = Plucene::Index::DocumentWriter
		->new($directory, $analyser, $max_field_length);

	$writer->add_document($segment, $doc);

=head1 DESCRIPTION

This is the document writer class.

=head2 METHODS

=cut

use strict;
use warnings;

use File::Slurp;
use Plucene::Index::FieldInfos;
use Plucene::Index::FieldsWriter;
use Plucene::Index::Term;
use Plucene::Index::TermInfo;
use Plucene::Index::TermInfosWriter;
use Plucene::Search::Similarity;
use Plucene::Store::OutputStream;

use IO::Scalar;

=head2 new

	my $writer = Plucene::Index::DocumentWriter
		->new($directory, $analyser, $max_field_length);

This will create a new Plucene::Index::DocumentWriter object with the passed
in arguments.

=cut

sub new {
	my ($self, $d, $a, $mfl) = @_;
	bless {
		directory        => $d,
		analyzer         => $a,
		max_field_length => $mfl,
		postings         => {},
	}, $self;
}

=head2 add_document

	$writer->add_document($segment, $doc);

=cut

sub add_document {
	my ($self, $segment, $doc) = @_;
	my $fi = Plucene::Index::FieldInfos->new();
	$fi->add($doc);
	$fi->write("$self->{directory}/$segment.fnm");
	$self->{field_infos} = $fi;

	my $fw =
		Plucene::Index::FieldsWriter->new($self->{directory}, $segment, $fi);
	$fw->add_document($doc);
	$self->{postings}      = {};
	$self->{field_lengths} = [];
	$self->_invert_document($doc);
	my @postings = sort {
		     $a->{term}->{field} cmp $b->{term}->{field}
			|| $a->{term}->{text} cmp $b->{term}->{text}
	} values %{ $self->{postings} };

	$self->_write_postings($segment, @postings);
	$self->_write_norms($doc, $segment);
}

sub _invert_document {
	my ($self, $doc) = @_;
	for my $field (grep $_->is_indexed, $doc->fields) {
		my $name = $field->name;
		my $fn   = $self->{field_infos}->field_number($name);
		my $pos  = $self->{field_lengths}->[$fn];
		if (!$field->is_tokenized) {
			$self->_add_position($name, $field->string, $pos++);
		} else {
			my $reader = $field->reader
				|| IO::Scalar->new(\$field->{string});
			my $stream = $self->{analyzer}->tokenstream({
					field  => $name,
					reader => $reader
				});
			while (my $t = $stream->next) {
				$self->_add_position($name, $t->text, $pos++);
				last if $pos > $self->{max_field_length};
			}
		}
		$self->{field_lengths}->[$fn] = $pos;
	}
}

sub _add_position {
	my ($self, $field, $text, $pos) = @_;
	my $ti = $self->{postings}->{"$field\0$text"};
	if ($ti) {
		$ti->{positions}->[ $ti->freq ] = $pos;
		$ti->{freq}++;
		return;
	}
	$self->{postings}->{"$field\0$text"} = Plucene::Index::Posting->new({
			term => Plucene::Index::Term->new({ field => $field, text => $text }),
			positions => [$pos],
			freq      => 1,
		});
}

sub _write_postings {
	my ($self, $segment, @postings) = @_;
	my (@freqs, @proxs);
	my $tis =
		Plucene::Index::TermInfosWriter->new($self->{directory}, $segment,
		$self->{field_infos});
	my $ti = Plucene::Index::TermInfo->new();

	for my $posting (@postings) {
		$ti->doc_freq(1);
		$ti->freq_pointer(scalar @freqs);
		$ti->prox_pointer(scalar @proxs);

		$tis->add($posting->term, $ti);
		my $f = $posting->freq;
		push @freqs, ($f == 1) ? 1 : (0, $f);
		my $last_pos  = 0;
		my $positions = $posting->positions;
		for my $j (0 .. $f - 1) {
			my $pos = $positions->[$j] || 0;
			push @proxs, $pos - $last_pos;
			$last_pos = $pos;
		}
	}

	write_file("$self->{directory}/$segment.frq" => pack('(w)*', @freqs));
	write_file("$self->{directory}/$segment.prx" => pack('(w)*', @proxs));
	$tis->break_ref;
}

sub _write_norms {
	my ($self, $doc, $segment) = @_;
	for my $field (grep $_->is_indexed, $doc->fields) {
		my $fn = $self->{field_infos}->field_number($field->name);
		warn "Couldn't find field @{[ $field->name ]} in list [ @{[ map
			$_->name, $self->{field_infos}->fields]}]" unless $fn >= 0;
		my $norm =
			Plucene::Store::OutputStream->new("$self->{directory}/$segment.f$fn");
		my $val      = $self->{field_lengths}[$fn];
		my $norm_val = Plucene::Search::Similarity->norm($val);
		$norm->print(chr($norm_val));
	}
}

package Plucene::Index::Posting;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw( term freq positions ));

1;
