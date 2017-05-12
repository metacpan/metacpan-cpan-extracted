package MooseX::MutatorAttributes;
use Moose::Role;
use Carp;
use Carp::Assert::More;


=head1 NAME

MooseX::MutatorAttributes - Moose Role to add a quick set method that returns self

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

I got tired of doing this:

    $obj->attr1($value1);
    $obj->attr2($value2);
    $obj->method_that_uses_attr;

What I wanted to do was:

    with qw{MooseX::MutatorAttributes};
    $obj->set( attr1 => $value1, attr2 => $value2 )->method_that_uses_attr;


Now I can, and so can you.

=head1 METHOD

=head2 set

    $self->set( HASH );

Set takes a hash, keys are expected to be attributes, if they are not then we Carp::croak. If a key is an acceptable 
attribute then we attempt to set with $value.

=cut

sub set {
   my ($self, %opts) = @_;
   while ( my ($name, $value) = each %opts ) {
      croak sprintf q{[!!!] %s is not an attribute to set for %s}, $name, $self
         unless defined $self->meta->find_attribute_by_name($name);
      
      my $setter = $self->meta->find_attribute_by_name($name)->get_write_method;
      croak sprintf q{[!!!] %s is not writable, no setter defined}, $name
         unless defined $setter;

      $self->$setter($value);
   }
   return $self;
}

=head2 set_only_rw_attr

    my $storage_href = {};
    $self->set_only_rw_attr($storage_href, HASH );

Set takes a hash, keys are expected to be attributes, but unlike set, we don't
die. Instead we populate a given storage ref that was passed in. It's up to
what to do with it. Post 'set' your $storage_href will hold all the 
non-writeable-attrs (either was not an attr or was 'ro').

If you wish to by-pass the storage part pass in an annon hashref {}. 

=cut

sub set_only_rw_attr {
   my ($self, $store, %opts) = @_;
   assert_hashref($store);
   
   while ( my ($name, $value) = each %opts ) {
      my $setter = $self->meta->find_attribute_by_name($name)->get_write_method
         if defined $self->meta->find_attribute_by_name($name) ; 

      if ( defined $setter ) {
         $self->$setter($value);
      } 
      else {
         $store->{$name} = $value;
      }
   }
   return $self;
}






=head1 AUTHOR

ben hengst, C<< <notbenh at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-setter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-MutatorAttributes>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::MutatorAttributes


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-MutatorAttributes>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-MutatorAttributes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-MutatorAttributes>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-MutatorAttributes>

=back


=head1 ACKNOWLEDGEMENTS

This would not be possible with out stevan, mst, and everyone else who hangs out on #moose. 

=head1 COPYRIGHT & LICENSE

Copyright 2008 ben hengst, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MooseX::MutatorAttributes
