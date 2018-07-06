package Perl::Critic::MergeProfile;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.002';

use Carp         ();
use Config::Tiny ();
use Scalar::Util ();

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    return $self;
}

sub read {
    my $self = shift;

    my $config = Config::Tiny->read(@_);

    Carp::croak Config::Tiny->errstr() if !defined $config;

    $self->_merge($config);

    return $self;
}

sub read_string {
    my $self = shift;

    my $config = Config::Tiny->read_string(@_);

    Carp::croak Config::Tiny->errstr() if !defined $config;

    $self->_merge($config);

    return $self;
}

sub _merge {
    my ( $self, $config ) = @_;

    if ( !exists $self->{_config} ) {
        $self->{_config} = $config;
        return;
    }

    for my $key ( grep { !m{ ^ - }xsm } keys %{$config} ) {
        Carp::croak "$key is enabled and disabled in the same profile" if exists $config->{"-$key"};
    }

  KEY:
    for my $key ( keys %{$config} ) {
        if ( $key =~ m { ^ - (.+ ) }xsm ) {
            my $policy = $1;
            delete $self->{_config}{$policy};
            $self->{_config}{$key} = {};
            next KEY;
        }

        if ( $key eq '_' ) {
            if ( !exists $self->{_config}{'_'} ) {
                $self->{_config}{'_'} = {};
            }

            %{ $self->{_config}{'_'} } = ( %{ $self->{_config}{'_'} }, %{ $config->{'_'} } );
            next KEY;
        }

        delete $self->{_config}{"-$key"};
        $self->{_config}{$key} = $config->{$key};
    }

    return;
}

sub write {
    my $self = shift;

    Carp::croak 'No policy exists to write' if !exists $self->{_config} || !Scalar::Util::blessed( $self->{_config} ) || !$self->{_config}->isa('Config::Tiny');

    my $rc = $self->{_config}->write(@_);

    Carp::croak Config::Tiny->errstr() if !$rc;

    return $rc;
}

sub write_string {
    my $self = shift;

    Carp::croak 'No policy exists to write' if !exists $self->{_config} || !Scalar::Util::blessed( $self->{_config} ) || !$self->{_config}->isa('Config::Tiny');

    my $string = $self->{_config}->write_string(@_);

    Carp::croak Config::Tiny->errstr() if !defined $string;

    return $string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::MergeProfile - merge multiple Perl::Critic profiles into one

=head1 VERSION

Version 0.002

=head1 SYNOPSIS

    use Perl::Critic::MergeProfile;

    my $merge = Perl::Critic::MergeProfile->new;
    $merge->read('xt/author/perlcriticrc-base');
    $merge->read('xt/author/perlcriticrc-project');
    $merge->write('xt/author/perlcriticrc-merged');

=head1 DESCRIPTION

Merges multiple L<Perl::Critic|Perl::Critic> profiles into a single one.

This allows to keep a common base profile for all projects but add project
specific changes to the profile.

=head1 USAGE

=head2 new

Returns a new C<Perl::Critic::MergeProfile>
instance. Arguments to C<new> are ignored.

=head2 read( FILENAME, [ ENCODING ] )

Calls C<read> from L<Config::Tiny|Config::Tiny> with the same arguments it
was called. Please see the documentation for C<read> of
L<Config::Tiny|Config::Tiny> for an explanation of the parameters.

If no valid L<Config::Tiny|Config::Tiny> object is returned an exception is
thrown.

If this is the first call to C<read> or C<read_string>, the returned
L<Config::Tiny|Config::Tiny> object is used as the base of the new merged
profile. No checks are performed on this first profile object.

Otherwise, the returned object is checked and if the same policy is enabled
and disabled in this new profile an exception is thrown.

After that, existing entries for this policy are removed from the base policy
and a new entry either a disabled or enabled policy is added.

Entries in the global section of this profile overwrite the existing entries
with the same name in the global section.

=head2 read_string( STRING )

Behaves the same as C<read> but calls C<read_string> from
L<Config::Tiny|Config::Tiny>.

=head2 write( FILENAME, [ ENCODING ] )

An exception is thrown if no valid policy exists, because neither C<read> nor
C<read_string> were successfully called at least once.

Otherwise C<write> from L<Config::Tiny|Config::Tiny> is called on the profile
with the same arguments C<write> was called. Please see the documentation for
C<write> of L<Config::Tiny|Config::Tiny> for an explanation of the parameters.

Returns something I<true> if on success and throws an exception otherwise.

=head2 write_string

Behaves the same as C<write> but calls C<write_string> from
L<Config::Tiny|Config::Tiny>.

Returns the policy as string on success and throws an exception otherwise.

=head1 EXAMPLES

=head2 Example 1 L<Test::Perl::Critic|Test::Perl::Critic>

The following test script can be used to test your code with
L<Perl::Critic|Perl::Critic> with a merged profile.

    use 5.006;
    use strict;
    use warnings;

    use Test::More 0.88;
    use Perl::Critic::MergeProfile;

    eval {
        my $merge = Perl::Critic::MergeProfile->new;
        $merge->read('xt/author/perlcriticrc-base');
        $merge->read('xt/author/perlcriticrc-project');

        my $profile = $merge->write_string;

        require Test::Perl::Critic;
        Test::Perl::Critic->import(-profile => \$profile);
        1;
    } || do {
        my $error = $@;
        BAIL_OUT($error);
    };

    all_critic_ok();

=head1 SEE ALSO

L<Config::Tiny|Config::Tiny>, L<Perl::Critic|Perl::Critic>,
L<Test::Perl::Critic|Test::Perl::Critic>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Perl-Critic-MergeProfile/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Perl-Critic-MergeProfile>

  git clone https://github.com/skirmess/Perl-Critic-MergeProfile.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
