package PICA::PlainParser;
{
  $PICA::PlainParser::VERSION = '0.585';
}
#ABSTRACT: Parse normalized PICA+
use strict;


use PICA::Field;
use PICA::Record;
use Carp qw(croak);


sub new {
    my ($class, %params) = @_;
    $class = ref $class || $class;

    my $self = bless {
        field_handler  => defined $params{Field} ? $params{Field} : undef,
        record_handler => defined $params{Record} ? $params{Record} : undef,

        broken_field_handler => defined $params{FieldError} ? $params{FieldError} : undef,
        broken_record_handler => defined $params{RecordError} ? $params{RecordError} : undef,

        proceed => $params{Proceed} ? $params{Proceed} : 0,
        limit  => ($params{Limit} || 0) * 1,
        offset  => ($params{Offset} || 0) * 1,

        record => undef,
        broken => undef,    # broken record

        read_records => [],
        'strict' => $params{strict} || 0,
        filename => "",
        fields => [],
        read_counter => 0,
        active => 0,
    }, $class;

    return $self;
}


sub parsefile {
    my ($self, $file) = @_;

    if ( ref($file) eq 'GLOB' ) {
        $self->{filehandle} = $file;
        $self->{filename} = "";
    } elsif ( UNIVERSAL::isa( $file, 'IO::Handle' ) ) {
        $self->{filehandle} = $file;
        $self->{filename} = "";
    } else {
        $self->{filename} = $file;

        my $fh = $file;
        $fh = "zcat $fh |" if $fh =~ /\.gz$/;
        $fh = "unzip -p $fh |" if $fh =~ /\.zip$/;

        $self->{filehandle} = IO::File->new($file, '<:utf8')
            or croak("failed to open file $file");
    }

    PICA::Parser::enable_binmode_encoding( $self->{filehandle} );

    if ( not $self->{proceed} ) {
        $self->{read_counter} = 0;
        $self->{read_records} = [];
    }

    $self->{active} = 0;
    $self->{record} = undef;

    my $dumpformat = 0;
    my $line = readline( $self->{filehandle} );
    if ($line =~ /\x1E/) { # dumpformat useds \x1E instead of newlines

        my $EOL = $/;
        $/ = chr(0x1E);
        my $id = "";

        my @linebuf = split( /\x1E/, $line );
        
        do {
            last if ($self->finished());
            if (@linebuf) {
                $line = shift @linebuf;
                if (defined $line and not @linebuf) {
                    $line .= readline( $self->{filehandle} );
                }
            } else {
                $line = readline( $self->{filehandle} );
            }
            if ( defined $line ) {
                $line =~ /^\x1D?([^\s]*)/;
                if (PICA::Field::parse_pp_tag($1)) {
                    $self->_parseline($line);
                } else {
                    if ( "$id" ne "$1" ) { 
                        $self->_parseline(""); # next record
                    }
                    $id = $1;
                }
            }
        } while(defined $line);

        $/ = $EOL;

    } else {
        while ( defined $line and not $self->finished ) {
            $self->_parseline($line);
            $line = readline( $self->{filehandle} );
        };
    }

    $self->handle_record() unless $self->finished(); # handle last record

    $self;
}


sub parsedata {
    my ($self, $data, $additional) = @_;

    $self->{active} = 0;
    $self->{record} = undef;

    if ( ! $self->{proceed} ) {
        $self->{read_counter} = 0;
        $self->{read_records} = [];
    }

    if ( ref($data) eq 'CODE' ) {
        my $chunk = &$data();
        while(defined $chunk) {
            $self->_parsedata($chunk);
            $chunk = &$data();
        }
    } elsif( UNIVERSAL::isa( $data, "PICA::Record" ) ) {
        # re-parse the record (could obviously be speed up by dropping tests)
        foreach ( $data->fields ) {
            $self->_parseline( $_->string );
        }
    } else {
        $self->_parsedata($data);
    }

    $self->handle_record(); # handle last record

    $self;
}



sub records {
    my $self = shift; 
    return @{ $self->{read_records} };
}


sub counter {
    my $self = shift; 
    return $self->{read_counter};
}


sub finished {
    my $self = shift; 
    return $self->{limit} && $self->counter() >= $self->{limit};
}


sub _parsedata {
    my ($self, $data) = @_;

    my @lines;

    if (ref(\$data) eq 'SCALAR') {
        @lines = $data eq "\n" ? ('') : split "\n", $data;
    } elsif (ref($data) eq 'ARRAY') {
        @lines = @{$data};
    } else {
        croak("Got " . ref(\$data) . " when parsing PICA+ while expecting SCALAR or ARRAY");
    }

    foreach my $line (@lines) {
        $self->_parseline($line);
    }
}


