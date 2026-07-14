package MojoX::Authentication::Model::Role::Remap;
{ our $VERSION = '0.003' }

use v5.24;
use Moo::Role;
use Ouch qw< :trytiny_var >;
use experimental qw< signatures >;
use namespace::clean;

sub remap ($self, $record, $mappings, $backwards = 0) {
   for my $remap ($backwards ? reverse($mappings->@*) : $mappings->@*) {
      if (ref($remap) eq 'CODE') {
         $remap->($record, $backwards);
      }
      elsif (ref($remap) eq 'ARRAY') { # simple okey = ikey remaps
         my @pairs = $remap->@*;
         ouch 400, 'odd number of elements in array remap' if @pairs % 2;
         @pairs = reverse(@pairs) if $backwards;
         while (@pairs) {
            my ($okey, $ikey) = splice(@pairs, 0, 2);
            next unless exists($record->{$ikey});
            $record->{$okey} = $record->{$ikey};
         }
      }
      elsif (ref($remap) eq 'HASH') { # more complex stuff
         my ($okey, $ikey, $op, $args) =
            $backwards ? $remap->@{qw< ikey okey backwards_op >}
                       : $remap->@{qw< okey ikey           op >};
         next unless exists($record->{$ikey});
         $record->{$okey} = $op ? $op->($record->{$ikey}, $args->@*)
            : $record->{$ikey};
      }
      else {
         ouch 400, 'unsupported remapping', $remap;
      }
   }
   return $record;
}


1;
__END__


