################################################################################
# Copyright (c) 2008 Martin Scharrer <martin@scharrer-online.de>
# This is open source software under the GPL v3 or later.
#
# $Id: Dumpfile.pm 107 2009-04-23 11:45:00Z martin $
################################################################################
package SVN::Dumpfile;
use strict;
use warnings;
use SVN::Dumpfile::Node;
use IO::File;
use Carp;
use Readonly;
Readonly my $NL => chr(10);

our $VERSION = do { '$Rev: 107 $' =~ /\$Rev: (\d+) \$/; '0.13' . ".$1" };


sub new {
    my $arg = shift;
    my $class = ref $arg ? ref $arg : $arg;

    my $self = bless {}, $class;
    return $self->_process_arguments(@_);
}

sub _process_arguments {
    my $self = shift;
    my @args;
    if ( @_ == 1 ) {
        if ( ref $_[0] eq 'HASH' ) {
            @args = %{ $_[0] };
        }
        elsif ( ref $_[0] eq 'ARRAY' ) {
            @args = @{ $_[0] };
        }
        elsif ( my $h = __PACKAGE__->_is_valid_fh( $_[0] ) ) {
            $self->{fh} = $h;
            @args = ();
        }
        elsif ( !ref $_[0] ) {
            $self->{file} = $_[0];
            @args = ();
        }
        else {
            carp "Single argument must be either a hash ref or a filename!";
            return undef;
        }
    }
    else {
        @args = @_;
    }
    croak "Final number of arguments not even"
        if @args % 2;

    %$self = ( %$self, @args );

    if ( exists $self->{version} ) {
        $self->{'SVN-fs-dump-format-version'} = $self->{version};
        delete $self->{version};
    }

    return $self;
}

sub dump {
    require Data::Dumper;
    my $self = shift;
    print STDERR Data::Dumper->Dump( [ \$self ], ['*self'] );
}

sub uuid : lvalue {
    my ( $self, $uuid ) = @_;
    $self->{'UUID'} = $uuid
        if defined $uuid;
    $self->{'UUID'};
}

sub version : lvalue {
    my ( $self, $version ) = @_;
    $self->{'SVN-fs-dump-format-version'} = $version
        if defined $version;
    $self->{'SVN-fs-dump-format-version'};
}

sub read_node {
    my $self = shift;
    my $node = SVN::Dumpfile::Node->new;
    return unless $self->{fh};
    $node = undef unless $node->read( $self->{fh} );

    return $node;
}
*get_node  = \&read_node;
*next_node = \&read_node;

sub write_node {
    my $self = shift;
    my $node = shift;

    return if not defined $node;

    return $node->write( $self->{fh} );
}

sub create {
    my $self = shift;
    if ( ref $self ) {
        return unless $self->_process_arguments(@_);
    }
    else {
        $self = $self->new(@_);
    }

    my $fh   = $self->{fh};
    my $file = $self->{file};
    if ( defined $fh ) {
        eval { $fh->binmode };
    }
    elsif ( defined $file ) {
        $self->{fh} = $fh = new IO::File;
        $fh->open( $file, '>' ) or croak "Couldn't create file.";
    }
    else {
        croak __PACKAGE__ . '::create() needs file name or handle.';
    }

    $fh->print( $self->as_string );
    return $self;
}

sub as_string {
    my $self   = shift;
    my $string = '';

    no warnings 'uninitialized';
    $self->{'SVN-fs-dump-format-version'} = 2
        if ( $self->{'SVN-fs-dump-format-version'} < 1 );

    $string
        = "SVN-fs-dump-format-version: "
        . $self->{'SVN-fs-dump-format-version'}
        . $NL x 2;

    if ( $self->{'SVN-fs-dump-format-version'} > 1 ) {
        if ( $self->{'UUID'} eq '' ) {
            $self->{'UUID'} = eval {

                # Use Data::GUID if available
                require Data::GUID;
                lc ( Data::GUID->new->as_string );
            } || eval {

                # Use Data::UUID if available
                require Data::UUID;
                my $ug       = new Data::UUID;
                my $uuid_bin = $ug->create();
                lc( $ug->to_string($uuid_bin) );
            } || do {
                my @r;

                # Otherwise just generate a random UUID
                push( @r, rand( 2**16 - 1 ) ) for ( 1 .. 9 );
                sprintf( "%04x%04x-%04x-%04x-%04x-%04x%04x%04x", @r );
            }
        }

        $string .= "UUID: $self->{UUID}" . $NL x 2;
    }

    return $string;
}
*to_string = \&as_string;

sub copy {
    my $self = shift;
    my $new  = $self->new();
    foreach my $key (qw(SVN-fs-dump-format-version UUID)) {
        $new->{$key} = $self->{$key};
    }
    return $new;
}

