#!/usr/bin/perl -T
# $RedRiver: keyring.t,v 1.12 2007/02/23 22:05:17 andrew Exp $
use strict;
use warnings;

use Test::More tests => 44;
use YAML;

BEGIN { 
    use_ok( 'Palm::PDB' ); 
    use_ok( 'Palm::Keyring' ); 
}

my $file = 'Keys-test.pdb';
my $password = '12345';
my $new_password = '54321';

my @o = (
    {
        version  => 4,
        password => $password,
    },
    {
        version      => 5,
        password     => $password,
        cipher       => 1,
        v4compatible => 1,
    },
);

foreach my $options (@o) {
    my $pdb;
    my $record;
    my $decrypted;

    my $acct = {
        name        => 'test3',
        account     => 'atestaccount',
        password    => $password,
        notes       => 'now that really roxorZ!',
        lastchange  => {
            day   =>  2,
            month =>  2,
            year  => 99,
        },
    };

    SKIP: {
        if (defined $options->{cipher} && $options->{cipher} > 0) {
            my $crypt = Palm::Keyring::crypts($options->{cipher});
            skip 'Crypt::CBC not installed', 21 unless 
                eval "require Crypt::CBC";
            skip 'Crypt::' . $crypt->{name} . ' not installed', 21 unless 
                eval "require Crypt::$crypt->{name}";
        }

        if ($options->{version} == 4) {
            skip 'Crypt::DES not installed', 21 unless 
                eval " require Crypt::DES ";
            skip 'Digest::MD5 not installed', 21 unless 
                eval " require Digest::MD5 ";
        } elsif ($options->{version} == 5) {
            skip 'Digest::HMAC_SHA1 not installed', 21 unless 
                eval " require Digest::HMAC_SHA1 ";
        }

        ok( $pdb = new Palm::Keyring($options), 
            'New Palm::Keyring v' . $options->{version} );

        ok( $record = $pdb->append_Record(), 'Append Record' );

        ok( $pdb->Encrypt($record, $acct, $password), 'Encrypt account into record' );

        ok( $pdb->Write($file), 'Write file' );

        $pdb = undef;


        my $rec_num = 1;
        if ($options->{version} == 4) {
            ok( $pdb = new Palm::PDB(), 'New Palm::PDB' );
        } else {
            ok( $pdb = new Palm::Keyring(-v4compatible => 1), 'New Palm::Keyring' );
            $rec_num = 0;
        }

        ok( $pdb->Load($file), 'Load File' );

        ok( $pdb->Password($password), 'Verify Password' );

        ok( $decrypted = $pdb->Decrypt($pdb->{records}->[$rec_num]), 'Decrypt record' );

        is( $decrypted->{password}, $password, 'Got password' );

        is_deeply( $decrypted, $acct, 'Account Matches' );

        my $old_date = $decrypted->{'lastchange'};

        ok( $pdb->Password($password, $new_password), 'Change PDB Password' );

        ok( $decrypted = $pdb->Decrypt($pdb->{'records'}->[$rec_num]), 'Decrypt with new password' );

        my $new_date = $decrypted->{'lastchange'};

        is_deeply( $old_date, $new_date, 'Date didn\'t change' );

        $acct->{'password'} = $new_password;

        ok(  $pdb->Encrypt($pdb->{'records'}->[$rec_num], $acct), 'Change record' );

        ok( $decrypted = $pdb->Decrypt($pdb->{'records'}->[$rec_num]), 'Decrypt new record' );

        $new_date = $decrypted->{'lastchange'};

        my $od = join '/', map { $old_date->{$_} } sort keys %{ $old_date };
        my $nd = join '/', map { $new_date->{$_} } sort keys %{ $new_date };

        isnt( $od, $nd, 'Date changed');

        is( $decrypted->{password}, $new_password, 'Got new password' ); 

        $decrypted = {};
        ok( $pdb->Password(), 'Forget password' );

        eval{ $decrypted = $pdb->Decrypt($pdb->{'records'}->[$rec_num]) };
        ok( $@, 'Don\'t decrypt' );

        isnt( $decrypted->{password}, $new_password, 'Didn\'t get new password' );

        ok( unlink($file), 'Remove test pdb v' . $options->{version} );
    }
}

1;
