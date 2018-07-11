package Perl::Download::FTP::Distribution;
use strict;
use warnings;
use 5.10.1;
use Carp;
use Net::FTP;
use File::Copy;
use Cwd;
use File::Spec;
our $VERSION = '0.05';

=head1 NAME

Perl::Download::FTP::Distribution - Identify CPAN distributions and download the most recent tarball via FTP

=head1 SYNOPSIS

    use Perl::Download::FTP::Distribution;

    $self = Perl::Download::FTP::Distribution->new( {
        host            => 'ftp.cpan.org',
        dir             => 'pub/CPAN/modules/by-module',
        distribution    => 'Test-Smoke',
        verbose         => 1,
    } );

    @all_releases = $self->ls();

    $latest_release = $self->get_latest_release( {
        path            => '/path/to/download',
        verbose         => 1,
    } );

=head1 DESCRIPTION

This library provides (a) methods for obtaining a list of all releases
available on CPAN for a given Perl distribution; and (b) a method for
downloading the most recent release or a specific release.

This library is similar to F<Perl::Download::FTP> contained in this same CPAN
distribution, except that in this module our objective is to download a CPAN
library rather than a tarball of the Perl 5 core distribution.

=head2 Testing

This library can only be truly tested by attempting live FTP connections and
downloads of tarballs of CPAN distributions.  Since testing over the internet
can be problematic when being conducted in an automatic manner or when the
user is behind a firewall, the test files under F<t/> will only be run live
when you say:

    export PERL_ALLOW_NETWORK_TESTING=1 && make test

Each test file further attempts to confirm the possibility of making an FTP
connection by using CPAN library Test::RequiresInternet.

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Perl::Download::FTP::Distribution constructor.

=item * Arguments

    $self = Perl::Download::FTP::Distribution->new( {
        distribution    => 'Test-Smoke',
    } );

    $self = Perl::Download::FTP::Distribution->new( {
        distribution    => 'Test-Smoke',
        host            => 'ftp.cpan.org',
        dir             => 'pub/CPAN/modules/by-module',
        verbose         => 1,
    } );

    $self = Perl::Download::FTP::Distribution->new( {
        distribution    => 'Test-Smoke',
        host            => 'ftp.cpan.org',
        dir             => 'pub/CPAN/modules/by-module',
        Timeout     => 5,
    } );

Takes a hash reference with, typically, three elements:  C<distribution>,
C<host> and C<dir>.

=over 4

=item *

