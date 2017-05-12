package SPOPS::HashFile;

# $Id: HashFile.pm,v 3.4 2004/06/02 00:48:21 lachoy Exp $

use strict;
use base  qw( SPOPS );
use Data::Dumper;

$SPOPS::HashFile::VERSION  = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

# Just grab the tied hash from the SPOPS::TieFileHash

sub new {
    my ( $pkg, $p ) = @_;
    my $class = ref $pkg || $pkg;
    my ( %data );
    my $int = tie %data, 'SPOPS::TieFileHash', $p->{filename}, $p->{perm};
    my $object = bless( \%data, $class );
    $object->initialize( $p );
    return $object;
}

# Subclasses can override

sub initialize { return 1 }

sub class_initialize {
    my $class = shift;
    return $class->_class_initialize( @_ );
}


# Just pass on the parameters to 'new'

sub fetch {
    my ( $class, $filename, $p ) = @_;
    $p ||= {};
    return undef unless ( $class->pre_fetch_action( $filename, $p ) );
    my $object = $class->new( { filename => $filename, %{ $p } } );
    return undef unless( $object->post_fetch_action( $filename, $p ) );
    return $object;
}


# Ensure we can write and that the filename is kosher, then
# dump out the data to the file.

sub save {
    my ( $self, $p ) = @_;
    my $obj = tied %{ $self };

    unless ( $obj->{perm} eq 'write' ) {
        SPOPS::Exception->throw( "Cannot save [$obj->{filename}]; opened as read-only" );
    }

    unless ( $obj->{filename} ) {
        SPOPS::Exception->throw( "Cannot save data: the filename has been " .
                                 "erased. Did you assign an empty hash to the object?" );
    }

    my $temp_filename = "$obj->{filename}.tmp";
    if ( -f $temp_filename ) {
        unlink( $temp_filename ); # just to be sure...
    }
    if ( -f $obj->{filename} ) {
        rename( $obj->{filename}, $temp_filename ) ||
              SPOPS::Exception->throw( "Cannot rename old file to make room for new one. Error: $!" );
    }

    return undef unless ( $self->pre_save_action( $p ) );

    my %data = %{ $obj->{data} };
    $p->{dumper_level} ||= 2;
    local $Data::Dumper::Indent = $p->{dumper_level};

    eval { open( INFO, "> $obj->{filename}" ) || die $! };
    if ( $@ ) {
        rename( $temp_filename, $obj->{filename} ) ||
              SPOPS::Exception->throw( "Cannot open file for writing [$@] and " .
                                       "cannot move backup file to original place [$!]" );
        SPOPS::Exception->throw( "Cannot open file for writing [$@]. Backup file restored ok." );
    }
    print INFO Data::Dumper->Dump( [ \%data ], [ 'data' ] );
    close( INFO );
    if ( -f $temp_filename ) {
        unlink( $temp_filename )
              || warn "Cannot remove the old data file. It still lingers in ($temp_filename)\n";
    }
    return undef unless ( $self->post_save_action( $p ) );
    return $self;
}


sub remove {
    my ( $self, $p ) = @_;
    my $obj = tied %{ $self };
    unless ( $obj->{perm} eq 'write' ) {
        SPOPS::Exception->throw( "Cannot save [$obj->{filename}]; opened as read-only" );
    }
    unless ( $obj->{filename} ) {
        SPOPS::Exception->throw( "Cannot remove data: the filename has been " .
                                 "erased. Did you assign an empty hash to the object?" );
    }
    return undef unless ( $self->pre_remove_action( $p ) );
    my $rv = %{ $self } = ();
    return undef unless ( $self->post_remove_action( $p ) );
    return $rv;
}


# Create a new object from an old one, allowing any passed-in
# values to override the ones from the old object

sub clone {
    my ( $self, $p ) = @_;
    unless ( $p->{filename} ) {
        $p->{filename} = (tied %{ $self })->{filename};
    }
    my $new = $self->new({ filename => $p->{filename}, perm => $p->{perm} });
    while ( my ( $k, $v ) = each %{ $self } ) {
        $new->{ $k } = $p->{ $k } || $v;
    }
    return $new;
}



package SPOPS::TieFileHash;

use strict;
use File::Copy qw( cp );

$SPOPS::TieFileHash::VERSION  = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

# These are all very standard routines for a tied hash; more info: see
# 'perldoc Tie::Hash'

# Ensure that the file exists and can be read (unless they pass in
# 'new' for the permissions, which means it's ok to start out with
# blank data); store the meta info (permission and filename) in the
# object, and the 'data' key holds the actual information

sub TIEHASH {
    my ( $class, $filename, $perm ) = @_;
    $perm ||= 'read';
    if ( $perm !~ /^(read|write|new|write\-new)$/ ) {
        SPOPS::Exception->throw( "Invalid permissions [$perm]; valid: [read|write|new|write-new]" );
    }
    unless ( $filename ) {
        SPOPS::Exception->throw( "You must pass a filename to use for reading and writing." );
    }
    my $file_exists = ( -f $filename );
    unless ( $file_exists ) {
        if ( $perm eq 'write-new' or $perm eq 'new' ) {
            $perm = 'new';
        }
        else {
            SPOPS::Exception->throw( "Cannot create object without existing file " .
                                     "or 'new' permission [$filename] [$perm]" );
        }
    }
    $perm = 'write' if ( $perm eq 'write-new' );

    my $data = undef;
    if ( $file_exists ) {

        # First create a backup...

        cp( $filename, "${filename}.backup" );

        # Then open up the file

        open( PD, $filename ) ||
            SPOPS::Exception->throw( "Cannot open [$filename]:  $!" );
        local $/ = undef;
        my $info = <PD>;
        close( PD );

        # Note that we create the SIG{__WARN__} handler here to trap any
        # messages that might be sent to STDERR; we want to capture the
        # message and send it along in a 'die' instead

        {
            local $SIG{__WARN__} = sub { return undef };
            no strict 'vars';
            $data = eval $info;
        }
        if ( $@ ) {
            SPOPS::Exception->throw( "Error reading in perl code: $@" );
        }
    }
    else {
        $data = {};
        $perm = 'write';
    }
    return bless({ data     => $data,
                   filename => $filename,
                   perm     => $perm }, $class );
}


