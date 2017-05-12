package OpenVZ::Vzlist;

# ABSTRACT: Call OpenVZ vzlist command from your program

#XXX: Need to handle version call
#XXX: Need to use 'on_fail' option for validate_with for smoother error
#     handling.


use 5.006;

use strict;
use warnings;

use namespace::autoclean;

use Carp;
use List::MoreUtils qw( any );
use OpenVZ ':all';
use Params::Validate ':all';
use Regexp::Common qw( URI net );
use Scalar::Util 'blessed';
use Sub::Exporter;

use parent 'OpenVZ';

our $VERSION = '0.01'; # VERSION

our $AUTOLOAD;


{  # "The secret to creativity is knowing how to hide your sources." -Albert Einstein

    ############################################################################
    # Public Functions

    my @vzlist_exports;

    push @vzlist_exports, 'execute';  # imported from OpenVZ

    ############################################################################

    my @fields = qw(

        bootorder cpulimit cpuunits ctid description hostname ioprio ip laverage name onboot ostemplate status uptime

    );

    push @fields, map { ( $_, "$_.h", "$_.s" ) } qw( diskinodes diskspace );

    push @fields, map { ( $_, "$_.b", "$_.f", "$_.l", "$_.m" ) } qw(

        dcachesize dgramrcvbuf kmemsize lockedpages numfile numflock numiptent numothersock numproc numpty numsiginfo numtcpsock
        oomguarpages othersockbuf physpages privvmpages shmpages swappages tcprcvbuf tcpsndbuf vmguarpages

    );

    my $fields_rx = join q{|}, @fields;

    push @vzlist_exports, 'known_fields';

    sub known_fields { return wantarray ? @fields : \@fields }

    ############################################################################

    my %spec = do {

        my %hash = (

            # XXX: Annoying.  Need to submit a bug for this.
            ## no critic qw( Variables::ProhibitPunctuationVars )
            all         => { type => UNDEF,  optional => 1 },
            description => { type => SCALAR, optional => 1, regex => qr/^.+$/ },
            output      => { type => SCALAR, optional => 1, regex => qr/^(?:$fields_rx)(?:,$fields_rx)*$/i },
            sort        => { type => SCALAR, optional => 1, regex => qr/^-?(?:$fields_rx)$/i },
            ## use critic

        );

        my %same = (

            all         => [qw( list name no-header stopped )],
            description => [qw( hostname name_filter )],

        );

        for my $key ( keys %same ) {

            $hash{ $_ } = $hash{ $key } for @{ $same{ $key } };

        }

        %hash;

    };

    my %hash = ( command => 'vzlist' );

    push @vzlist_exports, 'vzlist';  # imported from OpenVZ

    sub vzlist { ## no critic qw( Subroutines::RequireArgUnpacking )

        shift if blessed $_[0];

        my %arg = validate_with( params => \@_, spec => \%spec );

        my @params;

        for my $arg_name ( keys %arg ) {

            push @params, "--$arg_name";

            push @params, $arg{ $arg_name }
                if defined $arg{ $arg_name } && $arg{ $arg_name } ne '';

        }

        @params = grep { $_ ne '' } @params;

        $hash{ params } = \@params;

        return execute( \%hash );

    } ## end sub vzlist

    ############################################################################

    push @vzlist_exports, 'known_options';

    my @vzlist = map { "[$_]" } keys %spec;

    sub known_options { return wantarray ? @vzlist : \@vzlist }

    ############################################################################
    # Internal Functions

    # for oop stuff

    # XXX: Do we need/want to support methods for the various options (what is returned from subcommand_specs)?

    #    sub AUTOLOAD { ## no critic qw( Subroutines::RequireArgUnpacking ClassHierarchies::ProhibitAutoloading )
    #
    #        carp "$_[0] is not an object"
    #            unless blessed $_[0];
    #
    #        ( my $subcommand = $AUTOLOAD ) =~ s/^.*:://;
    #
    #        carp "$subcommand is not a valid method"
    #            unless exists $vzctl{ $subcommand };
    #
    #        ## no critic qw( TestingAndDebugging::ProhibitNoStrict References::ProhibitDoubleSigils )
    #        no strict 'refs';
    #        *$AUTOLOAD = _generate_subcommand( undef, $subcommand );
    #
    #        goto &$AUTOLOAD;
    #        ## use critic
    #
    #    } ## end sub AUTOLOAD
    #
    #    # AUTOLOAD assumes DESTROY exists
    #    DESTROY { }
    #
    #    push @vzctl_exports, ( $_ => \&_generate_subcommand ) for keys %vzctl;

    ############################################################################
    # Setup exporter

    my $config = {

        exports    => \@vzlist_exports,
        groups     => {},
        collectors => [],

    };

    Sub::Exporter::setup_exporter( $config );

}  # Coming out from under!

1;

__END__
=pod

=for :stopwords Alan Young vzlist

=encoding utf-8

=head1 NAME

OpenVZ::Vzlist - Call OpenVZ vzlist command from your program

=head1 VERSION

  This document describes v0.01 of OpenVZ::Vzlist - released April 17, 2012 as part of OpenVZ.

=head1 SYNOPSIS

  use OpenVZ::Vzlist;

  #XXX: need to add more examples

=head1 DESCRIPTION

This program is a simple (or not so simple in some cases) wrapper around the 'vzlist' program.  It will do some basic verification
on options and parameters but it will not (currently) do sanity checks on the values.

=head2 NOTE

All of the commands for vzlist are implemented and all of the options for each command is provided for, but some commands and options
I don't use so I'm not sure how to test them.  Tests are welcome.

If you want to know what commands and options are available read C<vzlist>s man page.  I followed that in creating this module.

=head1 FUNCTIONS

=head2 vzlist

=head2 known_fields

Returns a list of known fields for the output and sort options.

=head2 known_options

Given a command, returns a list of known options

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<OpenVZ|OpenVZ>

=back

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

