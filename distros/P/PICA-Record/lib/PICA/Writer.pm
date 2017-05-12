package PICA::Writer;
{
  $PICA::Writer::VERSION = '0.585';
}
#ABSTRACT: Write and count PICA+ records and fields
use strict;


use PICA::Record;
use XML::Writer;
use PICA::Parser;
use IO::Handle;
use IO::Scalar;
use IO::File;
use String::Escape qw(qqbackslash elide);
use Carp qw(croak);

use constant ERROR   => 0;
use constant NEW     => 1;
use constant STARTED => 2;
use constant ENDED   => 3;

use overload 
    'bool' => sub { $_[0]->status };


sub new {
    my $class = shift;
    my $self = bless {
        status => NEW,
        io => undef,
        options => {},
        recordcounter => 0,
        fieldcounter => 0,
    }, $class;
    return $self->reset( @_ ? @_ : undef );
}


sub output {
    my $self = shift;
    my ($output, %options) = @_ % 2 ? @_ : (undef, @_);

    %{ $self->{options} } = %options;
    my $format = $self->{options}->{format};

    if (not defined $output) {
        $self->{io} = undef;
    } elsif ( ref($output) eq 'GLOB' ) {
        $self->{io} = $output;
        PICA::Parser::enable_binmode_encoding( $self->{io} );
    } elsif ( UNIVERSAL::isa('IO::Handle', $output) ) {
        $self->{io} = $output;
        PICA::Parser::enable_binmode_encoding( $self->{io} );
    } elsif ( ref($output) eq 'SCALAR' ) {
        $self->{io} = IO::Scalar->new( $output );
    } else {
        $self->{io} = IO::File->new($output, '>:utf8');
        $format = 'xml' if not defined $format and $output =~ /\.xml$/;
    }

    if ($options{pretty}) {
        $options{DATA_MODE} = 1;
        $options{DATA_INDENT} = 2;
        $options{NAMESPACES} = 1;
        $options{PREFIX_MAP} =  {'info:srw/schema/5/picaXML-v1.0'=>''};
    }

    $format = 'plain' unless defined $format and $format =~ /^(plain|normalized|xml)$/i;

    $self->{options}->{format} = lc($format);
    if ( $format =~ /^xml$/i and defined $output ) {
        $options{OUTPUT} = $self->{io};
        $options{header} = 1 unless defined $options{header};
        $self->{xmlwriter} = PICA::Writer::xmlwriter( %options );
    } else {
        $self->{xmlwriter} = undef;
    }
    
    if (defined $output and not $self->{io}) {
        $self->{status} = ERROR;
    }

    if ( $self->{options}->{stats} ) {
        $self->{fieldstat} = {};
        $self->{subfieldstat} = {} if $self->{options}->{stats} > 1;
    } else {
        $self->{subfieldstat} = undef;
        $self->{fieldstat} = undef;
    }

    return $self;
}


sub reset {
    my $self = shift;
    $self->output( @_ ) if @_;

    $self->{recordcounter} = 0;
    $self->{fieldcounter} = 0;
    
    return $self;
}