The C<distribution> element is mandatory; its value must be spelled with
hyphens (I<e.g.>, C<Test-Smoke>, rather than with the double colons used for
modules (C<Test::Smoke>).

=item *

When no argument is provided for either of C<host> or C<dir>, the values shown
above for C<host> and C<dir> will be used.  You may enter values for any CPAN
mirror which provides FTP access.  (See L<https://www.cpan.org/SITES.html> and
L<http://mirrors.cpan.org/>.)

=item *

Any options which can be passed to F<Net::FTP::new()> may also be passed as
key-value pairs.

=item *

You may also pass C<verbose> for more descriptive output; by default, this is
off.

=back

=item * Return Value

Perl::Download::FTP::Distribution object.

=item * Comments

The method establishes an FTP connection to <host>, logs you in as an
anonymous user, and changes directory to C<dir>.

Wrapper around Net::FTP object.  You will get Net::FTP error messages at any
point of failure.  Uses FTP C<Passive> mode.

Note that the value for C<dir> on a given CPAN FTP mirror is different from
the value for C<dir> one would use in downloading a Perl 5 core distribution
tarball via F<Perl::Download::FTP>.

=back

=cut

sub new {
    my ($class, $args) = @_;
    $args //= {};
    croak "Argument to constructor must be hashref"
        unless ref($args) eq 'HASH';
    croak "Must provide 'distribution' element"
        unless $args->{distribution};

    # The value for 'dir' we pass to the constructor differs among FTP
    # mirrors but is uniform within a given mirror.  However, it is *not* the
    # directory to which we will actually change down below.  That's because
    # the tarballs are stored one directory farther down, in a directory named
    # by the "top-level" of the distribution's name.  So, for example, on
    # ftp.cpan.org, Test-Smoke-1.71.tar.gz will be found in:
    #    pub/CPAN/modules/by-module/Test/
    # rather than in:
    #    pub/CPAN/modules/by-module/

	my ($host_subdir) = $args->{distribution} =~ m/^([^-]+)/;

    my %default_args = (
        host    => 'ftp.cpan.org',
        dir     => 'pub/CPAN/modules/by-module',
        verbose => 0,
    );
    my $default_args_string = join('|' => keys %default_args);
    my %netftp_options = (
        Firewall        => undef,
        FirewallType    => undef,
        BlockSize       => 10240,
        Port            => undef,
        SSL             => undef,
        Timeout         => 120,
        Debug           => 0,
        Passive         => 1,
        Hash            => undef,
        LocalAddr       => undef,
        Domain          => undef,
    );
    my %permitted_args = map {$_ => 1} (
        'distribution',
        keys %default_args,
        keys %netftp_options,
    );

    for my $k (keys %{$args}) {
        croak "Argument '$k' not permitted in constructor"
            unless $permitted_args{$k};
    }

    my $data;
    # Populate object starting with default host and directory
    while (my ($k,$v) = each %default_args) {
        $data->{$k} = $v;
    }
    # Then add Net::FTP plausible defaults
    while (my ($k,$v) = each %netftp_options) {
        $data->{$k} = $v;
    }
    # Then override with key-value pairs passed to new()
    while (my ($k,$v) = each %{$args}) {
        $data->{$k} = $v;
    }

    # For the Net::FTP constructor, we don't need 'dir' and 'host'
    my %passed_netftp_options;
    for my $k (keys %{$data}) {
        $passed_netftp_options{$k} = $data->{$k}
            unless ($k =~ m/^($default_args_string)$/);
    }

    my $ftp = Net::FTP->new($data->{host}, %passed_netftp_options)
        or croak "Cannot connect to $data->{host}: $@";

    $ftp->login("anonymous",'-anonymous@')
        or croak "Cannot login ", $ftp->message;

    $data->{subdir} = "$data->{dir}/$host_subdir";
    $ftp->cwd($data->{subdir})
        or croak "Cannot change to working directory $data->{subdir}", $ftp->message;

    $data->{ftp} = $ftp;

    return bless $data, $class;
}

=head2 C<ls()>

=over 4

=item * Purpose

Identify all currently available tarballs of the CPAN distribution in question.

=item * Arguments

    @all_releases = $self->ls();

None; all information needed is in the object.

=item * Return Value

List of strings like:

    'Test-Smoke-1.53.tar.gz',
    'Test-Smoke-1.59.tar.gz',
	'Test-Smoke-1.6.tar.gz',
	'Test-Smoke-1.70.tar.gz',
    'Test-Smoke-1.71.tar.gz',

=item * Comment

Results do not include versions which have been moved to BackCPAN.

=back

=cut

sub ls {
    my ($self) = shift;
    my $extensions = qr/(?:tar\.(?:g?z|bz2)|zip|tgz)/;
    my @releases = grep
        { m/^$self->{distribution}-v?\d+\.\d+(?:\.\d+)?\.$extensions$/ }
        $self->{ftp}->ls()
        or croak "Unable to perform FTP 'get' call to host: $!";
    my %releases;
    for my $r (@releases) {
        my ($v, $w, $x, $y);
        if (($v) = $r =~ m/^$self->{distribution}-v?(\d+\.\d+)\.$extensions$/) {
            $releases{$r} = $v;
        }
        elsif (($w, $x, $y) = $r =~ m/^$self->{distribution}-v?(\d+)\.(\d+)\.(\d+)\.$extensions$/) {
            my $v = sprintf("%04d%04d%04d" => ($w, $x, $y));
            $releases{$r} = $v;
        }
        else {
            croak "Unable to analyze $r";
        }
    }
    my @sorted_releases = sort { $releases{$a} <=> $releases{$b} } keys %releases;;
    $self->{cache} = [ @sorted_releases ];
    return @sorted_releases;;
}


=head2 C<get_latest_release()>

=over 4

=item * Purpose

Download the latest release via FTP.

=item * Arguments

    $latest_release = $self->get_latest_release( {
        path            => '/path/to/download',
        verbose         => 1,
    } );

Takes a hash reference with two possible elements: C<path> and C<verbose>.
The value of C<path> should be a string holding the path to the directory to
which the tarball will be downloaded.  If not provided, the tarball will be
downloaded to the current working directory.

=item * Return Value

Scalar holding path to download of tarball.

=back

=cut

sub get_latest_release {
    my ($self, $args) = @_;
    croak "Argument to method must be hashref"
        unless ref($args) eq 'HASH';

    my $path = cwd();
    if (exists $args->{path}) {
        croak "Value for 'path' not found" unless (-d $args->{path});
        $path = $args->{path};
    }
    my $latest;
    if (exists $self->{cache} and ref($self->{cache}) eq 'ARRAY' and scalar(@{$self->{cache}})) {
        $latest = $self->{cache}->[-1];
        say "Latest release $latest identified from cached ls() call" if $args->{verbose};
    }
    else {
        my @releases = $self->ls();
        $latest = $releases[-1];
    }

    say "Performing FTP 'get' call for: $latest" if $self->{verbose};
    my $starttime = time();
    $self->{ftp}->get($latest)
        or croak "Unable to perform FTP get call: $!";
    my $endtime = time();
    say "Elapsed time for FTP 'get' call: ", $endtime - $starttime, " seconds"
        if $self->{verbose};
    my $rv = File::Spec->catfile($path, $latest);
    move $latest, $rv or croak "Unable to move $latest to $path";
    say "See: $rv" if $self->{verbose};
    return $rv;
}

1;

=head1 BUGS AND SUPPORT

Please report any bugs by mail to C<bug-Perl-Download-FTP@rt.cpan.org>
or through the web interface at L<http://rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

Thanks for feedback from Chad Granum, Kent Fredric and David Golden
in the perl.cpan.workers newsgroup.

=head1 AUTHOR

    James E Keenan
    CPAN ID: JKEENAN
    jkeenan@cpan.org
    http://thenceforward.net/perl

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

Copyright James E Keenan 2018.  All rights reserved.

=head1 SEE ALSO

perl(1).  Net::FTP(3).  Test::RequiresInternet(3).

=cut

1;

