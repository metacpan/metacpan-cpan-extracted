#line 1
package Modern::Perl;
{
  $Modern::Perl::VERSION = '1.20121103';
}
# ABSTRACT: enable all of the features of Modern Perl with one import

use 5.010_000;

use strict;
use warnings;

use mro     ();
use feature ();

# enable methods on filehandles; unnecessary when 5.14 autoloads them
use IO::File   ();
use IO::Handle ();

our $VERSION;

my $wanted_date;
sub VERSION
{
    my ($self, $version) = @_;

    return $VERSION unless defined $version;
    return $VERSION if             $version < 2009;

    $wanted_date = $version if (caller(1))[3] =~ /::BEGIN/;
    return 2012;
}

sub import
{
    my ($class, $date) = @_;
    $date = $wanted_date unless defined $date;

    my $feature_tag    = validate_date( $date );
    undef $wanted_date;

    warnings->import();
    strict->import();
    feature->import( $feature_tag );
    mro::set_mro( scalar caller(), 'c3' );
}

sub unimport
{
    warnings->unimport;
    strict->unimport;
    feature->unimport;
}

my %dates =
(
    2009 => ':5.10',
    2010 => ':5.10',
    2011 => ':5.12',
    2012 => ':5.14',
    2013 => ':5.16',
);

sub validate_date
{
    my $date = shift;

    # always enable unicode_strings when available
    unless ($date)
    {
        return ':5.12' if $] > 5.011003;
        return ':5.10';
    }

    my $year = substr $date, 0, 4;
    return $dates{$year} if exists $dates{$year};

    die "Unknown date '$date' requested\n";
}


1;

__END__

#line 219
