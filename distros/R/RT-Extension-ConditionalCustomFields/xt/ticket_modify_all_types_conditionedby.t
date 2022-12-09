use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 57;

use WWW::Mechanize::PhantomJS;

my $cf_condition = RT::CustomField->new(RT->SystemUser);
$cf_condition->Create(Name => 'Condition', Type => 'Select', MaxValues => 1, Queue => 'General');
$cf_condition->AddValue(Name => 'Passed', SortOder => 0);
$cf_condition->AddValue(Name => 'Failed', SortOrder => 1);
my $cf_values = $cf_condition->Values->ItemsArrayRef;

my $cf_conditioned_by_selectbox_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_selectbox_single->Create(Name => 'ConditionedBySelectBoxSingle', Type => 'Select', RenderType => 'Select box', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_selectbox_single->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_selectbox_single->AddValue(Name => 'Two', SortOrder => 1);
my $cf_conditioned_by_selectbox_single_values = $cf_conditioned_by_selectbox_single->Values->ItemsArrayRef;
$cf_conditioned_by_selectbox_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_selectbox_multiple = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_selectbox_multiple->Create(Name => 'ConditionedBySelectBoxMultiple', Type => 'Select', RenderType => 'Select box', MaxValues => 0, Queue => 'General');
$cf_conditioned_by_selectbox_multiple->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_selectbox_multiple->AddValue(Name => 'Two', SortOrder => 1);
my $cf_conditioned_by_selectbox_multiple_values = $cf_conditioned_by_selectbox_multiple->Values->ItemsArrayRef;
$cf_conditioned_by_selectbox_multiple->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_list_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_list_single->Create(Name => 'ConditionedByListSingle', Type => 'Select', RenderType => 'List', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_list_single->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_list_single->AddValue(Name => 'Two', SortOrder => 1);
my $cf_conditioned_by_list_single_values = $cf_conditioned_by_list_single->Values->ItemsArrayRef;
$cf_conditioned_by_list_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_list_multiple = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_list_multiple->Create(Name => 'ConditionedByListMultiple', Type => 'Select', RenderType => 'List', MaxValues => 0, Queue => 'General');
$cf_conditioned_by_list_multiple->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_list_multiple->AddValue(Name => 'Two', SortOrder => 1);
my $cf_conditioned_by_list_multiple_values = $cf_conditioned_by_list_multiple->Values->ItemsArrayRef;
$cf_conditioned_by_list_multiple->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_dropdown_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_dropdown_single->Create(Name => 'ConditionedByDropdownSingle', Type => 'Select', RenderType => 'Dropdown', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_dropdown_single->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_dropdown_single->AddValue(Name => 'Two', SortOrder => 1);
my $cf_conditioned_by_dropdown_single_values = $cf_conditioned_by_dropdown_single->Values->ItemsArrayRef;
$cf_conditioned_by_dropdown_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_chosen_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_chosen_single->Create(Name => 'ConditionedByChosenSingle', Type => 'Select', RenderType => 'Select box', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_chosen_single->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Two', SortOrder => 1);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Three', SortOrder => 2);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Four', SortOrder => 3);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Five', SortOrder => 4);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Six', SortOrder => 5);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Seven', SortOrder => 6);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Eight', SortOrder => 7);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Nine', SortOrder => 8);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Ten', SortOrder => 9);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Eleven', SortOrder => 10);
$cf_conditioned_by_chosen_single->AddValue(Name => 'Twelve', SortOrder => 11);
my $cf_conditioned_by_chosen_single_values = $cf_conditioned_by_chosen_single->Values->ItemsArrayRef;
$cf_conditioned_by_chosen_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_chosen_multiple = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_chosen_multiple->Create(Name => 'ConditionedByChosenMultiple', Type => 'Select', RenderType => 'Select box', MaxValues => 0, Queue => 'General');
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Two', SortOrder => 1);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Three', SortOrder => 2);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Four', SortOrder => 3);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Five', SortOrder => 4);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Six', SortOrder => 5);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Seven', SortOrder => 6);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Eight', SortOrder => 7);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Nine', SortOrder => 8);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Ten', SortOrder => 9);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Eleven', SortOrder => 10);
$cf_conditioned_by_chosen_multiple->AddValue(Name => 'Twelve', SortOrder => 11);
my $cf_conditioned_by_chosen_multiple_values = $cf_conditioned_by_chosen_multiple->Values->ItemsArrayRef;
$cf_conditioned_by_chosen_multiple->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_freeform_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_freeform_single->Create(Name => 'ConditionedByFreeformSingle', Type => 'Freeform', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_freeform_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_freeform_multiple = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_freeform_multiple->Create(Name => 'ConditionedByFreeformMultiple', Type => 'Freeform', MaxValues => 0, Queue => 'General');
$cf_conditioned_by_freeform_multiple->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_text_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_text_single->Create(Name => 'ConditionedByTextSingle', Type => 'Text', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_text_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_wikitext_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_wikitext_single->Create(Name => 'ConditionedByWikitextSingle', Type => 'Text', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_wikitext_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_image_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_image_single->Create(Name => 'ConditionedByImageSingle', Type => 'Image', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_image_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_image_multiple = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_image_multiple->Create(Name => 'ConditionedByImageMultiple', Type => 'Image', MaxValues => 0, Queue => 'General');
$cf_conditioned_by_image_multiple->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_binary_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_binary_single->Create(Name => 'ConditionedByBinarySingle', Type => 'Binary', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_binary_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_binary_multiple = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_binary_multiple->Create(Name => 'ConditionedByBinaryMultiple', Type => 'Binary', MaxValues => 0, Queue => 'General');
$cf_conditioned_by_binary_multiple->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_combobox_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_combobox_single->Create(Name => 'ConditionedByComboboxSingle', Type => 'Combobox', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_combobox_single->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_combobox_single->AddValue(Name => 'Two', SortOrder => 1);
my $cf_conditioned_by_combobox_single_values = $cf_conditioned_by_combobox_single->Values->ItemsArrayRef;
$cf_conditioned_by_combobox_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_autocomplete_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_autocomplete_single->Create(Name => 'ConditionedByAutocompleteSingle', Type => 'Autocomplete', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_autocomplete_single->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_autocomplete_single->AddValue(Name => 'Two', SortOrder => 1);
my $cf_conditioned_by_autocomplete_single_values = $cf_conditioned_by_autocomplete_single->Values->ItemsArrayRef;
$cf_conditioned_by_autocomplete_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_autocomplete_multiple = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_autocomplete_multiple->Create(Name => 'ConditionedByAutocompleteMultiple', Type => 'Autocomplete', MaxValues => 0, Queue => 'General');
$cf_conditioned_by_autocomplete_multiple->AddValue(Name => 'One', SortOder => 0);
$cf_conditioned_by_autocomplete_multiple->AddValue(Name => 'Two', SortOrder => 1);
my $cf_conditioned_by_autocomplete_multiple_values = $cf_conditioned_by_autocomplete_multiple->Values->ItemsArrayRef;
$cf_conditioned_by_autocomplete_multiple->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_date_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_date_single->Create(Name => 'ConditionedByDateSingle', Type => 'Date', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_date_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_datetime_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_datetime_single->Create(Name => 'ConditionedByDateTimeSingle', Type => 'DateTime', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_datetime_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_ipaddress_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_ipaddress_single->Create(Name => 'ConditionedByIPAddressSingle', Type => 'IPAddress', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_ipaddress_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_ipaddress_multiple = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_ipaddress_multiple->Create(Name => 'ConditionedByIPAddressMultiple', Type => 'IPAddress', MaxValues => 0, Queue => 'General');
$cf_conditioned_by_ipaddress_multiple->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_ipaddressrange_single = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_ipaddressrange_single->Create(Name => 'ConditionedByIPAddressRangeSingle', Type => 'IPAddressRange', MaxValues => 1, Queue => 'General');
$cf_conditioned_by_ipaddressrange_single->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

my $cf_conditioned_by_ipaddressrange_multiple = RT::CustomField->new(RT->SystemUser);
$cf_conditioned_by_ipaddressrange_multiple->Create(Name => 'ConditionedByIPAddressRangeMultiple', Type => 'IPAddressRange', MaxValues => 0, Queue => 'General');
$cf_conditioned_by_ipaddressrange_multiple->SetConditionedBy($cf_condition->id, 'is', $cf_values->[0]->Name);

RT->Config->Set('CustomFieldGroupings',
    'RT::Ticket' => [
        'Group one' => ['Condition'],
        'Group two' => [
            'ConditionedBySelectBoxSingle',
            'ConditionedBySelectBoxMultiple',
            'ConditionedByListSingle',
            'ConditionedByListMultiple',
            'ConditionedByDropdownSingle',
            'ConditionedByChosenSingle',
            'ConditionedByChosenMultiple',
            'ConditionedByFreeformSingle',
            'ConditionedByFreeformMultiple',
            'ConditionedByTextSingle',
            'ConditionedByWikitextSingle',
            'ConditionedByImageSingle',
            'ConditionedByImageMultiple',
            'ConditionedByBinarySingle',
            'ConditionedByBinaryMultiple',
            'ConditionedByComboboxSingle',
            'ConditionedByComboboxSingle',
            'ConditionedByAutocompleteSingle',
            'ConditionedByAutocompleteMultiple',
            'ConditionedByDateSingle',
            'ConditionedByDateTimeSingle',
            'ConditionedByIPAddressSingle',
            'ConditionedByIPAddressMultiple',
            'ConditionedByIPAddressRangeSingle',
            'ConditionedByIPAddressRangeMultiple',
        ],
    ],
);

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket ConditionalCF');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_selectbox_single->id , Value => $cf_conditioned_by_selectbox_single_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_selectbox_multiple->id , Value => $cf_conditioned_by_selectbox_multiple_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_list_single->id , Value => $cf_conditioned_by_list_single_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_list_multiple->id , Value => $cf_conditioned_by_list_multiple_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_dropdown_single->id , Value => $cf_conditioned_by_dropdown_single_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_chosen_single->id , Value => $cf_conditioned_by_chosen_single_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_chosen_multiple->id , Value => $cf_conditioned_by_chosen_multiple_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_freeform_single->id , Value => 'See me?');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_freeform_multiple->id , Value => 'See me?');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_text_single->id , Value => 'See me?');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_wikitext_single->id , Value => 'See me?');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_combobox_single->id , Value => $cf_conditioned_by_combobox_single_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_autocomplete_single->id , Value => $cf_conditioned_by_autocomplete_single_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_autocomplete_multiple->id , Value => $cf_conditioned_by_autocomplete_multiple_values->[0]->Name);
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_date_single->id , Value => '2019-06-21');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_datetime_single->id , Value => '2021-06-21 00:42:00');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_ipaddress_single->id , Value => '192.168.1.6');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_ipaddress_multiple->id , Value => '192.168.1.6');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_ipaddressrange_single->id , Value => '192.168.1.0-192.168.1.255');
$ticket->AddCustomFieldValue(Field => $cf_conditioned_by_ipaddressrange_multiple->id , Value => '192.168.1.0-192.168.1.255');

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
ok($m->login, 'logged in');

$m->get_ok('/Ticket/Modify.html?id=' . $ticket->id);
my $image_name = 'image.png';
my $image_path = RT::Test::get_relocatable_file($image_name, 'data');
my $binary_name = 'ee-rt.pdf';
my $binary_path = RT::Test::get_relocatable_file($binary_name, 'data');
$m->submit_form_ok({
    form_name => 'TicketModify',
    fields    => {
        'Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_image_single->id . '-Upload' => $image_path,
        'Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_image_multiple->id . '-Upload' => $image_path,
        'Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_binary_single->id . '-Upload' => $binary_path,
        'Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_binary_multiple->id . '-Upload' => $binary_path,
    },
});

my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->driver->ua->timeout(600);
$mjs->get($m->rt_base_url . '?user=root;pass=password');

# Condition met
$ticket->AddCustomFieldValue(Field => $cf_condition->id , Value => $cf_values->[0]->Name);
$mjs->get($m->rt_base_url . 'Ticket/Modify.html?id=' . $ticket->id);

my $ticket_cf_conditioned_by_selectbox_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_selectbox_single->id . '-Values', single => 1);
my $ticket_cf_conditioned_by_selectbox_multiple = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_selectbox_multiple->id . '-Values', single => 1);
my $ticket_cf_conditioned_by_list_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_list_single->id . '-Value', single => 1);
my $ticket_cf_conditioned_by_list_multiple = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_list_multiple->id . '-Values', single => 1);
my $ticket_cf_conditioned_by_dropdown_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_dropdown_single->id . '-Values', single => 1);
my $ticket_cf_conditioned_by_chosen_single = $mjs->by_id('Object_RT__Ticket_' . $ticket->id . '_CustomField_Grouptwo_' . $cf_conditioned_by_chosen_single->id . '_Values_chosen', single => 1);
my $ticket_cf_conditioned_by_chosen_multiple = $mjs->by_id('Object_RT__Ticket_' . $ticket->id . '_CustomField_Grouptwo_' . $cf_conditioned_by_chosen_multiple->id . '_Values_chosen', single => 1);
my $ticket_cf_conditioned_by_freeform_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_freeform_single->id . '-Value', single => 1);
my $ticket_cf_conditioned_by_freeform_multiple = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_freeform_multiple->id . '-Values', single => 1);
my $ticket_cf_conditioned_by_text_single = $mjs->xpath('//textarea[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_text_single->id . '-Values"]', single => 1);
my $ticket_cf_conditioned_by_wikitext_single = $mjs->xpath('//textarea[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_wikitext_single->id . '-Values"]', single => 1);
my $ticket_cf_conditioned_by_image_single = $mjs->xpath('//input[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_image_single->id . '-Upload"]', single => 1);
my $ticket_cf_conditioned_by_image_multiple = $mjs->xpath('//input[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_image_multiple->id . '-Upload"]', single => 1);
my $ticket_cf_conditioned_by_binary_single = $mjs->xpath('//input[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_binary_single->id . '-Upload"]', single => 1);
my $ticket_cf_conditioned_by_binary_multiple = $mjs->xpath('//input[@name="Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_binary_multiple->id . '-Upload"]', single => 1);
my $ticket_cf_conditioned_by_combobox_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_combobox_single->id . '-Value', single => 1);
my $ticket_cf_conditioned_by_autocomplete_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_autocomplete_single->id . '-Value', single => 1);
my $ticket_cf_conditioned_by_autocomplete_multiple = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_autocomplete_multiple->id . '-Values', single => 1);
my $ticket_cf_conditioned_by_date_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_date_single->id . '-Values', single => 1);
my $ticket_cf_conditioned_by_datetime_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_datetime_single->id . '-Values', single => 1);
my $ticket_cf_conditioned_by_ipaddress_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_ipaddress_single->id . '-Value', single => 1);
my $ticket_cf_conditioned_by_ipaddress_multiple = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_ipaddress_multiple->id . '-Values', single => 1);
my $ticket_cf_conditioned_by_ipaddressrange_single = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_ipaddressrange_single->id . '-Value', single => 1);
my $ticket_cf_conditioned_by_ipaddressrange_multiple = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Grouptwo-' . $cf_conditioned_by_ipaddressrange_multiple->id . '-Values', single => 1);

