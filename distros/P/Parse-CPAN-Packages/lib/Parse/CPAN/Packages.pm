package Parse::CPAN::Packages;
use Moo;
use CPAN::DistnameInfo;
use Compress::Zlib;
use Path::Class ();
use File::Slurp 'read_file';
use Parse::CPAN::Packages::Distribution;
use Parse::CPAN::Packages::Package;
use Types::Standard qw( HashRef Maybe Str );
use version;
our $VERSION = '2.40';

has 'filename' => ( is => 'rw', isa => Str );
has 'mirror_dir' => ( is => 'lazy', isa => Maybe [Str] );

has 'details'     => ( is => 'rw', isa => HashRef, default => sub { {} } );
has 'data'        => ( is => 'rw', isa => HashRef, default => sub { {} } );
has 'dists'       => ( is => 'rw', isa => HashRef, default => sub { {} } );
has 'latestdists' => ( is => 'rw', isa => HashRef, default => sub { {} } );

sub BUILDARGS {
    my ( $class, @args ) = @_;
    return {@args} if @args > 1;
    return { filename => $args[0] };
}

sub BUILD {
    my $self     = shift;
    my $filename = $self->filename;

    # read the file then parse it if present
    $self->parse( $filename ) if $filename;

    return $self;
}

sub _build_mirror_dir {
    my ( $self ) = @_;
    return if $self->filename =~ /\n/;
    return if !-f $self->filename;
    my $dir = Path::Class::file( $self->filename )->dir->parent;
    return $dir->stringify;
}

# read the file into memory and return it
sub _slurp_details {
    my ( $self, $filename ) = @_;
    $filename ||= '02packages.details.txt.gz';

    return $filename if $filename =~ /Description:/;
    return Compress::Zlib::memGunzip( $filename ) if $filename =~ /^\037\213/;

    my @read_params = ( $filename );
    push @read_params, ( binmode => ':raw' ) if $filename =~ /\.gz/;

    my $data = read_file( @read_params );

    return Compress::Zlib::memGunzip( $data ) if $filename =~ /\.gz/;
    return $data;
}

for my $subname ( qw(file url description columns intended_for written_by line_count last_updated) ) {
    no strict 'refs';
    *{$subname} = sub { return shift->{preamble}{$subname} };
}

sub parse {
    my ( $self, $filename ) = @_;

    # read the preamble
    my @details = split "\n", $self->_slurp_details( $filename );
    while ( @details ) {
        local $_ = shift @details;
        last if /^\s*$/;
        next unless /^([^:]+):\s*(.*)/;
        my ( $key, $value ) = ( lc( $1 ), $2 );
        $key =~ tr/-/_/;
        $self->{preamble}{$key} = $value;
    }

    # run though each line of the file
    for my $line ( @details ) {

        # make a package object from the line
        my ( $package_name, $package_version, $prefix ) = split ' ', $line;
        $self->add_quick( $package_name, $package_version, $prefix );
    }
}

sub add_quick {
    my ( $self, $package_name, $package_version, $prefix ) = @_;

    # create a distribution object (or get an existing one)
    my $dist = $self->distribution_from_prefix( $prefix );

    # create the package object
    my $m = Parse::CPAN::Packages::Package->new(
        {
            package      => $package_name,
            version      => $package_version,
            distribution => $dist
        }
    );

    # make the package have the distribion and the distribution
    # have the package.  Yes, this creates a cirtular reference.  eek!
    $dist->add_package( $m );

    # record this distribution and package
    $self->add_distribution( $dist );
    $self->add_package( $m );
}

sub distribution_from_prefix {
    my ( $self, $prefix ) = @_;

    # see if we have one of these already and return it if we do.
    my $d = $self->distribution( $prefix );
    return $d if $d;

    # create a new one otherwise
    my $i = CPAN::DistnameInfo->new( $prefix );
    $d = Parse::CPAN::Packages::Distribution->new(
        {
            prefix     => $prefix,
            dist       => $i->dist,
            version    => $i->version,
            maturity   => $i->maturity,
            filename   => $i->filename,
            cpanid     => $i->cpanid,
            distvname  => $i->distvname,
            mirror_dir => $self->mirror_dir,
        }
    );
    return $d;
}

