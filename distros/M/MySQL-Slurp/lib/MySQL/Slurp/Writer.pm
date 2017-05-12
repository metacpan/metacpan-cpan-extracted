package MySQL::Slurp::Writer;

# MySQL::Slurp::Writer -  provide a buffer writing file handle for MySQL::Slurp
#
# Attributes:
#   buffer      Int
#   _buffer     ArrayRef
#   file        Filename
#   io-file     
#
# Methods: print / write, close, open
#   BUILD
#
#   print
#   flush
#   close
#   lock_ex
#   lock_un
#  

our $VERSION = 0.28;

use Fcntl ':flock';
use IO::File;
use Moose;
    

    has 'filename' => ( 
        is            => 'rw' ,
        isa           => 'Str' ,
        required      => 1 ,            
        documentation => 'Location of file to write to' ,
    );


    has 'buffer' => ( 
            is            => 'rw' ,
            isa           => 'Int' ,
            required      => 1 ,
            default       => 1 ,
            documentation => 'Records processed before flushing to the file handle ( default: 1)' 
    );


    has '_buffer' => (
            is            => 'rw' ,
            isa           => 'ArrayRef' ,
            required      => 1 ,
            default       => sub { [ ] } ,
            documentation => 'Write record buffer' ,
    );


    has 'iofile' => (
            is            => 'ro' ,
            isa           => 'IO::File' ,
            required      => 0 ,
            documentation => 'IO::File object' ,
            handles       => [ qw(open) ] ,
    );
    


# ---------------------------------------------------------------------
# INSTANTIATION
# ---------------------------------------------------------------------

    sub BUILD { 

      # Create a iofile handle
        $_[0]->{iofile} = IO::File->new( $_[0]->filename, ">" ) ;

    }
        

# ---------------------------------------------------------------------
# METHODS
# ---------------------------------------------------------------------

  # Buffered 
  # Returns the number of records in the buffer before flush if any.
    sub print {
        
        my $n_records = $#_;

        push( @{ $_[0]->_buffer }, @_[1..$#_]); 

      # Flush buffer if it exceeds capacity
        $_[0]->flush
          if ( scalar @{ $_[0]->_buffer } > $_[0]->buffer );

        $n_records;  # return the number of records committed 

    }       


  # Flush buffer to FIFO
    sub flush {

            my $records = scalar @{ $_[0]->_buffer };
            
            $_[0]->lock_ex;
            print { $_[0]->iofile } @{ $_[0]->_buffer }; 
            $_[0]->lock_un; 

            $_[0]->_buffer( [] );

            return $records;

    }


    sub lock_ex {

        flock( $_[0]->iofile, LOCK_EX );

    }

    sub lock_un {

        flock( $_[0]->iofile, LOCK_UN );

    }

    sub close { 

        $_[0]->flush;
        $_[0]->iofile->close;

    }


# ---------------------------------------------------------------------
# EVENTS
# ---------------------------------------------------------------------

    __PACKAGE__->meta->make_immutable;

1;


# ---------------------------------------------------------------------
__END__


=head1 NAME

MySQL::Slurp::Writer - Adds buffering / locking writing to MySQL::Slurp 


=head1 SYNOPSIS

    my $writer = MySQL::Slurp::Writer->new( ... );

    $writer->print( "records\tto\tprint\n" );


=head1 DESCRIPTION

This module wraps L<IO::File> to provide a thread-safe method for 
writing to a file handles.  The method is simple ... writing is 
buffered; the file handle is locked; the output is written to the file
handle, the lock is released.    

=head1 METHODS

=head2 new

Create a new MySQL::Slurp::Writer object

=over

=item buffer

The size of the buffer.  The default is 1 record, i.e. no buffering.

=item filename

The filename of the IO::File object

=back

=head2 print

Write arguments to the buffer and if the buffer is full, commit to the
file handle

=head2 flush

Flush the buffer

=head2 close

Closes the writing file handle

=head2 lock_ex 

Block until an exclusive lock can be made on the file handle

=head2 lock_un

Release the lock

=head1 TODO

- item Generalize to object independent of MySQL::Slurp

=head1 SEE ALSO

L<MySQL::Slurp>, L<IO::File>, L<Moose>


=head1 AUTHOR

Christopher Brown, E<lt>ctbrown@cpan.org<gt>

L<http://www.opendatagroup.com>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Open Data

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut              