sub write {
    my $self = shift;
    croak('cannot write to a closed writer') if $self->status == ENDED;
    $self->start if $self->status != STARTED;

    my $format = $self->{options}->{format};

    if (UNIVERSAL::isa($_[0],'PICA::Field')) {
        while (@_) {
            my $field = shift;
            if (UNIVERSAL::isa($field,'PICA::Field')) {
                if ($format eq 'plain') {
                    print { $self->{io} } $field->string if $self->{io};
                } elsif ($format eq 'normalized') {
                    print { $self->{io} } $field->normalized() if $self->{io};
                } elsif ($format eq 'xml' and defined $self->{xmlwriter} ) {
                    $field->xml( $self->{xmlwriter} );
                }
                $self->addfieldstat( $field );
            } else {
                croak("Cannot write object of unknown type (PICA::Field expected)!");
            }
        }
    } else {
        my $comment = "";
        while (@_) {
            my $record = shift;
            if ( UNIVERSAL::isa($record, 'PICA::Record') ) {
                if ($format eq 'plain') {
                    print { $self->{io} } "\n"
                        if ($self->{recordcounter} > 0 && $self->{io});
                    print { $self->{io} } $record->string if $self->{io};
                } elsif ($format eq 'normalized') {
                    print { $self->{io} }  "\x1D\x0A" # next record
                        if ($self->{recordcounter} > 0 && $self->{io});
                    print { $self->{io} } $record->normalized() if $self->{io};
                } elsif ($format eq 'xml' and defined $self->{xmlwriter} ) {
                    $record->xml( $self->{xmlwriter} );
                }
                $self->addrecordstat( $record );
            } elsif (ref(\$record) eq 'SCALAR') {
                next if !$record;
                $comment = '# ' . join("\n# ", split(/\n/,$record)) . "\n";
                $comment =~ s/--//g;
                if ($format eq 'xml') {
                    $self->{xmlwriter}->comment( $comment )
                        if defined $self->{xmlwriter};
                } else {
                    print { $self->{io} } $comment if $self->{io};
                }
            } else {
                croak("Cannot write object of unknown type (PICA::Record expected)!");
            }
        }
    }

    return $self;
}


sub start {
    my $self = shift;
    croak('cannot start a writer twice') if $self->status == STARTED;
    croak('cannot start a writer in error status') if $self->status == ERROR;

    my $writer = $self->{xmlwriter};
    if ( $self->{options}->{format} eq 'xml' and defined $writer ) {
        if (UNIVERSAL::isa( $writer, 'XML::Writer::Namespaces' )) {
            $writer->startTag( [$PICA::Record::XMLNAMESPACE, 'collection'] );
        } else {
            $writer->startTag( 'collection' );
        }
    }

    $self->{status} = STARTED;

    return $self;
}



sub end {
    my $self = shift;
    croak('cannot end a writer in error status') if $self->status == ERROR;
    croak('cannot end a writer twice') if $self->status == ENDED;
    $self->start if $self->status != STARTED;

    if ( $self->{options}->{format} eq 'xml') {
        if ( defined $self->{xmlwriter} ) {
            $self->{xmlwriter}->endTag(); # </collection>
            $self->{xmlwriter}->end(); 
        }
    } else {
        # other supported formats don't need end handling
    }

    $self->{io}->close if defined $self->{io};
    $self->{status} = ENDED;
 
    return $self;
}


sub status {
    my $self = shift;
    return $self->{status};
}


sub records {
    my $self = shift;
    return $self->{recordcounter};
}


*counter = *records;


sub fields {
    my $self = shift;
    return $self->{fieldcounter};
}


sub statlines {
    my $self = shift;

    my @STRINGS = ('?',' ','*','+');
    my @stats = ();

    my $fieldstat = $self->{fieldstat} || { };
    my $subfieldstat = $self->{subfieldstat};

    foreach my $tag (sort { $a cmp $b } keys %{$fieldstat}) {
        my $line = length($tag) < 5 ? "$tag    " : "$tag ";
        $line .= $STRINGS[ $fieldstat->{$tag} ];
        if ( defined $subfieldstat ) {
            my $s = $subfieldstat->{$tag};
            foreach (keys %{$s}) {
                $line .= "\$$_ ";
                $line .= $STRINGS[ $s->{$_}->{occ} ];
                $line .= qqbackslash(elide($s->{$_}->{val},40))
                    if defined $s->{$_}->{val};
                $line .= " "; # TODO: join!
            }
        }
        push @stats, $line;
    }

    return @stats;
}



sub xmlwriter {
    my %params = @_;

    $params{NAMESPACES} = 1 unless defined $params{NAMESPACES};
    if (not defined $params{PREFIX_MAP} or 
        not defined $params{PREFIX_MAP}->{ $PICA::Record::XMLNAMESPACE }) {
        $params{PREFIX_MAP} = { $PICA::Record::XMLNAMESPACE => 'pica' };
    }
    my $writer = XML::Writer->new( %params );
    $writer->xmlDecl('UTF-8') if $params{header};
    if ($params{xslt}) {
        $writer->pi('xml-stylesheet', 'type="text/xsl" href="' . $params{xslt} . '"');
    }

    return $writer;
}


