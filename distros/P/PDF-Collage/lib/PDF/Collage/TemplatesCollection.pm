package PDF::Collage::TemplatesCollection;
use v5.24;
use warnings;
{ our $VERSION = '0.003' }

use Carp;
use JSON::PP qw< decode_json >;
use Scalar::Util qw< blessed >;
use PDF::Collage::Template ();

use Moo;
use experimental qw< signatures >;

use namespace::clean;

has resolver   => (is => ro => required => 1 => coerce => \&__resolver);
has _selectors => (is => 'lazy');

sub _build__selectors ($self) {
   my @selectors =
      map  { s{\.json}{}rmxs }
      grep { m{\.json \z}mxs }
      $self->resolver->get_sub_resolver('definitions')->list_asset_keys;
   return \@selectors;
} ## end sub _build__selectors

sub contains ($self, $sel) { defined($self->_selector_from($sel)) }

sub get ($self, $selector) {
   $selector = $self->_selector_from($selector)
      or croak 'invalid selector';

   my $resolver = $self->resolver;

#   my $def = $resolver->get_sub_resolver('definitions')
#      ->get_asset("$selector.json")->parsed_as_json;
   my $def = $resolver->get_asset("./definitions/$selector.json")->parsed_as_json;

   $def = { commands => $def } unless ref($def) eq 'HASH';

   $def->{functions} = {
      as_data => sub ($key) { $resolver->get_asset($key)->raw_data },
      as_file => sub ($key) { $resolver->get_asset($key)->file     },
   };

   return PDF::Collage::Template->new($def);
}

sub render ($self, $selector = undef, $data = undef) {
   ($selector, $data) = ($data, $selector) if ref($selector);
   return $self->get($selector)->render($data);
}

# coercion function to get a Data::Resolver CDDE reference back
sub __resolver ($candidate) {
   return $candidate if blessed($candidate);
   my $class = $candidate->{class};
   my $path = "$class.pm" =~ s{::}{/}rgmxs;
   require $path;
   return $class->new($candidate->%*);
}

sub _selector_from ($self, $selector) {
   my $sels = $self->_selectors;
   $selector //= $sels->[0] if $sels->@* == 1;
   return undef unless defined $selector;
   my @candidates = grep { $selector eq $_ } $sels->@*;
   return @candidates ? $candidates[0] : undef;
}

sub selectors ($self) { $self->_selectors->@* }

1;
