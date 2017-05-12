package Module::ThirdParty;
use strict;
use Exporter ();

{
    no strict;
    $VERSION   = "0.27";
    @ISA       = qw< Exporter >;
    @EXPORT    = qw< is_3rd_party module_information >;
    @EXPORT_OK = qw< provides all_modules >;
}

=head1 NAME

Module::ThirdParty - Provide information for 3rd party modules (outside CPAN)

=head1 VERSION

Version 0.27

=head1 SYNOPSIS

    use Module::ThirdParty;

    if (is_3rd_party($module)) {
        my $info = module_information($module);
        print "$module is a known third-party Perl module\n", 
              " -> included in $info->{name} ($info->{url})\n",
              " -> made by $info->{author} ($info->{author_url})\n"
    }
    else {
        print "$module is not a known third-party Perl module\n"
    }
        

=head1 DESCRIPTION

Perl modules can be roughly classified in three categories: 

=over 4

=item *

core modules, included with the standard Perl distribution; 

=item *

CPAN modules, available from any CPAN mirror; 

=item *

third-party modules, including modules publicly available on the 
Internet (outside CPAN) and "closed" modules available only through 
commercial licenses. They are therefore the very tip of the iceberg,
the most visible part of the DarkPAN, which is all the Perl code,
public or non-public, used in the world.

=back

The list of core modules is provided by C<Module::CoreList> and the 
list of CPAN modules is in the file 
L<http://www.cpan.org/modules/02packages.details.txt.gz> and provided 
by modules like C<CPANPLUS>, but there was no module that listed 
third-party modules. This module tries to address this need by providing 
such a list. 

Why bother in the first place? Because some CPAN modules 
specify such third-party software. Therefore installing them may not 
be as easy as other CPAN modules because one must first find and 
manually install the prerequisites. The aim of C<Module::ThirdParty> 
is to provide basic information to installer shells like C<CPANPLUS> 
and to give hints to the user. 

Note that there is also another category of modules regarding 
dependencies problems: the ghost modules. Those are modules no longer 
present on the CPAN, but which still haunt it from old PREREQS. They 
can be found in the BackPAN graveyard, for which the only map is 
C<Parse::BACKPAN::Packages>. 

=cut 

