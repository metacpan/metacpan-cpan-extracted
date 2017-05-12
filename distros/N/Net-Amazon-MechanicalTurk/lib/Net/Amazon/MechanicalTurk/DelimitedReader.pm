package Net::Amazon::MechanicalTurk::DelimitedReader;
use strict;
use warnings;
use IO::File;
use Carp;
use Net::Amazon::MechanicalTurk::BaseObject;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };

Net::Amazon::MechanicalTurk::DelimitedReader->attributes(qw{
    fieldSeparator
    input
    file
    utf8
    autoclose
});

# The following CPAN modules do not support new lines in a column:
# (So I wrote this class)
# Text::CSV
# Text::CSV_XS
# Text::CSV_PP

sub init {
    my $self = shift;
    $self->setAttributes(@_);
    $self->setAttributesIfNotDefined(
        fieldSeparator => ',',
        utf8 => 1,
        autoclose => 0
    );
    $self->assertRequiredAttributes(qw{
        fieldSeparator
    });
    if (!defined $self->input) {
        if (!defined $self->file) {
            Carp::croak("Either input or file must be specified.");
        }
        my $in = IO::File->new($self->file, "r");
        if (!$in) {
            Carp::croak("Couldn't open " . $self->file . " - $!.");
        }
        if ($self->utf8) {
            # By using utf8 these modules should be able to handle
            # non-english answers with recent versions of perl.
            eval { binmode($in, ":utf8") };
            warn "Couldn't set filehandle to utf8." if $@;
        }
        $self->autoclose(1);
        $self->input($in);
    }
    else {
        $self->file(sprintf "%s", $self->input);
    }
}

sub DESTROY {
    my $self = shift;
    if ($self->autoclose) {
        $self->close;
    }
}

sub close {
    my $self = shift;
    if ($self->input) {
        $self->input->close;
        $self->input(undef);
    }
}

sub next {
    my $self = shift;
    my $in = $self->input;
    my $fs = $self->fieldSeparator;
    my $row = [];
    my $lastWasQuote = 0;
    my $quotedCell = 0;
    my $cell = '';
    
    return undef unless $self->input;
    
    while (1) {
        my $c = getc($in);

        # Handle end of input        
        if (!defined($c)) {
            push(@$row, $cell);
            $self->close;
            $self->input(undef);
            return $row;
        }
        
        next if ($c eq "\r"); # just throw away \r
        
        if ($quotedCell) {
           if ($c eq "\n") {
               if ($lastWasQuote) {
                   push(@$row, $cell);
                   return $row;
               }
               $cell .= "\n";
               $lastWasQuote = 0;
           }
           elsif ($c eq $fs) {
               if ($lastWasQuote) {
                   push(@$row, $cell);
                   $cell = '';
                   $lastWasQuote = 0;
                   $quotedCell = 0;
               }
               else {
                   $cell .= $c;
                   $lastWasQuote = 0;
               }
           }
           elsif ($c eq '"') {
               if ($lastWasQuote) {
                   $cell .= $c;
                   $lastWasQuote = 0;
               }
               else {
                   $lastWasQuote = 1;
               }
           }
           else {
               if ($lastWasQuote) {
                   warn "Single quote found in cell which was not escaped.\n";
               }
               $cell .= $c;
               $lastWasQuote = 0;
           }
        }
        else {
           if ($cell eq '' and $c eq '"') {
               $quotedCell = 1;
           }
           elsif ($c eq "\n") {
               push(@$row, $cell);
               return $row;
           }
           elsif ($c eq $fs) {
               push(@$row, $cell);
               $cell = '';
           }
           else {
               $cell .= $c;
           }
        }
    }
}

return 1;
