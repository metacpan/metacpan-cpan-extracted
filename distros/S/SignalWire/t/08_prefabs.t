#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use_ok('SignalWire::Prefabs::InfoGatherer');
use_ok('SignalWire::Prefabs::Survey');
use_ok('SignalWire::Prefabs::Receptionist');
use_ok('SignalWire::Prefabs::FAQBot');
use_ok('SignalWire::Prefabs::Concierge');

# ============================================================
# 1. InfoGatherer construction
# ============================================================
subtest 'InfoGatherer construction' => sub {
    my $agent = SignalWire::Prefabs::InfoGatherer->new(
        questions => [
            { key_name => 'full_name', question_text => 'What is your full name?' },
            { key_name => 'email',     question_text => 'What is your email?', confirm => 1 },
        ],
    );
    is($agent->name, 'info_gatherer', 'default name');
    is($agent->route, '/info_gatherer', 'default route');
    ok(exists $agent->tools->{start_questions}, 'start_questions tool registered');
    ok(exists $agent->tools->{submit_answer}, 'submit_answer tool registered');
    ok($agent->prompt_has_section('Information Gathering'), 'prompt section added');

    # Check global data
    my $gdata = $agent->global_data;
    is(scalar @{$gdata->{questions}}, 2, 'questions in global data');
    is($gdata->{question_index}, 0, 'question_index starts at 0');
};

# ============================================================
# 2. InfoGatherer SWML rendering
# ============================================================
subtest 'InfoGatherer render_swml' => sub {
    my $agent = SignalWire::Prefabs::InfoGatherer->new(
        questions => [
            { key_name => 'name', question_text => 'Your name?' },
        ],
    );
    my $swml = $agent->render_swml;
    is($swml->{version}, '1.0.0', 'SWML version');
    my @ai = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    ok(scalar @ai >= 1, 'AI verb present');
    ok(exists $ai[0]{ai}{SWAIG}{functions}, 'functions in SWAIG');
};

# ============================================================
# 3. InfoGatherer tool execution
# ============================================================
subtest 'InfoGatherer tool execution' => sub {
    my $agent = SignalWire::Prefabs::InfoGatherer->new(
        questions => [
            { key_name => 'name', question_text => 'What is your name?' },
        ],
    );

    my $result = $agent->on_function_call('start_questions', {}, {});
    ok(defined $result, 'start_questions returns result');

    my $answer = $agent->on_function_call('submit_answer', { answer => 'John' }, {});
    ok(defined $answer, 'submit_answer returns result');
};

# ============================================================
# 4. Survey construction
# ============================================================
subtest 'Survey construction' => sub {
    my $agent = SignalWire::Prefabs::Survey->new(
        survey_name      => 'Satisfaction Survey',
        survey_questions => [
            { id => 'q1', text => 'Rate our service', type => 'rating', scale => 5, required => 1 },
            { id => 'q2', text => 'Any comments?',    type => 'open_ended', required => 0 },
        ],
        introduction => 'Welcome to our survey.',
    );
    is($agent->name, 'survey', 'default name');
    is($agent->route, '/survey', 'default route');
    ok(exists $agent->tools->{submit_survey_answer}, 'survey tool registered');
    ok($agent->prompt_has_section('Survey Introduction'), 'survey intro section');
    ok($agent->prompt_has_section('Survey Questions'), 'survey questions section');
};

# ============================================================
# 5. Survey SWML rendering
# ============================================================
subtest 'Survey render_swml' => sub {
    my $agent = SignalWire::Prefabs::Survey->new(
        survey_name      => 'Test Survey',
        survey_questions => [
            { id => 'q1', text => 'Question?', type => 'rating', scale => 5, required => 1 },
        ],
    );
    my $swml = $agent->render_swml;
    is($swml->{version}, '1.0.0', 'version');
    my @ai = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    ok(scalar @ai >= 1, 'AI verb present');
};

# ============================================================
# 6. Receptionist construction
# ============================================================
subtest 'Receptionist construction' => sub {
    my $agent = SignalWire::Prefabs::Receptionist->new(
        departments => [
            { name => 'sales',   description => 'For purchasing',    number => '+15551235555' },
            { name => 'support', description => 'For tech help',     number => '+15551236666' },
        ],
        greeting => 'Welcome to Acme Corp!',
    );
    is($agent->name, 'receptionist', 'default name');
    is($agent->route, '/receptionist', 'default route');
    ok(exists $agent->tools->{transfer_to_department}, 'transfer tool registered');
    ok($agent->prompt_has_section('Receptionist Role'), 'role section added');

    my $gdata = $agent->global_data;
    is(scalar @{$gdata->{departments}}, 2, 'departments in global data');
};

# ============================================================
# 7. Receptionist transfer tool
# ============================================================
subtest 'Receptionist transfer' => sub {
    my $agent = SignalWire::Prefabs::Receptionist->new(
        departments => [
            { name => 'sales', description => 'Sales dept', number => '+15551235555' },
        ],
    );

    my $result = $agent->on_function_call('transfer_to_department', { department => 'sales' }, {});
    ok(defined $result, 'transfer returns result');
};

