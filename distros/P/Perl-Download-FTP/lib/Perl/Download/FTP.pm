package Perl::Download::FTP;
use strict;
use warnings;
use 5.10.1;
use Carp;
use Net::FTP;
use File::Copy;
use Cwd;
use File::Spec;
our $VERSION = '0.01';

=head1 NAME

Perl::Download::FTP - Identify Perl releases and download the most recent via FTP

=head1 SYNOPSIS

    use Perl::Download::FTP;

    $self = Perl::Download::FTP->new( {
        host        => 'ftp.cpan.org',
        dir         => '/pub/CPAN/src/5.0',
        verbose     => 1,
    } );

    @all_releases = $self->ls();

    $classified_releases = $self->classify_releases();

    @releases = $self->list_releases( {
        type            => 'production',
        compression     => 'gz',
    } );

    $latest_release = $self->get_latest_release( {
        compression     => 'gz',
        type            => 'dev',
        dir             => '/path/to/download',
        verbose         => 1,
    } );

=head1 DESCRIPTION

This library provides (a) methods for obtaining a list of all Perl 5 releases
which are available for FTP download; and (b) a method for obtaining the most
recent release.

=head2 Compression Formats

Perl releases have, over time, used three different compression formats:
C<gz>, C<bz2> and C<xz>.  C<gz> is the one that has been used in every
production, development and release candidate release, so that is the default
value used herein.  All three compression formats are available for use herein.

=head2 Testing

This library can only be truly tested by attempting live FTP connections and
downloads of Perl 5 source code tarballs.  Since testing over the internet
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

Perl::Download::FTP constructor.

=item * Arguments

    $self = Perl::Download::FTP->new();

    $self = Perl::Download::FTP->new( {
        host        => 'ftp.cpan.org',
        dir         => '/pub/CPAN/src/5.0',
        verbose     => 1,
    } );

    $self = Perl::Download::FTP->new( {
        host        => 'ftp.cpan.org',
        dir         => '/pub/CPAN/src/5.0',
        Timeout     => 5,
    } );

