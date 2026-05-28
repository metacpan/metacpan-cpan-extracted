#!/usr/bin/env perl
# enumerate_surface.pl — emit a JSON snapshot of the Perl SDK's public API in
# the same shape as the porting-sdk's python_surface.json.
#
# Layer B symbol-level surface audit: walk lib/SignalWire/**/*.pm, extract
# every `package Foo::Bar;` block and the `sub name {` declarations within
# it, then translate Perl-native names to Python-reference names so
# diff_port_surface.py can line up the two surfaces without false positives.
#
# Translation rules (see the task spec):
#   * package SignalWire::Agent::AgentBase   -> module signalwire.core.agent_base,
#                                               class AgentBase
#   * sub foo                                 -> method foo (already snake_case)
#   * sub new                                 -> method __init__
#   * sub _foo                                -> skipped (Perl convention: private)
#   * AgentBase in Perl is one big class, but Python splits it across mixins
#     (prompt/tool/ai_config/auth/skill/web/state/serverless/mcp_server).
#     The translation table below routes each Perl sub to the right Python
#     home so the diff is meaningful instead of noise.
#
# Usage:
#   perl scripts/enumerate_surface.pl                      # write port_surface.json
#   perl scripts/enumerate_surface.pl --output surface.json
#   perl scripts/enumerate_surface.pl --stdout             # dump to stdout
use strict;
use warnings;
use JSON ();
use File::Find ();
use File::Spec ();
use Getopt::Long ();
use FindBin ();

# -------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------

my $REPO_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $LIB_ROOT  = File::Spec->catdir($REPO_ROOT, 'lib', 'SignalWire');

my $output_path = File::Spec->catfile($REPO_ROOT, 'port_surface.json');
my $to_stdout   = 0;
Getopt::Long::GetOptions(
    'output=s' => \$output_path,
    'stdout'   => \$to_stdout,
) or die "usage: $0 [--output PATH] [--stdout]\n";