ok($ticket_cf_conditioned_by_selectbox_single->is_displayed, 'Show ConditionedBySelectBoxSingle CF when condition is met');
ok($ticket_cf_conditioned_by_selectbox_multiple->is_displayed, 'Show ConditionedBySelectBoxMultiple CF when condition is met');
ok($ticket_cf_conditioned_by_list_single->is_displayed, 'Show ConditionedByListSingle CF when condition is met');
ok($ticket_cf_conditioned_by_list_multiple->is_displayed, 'Show ConditionedByListMultiple CF when condition is met');
ok($ticket_cf_conditioned_by_dropdown_single->is_displayed, 'Show ConditionedByDropdownSingle CF when condition is met');
ok($ticket_cf_conditioned_by_chosen_single->is_displayed, 'Show ConditionedByChosenSingle CF when condition is met');
ok($ticket_cf_conditioned_by_chosen_multiple->is_displayed, 'Show ConditionedByChosenMultiple CF when condition is met');
ok($ticket_cf_conditioned_by_freeform_single->is_displayed, 'Show ConditionedByFreeformSingle CF when condition is met');
ok($ticket_cf_conditioned_by_freeform_multiple->is_displayed, 'Show ConditionedByFreeformMultiple CF when condition is met');
ok($ticket_cf_conditioned_by_text_single->is_displayed, 'Show ConditionedByTextSingle CF when condition is met');
ok($ticket_cf_conditioned_by_wikitext_single->is_displayed, 'Show ConditionedByWikitextSingle CF when condition is met');
ok($ticket_cf_conditioned_by_image_single->is_displayed, 'Show ConditionedByImageSingle CF when condition is met');
ok($ticket_cf_conditioned_by_image_multiple->is_displayed, 'Show ConditionedByImageMultiple CF when condition is met');
ok($ticket_cf_conditioned_by_binary_single->is_displayed, 'Show ConditionedByBinarySingle CF when condition is met');
ok($ticket_cf_conditioned_by_binary_multiple->is_displayed, 'Show ConditionedByBinaryMultiple CF when condition is met');
ok($ticket_cf_conditioned_by_combobox_single->is_displayed, 'Show ConditionedByComboboxSingle CF when condition is met');
ok($ticket_cf_conditioned_by_autocomplete_single->is_displayed, 'Show ConditionedByAutocompleteSingle CF when condition is met');
ok($ticket_cf_conditioned_by_autocomplete_multiple->is_displayed, 'Show ConditionedByAutocompleteMultiple CF when condition is met');
ok($ticket_cf_conditioned_by_date_single->is_displayed, 'Show ConditionedByDateSingle CF when condition is met');
ok($ticket_cf_conditioned_by_datetime_single->is_displayed, 'Show ConditionedByDateTimeSingle CF when condition is met');
ok($ticket_cf_conditioned_by_ipaddress_single->is_displayed, 'Show ConditionedByIPAddressSingle CF when condition is met');
ok($ticket_cf_conditioned_by_ipaddress_multiple->is_displayed, 'Show ConditionedByIPAddressMultiple CF when condition is met');
ok($ticket_cf_conditioned_by_ipaddressrange_single->is_displayed, 'Show ConditionedByIPAddressRangeSingle CF when condition is met');
ok($ticket_cf_conditioned_by_ipaddressrange_multiple->is_displayed, 'Show ConditionedByIPAddressRangeMultiple CF when condition is met');