# third party modules information
my %softwares = (
    'Zeus-ModPerl' => {
        name => 'Zeus Web Server Perl Extensions', 
        url => 'http://support.zeus.com/', 
        author => 'Zeus Technology', 
        author_url => 'http://www.zeus.com/', 
        modules => [qw(
            ui::admin::Admin::Admin_Security
            ui::web::Access::Bandwidth_Throttling
            ui::web::Access::htaccess_Support
            ui::web::Access::Referrer_Checking
            ui::web::Access::Restricting_Access
            ui::web::Access::Users_and_Groups
            ui::web::Access::Users_and_Groups::Edit_group
            ui::web::Access::Users_and_Groups::Edit_user
            ui::web::Add_Ons::Imagemaps
            ui::web::Add_Ons::Search_Engine
            ui::web::Admin::Preferences
            ui::web::Admin::SSL_Certificates
            ui::web::Admin::Technical_Support
            ui::web::Admin::Technical_Support::Review
            ui::web::API_Support::CGI::General
            ui::web::API_Support::CGI::Sandboxing
            ui::web::API_Support::FastCGI
            ui::web::API_Support::ISAPI
            ui::web::API_Support::Java_Servlets
            ui::web::API_Support::NSAPI
            ui::web::API_Support::Perl
            ui::web::API_Support::SSI
            ui::web::API_Support::ZDAC
            ui::web::Change::Config_Difference
            ui::web::Change::Review_Modification
            ui::web::Create::Group
            ui::web::Create::Virtual_Server
            ui::web::Delete
            ui::web::File_Handling::Content_Compression
            ui::web::File_Handling::Content_Negotiation
            ui::web::File_Handling::File_Upload
            ui::web::File_Handling::MIME_Types
            ui::web::General::Advanced_Settings
            ui::web::General::Config_Summary
            ui::web::General::Fundamentals
            ui::web::General::Processing_Summary
            ui::web::General::SSL_Security::Client_Certificates
            ui::web::General::SSL_Security::General
            ui::web::Information
            ui::web::Machines::Configuration
            ui::web::Machines::Current_Connections
            ui::web::Machines::Grouped_Reports
            ui::web::Machines::Licensing
            ui::web::Machines::Licensing::Update
            ui::web::Machines::Monitoring::ChooseCounters
            ui::web::Machines::Real_Time_Monitoring
            ui::web::Machines::Traffic_History
            ui::web::MainIndex
            ui::web::Monitoring::Error_Handling
            ui::web::Monitoring::Forensic_Logging
            ui::web::Monitoring::Request_Logging
            ui::web::Monitoring::Statistics_Gathering
            ui::web::Monitoring::User_Tracking
            ui::web::Protection::Connection_Limiting
            ui::web::Protection::Edit_Rule
            ui::web::Protection::General
            ui::web::Protection::Request_Filtering
            ui::web::Protection::Request_Filtering::Rule
            ui::web::Protection::Request_Filtering::Upload
            ui::web::Protection::Review_Modification
            ui::web::SSL::VICE
            ui::web::Subservers::Subservers
            ui::web::Third_Party::FrontPage
            ui::web::Third_Party::PHP
            ui::web::Traffic_History::Cluster_Traffic_Analysis
            ui::web::Traffic_History::Traffic_Overview
            ui::web::Traffic_History::Website_Comparison
            ui::web::URL_Handling::Directory_Requests
            ui::web::URL_Handling::Gateway
            ui::web::URL_Handling::Handlers
            ui::web::URL_Handling::Home_Directories
            ui::web::URL_Handling::Request_Rewriting
            ui::web::URL_Handling::Request_Rewriting::ModRewriteConvert
            ui::web::URL_Handling::Response_Headers
            ui::web::URL_Handling::Spelling_Correction
            ui::web::URL_Handling::URL_Mappings
            Zeus::Admin::AdminVSConfig
            Zeus::Admin::AdminVSStorage
            Zeus::Admin::UIComponents
            Zeus::CGI
            Zeus::ConfigErrors
            Zeus::ConfigStorageControl
            Zeus::Diverter
            Zeus::Dumper
            Zeus::Execute
            Zeus::Exporter
            Zeus::FastCGI
            Zeus::Form
            Zeus::GroupConfig
            Zeus::HTMLTemplater
            Zeus::HTMLUtils
            Zeus::I18N
            Zeus::KeyValueConfig
            Zeus::KeyValueConfigFile
            Zeus::MD5
            Zeus::Menu
            Zeus::ModPerl
            Zeus::ModPerl::Connection
            Zeus::ModPerl::Constants
            Zeus::ModPerl::Cookie
            Zeus::ModPerl::FakeRequest
            Zeus::ModPerl::File
            Zeus::ModPerl::HeaderTable
            Zeus::ModPerl::Include
            Zeus::ModPerl::Log
            Zeus::ModPerl::NotesTable
            Zeus::ModPerl::PerlRun
            Zeus::ModPerl::Registry
            Zeus::ModPerl::RegistryLoader
            Zeus::ModPerl::Reload
            Zeus::ModPerl::Request
            Zeus::ModPerl::Server
            Zeus::ModPerl::SSI
            Zeus::ModPerl::Symbol
            Zeus::ModPerl::Table
            Zeus::ModPerl::URI
            Zeus::ModPerl::Util
            Zeus::MultiConfigs
            Zeus::PDF
            Zeus::PEM
            Zeus::PreferencesConfig
            Zeus::PreferencesStorage
            Zeus::Section
            Zeus::SSLSet
            Zeus::SSLSets
            Zeus::SSLStorage
            Zeus::TempFile
            Zeus::TimeLocal
            Zeus::UIComponents
            Zeus::Util
            Zeus::VICE
            Zeus::Web::AccessRule
            Zeus::Web::AMP
            Zeus::Web::Cipher
            Zeus::Web::Deployer
            Zeus::Web::DynamicConfig
            Zeus::Web::DynamicConfigs
            Zeus::Web::DynamicConfigSanity
            Zeus::Web::FrontPage
            Zeus::Web::GUI
            Zeus::Web::GzipHash
            Zeus::Web::HookData
            Zeus::Web::KeyToPage
            Zeus::Web::License
            Zeus::Web::MappingUI
            Zeus::Web::PerlStartup
            Zeus::Web::RequestRewriteSupport
            Zeus::Web::Storage_FS
            Zeus::Web::SubserverHash
            Zeus::Web::SupportInfo
            Zeus::Web::UIComponents
            Zeus::Web::VSCommand
            Zeus::Web::VSConfig
            Zeus::Web::VSConfigs
            Zeus::Web::VSConfigSanity
            Zeus::Web::VSDeploymentConfig
            Zeus::Web::VSDeploymentStorage
            Zeus::Web::VSGroupConfig
            Zeus::Web::VSGroupStorage
            Zeus::Web::VSStatus
            Zeus::Web::VSStorage
            Zeus::Web::ZWSStat
            Zeus::Web::ZWSStat::Descriptions
            Zeus::Widget
            Zeus::ZInstall::Cluster
            Zeus::ZInstall::Common
            Zeus::ZInstall::Products
            Zeus::ZInstall::Questions
            Zeus::ZInstall::TkInstall
            Zeus::ZInstall::ZInstall
            Zeus::ZSSL
            ZeusOS
            ZWS4Conf
        )]
    }, 

    'Subversion' => {
        name => 'Subversion', 
        url => 'http://subversion.tigris.org/', 
        author => 'Subversion', 
        author_url => 'http://subversion.tigris.org/', 
        modules => [qw(
            SVN::Base
            SVN::Client
            SVN::Core
            SVN::Delta
            SVN::Fs
            SVN::Ra
            SVN::Repos
            SVN::Wc
        )]
    }, 

    'VCP' => {
        name => 'Version CoPy (VCP)', 
        url => 'http://search.cpan.org/dist/VCP-autrijus-snapshot/', 
        author => 'Perforce', 
        author_url => 'http://www.perforce.com/', 
        modules => [qw(
            RevML::Doctype
            RevML::Writer
            VCP
            VCP::DB
            VCP::Logger
            VCP::Plugin
            VCP::Source
            VCP::UI
            VCP::Utils
        )]
    }, 

    'RT' => {
        name => 'Request Tracker', 
        url => 'http://bestpractical.com/rt/', 
        author => 'Best Practical', 
        author_url => 'http://bestpractical.com/', 
        modules => [qw(
            RT
            RT::ACE
            RT::ACL
            RT::Action::AutoOpen
            RT::Action::Autoreply
            RT::Action::CreateTickets
            RT::Action::EscalatePriority
            RT::Action::Generic
            RT::Action::Notify
            RT::Action::NotifyAsComment
            RT::Action::RecordComment
            RT::Action::RecordCorrespondence
            RT::Action::ResolveMembers
            RT::Action::SendEmail
            RT::Action::SetPriority
            RT::Action::UserDefined
            RT::Attachment
            RT::Attachments
            RT::Attribute
            RT::Attributes
            RT::Base
            RT::CachedGroupMember
            RT::CachedGroupMembers
            RT::Condition::AnyTransaction
            RT::Condition::BeforeDue
            RT::Condition::Generic
            RT::Condition::Overdue
            RT::Condition::OwnerChange
            RT::Condition::PriorityChange
            RT::Condition::PriorityExceeds
            RT::Condition::QueueChange
            RT::Condition::StatusChange
            RT::Condition::UserDefined
            RT::CurrentUser
            RT::CustomField
            RT::CustomFields
            RT::CustomFieldValue
            RT::CustomFieldValues
            RT::Date
            RT::EmailParser
            RT::Group
            RT::GroupMember
            RT::GroupMembers
            RT::Groups
            RT::Handle
            RT::I18N
            RT::I18N::cs
            RT::I18N::i_default
            RT::Interface::CLI
            RT::Interface::Email
            RT::Interface::Email::Auth::GnuPG
            RT::Interface::Email::Auth::MailFrom
            RT::Interface::Email::Filter::SpamAssassin
            RT::Interface::REST
            RT::Interface::Web
            RT::Interface::Web::Handler
            RT::Link
            RT::Links
            RT::ObjectCustomField
            RT::ObjectCustomFields
            RT::ObjectCustomFieldValue
            RT::ObjectCustomFieldValues
            RT::Principal
            RT::Principals
            RT::Queue
            RT::Queues
            RT::Record
            RT::Scrip
            RT::ScripAction
            RT::ScripActions
            RT::ScripCondition
            RT::ScripConditions
            RT::Scrips
            RT::Search::ActiveTicketsInQueue
            RT::SearchBuilder
            RT::Search::FromSQL
            RT::Search::Generic
            RT::System
            RT::Template
            RT::Templates
            RT::Ticket
            RT::Tickets
            RT::Transaction
            RT::Transactions
            RT::URI
            RT::URI::base
            RT::URI::fsck_com_rt
            RT::User
            RT::Users
        )]
    }, 

    'OTRS' => {
        name => 'Open Ticket Request System', 
        url => 'http://otrs.org/', 
        author => 'OTRS Team', 
        author_url => 'http://otrs.org/', 
        modules => [qw(
            Kernel::Config
            Kernel::Config::Defaults
            Kernel::Language
            Kernel::Language::bb
            Kernel::Language::bg
            Kernel::Language::cz
            Kernel::Language::de
            Kernel::Language::en
            Kernel::Language::es
            Kernel::Language::fi
            Kernel::Language::fr
            Kernel::Language::hu
            Kernel::Language::it
            Kernel::Language::nb_NO
            Kernel::Language::nl
            Kernel::Language::pl
            Kernel::Language::pt
            Kernel::Language::pt_BR
            Kernel::Language::ru
            Kernel::Language::sv
            Kernel::Language::xx_AgentZoom
            Kernel::Language::xx_Custom
            Kernel::Language::zh_CN
            Kernel::Modules::Admin
            Kernel::Modules::AdminAttachment
            Kernel::Modules::AdminAutoResponse
            Kernel::Modules::AdminCustomerUser
            Kernel::Modules::AdminCustomerUserGroup
            Kernel::Modules::AdminEmail
            Kernel::Modules::AdminGenericAgent
            Kernel::Modules::AdminGroup
            Kernel::Modules::AdminLog
            Kernel::Modules::AdminNotification
            Kernel::Modules::AdminPackageManager
            Kernel::Modules::AdminPGP
            Kernel::Modules::AdminPOP3
            Kernel::Modules::AdminPostMasterFilter
            Kernel::Modules::AdminQueue
            Kernel::Modules::AdminQueueAutoResponse
            Kernel::Modules::AdminQueueResponses
            Kernel::Modules::AdminResponse
            Kernel::Modules::AdminResponseAttachment
            Kernel::Modules::AdminRole
            Kernel::Modules::AdminRoleGroup
            Kernel::Modules::AdminRoleUser
            Kernel::Modules::AdminSalutation
            Kernel::Modules::AdminSelectBox
            Kernel::Modules::AdminSession
            Kernel::Modules::AdminSignature
            Kernel::Modules::AdminSMIME
            Kernel::Modules::AdminState
            Kernel::Modules::AdminSysConfig
            Kernel::Modules::AdminSystemAddress
            Kernel::Modules::AdminUser
            Kernel::Modules::AdminUserGroup
            Kernel::Modules::AgentBook
            Kernel::Modules::AgentCalendarSmall
            Kernel::Modules::AgentInfo
            Kernel::Modules::AgentLinkObject
            Kernel::Modules::AgentLookup
            Kernel::Modules::AgentPreferences
            Kernel::Modules::AgentSpelling
            Kernel::Modules::AgentTicketAttachment
            Kernel::Modules::AgentTicketBounce
            Kernel::Modules::AgentTicketBulk
            Kernel::Modules::AgentTicketClose
            Kernel::Modules::AgentTicketCompose
            Kernel::Modules::AgentTicketCustomer
            Kernel::Modules::AgentTicketCustomerFollowUp
            Kernel::Modules::AgentTicketEmail
            Kernel::Modules::AgentTicketForward
            Kernel::Modules::AgentTicketFreeText
            Kernel::Modules::AgentTicketHistory
            Kernel::Modules::AgentTicketLock
            Kernel::Modules::AgentTicketMailbox
            Kernel::Modules::AgentTicketMerge
            Kernel::Modules::AgentTicketMove
            Kernel::Modules::AgentTicketNote
            Kernel::Modules::AgentTicketOwner
            Kernel::Modules::AgentTicketPending
            Kernel::Modules::AgentTicketPhone
            Kernel::Modules::AgentTicketPlain
            Kernel::Modules::AgentTicketPrint
            Kernel::Modules::AgentTicketPriority
            Kernel::Modules::AgentTicketQueue
            Kernel::Modules::AgentTicketSearch
            Kernel::Modules::AgentTicketStatusView
            Kernel::Modules::AgentTicketZoom
            Kernel::Modules::AgentZoom
            Kernel::Modules::CustomerAccept
            Kernel::Modules::CustomerCalendarSmall
            Kernel::Modules::CustomerFAQ
            Kernel::Modules::CustomerPreferences
            Kernel::Modules::CustomerTicketAttachment
            Kernel::Modules::CustomerTicketMessage
            Kernel::Modules::CustomerTicketOverView
            Kernel::Modules::CustomerTicketSearch
            Kernel::Modules::CustomerTicketZoom
            Kernel::Modules::CustomerZoom
            Kernel::Modules::FAQ
            Kernel::Modules::FAQCategory
            Kernel::Modules::FAQLanguage
            Kernel::Modules::Installer
            Kernel::Modules::PublicFAQ
            Kernel::Modules::SystemStats
            Kernel::Modules::SystemStatsGeneric
            Kernel::Modules::Test
            Kernel::Output::HTML::Agent
            Kernel::Output::HTML::ArticleAttachmentDownload
            Kernel::Output::HTML::ArticleAttachmentHTMLViewer
            Kernel::Output::HTML::ArticleCheckPGP
            Kernel::Output::HTML::ArticleCheckSMIME
            Kernel::Output::HTML::ArticleComposeCrypt
            Kernel::Output::HTML::ArticleComposeSign
            Kernel::Output::HTML::Customer
            Kernel::Output::HTML::CustomerNewTicketQueueSelectionGeneric
            Kernel::Output::HTML::Generic
            Kernel::Output::HTML::NavBarLockedTickets
            Kernel::Output::HTML::NavBarModuleAdmin
            Kernel::Output::HTML::NavBarTicketBulkAction
            Kernel::Output::HTML::NotificationAgentOnline
            Kernel::Output::HTML::NotificationAgentTicket
            Kernel::Output::HTML::NotificationAgentTicketSeen
            Kernel::Output::HTML::NotificationCharsetCheck
            Kernel::Output::HTML::NotificationCustomerOnline
            Kernel::Output::HTML::NotificationUIDCheck
            Kernel::Output::HTML::OutputFilterActiveElement
            Kernel::Output::HTML::PreferencesCustomQueue
            Kernel::Output::HTML::PreferencesGeneric
            Kernel::Output::HTML::PreferencesLanguage
            Kernel::Output::HTML::PreferencesPassword
            Kernel::Output::HTML::PreferencesPGP
            Kernel::Output::HTML::PreferencesSMIME
            Kernel::Output::HTML::PreferencesTheme
            Kernel::Output::HTML::TicketMenuGeneric
            Kernel::Output::HTML::TicketMenuLock
            Kernel::System::Auth
            Kernel::System::Auth::DB
            Kernel::System::Auth::HTTPBasicAuth
            Kernel::System::Auth::LDAP
            Kernel::System::Auth::Radius
            Kernel::System::AuthSession
            Kernel::System::AuthSession::DB
            Kernel::System::AuthSession::FS
            Kernel::System::AuthSession::IPC
            Kernel::System::AutoResponse
            Kernel::System::CheckItem
            Kernel::System::Config
            Kernel::System::Crypt
            Kernel::System::Crypt::PGP
            Kernel::System::Crypt::SMIME
            Kernel::System::CustomerAuth
            Kernel::System::CustomerAuth::DB
            Kernel::System::CustomerAuth::HTTPBasicAuth
            Kernel::System::CustomerAuth::LDAP
            Kernel::System::CustomerAuth::Radius
            Kernel::System::CustomerGroup
            Kernel::System::CustomerUser
            Kernel::System::CustomerUser::DB
            Kernel::System::CustomerUser::LDAP
            Kernel::System::CustomerUser::Preferences::DB
            Kernel::System::DB
            Kernel::System::DB::db2
            Kernel::System::DB::maxdb
            Kernel::System::DB::mysql
            Kernel::System::DB::oracle
            Kernel::System::DB::postgresql
            Kernel::System::Email
            Kernel::System::EmailParser
            Kernel::System::Email::Sendmail
            Kernel::System::Email::SMTP
            Kernel::System::Encode
            Kernel::System::FAQ
            Kernel::System::FileTemp
            Kernel::System::GenericAgent
            Kernel::System::GenericAgent::AutoPriorityIncrease
            Kernel::System::GenericAgent::NotifyAgentGroupOfCustomQueue
            Kernel::System::Group
            Kernel::System::LinkObject
            Kernel::System::LinkObject::FAQ
            Kernel::System::LinkObject::Ticket
            Kernel::System::Lock
            Kernel::System::Log
            Kernel::System::Log::File
            Kernel::System::Log::SysLog
            Kernel::System::Main
            Kernel::System::Notification
            Kernel::System::Package
            Kernel::System::Permission
            Kernel::System::PID
            Kernel::System::POP3Account
            Kernel::System::PostMaster
            Kernel::System::PostMaster::DestQueue
            Kernel::System::PostMaster::Filter
            Kernel::System::PostMaster::Filter::AgentInterface
            Kernel::System::PostMaster::Filter::CMD
            Kernel::System::PostMaster::Filter::Match
            Kernel::System::PostMaster::Filter::MatchDBSource
            Kernel::System::PostMaster::FollowUp
            Kernel::System::PostMaster::LoopProtection
            Kernel::System::PostMaster::LoopProtection::DB
            Kernel::System::PostMaster::LoopProtection::FS
            Kernel::System::PostMaster::NewTicket
            Kernel::System::PostMaster::Reject
            Kernel::System::Priority
            Kernel::System::Queue
            Kernel::System::SearchProfile
            Kernel::System::Spelling
            Kernel::System::State
            Kernel::System::Stats::AccountedTime
            Kernel::System::Stats::NewTickets
            Kernel::System::Stats::StateAction
            Kernel::System::Stats::TicketOverview
            Kernel::System::StdAttachment
            Kernel::System::StdResponse
            Kernel::System::SystemAddress
            Kernel::System::Ticket
            Kernel::System::Ticket::Article
            Kernel::System::Ticket::ArticleStorageDB
            Kernel::System::Ticket::ArticleStorageFS
            Kernel::System::Ticket::CustomerPermission::CustomerIDCheck
            Kernel::System::Ticket::CustomerPermission::CustomerUserIDCheck
            Kernel::System::Ticket::CustomerPermission::GroupCheck
            Kernel::System::Ticket::Event::Test
            Kernel::System::Ticket::IndexAccelerator::RuntimeDB
            Kernel::System::Ticket::IndexAccelerator::StaticDB
            Kernel::System::Ticket::Number::AutoIncrement
            Kernel::System::Ticket::Number::Date
            Kernel::System::Ticket::Number::DateChecksum
            Kernel::System::Ticket::Number::Random
            Kernel::System::Ticket::Permission::GroupCheck
            Kernel::System::Ticket::Permission::OwnerCheck
            Kernel::System::Time
            Kernel::System::User
            Kernel::System::User::Preferences::DB
            Kernel::System::Web::InterfaceAgent
            Kernel::System::Web::InterfaceCustomer
            Kernel::System::Web::InterfacePublic
            Kernel::System::Web::Request
            Kernel::System::Web::UploadCache
            Kernel::System::Web::UploadCache::DB
            Kernel::System::Web::UploadCache::FS
            Kernel::System::XML
            Kernel::System::XMLMaster
        )]
    }, 

    'SlimServer' => {
        name => 'SlimServer', 
        url => 'http://www.slimdevices.com/dev_resources.html', 
        author => 'Slim Devices', 
        author_url => 'http://www.slimdevices.com/', 
        modules => [qw(
            Slim::bootstrap
            Slim::Buttons::AlarmClock
            Slim::Buttons::Block
            Slim::Buttons::BrowseDB
            Slim::Buttons::BrowseTree
            Slim::Buttons::BrowseUPnPMediaServer
            Slim::Buttons::Common
            Slim::Buttons::Favorites
            Slim::Buttons::Home
            Slim::Buttons::Information
            Slim::Buttons::Input::Bar
            Slim::Buttons::Input::Choice
            Slim::Buttons::Input::List
            Slim::Buttons::Input::Text
            Slim::Buttons::Input::Time
            Slim::Buttons::Playlist
            Slim::Buttons::Power
            Slim::Buttons::RemoteTrackInfo
            Slim::Buttons::ScreenSaver
            Slim::Buttons::Search
            Slim::Buttons::Settings
            Slim::Buttons::SqueezeNetwork
            Slim::Buttons::Synchronize
            Slim::Buttons::TrackInfo
            Slim::Buttons::Volume
            Slim::Buttons::XMLBrowser
            Slim::Control::Command
            Slim::Control::Commands
            Slim::Control::Queries
            Slim::Control::Request
            Slim::Control::Stdio
            Slim::Display::Display
            Slim::Display::Graphics
            Slim::Display::Lib::Fonts
            Slim::Display::Lib::TextVFD
            Slim::Display::NoDisplay
            Slim::Display::Squeezebox2
            Slim::Display::SqueezeboxG
            Slim::Display::Text
            Slim::Display::Transporter
            Slim::Formats
            Slim::Formats::AIFF
            Slim::Formats::APE
            Slim::Formats::FLAC
            Slim::Formats::HTTP
            Slim::Formats::MMS
            Slim::Formats::Movie
            Slim::Formats::MP3
            Slim::Formats::Musepack
            Slim::Formats::Ogg
            Slim::Formats::Parse
            Slim::Formats::Playlists
            Slim::Formats::Playlists::ASX
            Slim::Formats::Playlists::Base
            Slim::Formats::Playlists::CUE
            Slim::Formats::Playlists::M3U
            Slim::Formats::Playlists::PLS
            Slim::Formats::Playlists::WPL
            Slim::Formats::Playlists::XML
            Slim::Formats::Playlists::XSPF
            Slim::Formats::RemoteStream
            Slim::Formats::Shorten
            Slim::Formats::Wav
            Slim::Formats::WMA
            Slim::Formats::XML
            Slim::Hardware::IR
            Slim::Hardware::mas3507d
            Slim::Hardware::mas35x9
            Slim::Music::Artwork
            Slim::Music::Import
            Slim::Music::Info
            Slim::Music::MusicFolderScan
            Slim::Music::PlaylistFolderScan
            Slim::Music::TitleFormatter
            Slim::Networking::Async
            Slim::Networking::Async::HTTP
            Slim::Networking::Async::Socket
            Slim::Networking::Async::Socket::HTTP
            Slim::Networking::Async::Socket::HTTPS
            Slim::Networking::Async::Socket::UDP
            Slim::Networking::Discovery
            Slim::Networking::mDNS
            Slim::Networking::Select
            Slim::Networking::SimpleAsyncHTTP
            Slim::Networking::SliMP3::Protocol
            Slim::Networking::SliMP3::Stream
            Slim::Networking::Slimproto
            Slim::Networking::UDP
            Slim::Networking::UPnP::ControlPoint
            Slim::Player::Client
            Slim::Player::HTTP
            Slim::Player::Pipeline
            Slim::Player::Player
            Slim::Player::Playlist
            Slim::Player::ProtocolHandlers
            Slim::Player::Protocols::HTTP
            Slim::Player::Protocols::MMS
            Slim::Player::ReplayGain
            Slim::Player::SLIMP3
            Slim::Player::SoftSqueeze
            Slim::Player::Source
            Slim::Player::Squeezebox
            Slim::Player::Squeezebox2
            Slim::Player::Sync
            Slim::Player::TranscodingHelper
            Slim::Player::Transporter
            Slim::Schema
            Slim::Schema::Age
            Slim::Schema::Album
            Slim::Schema::Comment
            Slim::Schema::Contributor
            Slim::Schema::ContributorAlbum
            Slim::Schema::ContributorTrack
            Slim::Schema::DBI
            Slim::Schema::Genre
            Slim::Schema::GenreTrack
            Slim::Schema::MetaInformation
            Slim::Schema::PageBar
            Slim::Schema::Playlist
            Slim::Schema::PlaylistTrack
            Slim::Schema::Rescan
            Slim::Schema::ResultSet::Age
            Slim::Schema::ResultSet::Album
            Slim::Schema::ResultSet::Base
            Slim::Schema::ResultSet::Contributor
            Slim::Schema::ResultSet::Genre
            Slim::Schema::ResultSet::Playlist
            Slim::Schema::ResultSet::PlaylistTrack
            Slim::Schema::ResultSet::Track
            Slim::Schema::ResultSet::Year
            Slim::Schema::Storage
            Slim::Schema::Track
            Slim::Schema::Year
            Slim::Utils::Alarms
            Slim::Utils::Cache
            Slim::Utils::ChangeNotify
            Slim::Utils::ChangeNotify::Linux
            Slim::Utils::ChangeNotify::Win32
            Slim::Utils::DateTime
            Slim::Utils::Favorites
            Slim::Utils::FileFindRule
            Slim::Utils::Firmware
            Slim::Utils::IPDetect
            Slim::Utils::MemoryUsage
            Slim::Utils::Misc
            Slim::Utils::MySQLHelper
            Slim::Utils::Network
            Slim::Utils::OSDetect
            Slim::Utils::PerfMon
            Slim::Utils::PerlRunTime
            Slim::Utils::PluginManager
            Slim::Utils::Prefs
            Slim::Utils::ProgressBar
            Slim::Utils::Scanner
            Slim::Utils::Scheduler
            Slim::Utils::SoundCheck
            Slim::Utils::SQLHelper
            Slim::Utils::Strings
            Slim::Utils::Text
            Slim::Utils::Timers
            Slim::Utils::Unicode
            Slim::Utils::UPnPMediaServer
            Slim::Utils::Validate
            Slim::Web::Graphics
            Slim::Web::HTTP
            Slim::Web::Pages
            Slim::Web::Pages::BrowseDB
            Slim::Web::Pages::BrowseTree
            Slim::Web::Pages::EditPlaylist
            Slim::Web::Pages::Favorites
            Slim::Web::Pages::History
            Slim::Web::Pages::Home
            Slim::Web::Pages::LiveSearch
            Slim::Web::Pages::Playlist
            Slim::Web::Pages::Search
            Slim::Web::Pages::Status
            Slim::Web::Setup
            Slim::Web::Template::Context
            Slim::Web::UPnPMediaServer
            Slim::Web::XMLBrowser
            Plugins::CLI
            Plugins::DateTime::Plugin
            Plugins::DigitalInput::Plugin
            Plugins::DigitalInput::ProtocolHandler
            Plugins::Health::NetTest
            Plugins::Health::Plugin
            Plugins::iTunes::Common
            Plugins::iTunes::Importer
            Plugins::iTunes::Plugin
            Plugins::Live365::Live365API
            Plugins::Live365::Plugin
            Plugins::Live365::ProtocolHandler
            Plugins::Live365::Web
            Plugins::LMA::Plugin
            Plugins::MoodLogic::Common
            Plugins::MoodLogic::Importer
            Plugins::MoodLogic::InstantMix
            Plugins::MoodLogic::MoodWheel
            Plugins::MoodLogic::Plugin
            Plugins::MoodLogic::VarietyCombo
            Plugins::MusicMagic::Common
            Plugins::MusicMagic::Importer
            Plugins::MusicMagic::Plugin
            Plugins::MusicMagic::Settings
            Plugins::Picks::Plugin
            Plugins::Podcast::Plugin
            Plugins::PreventStandby::Plugin
            Plugins::RadioIO::Plugin
            Plugins::RadioIO::ProtocolHandler
            Plugins::RadioTime::Plugin
            Plugins::RandomPlay::Plugin
            Plugins::Rescan
            Plugins::Rhapsody::Plugin
            Plugins::Rhapsody::ProtocolHandler
            Plugins::RPC
            Plugins::RS232::Plugin
            Plugins::RssNews
            Plugins::SavePlaylist
            Plugins::ShoutcastBrowser::Plugin
            Plugins::SlimTris
            Plugins::Snow
            Plugins::TT::Clients
            Plugins::TT::Prefs
            Plugins::Visualizer
            Plugins::xPL
        )]
    }, 

    'XXX' => {
        name => 'XXX', 
        url => 'http://search.cpan.org/dist/XXX/', 
        author => 'Brian Ingerson', 
        author_url => 'http://ingy.net/', 
        modules => [qw(
            XXX
        )]
    }, 

    'Perl::API' => {
        name => 'Perl::API', 
        url => 'http://search.cpan.org/dist/Perl-API/', 
        author => 'Gisle Aas', 
        author_url => 'http://gisle.aas.no/', 
        modules => [qw(
            Perl::API
        )]
    }, 

    'PerlObjCBridge' => {
        name => 'Perl/Objective-C bridge', 
        url => 'http://developer.apple.com/', 
        author => 'Apple', 
        author_url => 'http://www.apple.com/', 
        modules => [qw(
            PerlObjCBridge
            Foundation
        )]
    }, 

    'ActivePerl' => {
        name => 'ActivePerl', 
        url => 'http://aspn.activestate.com/ASPN/Perl', 
        author => 'Apple', 
        author_url => 'http://www.activestate.com/', 
        modules => [qw(
            ActivePerl
            ActiveState::Browser
            ActiveState::Bytes
            ActiveState::Color
            ActiveState::DateTime
            ActiveState::DiskUsage
            ActiveState::Duration
            ActiveState::Handy
            ActiveState::Indenter
            ActiveState::Menu
            ActiveState::ModInfo
            ActiveState::Path
            ActiveState::Prompt
            ActiveState::RelocateTree
            ActiveState::Run
            ActiveState::Scineplex
            ActiveState::StopWatch
            ActiveState::Table
            ActiveState::Win32::Shell
        )]
    }, 

    'OpenBSD-modules' => {
        name => 'OpenBSD modules', 
        url => 'http://www.openbsd.org/cgi-bin/cvsweb/src/usr.sbin/pkg_add/', 
        author => 'OpenBSD', 
        author_url => 'http://www.openbsd.org/', 
        modules => [qw(
            OpenBSD::Add
            OpenBSD::ArcCheck
            OpenBSD::CollisionReport
            OpenBSD::Delete
            OpenBSD::Dependencies
            OpenBSD::Error
            OpenBSD::Getopt
            OpenBSD::IdCache
            OpenBSD::Interactive
            OpenBSD::Mtree
            OpenBSD::PackageInfo
            OpenBSD::PackageLocation
            OpenBSD::PackageLocator
            OpenBSD::PackageName
            OpenBSD::PackageRepository
            OpenBSD::PackageRepository::Installed
            OpenBSD::PackageRepository::SCP
            OpenBSD::PackageRepository::Source
            OpenBSD::PackageRepositoryList
            OpenBSD::PackingElement
            OpenBSD::PackingList
            OpenBSD::Paths
            OpenBSD::PkgCfl
            OpenBSD::PkgConfig
            OpenBSD::PkgSpec
            OpenBSD::ProgressMeter
            OpenBSD::Replace
            OpenBSD::RequiredBy
            OpenBSD::Search
            OpenBSD::SharedItems
            OpenBSD::SharedLibs
            OpenBSD::Temp
            OpenBSD::Update
            OpenBSD::UpdateSet
            OpenBSD::Ustar
            OpenBSD::Vstat
            OpenBSD::md5
        )]
    }, 

    'W2RK-WMI' => {
        name => 'W2RK::WMI',
        url => 'http://www.microsoft.com/windows2000/techinfo/reskit/default.mspx',
        author => 'Microsoft',
        author_url => 'http://www.microsoft.com/',
        modules => [qw(
            W2RK::WMI
        )]
    }, 

    'Win32-Daemon' => {
        name => "Win32::Daemon",
        url => 'http://code.google.com/p/libwin32/source/browse/trunk/Win32-Daemon/',
        author => 'libwin32 contributors',
        author_url => 'http://code.google.com/p/libwin32/',
        modules => [qw(
            Win32::Daemon
        )]
    },

    'RothWin32' => {
        name => "Roth Consulting's Perl Contributions", 
        url => 'http://www.roth.net/perl/', 
        author => 'Roth Consulting', 
        author_url => 'http://www.roth.net/', 
        modules => [qw(
            Win32::AdminMisc
            Win32::API::Prototype
            Win32::Daemon
            Win32::Perms
            Win32::RasAdmin
            Win32::Tie::Ini
        )]
    }, 

    'Win32-Lanman' => {
        name => 'Win32::Lanman',
        url => 'http://www.cpan.org/authors/id/J/JH/JHELBERG/',
        author => 'Jens Helberg',
        author_url => 'http://www.cpan.org/authors/id/J/JH/JHELBERG/',
        modules => [qw(
            Win32::Lanman
        )]
    }, 

    'Win32-Setupsup' => {
        name => 'Win32::Setupsup',
        url => 'http://www.cpan.org/authors/id/J/JH/JHELBERG/',
        author => 'Jens Helberg',
        author_url => 'http://www.cpan.org/authors/id/J/JH/JHELBERG/',
        modules => [qw(
            Win32::Setupsup
        )]
    }, 

    'XChat-1-Perl-API' => {
        name => 'X-Chat 1.x Perl Interface (legacy)', 
        url => 'http://xchat.org/docs/xchat2-perldocs.html', 
        author => 'Peter Zelezny', 
        author_url => 'http://xchat.org/', 
        modules => [qw(
            IRC
        )]
    }, 

    'XChat-2-Perl-API' => {
        name => 'X-Chat 2.x Perl Interface', 
        url => 'http://xchat.org/docs/xchat2-perl.html', 
        author => 'Lian Wan Situ', 
        author_url => 'http://xchat.org/', 
        modules => [qw(
            Xchat
        )]
    }, 

    'OwPerlProvider' => {
        name => 'OwPerlProvider', 
        url => 'http://jason.long.name/owperl/', 
        author => 'Jason Alonzo Long', 
        author_url => 'http://jason.long.name/', 
        modules => [qw(
            Net::OpenWBEM
            Net::OpenWBEM::Client
            Net::OpenWBEM::Provider
        )]
    }, 

    'DCOP-Perl' => {
        name => 'DCOP-Perl', 
        url => 'http://websvn.kde.org/branches/KDE/3.5/kdebindings/dcopperl/', 
        author => 'KDE', 
        author_url => 'http://kde.org/', 
        modules => [qw(
            DCOP::Object
        )]
        #   DCOP        # conflicts with J/JC/JCMULLER/DCOP-*.tar.gz
    }, 

    'NoCat' => {
        name => 'NoCat', 
        url => 'http://nocat.net/', 
        author => 'Schuyler Erle & Robert Flickenger', 
        author_url => 'http://nocat.net/', 
        modules => [qw(
            NoCat
            NoCat::AuthService
            NoCat::Firewall
            NoCat::Gateway
            NoCat::Gateway::Captive
            NoCat::Gateway::Open
            NoCat::Gateway::Passive
            NoCat::Group
            NoCat::Message
            NoCat::Peer
            NoCat::Source
            NoCat::Source::DBI
            NoCat::Source::IMAP
            NoCat::Source::LDAP
            NoCat::Source::NIS
            NoCat::Source::PAM
            NoCat::Source::Passwd
            NoCat::Source::RADIUS
            NoCat::Source::Samba
            NoCat::User
        )]
    }, 

    'LibWhisker' => {
        name => 'LibWhisker', 
        url => 'http://www.wiretrip.net/rfp/lw1.asp', 
        author => 'rfp.labs', 
        author_url => 'http://www.wiretrip.net/rfp/', 
        modules => [qw(
            LW
        )]
    }, 

    'LibWhisker2' => {
        name => 'LibWhisker2', 
        url => 'http://www.wiretrip.net/rfp/lw.asp', 
        author => 'rfp.labs', 
        author_url => 'http://www.wiretrip.net/rfp/', 
        modules => [qw(
            LW2
        )]
    }, 

    'GeoPlot' => {
        name => 'GeoPlot Perl API', 
        url => 'http://www.caida.org/tools/visualization/geoplot/', 
        author => 'CAIDA', 
        author_url => 'http://www.caida.org/', 
        modules => [qw(
            GeoPlot
            GPMod::Node
            GPMod::Link
            GPMod::Key
            GPMod::Path
        )]
    }, 

    'NetGeoAPI' => {
        name => 'NetGeo API', 
        url => 'http://www.caida.org/tools/utilities/netgeo/', 
        author => 'CAIDA', 
        author_url => 'http://www.caida.org/', 
        modules => [qw(
            CAIDA::NetGeoClient
        )]
    }, 

    'Swish-e' => {
        name => 'Swish-e', 
        url => 'http://www.swish-e.org/', 
        author => 'Swish-e', 
        author_url => 'http://www.swish-e.org/', 
        modules => [qw(
            SWISH::API
        )]
    }, 

    'BackupPC' => {
        name => 'BackupPC', 
        url => 'http://backuppc.sourceforge.net/', 
        author => 'Craig Barratt', 
        author_url => 'http://backuppc.sourceforge.net/', 
        modules => [qw(
            BackupPC::Attrib
            BackupPC::CGI::AdminOptions
            BackupPC::CGI::Archive
            BackupPC::CGI::ArchiveInfo
            BackupPC::CGI::Browse
            BackupPC::CGI::DirHistory
            BackupPC::CGI::EditConfig
            BackupPC::CGI::EmailSummary
            BackupPC::CGI::GeneralInfo
            BackupPC::CGI::HostInfo
            BackupPC::CGI::Lib
            BackupPC::CGI::LOGlist
            BackupPC::CGI::Queue
            BackupPC::CGI::ReloadServer
            BackupPC::CGI::Restore
            BackupPC::CGI::RestoreFile
            BackupPC::CGI::RestoreInfo
            BackupPC::CGI::RSS
            BackupPC::CGI::StartServer
            BackupPC::CGI::StartStopBackup
            BackupPC::CGI::StopServer
            BackupPC::CGI::Summary
            BackupPC::CGI::View
            BackupPC::Config
            BackupPC::Config::Meta
            BackupPC::FileZIO
            BackupPC::Lang::de
            BackupPC::Lang::en
            BackupPC::Lang::es
            BackupPC::Lang::fr
            BackupPC::Lang::it
            BackupPC::Lang::nl
            BackupPC::Lang::pt_br
            BackupPC::Lib
            BackupPC::PoolWrite
            BackupPC::Storage
            BackupPC::Storage::Text
            BackupPC::View
            BackupPC::Xfer::Archive
            BackupPC::Xfer::BackupPCd
            BackupPC::Xfer::Rsync
            BackupPC::Xfer::RsyncDigest
            BackupPC::Xfer::RsyncFileIO
            BackupPC::Xfer::Smb
            BackupPC::Xfer::Tar
            BackupPC::Zip::FileMember
        )]
    }, 

    'VMware' => {
        name => 'VMware Perl API', 
        url => 'http://www.vmware.com/support/developer/scripting-API/', 
        author => 'VMware', 
        author_url => 'http://www.vmware.com/', 
        modules => [qw(
            VMware::Control
            VMware::Control::Server
            VMware::Control::VM
        )]
    }, 

    'Circos' => {
        name => 'Circos',
        url => 'http://mkweb.bcgsc.ca/circos/',
        author => 'Martin Krzywinski et al.',
        author_url => 'http://mkweb.bcgsc.ca/',
        modules => [qw(
            Circos
        )]
    },

    'MT' => {
        name => 'Movable Type', 
        url => 'http://www.sixapart.com/movabletype/', 
        author => 'Six Apart', 
        author_url => 'http://www.sixapart.com/', 
        modules => [qw(
            MT
            MT::App
            MT::App::CMS
            MT::App::Comments
            MT::App::NotifyList
            MT::App::Search
            MT::App::Search::Context
            MT::App::Trackback
            MT::App::Viewer
            MT::Atom
            MT::Atom::Entry
            MT::AtomServer
            MT::AtomServer::Weblog
            MT::Author
            MT::Blog
            MT::Builder
            MT::Callback
            MT::Category
            MT::ConfigMgr
            MT::DateTime
            MT::Entry
            MT::ErrorHandler
            MT::FileInfo
            MT::FileMgr
            MT::FileMgr::Local
            MT::Image
            MT::Image::ImageMagick
            MT::Image::NetPBM
            MT::ImportExport
            MT::IPBanList
            MT::L10N
            MT::L10N::en_us
            MT::Log
            MT::Mail
            MT::Notification
            MT::Object
            MT::ObjectDriver
            MT::ObjectDriver::DBI
            MT::ObjectDriver::DBI::mysql
            MT::ObjectDriver::DBI::postgres
            MT::ObjectDriver::DBI::sqlite
            MT::ObjectDriver::DBM
            MT::Permission
            MT::Placement
            MT::Plugin
            MT::PluginData
            MT::Plugin::Nofollow
            MT::Promise
            MT::Request
            MT::Sanitize
            MT::Serialize
            MT::Session
            MT::TBPing
            MT::Template
            MT::Template::Context
            MT::TemplateMap
            MT::Trackback
            MT::Util
            MT::XMLRPC
            MT::XMLRPCServer
            MT::XMLRPCServer::Util
        )]
    }, 

    'CSS-Cleaner' => {
        name => 'CSS::Cleaner', 
        url => 'http://code.sixapart.com/trac/CSS-Cleaner', 
        author => 'Six Apart', 
        author_url => 'http://www.sixapart.com/', 
        modules => [qw(
            CSS::Cleaner
        )]
    }, 

    'Devel-Gladiator' => {
        name => 'Devel::Gladiator', 
        url => 'http://code.sixapart.com/svn/Devel-Gladiator/', 
        author => 'Six Apart', 
        author_url => 'http://www.sixapart.com/', 
        modules => [qw(
            Devel::Gladiator
        )]
    }, 

    'Sprog' => {
        name => 'Sprog', 
        url => 'http://sprog.sourceforge.net/', 
        author => 'Grant McLean', 
        author_url => 'http://homepages.paradise.net.nz/gmclean1/', 
        modules => [qw(
            Sprog
            Sprog::Accessor
            Sprog::ClassFactory
            Sprog::Debug
            Sprog::Gear
            Sprog::Gear::ApacheLogParse
            Sprog::Gear::ApacheLogParse::Parser
            Sprog::Gear::CommandFilter
            Sprog::Gear::CommandIn
            Sprog::Gear::CSVSplit
            Sprog::Gear::FindReplace
            Sprog::Gear::Grep
            Sprog::Gear::ImageBorder
            Sprog::Gear::InputByLine
            Sprog::Gear::InputFromFH
            Sprog::Gear::ListToCSV
            Sprog::Gear::ListToRecord
            Sprog::Gear::LowerCase
            Sprog::GearMetadata
            Sprog::Gear::NameFields
            Sprog::Gear::OutputToFH
            Sprog::Gear::ParseHTMLTable
            Sprog::Gear::PerlBase
            Sprog::Gear::PerlCode
            Sprog::Gear::PerlCodeAP
            Sprog::Gear::PerlCodeHP
            Sprog::Gear::PerlCodePA
            Sprog::Gear::PerlCodePH
            Sprog::Gear::ReadFile
            Sprog::Gear::ReplaceFile
            Sprog::Gear::RetrieveURL
            Sprog::Gear::SelectColumns
            Sprog::Gear::SelectFields
            Sprog::Gear::SlurpFile
            Sprog::Gear::StripWhitespace
            Sprog::Gear::TemplateTT2
            Sprog::Gear::TextInput
            Sprog::Gear::TextWindow
            Sprog::Gear::UpperCase
            Sprog::Gear::WriteFile
            Sprog::GlibEventLoop
            Sprog::GtkAutoDialog
            Sprog::GtkAutoDialog::CheckButton
            Sprog::GtkAutoDialog::ColorButton
            Sprog::GtkAutoDialog::Entry
            Sprog::GtkAutoDialog::RadioButton
            Sprog::GtkAutoDialog::RadioButtonGroup
            Sprog::GtkAutoDialog::SpinButton
            Sprog::GtkAutoDialog::TextView
            Sprog::GtkEventLoop
            Sprog::GtkGearView
            Sprog::GtkGearView::Paths
            Sprog::GtkGearView::TextWindow
            Sprog::GtkView
            Sprog::GtkView::AboutDialog
            Sprog::GtkView::AlertDialog
            Sprog::GtkView::Chrome
            Sprog::GtkView::DnD
            Sprog::GtkView::HelpViewer
            Sprog::GtkView::Menubar
            Sprog::GtkView::Palette
            Sprog::GtkView::PrefsDialog
            Sprog::GtkView::Toolbar
            Sprog::GtkView::WorkBench
            Sprog::HelpParser
            Sprog::Machine
            Sprog::Machine::Scheduler
            Sprog::Preferences
            Sprog::Preferences::Unix
            Sprog::PrintProxy
            Sprog::PrintProxyTie
            Sprog::TestHelper
            Sprog::TextGearView
            Sprog::TextGearView::TextWindow
            Sprog::TextView
        )]
    }, 

    'PCE' => {
        name => 'Proton-CE', 
        url => 'http://proton-ce.sourceforge.net/', 
        author => 'Proton-CE Team', 
        author_url => 'http://proton-ce.sourceforge.net/', 
        modules => [qw(
            PCE
            PCE::App
            PCE::App::CommandList
            PCE::App::ContextMenu
            PCE::App::EditPanel
            PCE::App::EditPanel::Margin
            PCE::App::EventList
            PCE::App::Events
            PCE::App::MainToolBar
            PCE::App::Menu
            PCE::App::MenuBar
            PCE::App::SearchBar
            PCE::App::StatusBar
            PCE::App::STC
            PCE::App::TabBar
            PCE::App::ToolBar
            PCE::App::Window
            PCE::Config
            PCE::Config::Embedded
            PCE::Config::File
            PCE::Config::Global
            PCE::Config::Interface
            PCE::Dialog
            PCE::Dialog::Config
            PCE::Dialog::Exit
            PCE::Dialog::Info
            PCE::Dialog::Keymap
            PCE::Dialog::Search
            PCE::Document
            PCE::Document::Change
            PCE::Document::Internal
            PCE::Document::SyntaxMode
            PCE::Edit
            PCE::Edit::Bookmark
            PCE::Edit::Comment
            PCE::Edit::Convert
            PCE::Edit::Format
            PCE::Edit::Goto
            PCE::Edit::Search
            PCE::Edit::Select
            PCE::File
            PCE::File::IO
            PCE::File::Session
            PCE::Plugin::Demo
            PCE::Show
            syntaxhighlighter::ada
            syntaxhighlighter::as
            syntaxhighlighter::asm
            syntaxhighlighter::conf
            syntaxhighlighter::context
            syntaxhighlighter::cpp
            syntaxhighlighter::cs
            syntaxhighlighter::cs2
            syntaxhighlighter::css
            syntaxhighlighter::eiffel
            syntaxhighlighter::forth
            syntaxhighlighter::fortran
            syntaxhighlighter::html
            syntaxhighlighter::idl
            syntaxhighlighter::java
            syntaxhighlighter::js
            syntaxhighlighter::latex
            syntaxhighlighter::lisp
            syntaxhighlighter::lua
            syntaxhighlighter::nsis
            syntaxhighlighter::pascal
            syntaxhighlighter::perl
            syntaxhighlighter::php
            syntaxhighlighter::ps
            syntaxhighlighter::python
            syntaxhighlighter::ruby
            syntaxhighlighter::scheme
            syntaxhighlighter::sh
            syntaxhighlighter::sql
            syntaxhighlighter::tcl
            syntaxhighlighter::tex
            syntaxhighlighter::vb
            syntaxhighlighter::vbs
            syntaxhighlighter::xml
            syntaxhighlighter::yaml
        )]
    }, 

    'Vx' => {
        name => 'Vx', 
        url => 'http://opensource.fotango.com/software/vx/', 
        author => 'Fotango', 
        author_url => 'http://www.fotango.com/', 
        modules => [qw(
            SQL
            Vx
            Vx::Abstract
            Vx::Address
            Vx::Address::Container
            Vx::Address::Email
            Vx::Address::Postal
            Vx::Address::Telephone
            Vx::Base
            Vx::Binary
            Vx::Class::Chameleon
            Vx::Collection
            Vx::Collection::Container
            Vx::Collection::ContainerHash
            Vx::Collection::ContainerPublisheable
            Vx::Collection::Element
            Vx::Config
            Vx::Constants
            Vx::Context
            Vx::Counter
            Vx::Data
            Vx::Data::Container
            Vx::Data::Image
            Vx::Data::Null
            Vx::Data::Sound
            Vx::Datastore
            Vx::Datastore::Builder
            Vx::Datastore::Cache
            Vx::Data::Text
            Vx::Event
            Vx::Facade
            Vx::Fulfillment
            Vx::Fulfillment::Type
            Vx::Function
            Vx::Globals
            Vx::Image
            Vx::Image::Manipulation
            Vx::Image::Manipulation::Container
            Vx::Image::Manipulation::Crop
            Vx::Image::Manipulation::Handler
            Vx::Image::Manipulation::Rotate
            Vx::Image::PrintArea::Container
            Vx::Image::PrintArea::Crop
            Vx::Image::PrintArea::Element
            Vx::Image::Rendering
            Vx::Image::Util
            Vx::Init::Fotango
            Vx::Init::Fotango::Canon
            Vx::Init::Fotango::Canon::UK
            Vx::Interface::Cloneable
            Vx::Interface::Container
            Vx::Interface::Filter
            Vx::Interface::Publish
            Vx::Interface::Singleton
            Vx::Manipulation
            Vx::Manipulation::Container
            Vx::Metadata
            Vx::ObjectTree
            Vx::PathWalker
            Vx::Person
            Vx::Person::Contact
            Vx::Person::User
            Vx::Product
            Vx::Product::Container
            Vx::Product::Element
            Vx::Product::Type
            Vx::Profile
            Vx::Profile::Function
            Vx::Profile::Object
            Vx::Profile::Right
            Vx::Publication
            Vx::Purchase
            Vx::Purchase::Container
            Vx::Purchase::Element
            Vx::Purchase::Event
            Vx::Service::Account
            Vx::Service::Admin
            Vx::Service::DVD
            Vx::Service::Fulfillment
            Vx::Service::Purchase
            Vx::Service::Share
            Vx::Service::Storage
            Vx::Share
            Vx::Share::Event
            Vx::Share::Received
            Vx::Share::Sent
            Vx::SOAP
            Vx::SOAP::Daemon
            Vx::SOAP::DataFilter
            Vx::SOAP::DataStore
            Vx::SOAP::Dispatcher
            Vx::SOAP::Session
            Vx::Sound
            Vx::Sound::Manipulation
            Vx::Sound::Manipulation::Container
            Vx::Transaction::Container
            Vx::Transaction::Element
            Vx::Transaction::Processor
            Vx::Transaction::Processor::CC
            Vx::Transaction::Processor::CC::Datacash
            Vx::Transaction::Processor::Configurator
            Vx::Transaction::Processor::Configurator::Datacash
            Vx::Transaction::Processor::Null
            Vx::Upload::Event
            Vx::View
            Vx::View::Container
            Vx::View::Image
            Vx::View::Manager
            Vx::View::Sound
        )]
    }, 

    'Webmin' => {
        name => 'Webmin', 
        url => 'http://webmin.com/', 
        author => 'Jamie Cameron', 
        author_url => 'http://webmin.com/', 
        modules => [qw(
            Authen::SolarisRBAC
            Webmin::Button
            Webmin::Checkbox
            Webmin::Checkboxes
            Webmin::Columns
            Webmin::ConfirmPage
            Webmin::Date
            Webmin::DynamicBar
            Webmin::DynamicHTML
            Webmin::DynamicText
            Webmin::DynamicWait
            Webmin::ErrorPage
            Webmin::File
            Webmin::Form
            Webmin::Group
            Webmin::Icon
            Webmin::Input
            Webmin::InputTable
            Webmin::JavascriptButton
            Webmin::LinkTable
            Webmin::Menu
            Webmin::Multiline
            Webmin::OptTextarea
            Webmin::OptTextbox
            Webmin::Page
            Webmin::Password
            Webmin::PlainText
            Webmin::Properties
            Webmin::Radios
            Webmin::ResultPage
            Webmin::Section
            Webmin::Select
            Webmin::Submit
            Webmin::Table
            Webmin::TableAction
            Webmin::Tabs
            Webmin::Textarea
            Webmin::Textbox
            Webmin::Time
            Webmin::TitleList
            Webmin::Upload
            Webmin::User
        )]
    }, 

    'PerlHP' => {
        name => 'PerlHP', 
        url => 'http://wakaba.c3.cx/perlhp/', 
        author => '!WAHa.06x36', 
        author_url => 'http://wakaba.c3.cx/', 
        modules => [qw(
            PerlHP
            PerlHP::Comments
            PerlHP::Utils
        )]
    }, 

    'ClearSilver' => {
        name => 'ClearSilver', 
        url => 'http://www.clearsilver.net/', 
        author => 'Brandon Long', 
        author_url => 'http://www.fiction.net/blong/', 
        modules => [qw(
            ClearSilver
        )]
    }, 

    'TLPDriver' => {
        name => 'TLP Driver', 
        url => 'http://www.gemplus.com/techno/tlp_drivers/index.html', 
        author => 'Gemplus', 
        author_url => 'http://www.gemplus.com/', 
        modules => [qw(
            cardreader
        )]
    }, 

    'VOTable' => {
        name => 'VOTable', 
        url => 'http://www.us-vo.org/VOTable/', 
        author => 'US National Virtual Observatory', 
        author_url => 'http://www.us-vo.org/', 
        modules => [qw(
            VOTable::DOM
        )]
    }, 

    'NetVigil' => {
        name => 'NetVigil', 
        url => 'http://www.fidelia.com/products/', 
        author => 'Fidelia', 
        author_url => 'http://www.fidelia.com/', 
        # other useful link: 
        #   http://www.navya.com/
        #   http://www.navya.com/netvigil/   --  NetVigil documentation
        modules => [qw(
            NetVigil
            NetVigil::Clients
            NetVigil::Clients::SimpleServer
            NetVigil::Clients::WmiQueryDaemon
            NetVigil::Config
            NetVigil::Debug
            NetVigil::Discover::Static
            NetVigil::Discover::SNMP
            NetVigil::Discover::WMI
            NetVigil::ExternalData
            NetVigil::Message
            NetVigil::MonitorStatus
            NetVigil::NameSpace
            NetVigil::Provisioning
            NetVigil::SimpleServerClient
            NetVigil::SocketIO
        )]
    }, 

    'Metasploit' => {
        name => 'Metasploit Framework', 
        url => 'http://metasploit.com/projects/Framework/', 
        author => 'Metasploit', 
        author_url => 'http://metasploit.com/', 
        modules => [qw(
            Msf::Base
            Msf::ColPrint
            Msf::Config
            Msf::EncodedPayload
            Msf::Encoder
            Msf::Encoder::Alpha2
            Msf::Encoder::Countdown
            Msf::Encoder::JmpCallAdditive
            Msf::Encoder::None
            Msf::Encoder::OSXPPCLongXOR
            Msf::Encoder::OSXPPCLongXORTag
            Msf::Encoder::Pex
            Msf::Encoder::PexAlphaNum
            Msf::Encoder::PexFnstenvMov
            Msf::Encoder::PexFnstenvSub
            Msf::Encoder::QuackQuack
            Msf::Encoder::ShikataGaNai
            Msf::Encoder::SkyAlphaNum
            Msf::Encoder::Sparc
            Msf::Encoder::_Sparc
            Msf::Encoder::Sparc::CheckEncoder
            Msf::Encoder::XorDword
            Msf::Exploit
            Msf::Exploit::3com_3cdaemon_ftp_overflow
            Msf::Exploit::afp_loginext
            Msf::Exploit::aim_goaway
            Msf::Exploit::altn_webadmin
            Msf::Exploit::apache_chunked_win32
            Msf::Exploit::arkeia_agent_access
            Msf::Exploit::arkeia_type77_macos
            Msf::Exploit::arkeia_type77_win32
            Msf::Exploit::awstats_configdir_exec
            Msf::Exploit::backupexec_agent
            Msf::Exploit::backupexec_dump
            Msf::Exploit::backupexec_ns
            Msf::Exploit::backupexec_registry
            Msf::Exploit::badblue_ext_overflow
            Msf::Exploit::bakbone_netvault_heap
            Msf::Exploit::barracuda_img_exec
            Msf::Exploit::blackice_pam_icq
            Msf::Exploit::cabrightstor_disco
            Msf::Exploit::cabrightstor_disco_servicepc
            Msf::Exploit::cabrightstor_sqlagent
            Msf::Exploit::cabrightstor_uniagent
            Msf::Exploit::cacam_logsecurity_win32
            Msf::Exploit::cacti_graphimage_exec
            Msf::Exploit::calicclnt_getconfig
            Msf::Exploit::calicserv_getconfig
            Msf::Exploit::Credits
            Msf::Exploit::distcc_exec
            Msf::Exploit::edirectory_imonitor
            Msf::Exploit::exchange2000_xexch50
            Msf::Exploit::freeftpd_user
            Msf::Exploit::futuresoft_tftpd
            Msf::Exploit::globalscapeftp_user_input
            Msf::Exploit::gnu_mailutils_imap4d
            Msf::Exploit::google_proxystylesheet_exec
            Msf::Exploit::hpux_ftpd_preauth_list
            Msf::Exploit::hpux_lpd_exec
            Msf::Exploit::ia_webmail
            Msf::Exploit::icecast_header
            Msf::Exploit::ie_objecttype
            Msf::Exploit::ie_xp_pfv_metafile
            Msf::Exploit::iis40_htr
            Msf::Exploit::iis50_printer_overflow
            Msf::Exploit::iis50_webdav_ntdll
            Msf::Exploit::iis_fp30reg_chunked
            Msf::Exploit::iis_nsiislog_post
            Msf::Exploit::iis_source_dumper
            Msf::Exploit::iis_w3who_overflow
            Msf::Exploit::imail_imap_delete
            Msf::Exploit::imail_ldap
            Msf::Exploit::irix_lpsched_exec
            Msf::Exploit::lsass_ms04_011
            Msf::Exploit::lyris_attachment_mssql
            Msf::Exploit::mailenable_auth_header
            Msf::Exploit::mailenable_imap
            Msf::Exploit::mailenable_imap_w3c
            Msf::Exploit::maxdb_webdbm_get_overflow
            Msf::Exploit::mdaemon_imap_cram_md5
            Msf::Exploit::mercantec_softcart
            Msf::Exploit::mercury_imap
            Msf::Exploit::minishare_get_overflow
            Msf::Exploit::mozilla_compareto
            Msf::Exploit::ms05_039_pnp
            Msf::Exploit::msasn1_ms04_007_killbill
            Msf::Exploit::msmq_deleteobject_ms05_017
            Msf::Exploit::msrpc_dcom_ms03_026
            Msf::Exploit::mssql2000_preauthentication
            Msf::Exploit::mssql2000_resolution
            Msf::Exploit::netterm_netftpd_user_overflow
            Msf::Exploit::openview_connectednodes_exec
            Msf::Exploit::openview_omniback
            Msf::Exploit::oracle9i_xdb_ftp
            Msf::Exploit::oracle9i_xdb_ftp_pass
            Msf::Exploit::oracle9i_xdb_http
            Msf::Exploit::payload_handler
            Msf::Exploit::phpbb_highlight
            Msf::Exploit::php_vbulletin_template
            Msf::Exploit::php_wordpress_lastpost
            Msf::Exploit::php_xmlrpc_eval
            Msf::Exploit::poptop_negative_read
            Msf::Exploit::realserver_describe_linux
            Msf::Exploit::rsa_iiswebagent_redirect
            Msf::Exploit::samba_nttrans
            Msf::Exploit::sambar6_search_results
            Msf::Exploit::samba_trans2open
            Msf::Exploit::samba_trans2open_osx
            Msf::Exploit::samba_trans2open_solsparc
            Msf::Exploit::seattlelab_mail_55
            Msf::Exploit::sentinel_lm7_overflow
            Msf::Exploit::servu_mdtm_overflow
            Msf::Exploit::shoutcast_format_win32
            Msf::Exploit::slimftpd_list_concat
            Msf::Exploit::smb_sniffer
            Msf::Exploit::solaris_dtspcd_noir
            Msf::Exploit::solaris_kcms_readfile
            Msf::Exploit::solaris_lpd_exec
            Msf::Exploit::solaris_lpd_unlink
            Msf::Exploit::solaris_sadmind_exec
            Msf::Exploit::solaris_snmpxdmid
            Msf::Exploit::solaris_ttyprompt
            Msf::Exploit::squid_ntlm_authenticate
            Msf::Exploit::svnserve_date
            Msf::Exploit::Tester
            Msf::Exploit::trackercam_phparg_overflow
            Msf::Exploit::uow_imap4_copy
            Msf::Exploit::uow_imap4_lsub
            Msf::Exploit::ut2004_secure_linux
            Msf::Exploit::ut2004_secure_win32
            Msf::Exploit::vuln1_1
            Msf::Exploit::vuln1_2
            Msf::Exploit::vuln1_3
            Msf::Exploit::vuln1_osx
            Msf::Exploit::warftpd_165_pass
            Msf::Exploit::warftpd_165_user
            Msf::Exploit::webstar_ftp_user
            Msf::Exploit::windows_ssl_pct
            Msf::Exploit::wins_ms04_045
            Msf::Exploit::wsftp_server_503_mkd
            Msf::Exploit::zenworks_desktop_agent
            Msf::Logging
            Msf::Logo
            Msf::Module
            Msf::Nop
            Msf::Nop::Alpha
            Msf::Nop::MIPS
            Msf::Nop::Opty2
            Msf::Nop::OptyNop2
            Msf::Nop::OptyNop2Tables
            Msf::Nop::Pex
            Msf::Nop::PPC
            Msf::Nop::SPARC
            Msf::Payload
            Msf::Payload::bsd_ia32_bind
            Msf::Payload::bsd_ia32_bind_ie
            Msf::Payload::bsd_ia32_bind_stg
            Msf::Payload::bsd_ia32_exec
            Msf::Payload::bsd_ia32_findrecv
            Msf::Payload::bsd_ia32_findrecv_stg
            Msf::Payload::bsd_ia32_findsock
            Msf::Payload::bsd_ia32_reverse
            Msf::Payload::bsd_ia32_reverse_ie
            Msf::Payload::bsd_ia32_reverse_stg
            Msf::Payload::bsdi_ia32_bind
            Msf::Payload::bsdi_ia32_bind_stg
            Msf::Payload::bsdi_ia32_findsock
            Msf::Payload::bsdi_ia32_reverse
            Msf::Payload::bsdi_ia32_reverse_stg
            Msf::Payload::bsd_sparc_bind
            Msf::Payload::bsd_sparc_reverse
            Msf::Payload::cmd_generic
            Msf::Payload::cmd_interact
            Msf::Payload::cmd_irix_bind
            Msf::Payload::cmd_localshell
            Msf::Payload::cmd_sol_bind
            Msf::Payload::cmd_unix_reverse
            Msf::Payload::cmd_unix_reverse_bash
            Msf::Payload::cmd_unix_reverse_nss
            Msf::PayloadComponent::BindConnection
            Msf::PayloadComponent::BSD::BindStager
            Msf::PayloadComponent::BSD::FindRecvStager
            Msf::PayloadComponent::BSD::ia32::BindStager
            Msf::PayloadComponent::BSD::ia32::FindRecvStager
            Msf::PayloadComponent::BSD::ia32::ReverseStager
            Msf::PayloadComponent::BSD::ia32::ShellStage
            Msf::PayloadComponent::BSDi::BindStager
            Msf::PayloadComponent::BSDi::FindRecvStager
            Msf::PayloadComponent::BSDi::ia32::BindStager
            Msf::PayloadComponent::BSDi::ia32::ReverseStager
            Msf::PayloadComponent::BSDi::ia32::ShellStage
            Msf::PayloadComponent::BSDi::Payload
            Msf::PayloadComponent::BSDi::ReverseStager
            Msf::PayloadComponent::BSDi::StagePayload
            Msf::PayloadComponent::BSD::Payload
            Msf::PayloadComponent::BSD::ReverseStager
            Msf::PayloadComponent::BSD::StagePayload
            Msf::PayloadComponent::CommandPayload
            Msf::PayloadComponent::ConnectionHandler
            Msf::PayloadComponent::Console
            Msf::PayloadComponent::DoubleReverseConnection
            Msf::PayloadComponent::ExternalPayload
            Msf::PayloadComponent::FindConnection
            Msf::PayloadComponent::FindLocalShell
            Msf::PayloadComponent::FindRecvConnection
            Msf::PayloadComponent::InlineEggPayload
            Msf::PayloadComponent::Linux::BindStager
            Msf::PayloadComponent::Linux::FindRecvStager
            Msf::PayloadComponent::Linux::ia32::BindStager
            Msf::PayloadComponent::Linux::ia32::FindRecvStager
            Msf::PayloadComponent::Linux::ia32::ReverseStager
            Msf::PayloadComponent::Linux::ia32::ShellStage
            Msf::PayloadComponent::Linux::Payload
            Msf::PayloadComponent::Linux::ReverseStager
            Msf::PayloadComponent::Linux::StagePayload
            Msf::PayloadComponent::NoConnection
            Msf::PayloadComponent::OSX::BindStager
            Msf::PayloadComponent::OSX::FindRecvStager
            Msf::PayloadComponent::OSX::Payload
            Msf::PayloadComponent::OSX::ppc::BindStager
            Msf::PayloadComponent::OSX::ppc::FindRecvPeekStager
            Msf::PayloadComponent::OSX::ppc::FindRecvStager
            Msf::PayloadComponent::OSX::ppc::ReverseNFStager
            Msf::PayloadComponent::OSX::ppc::ReverseStager
            Msf::PayloadComponent::OSX::ppc::ShellStage
            Msf::PayloadComponent::OSX::ReverseStager
            Msf::PayloadComponent::OSX::StagePayload
            Msf::PayloadComponent::PassiveXConnection
            Msf::PayloadComponent::ReverseConnection
            Msf::PayloadComponent::SolarisBindStager
            Msf::PayloadComponent::SolarisFindStager
            Msf::PayloadComponent::SolarisPayload
            Msf::PayloadComponent::SolarisReverseStager
            Msf::PayloadComponent::SolarisShellStage
            Msf::PayloadComponent::SolarisStagePayload
            Msf::PayloadComponent::TextConsole
            Msf::PayloadComponent::WebConsole
            Msf::PayloadComponent::Windows::BindStager
            Msf::PayloadComponent::Windows::FindRecvStager
            Msf::PayloadComponent::Windows::ia32::BindStager
            Msf::PayloadComponent::Windows::ia32::BindStagerIE
            Msf::PayloadComponent::Windows::ia32::ExecuteCommand
            Msf::PayloadComponent::Windows::ia32::FindRecvOrdinalStager
            Msf::PayloadComponent::Windows::ia32::InjectLibStage
            Msf::PayloadComponent::Windows::ia32::InjectMeterpreterStage
            Msf::PayloadComponent::Windows::ia32::InjectVncStage
            Msf::PayloadComponent::Windows::ia32::PassiveXStager
            Msf::PayloadComponent::Windows::ia32::PipedShellStage
            Msf::PayloadComponent::Windows::ia32::ReverseOrdinalStager
            Msf::PayloadComponent::Windows::ia32::ReverseStager
            Msf::PayloadComponent::Windows::ia32::ReverseStagerIE
            Msf::PayloadComponent::Windows::ia32::ShellStage
            Msf::PayloadComponent::Windows::ia32::UploadExecStage
            Msf::PayloadComponent::Windows::PassiveXStager
            Msf::PayloadComponent::Windows::Payload
            Msf::PayloadComponent::Windows::ReverseStager
            Msf::PayloadComponent::Windows::StagePayload
            Msf::PayloadComponent::Windows::StagePayloadIE
            Msf::Payload::Empty
            Msf::Payload::generic_sparc_execve
            Msf::Payload::irix_mips_execve
            Msf::Payload::linux_ia32_adduser
            Msf::Payload::linux_ia32_bind
            Msf::Payload::linux_ia32_bind_ie
            Msf::Payload::linux_ia32_bind_stg
            Msf::Payload::linux_ia32_exec
            Msf::Payload::linux_ia32_findrecv
            Msf::Payload::linux_ia32_findrecv_stg
            Msf::Payload::linux_ia32_findsock
            Msf::Payload::linux_ia32_reverse
            Msf::Payload::linux_ia32_reverse_ie
            Msf::Payload::linux_ia32_reverse_impurity
            Msf::Payload::linux_ia32_reverse_stg
            Msf::Payload::linux_ia32_reverse_udp
            Msf::Payload::linux_ia32_reverse_xor
            Msf::Payload::linux_sparc_bind
            Msf::Payload::linux_sparc_findsock
            Msf::Payload::linux_sparc_reverse
            Msf::Payload::osx_ppc_bind
            Msf::Payload::osx_ppc_bind_stg
            Msf::Payload::osx_ppc_findrecv_peek_stg
            Msf::Payload::osx_ppc_findrecv_stg
            Msf::Payload::osx_ppc_reverse
            Msf::Payload::osx_ppc_reverse_nf_stg
            Msf::Payload::osx_ppc_reverse_stg
            Msf::Payload::solaris_ia32_bind
            Msf::Payload::solaris_ia32_findsock
            Msf::Payload::solaris_ia32_reverse
            Msf::Payload::solaris_sparc_bind
            Msf::Payload::solaris_sparc_findsock
            Msf::Payload::solaris_sparc_reverse
            Msf::Payload::win32_adduser
            Msf::Payload::win32_bind
            Msf::Payload::win32_bind_dllinject
            Msf::Payload::win32_bind_meterpreter
            Msf::Payload::win32_bind_stg
            Msf::Payload::win32_bind_stg_upexec
            Msf::Payload::win32_bind_vncinject
            Msf::Payload::win32_downloadexec
            Msf::Payload::win32_exec
            Msf::Payload::win32_findrecv_ord_meterpreter
            Msf::Payload::win32_findrecv_ord_stg
            Msf::Payload::win32_findrecv_ord_vncinject
            Msf::Payload::win32_passivex
            Msf::Payload::win32_passivex_meterpreter
            Msf::Payload::win32_passivex_stg
            Msf::Payload::win32_passivex_vncinject
            Msf::Payload::win32_reverse
            Msf::Payload::win32_reverse_dllinject
            Msf::Payload::win32_reverse_meterpreter
            Msf::Payload::win32_reverse_ord
            Msf::Payload::win32_reverse_ord_vncinject
            Msf::Payload::win32_reverse_stg
            Msf::Payload::win32_reverse_stg_ie
            Msf::Payload::win32_reverse_stg_upexec
            Msf::Payload::win32_reverse_vncinject
            Msf::Socket::RawUdp
            Msf::Socket::RawUdpBase
            Msf::Socket::Socket
            Msf::Socket::SocketBase
            Msf::Socket::SSLTcp
            Msf::Socket::SSLTcpBase
            Msf::Socket::Tcp
            Msf::Socket::TcpBase
            Msf::Socket::Udp
            Msf::Socket::UdpBase
            Msf::TextUI
            Msf::UI
            Msf::WebUI
            Pex
            Pex::Alpha
            Pex::Arkeia
            Pex::BEServerRPC
            Pex::DCERPC
            Pex::ELFInfo
            Pex::Encoder
            Pex::Encoding::XorDword
            Pex::Encoding::XorDwordFeedback
            Pex::Encoding::XorDwordFeedbackN
            Pex::Encoding::XorWord
            Pex::jBASE
            Pex::Meterpreter::Arguments
            Pex::Meterpreter::Base
            Pex::Meterpreter::Buffer
            Pex::Meterpreter::Channel
            Pex::Meterpreter::Client
            Pex::Meterpreter::Crypto::Xor
            Pex::Meterpreter::Extension::Client::Boiler
            Pex::Meterpreter::Extension::Client::Fs
            Pex::Meterpreter::Extension::Client::Net
            Pex::Meterpreter::Extension::Client::Process
            Pex::Meterpreter::Extension::Client::Sam
            Pex::Meterpreter::Extension::Client::Sys
            Pex::Meterpreter::LocalDispatch
            Pex::Meterpreter::Packet
            Pex::Meterpreter::RemoteDispatch
            Pex::MSSQL
            Pex::Nasm::Instruction
            Pex::Nasm::Nasm
            Pex::Nasm::Ndisasm
            Pex::NDR
            Pex::PEInfo
            Pex::Poly::BlockMaster
            Pex::Poly::BlockMaster::Block
            Pex::Poly::DeltaKing
            Pex::Poly::RegAssassin
            Pex::PsuedoShell
            Pex::RawPackets
            Pex::RawSocket
            Pex::Searcher
            Pex::SMB
            Pex::Socket::RawUdp
            Pex::Socket::Socket
            Pex::Socket::SSLTcp
            Pex::Socket::Tcp
            Pex::Socket::Udp
            Pex::SPARC
            Pex::Struct
            Pex::SunRPC
            Pex::Text
            Pex::Utils
            Pex::x86
            Pex::XDR
        )]
    }, 

    'perl4patrol' => {
        name => 'perl4patrol', 
        url => 'http://www.manageit.ca/p_and_s/tools/perl4patrol/perl4patrol.html', 
        author => 'ManageIt', 
        author_url => 'http://www.manageit.ca/', 
        modules => [qw(
            perl4patrol
        )]
    }, 

    'AuthCourier' => {
        name => 'SpamAssassin and Courier virtual domain management',
        url => 'http://da.andaka.org/Doku/courier-spamassassin.html',
        author => 'Dave Kliczbor',
        author_url => 'http://da.andaka.org/',
        modules => [qw(
            Mail::SpamAssassin::AuthCourier
        )]
    },

    'Directi' => {
        name => 'Directi Perl API', 
        url => 'http://manage.directi.com/kb/servlet/KBServlet/faq685.html', 
        author => 'Directi', 
        author_url => 'http://www.directi.com/', 
        modules => [qw(
            Customers
            DirectICustomerService
            DirectIDomainContact
            DirectIDomainFwdService
            DirectIDomainService
            DirectIFund
            DirectIMailFwdService
            DirectISerialiser
            DirectISerialiser12
            DirectIXMLIO
            DirectIXMLIO12
            DomainContact
            DomainFwd
            DomOrder
            DomUSContact
            ErrorTraping
            Fund
            MailFwd
            SOAPProperty
            Zone
        )]
        #   Website     # conflicts with R/RE/RETOH/Template/Website-*.tar.gz
    }, 

    'Fathom' => {
        name => 'Fathom Management Perl API', 
        url => 'http://psdn.progress.com/library/fathom/', 
        author => 'Progress Software', 
        author_url => 'http://www.progress.com/', 
        modules => [qw(
            Fathom
            Fathom::Alerts
            Fathom::ConfigAdvisor
            Fathom::Constants
            Fathom::Defaults
            Fathom::Jobs
            Fathom::Library
            Fathom::OpenEdge
            Fathom::Reports
            Fathom::Resources
            Fathom::Users
            Fathom::Utils
            Fathom::Views
            HTMLInput
            HTMLStripper
        )]
    }, 

    'Gedafe' => {
        name => 'Gedafe', 
        url => 'http://isg.ee.ethz.ch/tools/gedafe/', 
        author => 'Tobi Oetiker', 
        author_url => 'http://people.ee.ethz.ch/~oetiker/', 
        modules => [qw(
            Gedafe::Auth
            Gedafe::DB
            Gedafe::Global
            Gedafe::GUI
            Gedafe::Pearl
            Gedafe::Start
            Gedafe::Util
        )]
    }, 

    'Gossips' => {
        name => 'Gossips', 
        url => 'http://isg.ee.ethz.ch/tools/gossips/', 
        author => "ETH/DEE IT & Support Group", 
        author_url => 'http://www.ee.ethz.ch/', 
        modules => [qw(
            Authen::Challenge
            Base_Prototype
            Error_File
            Gossips_Config
            GossipsError
            Gossips_HTML
            History
            ISG::ParseConfig
            Logger
            Message
            Message_Handler
            Message_Mail
            Message_Server
            Probe_CPUTemp
            Probe_DiskS
            Probe_FileSize
            Probe_Ftp
            Probe_Load
            Probe_Logfile
            Probe_Message_Pool
            Probe_MultiPing
            Probe_Ping
            Probe_Prototype
            Probe_Server
            Scheduler
            Test_CPUTemp
            Test_DiskGraph
            Test_DiskS
            Test_Ftp
            Test_Ftp_Ping
            Test_LinkUp
            Test_Load
            Test_Logfile
            Test_MailGraph
            Test_MailWatcher
            Test_Ping
            Test_Prototype
            Test_Server
        )]
        #   Parser      # conflicts with Parrot
    }, 

    'TeTre2' => {
        name => 'Template Tree II', 
        url => 'http://isg.ee.ethz.ch/tools/tetre2/', 
        author => 'Tobi Oetiker', 
        author_url => 'http://people.ee.ethz.ch/~oetiker/', 
        modules => [qw(
            ISG::HostList
            ISG::TeTre2
        )]
    }, 

    'RRDTool' => {
        name => 'RRDTool', 
        url => 'http://oss.oetiker.ch/rrdtool/', 
        author => 'Tobi Oetiker', 
        author_url => 'http://people.ee.ethz.ch/~oetiker/', 
        modules => [qw(
            RRDp
            RRDs
        )]
    }, 

    'SNMP_Session' => {
        name => 'SNMP_Session', 
        url => 'http://www.switch.ch/misc/leinen/snmp/perl/', 
        author => 'Simon Leinen', 
        author_url => 'http://www.switch.ch/misc/leinen/', 
        modules => [qw(
            BER
            SNMP_Session
            SNMP_util
        )]
    }, 

    'MRTG' => {
        name => 'MRTG', 
        url => 'http://oss.oetiker.ch/mrtg/', 
        author => 'Tobi Oetiker', 
        author_url => 'http://people.ee.ethz.ch/~oetiker/', 
        modules => [qw(
            locales_mrtg
            MRTG_lib
        )]
    }, 

    'SmokePing' => {
        name => 'SmokePing', 
        url => 'http://oss.oetiker.ch/smokeping/', 
        author => 'Tobi Oetiker', 
        author_url => 'http://people.ee.ethz.ch/~oetiker/', 
        modules => [qw(            Smokeping
            Smokeping::ciscoRttMonMIB
            Smokeping::Examples
            Smokeping::matchers::Avgratio
            Smokeping::matchers::base
            Smokeping::matchers::Median
            Smokeping::probes::AnotherDNS
            Smokeping::probes::AnotherSSH
            Smokeping::probes::base
            Smokeping::probes::basefork
            Smokeping::probes::basevars
            Smokeping::probes::CiscoRTTMonDNS
            Smokeping::probes::CiscoRTTMonEchoICMP
            Smokeping::probes::CiscoRTTMonTcpConnect
            Smokeping::probes::Curl
            Smokeping::probes::DNS
            Smokeping::probes::EchoPing
            Smokeping::probes::EchoPingChargen
            Smokeping::probes::EchoPingDiscard
            Smokeping::probes::EchoPingHttp
            Smokeping::probes::EchoPingHttps
            Smokeping::probes::EchoPingIcp
            Smokeping::probes::EchoPingSmtp
            Smokeping::probes::FPing
            Smokeping::probes::FPing6
            Smokeping::probes::IOSPing
            Smokeping::probes::LDAP
            Smokeping::probes::passwordchecker
            Smokeping::probes::Radius
            Smokeping::probes::RemoteFPing
            Smokeping::probes::skel
            Smokeping::probes::SSH
            Smokeping::probes::TelnetIOSPing
            Smokeping::RRDtools
        )]
        #   Config::Grammar     # conflicts with D/DS/DSCHWEI/Config-Grammar-*.tar.gz
    }, 

    'RealMen' => {
        name => "Real Men Don't Click", 
        url => 'http://isg.ee.ethz.ch/tools/realmen/', 
        author => "ETH/DEE IT & Support Group", 
        author_url => 'http://www.ee.ethz.ch/', 
        modules => [qw(
            ISG::ParseConfig
            ISG::Util
            ISG::Win32::ActiveDirectory
            ISG::Win32::BootConfig
            ISG::Win32::Config
            ISG::Win32::Util
        )]
    }, 

    'BB' => {
        name => 'BB', 
        url => 'http://www.teaser.fr/~nchuche/bb/bb_pm/', 
        author => 'Nicolas Chuche', 
        author_url => 'http://www.teaser.fr/~nchuche/', 
        modules => [qw(
            BB
        )]
    }, 

    'Orabb' => {
        name => 'Orabb', 
        url => 'http://www.teaser.fr/~nchuche/bb/orabb.html', 
        author => 'Nicolas Chuche', 
        author_url => 'http://www.teaser.fr/~nchuche/', 
        modules => [qw(
            Orabb::Databases
            Orabb::Databases::Element
            Orabb::Conf
            Orabb::Files
            Orabb::Fork
            Orabb::Limits
            Orabb::Limits::Test
            Orabb::Modules
            Orabb::SGBD
            Orabb::Test
            Orabb::Utils
            Output::DaveNull
            Output::BB
            Output::Debug
            Output::Dumper
            Output::HTML
            Output::MkHosts
        )]
    }, 

    'PatrolPerl' => {
        name => 'PatrolPerl', 
        url => 'http://www.portal-to-web.de/PatrolPerl/', 
        author => 'Martin Mersberger', 
        author_url => 'http://www.portal-to-web.de/', 
        modules => [qw(
            PatrolPerl
        )]
    }, 

    'Interchange' => {
        name => 'Interchange Payment Modules', 
        url => 'http://www.interchange.rtfm.info/downloads/payments/', 
        author => 'Interchange', 
        author_url => 'http://www.interchange.rtfm.info/', 
        modules => [qw(
            Vend::Payment::AuthorizeNet
            Vend::Payment::BoA
            Vend::Payment::BusinessOnlinePayment
            Vend::Payment::CyberCash
            Vend::Payment::ICS
            Vend::Payment::ECHO
            Vend::Payment::EFSNet
            Vend::Payment::Ezic
            Vend::Payment::iTransact
            Vend::Payment::Linkpoint
            Vend::Payment::Linkpoint3
            Vend::Payment::MCVE
            Vend::Payment::Netbilling
            Vend::Payment::NetBilling2
            Vend::Payment::PRI
            Vend::Payment::ProcessNet
            Vend::Payment::Protx
            Vend::Payment::PSiGate
            Vend::Payment::Signio
            Vend::Payment::Skipjack
            Vend::Payment::TestPayment
            Vend::Payment::TCLink
            Vend::Payment::WellsFargo
        )]
    }, 

    'MIM' => {  # seems to no longer be available
        name => 'Market Information Machine', 
        #url => 'http://www.lim.com/download/download_perl_api.html', 
        url => 'http://www.lim.com/download/', 
        author => 'Logical Information Machines', 
        author_url => 'http://www.lim.com/', 
        modules => [qw(
            xmim4
        )]
    }, 

    'OpenConnect' => {
        name => 'OpenConnect', 
        url => 'http://www.paradata.com/content/developers/', 
        author => 'Paradata Systems', 
        author_url => 'http://www.paradata.com/', 
        modules => [qw(
            ACHRequest
            ACHResponse
            AdditionalField
            BatchRequest
            BatchResponse
            constants
            CountryCodes
            CreditCardRequest
            CreditCardResponse
            PayerAuthenticationRequest
            PayerAuthenticationResponse
            RecurringRequest
            RecurringResponse
            SecureHttp
            TransactionClient
            TransactionRequest
            TransactionResponse
            URLEncoder
        )]
    }, 

    'PayFlowPro' => {
        name => 'PayFlow Pro', 
        url => 'http://www.verisign.com/products-services/payment-processing/online-payment/payflow-pro/index.html', 
        author => 'VeriSign', 
        author_url => 'http://www.verisign.com/', 
        modules => [qw(
            PFProAPI
        )]
    }, 

    'MVCE' => {
        name => 'Main Street Credit Verification Engine (MCVE)', 
        url => 'http://www.mainstreetsoftworks.com/', 
        author => 'Main Street Softworks', 
        author_url => 'http://www.mainstreetsoftworks.com/', 
        modules => [qw(
            MVCE
        )]
    }, 

    'LinkPoint' => {
        name => 'LinkPoint API', 
        url => 'https://www.linkpoint.com/viewcart/', 
        author => 'LinkPoint', 
        author_url => 'https://www.linkpoint.com/', 
        modules => [qw(
            lpperl
        )]
    }, 

    'ICS' => {
        name => 'CyberSource ICS', 
        url => 'http://www.cybersource.com/support_center/implementation/downloads/', 
        author => 'CyberSource', 
        author_url => 'http://www.cybersource.com/', 
        modules => [qw(
            ICS
        )]
    }, 

    'CyberCash' => {
        name => 'CyberCash', 
        url => 'http://www.cybersource.com/support_center/implementation/downloads/', 
        author => 'CyberSource', 
        author_url => 'http://www.cybersource.com/', 
        modules => [qw(
            CCMckLib3_2
            CCMckDirectLib3_2
            CCMckErrno3_2
        )]
    }, 

    'OpenECHO' => {
        name => 'OpenECHO', 
        url => 'http://www.openecho.com/index.php?ba=downloads', 
        author => 'OpenECHO', 
        author_url => 'http://www.openecho.com/', 
        modules => [qw(
            OpenECHO
        )]
    },

    'Fuzzled' => {
        name => 'Fuzzled - Perl Fuzzing Framework',
        url => 'http://www.nth-dimension.org.uk/downloads.php?id=15',
        author => 'Tim Brown',
        author_url => 'http://www.nth-dimension.org.uk/',
        modules => [qw(
            Fuzzled::Factory::BruteForce
            Fuzzled::Factory::Date
            Fuzzled::Factory::Increment
            Fuzzled::Factory::Pad
            Fuzzled::Factory::Pattern
            Fuzzled::Factory::QuickBruteForce
            Fuzzled::Factory::Repeat
            Fuzzled::Factory::Replace
            Fuzzled::Helper
            Fuzzled::Helper::SharedMemory
            Fuzzled::Helper::TCP
            Fuzzled::Helper::UDP
            Fuzzled::Namespace::EndLine
            Fuzzled::Namespace::Filename
            Fuzzled::Namespace::FormatString
            Fuzzled::Namespace::Javascript
            Fuzzled::Namespace::LDAP
            Fuzzled::Namespace::LettersUpper
            Fuzzled::Namespace::Printable
            Fuzzled::Namespace::Separate
            Fuzzled::Namespace::Shell
            Fuzzled::Namespace::SQL
            Fuzzled::Namespace::Unicode
            Fuzzled::Namespace::URLEncoded
            Fuzzled::Namespace::Whitespace
            Fuzzled::PacketParse::Separate
            Fuzzled::Protocol::CAArcServe6050
            Fuzzled::Protocol::HTTP
            Fuzzled::Protocol::HTTPDirBuster
            Fuzzled::Protocol::HTTPFormsAuthenticate
            Fuzzled::Protocol::SOCKS4
        )],
    },

    'Opus10' => {
        name => 'Opus10 - Data Structures and Algorithms',
        url => 'http://www.brpreiss.com/books/opus10/',
        author => 'Bruno R. Preiss',
        author_url => 'http://www.brpreiss.com/',
        modules => [qw(
            Opus10
            Opus10::Algorithms
            Opus10::Application1
            Opus10::Application11
            Opus10::Application12
            Opus10::Application2
            Opus10::Application3
            Opus10::Application4
            Opus10::Application5
            Opus10::Application6
            Opus10::Application7
            Opus10::Application8
            Opus10::Application9
            Opus10::Array
            Opus10::Association
            Opus10::AVLTree
            Opus10::BinaryHeap
            Opus10::BinaryInsertionSorter
            Opus10::BinarySearchTree
            Opus10::BinaryTree
            Opus10::BinomialQueue
            Opus10::Box
            Opus10::BreadthFirstBranchAndBoundSolver
            Opus10::BreadthFirstSolver
            Opus10::BTree
            Opus10::BubbleSorter
            Opus10::BucketSorter
            Opus10::ChainedHashTable
            Opus10::ChainedScatterTable
            Opus10::Circle
            Opus10::Comparable
            Opus10::Complex
            Opus10::Container
            Opus10::Cursor
            Opus10::Deap
            Opus10::Declarators
            Opus10::Demo1
            Opus10::Demo10
            Opus10::Demo2
            Opus10::Demo3
            Opus10::Demo4
            Opus10::Demo5
            Opus10::Demo6
            Opus10::Demo7
            Opus10::Demo9
            Opus10::DenseMatrix
            Opus10::DepthFirstBranchAndBoundSolver
            Opus10::DepthFirstSolver
            Opus10::Deque
            Opus10::DequeAsArray
            Opus10::DequeAsLinkedList
            Opus10::Digraph
            Opus10::DigraphAsLists
            Opus10::DigraphAsMatrix
            Opus10::DoubleEndedPriorityQueue
            Opus10::Edge
            Opus10::Example
            Opus10::Experiment1
            Opus10::Experiment2
            Opus10::ExponentialRV
            Opus10::ExpressionTree
            Opus10::Float
            Opus10::GeneralTree
            Opus10::Graph
            Opus10::GraphAsLists
            Opus10::GraphAsMatrix
            Opus10::GraphicalObject
            Opus10::HashTable
            Opus10::HeapSorter
            Opus10::Integer
            Opus10::LeftistHeap
            Opus10::LinkedList
            Opus10::MakePod
            Opus10::Matrix
            Opus10::MedianOfThreeQuickSorter
            Opus10::MergeablePriorityQueue
            Opus10::MultiDimensionalArray
            Opus10::Multiset
            Opus10::MultisetAsArray
            Opus10::MultisetAsLinkedList
            Opus10::MWayTree
            Opus10::NaryTree
            Opus10::Object
            Opus10::OpenScatterTable
            Opus10::OpenScatterTableV2
            Opus10::OrderedList
            Opus10::OrderedListAsArray
            Opus10::OrderedListAsLinkedList
            Opus10::Parent
            Opus10::Partition
            Opus10::PartitionAsForest
            Opus10::PartitionAsForestV2
            Opus10::PartitionAsForestV3
            Opus10::Person
            Opus10::Point
            Opus10::Polynomial
            Opus10::PolynomialAsOrderedList
            Opus10::PolynomialAsSortedList
            Opus10::PriorityQueue
            Opus10::Queue
            Opus10::QueueAsArray
            Opus10::QueueAsLinkedList
            Opus10::QuickSorter
            Opus10::RadixSorter
            Opus10::RandomNumberGenerator
            Opus10::RandomVariable
            Opus10::Rectangle
            Opus10::ScalesBalancingProblem
            Opus10::SearchableContainer
            Opus10::SearchTree
            Opus10::Set
            Opus10::SetAsArray
            Opus10::SetAsBitVector
            Opus10::SimpleRV
            Opus10::Simulation
            Opus10::Solution
            Opus10::Solver
            Opus10::SortedList
            Opus10::SortedListAsArray
            Opus10::SortedListAsLinkedList
            Opus10::Sorter
            Opus10::SparseMatrix
            Opus10::SparseMatrixAsArray
            Opus10::SparseMatrixAsLinkedList
            Opus10::SparseMatrixAsVector
            Opus10::Square
            Opus10::Stack
            Opus10::StackAsArray
            Opus10::StackAsLinkedList
            Opus10::StraightInsertionSorter
            Opus10::StraightSelectionSorter
            Opus10::String
            Opus10::Timer
            Opus10::Tree
            Opus10::TwoWayMergeSorter
            Opus10::UniformRV
            Opus10::Vertex
            Opus10::Wrapper
            Opus10::ZeroOneKnapsackProblem
        )],
    },
);

