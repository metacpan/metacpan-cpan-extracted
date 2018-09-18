package QBit::Application::Model::Multistate;
$QBit::Application::Model::Multistate::VERSION = '0.009';
use qbit;

use base qw(QBit::Application::Model);

use Exception::Multistate;

use QBit::GraphViz;

sub multistates_graph {
    my ($package, %meta) = @_;

    throw gettext("First argument must be package name, QBit::Application::Model::Multistate descendant")
      if !$package
          || ref($package)
          || !$package->isa('QBit::Application::Model::Multistate');

    my $pkg_stash = package_stash(ref($package) || $package);
    my $bit_num = 0;
    throw gettext('Max multistates count is 63')
      if @{$meta{'multistates'} || []} > 63;

    $pkg_stash->{'__EMPTY_NAME__'} = $meta{'empty_name'} || gettext('Start status');

    $pkg_stash->{'__BITS__'} = [map {[shift(@$_), shift(@$_), {@$_}]} @{$meta{'multistates'} || []}];

    $pkg_stash->{'__BITS_HS__'} =
      {map {$_->[0] => {bit => $bit_num++, description => $_->[1], opts => $_->[2]}} @{$pkg_stash->{'__BITS__'}}};

    $pkg_stash->{'__ACTIONS__'} = {};
    my %actions = (%{$meta{'actions'} || {}}, %{$meta{'right_actions'} || {}});
    while (my ($key, $value) = each(%actions)) {
        $pkg_stash->{'__ACTIONS__'}{$key} = $value;
    }

    $pkg_stash->{'__RIGHT_ACTIONS__'} = {};
    my %right_group = (
        (
            exists($meta{'right_group'})
            ? (
                name        => $meta{'right_group'}[0],
                description => $meta{'right_group'}[1]
              )
            : ()
        ),
        rights => {}
    );
    foreach my $action (keys(%{$meta{'right_actions'} || {}})) {
        my $right_name = 'do_' . ($meta{'right_name_prefix'} || '') . $action;
        $pkg_stash->{'__RIGHT_ACTIONS__'}{$action} = $right_name;
        $right_group{'rights'}->{$right_name} =
          sub {gettext('Right to do action "%s"', $meta{'right_actions'}->{$action}->())};
    }
    __PACKAGE__->register_rights([\%right_group]);

    $pkg_stash->{'__MULTISTATES__'} = {0 => {}};
    my $prev_multistates_cnt;

    while (!$prev_multistates_cnt || $prev_multistates_cnt != keys(%{$pkg_stash->{'__MULTISTATES__'}})) {
        $prev_multistates_cnt = keys(%{$pkg_stash->{'__MULTISTATES__'}});
        foreach my $action (@{$meta{'multistate_actions'} || []}) {
            throw gettext('Unknown action "%s"', $action->{'action'})
              unless exists($pkg_stash->{'__ACTIONS__'}{$action->{'action'}});

            foreach my $multistate (
                __filter_multistates($pkg_stash->{'__BITS_HS__'}, $pkg_stash->{'__MULTISTATES__'}, $action->{'from'}))
            {
                my $new_multistate = $multistate;
                $new_multistate |= 2**$pkg_stash->{'__BITS_HS__'}{$_}{'bit'} foreach @{$action->{set_flags} || []};

                $new_multistate &= ~(2**$pkg_stash->{'__BITS_HS__'}{$_}{'bit'}) foreach @{$action->{reset_flags} || []};

                $pkg_stash->{'__MULTISTATES__'}{$multistate}{$action->{'action'}} = $new_multistate;

                $pkg_stash->{'__MULTISTATES__'}{$new_multistate} = {}
                  unless exists($pkg_stash->{'__MULTISTATES__'}{$new_multistate});
            }
        }
    }

    # Check the multistates graph for unreachable statuses.

    my @unreachable;
    foreach my $multistate_name (keys(%{$pkg_stash->{'__BITS_HS__'}})) {
        my $multistate = $pkg_stash->{'__BITS_HS__'}{$multistate_name};

        my $exists = $pkg_stash->{'__MULTISTATES__'}{$multistate->{'bit'}};
        unless ($exists) {
            foreach (keys(%{$pkg_stash->{'__MULTISTATES__'}})) {
                if (($_ & 2**$multistate->{'bit'})) {
                    $exists = TRUE;
                    last;
                }
            }
        }
        push(@unreachable, $multistate_name) unless $exists;
    }

    throw gettext("Unreachable status(es) in package '$package': '%s'.", join(q{', '}, @unreachable)),
      if @unreachable;
}

sub get_empty_name {
    my $name = package_stash(ref(shift))->{'__EMPTY_NAME__'};

    return ref($name) eq 'CODE' ? $name->() : $name;
}

sub get_multistates {
    return package_stash(ref(shift))->{'__MULTISTATES__'};
}

sub get_multistates_bits {
    return package_stash(ref(shift))->{'__BITS__'};
}

sub get_multistates_bits_hs {
    return package_stash(ref(shift))->{'__BITS_HS__'};
}

sub get_registered_actions {
    return package_stash(ref(shift))->{'__ACTIONS__'};
}

sub get_registered_actions_rights {
    return package_stash(ref(shift))->{'__RIGHT_ACTIONS__'};
}