sub DESTROY {
    shift->close;
}

sub close {
    my $self = shift;
    $self->{fh}->close
        if defined $self->{fh};
}

sub version_supported {
    my $self    = shift;
    my $version = shift;
    if ( ref $self and not defined $version ) {
        $version = $self->{'SVN-fs-dump-format-version'};
    }

    return unless defined $version;

    # Versions 1 - 3 are supported
    return ( $version >= 1 && $version <= 3 );
}

sub _is_valid_fh {
    my $self = shift;
    my $h    = shift;
    return if not defined $h;
    return $h if eval { $h->isa('IO::Handle') };
    no strict 'refs';
    return *$h{IO}
        if ref $h eq 'GLOB'
            or ref \$h eq 'GLOB'
            or $h      eq 'STDIN'
            or $h      eq 'STDOUT';
    return;
}

sub _is_stdin {
    no warnings 'uninitialized';
    my $self = shift;
    my $file = shift;
    return ( $file eq '' or $file eq '-' or $file eq 'STDIN' );
}

sub _is_stdout {
    no warnings 'uninitialized';
    my $self = shift;
    my $file = shift;
    return ( $file eq '' or $file eq '-' or $file eq 'STDOUT' );
}

sub open {
    my $self = shift;
    if ( ref $self ) {
        return unless $self->_process_arguments(@_);
    }
    else {
        $self = $self->new(@_);
    }
    my $fh   = $self->{fh};
    my $file = $self->{file};
    if ( defined $fh ) {
        eval { $fh->binmode };
    }
    elsif ( defined $file ) {
        $self->{fh} = $fh = new IO::File;
        if ( !$fh->open( $file, '<' ) ) {
            carp "Couldn't open dumpfile.";
            return;
        }
    }
    else {
        croak __PACKAGE__ . '::open() needs file name or handle.';
    }

    my $irs  = IO::Handle->input_record_separator($NL);
    my $line = $fh->getline;
    if ( $line =~ /^SVN-fs-dump-format-version: (\d+)$/ ) {
        $self->{'SVN-fs-dump-format-version'} = $1;
        if ( !$self->version_supported ) {
            carp "Warning: Found dump format version ",
                $self->{'SVN-fs-dump-format-version'},
                " is not supported (yet).\n",
                "Unknown entries will be ignored. Use at your own risk.\n";
        }
    }
    else {
        carp "Error: Dumpfile looks invalid. Couldn't find valid ",
            "'SVN-fs-dump-format-version' header.\n";
    }

    if ( $self->{'SVN-fs-dump-format-version'} > 1 ) {
        my $char;
        while ( ( $char = $fh->getc ) eq "\012" ) { }
        if ( $char eq 'U' ) {
            $line = $char . $fh->getline;
            if ( $line =~ /^UUID: (.*)$/ ) {
                $self->{'UUID'} = $1;

                # read blank line after UUID:
                $char = $fh->getc;
                $fh->ungetc( ord $char ) if ( $char ne "\012" );
            }
            else {
                carp "Error: Dumpfile looks invalid. Couldn't find valid ",
                "'UUID' header.\n";
            }
        }
        else {
            carp "Error: Dumpfile looks invalid. Couldn't find valid ",
            "'UUID' header.\n";
            $fh->ungetc( ord $char );
        }
    }

    IO::Handle->input_record_separator($irs);
    return $self;
}

1;
__END__

# Documentation

=head1 NAME

SVN::Dumpfile - Perl extension to access and manipulate Subversion dumpfiles

=head1 SYNOPSIS

  use SVN::Dumpfile;

  # Opens existing dumpfile:
  my $olddf = SVN::Dumpfile->new(file => "old.dump"); 
  # Creates new dumpfile with same version and UUID as old one:
  my $newdf = $olddf->copy->create(file => "new.dump"); 

  # Read old dumpfile node by node
  while ( my $node = $olddf->read_node ) {
      # Manipulate current node:
      $node->header("some header","new value");
      $node->property("some property","new value");
      $node->changed;

      # Write to new dumpfile
      $newdf->write_node($node);
  }


=head1 DESCRIPTION