my %modules = ();

for my $soft (keys %softwares) {
    my @mods = @{$softwares{$soft}->{modules}};
    @modules{@mods} = ($softwares{$soft}) x @mods;
}


=head1 EXPORT

This module exports by defalut the functions C<is_3rd_party()> and 
C<module_information()>. C<provides()> and C<all_modules()> can be 
exported on demand.

=head1 FUNCTIONS

=over 4

=item B<is_3rd_party()>

Returns true if the given module name is a known third-party Perl module. 

B<Example>

    print "$module is a known third-party module\n" if is_3rd_party($module)

=cut

sub is_3rd_party {
    return exists $modules{$_[0]}
}

=item B<module_information()>

Returns the information about a known third-party Perl Module or C<undef> 
if the module is not known. The information is returned as a hashref with 
the following keys: 

=over 4

=item *

C<name> is the name of the software that provides the given module; 

=item *

C<url> is the URL where this software can be found; 

=item *

C<author> is the name of the author who publishes the software; 

=item *

C<author_url> is the URL of the author's web site; 

=item *

C<modules> is an arrayref which contains the list of the Perl modules 
provided by the software.

=back

B<Example>

    my $info = module_information($module);
    print "$module is included in $info->{name}, which can be found at $info->{url}\n"

=cut

sub module_information {
    return exists $modules{$_[0]} ? $modules{$_[0]} : undef
}