# Update value to condition not met
my $ticket_cf_condition = $mjs->by_id('Object-RT::Ticket-' . $ticket->id . '-CustomField:Groupone-' . $cf_condition->id . '-Values', single => 1);
$mjs->field($ticket_cf_condition, $cf_values->[1]->Name);
$mjs->eval_in_page("jQuery('#Object-RT\\\\:\\\\:Ticket-" . $ticket->id . "-CustomField\\\\:Groupone-" . $cf_condition->id . "-Values').trigger('change');");
ok($ticket_cf_conditioned_by_selectbox_single->is_hidden, 'Hide ConditionedBySelectBoxSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_selectbox_multiple->is_hidden, 'Hide ConditionedBySelectBoxMultiple CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_list_single->is_hidden, 'Hide ConditionedByListSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_list_multiple->is_hidden, 'Hide ConditionedByListMultiple CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_dropdown_single->is_hidden, 'Hide ConditionedByDropdownSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_chosen_single->is_hidden, 'Hide ConditionedByChosenSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_chosen_multiple->is_hidden, 'Hide ConditionedByChosenMultiple CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_freeform_single->is_hidden, 'Hide ConditionedByFreeformSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_freeform_multiple->is_hidden, 'Hide ConditionedByFreeformMultiple CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_text_single->is_hidden, 'Hide ConditionedByTextSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_wikitext_single->is_hidden, 'Hide ConditionedByWikitextSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_image_single->is_hidden, 'Hide ConditionedByImageSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_image_multiple->is_hidden, 'Hide ConditionedByImageMultiple CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_binary_single->is_hidden, 'Hide ConditionedByBinarySingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_binary_multiple->is_hidden, 'Hide ConditionedByBinaryMultiple CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_combobox_single->is_hidden, 'Hide ConditionedByComboboxSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_autocomplete_single->is_hidden, 'Hide ConditionedByAutocompleteSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_autocomplete_multiple->is_hidden, 'Hide ConditionedByAutocompleteMultiple CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_date_single->is_hidden, 'Hide ConditionedByDateSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_datetime_single->is_hidden, 'Hide ConditionedByDateTimeSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_ipaddress_single->is_hidden, 'Hide ConditionedByIPAddressSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_ipaddress_multiple->is_hidden, 'Hide ConditionedByIPAddressMultiple CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_ipaddressrange_single->is_hidden, 'Hide ConditionedByIPAddressRangeSingle CF when condition is updated to not met');
ok($ticket_cf_conditioned_by_ipaddressrange_multiple->is_hidden, 'Hide ConditionedByIPAddressRangeMultiple CF when condition is updated to not met');
