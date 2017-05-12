package Net::Route::Parser;

use 5.008;
use Moose;
use English qw( -no_match_vars );
use POSIX qw( WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG WIFSTOPPED WSTOPSIG );
use Readonly;
use Exporter qw( import );
use version; our ( $VERSION ) = '$Revision: 363 $' =~ m{(\d+)}xms;
use IPC::Run3;

# /m is broken in <5.10
## no critic (RegularExpressions::RequireLineBoundaryMatching)

# Very loose matching, it's just meant to filter lines
Readonly our $IPV4_RE  => qr/ (?: \d+ \.){3} \d+ /xs;
Readonly our $IPV6_RE  => qr/ (?: \p{IsXDigit}+ : :? )+ \p{IsXDigit}+ /xs;
Readonly our $IP_RE    => qr/ (?: $IPV4_RE | $IPV6_RE ) /xs;
Readonly our $ROUTE_RE => qr/^ \s* ($IP_RE) \s+ ($IP_RE) \s+ ($IP_RE) \s+ ($IP_RE) \s+ (\d+) \s* $ /xs;

## use critic

our %EXPORT_TAGS = ( ip_re    => [qw($IPV4_RE $IPV6_RE $IP_RE)],
                     route_re => [qw($ROUTE_RE)], );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'ip_re'} }, @{ $EXPORT_TAGS{'route_re'} }, );

sub create_ip_object
{
    my ( $self, $address, $mask ) = @_;

    my $ip_object_ref = NetAddr::IP->new( $address, $mask );

    if ( !defined $ip_object_ref )
    {
        $mask = defined $mask ? $mask : q{};
        die "Cannot create ip object (address: $address, mask: $mask)";
    }
    else
    {
        return $ip_object_ref;
    }
}

sub from_system
{
    my ( $self ) = @_;

    my $command_ref = $self->command_line();
    my $human_command = ref $command_ref ? ( join q{ }, @{$command_ref} ) : $command_ref;

    my @routes_as_text;
    if ( !eval { IPC::Run3::run3( $command_ref, undef, \@routes_as_text ); 1 } )
    {
        die "Cannot execute '$human_command': $EVAL_ERROR";
    }

    if ( $CHILD_ERROR )
    {
        if ( $OSNAME eq 'MSWin32' )
        {
            die "'$human_command' returned non-zero value $CHILD_ERROR";
        }
        elsif ( WIFSIGNALED( $CHILD_ERROR ) )
        {
            die "'$human_command' died with signal ", WTERMSIG( $CHILD_ERROR );
        }
        elsif ( WEXITSTATUS( $CHILD_ERROR ) )
        {
            die "'$human_command' returned non-zero value ", WEXITSTATUS( $CHILD_ERROR );
        }
    }

    chomp @routes_as_text;
    my $routes_ref = $self->parse_routes( \@routes_as_text );

    return $routes_ref;
}

no Moose;
__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 NAME

Net::Route::Parser - Internal class


=head1 SYNOPSIS

Not used directly.


=head1 VERSION

Revision $Revision: 363 $.


=head1 DESCRIPTION

This is a base class for the system-specific parsers. It is not usable directly
(abstract).

System-specific parsers should inherit from this class to obtain common
functionality.


=head1 INTERFACE

This interface is subject to change until version 1.


=head2 Object Methods

=head3 from_system()

Implementation of C<Net::Route::Table::from_system()>.

=head3 command_line() [pure virtual]

What you want to read the information from, as either:

=over

=item *

a string - it will undergo shell expansion

=item *

an arrayref - the command and its arguments, without shell expansion

=back

Implement this in subclasses.

=head3 parse_routes( $text_lines_ref ) [pure virtual]

Reads and parses the routes from the output of the command, returns an arrayref
of L<Net::Route> objects.

=head3 create_ip_object ( $address, $mask )

Factory of L<NetAddr::IP> objects for centralized error management. Dies if the
arguments do not constitute a valid IP or network address.

=head1 AUTHOR

Created by Alexandre Storoz, C<< <astoroz@straton-it.fr> >>

Maintained by Thomas Equeter, C<< <tequeter@straton-it.fr> >>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 Straton IT.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

