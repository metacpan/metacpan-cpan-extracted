# ABSTRACT: A Node style event Role for Moose
package MooseX::Event;
{
  $MooseX::Event::VERSION = 'v0.2.0';
}
use Any::Moose ();
use Any::Moose '::Exporter';

{
    my($import,$unimport,$init_meta) = any_moose('::Exporter')->build_import_methods(
        as_is => [qw( has_event has_events )],
        also => any_moose(),
        );

    sub import {
        my $class = shift;

        my $with_args = {};

        my @args;
        while (local $_ = shift @_) {
            if ( $_ eq '-alias' ) {
                $with_args->{'-alias'} = shift;
            }
            elsif ( $_ eq '-excludes' ) {
                $with_args->{'-excludes'} = shift;
            }
            else {
                push @args, $_;
            }
        }

        my $caller = caller();
        $class->$import( { into => $caller }, @args );

        # I would expect that 'base_class_roles' in setup_import_methods would
        # do the below, but no, it doesn't.
        if ( ! any_moose('::Util')->can('does_role')->( $caller, 'MooseX::Event::Role' ) ) {
             require MooseX::Event::Role;
             MooseX::Event::Role->meta->apply( $caller->meta, %{$with_args} );
        }
    }
   
    sub unimport { goto $unimport; }
    *init_meta = $init_meta if defined $init_meta;
}


our @listener_wrappers;


sub add_listener_wrapper {
    my( $wrapper ) = @_[1..$#_];
    push @listener_wrappers, $wrapper;
    return $wrapper;
}


sub remove_listener_wrapper {
    my( $wrapper ) = @_[1..$#_];
    @listener_wrappers = grep { $_ != $wrapper } @listener_wrappers;
    return;
}




my $stub = sub {};
sub has_event {
    my $class = caller();
    $class->meta->add_method( "event:$_" => $stub ) for @_;
}

BEGIN { *has_events = \&has_event }

no Any::Moose '::Exporter';

1;


__END__
=pod

=head1 NAME

MooseX::Event - A Node style event Role for Moose

=head1 VERSION

version v0.2.0

=head1 SYNOPSIS

  package Example {
      use MooseX::Event;
      
      has_event 'pinged';
      
      sub ping {
          my $self = shift;
          $self->emit('pinged');
      }
  }
  
  use 5.10.0;

  my $example = Example->new;

  $example->on( pinged => sub { say "Got a ping!" } );
  $example->on( pinged => sub { say "Got another ping!" } );

  $example->ping; # prints "Got a ping!" and "Got another ping!"

  $example->remove_all_listeners( "pinged" ); # Remove all of the pinged listeners

  $example->once( pinged => sub { say "First ping." } );
  $example->ping; $example->ping; # Only prints "First ping." once

  my $listener = $example->on( pinged => sub { say "Ping" } );
  $example->remove_listener( pinged => $listener );

  $example->ping(); # Does nothing

=head1 DESCRIPTION

This provides Node.js style events in a Role for Moose.

MooseX::Event is implemented as a Moose Role.  To add events to your object:

  use MooseX::Event;

It provides a helper declare what events your object supports:

  has_event 'event';
  ## or
  has_events qw( event1 event2 event3 );

Users of your class can now call the "on" method in order to register an event handler:

  $obj->on( event1 => sub { say "I has an event"; } );

And clear their event listeners with:

  $obj->remove_all_listeners( "event1" );

Or add and clear just one listener:

  my $listener = $obj->on( event1 => sub { say "Event here"; } );
  $obj->remove_listener( event1 => $listener );

You can trigger events from your class with the "emit" method:

  $self->emit( event1 => ( "arg1", "arg2", "argn" ) );

You can remove the has_event and has_events helpers by unimporting MooseX::Event

  no MooseX::event;

=head1 CLASS METHODS

=head2 our method add_listener_wrapper( CodeRef $wrapper ) returns CodeRef

Wrappers are called in reverse declaration order.  They take a the listener
to be added as an argument, and return a wrapped listener.

=head2 our method remove_listener_wrapper( CodeRef $wrapper )

Removes a previously added listener wrapper.

=head1 HELPERS

=head2 sub has_event( Array[Str] *@event_names ) is export

=head2 sub has_events( Array[Str] *@event_names ) is export

Registers your class as being able to emit the event names listed.

=head1 RELATED

=over

=item L<Object::Event>

=item L<Mixin::Event::Dispatch>

=item L<Class::Publisher>

=item L<Event::Notify>

=item L<Notification::Center>

=item L<Class::Observable>

=item L<Reflex::Role::Reactive>

=item L<Aspect::Library::Listenable>

=item L<http://nodejs.org/docs/v0.5.4/api/events.html>

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::Event::Role|MooseX::Event::Role>

=item *

L<MooseX::Event::Role::ClassMethods|MooseX::Event::Role::ClassMethods>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc MooseX::Event

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/MooseX-Event>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-moosex-event at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Event>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/iarna/On-Event>

  git clone https://github.com/iarna/On-Event.git

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

