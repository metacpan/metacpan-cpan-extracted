package Net::Google::Calendar::Base;
{
  $Net::Google::Calendar::Base::VERSION = '1.05';
}

use strict;
use XML::Atom::Thing;
use XML::Atom::Util qw( set_ns first nodelist childlist iso2dt);

=head1 NAME

Net::Google::Calendar::Base - utility functions for Net::Google::Calendar objects

=cut


sub _initialize {
    my $self    = shift;
    my $ns      = XML::Atom::Namespace->new(gd => 'http://schemas.google.com/g/2005');
    $self->{_gd_ns} = $ns;
}



# work round get in XML::Atom::Thing which stringifies stuff
sub _my_get {
    my $obj = shift;
    my($ns, $name) = @_;
    my @list = $obj->_my_getlist($ns, $name);
    return $list[0];
}

sub _my_getlist {
    my $obj = shift;
    my($ns, $name) = @_;
    my $ns_uri = ref($ns) eq 'XML::Atom::Namespace' ? $ns->{uri} : $ns;
    my @node = childlist($obj->elem, $ns_uri, $name);
    return @node;
}

sub _generic_url {
    my $self = shift;
    my $name = shift;
    my $uri;
    for ($self->link) {
        next unless $name eq $_->rel;
        $uri = $_;
        last;
    }
    return undef unless defined $uri;
    return $uri->href;
}

1;
