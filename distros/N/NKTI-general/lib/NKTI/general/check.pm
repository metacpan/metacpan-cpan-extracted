package NKTI::general::check;

use strict;
use warnings;
use JSON;
use NKTI::general::request::post;
use NKTI::general::dbconnect;
use NKTI::general::char::split;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NKTI::general::request::post ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our @EXPORT = qw(nkti_get_authkey);


# Define Version :
# ----------------------------------------------------------------
our $VERSION = '0.13';

# Create Module for Constructor :
# ------------------------------------------------------------------------
#
=head1 MODULE new()

    Parameter Modul :
    ----------------------------------------
    _db_config =>       Parameter yang berisi String JSON Konfigurasi Database.
    _query_get =>       Parameter yang berisi query untuk mengambil data Auth Key dari Database.
    _domain =>          Parameter yang berisi nama domain.
                        Ex : "yourdomain.tld"
    _auth_key =>        Parameter yang berisi auth key yang sudah didefinisikan.
    _other_config =>    Parameter yang berisi hash config nama kolom table databsae untuk Auth Key dan Domain
                        ataupun data config lainnya

    Format Array _other_config :
    ----------------------------------------
    %hash = (
        'authkey' => 'col_name',
        'domain' => 'col_name',
        'other_config1' => 'value_other_config1'
    )

=cut
sub new {

    # Declare parameter module :
    # ----------------------------------------------------------------
    my $class = shift;
    my $self = {
        _db_config => shift,
        _query_get => shift,
        _domain => shift,
        _auth_key => shift,
        _other_config => shift,
    };
    bless $self, $class;

    # Return result constructor :
    # ----------------------------------------------------------------
    return $self;

}
# End of Create Module for Constructor.
# ===========================================================================================================

# Create Module for Check Auth Key :
# ------------------------------------------------------------------------
#
=head1 MODULE auth_key

    Parameter Modul :
    ----------------------------------------
    Tidak memiliki Parameter Module, aksi dilakukan berdasarkan input parameter di constructor.

=cut
sub auth_key {

    # Define result constructor :
    # ----------------------------------------------------------------
    my ($self) = @_;

    # Define scalar for get parameter constructor :
    # ----------------------------------------------------------------
    my $db_config = $self->{_db_config};
    my $query_get = $self->{_query_get};
    my $auth_key = $self->{_auth_key};
    my $other_conf = $self->{_other_config};
    my $colname_authKey = $other_conf->{'authkey'};

    # Action Request for Get Database Config :
    # ----------------------------------------------------------------
    my $unpack_dbconf = decode_json($db_config);
    my $prefix_db = $unpack_dbconf->{'prefix_table'};

    # Action for Check Authentication Key :
    # ----------------------------------------------------------------
    my $db_con = NKTI::general::dbconnect->mysql($db_config);
    my $q= $query_get;
    my $sth = $db_con->prepare($q);
    $sth->execute($prefix_db, $colname_authKey);
    my $result_get = $sth->rows;

    # Declare scalar for placing result :
    # ----------------------------------------------------------------
    my %data;

    # Check IF $result_get >= 1 :
    # ----------------------------------------------------------------
    if ($result_get >= 1) {

        # While loop to get data :
        # ----------------------------------------------------------------
        while (my @r_data = $sth->fetchrow_array()) {

            # Declare scalar for get result data :
            # ----------------------------------------------------------------
            my ($id_pengaturan, $item_pengaturan, $value_pengaturan) = @r_data;

            # Decode Auth Key :
            # ----------------------------------------------------------------
            my $docode_auth_key = NKTI::general::char::split->based_char($auth_key, "-", 1);

            # Check IF $value_pengaturan eq $docode_auth_key :
            # ----------------------------------------------------------------
            if ($value_pengaturan eq $docode_auth_key) {

                # Placing result into hash %data :
                # ----------------------------------------------------------------
                $data{'result'} = {
                    'sukses' => 1,
                    'code' => 'success',
                    'data' => $value_pengaturan
                };
            }
            # End of check IF $value_pengaturan eq $docode_auth_key.
            # ----------------------------------------------------------------

            # Check IF $value_pengaturan eq $docode_auth_key :
            # ----------------------------------------------------------------
            else {

                # Placing result into hash %data :
                # ----------------------------------------------------------------
                $data{'result'} = {
                    'sukses' => 0,
                    'code' => 'no-eq'
                };
            }
            # End of check IF $value_pengaturan eq $docode_auth_key.
            # ----------------------------------------------------------------
        }
        # End of while to get data.
        # ================================================================
    }
    # End of check IF $result_get >= 1.
    # ----------------------------------------------------------------

    # Check IF $result_get == 0 :
    # ----------------------------------------------------------------
    else {

        # Placing error result into hash %data :
        # ----------------------------------------------------------------
        $data{'result'} = {
            'sukses' => 0,
            'code' => 'not-found'
        };

    }
    # End of check IF $result_get == 0.
    # ----------------------------------------------------------------

    # Return Result :
    # ----------------------------------------------------------------
    return \%data;

}
# End of Create Module for Check Auth Key.
# ===========================================================================================================

# Create Module for Check Domain :
# ------------------------------------------------------------------------
#
=head1 MODULE domain()

    Parameter Modul :
    ----------------------------------------
    Tidak memiliki Parameter Module, aksi dilakukan berdasarkan input parameter di constructor.