=item B<provides()>

Returns a list of hashref with the name and author of each 
software for which this module provides information. 

B<Example>

Prints the list of known third-party modules sorted by software name.

    print "Known third-party software:\n";
    my @softs = Module::ThirdParty::provides();
    for my $soft (sort {$a->{name} cmp $b->{name}} @softs) {
        print " - $$soft{name} by $$soft{author} \n"
    }

=cut

sub provides {
    my @softs = ();

    for my $soft (keys %softwares) {
        push @softs, {
            author      => $softwares{$soft}{author}, 
            name        => $softwares{$soft}{name}, 
            url         => $softwares{$soft}{url}, 
            author_url  => $softwares{$soft}{author_url}, 
        }
    }

    return @softs
}


=item B<all_modules()>

Returns the list of all known third-third modules.

B<Example>

    my @modules = Module::ThirdParty::all_modules();

=cut

sub all_modules {
    return sort keys %modules
}

=back

=head1 KNOWN THIRD-PARTY SOFTWARE

Here is the list of the third-party software know by this version of 
C<Module::ThirdParty>. 

=over

=item *

!WAHa.06x36 I<PerlHP> - L<http://wakaba.c3.cx/perlhp/>

=item *

Apple I<ActivePerl> - L<http://aspn.activestate.com/ASPN/Perl>

