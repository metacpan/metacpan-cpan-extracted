package Net::OpenStack::Client::Auth;
$Net::OpenStack::Client::Auth::VERSION = '0.1.4';
use strict;
use warnings;

use Readonly;

Readonly my $OPENRC_REQUIRED => [qw(username password auth_url)];

Readonly my %OPENRC_DEFAULT => {
    identity_api_version => 3,
    project_domain_name => 'Default',
    user_domain_name => 'Default',
};

Readonly my $DEFAULT_ENDPOINT_INTERFACE_PREFERENCE => [qw(admin internal public)];

# read openrc file and extract the variables in hashref
sub _parse_openrc
{
    my ($self, $fn) = @_;

    my $res;
    if (open(my $fh, $fn)) {
        while (<$fh>) {
            chomp;
            if (m/^\s*(?:export\s+)(\w+)\s*=\s*(['"]?)(.+)\2\s*$/) {
                $res->{$1} = $3;
            }
        }
        close($fh);
        $self->debug("Parsed openrc file $fn: found variables ".join(',', sort keys %$res));
    } else {
        $self->error("Failed to openrc file $fn: $!");
    }
    return $res;
}


=head1 methods

=over

=item get_openrc

Given variable name, get OS_<uppercase variable name> from hashref C<data>.

Use default from OPENRC_DEFAULT, if none exists.
If none exists, and no default and in OPENRC_REQUIRED, report error.

=cut

sub get_openrc
{
    my ($self, $var, $data) = @_;

    my $full_var = "OS_".uc($var);
    if (exists($data->{$full_var})) {
        return $data->{$full_var};
    } elsif (exists($OPENRC_DEFAULT{$full_var})) {
        return $OPENRC_DEFAULT{$full_var};
    } else {
        my $req = (grep {$_ eq $var} @$OPENRC_REQUIRED) ? 1 : 0;
        my $method = $req  ? 'error' : 'debug';
        $self->$method("openrc ".($req ? 'required ' : '')."variable $var ($full_var) not found");
    }

    return;
}


=item login

Login and obtain token for further authentication.

Options:

=over

=item openrc: openrc file to parse to extract the login details.


=back

=cut

sub login
{
    my ($self, %opts) = @_;

    if ($opts{openrc}) {
        my $openrc = $self->_parse_openrc($opts{openrc})
            or return;

        my $os = sub {return $self->get_openrc(shift, $openrc)};

        my $version = version->new('v'.&$os('identity_api_version'));
        $self->{versions}->{identity} = $version;
        if ($self->{versions}->{identity} == 3) {
            $self->{services}->{identity} = &$os('auth_url');
            my $opts = {
                methods => ['password'],
                user_name => &$os('username'),
                password => &$os('password'),
                user_domain_name => &$os('user_domain_name') || &$os('project_domain_name'),
                project_domain_name => &$os('project_domain_name'),
                project_name => &$os('project_name'),
            };

            my $resp = $self->api_identity_tokens(map {$_ => $opts->{$_}} grep {defined($opts->{$_})} keys %$opts);
            if ($resp) {
                # token in result attr
                $self->{token} = $resp->result;
                $self->verbose("login succesful, obtained a token");
                # parse the catalog
                $self->services_from_catalog($resp->{data}->{token}->{catalog});
            } else {
                $self->error("login: failed to get token $resp->{error}");
                return;
            }
        } else {
            $self->error("login: only identity v3 supported for now");
            return;
        }
    } else {
        $self->error("login: only openrc supported for now");
        return;
    }

    return 1;
}

=item services_from_catalog

Parse the catalog arrayref, and build up the services attribute

=cut

sub services_from_catalog
{
    my ($self, $catalog) = @_;

    # TODO: allow to change this
    my @pref_intfs = (@$DEFAULT_ENDPOINT_INTERFACE_PREFERENCE);

    foreach my $service (@$catalog) {
        my $type = $service->{type};
        my $endpoint;
        foreach my $intf (@pref_intfs) {
            my @epts = grep {$_->{interface} eq $intf} @{$service->{endpoints}};
            if (@epts) {
                $endpoint = $epts[0]->{url};
                last;
            }
        }
        my $msg = "for service $type from catalog";
        if ($endpoint) {
            $self->{services}->{$type} = $endpoint;
            $self->verbose("Added endpoint $endpoint $msg");
        } else {
            $self->error("No endpoint $msg using preferred interfaces ".join(",", @pref_intfs));
        }
    }
}

=pod

=back

=cut

1;
