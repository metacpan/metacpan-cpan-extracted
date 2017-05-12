#package Reaction::UI::ViewPort::TimeRangeCollection;
#
# Marked commented out because unused and unmaintained. Should probably
# be turned into a complex viewport example later instead --mst
#
#use Reaction::Class;
#use Reaction::Types::DateTime;
#use Moose::Util::TypeConstraints ();
#use DateTime::Event::Recurrence;
#use aliased 'Reaction::UI::ViewPort::Field::String';
#use aliased 'Reaction::UI::ViewPort::Field::DateTime';
#use aliased 'Reaction::UI::ViewPort::Field::HiddenArray';
#use aliased 'Reaction::UI::ViewPort::Field::TimeRange';
#
#class TimeRangeCollection is 'Reaction::UI::ViewPort', which {
#
#  #has '+layout' => (default => 'timerangecollection');
#
#  has '+column_order' => (
#    default => sub{[ qw/ time_from time_to pattern repeat_from repeat_to / ]},
#  );
#
#  has time_from => (
#    isa => 'Reaction::UI::ViewPort::Field::DateTime',
#    is => 'rw', lazy_build => 1,
#  );
#
#  has time_to => (
#    isa => 'Reaction::UI::ViewPort::Field::DateTime',
#    is => 'rw', lazy_build => 1,
#  );
#
#  has repeat_from => (
#    isa => 'Reaction::UI::ViewPort::Field::DateTime',
#    is => 'rw', lazy_build => 1,
#  );
#
#  has repeat_to => (
#    isa => 'Reaction::UI::ViewPort::Field::DateTime',
#    is => 'rw', lazy_build => 1,
#  );
#
#  has pattern => (
#    isa => 'Reaction::UI::ViewPort::Field::String',
#  #  valid_values => [ qw/none daily weekly monthly/ ],
#    is => 'rw', lazy_build => 1,
#  );
#
#  has range_vps => (isa => 'ArrayRef', is => 'rw', lazy_build => 1,);
#
#  has max_range_vps => (isa => 'Int', is => 'rw', lazy_build => 1,);
#
#  has error => (
#    isa => 'Str',
#    is => 'rw',
#    required => 0,
#  );
#
#  has field_names => (
#    isa => 'ArrayRef', is => 'rw',
#    lazy_build => 1, clearer => 'clear_field_names',
#  );
#
#  has _field_map => (
#    isa => 'HashRef', is => 'rw', init_arg => 'fields',
#    clearer => '_clear_field_map',
#    predicate => '_has_field_map',
#    lazy_build => 1,
#  );
#
#  has on_next_callback => (
#    isa => 'CodeRef',
#    is => 'rw',
#    predicate => 'has_on_next_callback',
#  );
#
#  implements fields => as { shift->_field_map };
#
#  implements _build_range_vps => as { [] };
#
#  implements spanset => as {
#    my ($self) = @_;
#    my $spanset = DateTime::SpanSet->empty_set;
#    $spanset = $spanset->union($_->value) for @{$self->range_vps};
#    return $spanset;
#  };
#
#  implements range_strings => as {
#    my ($self) = @_;
#    return [ map { $_->value_string } @{$self->range_vps} ];
#  };
#
#  implements remove_range_vp => as {
#    my ($self, $to_remove) = @_;
#    $self->range_vps([ grep { $_ != $to_remove } @{$self->range_vps} ]);
#    $self->_clear_field_map;
#    $self->clear_field_names;
#  };
#
#  implements add_range_vp => as {
#    my ($self) = @_;
#    if ($self->can_add) {
#      $self->_clear_field_map;
#      $self->clear_field_names;
#      my @span_info = (
#        $self->time_from->value,
#        $self->time_to->value,
#        (map { $_->has_value ? $_->value : '' }
#         map { $self->$_ } qw/repeat_from repeat_to/),
#        $self->pattern->value,
#      );
#      my $encoded_spanset = join ',', @span_info;
#      my $args = {
#        value_string => $encoded_spanset,
#        parent => $self
#      };
#      my $count = scalar(@{$self->range_vps});
#      my $field = $self->_build_simple_field(TimeRange, 'range-'.$count, $args);
#      my $d = DateTime::Format::Duration->new( pattern => '%s' );
#      if ($d->format_duration( $self->spanset->intersection($field->value)->duration ) > 0) {
#        # XXX - Stop using the stash here?
#        $self->ctx->stash->{warning} = 'Warning: Most recent time range overlaps '.
#                                       'with existing time range in this booking.';
#      }
#      #warn "encoded spanset = $encoded_spanset\n";
#      #warn "current range = ".join(', ', (@{$self->range_vps}))."\n";
#      push(@{$self->range_vps}, $field);
#    }
#  };
#
#  implements _build_field_map => as {
#    my ($self) = @_;
#    my %map;
#    foreach my $field (@{$self->range_vps}) {
#      $map{$field->name} = $field;
#    }
#    foreach my $name (@{$self->column_order}) {
#      $map{$name} = $self->$name;
#    }
#    return \%map;
#  };
#
#  implements _build_field_names => as {
#    my ($self) = @_;
#    return [
#      (map { $_->name } @{$self->range_vps}),
#      @{$self->column_order}
#    ];
#  };
#
#  implements can_add => as {
#    my ($self) = @_;
#    my $error;
#    if ($self->time_to->has_value && $self->time_from->has_value) {
#      my $time_to = $self->time_to->value;
#      my $time_from = $self->time_from->value;
#
#      my ($pattern, $repeat_from, $repeat_to) = ('','','');
#      $pattern = $self->pattern->value if $self->pattern->has_value;
#      $repeat_from = $self->repeat_from->value if $self->repeat_from->has_value;
#      $repeat_to = $self->repeat_to->value if $self->repeat_to->has_value;
#
#      my $duration = $time_to - $time_from;
#      if ($time_to < $time_from) {
#        $error = 'Please make sure that the Time To is after the Time From.';
#      } elsif ($time_to == $time_from) {
#        $error = 'Your desired booking slot is too small.';
#      } elsif ($pattern && $pattern ne 'none') {
#        my %pattern = (hourly => [ hours => 1 ],
#                        daily => [ days => 1 ],
#                       weekly => [ days => 7 ],
#                      monthly => [ months => 1 ]);
#        my $pattern_comp = DateTime::Duration->compare(
#                             $duration, DateTime::Duration->new( @{$pattern{$pattern}} )
#                           );
#        if (!$repeat_to || !$repeat_from) {
#          $error = 'Please make sure that you enter a valid range for the '.
#                   'repetition period.';
#        } elsif ($time_to == $time_from) {
#          $error = 'Your desired repetition period is too short.';
#        } elsif ($repeat_to && ($repeat_to < $repeat_from)) {
#          $error = 'Please make sure that the Repeat To is after the Repeat From.';
#        } elsif ( ( ($pattern eq 'hourly') && ($pattern_comp > 0) )  ||
#         ( ($pattern eq 'daily') && ($pattern_comp > 0) ) ||
#         ( ($pattern eq 'weekly') && ($pattern_comp > 0) ) ||
#         ( ($pattern eq 'monthly') && ($pattern_comp > 0) ) ) {
#          $error = "Your repetition pattern ($pattern) is too short for your ".
#                   "desired booking length.";
#        }
#      }
#    } else {
#      $error = 'Please complete both the Time To and Time From fields.';
#    }
#    $self->error($error);
#    return !defined($error);
#  };
#
#  implements _build_simple_field => as {
#    my ($self, $class, $name, $args) = @_;
#    return $class->new(
#             name => $name,
#             location => join('-', $self->location, 'field', $name),
#             ctx => $self->ctx,
#             %$args
#           );
#  };
#
#  implements _build_time_to => as {
#    my ($self) = @_;
#    return $self->_build_simple_field(DateTime, 'time_to', {});
#  };
#
#  implements _build_time_from => as {
#    my ($self) = @_;
#    return $self->_build_simple_field(DateTime, 'time_from', {});
#  };
#
#  implements _build_repeat_to => as {
#    my ($self) = @_;
#    return $self->_build_simple_field(DateTime, 'repeat_to', {});
#  };
#
#  implements _build_repeat_from => as {
#    my ($self) = @_;
#    return $self->_build_simple_field(DateTime, 'repeat_from', {});
#  };
#
#  implements _build_pattern => as {
#    my ($self) = @_;
#    return $self->_build_simple_field(String, 'pattern', {});
#  };
#
#  implements next => as {
#    $_[0]->on_next_callback->(@_);
#  };
#
#  override accept_events => sub {
#    my $self = shift;
#    ('add_range_vp', ($self->has_on_next_callback ? ('next') : ()), super());
#  };
#
#  override child_event_sinks => sub {
#    my ($self) = @_;
#    return ((grep { ref($_) =~ 'Hidden' } values %{$self->_field_map}),
#            (grep { ref($_) !~ 'Hidden' } values %{$self->_field_map}),
#            super());
#  };
#
#  override apply_events => sub {
#    my ($self, $ctx, $events) = @_;
#
#    # auto-inflate range fields based on number from hidden field
#
#    my $max = $events->{$self->location.':max_range_vps'};
#    my @range_vps = map {
#      TimeRange->new(
#        name => "range-$_",
#        location => join('-', $self->location, 'field', 'range', $_),
#        ctx => $self->ctx,
#        parent => $self,
#      )
#    } ($max ? (0 .. $max - 1) : ());
#    $self->range_vps(\@range_vps);
#    $self->_clear_field_map;
#    $self->clear_field_names;
#
#    # call original event handling
#
#    super();
#
#    # repack range VPs in case of deletion
#
#    my $prev_idx = -1;
#
#    foreach my $vp (@{$self->range_vps}) {
#      my $cur_idx = ($vp->name =~ m/range-(\d+)/);
#      if (($cur_idx - $prev_idx) > 1) {
#        $cur_idx--;
#        my $name = "range-${cur_idx}";
#        $vp->name($name);
#        $vp->location(join('-', $self->location, 'field', $name));
#      }
#      $prev_idx = $cur_idx;
#    }
#  };
#
#};
#
#1;
#
#=head1 NAME
#
#Reaction::UI::ViewPort::TimeRangeCollection
#
#=head1 SYNOPSIS
#
#  my $trc = $self->push_viewport(TimeRangeCollection,
#    layout => 'avail_search_form',
#    on_apply_callback => $search_callback,
#    name => 'TRC',
#  );
#
#=head1 DESCRIPTION
#
#=head1 ATTRIBUTES
#
#=head2 can_add
#
#=head2 column_order
#
#=head2 error
#
#=head2 field_names
#
#=head2 fields
#
#=head2 layout
#
#=head2 pattern
#
#Typically either: none, daily, weekly or monthly
#
#=head2 max_range_vps
#
#=head2 range_vps
#
#=head2 repeat_from
#
#A DateTime field.
#
#=head2 repeat_to
#
#A DateTime field.
#
#=head2 time_from
#
#A DateTime field.
#
#=head2 time_to
#
#A DateTime field.
#
#=head1 METHODS
#
#=head2 spanset
#
#Returns: $spanset consisting of all the TimeRange spans combined
#
#=head2 range_strings
#
#Returns: ArrayRef of Str consisting of the value_strings of all TimeRange
#VPs
#
#=head2 remove_range_vp
#
#Arguments: $to_remove
#
#=head2 add_range_vp
#
#Arguments: $to_add
#
#=head2 _build_simple_field
#
#Arguments: $class, $name, $args
#where $class is an object, $name is a scalar and $args is a hashref
#
#=head2 next
#
#=head2 on_next_callback
#
#=head2 clear_field_names
#
#=head2 child_event_sinks
#
#=head1 SEE ALSO
#
#=head2 L<Reaction::UI::ViewPort>
#
#=head2 L<Reaction::UI::ViewPort::Field::TimeRange>
#
#=head2 L<Reaction::UI::ViewPort::Field::DateTime>
#
#=head2 L<DateTime::Event::Recurrence>
#
#=head1 AUTHORS
#
#See L<Reaction::Class> for authors.
#
#=head1 LICENSE
#
#See L<Reaction::Class> for the license.
#
#=cut

1;