=item *

Apple I<Perl/Objective-C bridge> - L<http://developer.apple.com/>

=item *

Best Practical I<Request Tracker> - L<http://bestpractical.com/rt/>

=item *

Brandon Long I<ClearSilver> - L<http://www.clearsilver.net/>

=item *

Brian Ingerson I<XXX> - L<http://search.cpan.org/dist/XXX/>

=item *

Bruno R. Preiss I<Opus10 - Data Structures and Algorithms> - L<http://www.brpreiss.com/books/opus10/>

=item *

CAIDA I<GeoPlot Perl API> - L<http://www.caida.org/tools/visualization/geoplot/>

=item *

CAIDA I<NetGeo API> - L<http://www.caida.org/tools/utilities/netgeo/>

=item *

Craig Barratt I<BackupPC> - L<http://backuppc.sourceforge.net/>

=item *

CyberSource I<CyberCash> - L<http://www.cybersource.com/support_center/implementation/downloads/>

=item *

I<CyberSource ICS> - L<http://www.cybersource.com/support_center/implementation/downloads/>

=item *

Dave Kliczbor I<SpamAssassin and Courier virtual domain management> - L<http://da.andaka.org/Doku/courier-spamassassin.html>

=item *

I<Directi Perl API> - L<http://manage.directi.com/kb/servlet/KBServlet/faq685.html>

