package Net::FreeIPA::API::Convert;
$Net::FreeIPA::API::Convert::VERSION = '3.0.2';
use strict;
use warnings qw(FATAL numeric);

use Net::FreeIPA::Request;

# cannout use 'use Types::Serialiser'; it is incompatible with JSON::XS 2.X (eg on EL6)
use JSON::XS;
use Readonly;

use base qw(Exporter);

our @EXPORT_OK = qw(process_args);

# Convert dispatch table
Readonly::Hash my %CONVERT_DISPATCH => {
    str => sub {my $val = shift; return "$val";}, # stringify
    int => sub {my $val = shift; return 0 + $val;}, # Force internal conversion to int
    float => sub {my $val = shift; return 1.0 * $val;}, # Force internal conversion to float
    bool => sub {my $val = shift; return $val ? JSON::XS::true : JSON::XS::false;},
};

# Aliases for each dispatch
Readonly::Hash my %CONVERT_ALIAS => {
    str => [qw(unicode DNSName)],
};

Readonly my $API_RPC_OPTION_PATTERN => '^__';


=head1 NAME

Net::FreeIPA::Convert provides type conversion for Net::FreeIPA

=head2 Public functions

=over

=item convert

Convert/cast value to type.

If a type is not found in the dispatch tabel, log a warning and return the value as-is.

Always returns value, dies when dealing with non-convertable type (using 'FATAL numeric').

=cut

# Do not use intermediate variables for the result

sub convert
{
    my ($value, $type) = @_;

    my $funcref = $CONVERT_DISPATCH{$type};

    if(!defined($funcref)) {
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

=item check_command

Given the (single) command hashref C<cmd> and C<value>,
verify the value, convert it and add it to C<where>.

(Adding to where is required to avoid using intermdiadate varaibles
which can cause problems for the internal types).

Returns errormessage (which is undef on success).

=cut

sub check_command
{
    my ($cmd, $value, $where) = @_;

    my $errmsg;

    my $ref = ref($value);
    my $name = $cmd->{name};

    # Check mandatory / undef
    # only mandatory if required and no autofill/default
    my $mandatory = ($cmd->{required} && (! $cmd->{autofill})) ? 1 : 0;

    # Check multivalue
    my $multi = $cmd->{multivalue} ? 1 : 0;

    if (! defined($value)) {
        if ($mandatory) {
            $errmsg = "name $name mandatory with undefined value";
        };
    } elsif((! $ref && ! $multi) ||
            (($ref eq 'ARRAY') && $multi) ) {
        # Convert and add to where
        my $wref = ref($where);
        local $@;
        eval {
            if ($wref eq 'ARRAY') {
                push(@$where, convert($value, $cmd->{type}));
            } elsif ($wref eq 'HASH') {
                $where->{$name} = convert($value, $cmd->{type});
            } else {
                $errmsg = "name $name unknown where ref $wref";
            };
        };
        $errmsg = "name $name where ref $wref died $@" if ($@);
    } else {
        $errmsg = "name $name wrong multivalue (multi $multi, ref $ref)";
    };

    return $errmsg;
}

=item process_args

Given the command hasref C<cmds> and the arguments passed, return

=over

=item errmsg: an error message in case of failure

=item posarg: arrayref with positional arguments

=item opts: hasref with options

=item rpc: hashref with options for the RPC call

(All options starting with C<__> are passed as options to
C<Net::FreeIPA::RPC::rpc>, with C<__> prefix removed).

=back

Positional argument and option values are converted
using C<convert> function.

=cut

sub process_args
{
    my ($cmds, @args) = @_;

    my $cmdname = $cmds->{name};

    my $posargs = [];
    my $opts = {};
    my $rpc = {};
    my $errmsg;

    my $err_req = sub {
        $errmsg = join(" ", "$cmdname:", shift, $errmsg);
        return mkrequest($cmdname, error => $errmsg);
    };

    # Check posargs
    my $aidx = 0;
    foreach my $cmd (@{$cmds->{takes_args} || []}) {
        $aidx += 1;
        $errmsg = check_command($cmd, shift(@args), $posargs);
        return &$err_req("$aidx-th argument") if $errmsg;
    }

    # Check options
    my %origopts = @args;

    # Process all options
    # The processed options are removed from %origopts
    foreach my $cmd (@{$cmds->{takes_options} || []}) {
        my $name = $cmd->{name};
        $errmsg = check_command($cmd, delete $origopts{$name}, $opts);
        return &$err_req("option") if $errmsg;
    }

    # Filter out any RPC options
    # Any remaing key is invalid
    foreach my $name (sort keys %origopts) {
        if ($name =~ m/$API_RPC_OPTION_PATTERN/) {
            my $val = $origopts{$name};
            $name =~ s/$API_RPC_OPTION_PATTERN//;
            $rpc->{$name} = $val;
        } else {
            return &$err_req("option invalid name $name");
        };
    }

    # No error
    return mkrequest($cmdname, args => $posargs, opts => $opts, rpc => $rpc);
}

=pod

=back

=cut

1;
