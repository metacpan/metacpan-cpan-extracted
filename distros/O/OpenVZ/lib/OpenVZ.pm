package OpenVZ;

# no critic qw( ErrorHandling::RequireUseOfExceptions )

# ABSTRACT: Base class for OpenVZ utilities like vzctl

#XXX: We need to load and parse the VZ system config file.


use 5.006;

use strict;
use warnings;

# This way, we don't need to remember to use autoclean in our submodules.
#use namespace::autoclean ();
#sub import { return namespace::autoclean->import( -cleanee => scalar caller ) }
use namespace::sweep ();
sub import { return namespace::sweep->import( -cleanee => scalar caller, -also => qr/^_\w*$/ ) }

use Carp;

#use Config::NameValue;
#use Regexp::Common qw( URI net );

use File::Which;
use IPC::Run3::Simple;
use Params::Validate qw( validate ARRAYREF );
use Scalar::Util 'blessed';
use Sub::Exporter;
use Sub::Exporter::Util 'curry_method';
use Sub::Exporter::ForMethods 'method_installer';

our $VERSION = '0.01'; # VERSION

############################################################################
# Public Functions


{  # Quick! Hide!!

    my @exports;

    # @exports holds the names of functions to be exported.  The easiest way to
    # maintain this is to push the name of the function right before it is
    # defined.

    #push @exports, 'new';

    my $object; ## no critic qw( Bangs::ProhibitVagueNames )

    sub new { ## no critic qw( Bangs::ProhibitVagueNames Subroutines::RequireArgUnpacking )

        shift if blessed $_[0] or $_[0] eq __PACKAGE__;
        croak 'OpenVZ is designed to be an abstract class' if @_ == 0;
        return bless \$object, ref $_[0] || $_[0]; ## no critic qw( Bangs::ProhibitVagueNames )

    }
    ## use critic

    my %program;

    # Determines if the specified command is installed, what its path is and
    # caches it. Used in execute.

    my $find_command = sub {

        shift if blessed $_[0] or $_[0] eq __PACKAGE__;

        #my ( $pgm, $params ) = @_;
        my $pgm = shift;

        return 1
            if exists $program{ path }{ $pgm };

        $program{ path }{ $pgm } = which( $pgm )
            or croak "Could not find $pgm in path ($ENV{PATH})";

        return 1;

    };

    push @exports, 'execute';

    sub execute { ## no critic qw( Subroutines::RequireArgUnpacking )

        # We're doing the funky twisty stuff here so we can handle either functional or oop style calls.
        # I think this is because of the way Sub::Exporter handles things, but I'm not sure.
        shift if blessed $_[0] or $_[0] eq __PACKAGE__;
        shift if blessed $_[0];

        my %arg = validate(
            @_, {
                'command' => { callbacks => { 'find command path' => $find_command } },
                'params' => { type => ARRAYREF, optional => 1 },
            } );

        # XXX: Need to handle also the case of a hashref

        my @args = $program{ path }{ $arg{ command } };
        push @args, @{ $arg{ params } } if exists $arg{ params };
        return run3( \@args );

    } ## end sub execute

############################################################################
    # Utility Functions - not for general consumption

############################################################################
    # Setup exporter

    my %exports = map { ( $_ => curry_method ) } @exports;

    my $config = {

        exports   => \%exports,
        installer => method_installer,

    };

    Sub::Exporter::setup_exporter( $config );

} ## end hiding

1;

__END__
=pod

=for :stopwords Alan Young OpenVZ vzctl vzlist STDOUT STDERR hashref params

=encoding utf-8

=head1 NAME

OpenVZ - Base class for OpenVZ utilities like vzctl

=head1 VERSION

  This document describes v0.01 of OpenVZ - released April 17, 2012 as part of OpenVZ.

=head1 SYNOPSIS

  use parent 'OpenVZ';

  #XXX: need to add more examples

=head1 DESCRIPTION

This is a base class for OpenVZ utilities like vzctl and vzlist.  It shouldn't
be used generally outside of this framework.

=head1 FUNCTIONS

=head2 new

If you prefer an object oriented interface then just C<use OpenVZ::submodule> and
call the new function.  All of the following functions will be available as
methods.

  $vzctl = OpenVZ::vzctl->new;
  $vzctl->set({ ctid => 101, name => 'user101', save => '' });

=head2 execute

This function should not be called directly unless you know what you're doing.

C<execute> uses L<IPC::Run3::Simple>'s C<run3> function to make system calls.
C<run3> returns whatever is sent to STDOUT, STDERR and the exit value as well
as the execution time of the system call.

This function is the workhorse of this package.  It expects the following
parameters as a hashref

  command => program name to be called (e.g., vzctl) (STRING)
  params  => parameters to be passed to the command to be called (ARRAYREF)

C<params> is optional.

The params value will not be checked for validity.  It is assumed that if you
are calling this subroutine you have already validated whatever is going to be
passed on the command line.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