sub add_package {
    my ( $self, $package ) = @_;

    # store it
    $self->data->{ $package->package } = $package;

    return $self;
}

sub package {
    my ( $self, $package_name ) = @_;
    return $self->data->{$package_name};
}

sub packages {
    my $self = shift;
    return values %{ $self->data };
}

sub add_distribution {
    my ( $self, $dist ) = @_;

    $self->_store_distribution( $dist );
    $self->_ensure_latest_distribution( $dist );
}

sub _store_distribution {
    my ( $self, $dist ) = @_;

    $self->dists->{ $dist->prefix } = $dist;
}

sub _ensure_latest_distribution {
    my ( $self, $new ) = @_;

    my $latest = $self->latest_distribution( $new->dist );
    if ( !$latest ) {
        $self->_set_latest_distribution( $new );
        return;
    }
    my $new_version    = $new->version;
    my $latest_version = $latest->version;
    my ( $newv, $latestv );

    eval {
        no warnings;
        $newv    = version->new( $new_version    || 0 );
        $latestv = version->new( $latest_version || 0 );
    };

    $self->_set_latest_distribution( $new ) if $self->_dist_is_latest( $newv, $latestv, $new_version, $latest_version );

    return;
}

sub _dist_is_latest {
    my ( $self, $newv, $latestv, $new_version, $latest_version ) = @_;
    return 1 if $newv && $latestv && $newv > $latestv;
    no warnings;
    return 1 if $new_version > $latest_version;
    return 0;
}

sub distribution {
    my ( $self, $dist ) = @_;
    return $self->dists->{$dist};
}

sub distributions {
    my $self = shift;
    return values %{ $self->dists };
}

sub _set_latest_distribution {
    my ( $self, $dist ) = @_;
    return unless $dist->dist;
    $self->latestdists->{ $dist->dist } = $dist;
}

sub latest_distribution {
    my ( $self, $dist ) = @_;
    return unless $dist;
    return $self->latestdists->{$dist};
}

sub latest_distributions {
    my $self = shift;
    return values %{ $self->latestdists };
}

sub package_count {
    my $self = shift;
    return scalar scalar $self->packages;
}

sub distribution_count {
    my $self = shift;
    return scalar $self->distributions;
}

sub latest_distribution_count {
    my $self = shift;
    return scalar $self->latest_distributions;
}

1;

__END__

=head1 NAME

Parse::CPAN::Packages - Parse 02packages.details.txt.gz

=head1 SYNOPSIS

  use Parse::CPAN::Packages;

  # must have downloaded
  my $p = Parse::CPAN::Packages->new("02packages.details.txt.gz");
  # either a filename as above or pass in the contents of the file
  # (uncompressed)
  my $p = Parse::CPAN::Packages->new($packages_details_contents);

  my $m = $p->package("Acme::Colour");
  # $m is a Parse::CPAN::Packages::Package object
  print $m->package, "\n";   # Acme::Colour
  print $m->version, "\n";   # 1.00

  my $d = $m->distribution();
  # $d is a Parse::CPAN::Packages::Distribution object
  print $d->prefix, "\n";    # L/LB/LBROCARD/Acme-Colour-1.00.tar.gz
  print $d->dist, "\n";      # Acme-Colour
  print $d->version, "\n";   # 1.00
  print $d->maturity, "\n";  # released
  print $d->filename, "\n";  # Acme-Colour-1.00.tar.gz
  print $d->cpanid, "\n";    # LBROCARD
  print $d->distvname, "\n"; # Acme-Colour-1.00

  # all the package objects
  my @packages = $p->packages;

  # all the distribution objects
  my @distributions = $p->distributions;

  # the latest distribution
  $d = $p->latest_distribution("Acme-Colour");
  is($d->prefix, "L/LB/LBROCARD/Acme-Colour-1.00.tar.gz");
  is($d->version, "1.00");

  # all the latest distributions
  my @distributions = $p->latest_distributions;

=head1 DESCRIPTION

The Comprehensive Perl Archive Network (CPAN) is a very useful
collection of Perl code. It has several indices of the files that it
hosts, including a file named "02packages.details.txt.gz" in the
"modules" directory. This file contains lots of useful information and
this module provides a simple interface to the data contained within.