# -------------------------------------------------------------------------
# Package -> Python module/class translation
# -------------------------------------------------------------------------
#
# For packages whose Perl-native layout matches a single Python module, this
# is a straight map. For AgentBase (a fat Moo class that Python splits into
# mixins) the mapping is per-method and handled below.
#
my %PACKAGE_TO_PY = (
    # Entry point (SignalWire.pm acts as the package-level loader)
    'SignalWire' => { module => 'signalwire', class => undef },

    # Core orchestration
    'SignalWire::Agent::AgentBase'         => { module => 'signalwire.core.agent_base',      class => 'AgentBase'    },
    'SignalWire::SWML::Service'            => { module => 'signalwire.core.swml_service',    class => 'SWMLService'  },
    'SignalWire::SWAIG::FunctionResult'    => { module => 'signalwire.core.function_result', class => 'FunctionResult' },
    'SignalWire::DataMap'                  => { module => 'signalwire.core.data_map',        class => 'DataMap'      },
    'SignalWire::Security::SessionManager'      => { module => 'signalwire.core.security.session_manager',   class => 'SessionManager' },
    'SignalWire::Security::WebhookValidator'    => { module => 'signalwire.core.security.webhook_validator', class => undef },
    'SignalWire::Security::WebhookMiddleware'   => { module => 'signalwire.core.security.webhook_middleware', class => undef },
    'SignalWire::Server::AgentServer'      => { module => 'signalwire.agent_server',         class => 'AgentServer'  },
    'SignalWire::Logging'                  => { module => 'signalwire.core.logging_config',  class => undef          },
    'SignalWire::Core::LoggingConfig'      => { module => 'signalwire.core.logging_config',  class => undef          },
    'SignalWire::Utils'                    => { module => 'signalwire.utils',                 class => undef          },
    'SignalWire::Utils::UrlValidator'      => { module => 'signalwire.utils.url_validator',    class => undef          },

    # Contexts (multiple classes in one .pm)
    'SignalWire::Contexts'                 => { module => 'signalwire.core.contexts',        class => undef          },
    'SignalWire::Contexts::Context'        => { module => 'signalwire.core.contexts',        class => 'Context'      },
    'SignalWire::Contexts::ContextBuilder' => { module => 'signalwire.core.contexts',        class => 'ContextBuilder' },
    'SignalWire::Contexts::GatherInfo'     => { module => 'signalwire.core.contexts',        class => 'GatherInfo'   },
    'SignalWire::Contexts::GatherQuestion' => { module => 'signalwire.core.contexts',        class => 'GatherQuestion' },
    'SignalWire::Contexts::Step'           => { module => 'signalwire.core.contexts',        class => 'Step'         },

    # Skills
    'SignalWire::Skills::SkillBase'        => { module => 'signalwire.core.skill_base',    class => 'SkillBase'     },
    'SignalWire::Skills::SkillManager'     => { module => 'signalwire.core.skill_manager', class => 'SkillManager'  },
    'SignalWire::Skills::SkillRegistry'    => { module => 'signalwire.skills.registry',    class => 'SkillRegistry' },

    # Built-in skills: each Perl package maps to the equivalent
    # signalwire.skills.<name>.skill module + Skill class.
    'SignalWire::Skills::Builtin::Datetime'             => { module => 'signalwire.skills.datetime.skill',             class => 'DateTimeSkill' },
    'SignalWire::Skills::Builtin::Math'                 => { module => 'signalwire.skills.math.skill',                 class => 'MathSkill' },
    'SignalWire::Skills::Builtin::WebSearch'            => { module => 'signalwire.skills.web_search.skill',           class => 'WebSearchSkill' },
    'SignalWire::Skills::Builtin::WikipediaSearch'      => { module => 'signalwire.skills.wikipedia_search.skill',     class => 'WikipediaSearchSkill' },
    'SignalWire::Skills::Builtin::WeatherApi'           => { module => 'signalwire.skills.weather_api.skill',          class => 'WeatherApiSkill' },
    'SignalWire::Skills::Builtin::Joke'                 => { module => 'signalwire.skills.joke.skill',                 class => 'JokeSkill' },
    'SignalWire::Skills::Builtin::Spider'               => { module => 'signalwire.skills.spider.skill',               class => 'SpiderSkill' },
    'SignalWire::Skills::Builtin::Datasphere'           => { module => 'signalwire.skills.datasphere.skill',           class => 'DataSphereSkill' },
    'SignalWire::Skills::Builtin::DatasphereServerless' => { module => 'signalwire.skills.datasphere_serverless.skill', class => 'DataSphereServerlessSkill' },
    'SignalWire::Skills::Builtin::NativeVectorSearch'   => { module => 'signalwire.skills.native_vector_search.skill', class => 'NativeVectorSearchSkill' },
    'SignalWire::Skills::Builtin::ApiNinjasTrivia'      => { module => 'signalwire.skills.api_ninjas_trivia.skill',    class => 'ApiNinjasTriviaSkill' },
    'SignalWire::Skills::Builtin::SwmlTransfer'         => { module => 'signalwire.skills.swml_transfer.skill',        class => 'SWMLTransferSkill' },
    'SignalWire::Skills::Builtin::GoogleMaps'           => { module => 'signalwire.skills.google_maps.skill',          class => 'GoogleMapsSkill' },
    'SignalWire::Skills::Builtin::PlayBackgroundFile'   => { module => 'signalwire.skills.play_background_file.skill', class => 'PlayBackgroundFileSkill' },
    'SignalWire::Skills::Builtin::InfoGatherer'         => { module => 'signalwire.skills.info_gatherer.skill',        class => 'InfoGathererSkill' },
    'SignalWire::Skills::Builtin::McpGateway'           => { module => 'signalwire.skills.mcp_gateway.skill',          class => 'MCPGatewaySkill' },
    'SignalWire::Skills::Builtin::ClaudeSkills'         => { module => 'signalwire.skills.claude_skills.skill',        class => 'ClaudeSkillsSkill' },
    # CustomSkills has no direct Python equivalent — it's a Perl-only harness
    # for loading user-supplied skill packages. Report it under the registry
    # namespace with a port-only class; it will surface in PORT_ADDITIONS.md.
    'SignalWire::Skills::Builtin::CustomSkills'         => { module => 'signalwire.skills.registry', class => 'CustomSkills' },

    # Prefabs
    'SignalWire::Prefabs::Concierge'    => { module => 'signalwire.prefabs.concierge',     class => 'ConciergeAgent'    },
    'SignalWire::Prefabs::FAQBot'       => { module => 'signalwire.prefabs.faq_bot',       class => 'FAQBotAgent'       },
    'SignalWire::Prefabs::InfoGatherer' => { module => 'signalwire.prefabs.info_gatherer', class => 'InfoGathererAgent' },
    'SignalWire::Prefabs::Receptionist' => { module => 'signalwire.prefabs.receptionist',  class => 'ReceptionistAgent' },
    'SignalWire::Prefabs::Survey'       => { module => 'signalwire.prefabs.survey',        class => 'SurveyAgent'       },

    # RELAY client
    'SignalWire::Relay::Client'    => { module => 'signalwire.relay.client',  class => 'RelayClient' },
    'SignalWire::Relay::Call'      => { module => 'signalwire.relay.call',    class => 'Call'        },
    'SignalWire::Relay::Message'   => { module => 'signalwire.relay.message', class => 'Message'     },
    'SignalWire::Relay::Action'    => { module => 'signalwire.relay.call',    class => 'Action'      },
    'SignalWire::Relay::Action::AI'         => { module => 'signalwire.relay.call', class => 'AIAction'         },
    'SignalWire::Relay::Action::Collect'    => { module => 'signalwire.relay.call', class => 'CollectAction'    },
    'SignalWire::Relay::Action::StandaloneCollect' => { module => 'signalwire.relay.call', class => 'StandaloneCollectAction' },
    'SignalWire::Relay::Action::Detect'     => { module => 'signalwire.relay.call', class => 'DetectAction'     },
    'SignalWire::Relay::Action::Fax'        => { module => 'signalwire.relay.call', class => 'FaxAction'        },
    'SignalWire::Relay::Action::Pay'        => { module => 'signalwire.relay.call', class => 'PayAction'        },
    'SignalWire::Relay::Action::Play'       => { module => 'signalwire.relay.call', class => 'PlayAction'       },
    'SignalWire::Relay::Action::Record'     => { module => 'signalwire.relay.call', class => 'RecordAction'     },
    'SignalWire::Relay::Action::Stream'     => { module => 'signalwire.relay.call', class => 'StreamAction'     },
    'SignalWire::Relay::Action::Tap'        => { module => 'signalwire.relay.call', class => 'TapAction'        },
    'SignalWire::Relay::Action::Transcribe' => { module => 'signalwire.relay.call', class => 'TranscribeAction' },
    'SignalWire::Relay::Event'                     => { module => 'signalwire.relay.event', class => 'RelayEvent'         },
    'SignalWire::Relay::Event::CallState'          => { module => 'signalwire.relay.event', class => 'CallStateEvent'     },
    'SignalWire::Relay::Event::CallReceive'        => { module => 'signalwire.relay.event', class => 'CallReceiveEvent'   },
    'SignalWire::Relay::Event::CallDial'           => { module => 'signalwire.relay.event', class => 'DialEvent'          },
    'SignalWire::Relay::Event::CallConnect'        => { module => 'signalwire.relay.event', class => 'ConnectEvent'       },
    'SignalWire::Relay::Event::CallPlay'           => { module => 'signalwire.relay.event', class => 'PlayEvent'          },
    'SignalWire::Relay::Event::CallRecord'         => { module => 'signalwire.relay.event', class => 'RecordEvent'        },
    'SignalWire::Relay::Event::CallCollect'        => { module => 'signalwire.relay.event', class => 'CollectEvent'       },
    'SignalWire::Relay::Event::CallDetect'         => { module => 'signalwire.relay.event', class => 'DetectEvent'        },
    'SignalWire::Relay::Event::CallFax'            => { module => 'signalwire.relay.event', class => 'FaxEvent'           },
    'SignalWire::Relay::Event::CallTap'            => { module => 'signalwire.relay.event', class => 'TapEvent'           },
    'SignalWire::Relay::Event::CallStream'         => { module => 'signalwire.relay.event', class => 'StreamEvent'        },
    'SignalWire::Relay::Event::CallTranscribe'     => { module => 'signalwire.relay.event', class => 'TranscribeEvent'    },
    'SignalWire::Relay::Event::CallPay'            => { module => 'signalwire.relay.event', class => 'PayEvent'           },
    'SignalWire::Relay::Event::CallSendDigits'     => { module => 'signalwire.relay.event', class => 'SendDigitsEvent'    },
    'SignalWire::Relay::Event::CallRefer'          => { module => 'signalwire.relay.event', class => 'ReferEvent'         },
    'SignalWire::Relay::Event::Conference'         => { module => 'signalwire.relay.event', class => 'ConferenceEvent'    },
    'SignalWire::Relay::Event::CallAI'             => { module => 'signalwire.relay.event', class => 'CallingErrorEvent'  },
    'SignalWire::Relay::Event::MessageReceive'     => { module => 'signalwire.relay.event', class => 'MessageReceiveEvent' },
    'SignalWire::Relay::Event::MessageState'       => { module => 'signalwire.relay.event', class => 'MessageStateEvent'  },
    # Perl-only events: CallDisconnect, Conference subtypes, Authorization,
    # plain Disconnect. Routed to relay.event so they surface in PORT_ADDITIONS.
    'SignalWire::Relay::Event::CallDisconnect'     => { module => 'signalwire.relay.event', class => 'CallDisconnectEvent' },
    'SignalWire::Relay::Event::AuthorizationState' => { module => 'signalwire.relay.event', class => 'AuthorizationStateEvent' },
    'SignalWire::Relay::Event::Disconnect'         => { module => 'signalwire.relay.event', class => 'DisconnectEvent' },
    'SignalWire::Relay::Constants'                 => { module => 'signalwire.relay.client', class => 'Constants' },

    # REST client
    'SignalWire::REST::RestClient'  => { module => 'signalwire.rest.client',  class => 'RestClient' },
    'SignalWire::REST::HttpClient'        => { module => 'signalwire.rest._base', class => 'HttpClient' },
    'SignalWire::REST::HttpClient::Error' => { module => 'signalwire.rest._base', class => 'SignalWireRestError' },
    'SignalWire::REST::Namespaces::Base'          => { module => 'signalwire.rest._base', class => 'BaseResource' },
    'SignalWire::REST::Namespaces::CrudResource'  => { module => 'signalwire.rest._base', class => 'CrudResource' },
    'SignalWire::REST::PhoneCallHandler'          => { module => 'signalwire.rest.call_handler', class => 'PhoneCallHandler' },
    'SignalWire::REST::Pagination'                => { module => 'signalwire.rest._pagination', class => undef },
    'SignalWire::REST::Pagination::PaginatedIterator' => { module => 'signalwire.rest._pagination', class => 'PaginatedIterator' },

    # REST: simple namespaces
    'SignalWire::REST::Namespaces::Calling'       => { module => 'signalwire.rest.namespaces.calling',    class => 'CallingNamespace' },
    'SignalWire::REST::Namespaces::Chat'          => { module => 'signalwire.rest.namespaces.chat',       class => 'ChatResource' },
    'SignalWire::REST::Namespaces::PubSub'        => { module => 'signalwire.rest.namespaces.pubsub',     class => 'PubSubResource' },
    'SignalWire::REST::Namespaces::PhoneNumbers'  => { module => 'signalwire.rest.namespaces.phone_numbers', class => 'PhoneNumbersResource' },
    'SignalWire::REST::Namespaces::Datasphere'    => { module => 'signalwire.rest.namespaces.datasphere', class => 'DatasphereNamespace' },
    'SignalWire::REST::Namespaces::Datasphere::Documents' => { module => 'signalwire.rest.namespaces.datasphere', class => 'DatasphereDocuments' },
    'SignalWire::REST::Namespaces::Project'       => { module => 'signalwire.rest.namespaces.project',    class => 'ProjectNamespace' },
    'SignalWire::REST::Namespaces::Project::Tokens' => { module => 'signalwire.rest.namespaces.project',  class => 'ProjectTokens' },

    # REST: multi-package Resources.pm splits into several namespaces
    'SignalWire::REST::Namespaces::Resources'         => { module => 'signalwire.rest._base',         class => undef },
    'SignalWire::REST::Namespaces::Addresses'         => { module => 'signalwire.rest.namespaces.addresses',         class => 'AddressesResource' },
    'SignalWire::REST::Namespaces::Queues'            => { module => 'signalwire.rest.namespaces.queues',            class => 'QueuesResource' },
    'SignalWire::REST::Namespaces::Recordings'        => { module => 'signalwire.rest.namespaces.recordings',        class => 'RecordingsResource' },
    'SignalWire::REST::Namespaces::NumberGroups'      => { module => 'signalwire.rest.namespaces.number_groups',     class => 'NumberGroupsResource' },
    'SignalWire::REST::Namespaces::VerifiedCallers'   => { module => 'signalwire.rest.namespaces.verified_callers',  class => 'VerifiedCallersResource' },
    'SignalWire::REST::Namespaces::SipProfile'        => { module => 'signalwire.rest.namespaces.sip_profile',       class => 'SipProfileResource' },
    'SignalWire::REST::Namespaces::Lookup'            => { module => 'signalwire.rest.namespaces.lookup',            class => 'LookupResource' },
    'SignalWire::REST::Namespaces::ShortCodes'        => { module => 'signalwire.rest.namespaces.short_codes',       class => 'ShortCodesResource' },
    'SignalWire::REST::Namespaces::ImportedNumbers'   => { module => 'signalwire.rest.namespaces.imported_numbers',  class => 'ImportedNumbersResource' },
    'SignalWire::REST::Namespaces::MFA'               => { module => 'signalwire.rest.namespaces.mfa',               class => 'MfaResource' },

    # REST: Logs.pm — multi-package
    'SignalWire::REST::Namespaces::Logs'              => { module => 'signalwire.rest.namespaces.logs', class => 'LogsNamespace' },
    'SignalWire::REST::Namespaces::Logs::Messages'    => { module => 'signalwire.rest.namespaces.logs', class => 'MessageLogs' },
    'SignalWire::REST::Namespaces::Logs::Voice'       => { module => 'signalwire.rest.namespaces.logs', class => 'VoiceLogs' },
    'SignalWire::REST::Namespaces::Logs::Fax'         => { module => 'signalwire.rest.namespaces.logs', class => 'FaxLogs' },
    'SignalWire::REST::Namespaces::Logs::Conferences' => { module => 'signalwire.rest.namespaces.logs', class => 'ConferenceLogs' },

    # REST: Registry.pm — multi-package
    'SignalWire::REST::Namespaces::Registry'              => { module => 'signalwire.rest.namespaces.registry', class => 'RegistryNamespace' },
    'SignalWire::REST::Namespaces::Registry::Brands'      => { module => 'signalwire.rest.namespaces.registry', class => 'RegistryBrands' },
    'SignalWire::REST::Namespaces::Registry::Campaigns'   => { module => 'signalwire.rest.namespaces.registry', class => 'RegistryCampaigns' },
    'SignalWire::REST::Namespaces::Registry::Orders'      => { module => 'signalwire.rest.namespaces.registry', class => 'RegistryOrders' },
    'SignalWire::REST::Namespaces::Registry::Numbers'     => { module => 'signalwire.rest.namespaces.registry', class => 'RegistryNumbers' },

    # REST: Compat.pm — multi-package
    'SignalWire::REST::Namespaces::Compat'               => { module => 'signalwire.rest.namespaces.compat', class => 'CompatNamespace' },
    'SignalWire::REST::Namespaces::Compat::Accounts'     => { module => 'signalwire.rest.namespaces.compat', class => 'CompatAccounts' },
    'SignalWire::REST::Namespaces::Compat::Calls'        => { module => 'signalwire.rest.namespaces.compat', class => 'CompatCalls' },
    'SignalWire::REST::Namespaces::Compat::Messages'     => { module => 'signalwire.rest.namespaces.compat', class => 'CompatMessages' },
    'SignalWire::REST::Namespaces::Compat::Faxes'        => { module => 'signalwire.rest.namespaces.compat', class => 'CompatFaxes' },
    'SignalWire::REST::Namespaces::Compat::Conferences'  => { module => 'signalwire.rest.namespaces.compat', class => 'CompatConferences' },
    'SignalWire::REST::Namespaces::Compat::PhoneNumbers' => { module => 'signalwire.rest.namespaces.compat', class => 'CompatPhoneNumbers' },
    'SignalWire::REST::Namespaces::Compat::Applications' => { module => 'signalwire.rest.namespaces.compat', class => 'CompatApplications' },
    'SignalWire::REST::Namespaces::Compat::LamlBins'     => { module => 'signalwire.rest.namespaces.compat', class => 'CompatLamlBins' },
    'SignalWire::REST::Namespaces::Compat::Queues'       => { module => 'signalwire.rest.namespaces.compat', class => 'CompatQueues' },
    'SignalWire::REST::Namespaces::Compat::Recordings'   => { module => 'signalwire.rest.namespaces.compat', class => 'CompatRecordings' },
    'SignalWire::REST::Namespaces::Compat::Transcriptions' => { module => 'signalwire.rest.namespaces.compat', class => 'CompatTranscriptions' },
    'SignalWire::REST::Namespaces::Compat::Tokens'       => { module => 'signalwire.rest.namespaces.compat', class => 'CompatTokens' },

    # REST: Fabric.pm — multi-package (Python surface under rest.namespaces.fabric)
    'SignalWire::REST::Namespaces::Fabric'                     => { module => 'signalwire.rest.namespaces.fabric', class => 'FabricNamespace' },
    'SignalWire::REST::Namespaces::Fabric::Addresses'          => { module => 'signalwire.rest.namespaces.fabric', class => 'FabricAddresses' },
    'SignalWire::REST::Namespaces::Fabric::Subscribers'        => { module => 'signalwire.rest.namespaces.fabric', class => 'SubscribersResource' },
    'SignalWire::REST::Namespaces::Fabric::Tokens'             => { module => 'signalwire.rest.namespaces.fabric', class => 'FabricTokens' },
    'SignalWire::REST::Namespaces::Fabric::GenericResources'   => { module => 'signalwire.rest.namespaces.fabric', class => 'GenericResources' },
    'SignalWire::REST::Namespaces::Fabric::SwmlWebhooks'       => { module => 'signalwire.rest.namespaces.fabric', class => 'SwmlWebhooksResource' },
    # Other Fabric::* subpackages are helpers that have no 1:1 Python
    # equivalent; they'll land in PORT_ADDITIONS.md under rest.namespaces.fabric.
    'SignalWire::REST::Namespaces::Fabric::Resource'              => { module => 'signalwire.rest.namespaces.fabric', class => 'FabricResource' },
    'SignalWire::REST::Namespaces::Fabric::AutoMaterializedWebhook' => { module => 'signalwire.rest.namespaces.fabric', class => 'AutoMaterializedWebhook' },
    'SignalWire::REST::Namespaces::Fabric::CxmlWebhooks'          => { module => 'signalwire.rest.namespaces.fabric', class => 'CxmlWebhooksResource' },
    'SignalWire::REST::Namespaces::Fabric::ResourcePUT'           => { module => 'signalwire.rest.namespaces.fabric', class => 'FabricResourcePUT' },
    'SignalWire::REST::Namespaces::Fabric::CallFlows'             => { module => 'signalwire.rest.namespaces.fabric', class => 'CallFlowsResource' },
    'SignalWire::REST::Namespaces::Fabric::ConferenceRooms'       => { module => 'signalwire.rest.namespaces.fabric', class => 'ConferenceRoomsResource' },
    'SignalWire::REST::Namespaces::Fabric::CxmlApplications'      => { module => 'signalwire.rest.namespaces.fabric', class => 'CxmlApplicationsResource' },

    # REST: Video.pm — multi-package
    'SignalWire::REST::Namespaces::Video'                    => { module => 'signalwire.rest.namespaces.video', class => 'VideoNamespace' },
    'SignalWire::REST::Namespaces::Video::Rooms'             => { module => 'signalwire.rest.namespaces.video', class => 'VideoRooms' },
    'SignalWire::REST::Namespaces::Video::RoomTokens'        => { module => 'signalwire.rest.namespaces.video', class => 'VideoRoomTokens' },
    'SignalWire::REST::Namespaces::Video::RoomSessions'      => { module => 'signalwire.rest.namespaces.video', class => 'VideoRoomSessions' },
    'SignalWire::REST::Namespaces::Video::RoomRecordings'    => { module => 'signalwire.rest.namespaces.video', class => 'VideoRoomRecordings' },
    'SignalWire::REST::Namespaces::Video::Conferences'       => { module => 'signalwire.rest.namespaces.video', class => 'VideoConferences' },
    'SignalWire::REST::Namespaces::Video::ConferenceTokens'  => { module => 'signalwire.rest.namespaces.video', class => 'VideoConferenceTokens' },
    'SignalWire::REST::Namespaces::Video::Streams'           => { module => 'signalwire.rest.namespaces.video', class => 'VideoStreams' },

    # SWML
    'SignalWire::SWML::Document' => { module => 'signalwire.core.swml_builder',  class => 'SWMLBuilder' },
    'SignalWire::SWML::Schema'   => { module => 'signalwire.utils.schema_utils', class => 'SchemaUtils' },

    # POM — typed Prompt Object Model. Python lives in ``signalwire.pom.pom``;
    # Perl mirrors the same shape under ``SignalWire::POM::*`` and projects
    # both classes back to the canonical Python paths.
    'SignalWire::POM::PromptObjectModel' => { module => 'signalwire.pom.pom', class => 'PromptObjectModel' },
    'SignalWire::POM::Section'           => { module => 'signalwire.pom.pom', class => 'Section' },
);

