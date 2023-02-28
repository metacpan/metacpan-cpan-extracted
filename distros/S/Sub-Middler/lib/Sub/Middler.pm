package Sub::Middler;
use 5.024000;
use strict;
use warnings;
use feature "refaliasing";


our $VERSION = 'v0.1.0';

sub new {
	#simply an array...	
	bless [], __PACKAGE__;
}

# register sub refs to middleware makers
sub register {
  no warnings "experimental";
	\my @middleware=$_[0];	#self
	my $sub=$_[1];
	push @middleware, $sub;
	return $_[0]; #allow chaining
}


# Link together sub and give each one an index 
# Required argument is the 'dispatcher' which is the end point to call
# 
sub link {
  no warnings "experimental";

  die "A CODE reference is requred when linking middleware" unless(@_ >=2 and ref $_[1] eq "CODE");
  
	\my @middleware=$_[0];	#self;

	my $dispatcher=$_[1];

	my @mw;  # The generated subs

	for my $i (reverse 0..@middleware-1){
		my $maker=$middleware[$i];
		my $next=($i==@middleware-1)?$dispatcher:$mw[$i+1];	
		

		$mw[$i]=$maker->($next, $i);
	}

	@middleware?$mw[0]:$dispatcher;
}


1;

=head1 NAME

Sub::Middler - Middleware subroutine chaining

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Sub::Middler;

  my $middler=Sub::Middler->new;

  $middler->register(mw1(x=>1));
  $middler->register(mw2(y=>10));

  my $head=$middler->link(
    sub {
      print "Result: $_[0]\n";
    }
  );

  $head->(0); # Call the Chain

  # Middleware 1
  sub mw1 {
    my %options=@_;
    sub {
      my ($next,$index)=@_;
      sub {
        my $work=$_[0]+$options{x};
        $next->($work);
      }
    }
  }

  # Middleware 2
  sub mw2 {
    my %options=@_;
    sub {
      my ($next, $index)=@_;
      sub {
        my $work= $_[0]*$options{y};
        $next->( $work);
      }
    }
  }

=head1 DESCRIPTION

A small module, facilitating linking together subroutines, acting as middleware
or filters into chains with low runtime overhead.

To achieve this, the  'complexity' is offloaded to the definition of
middleware/filters subroutines. They must be wrapped in subroutines
appropriately to facilitate the lexical binding of linking variables.

This differs from other 'sub chaining' modules as it does not use a loop
internally to iterate over a list of subroutines at runtime. As such there is
no implicit call to the next item in the chain. Each stage can run
synchronously or asynchronously or even not at all. Each element in the chain
is responsible for calling the next.

Finally the arguments and signatures at each stage of middleware are completely
user defined and are not interfered with by this module. This allows reuse of
the C<@_> array in calling subsequent stages for ultimate performance if you
know what you're doing.


=head1 API

=head2 Managing a chain

=head3 new
  
    my $object=Sub::Middler->new;

Creates a empty middler object ready to accept middleware. The object is a
blessed array reference which stores the middleware directly.

=head3 register

    $object->register(my_middlware());

Appends the middleware to the internal list for later linking.

=head3 link

    $object->link($last);

Links together the registered middleware. Each middleware is intrinsically
linked to the next middleware in the list. The last middleware being linked to
the C<$last> argument, which must be a code ref. 

The C<$last> ref MUST be  a regular subroutine reference, not middleware as it
is defined below.

Calls C<die> if C<$last> is not a code ref.

=head2 Creating Middleware

To achieve low over head in linking middleware, functional programming
techniques (higher order functions) are utilised. This also give the greatest
flexibility to the middleware, as signatures are completely user defined.

The trade off is that the middleware must be defined in a certain code
structure. While this isn't difficult, it takes a minute to wrap your head
around.


=head3 Middlware Definition

Middleware must be a subroutine (top/name) which returns a anonymous subroutine
(maker), which also returns a anonymous subroutine to perform work (kernel).

This sounds complicated by this is what is looks like in code:

  sub my_middleware {                 (1) Top/name subroutine
    my %options=@_;                       Store any config
   
    sub {                             (2) maker sub is returned
      my ($next, $index)=@_;          (3) Must store these vars

      sub {                           (4) Returns the kernel sub
        # Code here implements your middleware
        # %options are lexically accessable here
        

        # Execute the next item in the chain
        $next->(...);                 (5) Does work and calls the next entry


                                      (6) Post work if applicable 
      }
    }
  }

=over

=item Top Subroutine

The top sub routine (1) can take any arguments you desire and can be called
what you like. The idea is it represents your middleware/filter and stores any
setup lexically for the B<maker> sub to close over. It returns the B<maker>
sub.

=item Maker Subroutine

This anonymous sub (2) closes over the variables stored in B<Top> and is the
input to this module (via C<register>). When being linked (called) by this
module it is provided two arguments; the reference to the next item in
the chain and the current middleware index. These B<MUST> be stored to be
useful, but can be called anything you like (3).


=item Kernel subroutine

This anonymous subroutine (4) actually performs the work of the
middleware/filter. After work is done, the next item in the chain must be
called explicitly (5).  This supports synchronous or asynchronous middleware.
Any extra work can be performed after the chain is completed after this call
(6).

=back


=head2 LINKING CHAINS

Multiple chains of middleware can be linked together. This needs to be done in
reverse order. The last segment becomes the C<$last> item when linking the
preceding chain and so on.


=head2 EXAMPLES

The synopsis example can be found in the examples directory of this
distribution.


=head1 SEE ALSO

L<Sub::Chain>  and L<Sub::Pipeline> links together subs. They provide other
features that this module does not. 

These iterate over a list of subroutines at runtime to achieve named subs etc.
where as this module pre links subroutines together, reducing overhead.


=head1 AUTHOR

Ruben Westerberg, E<lt>drclaw@mac.comE<gt>

=head1 REPOSITORTY and BUGS

Please report any bugs via git hub: L<http://github.com/drclaw1394/perl-sub-middler>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl or the MIT
license.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.
=cut

