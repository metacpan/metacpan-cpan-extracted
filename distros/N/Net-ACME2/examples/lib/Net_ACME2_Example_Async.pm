package Net_ACME2_Example_Async;

use strict;
use warnings;

# Without __SUB__ we get memory leaks.
use feature 'current_sub';

use parent 'Net_ACME2_Example';

use FindBin;
use lib "$FindBin::Bin/../lib";

use Crypt::Perl::ECDSA::Generate ();
use Crypt::Perl::PKCS10 ();

use constant _PROMISER_CLASS => 'Net::Curl::Promiser::AnyEvent';

use Promise::ES6;
Promise::ES6::use_event('AnyEvent');

die if !eval( 'require ' . _PROMISER_CLASS() );

use Net::ACME2::Curl ();

# Used to report failed challenges.
use Data::Dumper;

use Net::ACME2::LetsEncrypt ();

use constant {
    _ECDSA_CURVE => 'secp384r1',
    CAN_WILDCARD => 0,
};

# Fill these in to reuse an existing registration.
my $_CACHED_TEST_KEY_PEM = undef;
my $_CACHED_KEY_ID = undef;

sub _finish_http_curl {
    my ($end_promise) = @_;

    if ($end_promise->isa('Mojo::Promise')) {
        $end_promise->wait();
    }
    else {
        my $cv = AnyEvent->condvar();

        my $finally = $end_promise->finally( sub { $cv->() } );

        $cv->recv();
    }

    return;
}

sub _after_delay {
    my ($seconds) = @_;

    if ( _PROMISER_CLASS =~ m<AnyEvent> ) {
        return Promise::ES6->new( sub {
            my ($res) = @_;

            my $w;
            $w = AnyEvent->timer(
                after => $seconds,
                cb => sub {
                    undef $w;
                    $res->();
                },
            );
        } );
    }
    elsif ( _PROMISER_CLASS =~ m<Mojo> ) {
        return Mojo::Promise->timer($seconds => undef);
    }

    die ('Can’t delay: ' . _PROMISER_CLASS);
}

sub run {
    my ($class) = @_;

    local $Promise::ES6::DETECT_MEMORY_LEAKS = 1;

    my $_test_key = $_CACHED_TEST_KEY_PEM || Crypt::Perl::ECDSA::Generate::by_name(_ECDSA_CURVE())->to_pem_with_curve_name();

    my $promiser = _PROMISER_CLASS()->new();

    my $acme = Net::ACME2::LetsEncrypt->new(
        environment => 'staging',
        async_ua => Net::ACME2::Curl->new($promiser),
        key => $_test_key,
        key_id => $_CACHED_KEY_ID,
    );

    my ($key_id_promise, $key_id_is_cached);

    #conditional is for if you want to modify this example to use
    #a pre-existing account.
    if ($acme->key_id()) {
        $key_id_is_cached = 1;
        print "Using hard-coded ACME key ID …$/";

        require Promise::ES6;
        $key_id_promise = Promise::ES6->resolve($acme->key_id());
    }
    else {
        $key_id_promise = $acme->get_terms_of_service()->then( sub {
            my $tos = shift;

            print "$/Indicate acceptance of the terms of service at:$/$/";
            print "\t" . $tos . $/ . $/;
            print "… by hitting ENTER now.$/";

            # This isn’t very “async”, but oh well. :)
            <>;

            my $acct_promise = $acme->create_account(
                termsOfServiceAgreed => 1,
            )->then( sub {
                printf "Created ACME registration!$/";
                printf "ACME Key ID: %s$/$/", $acme->key_id();
                printf "Key:$/%s$/", $_test_key;
            } );

            return $acct_promise;
        } );
    }

    my $authzs_ar;

    my (@domains, $order, $key, $csr);

    my $end_promise = $key_id_promise->then( sub {
        @domains = $class->_get_domains();
        print "Creating order …$/";

        return $acme->create_order(
            identifiers => [ map { { type => 'dns', value => $_ } } @domains ],
        );
    } )->then( sub {
        $order = shift;

        return Promise::ES6->all(
            [ map { $acme->get_authorization($_) } $order->authorizations() ],
        );
    } )->then( sub {
        $authzs_ar = shift;

        my $valid_authz_count = 0;

        for my $authz_obj (@$authzs_ar) {
            my $domain = $authz_obj->identifier()->{'value'};

            if ($authz_obj->status() eq 'valid') {
                $valid_authz_count++;
                print "$/This account is already authorized on $domain.$/";
                next;
            }

            my $challenge = $class->_authz_handler($acme, $authz_obj);

            return $acme->accept_challenge($challenge);
        }
    } )->then( sub {
        my @promises;

        for my $authz (@$authzs_ar) {
            my $name = $authz->identifier()->{'value'};

            if ($authz->status() eq 'valid') {
                print "$/“$name” has passed validation.$/";
            }

            push @promises, $acme->poll_authorization($authz)->then( sub {
                my $status = shift;

                substr($name, 0, 0, '*.') if $authz->wildcard();

                if ($status eq 'valid') {

                    print "$/“$name” has passed validation.$/";
                }
                elsif ($status eq 'pending') {
                    print "$/“$name”’s authorization is still pending …$/";
                }
                else {
                    if ($status eq 'invalid') {
                        my $challenge = $class->_get_challenge_from_authz($authz);
                        print Dumper($challenge);
                    }

                    die "$/“$name”’s authorization is in “$status” state.";
                }
            } );
        }

        if (@promises) {
            return Promise::ES6->all(\@promises)->then( sub {
                print "Waiting 1 second before polling authz(s) again …$/";
                return _after_delay(1);
            } )->then(__SUB__);
        }

        return undef;
    } )->then( sub {
        ($key, $csr) = $class->_make_key_and_csr_for_domains(@domains);

        print "Finalizing order …$/";

        my $finalize_cr = __SUB__;

        return $acme->finalize_order($order, $csr)->then( sub {
            if ($order->status() ne 'valid') {
                print "Waiting 1 second before polling order again …$/";

                return _after_delay(1)->then( sub {
                    return $acme->poll_order($order)->then($finalize_cr);
                } );
            }
        } );
    } )->then( sub {
        return $acme->get_certificate_chain($order);
    } )->then( sub {
        print "Certificate key:$/$key$/$/";

        print "Certificate chain:$/";

        print shift;
    } )->catch( sub {
        my $msg = shift;
        print STDERR "FAILURE: " . ( eval { $msg->get_message() } // $msg ) . $/;
    } );

    _finish_http_curl($end_promise);

    return;
}

1;