# -------------------------------------------------------------------------
# AgentBase method -> Python module/class router.
#
# In the Python SDK, AgentBase inherits from many mixins. Each mixin owns a
# slice of the public API. The Perl port flattens all of this into one
# SignalWire::Agent::AgentBase package, so at enumeration time we must
# re-project each method onto its Python home. This is the only way the
# diff tool can reason about surface parity.
# -------------------------------------------------------------------------
my %AGENTBASE_METHOD_TO_PY = (
    # Stays on AgentBase itself
    'new'                      => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => '__init__' },
    'get_name'                 => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'get_name' },
    'get_full_url'             => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'get_full_url' },
    'set_web_hook_url'         => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'set_web_hook_url' },
    'set_post_prompt_url'      => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'set_post_prompt_url' },
    'add_pre_answer_verb'      => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'add_pre_answer_verb' },
    'add_post_answer_verb'     => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'add_post_answer_verb' },
    'add_post_ai_verb'         => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'add_post_ai_verb' },
    'clear_pre_answer_verbs'   => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'clear_pre_answer_verbs' },
    'clear_post_answer_verbs'  => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'clear_post_answer_verbs' },
    'clear_post_ai_verbs'      => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'clear_post_ai_verbs' },
    'add_swaig_query_params'   => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'add_swaig_query_params' },
    'clear_swaig_query_params' => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'clear_swaig_query_params' },
    'on_summary'               => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'on_summary' },
    'on_debug_event'           => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'on_debug_event' },
    'enable_sip_routing'       => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'enable_sip_routing' },
    'register_sip_username'    => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'register_sip_username' },
    'auto_map_sip_usernames'   => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'auto_map_sip_usernames' },
    'add_answer_verb'          => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'add_answer_verb' },

    # PromptMixin
    'set_prompt_text'      => { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'set_prompt_text' },
    'set_post_prompt'      => { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'set_post_prompt' },
    'prompt_add_section'   => { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'prompt_add_section' },
    'prompt_add_subsection' => { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'prompt_add_subsection' },
    'prompt_add_to_section'=> { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'prompt_add_to_section' },
    'prompt_has_section'   => { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'prompt_has_section' },
    'get_prompt'           => { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'get_prompt' },
    'define_contexts'      => { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'define_contexts' },
    'reset_contexts'       => { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'reset_contexts' },
    'contexts'             => { module => 'signalwire.core.mixins.prompt_mixin', class => 'PromptMixin', method => 'contexts' },

    # ToolMixin
    'define_tool'            => { module => 'signalwire.core.mixins.tool_mixin', class => 'ToolMixin', method => 'define_tool' },
    'register_swaig_function' => { module => 'signalwire.core.mixins.tool_mixin', class => 'ToolMixin', method => 'register_swaig_function' },
    'define_tools'           => { module => 'signalwire.core.mixins.tool_mixin', class => 'ToolMixin', method => 'define_tools' },
    'on_function_call'       => { module => 'signalwire.core.mixins.tool_mixin', class => 'ToolMixin', method => 'on_function_call' },

    # AIConfigMixin
    'add_hint'                 => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'add_hint' },
    'add_hints'                => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'add_hints' },
    'add_pattern_hint'         => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'add_pattern_hint' },
    'add_language'             => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'add_language' },
    'set_languages'            => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_languages' },
    'get_language_params'      => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'get_language_params' },
    'set_language_params'      => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_language_params' },
    'add_pronunciation'        => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'add_pronunciation' },
    'set_pronunciations'       => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_pronunciations' },
    'set_param'                => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_param' },
    'set_params'               => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_params' },
    'set_global_data'          => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_global_data' },
    'update_global_data'       => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'update_global_data' },
    'set_native_functions'     => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_native_functions' },
    'set_internal_fillers'     => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_internal_fillers' },
    'add_internal_filler'      => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'add_internal_filler' },
    'enable_debug_events'      => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'enable_debug_events' },
    'add_function_include'     => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'add_function_include' },
    'set_function_includes'    => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_function_includes' },
    'set_prompt_llm_params'    => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_prompt_llm_params' },
    'set_post_prompt_llm_params' => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'set_post_prompt_llm_params' },
    'add_mcp_server'           => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'add_mcp_server' },
    'enable_mcp_server'        => { module => 'signalwire.core.mixins.ai_config_mixin', class => 'AIConfigMixin', method => 'enable_mcp_server' },

    # SkillMixin
    'add_skill'    => { module => 'signalwire.core.mixins.skill_mixin', class => 'SkillMixin', method => 'add_skill' },
    'remove_skill' => { module => 'signalwire.core.mixins.skill_mixin', class => 'SkillMixin', method => 'remove_skill' },
    'list_skills'  => { module => 'signalwire.core.mixins.skill_mixin', class => 'SkillMixin', method => 'list_skills' },
    'has_skill'    => { module => 'signalwire.core.mixins.skill_mixin', class => 'SkillMixin', method => 'has_skill' },

    # WebMixin
    'run'                         => { module => 'signalwire.core.mixins.web_mixin', class => 'WebMixin', method => 'run' },
    'serve'                       => { module => 'signalwire.core.mixins.web_mixin', class => 'WebMixin', method => 'serve' },
    'manual_set_proxy_url'        => { module => 'signalwire.core.mixins.web_mixin', class => 'WebMixin', method => 'manual_set_proxy_url' },
    'set_dynamic_config_callback' => { module => 'signalwire.core.mixins.web_mixin', class => 'WebMixin', method => 'set_dynamic_config_callback' },

    # SWMLService (extract_sip_username lives here in Python)
    'extract_sip_username' => { module => 'signalwire.core.swml_service', class => 'SWMLService', method => 'extract_sip_username' },

    # Port-only on AgentBase — will land in PORT_ADDITIONS.md
    'render_swml'          => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'render_swml' },
    'psgi_app'             => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'psgi_app' },
    'set_answer_config'    => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'set_answer_config' },
    'list_tool_names'      => { module => 'signalwire.core.agent_base', class => 'AgentBase', method => 'list_tool_names' },
);

