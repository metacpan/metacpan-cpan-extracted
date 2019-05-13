package Net::FreeIPA::Common;
$Net::FreeIPA::Common::VERSION = '3.0.3';
use strict;
use warnings;

use Net::FreeIPA::API::Magic;
use Net::FreeIPA::Error;

use Readonly;

# Convert find one API method in attribute name to find
# This map might be API version dependant
Readonly::Hash our %FIND_ONE => {
    aci => 'aciname',
    cert => 'cn',
    delegation => 'aciname',
    dnsforwardzone => 'idnsname',
    dnsrecord => 'idnsname',
    dnszone => 'idnsname',
    group => 'cn',
    host => 'fqdn',
    hostgroup => 'fqdn',
    server => 'cn',
    service => 'krbprincipalname',
    trust => 'cn',
    user => 'uid',
    vault => 'cn',
};

=head1 NAME

Net::FreeIPA::Common provides common convenience methods for Net::FreeIPA

=head2 Public methods

=over

=item find_one

Use the C<api> method C<<api_<api>_find>> to retrieve a single answer.

The C<criteria> argument of the C<<api_<api>_find>> is the empty string,
the C<all> option is set.

(Warns if more than one is found, and returns the first one
in that case).

Returns undef in case of problem or if there is no result.

=cut

sub find_one
{
    my ($self, $api, $value) = @_;

    my $res;

    # Do not use ->can with autoload'ed magic
    # use API::retrieve (as function)
    my $func = $api."_find";
    my $method = "$Net::FreeIPA::API::API_METHOD_PREFIX$func";

    my ($cmds, $fail) = Net::FreeIPA::API::Magic::retrieve($func);

    if ($fail) {
        $self->error("find_one: unknown API method $method");
    } else {
        my $attr = $FIND_ONE{$api};
        if ($attr) {
            my $response = $self->$method("", $attr => $value, all => 1);
            if ($response) {
                my $count = $response->{answer}->{result}->{count};
                if (! $count) {
                    $self->debug("one_find method $method and value $value returns 0 answers.");
                } else {
                    if ($count > 1) {
                        $self->warn("one_find method $method and value $value returns $count answers");
                    };
                    $res = $response->{result}->[0];
                }
            } else {
                # error is already logged.
                $self->debug("find_one: method $method failed.");
            };
        } else {
            $self->error("find_one: no supported attribute for api $api");
        }
    };

    return $res;
}

=item do_one

Wrapper for simple call using C<api> and C<method> via
C<<api_<api>_<method>(C<name>)>>.

Any options are passed as is except C<__noerror>.

Following error-type are not reported as error
(set/added as defaults for C<__noerror>)
(still returns C<undef>):

=over

=item DuplicateEntry: when C<method> is C<add>,
an existing entry is not reported as an error

=item AlreadyInactive: when C<method> is C<disable>,
an already inactive/disabled entry is not reported as an error

=item NotFound: when C<method> is not C<mod> or any of the previous,
an missing entry is not reported as an error

=back

Returns the result attribute on success, or undef otherwise.

=cut

sub do_one
{
    my ($self, $api, $method, $name, %opts) = @_;

    my $api_method = $Net::FreeIPA::API::API_METHOD_PREFIX.$api."_$method";

    my $msg_map = {
        $Net::FreeIPA::Error::DUPLICATE_ENTRY => "already exists",
        $Net::FreeIPA::Error::ALREADY_INACTIVE => "already inactive/disabled",
        $Net::FreeIPA::Error::NOT_FOUND => "does not exist",
    };

    if ($method eq 'add') {
        # For add, do not report existing name as error
        push(@{$opts{__noerror}}, $Net::FreeIPA::Error::DUPLICATE_ENTRY);
    } elsif ($method eq 'disable') {
        # For disable, do not report already disabled name as error
        push(@{$opts{__noerror}}, $Net::FreeIPA::Error::ALREADY_INACTIVE);
    }

    if (! grep {$method eq $_ } qw(add mod)) {
        # For methods except add/mod, do not report missing name as error
        push(@{$opts{__noerror}}, $Net::FreeIPA::Error::NOT_FOUND);
    }

    my $response = $self->$api_method($name, %opts);

    my $name_msg = ref($name) eq 'ARRAY' ? join(', ', @$name) : $name;
    my $msg;
    if ($response) {
        $msg = "successfully $method-ed $api $name_msg";
    } else {
        $msg = "failed to $method $api $name_msg";

        foreach my $noerror (sort keys %$msg_map) {
            $msg .= " $api ".$msg_map->{$noerror} if ($response->{error} == $noerror);
        }
    }

    $self->debug("$api_method: $msg");

    return $response ? $response->{result} : undef;
};


=pod

=back

=cut

1;
