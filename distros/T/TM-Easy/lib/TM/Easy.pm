package TM::Easy;

use strict;
use warnings;

our $VERSION  = '0.03';

use TM::Easy::Map;
use TM::Easy::Topic;
use TM::Easy::Association;

use TM::Tied::Map;
use TM::Tied::Topic;
use TM::Tied::Association;

=pod

=head1 NAME

TM::Easy - Topic Maps, Easy Usage

=head1 SYNOPSIS

  use TM::Easy;

  # for the couch potatoes
  my $mm = new TM::Easy (file => 'somewhere.atm');
  # or, alternatively
  my $mm = new TM::Easy (inline => ' # here is AsTMa');
  # or, alternatively from LTM
  my $mm = new TM::Easy (file => 'somewhereelse.ltm');

  # more flexibility when doing it in several steps:
  # acquire a map from somewhere, any map should do (see TM)
  use TM;
  my $tm = new TM;

  # create an Easy Access (I'm sure some stupid company has a trademark on this)
  my $mm = new TM::Easy::Map ($tm);

  # walking, walking, ...
  foreach my $tid (keys %$mm) {        # iterate over all toplet identifiers
     ...
  }

  warn "oh no" unless $mm->{hubert};   # check whether a topic exists with this local identifier
  my $hubert = $mm->{hubert};          # using the local identifier

  print $hubert->{'!'};                # the local identifier, TMQL notation
  my $add = $hubert->{'='};            # the subject address, TMQL notation
  my @sin = $hubert->{'~'};            # the subject identifiers (as list reference, TMQL notation)

  print $hubert->{name_s}              # get a list of names
  print $hubert->{name}                # get _some_ name (or undef if there is none)
  print $hubert->{occurrence_s}        # get a list of all occurrences
  print $hubert->{occurrence}          # get a scalar with _some_ occurrence
  print $hubert->{blog_s}              # list of all blog characteristics
  print $hubert->{blog}                # get occurrence (or name) with this type, one value

  my $a = $hubert->{-owner};           # get association where hubert is owner
  my $a = $hubert->{'<- owner'};       # same, but with TMQL notation

  foreach my $role (keys %$a) {        # iterate over all roles
     warn $a->{$role}                  # output ONE player (does not work if there are several!)
     warn $a->{"-> $role"}             # same with TMQL notation

     warn $a->{"${role}_s"};           # get list of all role players
     warn $a->{"-> ${role}_s"};        # same, with TMQL notation
  }

  foreach (@{ $hubert->{'<-> likes'} }) {  # iterate over all on the other side(s)
     ...
  }


=head1 ABSTRACT

This package provides a HASH-like access to a topic map. For this purpose, first a given topic map
object will be tied to a hash and then the user can access certain aspects of a topic map via
keys. The same holds true for topics and associations.

=head1 DESCRIPTION

This abstraction layer provides a rather simplified view on topic map content. It pretends that a
topic map is a hash, a topic is a hash and an association is an hash. In that, this package offers
access to topics in maps, names and occurrences in topics and roles and players in associations via
keys.

Unsurprisingly, this package does not harness all the beauty (or ugliness) of L<TM>.

B<NOTE>: At the moment, we support only reading. That may change in the future.

=head2 Maps as Hashes 

=over

=item keys: get all local toplet identifiers

keys I<%$map>

=item fetch

=over

=item get the toplet with this toplet identifier

I<$map>->{xxx}

=item get the toplet with this subject identifier

I<$map>->{'http://... ~'}

=item same

I<$map>->{'http://...'}

=item get the toplet with this subject address

I<$map>->{'http://... ='}

=back

=item exists: check whether the toplet exists

exists I<$map>->{xxx}

exists I<$map>->{'http://... ~'}

exists I<$map>->{'http://... ='}

=back

=head2 Topics as Hashes

=over

=item identification

I<$t>->{'!'}             # get local identifier