=item *

ETH/DEE IT & Support Group I<Gossips> - L<http://isg.ee.ethz.ch/tools/gossips/>

=item *

ETH/DEE IT & Support Group I<Real Men Don't Click> - L<http://isg.ee.ethz.ch/tools/realmen/>

=item *

Fidelia I<NetVigil> - L<http://www.fidelia.com/products/>

=item *

Fotango I<Vx> - L<http://opensource.fotango.com/software/vx/>

=item *

Gemplus I<TLP Driver> - L<http://www.gemplus.com/techno/tlp_drivers/index.html>

=item *

Gisle Aas I<Perl::API> - L<http://search.cpan.org/dist/Perl-API/>

=item *

Grant McLean I<Sprog> - L<http://sprog.sourceforge.net/>

=item *

I<Interchange Payment Modules> - L<http://www.interchange.rtfm.info/downloads/payments/>

=item *

Jamie Cameron I<Webmin> - L<http://webmin.com/>

=item *

Jason Alonzo Long I<OwPerlProvider> - L<http://jason.long.name/owperl/>

=item *

Jens Helberg I<Win32::Lanman> - L<http://www.cpan.org/authors/id/J/JH/JHELBERG/>

=item *

Jens Helberg I<Win32::Setupsup> - L<http://www.cpan.org/authors/id/J/JH/JHELBERG/>

