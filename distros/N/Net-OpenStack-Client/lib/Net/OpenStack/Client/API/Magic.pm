package Net::OpenStack::Client::API::Magic;
$Net::OpenStack::Client::API::Magic::VERSION = '0.1.4';
use strict;
use warnings;

use Module::Load;
use Net::OpenStack::Client::Request qw(@SUPPORTED_METHODS @METHODS_REQUIRE_OPTIONS);

use Readonly;
use version;

use base qw(Exporter);

our @EXPORT_OK = qw(retrieve version);

# hashref to store cached command data
my $cache;
# Init the cache
$cache = flush_cache();

=head2 Public functions

=over

=item flush_cache

Reset the cache

=cut

sub flush_cache
{
    $cache = {cmd => {}, api => {}};
    return $cache;
}

=item cache

Given C<data> command hashref,
cache and return the relevant (filtered) command data.

If C<api_service> is defined, store the data as
the service C<API_DATA>.

=cut

sub cache
{
    my ($data, $api_service) = @_;

    if ($api_service) {
        $cache->{api}->{$api_service} = $data;
    } else {
        my $service = $data->{service};
        my $name = $data->{name};

        $cache->{cmd}->{$service}->{$name} = $data;
    }

    return $data;
}

=item retrieve

Retrieve the command data for service C<service>, name C<name>
and version C<version>.

Returns the tuple with cache command hashref and undef errormessage on SUCCESS,
an emptyhashref and actual errormessage otherwise.
If the command is already in cache, returns the cached version
(and undef errormessage).

=cut

sub retrieve
{
    my ($service, $name, $version) = @_;

    # Return already cached data
    return ($cache->{cmd}->{$service}->{$name}, undef) if defined(($cache->{cmd}->{$service} || {})->{$name});

    my $err_prefix = "retrieve name $name for service $service";

    if ($version) {
        if (ref($version) ne 'version') {
            $version = "v$version" if $version !~ m/^v/;
            $version = version->new($version);
        }
    } else {
        return {}, "$err_prefix no version defined";
    }

    $err_prefix .= " version $version failed:";

    my $versionpackagename = "$version";
    $versionpackagename =~ s/[.]/DOT/g; # cannot have a . in the package name

    my $servicepackagename = ucfirst($service);

    my $apidata = $cache->{api}->{$service};
    my $result;

    if (!$apidata) {
        my $package = "Net::OpenStack::Client::API::${servicepackagename}::${versionpackagename}";

        local $@;
        eval {
            load $package;
        };
        if ($@) {
            return {}, "$err_prefix no API module $package: $@";
        }

        my $varname = "${package}::API_DATA";
        eval {
            no strict 'refs';
            $apidata = ${$varname};
            use strict 'refs';
        };
        if ($@) {
            return {}, "$err_prefix somthing went wrong while looking for variable $varname: $@";
        } elsif (!defined $apidata) {
            return {}, "$err_prefix no variable $varname";
        } elsif (ref($apidata) ne 'HASH') {
            return {}, "$err_prefix variable $varname not a hash (got ".ref($apidata).")";
        };

        # cache this data
        cache($apidata, $service);
    }

    my $data = $apidata->{$name};
    if (! $data) {
        # Try custom functions
        my $package = "Net::OpenStack::Client::${servicepackagename}::${versionpackagename}";

        local $@;
        eval {
            load $package;
        };

        if ($@) {
            my $msg = "$err_prefix no API data or client module";
            if ($@ !~ m/^can.*locate.*in.*INC/i) {
                # if you can't locate the module, it's probably ok no to mention it
                # but anything else (eg syntax error) should be reported
                $msg .= " (client module load failed: $@)"
            }
            return {}, $msg;
        } else {
            # Retrieve the function in the package
            no strict 'refs';
            my %symbol_table = %{"${package}::"};
            use strict 'refs';

            my $something = $symbol_table{$name};
            if (defined $something) {
                # magic bits from Package::Stash list_all_symbols
                if (ref \$something eq 'GLOB' &&
                    defined *$something{CODE}) {
                    no strict 'refs';
                    my $function = \&{"${package}::$name"};
                    use strict 'refs';

                    $result = {
                        name => $name, # human readable function/method name
                        service => $service,
                        code => $function,
                    };
                } else {
                    return {}, "$err_prefix found in client module, but not a function";
                }
            } else {
                return {}, "$err_prefix no API data or function from client module";
            }
        }
    } else {
        # data is a hashref
        # sanity check
        if (!exists($data->{endpoint})) {
            return {}, "$err_prefix data should at least contain the endpoint";
        }

        if (!exists($data->{method})) {
            return {}, "$err_prefix data should at least contain the method";
        }

        my $method = $data->{method};
        if (!grep {$_ eq $method} @SUPPORTED_METHODS) {
            return {}, "$err_prefix method $method is not supported";
        }
        if ((grep {$method eq $_} @METHODS_REQUIRE_OPTIONS) && !exists($data->{options})) {
            return {}, "$err_prefix data should contain options for method $method";
        }

        $result = {
            name => $name, # human readable function/method name
            method => $method, # HTTP method
            service => $service,
            endpoint => $data->{endpoint},
            version => $version,
        };

        $result->{result} = $data->{result} if defined($data->{result});

        foreach my $k (qw(templates parameters options)) {
            $result->{$k} = $data->{$k} if exists($data->{$k});
        }
    }
    return cache($result), undef;
}


=pod

=back

=cut


1;