sub FETCH  {
    my ( $self, $key ) = @_;
    return undef unless $key;
    return $self->{data}->{ $key };
}


sub STORE  {
    my ( $self, $key, $value ) = @_;
    return undef unless $key;
    return $self->{data}->{ $key } = $value;
}


sub EXISTS {
    my ( $self, $key ) = @_;
    return undef unless $key;
    return exists $self->{data}->{ $key };
}


sub DELETE {
    my ( $self, $key ) = @_;
    return undef unless $key;
    return delete $self->{data}->{ $key };
}


# This allows people to do '%{ $obj } = ();' and remove the object; is
# this too easy to mistakenly do? I don't think so.

sub CLEAR {
    my ( $self ) = @_;
    if ( $self->{perm} ne 'write' ) {
        SPOPS::Exception->throw( "Cannot remove [$self->{filename}]; " .
                                 "permission set to read-only" );
    }
    unlink( $self->{filename} ) ||
            SPOPS::Exception->throw( "Cannot remove [$self->{filename}]: $!" );
    $self->{data} = undef;
    $self->{perm} = undef;
}


sub FIRSTKEY {
    my ( $self ) = @_;
    keys %{ $self->{data} };
    my $first_key = each %{ $self->{data} };
    return undef unless ( $first_key );
    return $first_key;
}


sub NEXTKEY {
    my ( $self ) = @_;
    my $next_key = each %{ $self->{data} };
    return undef unless ( $next_key );
    return $next_key;
}


1;

__END__

=pod

=head1 NAME

SPOPS::HashFile - Implement as objects files containing perl hashrefs
dumped to text

=head1 SYNOPSIS

 my $config = SPOPS::HashFile->new({ filename => '/home/httpd/myapp/server.perl',
                                     perm     => 'read' } );
 print "My SMTP host is $config->{smtp_host}";

 # Setting a different value is ok...
 $config->{smtp_host} = 'smtp.microsoft.com';

 # ...but this will throw an exception since you set the permission to
 # read-only 'read' in the 'new' call
 $config->save;

=head1 DESCRIPTION

Implement a simple interface that allows you to use a perl data
structure dumped to disk as an object. This is often used for
configuration files, since the key/value, and the flexibility of the
'value' part of the equation, maps well to varied configuration
directives.

=head1 METHODS

B<new( { filename =E<gt> $, [ perm =E<gt> $ ] } )>

Create a new C<SPOPS::HashFile> object that uses the given filename
and, optionally, the given permission. The permission can be one of
three values: 'read', 'write' or 'new'. If you try to create a new
object without passing the 'new' permission, the action will die
because it cannot find a filename to open. Any value passed in that is
not 'read', 'write' or 'new' will get changed to 'read', and if no
value is passed in it will also be 'read'.

Note that the 'new' permission does B<not> mean that a new file will
overwrite an existing file automatically. It simply means that a new
file will be created if one does not already exist; if one does exist,
it will be used.

The 'read' permission only forbids you from saving the object or
removing it entirely. You can still make modifications to the data in
the object.

This overrides the I<new()> method from SPOPS.

B<fetch( $filename, [ { perm =E<gt> $ } ] )>

Retrieve an existing config object (just a perl hashref data
structure) from a file. The action will result in a 'die' if you do
not pass a filename, if the file does not exist or for any reason you
cannot open it.

B<save>

Saves the object to the file you read it from.

B<remove>

Deletes the file you read the object from, and blanks out all data in
the object.

B<clone( { filename =E<gt> $, [ perm =E<gt> $ ] } )>

Create a new object from the old, but you can change the filename and
permission at the same time. Example:

 my $config = SPOPS::HashFile->new( { filename => '~/myapp/spops.perl' } );
 my $new_config = $config->clone( { filename => '~/otherapp/spops.perl',
                                    perm => 'write' } );
 $new_config->{base_dir} = '~/otherapp/spops.perl';
 $new_config->save;

This overrides the I<clone()> method from SPOPS.

=head1 NOTES

B<No use of SPOPS::Tie>

=head1 TO DO

B<Use SPOPS::Tie>

This is one of the few SPOPS implementations that will never use the
C<SPOPS::Tie> class to implement its data holding. We still use a tied
hash, but it is much simpler -- no field checking, no ensuring that
the keys match in case, etc. This just stores some information about
the object (filename, permission, and data) and lets you go on your
merry way.

However, since we recently changed L<SPOPS::Tie|SPOPS::Tie> to make
field-checking optional we might be able to use it.

=head1 BUGS

=head1 SEE ALSO

L<SPOPS|SPOPS>

L<Data::Dumper|Data::Dumper>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>

=cut