In a future release L<Parse::CPAN::Packages::Package> and
L<Parse::CPAN::Packages::Distribution> might have more information.

=head2 Methods

=over

=item new

Creates a new instance from a details file.

The constructor can be passed either the path to the
C<02packages.details.txt.gz> file, a path to an ungzipped version of
this file, or a scalar containing the entire uncompressed contents of
the file.

Note that this module does not concern itself with downloading this
file. You should do this yourself.  For example:

   use LWP::Simple qw(get);
   my $data = get("http://www.cpan.org/modules/02packages.details.txt.gz");
   my $p = Parse::CPAN::Packages->new($data);

If you have a configured L<CPAN>, then there's usually already a
cached file available:

   use CPAN;
   $CPAN::Be_Silent = 1;
   CPAN::HandleConfig->load;
   my $file = $CPAN::Config->{keep_source_where} . "/modules/02packages.details.txt.gz";
   my $p = Parse::CPAN::Packages->new($file);

=item package($packagename)

Returns a C<Parse::CPAN::Packages::Package> that represents the
named package.

  my $p = Parse::CPAN::Packages->new($gzfilename);
  my $package = $p->package("Acme::Colour");

=item packages()

Returns a list of B<Parse::CPAN::Packages::Package> objects
representing all the packages that were extracted from the file.

=item package_count()

Returns the number of packages stored.

=item distribution($filename)

Returns a B<Parse::CPAN::Packages::Distribution> object that
represents the filename passed:

  my $p = Parse::CPAN::Packages->new($gzfilename);
  my $dist = $p->distribution('L/LB/LBROCARD/Acme-Colour-1.00.tar.gz');

=item distributions()

Returns a list of B<Parse::CPAN::Packages::Distribution> objects
representing all the known distributions.

=item distribution_count()

Returns the number of distributions stored.

=item latest_distribution($distname)

Returns the C<Parse::CPAN::Packages::Distribution> object that
represents the latest distribution for the named disribution passed,
that is to say it returns the distribution that has the highest
version number (as determined by version.pm or number comparison if
that fails):

  my $p = Parse::CPAN::Packages->new($gzfilename);
  my $dist = $p->distribution('Acme-Color');

=item latest_distrbutions()

Returns a list of B<Parse::CPAN::Packages::Distribution> objects
representing all the latest distributions.

=item latest_distribution_count()

Returns the number of distributions stored.

=back

=head2 Preamble Methods

These methods return the information from the preamble
at the start of the file. They return undef if for any reason
no matching preamble line was found.

=over

=item file()

=item url()

=item description()

=item columns()

=item intended_for()

=item written_by()

=item line_count()

=item last_updated()

=back

=head2 Addtional Methods

These are additional methods that you may find useful.

=over

=item parse($filename)

Parses the filename.  Works in a similar fashion to the the
constructor (i.e. you can pass it a filename for a
compressed/1uncompressed file, a uncompressed scalar containing the
file.  You can also pass nothing to indicate to load the compressed
file from the current working directory.)

Note that each time this function is run the packages and distribtions
found will be C<added> to the current list of packages.

=item add_quick($package_name, $package_version, $prefix)

Quick way of adding a new package and distribution.

=item add_package($package_obj)

Adds a package.  Note that you'll probably want to add the
corrisponding distribution for that package too (it's not done
automatically.)

=item add_distribution($distribution_obj)

Adds a distribution.  Note that you'll probably want to add the
corresponding packages for that distribution too (it's not done
automatically.)

=item distribution_from_prefix($prefix)

Returns a distribution given a prefix.

=item latest_distributions

Returns all the latest distributions:

  my @distributions = $p->latest_distributions;

=cut

=back

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004-9, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.

=head1 BUGS

This module leaks memory as packages hold distributions and
distributions hold packages.  No attempt has been made to fix this as
it's not anticpated that this will be used in long running programs
that will dispose of the objects once created.

The old interface for C<new> where if you passed no arguments it would
look for a C<02packages.details.txt.gz> in your current directory is
no longer supported.

=head1 TODO

delete_* methods.  merge_into method.  Documentation for other modules.

=head1 SEE ALSO

L<CPAN::DistInfoname>, L<Parse::CPAN::Packages::Writer>.
