package Net::Amazon::MechanicalTurk::DelimitedWriter;
use strict;
use warnings;
use IO::File;
use Carp;
use Net::Amazon::MechanicalTurk::BaseObject;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };

Net::Amazon::MechanicalTurk::DelimitedWriter->attributes(qw{
    fieldSeparator
    output
    file
    append
    lazy
    utf8
    rowsWritten
    autoflush
    autoclose
});

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    $self->setAttributesIfNotDefined(
        fieldSeparator => ',',
        utf8           => 1,
        lazy           => 0,
        append         => 0,
        autoflush      => 0,
        autoclose      => 0
    );
    if (!defined $self->output) {
        if (!defined $self->file) {
             Carp::croak("Either output or file must be specified.");
        }
        if (!$self->lazy) {
            $self->open;
        }
    }
    else {
        $self->output->autoflush(1) if $self->autoflush;
    }
    $self->rowsWritten(0);
}

sub DESTROY {
    my $self = shift;
    if ($self->autoclose) {
        $self->close;
    }
    elsif ($self->output) {
        $self->output->flush;
    }
}

sub close {
    my $self = shift;
    if ($self->output) {
        $self->output->close;
        $self->output(undef);
    }
}

sub open {
    my $self = shift;
    if (defined $self->output) {
        return $self->output;
    }
    else {
        my $mode = ($self->append) ? "a" : "w";
        my $out = IO::File->new($self->file, $mode);
        if (!$out) {
            Carp::croak("Couldn't open " . $self->file . " - $!.");
        }
        if ($self->utf8) {
            # By using utf8 these modules should be able to handle
            # non-english answers with recent versions of perl.
            eval { binmode($out, ":utf8") };
            warn "Couldn't set filehandle to utf8." if $@;
        }
        $out->autoflush(1) if $self->autoflush;
        $self->output($out);
        $self->autoclose(1);
        return $out;
    }
}

sub write {
    my $self = shift;
    my $row = ($#_ == 0 and UNIVERSAL::isa($_[0], "ARRAY")) ? $_[0] : [@_];
    my $out = $self->open;
    my $rowsWritten = $self->rowsWritten;
    if ($rowsWritten > 0) {
        print $out "\n";
    }
    my $fs = $self->fieldSeparator;
    for (my $i=0; $i<=$#{$row}; $i++) {
        if ($i > 0) {
            print $out $fs;
        }
        print $out $self->formatCell($row->[$i]);
    }
    $self->rowsWritten($rowsWritten+1);
}

sub formatCell {
    my ($self, $cell) = @_;
    my $fs = $self->fieldSeparator;
    if (!defined $cell) {
        return '';
    }
    if (index($cell, $fs) >= 0 or $cell =~ /[\n"]/s) {
        $cell =~ s/"/""/gs;
        return '"' . $cell . '"';
    }
    else {
        return $cell;
    }
}

return 1;
