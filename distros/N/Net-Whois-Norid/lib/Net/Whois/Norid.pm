package Net::Whois::Norid;

use Net::Whois::Raw;
use strict;

our $VERSION='0.04';
use vars qw/$AUTOLOAD/;

sub AUTOLOAD {
    my $self=shift;
    $AUTOLOAD =~ s/.*:://;
    return $self->get($AUTOLOAD);
}

sub new {
  my ($proto,$lookup)=@_;
  my $class=ref $proto||$proto;
  my $self=bless {},$class;
  return $self unless $lookup;
  $self->lookup($lookup);
  return $self;
}

sub get {
    my ($self,$key) = @_;
    $key=lc($key);
    if (exists $self->{"${key}_handle"} ) {
        my @objs=(map { $self->new($_) }
                split (m/\n/,$self->{"${key}_handle"}));
        return ( wantarray ? @objs : $objs[0] );
    }
    return $self->{$key};
}

sub lookup {
  my ($self,$lookup) = @_;
  return $self->_parse(whois($lookup,'whois.norid.no'));
}

sub _parse {
    my ($self,$whois)=@_;
    foreach my $line (split("\n",$whois)) {
        if (my ($key,$value) = $line =~ m/^(\w+[^.]+)\.{2,}\:\s*(.+)$/) {
            # replace spaces and - with _ for accessors.
            $key =~ y/ -/_/;
            $key = lc($key);
            $self->{$key} = 
                ($self->{$key} ? $self->{$key}."\n$value" : $value);
      }
  }
}

=head1 NAME

Net::Whois::Norid - Lookup WHOIS data from norid.

=head1 SYNOPSIS

  my $whois = Net::Whois::Norid->new('thefeed.no');
  print $whois->post_address;
  print $whois->organization->fax_number;

=head1 DESCRIPTION

This module provides an object oriented API for use with the
Norid whois service. It uses L<Net::Whois::Raw> internally to
fetch information from Norid.

=head2 METHODS

=over 4

=item new

The constructor. Takes a lookup argument. Returns a new object.

=item lookup 

Do a whois lookup in the Norid database and populate the object
from the result.

=item get

Use this to access any data parsed. Note that spaces and '-'s will be 
converted to underscores (_). For the special "Handle" entries,
omitting the _Handle part will return a new L<Net::Whois::Norid>
object. The method is a case insensitive.

=item AUTOLOAD

This module uses the autoload mechanism to provide accessors for any
available data through the get mechanism above.


=back

=head1 SEE ALSO

L<Net::Whois::Raw>
L<http://www.norid.no>

=head1 CAVEATS

Some rows in the whois data might appear more than once. in that
case they are separated with line space. For objects, an array
is returned.

=head1 AUTHOR

Marcus Ramberg C<mramberg@cpan.org>

=head1 LICENSE 

This module is distributed under the same terms as Perl itself.

1;
