package Reaction::UI::RenderingContext::TT;

use Reaction::Class;
use aliased 'Reaction::UI::RenderingContext';
use aliased 'Template::View';

use namespace::clean -except => [ qw(meta) ];
extends RenderingContext;



our $body;
sub dispatch {
  my ($self, $render_tree, $args) = @_;
#warn "-- dispatch start\n";
  local $body = '';
  my %args_copy = %$args;
  foreach my $to_render (@$render_tree) {
    my ($type, @to) = @$to_render;
    if ($type eq '-layout') {
      my ($lset, $fname, $next) = @to;
      local $args_copy{call_next} =
        (@$next
          ? sub { $self->dispatch($next, $args); }
          : '' # no point running internal dispatch if nothing -to- dispatch
        );
      $self->render($lset, $fname, \%args_copy);
    } elsif ($type eq '-render') {
      my ($widget, $fname, $over) = @to;
      #warn "@to";
      if (defined $over) {
        my $count = 0;
        $over->each(sub {
          local $args_copy{_} = $_[0];
          local $args_copy{count} = ++$count;
          $body .= $widget->render($fname, $self, \%args_copy);
        });
      } else {
        $body .= $widget->render($fname, $self, \%args_copy);
      }
    }
  }
#warn "-- dispatch end, body: ${body}\n-- end body\nbacktrace: ".Carp::longmess()."\n-- end trace\n";
  return $body;
};
sub render {
  my ($self, $lset, $fname, $args) = @_;

  confess "\$body not in scope" unless defined($body);

  # foreach non-_ prefixed key in the args
  # build a subref for this key that passes self so the generator has a
  # rendering context when [% key %] is evaluated by TT as $val->()
  # (assuming it's a subref - if not just pass through)

  my $tt_args = {
    map {
      my $arg = $args->{$_};
      ($_ => (ref $arg eq 'CODE' ? sub { $arg->($self, $args) } : $arg))
    } grep { !/^_/ } keys %$args
  };

  $body .= $lset->tt_view->include($fname, $tt_args);
#warn "rendered ${fname}, body length now ".length($body)."\n";
};

__PACKAGE__->meta->make_immutable;


1;
