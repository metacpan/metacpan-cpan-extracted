package PDF::Collage::TemplatesCollection;
use v5.24;
use warnings;
{ our $VERSION = '0.001' }

use Carp;
use JSON::PP qw< decode_json >;
use PDF::Collage::Template ();

use Moo;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;

use namespace::clean;

has resolver   => (is => ro => required => 1 => coerce => \&__resolver);
has _selectors => (is => 'lazy');

sub _build__selectors ($self) {
   my $list = $self->_resolve(undef, 'list')
     or croak "cannot ask 'list' to resolver";
   my @selectors =
      map {  s{\A (?: \./)? definitions/ | \.json\z}{}rgmxs }
      grep { m{\A (?: \./)? definitions/.*\.json \z}mxs }
      $list->@*;
   return \@selectors;
} ## end sub _build__selectors

sub contains ($self, $sel) { defined($self->_selector_from($sel)) }

sub get ($self, $selector) {
   $selector = $self->_selector_from($selector)
      or croak 'invalid selector';

   my $json = $self->_resolve("definitions/$selector.json", 'data');
   my $definition = decode_json($json);

   $definition = { commands => $definition }
      unless ref($definition) eq 'HASH';

   my $resolver = $self->resolver;
   $definition->{functions} = {
      as_data => sub ($key) { $resolver->($key, 'data') },
      as_file => sub ($key, $keep_extension = 1) {
         my $old_name = $resolver->($key, 'file');
         return $old_name unless $keep_extension;

         # ensure the extension is there... should I rename the file?
         my $extension = $key =~ s{\A.*?\.}{.}rgmxs;
         my $elen = length($extension);
         return $old_name
            if length($old_name) >= $elen
            && substr($old_name, -$elen, $elen) eq $extension;

         # extension is not there, append it
         my $new_name = $old_name . $extension;
         rename $old_name, $new_name;
         return $new_name;
      },
   };

   return PDF::Collage::Template->new($definition);
}

sub render ($self, $selector = undef, $data = undef) {
   ($selector, $data) = ($data, $selector) if ref($selector);
   return $self->get($selector)->render($data);
}

sub _resolve ($self, $key, $type) { $self->resolver->($key, $type) }

# coercion function to get a Data::Resolver CDDE reference back
sub __resolver ($candidate) {
   return $candidate if ref($candidate) eq 'CODE';
   require Data::Resolver;
   return Data::Resolver::generate($candidate);
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