# Package-scoped overrides for specific (package, sub) → (module, class, method)
# mappings. Used when the default (which preserves the sub's name and class
# membership) needs to be rerouted, e.g. Perl helpers that live in a different
# Python home, or when Perl had to rename to avoid a builtin.
my %METHOD_OVERRIDES = (
    # SWMLService auth methods come from AuthMixin in Python.
    'SignalWire::SWML::Service' => {
        'validate_basic_auth'         => { module => 'signalwire.core.mixins.auth_mixin', class => 'AuthMixin', method => 'validate_basic_auth' },
        'get_basic_auth_credentials'  => { module => 'signalwire.core.mixins.auth_mixin', class => 'AuthMixin', method => 'get_basic_auth_credentials' },
    },

    # Perl renamed `delete` to `delete_<resource>` because `delete` is a
    # core builtin keyword. Translate back to the Python name `delete`.
    'SignalWire::REST::Namespaces::Recordings' => {
        'delete_recording' => { module => 'signalwire.rest.namespaces.recordings', class => 'RecordingsResource', method => 'delete' },
    },
    'SignalWire::REST::Namespaces::Fabric::GenericResources' => {
        'delete_resource' => { module => 'signalwire.rest.namespaces.fabric', class => 'GenericResources', method => 'delete' },
    },
    'SignalWire::REST::Namespaces::Compat::PhoneNumbers' => {
        'delete_number' => { module => 'signalwire.rest.namespaces.compat', class => 'CompatPhoneNumbers', method => 'delete' },
    },
    'SignalWire::REST::Namespaces::Compat::Recordings' => {
        'delete_recording' => { module => 'signalwire.rest.namespaces.compat', class => 'CompatRecordings', method => 'delete' },
    },
    'SignalWire::REST::Namespaces::Compat::Tokens' => {
        'delete_token' => { module => 'signalwire.rest.namespaces.compat', class => 'CompatTokens', method => 'delete' },
    },
    'SignalWire::REST::Namespaces::Compat::Transcriptions' => {
        'delete_transcription' => { module => 'signalwire.rest.namespaces.compat', class => 'CompatTranscriptions', method => 'delete' },
    },
    'SignalWire::REST::Namespaces::Project::Tokens' => {
        'delete_token' => { module => 'signalwire.rest.namespaces.project', class => 'ProjectTokens', method => 'delete' },
    },
    'SignalWire::REST::Namespaces::Registry::Numbers' => {
        'delete_number' => { module => 'signalwire.rest.namespaces.registry', class => 'RegistryNumbers', method => 'delete' },
    },
    'SignalWire::REST::Namespaces::Video::RoomRecordings' => {
        'delete_recording' => { module => 'signalwire.rest.namespaces.video', class => 'VideoRoomRecordings', method => 'delete' },
    },
    'SignalWire::REST::Namespaces::Video::Streams' => {
        'delete_stream' => { module => 'signalwire.rest.namespaces.video', class => 'VideoStreams', method => 'delete' },
    },
    # CrudResource base class's delete_resource maps to the Python `delete`.
    'SignalWire::REST::Namespaces::CrudResource' => {
        'delete_resource' => { module => 'signalwire.rest._base', class => 'CrudResource', method => 'delete' },
    },
    'SignalWire::REST::HttpClient' => {
        'delete_request' => { module => 'signalwire.rest._base', class => 'HttpClient', method => 'delete' },
    },

    # Perl uses `to_hash` where Python uses `to_dict`. Python hash-like
    # APIs are dicts; the Perl convention is hashref, hence the name. For
    # surface parity, translate back to the Python name.
    'SignalWire::Contexts::Context' => {
        'to_hash' => { module => 'signalwire.core.contexts', class => 'Context', method => 'to_dict' },
    },
    'SignalWire::Contexts::ContextBuilder' => {
        'to_hash' => { module => 'signalwire.core.contexts', class => 'ContextBuilder', method => 'to_dict' },
    },
    'SignalWire::Contexts::GatherInfo' => {
        'to_hash' => { module => 'signalwire.core.contexts', class => 'GatherInfo', method => 'to_dict' },
    },
    'SignalWire::Contexts::GatherQuestion' => {
        'to_hash' => { module => 'signalwire.core.contexts', class => 'GatherQuestion', method => 'to_dict' },
    },
    'SignalWire::Contexts::Step' => {
        'to_hash' => { module => 'signalwire.core.contexts', class => 'Step', method => 'to_dict' },
    },
    'SignalWire::SWAIG::FunctionResult' => {
        'to_hash' => { module => 'signalwire.core.function_result', class => 'FunctionResult', method => 'to_dict' },
    },
    # POM Section/PromptObjectModel: same to_hash -> to_dict rename as the
    # Contexts/FunctionResult families above; the underlying serialised
    # shape is identical between languages.
    'SignalWire::POM::Section' => {
        'to_hash' => { module => 'signalwire.pom.pom', class => 'Section', method => 'to_dict' },
    },
    'SignalWire::POM::PromptObjectModel' => {
        'to_hash' => { module => 'signalwire.pom.pom', class => 'PromptObjectModel', method => 'to_dict' },
    },

    # SWML::Service auth methods come from AuthMixin in Python (declared
    # above); ContextBuilder validate is an AgentBase-internal helper not
    # surfaced in Python.

    # Logging helpers: Perl exports debug/info/warn/error as package-level
    # functions; in Python they come via get_logger() -> logger.debug etc.
    # The Perl module also has get_logger, so keep debug/info/warn/error
    # recorded under logging_config where they currently are (they'll
    # surface as port additions, which is fine).
);

