package TestUts;

use Test::More;
use strict;

sub test_call {
    my ( $client, $url, $params, $result, $label ) = @_;

    my $check_id = sub {
        my ( $label, $exp_res, $got_res ) = @_;

        if ( exists $exp_res->{id} ) {
            my $exp_id = $exp_res->{id};
            my $got_id = $got_res->id;
            if ( defined $exp_id ) {
                if ( !( defined $got_id && $exp_id eq $got_id ) ) {
                    diag(qq{$label failed. id doesn't match});

                    return 0;
                }
            }
            else {
                if ( defined $got_id ) {
                    diag(qq{$label failed. id doesn't match});

                    return 0;
                }
            }
        }
        return 1;    # OK
    };

    my $check_value;
    $check_value = sub {
        my ( $label, $exp_res, $got_res ) = @_;

        if (   ( defined $exp_res xor defined $got_res )
            || ( ref $exp_res ne ref $got_res ) )
        {
            diag(qq{$label doesn't match.});
            return 0;
        }

        if ( ref $exp_res eq 'ARRAY' ) {
            my $n     = scalar @{$exp_res};
            my $n_got = scalar @{$got_res};

            if ( $n != $n_got ) {
                diag(
                    qq{$label doesn't match. expected array length $n but got $n_got}
                );

                return 0;
            }
            foreach ( my $i = 0; $i < $n; $i++ ) {
                if (!$check_value->(
                        $label . qq{->[$i]}, $exp_res->[$i],
                        $got_res->[$i]
                    )
                    )
                {
                    return 0;
                }
            }

        }
        elsif ( ref $exp_res eq 'HASH' ) {
            my $n     = scalar keys %{$exp_res};
            my $n_got = scalar keys %{$got_res};
            if ( $n != $n_got ) {
                diag(
                    qq{$label doesn't match. expected keys length $n but got $n_got}
                );

                return 0;
            }

            foreach my $k ( keys %{$exp_res} ) {
                if ( !exists $got_res->{$k} ) {
                    diag(
                        qq{$label doesn't match. expected key $k does not exists.}
                    );
                    return 0;
                }
                if (!$check_value->(
                        $label . qq{->{$k}}, $exp_res->{$k},
                        $got_res->{$k}
                    )
                    )
                {
                    return 0;
                }
            }
        }
        elsif ( defined $exp_res && $exp_res ne $got_res ) {

            diag(qq{$label doesn't match.});
            diag(qq{EXP[$exp_res]});
            diag(qq{GOT[$got_res]});

            return 0;
        }

        return 1;    # OK
    };

    my $res = $client->call( $url, $params );
    #my $tx = shift $res;
    if ($res) {
        if ( ref $result eq 'ARRAY' && ref $res ne 'ARRAY' ) {
            diag(     qq{Expecting }
                    . ref($result)
                    . qq{, but got }
                    . ref($res)
                    . qq{ as result} );
            fail($label);
            return;
        }
        if ( ref $result eq 'HASH' ) {
            $result = [$result];
            $res    = [$res];
        }
        my $n = scalar @{$result};
        if ( scalar @{$res} != $n ) {
            diag( qq{Expecting $n results, got } . ( scalar @{$res} ) );
            fail($label);
            return;
        }
        my $all_ok = 1;
    RES:
        for ( my $i = 0; $i < $n; $i++ ) {
            my $exp_res = $result->[$i];
            my $got_res = $res->[$i];

            if ( !$check_id->( qq{$label: RES[$i]}, $exp_res, $got_res ) ) {
                $all_ok = 0;
                next RES;
            }

            if ( $got_res->is_error && defined $got_res->result ) {

                diag(
                    qq{$label: RES[$i] error!. RPC result contains both result and error!}
                );

                $all_ok = 0;
                next RES;
            }

            if ( exists $exp_res->{error} ) {
                if ( !$got_res->is_error ) {
                    diag(
                        qq{$label: RES[$i] failed. Expected error not found.}
                    );

                    $all_ok = 0;
                    next RES;
                }

                my $code = $got_res->error_code    || '';
                my $msg  = $got_res->error_message || '';
                my $data = $got_res->error_data    || '';

                if ((   !exists $exp_res->{error}->{code}
                        || $exp_res->{error}->{code} ne $code
                    )
                    || ( exists $exp_res->{error}->{message}
                        && $exp_res->{error}->{message} ne $msg )
                    || ( exists $exp_res->{error}->{data}
                        && $exp_res->{error}->{data} ne $data )
                    )
                {
                    diag(
                        qq{$label: RES[$i] failed. ERROR CODE[$code] MESSAGE[$msg] DATA[$data]}
                    );
                    $all_ok = 0;
                    next RES;
                }
            }
            elsif ( exists $exp_res->{result} ) {
                if (!$check_value->(
                        qq{$label: RES[$i]}, $exp_res->{result},
                        $got_res->result
                    )
                    )
                {
                    $all_ok = 0;
                    next RES;
                }
            }
        }

        if ($all_ok) {
            pass($label);
        }
        else {
            fail($label);
        }
    }
    else {
        fail($label);
    }
    return;
}

1;
