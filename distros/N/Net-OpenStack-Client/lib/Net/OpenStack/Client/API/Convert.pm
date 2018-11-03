package Net::OpenStack::Client::API::Convert;
$Net::OpenStack::Client::API::Convert::VERSION = '0.1.4';
use strict;
use warnings qw(FATAL numeric);

use Net::OpenStack::Client::Request;

# cannot use 'use Types::Serialiser'; it is incompatible with JSON::XS 2.X (eg on EL6)
use JSON::XS;
use Readonly;

use base qw(Exporter);

our @EXPORT_OK = qw(convert process_args);

# Convert dispatch table
Readonly::Hash my %CONVERT_DISPATCH => {
    string => sub {my $val = shift; return "$val";}, # stringify
    long => sub {my $val = shift; return 0 + $val;}, # Force internal conversion to int/long
    double => sub {my $val = shift; return 1.0 * $val;}, # Force internal conversion to float/double
    boolean => sub {my $val = shift; return $val ? JSON::XS::true : JSON::XS::false;},
};

# Aliases for each dispatch
Readonly::Hash my %CONVERT_ALIAS => {
};

Readonly my $API_REST_OPTION_PATTERN => '^__';


=head1 NAME

Net::OpenStack::Client::API::Convert provides type conversion for Net::OpenStack

=head2 Public functions

=over

=item convert

Convert/cast value to type.

If a type is not found in the dispatch table, log a warning and return the value as-is.

Always returns value, dies when dealing with non-convertable type (using 'FATAL numeric').

=cut

# Do not use intermediate variables for the result

sub convert
{
    my ($value, $type) = @_;

    my $funcref = $CONVERT_DISPATCH{$type};

    if (!defined($funcref)) {
        # is it an alias?
        foreach my $tmpref (sort keys %CONVERT_ALIAS) {
            $funcref = $CONVERT_DISPATCH{$tmpref} if (grep {$_ eq $type} @{$CONVERT_ALIAS{$tmpref}});
        }
    };

    if (defined($funcref)) {
        my $vref = ref($value);
        if ($vref eq 'ARRAY') {
            return [map {$funcref->($_)} @$value];
        } elsif ($vref eq 'HASH') {
            return {map {$_ => $funcref->($value->{$_})} sort keys %$value};
        } else {
            return $funcref->($value);
        };
    } else {
        return $value;
    }
}

=item check_option

Given the (single) option hashref C<option> and C<value>,
verify the value, convert it and add it to C<where>.

(Adding to where is required to avoid using intermediadate variables
which can cause problems for the internal types).

Returns errormessage (which is undef on success).

=cut

sub check_option
{
    my ($opt, $value, $where, $attr) = @_;

    my $errmsg;

    my $ref = ref($value);
    my $name = $opt->{name};

    if ($attr) {
        # insert value attribute if needed. Reset where to this attribute
    };

    # Check mandatory / undef
    my $mandatory = $opt->{required} ? 1 : 0;

    if (! defined($value)) {
        if ($mandatory) {
            $errmsg = "name $name mandatory with undefined value";
        };
    } elsif (!$ref || $ref eq 'ARRAY') {
        # Convert and add to where
        my $wref = ref($where);
        local $@;
        eval {
            if ($wref eq 'ARRAY') {
                push(@$where, convert($value, $opt->{type}));
            } elsif ($wref eq 'HASH') {
                $where->{$name} = convert($value, $opt->{type});
            } else {
                $errmsg = "name $name unknown where ref $wref";
            };
        };
        $errmsg = "name $name where ref $wref died $@" if ($@);
    } else {
        $errmsg = "name $name wrong multivalue (ref $ref)";
    };

    return $errmsg;
}

=item process_args

Given the command hashref C<cmdhs> and the arguments passed, return
Request instance.

Command hashref

=over

=item endpoint

=item method

=item templates (optional)

=item parameters (optional)

=item options (optional)

(All options starting with C<__> are passed as options to
C<Net::OpenStack::Client::REST::rest>, with C<__> prefix removed).

=back

Request instance:

=over

=item error: an error message in case of failure

=item tpls: hashref with templates for endpoint

=item params: hashref with parameters for endpoint

=item opts: hashref with options

=item rest: hashref with options for the REST call

=back

Values are converted using C<convert> function.

=cut

sub process_args
{
    my ($cmdhs, @args) = @_;

    # template name and value
    my $templates = {};
    # parameters name and value
    my $parameters = {};
    # option name and value
    my $options = {};
    # option name and path (separate from option values)
    my $paths = {};
    # rest options
    my $rest = {};

    my $errmsg;

    my $endpoint = $cmdhs->{endpoint};
    my $method = $cmdhs->{method};

    my $err_req = sub {
        $errmsg = join(" ", "$endpoint $method:", shift, $errmsg);
        return mkrequest($endpoint, $method, error => $errmsg);
    };

    my %origopts = @args;

    my $raw = delete $origopts{raw};
    if ($raw && ref($raw) ne 'HASH') {
        return &$err_req("raw option must be a hashref, got ".ref($raw));
    }

    # Check endpoint template values; sort of mandatory special named options
    # The processed options are removed from %origopts
    # TODO: naming conflict between JSON key, parameter and template name? (handled in gen.pl)
    foreach my $name (@{$cmdhs->{templates} || []}) {
        # all strings, used for templating
        $errmsg = check_option({name => $name, required => 1, type => 'str'}, delete $origopts{$name}, $templates);
        return &$err_req("endpoint template $name") if $errmsg;
    }

    # Check parameters
    foreach my $name (@{$cmdhs->{parameters} || []}) {
        # all strings, used for url buildup
        $errmsg = check_option({name => $name, type => 'str'}, delete $origopts{$name}, $parameters);
        return &$err_req("endpoint parameter $name") if $errmsg;
    }

    # Check options
    # Process all options (for JSON data)
    # The processed options are removed from %origopts
    foreach my $name (sort keys %{$cmdhs->{options} || {}}) {
        my $opt = $cmdhs->{options}->{$name};
        $opt->{name} = $name if ! exists($opt->{$name});

        # Need both value (added via check_option) and path
        $paths->{$name} = $opt->{path};
        $errmsg = check_option($opt, delete $origopts{$name}, $options);
        return &$err_req("option $name") if $errmsg;
    }

    # Filter out any REST options
    # Any remaining key is invalid
    foreach my $name (sort keys %origopts) {
        if ($name =~ m/$API_REST_OPTION_PATTERN/) {
            my $val = $origopts{$name};
            $name =~ s/$API_REST_OPTION_PATTERN//;
            $rest->{$name} = $val;
        } else {
            return &$err_req("option invalid name $name");
        };
    }

    # No error
    return mkrequest(
        $endpoint,
        $method,
        tpls => $templates,
        params => $parameters,
        opts => $options,
        paths => $paths,
        rest => $rest,
        raw => $raw,
        service => $cmdhs->{service},
        version => $cmdhs->{version},
        result => $cmdhs->{result},
        );
}

=pod

=back

=cut

1;