sub _parseline {
    my ($self, $line) = @_;
    chomp $line; # remove newline if present

    # start of record marker
    if ( $line eq "\x1D" or (not $self->{strict} and $line =~ /^\s*$|^#|^SET/) ) {
        $self->handle_record() if $self->{active} and @{$self->{fields}};
    } else {
        $line =~ s/^\x1D//;
        my $field = eval { PICA::Field->parse($line); };
        if ($@) {
            $@ =~ s/ at .*\n//; # remove line number
            $field = $self->broken_field( $@, $line );
        } elsif ($self->{field_handler}) {
            $field = $self->{field_handler}( $field );
        }
        if ( UNIVERSAL::isa( $field, 'PICA::Field' ) ) {
            push (@{$self->{fields}}, $field);
        } elsif ( defined $field ) {
            $self->{broken} = $field unless defined $self->{broken};
        }
    }
    $self->{active} = 1;
}


sub broken_field {
    my ($self, $msg, $line) = @_;
    if ($self->{broken_field_handler}) {
        return $self->{broken_field_handler}( $msg, $line );
    }
    $msg = "$msg in line \"$line\"" if defined $line;
    print STDERR "$msg\n";
    # TODO: count/collect errors
    return;
}


sub broken_record {
    my ($self, $msg, $record) = @_;
    if ($self->{broken_record_handler}) {
        return $self->{broken_record_handler}( $msg, $record );
    }
    return if UNIVERSAL::isa( $record, 'PICA::Record' ) && $record->empty;
    print STDERR "$msg\n" if defined $msg;
    return;
}


sub handle_record {
    my $self = shift;

    $self->{read_counter}++;

    my ($record, $broken);

    # $self->{broken} = "empty record" 
    #    unless defined $self->{broken} or @{$self->{fields}} > 0;

    if ( $self->{broken} ) {
        $broken = $self->{broken};
    } else {
        $record = PICA::Record->new( @{$self->{fields}} );
    }
    $self->{fields} = [];
    $self->{broken} = undef;

    # TODO: fix this
    # return if ($self->{offset} && $self->{read_counter} < $self->{offset});

    if (not defined $broken) {
        if ($self->{record_handler}) {
            if (UNIVERSAL::isa( $self->{record_handler}, 'PICA::Writer') ) {
                $self->{record_handler}->write( $record );
                #$record = TODO allow here!
            } else {
                $record = $self->{record_handler}( $record );
                $record = undef if $record =~ /^-?\d+$/;            
            }
        }
        if (defined $record) {
            if ( UNIVERSAL::isa( $record, 'PICA::Record' ) ) {
                $broken = "empty record" if $record->empty;
            } else {
                $broken = $record;
            }
        }
    }

    if ( defined $broken ) {
        $self->broken_record( $broken, $record );
    } elsif ( defined $record ) {
        push @{ $self->{read_records} }, $record;
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PICA::PlainParser - Parse normalized PICA+

=head1 VERSION

version 0.585

=head1 SYNOPSIS

  my $parser = PICA::PlainParser->new(
      Field => \&field_handler,
      Record => \&record_handler
  );

  $parser->parsefile($filename);

  sub field_handler {
      my $field = shift;
      print $field->string;
      # no need to save the field so do not return it
  }

  sub record_handler {
      print "\n";
  }

=head1 DESCRIPTION

This module contains a parser for normalized PICA+

=head1 PUBLIC METHODS

=head2 new (params)

Create a new parser. See L<PICA::Parser> for a detailed description of
the possible parameters C<Field>, C<Record>, and C<Collection>. Errors
are reported to STDERR.

=head2 parsefile ( $filename | $handle )

Parses a file, specified by a filename or file handle or L<IO::Handle>.
Additional possible parameters are handlers (C<Field>, C<Record>,
C<Collection>) and options (C<EmptyRecords>). If you supply a filename
with extension C<.gz> then it is extracted while reading with C<zcat>,
if the extension is C<.zip> then C<unzip> is used to extract.

=head2 parsedata ( $data )

Parses PICA+ data from a string, array or function. If you supply
a function then this function is must return scalars or arrays and
it is called unless it returns undef. You can also supply a 
L<PICA::Record> object to be parsed again.

=head2 records ( )

Get an array of the read records (if they have been stored)

=head2 counter ( )

Get the number of records that have been (tried to) read. This also includes
broken records and other records that have been skipped, for instance by
filtering out with the record handler.

=head2 finished ( )

Return whether the parser will not parse any more records. This
is the case if the number of read records is larger then the limit.

=head1 PRIVATE METHODS

=head2 _parsedata

Parses a string or an array reference.

=head2 _parseline

Parses a line (without trailing newline character). May throw an exception with croak.

=head2 broken_field ( $errormessage [, $line ] )

If a line could not be parsed into a L<PICA::Field>, this method is called.
If it returns undef, the line is ignored, if it returns a PICA::Field object,
this field is used instead and if it returns a true value, the whole record
will be marked as broken. This method can be used as error handler. By default
it always returns undef and prints an error message to STDERR.

=head2 broken_record ( $errormessage [, $record ] )

Error handler for broken records. By default
prints the errormessage to STDERR if it is defined 
and the record is not empty.

=head2 handle_record ( )

Calls the record handler.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Verbundzentrale Goettingen (VZG) and Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
