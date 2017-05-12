package RPC::ExtDirect::Demo::Profile;

use strict;
use warnings;

use RPC::ExtDirect Action => 'Profile';

sub updateBasicInfo : ExtDirect(formHandler) {
    my ($class, %fields) = @_;

    if ( $fields{email} eq 'aaron@sencha.com' ) {
        return {
                    success => \0,              # Shortcut for JSON::false
                    errors  => { email => 'already taken' },
                    debug_formPacket   => \%fields,
               };
    }
    else {
        return {
                    success          => \1,     # Shortcut for JSON::true
                    debug_formPacket => \%fields
               };
    };
}

sub getBasicInfo : ExtDirect(2) {
    my ($class, $userId, $foo) = @_;

    return {
                success => \1,
                data => {
                            foo     => $foo,
                            name    => 'Aaron Conran',
                            company => 'Sencha Inc.',
                            email   => 'aaron@sencha.com',
                        },
           };
}

sub getPhoneInfo : ExtDirect(1) {
    my ($class, $userId) = @_;

    return {
                success => \1,
                data    => {
                                cell   => '443-555-1234',
                                office => '1-800-CALLEXT',
                                home   => '',
                           },
           };
}

sub getLocationInfo : ExtDirect(1) {
    my ($class, $userId) = @_;

    return {
                success => \1,
                data    => {
                                street => '1234 Red Dog Rd.',
                                city   => 'Seminole',
                                state  => 'FL',
                                zip    => 33776,
                           },
           };
}

1;

=pod

=head1 NAME

RPC::ExtDirect::Demo::Profile - Part of Ext.Direct interface demo

=head1 DESCRIPTION

This module implements Profile class used in ExtJS Ext.Direct demo
scripts; it is not intended to be used per se but rather as an example.

I decided to keep it in the installation tree so that it will always
be available to look up without going to CPAN.

=head1 SEE ALSO

You can use C<perldoc -m RPC::ExtDirect::Demo::Profile> to see the actual
code.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2016 by Alexander Tokarev.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

