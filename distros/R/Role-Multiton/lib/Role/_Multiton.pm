package Role::_Multiton;

use strict;
use warnings;

$Role::_Multiton::VERSION = '0.2';

sub _get_multiton_lookup_hr {
    my ($self) = @_;
    my $class = ref($self) || $self || '';

    no strict 'refs';    ## no critic
    return ${ $class . '::_multitons' } ||= {};
}

sub _get_arg_key {
    my ($arg_ar) = @_;
    my $arg_key;

    if ( !defined $arg_ar ) {
        $arg_ar = [];
    }
    else {
        $arg_ar = [ map { $_ => $arg_ar->[0]{$_} } sort keys %{ $arg_ar->[0] } ] if @{$arg_ar} == 1 && ref( $arg_ar->[0] ) eq 'HASH';
    }

    for my $arg ( @{$arg_ar} ) {
        if ( !defined $arg ) {
            $arg_key .= 'undef(),';
        }
        elsif ( my $ref = ref($arg) ) {
            $arg_key .= "$ref($arg),";    # ? need to expand further or YAGNI ?
        }
        else {
            my $copy = $arg;
            $copy =~ s/'/\\'/g;
            $arg_key .= "'$copy',";
        }
    }

    if ( defined $arg_key ) {
        $arg_key =~ s/,$//;
        return "($arg_key)";
    }
    else {
        return '()';
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Role::_Multiton - internal util for Role::Multiton[::*]

=head1 VERSION

This document describes Role::_Multiton version 0.2

=head1 SYNOPSIS

    use Role::_Multiton ();
    # use all the things!

=head1 DESCRIPTION

Internal util for Role::Multiton[::*]. Don’t use directly as it could change in any way at any time.

=head1 INTERFACE 

These are all functions.

=head2 _get_multiton_lookup_hr()

Takes a class or object whose multiton lookup you want.

Instantiates (if needed) and returns the class’s multiton lookup.

=head2 _get_arg_key()

Takes an array ref of the values passed to new(). That array can contain a single hashref ins support of new({…}) style syntax.

Returns a stringified version of those values to serve as a multiton’s identifier.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Role::_Multiton requires no configuration files or environment variables.

=head1 DEPENDENCIES

None

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-role-multiton@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