=item *

KDE I<DCOP-Perl> - L<http://websvn.kde.org/branches/KDE/3.5/kdebindings/dcopperl/>

=item *

Lian Wan Situ I<X-Chat 2.x Perl Interface> - L<http://xchat.org/docs/xchat2-perl.html>

=item *

libwin32 contributors I<Win32::Daemon> - L<http://code.google.com/p/libwin32/source/browse/trunk/Win32-Daemon/>

=item *

I<LinkPoint API> - L<https://www.linkpoint.com/viewcart/>

=item *

Logical Information Machines I<Market Information Machine> - L<http://www.lim.com/download/>

=item *

Main Street Softworks I<Main Street Credit Verification Engine (MCVE)> - L<http://www.mainstreetsoftworks.com/>

=item *

ManageIt I<perl4patrol> - L<http://www.manageit.ca/p_and_s/tools/perl4patrol/perl4patrol.html>

=item *

Martin Krzywinski et al. I<Circos> - L<http://mkweb.bcgsc.ca/circos/>

=item *

Martin Mersberger I<PatrolPerl> - L<http://www.portal-to-web.de/PatrolPerl/>

=item *

I<Metasploit Framework> - L<http://metasploit.com/projects/Framework/>

=item *

Microsoft I<W2RK::WMI> - L<http://www.microsoft.com/windows2000/techinfo/reskit/default.mspx>

