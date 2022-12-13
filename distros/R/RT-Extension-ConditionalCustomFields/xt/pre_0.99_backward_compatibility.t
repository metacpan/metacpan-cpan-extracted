use strict;
use warnings;

package RT::CustomField;
sub oldSetConditionedBy {
    my $self = shift;
    my $cf = shift;
    my $value = shift;

    return (0, $self->loc('CF parametrer is mandatory')) if (!$cf && $value);

    # Use empty RT::CustomField to delete attribute
    unless ($cf) {
        $cf = RT::CustomField->new($self->CurrentUser);
    }

    # Use $cf as a RT::CustomField object
    unless (ref $cf) {
        my $cf_id = $cf;
        $cf = RT::CustomField->new($self->CurrentUser);
        $cf->Load($cf_id);
        return(0, $self->loc("Couldn't load CustomField #[_1]", $cf_id)) unless $cf->id;
    }

    my @values = ref($value) eq 'ARRAY' ? @$value : ($value);

    sub arrays_identical {
        my( $left, $right ) = @_;
        my @leftary = ref $left eq 'ARRAY' ? @$left : ($left);
        my @rightary = ref $right eq 'ARRAY' ? @$right : ($right);
        return 0 if scalar @$left != scalar @$right;
        my %hash;
        @hash{ @leftary, @rightary } = ();
        return scalar keys %hash == scalar @leftary;
    }

    my $attr = $self->FirstAttribute('ConditionedBy');
    if ($attr && $attr->Content
              && $attr->Content->{CF}
              && $cf->id
              && $attr->Content->{CF} == $cf->id
              && $attr->Content->{vals}
              && arrays_identical($attr->Content->{vals}, \@values)) {
        return (1, $self->loc('ConditionedBy unchanged'));
    }

    if ($cf->id && @values) {
        return (0, "Permission Denied")
            unless $cf->CurrentUserHasRight('SeeCustomField');

        my ($ret, $msg) = $self->SetAttribute(
            Name    => 'ConditionedBy',
            Content => {CF => $cf->id, vals => \@values},
        );
        if ($ret) {
            return ($ret, $self->loc('ConditionedBy changed to CustomField #[_1], values [_2]', $cf->id, join(', ', @values)));
        }
        else {
            return ($ret, $self->loc( "Can't change ConditionedBy to CustomField #[_1], values [_2]: [_3]", $cf->id, join(', ', @values), $msg));
        }
    } elsif ($attr) {
        my ($ret, $msg) = $attr->Delete;
        if ($ret) {
            return ($ret, $self->loc('ConditionedBy deleted'));
        }
        else {
            return ($ret, $self->loc( "Can't delete ConditionedBy: [_1]", $msg));
        }
    }
}

package main;
use RT::Extension::ConditionalCustomFields::Test tests => 11;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Select', MaxValues => 1, Queue => 'General');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by->Create(Name => 'ConditionedBy', Type => 'Freeform', MaxValues => 1, Queue => 'General');

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['Condition'],
        'Group two' => ['ConditionedBy'],
    ],
);
RT->Config->PostLoadCheck;

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by->id , Value => 'See me?');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(600);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

# Display, condition met
$cf_conditioned_by->oldSetConditionedBy($cf_condition->id, $cf_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[0]->Name);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
my $ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when displaying and Select condition val is met');

# Display, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->selector('#CF-'. $cf_conditioned_by->id . '-ShowRow', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when displaying and Select condition val is not met');

# Modify, condition met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[0]->Name);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_displayed, 'Show ConditionalCF when modifying and Select condition val is met');

# Update value to condition not met
my $ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($ticket_cf_condition, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Values').trigger('change');");
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when modifying and Select condition val is updated to not met');

# Modify, condition not met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[1]->Name);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);
$ticket_cf_conditioned_by = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by->id . '-Value', single => 1);
ok($ticket_cf_conditioned_by->is_hidden, 'Hide ConditionalCF when modifying and Select condition val is not met');