# Force implicit __init__ for packages whose Python equivalent records
# __init__ on the class (Python AST sees an explicit `def __init__`), but
# whose Perl class extends another Moo class so our is_moo_root detector
# doesn't flag them. This list was derived from which Python classes
# expose __init__ in python_surface.json.
my %FORCE_IMPLICIT_INIT = map { $_ => 1 } (
    # REST core
    'SignalWire::REST::RestClient',
    'SignalWire::REST::HttpClient',
    'SignalWire::REST::HttpClient::Error',
    'SignalWire::REST::Namespaces::Base',

    # REST namespaces whose top-level class or resource declares __init__
    'SignalWire::REST::Namespaces::Calling',
    'SignalWire::REST::Namespaces::Chat',
    'SignalWire::REST::Namespaces::PubSub',
    'SignalWire::REST::Namespaces::PhoneNumbers',
    'SignalWire::REST::Namespaces::Addresses',
    'SignalWire::REST::Namespaces::Queues',
    'SignalWire::REST::Namespaces::Recordings',
    'SignalWire::REST::Namespaces::NumberGroups',
    'SignalWire::REST::Namespaces::VerifiedCallers',
    'SignalWire::REST::Namespaces::SipProfile',
    'SignalWire::REST::Namespaces::Lookup',
    'SignalWire::REST::Namespaces::ShortCodes',
    'SignalWire::REST::Namespaces::ImportedNumbers',
    'SignalWire::REST::Namespaces::MFA',
    'SignalWire::REST::Namespaces::Logs',
    'SignalWire::REST::Namespaces::Registry',
    'SignalWire::REST::Namespaces::Compat',
    'SignalWire::REST::Namespaces::Compat::Accounts',
    'SignalWire::REST::Namespaces::Compat::PhoneNumbers',
    'SignalWire::REST::Namespaces::Fabric',
    'SignalWire::REST::Namespaces::Fabric::Tokens',
    'SignalWire::REST::Namespaces::Datasphere',
    'SignalWire::REST::Namespaces::Datasphere::Documents',
    'SignalWire::REST::Namespaces::Video',
    'SignalWire::REST::Namespaces::Project',
    'SignalWire::REST::Namespaces::Project::Tokens',
    'SignalWire::REST::Pagination::PaginatedIterator',

    # Server / security / skills
    'SignalWire::Server::AgentServer',
    'SignalWire::Security::SessionManager',
    'SignalWire::Security::WebhookValidator',
    'SignalWire::Security::WebhookMiddleware',
    'SignalWire::Skills::SkillBase',
    'SignalWire::Skills::SkillManager',
    'SignalWire::Skills::SkillRegistry',

    # SWML
    'SignalWire::SWML::Document',   # SWMLBuilder in Python
    'SignalWire::SWML::Service',
    'SignalWire::SWML::Schema',     # SchemaUtils in Python

    # Prefabs (Python records __init__ on each prefab agent)
    'SignalWire::Prefabs::Concierge',
    'SignalWire::Prefabs::FAQBot',
    'SignalWire::Prefabs::InfoGatherer',
    'SignalWire::Prefabs::Receptionist',
    'SignalWire::Prefabs::Survey',

    # Skills that Python declares __init__ on the top-level Skill class
    # (GoogleMaps, WebSearch have __init__ on the INNER helper class, not
    # the skill itself — don't list those here).
    'SignalWire::Skills::Builtin::ApiNinjasTrivia',
    'SignalWire::Skills::Builtin::PlayBackgroundFile',
    'SignalWire::Skills::Builtin::Spider',
    'SignalWire::Skills::Builtin::WeatherApi',
);

