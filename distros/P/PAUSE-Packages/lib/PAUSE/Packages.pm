package PAUSE::Packages;
$PAUSE::Packages::VERSION = '0.17';
use 5.8.1;
use autodie 2.29 qw(open);

use Moo 1.006;

use CPAN::DistnameInfo;
use Carp;
use File::HomeDir 0.93;
use File::Spec::Functions 'catfile';
use HTTP::Date qw(time2str);
use HTTP::Tiny;
use JSON::MaybeXS;
use PAUSE::Packages::Module;
use PAUSE::Packages::Release;
use Safe::Isa;
use Types::URI -all;
use Types::Standard qw( Bool Object Str );
use URI;
use URL::Encode qw( url_encode );

my $DISTNAME = 'PAUSE-Packages';

has from_cache => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
);

has ua => (
    is      => 'ro',
    isa     => Object,
    default => sub { return HTTP::Tiny->new },
);

has url => (
    is  => 'ro',
    isa => Uri,
    coerce => 1,
    default =>
        sub { return 'http://www.cpan.org/modules/02packages.details.txt' },
);

has path => (
    is  => 'rw',
    isa => Str,
);

sub release_iterator
{
    my $self = shift;

    require PAUSE::Packages::ReleaseIterator;
    return PAUSE::Packages::ReleaseIterator->new( packages => $self, @_ );
}

sub release
{
    my $self     = shift;
    my $distname = shift;
    my $fh;
    local $_;

    open($fh, '<', $self->path);
    while (<$fh>) {
        last if /^$/;
    }
    while (<$fh>) {
        chomp;
        my ($path, $json) = split(/\s+/, $_, 2);
        my $di = CPAN::DistnameInfo->new($path);
        next RELEASE if !defined($di) || !defined($di->dist);
        last if $di->dist gt $distname;
        if ($di->dist eq $distname) {
            my $modules = [];
            foreach my $entry (@{ decode_json($json) }) {
                my $module = PAUSE::Packages::Module->new(
                                name    => $entry->[0],
                                version => $entry->[1],
                             );
                push(@$modules, $module);
            }
            return PAUSE::Packages::Release->new(
                                 modules => $modules,
                                    path => $path,
                                distinfo => $di,
                                );
        }
    }
    close($fh);
    return undef;
}

sub BUILD
{
    my $self = shift;

    # If constructor didn't specify a local file, then mirror the file from CPAN
    if (not $self->path) {
        # use a file name which is unique to the URI
        my $cache_file_name = url_encode( $self->url );

        $self->path( catfile(File::HomeDir->my_dist_data( $DISTNAME, { create => 1 } ), $cache_file_name) );
        $self->_cache_file_if_needed();
    }
}

sub _cache_file_if_needed
{
    my $self    = shift;
    my $options = $self->ua->$_isa( 'HTTP::Tiny' ) ? {} : [];

    my $cache_creation_time = (stat($self->path))[9];

    if (-f $self->path) {
        if ( $self->ua->$_isa( 'HTTP::Tiny' ) ) {
            $options->{headers}->{'If-Modified-Since'}
                = time2str( $cache_creation_time );
        }
        else {
            $options = [ 'If-Modified-Since' => time2str( $cache_creation_time ) ];
        }

        my $uri = $self->url;
        $uri->scheme( 'file' ) if !$uri->scheme;

        if (   $uri->scheme eq 'file'
            && -f $uri->path
            && ( stat( $uri->path ) )[9] < $cache_creation_time )
        {
            $self->_set_from_cache( 1 );
            return;
        }
    }

    my $response = $self->ua->get( $self->url,
        $self->ua->$_isa( 'HTTP::Tiny' ) ? $options : @{$options} );

    my $status   = $response->$_can('code') ? $response->code : $response->{status};
    if ( $status == 304) { ; # Not Modified
        $self->_set_from_cache( 1 );
        return;
    }

    if ($status == 200) {
        $self->_transform_and_cache( $response->$_can('content')
            ? $response->content
            : $response->{content} );
        $self->_set_from_cache ( 0 );
        return;
    }

    my $reason = $response->$_can('message') ? $response->message : $response->{reason};
    croak("request for 02packages failed: $status $reason");
}

sub _transform_and_cache
{
    my ($self, $content) = @_;
    my $inheader = 1;
    my (%release, %other, $module, $version, $path, $distname);

    LINE:
    while ($content =~ m!^(.*)$!gm) {
        my $line = $1;
        if ($line =~ /^$/ && $inheader) {
            $inheader = 0;
            next;
        }
        next LINE if $inheader;
        ($module, $version, $path) = split(/\s+/, $line);

        my $di = CPAN::DistnameInfo->new($path);

        if (defined($di) && defined($distname = $di->dist) && defined($di->version)) {
            if (!exists($release{$distname}) || $release{$distname}->{version} lt $di->version) {
                $release{$distname} = {
                                    version => $di->version,
                                    modules => [ { name => $module, version => $version } ],
                                    path    => $path,
                                   };
            } elsif ($di->version lt $release{$distname}->{version}) {
                next LINE;
            } else {
                push(@{ $release{$distname}->{modules} },
                     { name => $module, version => $version }
                    );
            }
        } else {
            push(@{ $other{$path} }, { name => $module, version => $version });
        }
    }

    open(my $fh, '>', $self->path);

    print $fh <<"END_HEADER";
File: PAUSE Packages data
Format: 2
Source: CPAN/modules/02packages.details.txt

END_HEADER

    foreach $distname (sort keys %release) {
        print $fh $release{$distname}->{path}, ' ';
        print $fh "[", join(",", map { '["'.$_->{name}.'","'.$_->{version}.'"]' } @{ $release{$distname}->{modules} }), "]\n";
    }

    foreach my $release (sort keys %other) {
        print $fh $release, ' ';
        print $fh "[", join(",", map { '["'.$_->{name}.'","'.$_->{version}.'"]' } @{ $other{$release} }), "]\n";
    }

    close($fh);
}