=item *

Nicolas Chuche I<BB> - L<http://www.teaser.fr/~nchuche/bb/bb_pm/>

=item *

Nicolas Chuche I<Orabb> - L<http://www.teaser.fr/~nchuche/bb/orabb.html>

=item *

I<OpenBSD modules> - L<http://www.openbsd.org/cgi-bin/cvsweb/src/usr.sbin/pkg_add/>

=item *

I<OpenECHO> - L<http://www.openecho.com/index.php?ba=downloads>

=item *

OTRS Team I<Open Ticket Request System> - L<http://otrs.org/>

=item *

Paradata Systems I<OpenConnect> - L<http://www.paradata.com/content/developers/>

=item *

Perforce I<Version CoPy (VCP)> - L<http://search.cpan.org/dist/VCP-autrijus-snapshot/>

=item *

Peter Zelezny I<X-Chat 1.x Perl Interface (legacy)> - L<http://xchat.org/docs/xchat2-perldocs.html>

=item *

Progress Software I<Fathom Management Perl API> - L<http://psdn.progress.com/library/fathom/>

=item *

Proton-CE Team I<Proton-CE> - L<http://proton-ce.sourceforge.net/>

=item *

rfp.labs I<LibWhisker> - L<http://www.wiretrip.net/rfp/lw1.asp>

=item *

rfp.labs I<LibWhisker2> - L<http://www.wiretrip.net/rfp/lw.asp>

=item *

I<Roth Consulting's Perl Contributions> - L<http://www.roth.net/perl/>

=item *

Schuyler Erle & Robert Flickenger I<NoCat> - L<http://nocat.net/>

=item *

Simon Leinen I<SNMP_Session> - L<http://www.switch.ch/misc/leinen/snmp/perl/>

=item *

Six Apart I<CSS::Cleaner> - L<http://code.sixapart.com/trac/CSS-Cleaner>

=item *

Six Apart I<Devel::Gladiator> - L<http://code.sixapart.com/svn/Devel-Gladiator/>

=item *

Six Apart I<Movable Type> - L<http://www.sixapart.com/movabletype/>

=item *

Slim Devices I<SlimServer> - L<http://www.slimdevices.com/dev_resources.html>

=item *

I<Subversion> - L<http://subversion.tigris.org/>

=item *

I<Swish-e> - L<http://www.swish-e.org/>

=item *

Tim Brown I<Fuzzled - Perl Fuzzing Framework> - L<http://www.nth-dimension.org.uk/downloads.php?id=15>

=item *

Tobi Oetiker I<Gedafe> - L<http://isg.ee.ethz.ch/tools/gedafe/>

=item *

Tobi Oetiker I<MRTG> - L<http://oss.oetiker.ch/mrtg/>

=item *

Tobi Oetiker I<RRDTool> - L<http://oss.oetiker.ch/rrdtool/>

=item *

Tobi Oetiker I<SmokePing> - L<http://oss.oetiker.ch/smokeping/>

=item *

Tobi Oetiker I<Template Tree II> - L<http://isg.ee.ethz.ch/tools/tetre2/>

=item *

US National Virtual Observatory I<VOTable> - L<http://www.us-vo.org/VOTable/>

=item *

VeriSign I<PayFlow Pro> - L<http://www.verisign.com/products-services/payment-processing/online-payment/payflow-pro/index.html>

=item *

I<VMware Perl API> - L<http://www.vmware.com/support/developer/scripting-API/>

=item *

Zeus Technology I<Zeus Web Server Perl Extensions> - L<http://support.zeus.com/>

=back

=head1 SEE ALSO

L<Module::CoreList>, L<CPANPLUS>, L<Parse::BACKPAN::Packages>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< E<lt>sebastien (at) aperghis.netE<gt> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-module-thirdparty (at) rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-ThirdParty>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005, 2006, 2007, 2008 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Module::ThirdParty
