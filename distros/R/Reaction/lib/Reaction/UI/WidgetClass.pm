package Reaction::UI::WidgetClass;

use Reaction::ClassExporter;
use Reaction::Class;
use Reaction::UI::Widget;
use Data::Dumper;
use Devel::Declare;
use HTML::Entities ();
use aliased 'Reaction::UI::WidgetClass::_OVER';

no warnings 'once';

use namespace::clean -except => [ qw(meta) ];


# for local() for fragment wrap
our ($next_call, $fragment_args, $current_widget, $do_render, $new_args);

after 'do_import' => sub {
  my ($self, $package) = @_;
  Devel::Declare->install_declarator(
    $package, 'fragment', DECLARE_NAME,
    sub { },
    sub {
      WidgetClass->handle_fragment(@_);
    }
  );
};

after 'setup_and_cleanup' => sub {
  my ($self, $package) = @_;
  {
    no strict 'refs';
    delete ${"${package}::"}{'fragment'};
  }
  #Devel::Declare->teardown_for($package);
};
override exports_for_package => sub {
  my ($self, $package) = @_;
  return (super(),
    over => sub {
      my ($collection) = @_;
      confess "too many args, should be: over \$collection" if @_ > 1;
      _OVER->new(collection => $collection);
    },
    render => sub {
      my ($name, $over) = @_;

      my $sig = "should be: render 'name' or render 'name' => over \$coll";
      if (!defined $name) { confess "name undefined: $sig"; }
      if (ref $name) { confess "name is a ${\ref $name} ref, not a plain string: $sig"; }
      if (defined $over && !(blessed($over) && $over->isa(_OVER))) {
        confess "invalid args after name, $sig";
      }
      $do_render->($package, $current_widget, $name, $over);
    },
    arg => sub {
      my ($name, $value) = @_;

      my $sig = "should be: arg 'name' => \$value";
      if (@_ < 2) {
        $name ||= 'undef';
        $value ||= 'undef';
        confess "Not enough arguments, $sig, got: $name => $value";
      }
      if (!defined $name) { confess "name undefined, $sig"; }
      if (ref $name) { confess "name is not a string, $sig"; }

      $new_args->{$name} = $value;
    },
    localized => sub {
      my($value) = @_;
      return $_{self}->view->localize($value);
    },
    call_next => sub {
      confess "args passed, should be just call_next; or call_next();"
        if @_;
      $next_call->(@$fragment_args);
    },
    event_id => sub {
      my ($name) = @_;
      $_{viewport}->event_id_for($name);
    },
    event_uri => sub {
      my ($events) = @_;
      my $vp = $_{viewport};
      my %args = map{ $vp->event_id_for($_) => $events->{$_} } keys %$events;
      $vp->ctx->req->uri_with(\%args);
    },
    attrs => sub {
      my ($attrs) = @_;
      return join(' ', map {
        my $text = HTML::Entities::encode_entities( $attrs->{$_} );
        qq{$_="${text}"};
      } keys %$attrs);
    },
    implements => sub {
      my ($name, $sub) = @_;
      $package->meta->add_method($name, $sub);
    },
  );
};
override default_base => sub { ('Reaction::UI::Widget') };
sub handle_fragment {
  my ($self, $name, $proto, $code) = @_;
#warn ($self, $name, $code);
  return ("_fragment_${name}" => $self->wrap_as_fragment($code));
};
sub wrap_as_fragment {
  my ($self, $code) = @_;
  return sub {
    local $next_call;
    if (ref $_[0] eq 'CODE') { # inside 'around' modifier
      $next_call = shift;
    }
    local $fragment_args = \@_;

    # $self->$method($do_render, \%_, $new_args)
    local $current_widget = $_[0];
    local $do_render = $_[1];
    local *_ = \%{$_[2]};
    local $_ = $_[2]->{_};
    local $new_args = $_[3];
    $code->(@_);
  };
};

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::UI::WidgetClass - Create a new widget class

=head1 DESCRIPTION

Turns the importing package into a widget class. It will export:

=over 4

=item All of L<Moose>

=item All of L<Reaction::Class>

=item L<strict> and L<warnings>

=item See L</EXPORTS> for this package's own exports

=back

It will also set the value of C<default_base> as new superclass. The default is
C<Reaction::UI::Widget>.

=head1 EXPORTS

=head2 over

  over $collection

Used in combination with L</render> to render a fragment for a series of values:

  render fragment_name => over [1, 2, 3];

=head2 render

  render $fragment_name;
  render $fragment_name, $over;

With only the fragment name as argument, it renders that fragment. If an C<$over>
collection is specified with the L</over> keyword, the fragment is rendered once
for every value in the collection. The value will be accessible in the topic
argument C<_>.

=head2 arg

  arg $arg_name, $arg_value;

Sets the fragment argument C<$arg_name> to C<$arg_value>;

=head2 localized

  localize $value;

Calls the view's C<localize> method to localize the passed value.

=head2 call_next

  call_next;

Calls the parent fragment.

=head2 event_id

  event_id $event_name;

Fetches the event id for the event C<$event_name> from the viewport via its C<event_id_for>
method.

=head2 event_uri

  event_uri \%events;

Returns an L<URI> object with the event ids corresponding to the keys in the C<%events> 
argument and the values being the values of the hash reference.

=head2 attrs

  attrs \%attrs;

Builds a string of rendered element attributes out of the C<%attrs> hash reference argument.

=head2 implements

  implements fragment foo { ... };
  implements bar => sub { ... };

Implements a method or a fragment in the widget class.

=head2 fragment

  fragment foo { ... };

Creates a new fragment named C<foo> with a implementation in the block.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
