# ABSTRACT: Make MooseX::Event methods available as class methods on a singleton
package MooseX::Event::Role::ClassMethods;
{
  $MooseX::Event::Role::ClassMethods::VERSION = 'v0.2.0';
}
use strict;
use warnings;
use Any::Moose 'Role';

requires 'instance';

around [qw( event_exists on once emit remove_all_listeners remove_listener )] => sub {
    my $orig = shift;
    if ( ! ref $_[0] ) {
        my $class = shift;
        unshift @_, $class->instance;
    }
    goto $orig;
};

no Any::Moose 'Role';

1;


__END__
=pod

=head1 NAME

MooseX::Event::Role::ClassMethods - Make MooseX::Event methods available as class methods on a singleton

=head1 VERSION

version v0.2.0

=head1 SYNOPSIS

  package Example {
      use MooseX::Singleton;
      use MooseX::Event;
      
      with 'MooseX::Event::Role::ClassMethods';
      
      has_event 'pinged';
      
      sub ping {
          my $self = shift;
          $self->emit('pinged');
      }
  }
  
  Example->on( pinged => sub { say "Got a ping!" } );
  Example->on( pinged => sub { say "Got another ping!" } );
  Example->ping; # prints "Got a ping!" and "Got another ping!"
  Example->remove_all_listeners( "pinged" ); # Remove all of the pinged listeners
  Example->once( pinged => sub { say "First ping." } );
  Example->ping; Example->ping; # Only prints "First ping." once
  my $listener = Example->on( pinged => sub { say "Ping" } );
  Example->remove_listener( pinged => $listener );
  Example->ping(); # Does nothing

=head1 DESCRIPTION

Sometimes it's handy to be able to call object methods directly on a
singleton class, without having to call instance yourself.  This wraps up
the MooseX::Event Role to allow this.  Your class must provide an instance
method that returns the singleton object.  One way to do this is with the
MooseX::Singleton class, as in the example, but you can easily role your own
if you prefer.

=for test_synopsis use 5.10.0;

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::Event|MooseX::Event>

=item *

L<MooseX::Event::Role|MooseX::Event::Role>

=back

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

