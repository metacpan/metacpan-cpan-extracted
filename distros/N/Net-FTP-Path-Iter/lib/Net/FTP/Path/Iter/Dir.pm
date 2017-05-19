package Net::FTP::Path::Iter::Dir;

# ABSTRACT: Class representing a Directory

use 5.010;
use strict;
use warnings;
use experimental 'switch';

our $VERSION = '0.04';

use Carp;
use Fcntl qw[ :mode ];

use File::Spec::Functions qw[ catdir catfile ];

use namespace::clean;

use parent 'Net::FTP::Path::Iter::Entry';

use Net::FTP::Path::Iter::File;

use constant is_file => 0;
use constant is_dir  => 1;

sub _children {

    my $self = shift;

    my %attr = ( server => $self->server, );

    my $entries = $self->_get_entries( $self->path );

    my @children;

    for my $entry ( @$entries ) {

        my $obj;

        for ( $entry->{type} ) {

            when ( 'd' ) {

                $obj = Net::FTP::Path::Iter::Dir->new( %$entry, %attr,
                    path => catdir( $self->path, $entry->{name} ) );
            }

            when ( 'f' ) {

                $obj = Net::FTP::Path::Iter::File->new( %$entry, %attr,
                    path => catfile( $self->path, $entry->{name} ) );
            }

            default {

                warn( "ignoring $entry->{name}; unknown type $_\n" );
            }

        }

        push @children, $obj;
    }

    return @children;

}

# if an entity doesn't have attributes, it didn't get loaded
# from a directory listing.  Try to get one.  This should
# happen rarely, so do this slowly but correctly.
sub _retrieve_attrs {

    my $self = shift;

    return if $self->_has_attrs;

    my $server = $self->server;

    my $pwd = $server->pwd;

    my $entry = {};

    $server->cwd( $self->path )
      or croak( "unable to chdir to ", $self->path, "\n" );

    # File::Listing doesn't return . or .. (and some FTP servers
    # don't return that info anyway), so try to go up a dir and
    # look for the name
    eval {

        # cdup sometimes returns ok even if it didn't work
        $server->cdup;

        if ( $pwd ne $server->pwd ) {

            my $entries = $self->_get_entries( '.' );

            ( $entry ) = grep { $self->name eq $_->{name} } @$entries;

            croak( "unable to find attributes for ", $self->path, "\n" )
              if !$entry;

            croak( $self->path, ": expected directory, got $entry->{type}\n" )
              unless $entry->{type} eq 'd';

        }

        # couldn't go up a directory; at the top?
        else {

            # fake it.

            $entry = {
                size  => 0,
                mtime => 0,
                mode  => S_IRUSR | S_IXUSR | S_IRGRP | S_IXGRP | S_IROTH
                  | S_IXOTH,
                type => 'd',
                _has_attrs => 1,
            };

        }

    };

    my $err = $@;

    $server->cwd( $pwd )
      or croak( "unable to return to directory: $pwd\n" );

    croak( $err ) if $err;

    $self->$_( $entry->{$_} ) for keys %$entry;
    return;
}

#
# This file is part of Net-FTP-Path-Iter
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
1;

__END__

=pod

=head1 NAME

Net::FTP::Path::Iter::Dir - Class representing a Directory

=head1 VERSION

version 0.04

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-FTP-Path-Iter>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::FTP::Path::Iter|Net::FTP::Path::Iter>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
