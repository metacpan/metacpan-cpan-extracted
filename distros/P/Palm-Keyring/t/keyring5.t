#!/usr/bin/perl -T
# $RedRiver: keyring5.t,v 1.5 2007/02/23 22:05:17 andrew Exp $
use strict;
use warnings;

use Test::More tests => 126;
use YAML;

BEGIN { 
    use_ok( 'Palm::PDB' ); 
    use_ok( 'Palm::Keyring' ); 
}

my $file = 'Keys-test.pdb';
my $password = '12345';
my $new_password = '54321';

foreach my $cipher (0..3) {
    my $pdb;
    my @recs;
    my $record;
    my $decrypted;

    my $crypt = Palm::Keyring::crypts($cipher);

    my $options = {
        version  => 5,
        password => $password,
        cipher   => $cipher,
    };

    my $rec1_name = 'test';

    my $original_accts = [
    [
    {
        'label_id' => 2,
        'data' => 'only password is set',
        'label' => 'password',
        'font' => 0,
    },
    {
        'label_id' => 3,
        'data' => {
            'month' => 1,
            'day' => 1,
            'year' => 107
        },
        'label' => 'lastchange',
        'font' => 0,
    }
    ],
    [
    {
        'label_id' => 2,
        'data' => 'abcd1234',
        'label' => 'password',
        'font' => 0,
    },
    {
        'label_id' => 3,
        'data' => {
            'month' => 1,
            'day' => 11,
            'year' => 107
        },
        'label' => 'lastchange',
        'font' => 0,
    },
    {
        'label_id' => 255,
        'data' => 'This is a short note.',
        'label' => 'notes',
        'font' => 0,
    }
    ],
    [
    {
        'label_id' => 2,
        'data' => 'password (date is 2/2/07)',
        'label' => 'password',
        'font' => 0,
    },
    {
        'label_id' => 3,
        'data' => {
            'month' => 1,
            'day' => 2,
            'year' => 107
        },
        'label' => 'lastchange',
        'font' => 0,
    }
    ]
    ];

    SKIP: {
        if ($cipher > 0) {
            skip 'Crypt::CBC not installed', 31 unless 
                eval "require Crypt::CBC";
            skip 'Crypt::' . $crypt->{name} . ' not installed', 31 unless 
                eval "require Crypt::$crypt->{name}";
        }
        skip 'Digest::HMAC_SHA1 not installed', 31 unless 
            eval " require Digest::HMAC_SHA1 ";

        ok( $pdb = new Palm::Keyring($options), 'New Palm::Keyring v' 
            . $options->{version} 
            . ' Cipher ' 
            . $options->{cipher}
        );

        my $rec_id = 0;
        foreach my $acct (@{ $original_accts} ) {
            ok( $record = $pdb->append_Record(), 'Append Record' );
            if ($rec_id == 1) {
                ok( $record->{name} = $rec1_name, 'Setting record name' );
            }
            ok( $pdb->Encrypt($record, $acct, $password), 'Encrypt account into record' );
            $rec_id++;
        }

        ok( $pdb->Write($file), 'Write file' );

        $pdb = undef;

        ok( $pdb = new Palm::PDB(), 'New Palm::PDB' );

        ok( $pdb->Load($file), 'Load File' );

        ok( $pdb->Password($password), 'Verify Password' );

        $rec_id = 0;
        foreach my $rec (@{ $pdb->{records} }) {
        ok( $decrypted = $pdb->Decrypt($rec), 'Decrypt record' );
        if ($rec_id == 1) {
        is( $rec->{name}, $rec1_name, 'Checking record name' );
        }
        push @recs, $decrypted;
        $rec_id++;
        }

        is_deeply( \@recs, $original_accts, 'Account Matches' );

        @recs = ();
        my $rec_num = 1;

        ok( $pdb->Password($password, $new_password), 'Change PDB Password' );

        foreach my $rec (@{ $pdb->{records} }) {
        ok( $decrypted = $pdb->Decrypt($rec), 'Decrypt record' );
        push @recs, $decrypted;
        }

        is_deeply( \@recs, $original_accts, 'Account Matches' );

        my $acct;
        ok( $acct = $pdb->Decrypt( $pdb->{records}->[$rec_num]), 'decrypt record ' . $rec_num);

        foreach my $field (@{ $acct }) {
        next unless $field->{label} eq 'password';
        ok($field->{data} = $new_password, 'Change password');
        }

        ok(  $pdb->Encrypt($pdb->{'records'}->[$rec_num], $acct), 'Change record' );

        ok( $decrypted = $pdb->Decrypt($pdb->{'records'}->[$rec_num]), 'Decrypt changed record' );

        is_deeply($acct, $decrypted, 'Compare changed record');

        $decrypted = [];
        ok( $pdb->Password(), 'Forget password' );

        eval{ $decrypted = $pdb->Decrypt($pdb->{'records'}->[$rec_num]) };
        ok($@, 'Don\'t decrypt');

        my $got_password = 'Got nothing';
        if ($decrypted) {
        foreach my $field (@{ $decrypted }) {
        next unless $field->{label} eq 'password';
        $got_password = $field->{data};
        }
        }

        isnt( $got_password, $new_password, 'Didn\'t get new password' );

        ok( unlink($file), 'Remove test pdb v' . $options->{version} );
        }
}

1;
