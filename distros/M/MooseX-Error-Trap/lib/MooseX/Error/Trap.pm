package MooseX::Error::Trap;
BEGIN {
  $MooseX::Error::Trap::VERSION = '0.021';
}
use Moose;
use Moose::Exporter;
Moose::Exporter->setup_import_methods(
   with_caller => [qw{trap}],
);

# ABSTRACT: Create error traps for methods.


=head1 SYNOPSIS

Allows you to wrap any method in an eval and specify a dispatch method if the eval trips.

   package My::Test;
   use Moose;
   use MooseX::Error::Trap;

   trap 'some_method', 'what_to_do';
   sub some_method {
      ...
   }

   sub what_to_do {
      my ($self, $error) = @_;
      ...
   }

=head1 Exported Keyword

=head2 trap

   trap 'wrapped_method', 'trap';

Will wrap any calls to 'wrapped_method' in an eval, and if that eval fails then 'trap' 
is run. 

Currently 'trap' can be either a string or a CodeRef. The case for a code ref is simple
if triped execute the code ref, passing $self and $@. When 'trap' is a string things are
a bit more complicated. If 'trap' is the name of an attribute of $self we check to see 
what the type constraint is on that attr, if it's 'CodeRef' then we grab the value and 
proceede like a CodeRef. For any other type constraint we return the value of that attr.
Lastly if 'trap' is the name of a method ($self->can($trap)) then we execute it passing 
$@ as the only param. 

In any other case we just die with $@ as though the eval was not there. 

=cut

sub trap {
   my $caller = shift;
   my $wrap   = shift;
   my $trap   = shift;

   #---------------------------------------------------------------------------
   #  check input
   #---------------------------------------------------------------------------
   confess q{No method specified} unless defined $wrap;
   confess q{No trap specified}   unless defined $trap;
   if ( ref($trap) eq '' ) {
      confess sprintf(q{%s can not %s}, $caller, $trap) unless $caller->can($trap);
   }

   #---------------------------------------------------------------------------
   #  build our trap
   #---------------------------------------------------------------------------
   #my $meta = Class::MOP::Class->initialize($caller);
   my $meta = Moose::Meta::Class->initialize($caller);
   my $attr = $meta->get_attribute($trap);

   $meta->add_around_method_modifier(
            $wrap,
            sub{  my $next = shift;
                  my $self = shift;

                  my $rv;
                  eval { $rv = $self->$next(@_) }
                  or do{ 
                     # If $trap is the name of an attr, and that attr is a CodeRef, grab it
                     if( my $attr = $meta->get_attribute($trap) ) {
                        if ($attr->type_constraint->equals('CodeRef') ) {
                           $trap = $self->$trap; # grab that code ref and store it to $trap
                        }
                        else {
                           return $self->$trap; # non-code attr, just pull the value and use that
                        }
                     }
                     $rv = ref($trap) eq ''     ? $self->$trap($@) 
                         : ref($trap) eq 'CODE' ? $trap->($self,$@)
                         : die $@ ; # sane fall back
                  };
                  return $rv;
            },
   );
}
   
=head1 TODO

=over 4

=item * A way to modify the relationship between the method run and the deferment method at runtime.

=back 

=head1 AUTHOR

NOTBENH, C<< <NOTBENH at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-error-trap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Error-Trap>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Error::Trap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Error-Trap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Error-Trap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Error-Trap>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Error-Trap/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks again to team Moose.

=head1 COPYRIGHT & LICENSE

Copyright 2009 NOTBENH, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

no MooseX::Error::Trap;
1; # End of MooseX::Error::Trap