1;

=head1 NAME

PAUSE::Packages - interface to PAUSE's packages file (02packages.details.txt)

=head1 SYNOPSIS

  use PAUSE::Packages 0.12;

  my $pp       = PAUSE::Packages->new;
  my $iterator = $pp->release_iterator();

  while (my $release = $iterator->next_release) {
    print 'path = ', $release->path, "\n";
    print '   modules = ', join(', ', @{ $release->modules }), "\n";
  }

  $release = $pp->release('Module-Path');

  # to parse a local file
    my $pp = PAUSE::Packages->new(
        url => 'file:///path/to/02packages.details.txt',
        ua  => LWP::UserAgent->new,
    );

=head1 DESCRIPTION

B<NOTE>: this is very much an alpha release. any and all feedback appreciated.

PAUSE::Packages provides an interface to the C<02packages.details.txt>
file produced by the Perl Authors Upload Server (PAUSE).
The file records what version of what modules are included in each
release of a distribution that is on CPAN.

PAUSE::Packages processes 02packages.details.txt and caches a transformed
version of the data, with the following characteristics:

=over 4

=item *

Only the highest numbered version of a module is included.

=item *

All modules in a release are written together, to make it efficient to
iterate over the file release by release.
02packages is sorted by module name, not by release, which means it can't
be efficiently processed by an iterator.

=back

The interface for this distribution is very much still in flux,
as is the documentation.

=head1 constructor

The constructor (C<new()>) can be passed an argument C<path>,
along with a path to a local copy of the I<cached format> used by
PAUSE::Packages:

 $pp = PAUSE::Packages->new(path => 'mypackages.txt');

Note: this is not the same format used by 02packages.details.txt,
as described above.

If you don't specify a path, then the local cache path is generated,
and you can use the C<path> attribute to find out what it is:

 $pp = PAUSE::Packages->new();
 print "cache path = ", $pp->path, "\n";

In a future release this will change: there will be separate attributes
for the cache path and the path to your own local copy.

=head1 METHODS

=head2 release_iterator()

See the SYNOPSIS.

This supports one optional argument, C<well_formed>,
which if true says that the iterator should only return releases
where the dist name and author's PAUSE id could be found:

 my $iterator = PAUSE::Packages->new()->release_iterator(
                    well_formed => 1
                );

This saves you from having to write code like the following:

 while (my $release = $iterator->next_release) {
    next unless defined($release->distinfo);
    next unless defined($release->distinfo->dist);
    next unless defined($release->distinfo->cpanid);
    ...
 }

=head2 release($DISTNAME)

Takes a dist name and returns an instance of L<PAUSE::Packages::Release>,
or C<undef> if a release couldn't be found for the specified distname.

=head2 ua( MyUserAgent->new )

Allows you to provide your own UserAgent.  This is useful if you're working off
a local copy of 02packages.details.txt  The default UserAgent is HTTP::Tiny,
which does not support the file:// schema.  So, if you want to work with a
local file you can either set up local web server using something like
L<App::HTTPThis>, or you can provide a your own UserAgent (like
L<LWP::UserAgent> which does support this behaviour.

=head2 url

The URL to the 02packages.details.txt which you would like to parse.  Defaults
to cpan.org  If you want to use the file:// scheme to fetch your local package,
be sure to provide your own UserAgent.  See the ua method above.

=head1 NOTE

The behaviour of this module changed between version 0.01 and 0.02,
so you should make sure you're using 0.02 or later:

  use PAUSE::Packages 0.02;

=head1 SEE ALSO

There are at least three other modules on CPAN
for parsing 02packages.details.txt.
There are two main differences between these modules and PAUSE::Packages:
(1) you have to download 02packages yourself, and
(2) if there are multiple releases of a dist on CPAN, containing different modules (eg due to refactoring), then you'll see the union of all modules, instead of just the modules in the most recent release.

=over 4

=item *

L<Parse::CPAN::Packages>

=item *

L<Parse::CPAN::Packages::Fast> - a 'largely API compatible rewrite' of
the above module, which is claimed to be a lot faster.

=item *

L<Parse::CPAN::Perms>

=item *

L<CPAN::Common::Index> - aims to be a common interface to all available backends

=item *

L<CPAN::PackageDetails> - can be used to read an existing copy of
02packages.details.txt, or to create your own.

=back

=head1 REPOSITORY

L<https://github.com/neilb/PAUSE-Packages>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