=cut
sub domain {

    # Declare Parameter Module :
    # ----------------------------------------------------------------
    my ($self) = @_;

    # Define scalar for get parameter constructor :
    # ----------------------------------------------------------------
    my $db_config = $self->{_db_config};
    my $query_get = $self->{_query_get};
    my $domain = $self->{_domain};
    my $other_conf = $self->{_other_config};
    my $colname_domain = $other_conf->{'domain'};

    # Action Request for Get Database Config :
    # ----------------------------------------------------------------
    my $unpack_dbconf = decode_json($db_config);
    my $prefix_db = $unpack_dbconf->{'prefix_table'};

    # Action for Check Domain :
    # ----------------------------------------------------------------
    my $db_con = NKTI::general::dbconnect->mysql($db_config);
    my $q = $query_get;
    my $sth = $db_con->prepare($q);
    $sth->execute($prefix_db, $colname_domain);
    my $result_get = $sth->rows;

    # Declare scalar for placing result :
    # ----------------------------------------------------------------
    my %data = ();

    # Check IF $result_get >= 1 :
    # ----------------------------------------------------------------
    if ($result_get >= 1) {

        # Define scalar will be uesd in this condition :
        # ----------------------------------------------------------------
        my $r_data = $sth->fetchrow_hashref();

        # Declare scalar for define result database :
        # ----------------------------------------------------------------
        my $result_item = $r_data->{'value_pengaturan'};

        # Check IF $result_item == $domain :
        # ----------------------------------------------------------------
        if ($result_item eq $domain) {

            # Placing success result into hashref %data :
            # ----------------------------------------------------------------
            $data{'result'} = {
                'sukses' => 1,
                'code' => 'success',
                'data' => $result_item
            }
        }
        # End of check IF $result_item == $domain.
        # ----------------------------------------------------------------

        # Check IF $result_item == $domain :
        # ----------------------------------------------------------------
        else {

            # Placing Error Result into hashref %data :
            # ----------------------------------------------------------------
            $data{'result'} = {
                'sukses' => 0,
                'code' => 'no-eq'
            }

        }
        # End of check IF $result_item == $domain.
        # ----------------------------------------------------------------
    }
    # End of check IF $result_get >= 1.
    # ----------------------------------------------------------------

    # Check IF $result_get == 0 :
    # ----------------------------------------------------------------
    else {

        # Placing Error Result into hashref %data :
        # ----------------------------------------------------------------
        $data{'result'} = {
            'sukses' => 0,
            'code' => 'no-found'
        }

    }
    # End of check IF $result_get == 0.
    # ----------------------------------------------------------------

    # Return result :
    # ----------------------------------------------------------------
    return \%data;
}
# End of Create Module for Check Domain.
# ===========================================================================================================

# Create Module for Get Auth Key : :
# ------------------------------------------------------------------------
#
=head1 MODULE get_authkey()

    Parameter Modul :
    ----------------------------------------
    $db_config =>       Parameter yang berisi string JSON Database Config.
    $result_check =>    Parameter yang berisi hashref Hasil pengecekan Auth Key dan Domain.
    $item_db =>         Parameter yang berisi Nama item ditable database.
    $query_db =>        Parameter yang berisi Query Database.

=cut
sub nkti_get_authkey {

    # Declare parameter module :
    # ----------------------------------------------------------------
    my ($db_config, $result_check, $item_db, $query_db) = @_;

    # Declare scalar for parameter module :
    # ----------------------------------------------------------------
    my $get_dbconf = decode_json($db_config);
    my $prefix_db = $get_dbconf->{'prefix_table'};

    # Declare scalar for Placing result :
    # ----------------------------------------------------------------
    my %data = ();

    # Query for get auth key :
    # ----------------------------------------------------------------
    my $dbcon = NKTI::general::dbconnect->mysql($db_config);
    my $q = $query_db;
    my $sth = $dbcon->prepare($q);
    $sth->execute($prefix_db, $item_db);
    my $result_get = $sth->rows;

    # Check IF $result_get >= 1 :
    # ----------------------------------------------------------------
    if ($result_get >= 1) {

        # Declare scalar for placing result Database :
        # ----------------------------------------------------------------
        my $r_data = $sth-> $sth->fetchrow_hashref();
        my $auth_key = $r_data->{'value_pengaturan'};

        # Placing data into hashref %data :
        # ----------------------------------------------------------------
        $data{'result'} = {
            'sukses' => 1,
            'code' => 'success',
            'data' => $auth_key
        };
    }
    # End of check IF $result_get >= 1.
    # ----------------------------------------------------------------

    # Check IF $result_get == 0 :
    # ----------------------------------------------------------------
    else {

        # Placing Error result into hashref %data :
        # ----------------------------------------------------------------
        $data{'result'} = {
            'sukses' => 0,
            'code' => 'not-found'
        };
    }
    # End of check IF $result_get == 0.
    # ----------------------------------------------------------------

    # Return Result :
    # ----------------------------------------------------------------
    return \%data;
}
# End of Create Module for Get Auth Key :.
# ===========================================================================================================
1;

__END__
=head1 AUTHOR
    Achmad Yusri Afandi, (linuxer08@gmail.com)

=head1 COPYRIGHT AND LICENSE
    Copyright (c) 2016, Achmad Yusri Afandi, All Rights reserved.

    Pustaka yang berfungsi untuk mengecek hak akses dan domain.

=cut