# Suppress implicit __init__ emission. Relay::Event subclasses and the
# Constants holder are dataclasses in Python: they don't expose __init__
# as a public method. Matching that keeps the diff meaningful.
my %SKIP_IMPLICIT_INIT = map { $_ => 1 } (
    'SignalWire::Relay::Constants',
    # Relay::Event and every Relay::Event::Foo subclass
    'SignalWire::Relay::Event',
    'SignalWire::Relay::Event::CallState',
    'SignalWire::Relay::Event::CallReceive',
    'SignalWire::Relay::Event::CallDial',
    'SignalWire::Relay::Event::CallConnect',
    'SignalWire::Relay::Event::CallDisconnect',
    'SignalWire::Relay::Event::CallPlay',
    'SignalWire::Relay::Event::CallRecord',
    'SignalWire::Relay::Event::CallCollect',
    'SignalWire::Relay::Event::CallDetect',
    'SignalWire::Relay::Event::CallFax',
    'SignalWire::Relay::Event::CallTap',
    'SignalWire::Relay::Event::CallStream',
    'SignalWire::Relay::Event::CallTranscribe',
    'SignalWire::Relay::Event::CallPay',
    'SignalWire::Relay::Event::CallSendDigits',
    'SignalWire::Relay::Event::CallRefer',
    'SignalWire::Relay::Event::Conference',
    'SignalWire::Relay::Event::CallAI',
    'SignalWire::Relay::Event::MessageReceive',
    'SignalWire::Relay::Event::MessageState',
    'SignalWire::Relay::Event::AuthorizationState',
    'SignalWire::Relay::Event::Disconnect',

    # CLI-only container packages with no instantiable class contract
    # (we don't emit them here, but listed for future use).
);