I<$t>->{'='}             # get subject address (or undef)

I<$t>->{'~'}             # get subject identifiers (as list reference)

=item characteristics

I<$t>->{name}            # get ONE name

I<$t>->{name_s}          # get ALL names (as list reference)

I<$t>->{nickname}        # get ONE name of this type

I<$t>->{nickname_s}      # get ALL names of this type (as list reference)

I<$t>->{homepage}        # get ONE occurrence of this type

I<$t>->{homepage_s}      # get ALL occurrences of this type (as list reference)

=item role playing

I<$t>->{'<- in_role'}    # get ONE association where toplet plays C<in_role>

I<$t>->{-in_role}        # same, shorter

I<$t>->{'<- in_role_s'}  # get ALL associations where toplet plays C<in_role>

I<$t>->{-in_role_s}      # same, shorter

=back

=head2 Associations as Hashes

=over

=item keys

keys I<%$a>               # all roles (role types)

=item fetch

I<%$a>->{out_role}        # get ONE toplet playing C<out_role>

I<%$a>->{'-> out_role'}   # same longer

I<%$a>->{out_role_s}      # get ALL toplets playing C<out_role>

I<%$a>->{'-> out_role_s'} # same longer

=back


=head2 TODOs?

$someone->{'<- husband -> wife'};


=head1 INTERFACE

=head2 Constructor

The constructor accepts an optional hash specifying the source of the map:

=over

=item C<inline>:

The string value specifies directly a map denoted in AsTMa.

=item C<file>:

The string denotes a file from where the map is consumed. If the
filename ends with C<.atm>, then an AsTMa file is assumed. If it ends
with C<.ltm>, then it will be parsed as LTM file. Otherwise the
machinery falls back to AsTMa.

=back

TODO: support XTM x.x

=cut

sub new {
    my $class = shift;
    my %provenance = @_;

    my $tm;
    if ($provenance{inline}) {
	use TM::Materialized::AsTMa;
	$tm = new TM::Materialized::AsTMa (inline => $provenance{inline})->sync_in;
    } elsif ($provenance{file}) {
	if ($provenance{file} =~ /\.atm$/i) {                                             # we assume AsTMa
	    use TM::Materialized::AsTMa;
	    $tm = new TM::Materialized::AsTMa (file => $provenance{file})->sync_in;
	} elsif ($provenance{file} =~ /\.ltm$/i) {                                        # most likely LTM
	    use TM::Materialized::LTM;
	    $tm = new TM::Materialized::LTM (file => $provenance{file})->sync_in;
	} elsif ($provenance{file} =~ /\.ctm$/i) {                                        # most likely CTM
	    use TM::Materialized::CTM;
	    $tm = new TM::Materialized::CTM (file => $provenance{file})->sync_in;
	} elsif ($provenance{file} =~ /\.xtm$/i) {                                        # most likely XTM
	    use TM::Materialized::XTM;
	    $tm = new TM::Materialized::XTM (file => $provenance{file})->sync_in;
	} else {                                                                          # assume it is astma
	    use TM::Materialized::AsTMa;
	    $tm = new TM::Materialized::AsTMa (file => $provenance{file})->sync_in;
	}
    } elsif (keys %provenance) {
	die "do not understand how to source the map";
    } else {                                                                              # keep it empty
	use TM;
	$tm = new TM;
    }
    my $mm = new TM::Easy::Map ($tm);
    return $mm;
}

=pod

=head2 Methods

=over

=item C<map>

This read-only method gives you access to the underlying L<TM> object.

=cut

# parked in TM::Easy::Map

=pod

=back

=head1 SEE ALSO

L<TM>

=head1 CREDITS

All this was strongly inspired by the Mappa project (Lars Heuer).

=head1 COPYRIGHT AND LICENSE

Copyright 200[8] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

Work under a Research Grant by the Austrian Research Centers Seibersdorf.

=cut

our $REVISION = '$Id$';

1;
