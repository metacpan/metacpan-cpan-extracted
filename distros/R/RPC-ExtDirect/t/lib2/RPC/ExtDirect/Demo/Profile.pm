package RPC::ExtDirect::Demo::Profile;

use strict;
use warnings;
no  warnings 'uninitialized';

use RPC::ExtDirect Action => 'Profile';

sub updateBasicInfo : ExtDirect(formHandler) {
    my ($class, %fields) = @_;

    if ( $fields{email} eq 'aaron@sencha.com' ) {
        return {
                    success => \0,
                    errors  => { email => 'already taken' },
                    debug_formPacket   => \%fields,
               };
    }
    else {
        return {
                    success          => \1,
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
