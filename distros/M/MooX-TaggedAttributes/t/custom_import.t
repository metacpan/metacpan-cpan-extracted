#!perl

use Test2::V0;
use Test::Lib;

{
    package R1;
    use Moo::Role;
    use MooX::TaggedAttributes -tags => 'as_hash';#, -no_install_import;

    # sub import {
    #     # don't shift, need this later
    #     my $class = $_[0];

    #     no strict 'refs';  ## no critic
    #     *${ \"${class}::TO_HASH" } = sub {
    #         my $self = shift;
    #         my %hash;
    #         my $attrs = $self->_tags->{as_hash};
    #         $hash{$_} = $self->$_ for keys %$attrs;
    #         \%hash;
    #     };

    #     # @_ is untouched; dispatch
    #     goto &$MooX::TaggedAttributes::_role_import;
    # }

    sub TO_HASH {
            my $self = shift;
            my %hash;
            my $attrs = $self->_tags->{as_hash};
            $hash{$_} = $self->$_ for keys %$attrs;
            \%hash;
    }

}

{
    package T1;
    use Moo;
    use R1;

    has foo => ( is => 'ro', as_hash => 1, default => 't1' );
}

{ package T2;
  use Moo;
  use R1;
  extends 'T1';
  has bar => ( is => 'ro', as_hash => 1, default => 't2' );
}

{ package T3;
  use Moo;
  extends 'T2';
  has zoo => ( is => 'ro', as_hash => 1, default => 'igloo' );
}

is ( T3->new->TO_HASH,
     hash {
         field bar => 't2';
         field foo => 't1';
         end;
     },
   );

done_testing;