sub addfieldstat {
    my ($self, $field) = @_;
    $self->{fieldcounter}++;

    return unless defined $self->{subfieldstat};

    my $tag = $field->tag;
    my (%o,%v);

    my @content = $field->content;
      #print Dumper($field->content);
    foreach (@content) {
        my ($sf,$value) = @{$_};

        $o{ $sf }++;
        if ( exists $v{ $sf } ) {
            $v{ $sf } = undef unless defined $v{ $sf } and $v{ $sf } eq $value;
        } else {
            $v{ $sf } = $value;
        }
    }

    my $sfstat = $self->{subfieldstat};

    # TODO: order of subfields
    my $all = $sfstat->{$tag};
    if ( $sfstat->{$tag} ) {
        foreach my $sf (keys %{$sfstat->{$tag}}) {
            my $cur = $sfstat->{$tag}->{$sf};
            if ( $o{$sf} ) { # this time also
                # ..
                $cur->{occ} += 2
                    if $o{$sf} > 1 and $cur->{occ} < 2;

                $cur->{val} = undef unless
                    defined $v{$sf} and defined $cur->{val} and $v{$sf} eq $cur->{val};
                delete $v{$sf};
                delete $o{$sf};
            } else { # not this time but before
                $cur->{occ} = $cur->{occ} > 1  ? 0 : 2; 
            }
        }

        # fehlende subfields hinzufügen
        foreach (keys %o) {
            $sfstat->{$tag}->{$_} = { val => $v{$_}, occ => $o{$_} };
        }
    } else {
        $sfstat->{$tag} = {
            map { $_ => { val => $v{$_}, occ => $o{$_} }  } keys %o
        };
    }
    
    # ...stats...
}