Takes a hash reference with, typically, two elements:  C<host> and C<dir>.
Any options which can be passed to F<Net::FTP::new()> may also be passed as
key-value pairs.  When no argument is provided, the values shown above for
C<host> and C<dir> will be used.  You may enter values for any CPAN mirror
which provides FTP access.  (See L<https://www.cpan.org/SITES.html> and
L<http://mirrors.cpan.org/>.)  You may also pass C<verbose> for more
descriptive output; by default, this is off.

=item * Return Value

Perl::Download::FTP object.

=item * Comment

The method establishes an FTP connection to <host>, logs you in as an
anonymous user, and changes directory to C<dir>.

Wrapper around Net::FTP object.  You will get Net::FTP error messages at any
point of failure.  Uses FTP C<Passive> mode.

=back

=cut

sub new {
    my ($class, $args) = @_;
    $args //= {};
    croak "Argument to constructor must be hashref"
        unless ref($args) eq 'HASH';

    my %default_args = (
        host    => 'ftp.cpan.org',
        dir     => '/pub/CPAN/src/5.0',
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

    $ftp->cwd($data->{dir})
        or croak "Cannot change to working directory $data->{dir}", $ftp->message;

    $data->{ftp} = $ftp;

    my @compressions = (qw| gz bz2 xz |);
    $data->{eligible_compressions}  = { map { $_ => 1 } @compressions };
    $data->{compression_string}     = join('|' => @compressions);

    return bless $data, $class;
}

=head2 C<ls()>

=over 4

=item * Purpose

Identify all Perl releases.

=item * Arguments

    @all_releases = $self->ls();

Returns list of all Perl core tarballs on the FTP host.

    @all_gzipped_releases = $self->ls('gz');

Returns list of only those all tarballs on the FTP host which are compressed
in C<.gz> format.  Also available (in separate calls):  C<bz2>, C<xz>.

=item * Return Value

List of strings like:

    "perl-5.10.0-RC2.tar.gz",
    "perl-5.10.0.tar.gz",
    "perl-5.26.0.tar.gz",
    "perl-5.26.1-RC1.tar.gz",
    "perl-5.27.0.tar.gz",
    "perl-5.6.0.tar.gz",
    "perl-5.6.1-TRIAL1.tar.gz",
    "perl-5.6.1-TRIAL2.tar.gz",
    "perl-5.6.1-TRIAL3.tar.gz",
    "perl5.003_07.tar.gz",
    "perl5.004.tar.gz",
    "perl5.004_01.tar.gz",
    "perl5.005.tar.gz",
    "perl5.005_01.tar.gz",

    "perl-5.10.1.tar.bz2",
    "perl-5.12.2-RC1.tar.bz2",
    "perl-5.26.1-RC1.tar.bz2",
    "perl-5.27.0.tar.bz2",
    "perl-5.8.9.tar.bz2",

    "perl-5.21.10.tar.xz",
    "perl-5.21.6.tar.xz",
    "perl-5.22.0-RC1.tar.xz",
    "perl-5.22.0.tar.xz",
    "perl-5.22.1-RC4.tar.xz",
    "perl-5.26.1.tar.xz",
    "perl-5.27.2.tar.xz",

=back

=cut

sub ls {
    my ($self, $compression) = @_;
    if (! defined $compression) {
        $compression = $self->{compression_string};
    }
    else {
        croak "ls():  Bad compression format:  $compression"
            unless $self->{eligible_compressions}{$compression};
    }
    my @all_releases = grep {
        /^perl
        (?:
            -5\.\d+\.\d+        # 5.6.0 and above
            |
            5\.00\d(_\d{2})?    # 5.003_007 thru 5.005
        )
        .*?                     # Account for RC and TRIAL
        \.tar                   # We only want tarballs
        \.(?:${compression})    # Compression format
        $/x
    } $self->{ftp}->ls()
        or croak "Unable to perform FTP 'get' call to host: $!";
    $self->{all_releases} = \@all_releases;
    say "Identified ",
        scalar(@all_releases),
        " perl releases at ftp://$self->{host}$self->{dir}"
        if $self->{verbose};
    return @all_releases;
}

=head2 C<classify_releases()>

=over 4

=item * Purpose

Categorize releases as production, development or RC (release candidate).

=item * Arguments

None.  Works on data stored in object by C<ls()>.

=item * Return Value

Hash reference.

=back

=cut

sub classify_releases {
    my $self = shift;

    my %versions;
    for my $tb (@{$self->{all_releases}}) {
        my ($major, $minor, $rc);
        if ($tb =~ m/^
            perl-5\.(\d+)
            \.(\d+)
            (?:-((?:TRIAL|RC)\d+))?
            \.tar\.(?:gz|bz2|xz)
            $/x) {
            ($major, $minor, $rc) = ($1,$2,$3);
            if ($major % 2 == 0) {
                unless (defined $rc) {
                    $versions{prod}{$tb} = {
                        tarball => $tb,
                        major   => $major,
                        minor   => $minor,
                    }
                }
                else {
                    $versions{rc}{$tb} = {
                        tarball => $tb,
                        major   => $major,
                        minor   => $minor,
                        rc      => $rc,
                    }
                }
            }
            else {
                $versions{dev}{$tb} = {
                    tarball => $tb,
                    major   => $major,
                    minor   => $minor,
                }
            }
        }
        elsif ($tb =~ m/^
            perl5\.
            (00\d)
            (?:_(\d{2}))?   # 5.003_007 thru 5.005; account for RC and TRIAL
            .*?
            \.tar           # We only want tarballs
            \.gz            # Compression format
            $/x
        ) {
            my $early_dev;
            ($major, $early_dev) = ($1,$2);
            $early_dev //= '';
            if (! $early_dev) {
                $versions{prod}{$tb} = {
                    tarball => $tb,
                    major   => $major,
                    minor   => '',
                }
            }
            else {
                $versions{dev}{$tb} = {
                    tarball => $tb,
                    major   => $major,
                    minor   => $early_dev,
                }
            }
        }
    }
    $self->{versions} = \%versions;
    return \%versions;
}

sub _compression_check {
    my ($self, $compression) = @_;
    if (! defined $compression) {
        return 'gz';
    }
    else {
        croak "ls():  Bad compression format:  $compression"
            unless $self->{eligible_compressions}{$compression};
        return $compression;
    }
}

sub _prepare_list {
    my ($self, $compression) = @_;
    $compression = $self->_compression_check($compression);

    unless (exists $self->{versions}) {
        $self->classify_releases();
    }
    return $compression;
}

=head2 C<list_releases()>

=over 4

=item * Purpose

List all releases for a specified compression format and release type, sorted
in reverse logical order.

=item * Arguments

    @releases = $self->list_releases( {
        type            => 'production',
        compression     => 'gz',
    } );

Takes a hash reference with, typically two elements:

=over 4

=item * C<compression>

Available values:

    gz      bz2     xz

Defaults to C<gz>.

=item * C<type>

Available values:

    production      prod
    development     dev
    rc

Defaults to C<dev>.

=back

=item * Return Value

List of strings naming Perl release tarballs for the specified compression
format and type.  The list is sorted in reverse logical order, I<i.e.,> the
newest production release will be the first item in the list and the oldest
will be the last.  So, for instance, the list of development releases in C<gz>
format will start with something like:

    perl-5.27.5.tar.gz
    perl-5.27.4.tar.gz
    perl-5.27.3.tar.gz

and end with:

    perl5.004_02.tar.gz
    perl5.004_01.tar.gz
    perl5.003_07.tar.gz

=back

=cut

sub list_releases {
    my ($self, $args) = @_;
    $args ||= {};
    croak "Argument to method must be hashref"
        unless ref($args) eq 'HASH';
    my %eligible_types = (
        production      => 'prod',
        prod            => 'prod',
        development     => 'dev',
        dev             => 'dev',
        rc              => 'rc',
    );
    my $type;
    if (defined $args->{type}) {
        croak "Bad value for 'type': $args->{type}"
            unless $eligible_types{$args->{type}};
        $type = $eligible_types{$args->{type}};
    }
    else {
        $type = 'dev';
    }

    my $compression = 'gz';
    if (exists $args->{compression}) {
        $compression = $self->_compression_check($args->{compression});
    }
    $compression = $self->_prepare_list($compression);

    say "Preparing list of '$type' releases with '$compression' compression"
        if $self->{verbose};
    my @these_releases;
    if ($type eq 'prod') {
        @these_releases =
            grep { /\.${compression}$/ } sort {
            $self->{versions}->{$type}{$b}{major} <=> $self->{versions}->{$type}{$a}{major} ||
            $self->{versions}->{$type}{$b}{minor} <=> $self->{versions}->{$type}{$a}{minor}
        } keys %{$self->{versions}->{$type}};
        $self->{"${compression}_${type}_releases"} = \@these_releases;
        return @these_releases;
    }
    elsif ($type eq 'dev') {
        @these_releases =
            grep { /\.${compression}$/ } sort {
            $self->{versions}->{$type}{$b}{major} <=> $self->{versions}->{$type}{$a}{major} ||
            $self->{versions}->{$type}{$b}{minor} <=> $self->{versions}->{$type}{$a}{minor}
        } keys %{$self->{versions}->{$type}};
        $self->{"${compression}_${type}_releases"} = \@these_releases;
        return @these_releases;
    }
    else { # $type eq rc
        @these_releases =
            grep { /\.${compression}$/ } sort {
            $self->{versions}->{$type}{$b}{major} <=> $self->{versions}->{$type}{$a}{major} ||
            $self->{versions}->{$type}{$b}{minor} <=> $self->{versions}->{$type}{$a}{minor} ||
            $self->{versions}->{$type}{$b}{rc}    cmp $self->{versions}->{$type}{$a}{rc}
        } keys %{$self->{versions}->{$type}};
        $self->{"${compression}_${type}_releases"} = \@these_releases;
        return @these_releases;
    }
}

=head2 C<get_latest_release()>

=over 4

=item * Purpose

Download the latest release via FTP.

=item * Arguments

    $latest_release = $self->get_latest_release( {
        compression     => 'gz',
        type            => 'dev',
        path            => '/path/to/download',
        verbose         => 1,
    } );

=item * Return Value

Scalar holding path to download of tarball.

=back

=cut

sub get_latest_release {
    my ($self, $args) = @_;
    croak "Argument to method must be hashref"
        unless ref($args) eq 'HASH';
    my %eligible_types = (
        production      => 'prod',
        prod            => 'prod',
        development     => 'dev',
        dev             => 'dev',
        rc              => 'rc',
    );
    my $type;
    if (defined $args->{type}) {
        croak "Bad value for 'type': $args->{type}"
            unless $eligible_types{$args->{type}};
        $type = $eligible_types{$args->{type}};
    }
    else {
        $type = 'dev';
    }

    my $compression = 'gz';
    if (exists $args->{compression}) {
        $compression = $self->_compression_check($args->{compression});
    }
    my $cache = "${compression}_${type}_releases";

    my $path = cwd();
    if (exists $args->{path}) {
        croak "Value for 'path' not found" unless (-d $args->{path});
        $path = $args->{path};
    }
    my $latest;
    if (exists $self->{$cache}) {
        say "Identifying latest $type release from cache" if $self->{verbose};
        $latest = $self->{$cache}->[0];
    }
    else {
        say "Identifying latest $type release" if $self->{verbose};
        my @releases = $self->list_releases( {
            compression     => $compression,
            type            => $type,
        } );
        $latest = $releases[0];
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

Copyright James E Keenan 2017.  All rights reserved.

=head1 SEE ALSO

perl(1).  Net::FTP(3).  Test::RequiresInternet(3).

=cut

1;
