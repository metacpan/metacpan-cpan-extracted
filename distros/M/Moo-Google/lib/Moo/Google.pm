package Moo::Google;
$Moo::Google::VERSION = '0.01';

# ABSTRACT: Server-side client library for any Google App API. Based on Moose


use Data::Dumper;
use Moose;
use Moo::Google::Client;

has 'debug' => ( is => 'rw', default => 0, lazy => 1 );
has 'client' => (
    is      => 'ro',
    default => sub { Moo::Google::Client->new( debug => shift->debug ) },
    handles => [qw(access_token user auth_storage do_autorefresh api_query)],
    lazy    => 1
);
has 'util' => (
    is      => 'ro',
    default => sub {
        require Moo::Google::Util;
        Moo::Google::Util->new( debug => shift->debug );
    },
    handles => [qw(substitute_placeholders)],
    lazy    => 1
);
has 'discovery' => (
    is      => 'ro',
    default => sub {
        require Moo::Google::Discovery;
        Moo::Google::Discovery->new( debug => shift->debug );
    },
    handles => [qw(getMethodMeta)],
    lazy    => 1
);

sub request {
    my ( $self, $caller, $params ) = @_;

    # my $caller = (caller(0))[3];
    warn "Caller: " . $caller
      if ( $self->debug );    # like Moo::Google::Calendar::Events::list
    warn "request PARAMETERS: " . Dumper $params if ( $self->debug );

    my $api_q_data = $self->getMethodMeta($caller);
    $api_q_data->{options} = $params->{options};
    delete $params->{options};

    warn 'API query data: ' . Dumper $api_q_data if ( $self->debug );

    # get $params from $caller object
    # proxying $self->Service->Resource attributes

    $api_q_data->{path} =
      $self->substitute_placeholders( $api_q_data->{path}, $params );    # util
    warn 'API query data: ' . Dumper $api_q_data if ( $self->debug );
    $self->api_query($api_q_data);    # path, httpMethod
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $unknown_resource =
      ( split( /::/, $AUTOLOAD ) )[-1];    # $unknown_method_name = API
    warn $unknown_resource if ( $self->debug );
    require Moo::Google::Services;
    my $a = Moo::Google::Services->new;
    $a->debug( $self->debug );
    $a->generate_one( $self, lcfirst $unknown_resource );
    $self->$unknown_resource;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moo::Google - Server-side client library for any Google App API. Based on Moose

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Moo::Google;

    my $gapi = Moo::Google->new(debug => 0); # my $gapi = Moo::Google->new(access_token => '');
    my $user = 'pavelsr@cpan.org'; # full gmail

    $gapi->auth_storage->setup({type => 'jsonfile', path => '/path' }); # by default
    # $gapi->auth_storage->setup({ type => 'dbi', path => 'DBI object' });
    # $gapi->auth_storage->setup({ type => 'mongodb', path => 'details' });

    $gapi->user($user);
    $gapi->do_autorefresh(1);

    my $r1 = $gapi->Calendar->Events->list({ calendarId => 'primary' })->json;
    warn scalar @{$r1->{items}};

To create authorization file with tokens in current folder run I<goauth> CLI tool

See unit test in xt folder for more examples

=head1 KEY FEATURES

=over 1

=item Object-oriented calls by API->Resource->method schema. Like $gapi->Calendar->Events->lists

=item Classes are generated dynamically using L<Moose::Meta::Class> based on Google API Discovery Service

=item Different app credentials (client_id, client_secret, users access_token && refresh_token) storage - json file, DBI, MongoDB (u can add your own even)

=item Automatic access_token refresh (if user has refresh_token) and saving refreshed token to storage

=item CLI tool (I<goauth>) with lightweight server for easy OAuth2 authorization and getting access_ and refresh_ tokens

=back

=head1 SEE ALSO

L<API::Google> - my old lib

L<Google::API::Client> - source of inspiration

=head1 SUPPORTED APIs

  acceleratedmobilepageurl : v1 : https://developers.google.com/amp/cache/
  adexchangebuyer : v1.2,v1.3,v1.4 : https://developers.google.com/ad-exchange/buyer-rest
  adexchangebuyer2 : v2beta1 : https://developers.google.com/ad-exchange/buyer-rest/guides/client-access/
  adexchangeseller : v1,v1.1,v2.0 : https://developers.google.com/ad-exchange/seller-rest/
  admin : datatransfer_v1,directory_v1,reports_v1 : https://developers.google.com/admin-sdk/data-transfer/,https://developers.google.com/admin-sdk/directory/,https://developers.google.com/admin-sdk/reports/
  adsense : v1.3,v1.4 : https://developers.google.com/adsense/management/
  adsensehost : v4.1 : https://developers.google.com/adsense/host/
  analytics : v2.4,v3 : https://developers.google.com/analytics/
  analyticsreporting : v4 : https://developers.google.com/analytics/devguides/reporting/core/v4/
  androidenterprise : v1 : https://developers.google.com/android/work/play/emm-api
  androidpublisher : v1,v1.1,v2 : https://developers.google.com/android-publisher
  appengine : v1alpha,v1beta,v1,v1beta4,v1beta5 : https://cloud.google.com/appengine/docs/admin-api/
  appsactivity : v1 : https://developers.google.com/google-apps/activity/
  appstate : v1 : https://developers.google.com/games/services/web/api/states
  bigquery : v2 : https://cloud.google.com/bigquery/
  blogger : v2,v3 : https://developers.google.com/blogger/docs/2.0/json/getting_started,https://developers.google.com/blogger/docs/3.0/getting_started
  books : v1 : https://developers.google.com/books/docs/v1/getting_started
  calendar : v3 : https://developers.google.com/google-apps/calendar/firstapp
  civicinfo : v2 : https://developers.google.com/civic-information
  classroom : v1 : https://developers.google.com/classroom
  cloudbilling : v1 : https://cloud.google.com/billing/
  cloudbuild : v1 : https://cloud.google.com/container-builder/docs/
  clouddebugger : v2 : http://cloud.google.com/debugger
  clouderrorreporting : v1beta1 : https://cloud.google.com/error-reporting/
  cloudfunctions : v1,v1beta2 : https://cloud.google.com/functions
  cloudkms : v1 : https://cloud.google.com/kms/
  cloudmonitoring : v2beta2 : https://cloud.google.com/monitoring/v2beta2/
  cloudresourcemanager : v1,v1beta1 : https://cloud.google.com/resource-manager
  cloudtrace : v1 : https://cloud.google.com/trace
  clouduseraccounts : alpha,beta,vm_alpha,vm_beta : https://cloud.google.com/compute/docs/access/user-accounts/api/latest/
  compute : alpha,beta,v1 : https://developers.google.com/compute/docs/reference/latest/
  Use of uninitialized value in join or string at lib/Moo/Google/Discovery.pm line 139.
  consumersurveys : v2 :
  container : v1 : https://cloud.google.com/container-engine/
  content : v2sandbox,v2 : https://developers.google.com/shopping-content
  customsearch : v1 : https://developers.google.com/custom-search/v1/using_rest
  dataflow : v1b3 : https://cloud.google.com/dataflow
  dataproc : v1alpha1,v1,v1beta1 : https://cloud.google.com/dataproc/
  datastore : v1,v1beta3 : https://cloud.google.com/datastore/
  deploymentmanager : alpha,v2beta,v2 : https://cloud.google.com/deployment-manager/,https://developers.google.com/deployment-manager/
  dfareporting : v2.6,v2.7 : https://developers.google.com/doubleclick-advertisers/
  discovery : v1 : https://developers.google.com/discovery/
  dlp : v2beta1 : https://cloud.google.com/dlp/docs/
  dns : v1,v2beta1 : https://developers.google.com/cloud-dns
  doubleclickbidmanager : v1 : https://developers.google.com/bid-manager/
  doubleclicksearch : v2 : https://developers.google.com/doubleclick-search/
  drive : v2,v3 : https://developers.google.com/drive/
  firebasedynamiclinks : v1 : https://firebase.google.com/docs/dynamic-links/
  firebaserules : v1 : https://firebase.google.com/docs/storage/security
  fitness : v1 : https://developers.google.com/fit/rest/
  fusiontables : v1,v2 : https://developers.google.com/fusiontables
  games : v1 : https://developers.google.com/games/services/
  gamesConfiguration : v1configuration : https://developers.google.com/games/services
  gamesManagement : v1management : https://developers.google.com/games/services
  genomics : v1alpha2,v1 : https://cloud.google.com/genomics
  gmail : v1 : https://developers.google.com/gmail/api/
  groupsmigration : v1 : https://developers.google.com/google-apps/groups-migration/
  groupssettings : v1 : https://developers.google.com/google-apps/groups-settings/get_started
  iam : v1 : https://cloud.google.com/iam/
  identitytoolkit : v3 : https://developers.google.com/identity-toolkit/v3/
  kgsearch : v1 : https://developers.google.com/knowledge-graph/
  language : v1,v1beta1,v1beta2 : https://cloud.google.com/natural-language/
  licensing : v1 : https://developers.google.com/google-apps/licensing/
  logging : v2,v2beta1 : https://cloud.google.com/logging/docs/
  manufacturers : v1 : https://developers.google.com/manufacturers/
  mirror : v1 : https://developers.google.com/glass
  ml : v1,v1beta1 : https://cloud.google.com/ml/
  monitoring : v3 : https://cloud.google.com/monitoring/api/
  oauth2 : v1,v2 : https://developers.google.com/accounts/docs/OAuth2
  pagespeedonline : v1,v2 : https://developers.google.com/speed/docs/insights/v1/getting_started,https://developers.google.com/speed/docs/insights/v2/getting-started
  partners : v2 : https://developers.google.com/partners/
  people : v1 : https://developers.google.com/people/
  playmoviespartner : v1 : https://developers.google.com/playmoviespartner/
  plus : v1 : https://developers.google.com/+/api/
  plusDomains : v1 : https://developers.google.com/+/domains/
  prediction : v1.2,v1.3,v1.4,v1.5,v1.6 : https://developers.google.com/prediction/docs/developer-guide
  proximitybeacon : v1beta1 : https://developers.google.com/beacons/proximity/
  pubsub : v1beta1a,v1,v1beta2 : https://cloud.google.com/pubsub/docs
  qpxExpress : v1 : http://developers.google.com/qpx-express
  replicapool : v1beta1,v1beta2 : https://developers.google.com/compute/docs/replica-pool/,https://developers.google.com/compute/docs/instance-groups/manager/v1beta2
  replicapoolupdater : v1beta1 : https://cloud.google.com/compute/docs/instance-groups/manager/#applying_rolling_updates_using_the_updater_service
  reseller : v1 : https://developers.google.com/google-apps/reseller/
  resourceviews : v1beta1,v1beta2 : https://developers.google.com/compute/
  runtimeconfig : v1,v1beta1 : https://cloud.google.com/deployment-manager/runtime-configurator/
  safebrowsing : v4 : https://developers.google.com/safe-browsing/
  script : v1 : https://developers.google.com/apps-script/execution/rest/v1/scripts/run
  searchconsole : v1 : https://developers.google.com/webmaster-tools/search-console-api/
  servicecontrol : v1 : https://cloud.google.com/service-control/
  servicemanagement : v1 : https://cloud.google.com/service-management/
  serviceuser : v1 : https://cloud.google.com/service-management/
  sheets : v4 : https://developers.google.com/sheets/
  siteVerification : v1 : https://developers.google.com/site-verification/
  slides : v1 : https://developers.google.com/slides/
  sourcerepo : v1 : https://cloud.google.com/eap/cloud-repositories/cloud-sourcerepo-api
  spanner : v1 : https://cloud.google.com/spanner/
  spectrum : v1explorer : http://developers.google.com/spectrum
  speech : v1beta1 : https://cloud.google.com/speech/
  sqladmin : v1beta3,v1beta4 : https://cloud.google.com/sql/docs/reference/latest
  storage : v1,v1beta1,v1beta2 : https://developers.google.com/storage/docs/json_api/
  storagetransfer : v1 : https://cloud.google.com/storage/transfer
  supportcases : v2 : https://sites.google.com/a/google.com/cases/
  Use of uninitialized value in join or string at lib/Moo/Google/Discovery.pm line 139.
  surveys : v2 :
  tagmanager : v1,v2 : https://developers.google.com/tag-manager/api/v1/,https://developers.google.com/tag-manager/api/v2/
  taskqueue : v1beta1,v1beta2 : https://developers.google.com/appengine/docs/python/taskqueue/rest
  tasks : v1 : https://developers.google.com/google-apps/tasks/firstapp
  toolresults : v1beta3firstparty,v1beta3 : https://firebase.google.com/docs/test-lab/
  tracing : v2 : https://cloud.google.com/trace
  translate : v2 : https://developers.google.com/translate/v2/using_rest
  urlshortener : v1 : https://developers.google.com/url-shortener/v1/getting_started
  vision : v1 : https://cloud.google.com/vision/
  webfonts : v1 : https://developers.google.com/fonts/docs/developer_api
  webmasters : v3 : https://developers.google.com/webmaster-tools/
  youtube : v3 : https://developers.google.com/youtube/v3
  youtubeAnalytics : v1,v1beta1 : http://developers.google.com/youtube/analytics/
  youtubereporting : v1 : https://developers.google.com/youtube/reporting/v1/reports/

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