# Subs to always skip: private helpers, Moo plumbing, __PACKAGE__ accessors.
my %SKIP_SUB = map { $_ => 1 } qw(
    BUILD
    BUILDARGS
    DEMOLISH
    DESTROY
    import
    AUTOLOAD
);

# Filenames to exclude from the walk.
my %SKIP_FILE = ();

# -------------------------------------------------------------------------
# Parser — one pass per file, tracking current package.
# -------------------------------------------------------------------------
sub parse_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    my @packages;        # list of { name => ..., subs => [...], _seen => {...} }
    my $current;
    while (my $line = <$fh>) {
        if ($line =~ /^\s*package\s+([A-Za-z_][\w:]*)\s*;/) {
            my $pkg = $1;
            $current = {
                name         => $pkg,
                subs         => [],
                _seen        => {},
                uses_moo     => 0,
                has_extends  => 0,
            };
            push @packages, $current;
            next;
        }
        # Detect `use Moo;` / `use Moo::Role;`
        if ($line =~ /^\s*use\s+Moo(?:::Role)?\b/) {
            $current->{uses_moo} = 1 if $current;
            next;
        }
        # Detect `extends 'Foo';` (Moo inheritance)
        if ($line =~ /^\s*extends\s+['"\(]/) {
            $current->{has_extends} = 1 if $current;
            # fall through — no 'next' needed, but nothing else to match
        }
        # Only match sub definitions at column 0. Indented subs are almost
        # always inside string heredocs/POD examples or nested coderefs, not
        # package-level public API. This keeps false positives out.
        if ($line =~ /^sub\s+([A-Za-z_]\w*)\b/) {
            my $sub_name = $1;
            next unless $current;   # sub before any package — ignore
            # Perl convention: leading underscore = private. Dunder
            # methods (e.g. __iter__, __next__, __init__) are public
            # protocol hooks and should be emitted.
            next if $sub_name =~ /^_/ && !($sub_name =~ /^__\w+__$/);
            next if $SKIP_SUB{$sub_name};
            next if $current->{_seen}{$sub_name}++;  # de-dup overloaded defs
            push @{ $current->{subs} }, $sub_name;
        }
    }
    close $fh;

    # A Moo "root" class uses Moo directly with no `extends`. Those classes
    # own their own __init__ and should emit it; subclasses/roles inherit it
    # and shouldn't repeat it in the surface.
    for my $p (@packages) {
        $p->{is_moo_root} = ($p->{uses_moo} && !$p->{has_extends}) ? 1 : 0;
    }
    return \@packages;
}

