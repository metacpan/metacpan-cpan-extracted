package MooseX::Role::Debugger;
use MooseX::Role::Parameterized;
use Log::Dispatch;
use Data::Dumper;

our $VERSION = '1.00';


parameter debug => ( 
   required => 1,
   default => 1
);

parameter logger => (
   default => sub { 
      Log::Dispatch->new( outputs => [
         [ 'Screen', min_level => 'debug', newline => 1 ],
         [ 'File', min_level => 'debug', newline => 1, filename => 'debug.log' ]
         ])
   }
);

parameter skip_methods => ( 
   default => sub { 
      my @list = Moose::Object->meta->get_all_method_names;
      push @list, 'can';
      return \@list;
   }
);

parameter skip_attrs => ( 
   required => 1,
   default => 1
);

role { 
   my $p = shift;
   my %args = @_;
   my $consumer = $args{consumer};

   method BUILD => sub  {};

   around 'BUILD' => sub { 
      my $self = shift;
      if( $p->debug ) { 
         $p->{logger}->debug('Debug is on.');
         my @method_list = $consumer->get_method_list();
         my %skipped = map { $_ => 1 } @{$p->skip_methods};
         $consumer->make_mutable;
         if( $p->skip_attrs ) { 
            # Since we've a Moose class, attributes are tricky.  
            # First, we find all the methods attributes have as
            # readers/writors..
            my @attributes = $consumer->get_all_attributes;
            my %method_hash = map { $_ => 1 } @method_list;
            foreach my $attr ( @attributes ) { 
               my( $reader, $writer ) = ( $attr->get_read_method, $attr->get_write_method );
               $reader && $skipped{$reader}++;
               $writer && $skipped{$writer}++;
            }
         }
         foreach my $method ( @method_list ) {

            # Skip over some generally bad-to-debug methods..
            if( $skipped{$method} ) { 
               $p->{logger}->debug("Skipping method $method");
               next;
            }
            $p->{logger}->debug('Adding debugger for method ' . $method );
            $consumer->add_around_method_modifier($method, sub { 
               my $orig = shift;
               my $class = shift;
               $p->{logger}->debug( $method  . ' called with parameters: ' . Dumper(\@_) );
               my @results = $class->$orig(@_);
               $p->{logger}->debug( $method . ' returned: ' . Dumper(\@results) );
               return wantarray ? @results : "@results";
            });
         }
         $consumer->make_immutable;
      }
   };
   
};

1;

=head1 NAME

MooseX::Role::Debugger - Automatically add debugging output with a role

=head1 SYNOPSIS

 package SomeMooseClass;
 use Moose;
 with 'MooseX::Role::Debugger';

 sub foo { ... }

 __PACKAGE__->meta->make_immutable;

..and later..

 $some_moose_class->foo();   
 
..you get some output..

  foo called with parameters: $VAR1 = [
     ... 
  ]
  (whatever foo may have done)
  foo returned: $VAR1 = [ 
     ... 
  ]

=head1 DESCRIPTION

This role is intended to add to any Moose class.  It will do a bit of introspection
on the consuming class and wrap each one in an C<around> modifier and add some debugging
output before and after.  

By default, logging is done via a Log::Dispatch object (generated in the role), with both 
the 'Screen' and 'File' outputs (the 'File' output uses a filename C<debug.log>).  

=head2 USAGE

MooseX::Role::Debugger makes use of parameterized roles, so you may pass some extra
information to your role in the C<with> statement.  The syntax is fairly straightforward:

 with 'MooseX::Role::Debugger' => { debug => 1, logger => $log_obj };

Though the defaults are fairly sensible.  If you feel the need to contradict me and 
supply your own options, they are:

=over 3

=item debug

A boolean indicating if you want to see debug output or not.  If this is what Perl considers
a true value, you get all sorts of extra stuff.  If it is false, there is no extra overhead.

=item logger

This is generated in the role by default, and is a L<Log::Dispatch> object.  If you'd like 
to provide different options for your logging, do it here.  All debugging is done by calling
the C<debug> method on this object.  Make sure anything you replace this with can C<debug()>
things.

=item skip_methods

This is an array reference containing the names of any methods you'd like to skip when adding
debugging.  The list is obtained by querying the method names from C<<Moose::Object->meta>>. 
At the time, this is:

 dump
 BUILDALL
 DESTROY
 DEMOLISHALL
 meta
 BUILDARGS
 does
 new
 DOES
 can

If you provide an alternate list, please be aware that you should also include these items.  
Were I you, I wouldn't worry about changing it at all.

=item skip_attrs

Attributes are skipped over automatically.  Attributes that have explicit (and differently-named)
accessors or mutators (via the C<reader> or C<writer> bits) are handled properly.  Set this
to something false to turn this behaviour off.

=back

=head1 AUTHOR

Dave Houston <L<dhouston@cpan.org>>

=head1 SPONSORED BY

Ionzero, LLC L<http://ionzero.com/>

=head1 SEE ALSO

L<Log::Dispatch>, L<Moose>, L<MooseX::Role::Parameterized>

=head1 BUGS

Probably

=head1 LICENSE

Copyright (C) 2011, Dave Houston <L<dhouston@cpan.org>>

This library is free software; you can redistribute and/or modify it under the same
terms as Perl itself.

=cut

__END__