SVN::Dumpfile represents a Subversion (http://subversion.tigris.org/) dumpfile.
It provides methods to read existing and write modified or new dumpfiles. It
supports dumpfiles with the version number 1 - 3 but was written in a tolerant
way to also support newer versions as long no major changes are made.

This module is a OO redesign and generalisation of
L<SVN::Dumpfilter|SVN::Dumpfilter> v0.21.  Newer versions of
L<SVN::Dumpfilter|SVN::Dumpfilter> are using it to access the input and output
dumpfiles.

The ability to create new dumpfiles sets it apart from the similar module
L<SVN::Dump|SVN::Dump>. The submodule
L<SVN::Dumpfile::Node::Properties|SVN::Dumpfile::Node::Properties> also allows 
the processing of Subversion revision property files (i.e. the files lying in 
the $REPOSITORY/db/revprops/ directory holding the author, date and log entry of
every revision).

=head1 EXPORT

Nothing, because it's an Object Oriented module.

=head1 SEE ALSO

Authors Module Website: L<http://www.scharrer-online.de/svn/>

Other man pages of sub-classes:

=over 8

=item L<SVN::Dumpfile::Node|SVN::Dumpfile::Node>

=item L<SVN::Dumpfile::Node::Headers|SVN::Dumpfile::Node::Headers>

=item L<SVN::Dumpfile::Node::Properties|SVN::Dumpfile::Node::Properties>

=item L<SVN::Dumpfile::Node::Content|SVN::Dumpfile::Node::Content>

=back

=head1 AUTHOR

Martin Scharrer, E<lt>martin@scharrer-online.deE<gt>; 
L<http://www.scharrer-online.de/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Martin Scharrer

This library is free software; you can redistribute it and/or modify
it under the GPL v3 or the same terms as Subversion or Perl itself, either Perl 
version 5.8.8 or, at your option, any later version of Perl 5 you may have 
available.

=head1 METHODS

=over 4

=item new()

Constructor. Returns a new SVN::Dumpfile object. Attributes can be given as
hash reference or as even array with key/value pairs. If only one argument is
given it will be taken as dumpfile name. The following attributes can be used:

=over 6

=item file

The file name of the dumpfile.

=item version

The version number of the dumpfile.

=item UUID

The UUID of the dumpfile.

=back

Please note that if the represented dumpfile is given by name it is not opened 
yet. open() has to be called first.

=item uuid()

Returns or sets the UUID of the dumpfile. A lvalue of the internal UUID is
returned, so the new UUID can be given as the first argument or assigned
directly to the function:

    $df->uuid                   # Returns uuid
    $df->uuid($newuuid)         # Set new uuid
    $df->uuid = $newuuid        # Set new uuid


=item version()

Returns or sets the version of the dumpfile. A lvalue of the internal version is
returned, so the new version can be given as the first argument or assigned
directly to the function:

    $df->version                # Returns version
    $df->version($newuuid)      # Sets new version
    $df->version = $newuuid     # Sets new version


=item open()

Opens a existing dumpfile. The file name can be given as argument or is taken
from the instance. Will reopen the file if called a second time.
Can be called as class or instance method. Returns a reference on the new or
calling object or undef on failure.

=item copy()

Creates a new SVN::Dumpfile instance with the same version and UUID as the
instance it was called upon. No other informations are copied.

=item create()

Creates and opens a new dumpfile on the harddisk. Can be called as class or
instance method. The file name can be given as an argument or is taken from the
instance.
Returns a reference on the new or calling object or undef on failure.

=item as_string()

=item to_string()

Returns the dumpfile header lines as string. These are the first lines of the
dumpfile and do not hold any node information, i.e. this doesn't return the
whole dumpfile. At the moment the only header lines are the dumpfile version
and, starting from version 2, the UUID. This method is called by create() to
write out the dumpfile head.


=item read_node()

=item next_node()

=item get_node()

Returns the next node of the dumpfile as SVN::Dumpfile::Node instance.
Alternative names are C<get_node> or C<next_node>.

=item write_node()

Awaits a SVN::Dumpfile::Node instance and writes this to the dumpfile.

=item close()

Closes the dumpfile. This will be called automatically when the dumpfile
reference is going out of scope.

=item version_supported()

Returns true if given version number is supported by SVN::Dumpfile. Can be
called as class or instance method. If called on an instance and the version 
number is not given as an argument the internal version is taken.

=item dump()

Dumps the object to STDERR using Data::Dumper for debugging.

=back

=begin internal

=over 4

=item _is_valid_fh()

Checks if given argument is either
a file glob, file glob reference or a IO::Handle object.
Returns the argument if so and undef else.


=item _is_stdin()

Returns true if given argument is either undefined/empty, the string '-' or 
'STDIN'.


=item _is_stdout()

Returns true if given argument is either undefined/empty, the string '-' or
'STDOUT'.


=item _process_arguments()

Processes the arguments given to new(), open() and create() and install them
into the object. It accepts the following arguments: single hash ref, single
array ref, even list, single scalar taken as file handle or name. One single
undefined argument is ignored for interface reasons. All other kinds of single 
arguments will cause a warning and will be ignored. Odd lists or array refs
pointing to odd arrays will result in an error, i.e. croak().

=back

=end internal