# -------------------------------------------------------------------------
# Projection — walk the files, project each (package, sub) into Python-shape
# surface buckets.
# -------------------------------------------------------------------------
sub collect_surface {
    my ($lib_root) = @_;
    my %modules;   # module => { classes => { CLS => [...] }, functions => [...] }

    my $ensure = sub {
        my ($mod) = @_;
        $modules{$mod} //= { classes => {}, functions => [] };
        return $modules{$mod};
    };
    my $record_class_method = sub {
        my ($mod, $class, $method) = @_;
        my $bucket = $ensure->($mod);
        $bucket->{classes}{$class} //= [];
        my %seen = map { $_ => 1 } @{ $bucket->{classes}{$class} };
        push @{ $bucket->{classes}{$class} }, $method unless $seen{$method};
    };
    my $record_function = sub {
        my ($mod, $fn) = @_;
        my $bucket = $ensure->($mod);
        my %seen = map { $_ => 1 } @{ $bucket->{functions} };
        push @{ $bucket->{functions} }, $fn unless $seen{$fn};
    };
    my $record_class_only = sub {
        my ($mod, $class) = @_;
        my $bucket = $ensure->($mod);
        $bucket->{classes}{$class} //= [];
    };

    my @pm_files;
    File::Find::find({
        wanted => sub { push @pm_files, $File::Find::name if /\.pm$/ },
        no_chdir => 1,
    }, $lib_root);
    # SignalWire.pm at the lib root
    my $top = File::Spec->catfile(File::Spec->catdir($lib_root, '..'), 'SignalWire.pm');
    push @pm_files, $top if -f $top;

    for my $file (sort @pm_files) {
        next if $SKIP_FILE{$file};
        my $packages = parse_file($file);
        for my $pkg (@$packages) {
            my $pkg_name = $pkg->{name};
            my $info = $PACKAGE_TO_PY{$pkg_name};
            if (!$info) {
                warn "enumerate_surface: package $pkg_name not in translation map (file: $file)\n";
                next;
            }
            my $mod   = $info->{module};
            my $class = $info->{class};

            # Record the class even if there are no subs, to keep the shape
            # consistent with Python's output for empty-class definitions.
            $record_class_only->($mod, $class) if defined $class;

            # Emit implicit `__init__` only when the Perl class is a Moo root
            # (use Moo; with no extends) — that matches Python's AST-based
            # enumerator which records `__init__` on the class that defines
            # it, not on subclasses that inherit it. Packages opting in via
            # %FORCE_IMPLICIT_INIT get one too.
            if (defined $class && !$SKIP_IMPLICIT_INIT{$pkg_name}) {
                my $has_explicit_new = grep { $_ eq 'new' } @{ $pkg->{subs} };
                my $should_emit_init = 0;
                if (!$has_explicit_new) {
                    if ($FORCE_IMPLICIT_INIT{$pkg_name}) {
                        $should_emit_init = 1;
                    } elsif ($pkg->{is_moo_root}) {
                        $should_emit_init = 1;
                    }
                }
                if ($should_emit_init) {
                    if ($pkg_name eq 'SignalWire::Agent::AgentBase') {
                        my $r = $AGENTBASE_METHOD_TO_PY{new};
                        $record_class_method->($r->{module}, $r->{class}, $r->{method}) if $r;
                    } else {
                        $record_class_method->($mod, $class, '__init__');
                    }
                }
            }

            for my $sub (@{ $pkg->{subs} }) {
                # Special-case routing for AgentBase flat class.
                if ($pkg_name eq 'SignalWire::Agent::AgentBase') {
                    my $route = $AGENTBASE_METHOD_TO_PY{$sub};
                    if ($route) {
                        $record_class_method->($route->{module}, $route->{class}, $route->{method});
                    } else {
                        warn "enumerate_surface: AgentBase sub '$sub' has no routing entry; recording on AgentBase\n";
                        $record_class_method->('signalwire.core.agent_base', 'AgentBase', $sub);
                    }
                    next;
                }

                # Per-package overrides
                if (my $ov = $METHOD_OVERRIDES{$pkg_name}{$sub}) {
                    $record_class_method->($ov->{module}, $ov->{class}, $ov->{method});
                    next;
                }

                # Default: project onto declared (module, class)
                my $method = ($sub eq 'new') ? '__init__' : $sub;
                if (defined $class) {
                    $record_class_method->($mod, $class, $method);
                } else {
                    # Module-level (no class)
                    $record_function->($mod, $method);
                }
            }
        }
    }

    # Normalise: sort method arrays and function arrays.
    for my $mod (keys %modules) {
        my $bucket = $modules{$mod};
        for my $c (keys %{ $bucket->{classes} }) {
            my @m = sort @{ $bucket->{classes}{$c} };
            $bucket->{classes}{$c} = \@m;
        }
        my @f = sort @{ $bucket->{functions} };
        $bucket->{functions} = \@f;
    }

    return \%modules;
}

# -------------------------------------------------------------------------
# git sha for provenance (optional)
# -------------------------------------------------------------------------
sub git_sha {
    my $out = eval { `git -C '$REPO_ROOT' rev-parse HEAD 2>/dev/null` };
    return 'N/A' unless defined $out;
    chomp $out;
    return $out || 'N/A';
}

# -------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------
my $modules = collect_surface($LIB_ROOT);

my $snapshot = {
    version        => '1',
    generated_from => 'signalwire-perl @ ' . git_sha(),
    perl_version   => sprintf('%vd', $^V),
    modules        => $modules,
};

my $json = JSON->new->utf8->canonical->pretty->encode($snapshot);

if ($to_stdout) {
    print $json;
} else {
    open my $fh, '>', $output_path or die "open $output_path: $!";
    print {$fh} $json;
    close $fh;
    print STDERR "wrote $output_path\n";
}