sub addrecordstat {
    my ($self, $record) = @_;
    $self->{recordcounter}++;

    if ( not defined $self->{fieldstat} ) {
        $self->{fieldcounter} += scalar $record->fields;
        return;
    }
    my $fieldstat = $self->{fieldstat};
    
    # add field stats
    my %count; # undef, one, repeatable
    foreach my $field ($record->fields) {
        $self->addfieldstat( $field );
        $count{ $field->tag }++;
    }

    # 1, 3 : unique
    # 0,1,2,3 ?: optional, 1: mandatory, +: repeatable

    foreach my $tag (keys %{$fieldstat}) {
        if ( $count{$tag} ) { # does exist this time but before only once
            if ( $count{$tag} > 1 and $fieldstat->{$tag} < 2 ) {
                $fieldstat->{$tag} += 2;
            } #if $fieldstat->{$tag} < 2;
            delete $count{$tag};
        } else { # has existed before but not this time
            $fieldstat->{$tag} = $fieldstat->{$tag} > 1  ? 0 : 2; 
        }
    }

    # new fields are '1' or '+'
    foreach my $tag (keys %count) {
        $fieldstat->{$tag} = $count{$tag} > 1 ? 3 : 1; # 
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PICA::Writer - Write and count PICA+ records and fields

=head1 VERSION

version 0.585

=head1 SYNOPSIS

  $writer = PICA::Writer->new( \*STDOUT );
  $writer = PICA::Writer->new( "output.pica" );
  $writer = PICA::Writer->new( \$string, format => 'xml' );
  $writer = PICA::Writer->new( ); # no output

  $writer->start();  # called implicitely by default

  $writer->write( $record );
  $writer->write( @records );
  $writer->write( $field1, $field2, $field3 );
  $writer->write( $comment, $record );

  $writer->output( "output.xml" );  
  $writer->output( \*STDOUT, format => 'plain' );  
  print "Failed to open writer" unless $writer; # PICA::Writer::ERROR == 0

  print $writer->counter() . " records written\n";
  print $writer->fields()  . " fields written\n";

  $writer->reset();  # reset counters

  print $writer->status() == PICA::Writer::ENDED ? "open" : "ended";
 
  $writer->end(); # essential to close end tags in XML and such

  use PICA::Record qw(writerecord);
  writerecord( $record, $file );

=head1 DESCRIPTION

This module contains a simple class to write PICA+ records and fields.
Several output targets (file, GLOB, L<IO:Handle>, string, null) and formats 
(XML, plain, normalized) are supported. The number of written records
and fields is counted so you can also use the class as a simple counter.
Additional statistics of fields and subfields can also be enabled.

=head1 METHODS

=head2 new ( [ $output ] [ format => $format ] [ %options ] )

Create a new writer. See the C<output> method for possible parameters. 
The status of the new writer is set to C<PICA::Writer::NEW> (1) or
C<PICA::Writer::ERROR> (0). Boolean conversion is overloaded to return
the status so you can easily check whether a writer is in error status.

The writer can also be used for statistics if you set the 'stats' option.
With stats = 1 statistics is created on field level and with stats = 2
also on subfield level.

=head2 output ( [ $output ] [ format => $format ] [ %options ] )

Define the output handler for this writer. Record and field counters are
not reset but the writer is ended with the C<end> method if it had been 
started before. The output handler can be a filename, a GLOB, an
L<IO:Handle> object, a string reference, or C<undef>. In addition you
can specify the output format with the C<format> parameter (C<plain> or
C<xml>) and some options depending on the format, for instance 'pretty =E<gt> 1'
and 'stats =E<gt> 0|1|2'.

The status of the writer is set to C<PICA::Writer::NEW> or C<PICA::Writer::ERROR>.
This methods returns the writer itself which boolean conversion is overloaded to
return the status so you can easily check the return value whether an error occurred.

=head2 reset ( [ $output ] )

Reset the writer by setting record and field counters to zero and returning
the writer object. Optionally you can define a new output handler, so the 
following two lines are equal:

  $writer->output( $output )->reset();
  $writer->reset( $output );

The status of the writer will only be changed if you specify a new output handler.

=head2 write ( [ $comment | $record | $field ]* )

Write L<PICA::Field>, L<PICA::Record> objects, and comments (as strings)
and record the writer object. The number of written records and fields is
counted and can be queried with methods counter and fields.

  $writer->write( $record );
  $writer->write( @records );
  $writer->write( "record number " . $writer->counter(), $record );
  $writer->write( $field1, $field2 );

Writing single fields or mixing records and fields may not be possible 
depending on the output format and output handler. 

Returns the writer object so you can chain calls:

  $writer->write( $r1 )->write( $r2 )->end;

=head2 start ( [ %options ] )

Start writing and return the writer object. Depending on the format and 
output handler a header is written. Afterwards the status is set to
PICA::Writer::STARTED. You can pass optional parameters depending on the
format.

  $writer->start( ); # default
  $writer->start( xslt => 'mystylesheet.xsl' );
  $writer->start( nsprefix => 'pica' );

This method is implicitely called the first time you write to a PICA::Writer
that is not in status PICA::Writer::STARTED..

=head2 end ( )

Finish writing. Depending on the format and output handler a footer is
written (for instance an XML end tag) and the output handler is closed. 
Afterwards the status is set to PICA::Writer::ENDED. If the writer had
not been started before, the start method is called first. 

Ending or writing to an already ended writer will throw an error. You can
restart an ended writer with the output method or with the start method.

=head2 status ( )

Return the status which can be PICA::Writer::NEW, PICA::Writer::STARTED, 
PICA::Writer::ENDED, or PICA::Writer::ERROR.

=head2 records ( )

Returns the number of written records.

=head2 counter ( )

Alias for records().

=head2 fields ( )

Returns the number of written fields.

=head2 statlines ( )

Return a list of lines with statistics (if stats option had been set).

=head1 FUNCTIONS

=head2 xmlwriter ( %params )

Create a new L<XML::Writer> instance and optionally write XML header
and processing instruction. Relevant parameters include 'header' (boolean),
'xslt', NAMESPACES, PREFIX_MAP.

=head2 PRIVATE METHDOS

=head2 addfieldstat ( $field )

Add a field to the statistics.

=head2 addrecordstat ( $record )

Add a record to the statistics.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Verbundzentrale Goettingen (VZG) and Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
