package Mojar::Google::Analytics::Request;
use Mojo::Base -base;

our $VERSION = 0.012;

use Carp 'croak';
use Mojo::Parameters;
use Mojo::Util 'url_escape';
use POSIX 'strftime';

# Attributes

has 'access_token';
has 'ids';
has dimensions => sub {[]};
has metrics => sub {[]};
has 'segment';
has filters => sub {[]};
has sort => sub {[]};
has start_date => &_today;
has end_date   => &_today;
has start_index => 1;
has max_results => 10_000;

# Public methods

sub params {
  my $self = shift;
  my $param = Mojar::Google::Analytics::Request->new(%$self, @_);
  my $p = Mojo::Parameters->new;

  # Absorb driver params, using defaults if necessary
  for (qw(start_date end_date start_index max_results)) {
    my $k = $_;
    my $v = $param->$k;
    delete $param->{$k};
    $k =~ s/_/-/;
    $p = $p->append($k => $v);
  }

  for my $k (qw(dimensions metrics)) {
    my $v = $param->$k;
    if (not ref $v or ref $v ne 'ARRAY') {
      croak "Field $k needs to be an arrayref";
    }
    elsif (@$v >= 2 and @$v % 2 == 0 and $v->[1] and $v->[1] !~ /[a-z]/) {
      # Assume hash (declaring datatypes)
      my $a = 'ga:'. $v->[2 * 0];
      $a .= ',ga:'. $v->[2 * $_] for 1 .. (@$v / 2 - 1);
      $p = $p->append($k => $a);
      delete $param->{$k};
    }
  }

  # Absorb everything else
  for my $k (keys %$param) {
    my $v = $param->$k;
    $k =~ s/_/-/;
    if (ref $v) {
      # Array ref
      $v = join ',', map "ga:$_", @$v;
    }
    else {
      # Scalar
      my $descending = 0;
      $k eq 'sort' and $v =~ s/^-// and $descending = 1;
      $v = ($descending ? '-ga:' : 'ga:') . $v if defined $v;
    }
    $p = $p->append($k => $v);
  }
  return $p->to_string;
}

# Private methods

sub _today { strftime '%F', localtime }

1;
__END__

=head1 NAME

Mojar::Google::Analytics::Request - Request object for GA reporting data.

=head1 SYNOPSIS

  use Mojar::Google::Analytics::Request;
  $req = Mojar::Google::Analytics::Request->new
    ->dimensions([qw( pagePath )])
    ->metrics([qw( visitors pageviews )])
    ->sort('pagePath')
    ->max_results($max_resultset);

=head1 DESCRIPTION

Provides a container object with convenience methods.

=head1 ATTRIBUTES

=over 4

=item access_token

Access token, obtained via JWT.

=item ids

Profile ID (from your GA account) you want to use.

=item dimensions

Arrayref to list of desired dimensions.

  $req->dimensions([qw(pagePath)]);

=item metrics

Arrayref to list of desired metrics.

  $req->metrics([qw(visitors newVisits visits bounces timeOnSite entrances
      pageviews uniquePageviews timeOnPage exits)]);

=item segment

String containing desired segment.

=item filters

Arrayref to list of desired filters.

  $req->filters(['browser==Firefox']);

=item sort

Specification of column sorting; either a single name (string) or a list
(arrayref).

=item start_date

Defaults to today.

=item end_date

Defaults to today.

=item start_index

Defaults to 1.

=item max_results

Defaults to 10,000.

=back

=head1 METHODS

=over 4

=item new

Constructor.

  $req = Mojar::Google::Analytics::Request->new(
    dimensions => [qw( pagePath )],
    metrics => [qw( visitors pageviews )],
    sort => 'pagePath',
    start_index => $start,
    max_results => $max_resultset
  );

=item params

String of request parameters.

  $url .= q{?}. $req->params;

=back

=head1 CONFIGURATION AND ENVIRONMENT

You need to create a low-privilege user within your GA account, granting them
access to an appropriate profile.  Then register your application for unattended
access.  That results in a username and private key that your application uses
for access.

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<Net::Google::Analytics> is similar, main differences being dependencies and
means of getting tokens.