# ============================================================
# 8. FAQBot construction
# ============================================================
subtest 'FAQBot construction' => sub {
    my $agent = SignalWire::Prefabs::FAQBot->new(
        faqs => [
            { question => 'What is SignalWire?', answer => 'A cloud comms platform.' },
            { question => 'How much?',           answer => 'Pay-as-you-go pricing.' },
        ],
        suggest_related => 1,
    );
    is($agent->name, 'faq_bot', 'default name');
    is($agent->route, '/faq', 'default route');
    ok(exists $agent->tools->{lookup_faq}, 'lookup tool registered');
    ok($agent->prompt_has_section('Personality'), 'personality section');
    ok($agent->prompt_has_section('FAQ Knowledge Base'), 'faq knowledge section');
    ok($agent->prompt_has_section('Related Questions'), 'related questions section');
};

# ============================================================
# 9. FAQBot lookup
# ============================================================
subtest 'FAQBot lookup' => sub {
    my $agent = SignalWire::Prefabs::FAQBot->new(
        faqs => [
            { question => 'What is SignalWire?', answer => 'Cloud comms platform.' },
        ],
    );

    my $result = $agent->on_function_call('lookup_faq', { query => 'signalwire' }, {});
    ok(defined $result, 'lookup returns result');
};

# ============================================================
# 10. Concierge construction
# ============================================================
subtest 'Concierge construction' => sub {
    my $agent = SignalWire::Prefabs::Concierge->new(
        venue_name => 'Grand Hotel',
        services   => ['room service', 'spa bookings', 'restaurant reservations'],
        amenities  => {
            pool => { hours => '7 AM - 10 PM', location => '2nd Floor' },
            gym  => { hours => '24 hours',     location => '3rd Floor' },
        },
        hours_of_operation => {
            Monday => '9 AM - 5 PM',
            Tuesday => '9 AM - 5 PM',
        },
        special_instructions => ['VIP guests get priority'],
    );
    is($agent->name, 'concierge', 'default name');
    is($agent->route, '/concierge', 'default route');
    ok(exists $agent->tools->{check_availability}, 'availability tool registered');
    ok($agent->prompt_has_section('Concierge Role'), 'role section');
    ok($agent->prompt_has_section('Available Services'), 'services section');
    ok($agent->prompt_has_section('Amenities'), 'amenities section');
    ok($agent->prompt_has_section('Hours of Operation'), 'hours section');
    ok($agent->prompt_has_section('Special Instructions'), 'special instructions section');
};

# ============================================================
# 11. Concierge SWML rendering
# ============================================================
subtest 'Concierge render_swml' => sub {
    my $agent = SignalWire::Prefabs::Concierge->new(
        venue_name => 'Test Hotel',
        services   => ['room service'],
        amenities  => { pool => { hours => '9-5' } },
    );
    my $swml = $agent->render_swml;
    is($swml->{version}, '1.0.0', 'version');
    my @ai = grep { exists $_->{ai} } @{ $swml->{sections}{main} };
    ok(scalar @ai >= 1, 'AI verb present');
    ok(exists $ai[0]{ai}{global_data}, 'global data present');
    is($ai[0]{ai}{global_data}{venue_name}, 'Test Hotel', 'venue name in global data');
};

# ============================================================
# 12. All prefabs have psgi_app
# ============================================================
subtest 'all prefabs have psgi_app' => sub {
    my @prefabs = (
        SignalWire::Prefabs::InfoGatherer->new(
            questions => [{ key_name => 'n', question_text => 'Name?' }],
        ),
        SignalWire::Prefabs::Survey->new(
            survey_name      => 'Test',
            survey_questions => [{ id => 'q1', text => 'Q?', type => 'rating', scale => 5, required => 1 }],
        ),
        SignalWire::Prefabs::Receptionist->new(
            departments => [{ name => 'sales', description => 'Sales', number => '+1555' }],
        ),
        SignalWire::Prefabs::FAQBot->new(
            faqs => [{ question => 'Q?', answer => 'A.' }],
        ),
        SignalWire::Prefabs::Concierge->new(
            venue_name => 'Hotel',
            services   => ['room service'],
            amenities  => { pool => {} },
        ),
    );

    for my $prefab (@prefabs) {
        my $class = ref $prefab;
        $class =~ s/.*:://;
        my $app = $prefab->psgi_app;
        is(ref $app, 'CODE', "$class has psgi_app");
    }
};

# ============================================================
# 13. Prefabs inherit from AgentBase
# ============================================================
subtest 'prefabs inherit AgentBase' => sub {
    my $agent = SignalWire::Prefabs::InfoGatherer->new(
        questions => [{ key_name => 'n', question_text => 'Name?' }],
    );
    ok($agent->isa('SignalWire::Agent::AgentBase'), 'InfoGatherer isa AgentBase');
    ok($agent->can('render_swml'), 'has render_swml');
    ok($agent->can('add_skill'), 'has add_skill');
    ok($agent->can('define_tool'), 'has define_tool');
};

# ============================================================
# 14. Prefab with custom name/route
# ============================================================
subtest 'prefab custom name/route' => sub {
    my $agent = SignalWire::Prefabs::FAQBot->new(
        name  => 'my_faq',
        route => '/my_faq',
        faqs  => [{ question => 'Q?', answer => 'A.' }],
    );
    is($agent->name, 'my_faq', 'custom name');
    is($agent->route, '/my_faq', 'custom route');
};

done_testing;
