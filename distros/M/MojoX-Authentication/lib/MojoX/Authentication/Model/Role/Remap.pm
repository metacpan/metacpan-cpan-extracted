package MojoX::Authentication::Model::Role::Remap;
{ our $VERSION = '0.100' }

use v5.24;
use Moo::Role;
use Ouch qw< :trytiny_var >;
use experimental qw< signatures >;
use namespace::clean;

sub _remove_protected_keys ($self, $record) {
   return [] unless $self->can('protected_keys_list');
   return [
      map {
         my $has_key = exists($record->{$_});
         [ $_, $has_key, delete($record->{$_}) ];
      } $self->protected_keys_list
   ];
}

sub _restore_protected_keys ($self, $record, $list) {
   for my $item (reverse($list->@*)) {
      my ($key, $restore, $value) = $item->@*;
      delete($record->{$key});
      $record->{$key} = $value if $restore;
   }
   return;
}

sub remap ($self, $record, $mappings, $backwards = 0) {
   my $to_restore = $self->_remove_protected_keys($record);
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
   $self->_restore_protected_keys($record, $to_restore);
   return $record;
}


1;
__END__


