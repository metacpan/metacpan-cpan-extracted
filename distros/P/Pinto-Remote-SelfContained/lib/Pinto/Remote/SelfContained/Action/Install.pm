package
    Pinto::Remote::SelfContained::Action::Install; # hide from PAUSE

use v5.10;
use Moo;

use Carp qw(croak);
use MooX::HandlesVia;
use Pinto::Remote::SelfContained::Util qw(mask_uri_passwords);
use Types::Standard qw(ArrayRef Bool HashRef Maybe Str);

use constant PINTO_MINIMUM_CPANM_VERSION => '1.6920';

use namespace::clean;

our $VERSION = '1.000';

extends qw(Pinto::Remote::SelfContained::Action);

has cpanm_options => (
    is => 'lazy',
    isa => HashRef[ Maybe[Str] ],
    default => sub { +{} },
);

has cpanm_exe => (
    is => 'lazy',
    isa => Str,
    builder => sub {
        return "$ENV{PINTO_HOME}/sbin/cpanm"
            if defined $ENV{PINTO_HOME}
            && -x "$ENV{PINTO_HOME}/sbin/cpanm";

        my $output = `cpanm --version`
            // croak("Could not learn version of cpanm");

        croak("Could not learn version of cpanm")
            if $output eq '';

        my ($cpanm_version) = $output =~ m{version ([0-9.]+)}
            or croak("Could not parse cpanm version number from $output");

        croak("Your cpanm ($cpanm_version) is too old. Must have @{[PINTO_MINIMUM_CPANM_VERSION]} or newer")
            if $cpanm_version < PINTO_MINIMUM_CPANM_VERSION;

        return 'cpanm';
    },
);

has targets => (
    is => 'bare',
    lazy => 1,
    isa => ArrayRef[Str],
    handles_via => 'Array',
    handles => { targets => 'elements' },
    builder => sub { shift->args->{targets} // [] },
);

has do_pull => (is => 'ro', isa => Bool, default => 0);

has mirror_uri => (
    is => 'lazy',
    isa => Str,
    builder => sub {
        my ($self) = @_;

        my $stack = $self->args->{stack};
        my $mirror_uri = join '',
            $self->root, defined $stack ? "/stacks/$stack" : '';

        if (defined $self->password) {
            my $credentials = $self->username . ':' . $self->password;
            $mirror_uri =~ s{^ https?:// \K}{$credentials\@}mx;
        }

        return $mirror_uri;
    },
);

around BUILDARGS => sub {
    my ($orig, $class, @rest) = @_;
    my $attrs = $class->$orig(@rest);

    # Intercept attributes from the action "args" hash
    $attrs->{do_pull} = delete $attrs->{args}{do_pull} // 0;
    $attrs->{cpanm_options} = delete $attrs->{args}{cpanm_options} // {};

    return $attrs;
};

around execute => sub {
    my (undef, $self, $streaming_callback) = @_;

    if ($self->do_pull) {
        my $request = $self->_make_request('pull');
        my $response = $self->_send_request($request, $streaming_callback);
        croak('Failed to pull packages') if !$response->{success};
    }

    # Wire cpanm to our repo
    my @opts = ('--mirror', $self->mirror_uri, '--mirror-only');

    # Process other cpanm options
    my $cpanm_options = $self->cpanm_options;
    for my $opt (sort keys %$cpanm_options) {
        my $dash = length $opt == 1 ? '-' : '--';
        push @opts, "$dash$opt", grep defined && length, $cpanm_options->{$opt}
    }

    # Scrub passwords from the command so they don't appear in the logs
    my @sanitized = map mask_uri_passwords($_), @opts;
    $self->chrome->info( join ' ', 'Running:', $self->cpanm_exe, @sanitized, $self->targets );

    # Run cpanm
    system($self->cpanm_exe, @opts, $self->targets) == 0
        or croak("Installation failed. See the cpanm build log for details");
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pinto::Remote::SelfContained::Action::Install

=head1 NAME

Pinto::Remote::SelfContained::Action::Install

=head1 NAME

Pinto::Remote::SelfContained::Action::Install - Install packages from the repository

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>, Brad Lhotsky E<lt>brad@divisionbyzero.netE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