sub get_multistate_name {
    my ($self, $multistate, %opts) = @_;

    return $self->get_empty_name() if $multistate == 0;

    my $i = 0;

    my $name = join(
        ".\n",
        map {ref($_->[1]) eq 'CODE' ? $_->[1]() : $_->[1]}
          grep {
                 ($multistate & 2**$i++) == 2**($i - 1)
              && ($opts{'private'} && $_->[2]{'private'} || !$_->[2]{'private'})
          } @{$self->get_multistates_bits()}
    );

    $name = $self->get_empty_name() unless length($name);
    $name .= '.' if length($name);

    return $name;
}

sub get_action_name {
    my ($self, $action) = @_;

    my $action_name = $self->get_registered_actions()->{$action};
    $action_name = $action_name->()
      if ref($action_name) eq 'CODE';

    return $action_name;
}

sub get_multistates_graph {
    my ($self, %opts) = @_;

    my $g = QBit::GraphViz->new(
        concentrate => 0,
        overlap     => 'false',
        node        => {
            style => 'solid',
            style => 'solid',
        },
    );

    my $states          = $self->get_multistates();
    my $action_right_hs = $self->get_registered_actions_rights();

    foreach my $state (keys %$states) {
        my $color = join(',', rand, rand, 0.7);
        $g->add_node(
            {
                name      => "MS_$state",
                label     => "($state) " . $self->get_multistate_name($state, private => $opts{'private_names'}),
                color     => $color,
                fontcolor => $color,
            }
        );

        foreach (keys %{$states->{$state}}) {
            $g->add_edge(
                "MS_$state" => "MS_$states->{$state}{$_}",
                label       => "$_\n" . $self->get_action_name($_),
                constraint  => !(/^un(.+)$/ && exists($self->get_registered_actions()->{$1})),
                color       => $color,
                fontcolor   => $color,
                style       => (exists($action_right_hs->{$_}) ? 'dashed' : 'solid'),
            );
        }
    }

    return $g;
}

sub check_multistate_action {
    my ($self, $multistate, $action) = @_;

    return FALSE unless exists($self->get_multistates()->{$multistate}{$action});

    my $right = $self->get_registered_actions_rights->{$action};
    return FALSE if defined($right) && !$self->check_rights($right);

    return TRUE;
}

sub check_multistate_flag {
    my ($self, $multistate, $flag) = @_;

    my $bits_hs = $self->get_multistates_bits_hs()->{$flag} || return FALSE;

    return !!(($multistate || 0) & (2**$bits_hs->{'bit'}));
}

sub get_multistate_actions {
    my ($self, $multistate) = @_;

    return {
        map {$_ => $self->get_action_name($_)}
          grep {$self->check_multistate_action($multistate, $_)}
          keys(%{$self->get_multistates()->{$multistate} || {}})
    };
}

sub get_multistate_by_action {
    my ($self, $action) = @_;

    my $multistates = $self->get_multistates();

    return [grep {exists($multistates->{$_}{$action})} keys(%$multistates)];
}

sub get_multistates_by_filter {
    my ($self, $filter) = @_;

    return [__filter_multistates($self->get_multistates_bits_hs(), $self->get_multistates(), $filter)];
}

sub __filter_multistates {
    my ($bits, $multistates, $expression) = @_;

    my %operators = (
        OR  => [0, sub {'(' . pop(@{$_[0]}) . ' || ' . pop(@{$_[0]}) . ')'}],
        AND => [1, sub {'(' . pop(@{$_[0]}) . ' && ' . pop(@{$_[0]}) . ')'}],
        NOT => [2, sub {'!' . pop(@{$_[0]})}],
    );

    my $process = sub {
        my ($op, $Q) = @_;

        push(@$Q, $operators{$op}->[1]($Q));
    };

    my $qexpression = "($expression)";
    my (@Q, @W);
    while ($qexpression =~ /(\(|\)|[a-zA-Z0-9_]+)/g) {
        my $token = $1;

        if ($token eq '(') {
            push(@W, '(');
        } elsif ($token eq ')') {
            while (@W) {
                my $operator = pop(@W);
                last if $operator eq '(';
                $process->($operator, \@Q);
            }
        } elsif (exists($operators{uc($token)})) {
            my $operator = pop(@W);
            ($operators{uc($token)}->[0] || 0) < ($operators{$operator}->[0] || 0)
              ? $process->($operator, \@Q)
              : push(@W, $operator);

            push(@W, uc($token));
        } else {
            throw gettext('Status "%s" does not exists', $token)
              unless exists($bits->{$token}) || $token eq '__EMPTY__';
            push(@Q,
                $token eq '__EMPTY__'
                ? '($_[0] == 0)'
                : '(($_[0] & ' . 2**$bits->{$token}{'bit'} . ') == ' . 2**$bits->{$token}{'bit'} . ')');
        }
    }

    my $sub_text = 'sub {' . pop(@Q) . '}';

    throw gettext('Syntax error in expression "%s"', $expression) if @W + @Q;

    my $sub = eval($sub_text);

    return grep {$sub->($_)} keys(%$multistates);
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::Multistate - Class for working with multistates.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-Multistate

=head1 Install

=over

=item *

cpanm QBit::Application::Model::Multistate

=item *

apt-get install libqbit-application-model-multistate-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
