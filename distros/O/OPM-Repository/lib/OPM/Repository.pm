package OPM::Repository;

# ABSTRACT: parse OPM repositories' framework.xml files to search for add ons

use strict;
use warnings;

our $VERSION = '1.0.0'; # VERSION

use Moo;
use List::Util qw(all);
use Scalar::Util qw(blessed);
use Regexp::Common qw(URI);

use OPM::Repository::Source;

our $ALLOWED_SCHEME = [ 'HTTP', 'file' ];

has sources => ( is => 'ro', required => 1, isa => sub {
    die "no valid URIs" unless 
        ref $_[0] eq 'ARRAY' 
        and
        all { _check_uri( $_ ) } @{ $_[0] }
});

has _objects => ( is => 'ro', isa => sub {
    die "no valid objects" unless 
        ref $_[0] eq 'ARRAY' 
        and
        all { blessed $_ and $_->isa( 'OPM::Repository::Source' ) } @{ $_[0] }
});

sub find {
    my ($self, %params) = @_;

    my @found;
    for my $source ( @{ $self->_objects || [] } ) {
        my $found = $source->find( %params );
        push @found, $found if $found;
    }

    return @found;
}

sub list {
    my ($self, %params) = @_;

    my %found_packages;
    my @detailed_list;
    for my $source ( @{ $self->_objects || [] } ) {
        my @found = $source->list( %params );
        @found_packages{@found} = (1) x @found;
        push @detailed_list, @found;
    }

    my @packages;
    if ( $params{details} ) {
        @packages = sort { $a->{name} cmp $b->{name} || $a->{version} cmp $b->{version} }@detailed_list;
    }
    else {
        @packages = sort keys %found_packages;
    }

    return @packages;
}

sub BUILDARGS {
    my ($class, @args) = @_;

    unshift @args, 'sources' if @args % 2;

    my %param = @args;

    for my $url ( @{ $param{sources} || [] } ) {
        push @{ $param{_objects} }, OPM::Repository::Source->new( url => $url );
    }

    return \%param;
}

sub _check_uri {
    my @allowed_schemes = ref $ALLOWED_SCHEME ? @{ $ALLOWED_SCHEME } : $ALLOWED_SCHEME;

    my $matches;

    SCHEME:
    for my $scheme ( @allowed_schemes ) {
        my $regex = ( lc $scheme eq 'http' ) ?
            $RE{URI}{HTTP}{-scheme => qr/https?/} :
            $RE{URI}{$scheme};

        if ( $_[0] =~ m{\A$regex\z} ) {
            $matches++;
            last SCHEME;
        }
    }

    die "No valid URI" unless $matches;
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Repository - parse OPM repositories' framework.xml files to search for add ons

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

  use OPM::Repository;
  
  my $repo = OPM::Repository->new(
      sources => [qw!
          https://opar.perl-services.de/framework.xml
          https://download.znuny.org/releases/packages/framework.xml
          https://download.znuny.org/releases/itsm/packages6/framework.xml
      !],
  );
  
  my ($url) = $repo->find(
    name      => 'ITSMCore',
    framework => '3.3',
  );
  
  print $url;

=begin Pod::Coverage




=end Pod::Coverage

=head2 BUILDARGS

=head1 ATTRIBUTES

=over 4

=item * sources

=back

=head1 METHODS

=head2 new

C<new> has only one mandatory parameter: I<sources>. This has to be 
an array reference of URLs for repositories' framework.xml files.

  my $repo = OPM::Repository->new(
      sources => [qw!
          http://opar.perl-services.de/framework.xml
          http://ftp.framework.org/pub/framework/packages/framework.xml
          http://ftp.framework.org/pub/framework/itsm/packages33/framework.xml
      !],
  );

=head2 find

Search for an add on for a given OPM version in those repositories. It
returns a list of urls if the add on was found, C<undef> otherwise.

  my @urls = $repo->find(
    name      => 'ITSMCore',
    framework => '3.3',
  );

Find a specific version

  my @urls = $repo->find(
    name      => 'ITSMCore',
    framework => '3.3',
    version   => '1.4.8',
  );

=head2 list

List all addons found in the repositories

  my @addons = $repo->list;
  say $_ for @addons;

You can also define the OPM version

  my @addons = $repo->list( framework => '5.0.x' );
  say $_ for @addons;

Both snippets print a simple list of addon names. If you want to
to create a list with more information, you can use

  my @addons = $repo->list(
      framework => '5.0.x',
      details   => 1,
  );
  say sprintf "%s (%s) on %s\n", $_->{name}, $_->{version}, $_->{url} for @addons;

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
