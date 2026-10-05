package Net::Async::Authentik::API;

# ABSTRACT: authentik REST API v3, asynchronously, with idempotent ensure methods

use Moo;
with 'Net::Async::Authentik::Role::HTTP';
with 'WWW::Authentik::Role::HTTP';
use Future;
use Future::AsyncAwait;
use Scalar::Util qw( blessed );
use Types::Standard qw( Int Object Str );
use URI::Escape qw( uri_escape_utf8 );
use WWW::Authentik::API;
use WWW::Authentik::Diff;
use namespace::autoclean;

our $VERSION = '0.001';


has base_url => ( is => 'ro', isa => Str, required => 1 );


has token => ( is => 'ro', isa => Str, predicate => 'has_token' );


has http => ( is => 'ro', isa => Object, required => 1 );


has page_size => ( is => 'ro', isa => Int, default => 100 );


sub diff_class { 'WWW::Authentik::Diff' }


sub resolvable_fields { WWW::Authentik::API->resolvable_fields }
sub uuid_pattern      { WWW::Authentik::API->uuid_pattern }
sub integer_pattern   { WWW::Authentik::API->integer_pattern }


####  transport

sub api_url { $_[0]->base_url.'/api/v3' }


sub call_f {
  my ( $self, $method, $path, $body ) = @_;
  return $self->fail_validation( __PACKAGE__.' needs an API token' ) unless $self->has_token && length $self->token;
  $path = '/'.$path unless $path =~ m{\A/};
  my %arg = defined $body ? ( json => $body ) : ();
  return $self->send_request_f( $method, $self->api_url.$path, %arg, bearer => $self->token );
}


async sub _data_f { return ( await $_[0]->call_f( @_[ 1 .. $#_ ] ) )->{data} }
async sub _done_f { await $_[0]->call_f( @_[ 1 .. $#_ ] ); return 1 }

sub _esc { uri_escape_utf8( $_[1] ) }

sub _query {
  my ( $self, %query ) = @_;
  return '' unless %query;
  return '?'.join '&', map { $self->_esc($_).'='.$self->_esc( $query{$_} ) }
    grep { defined $query{$_} } sort keys %query;
}

async sub _paged_f {
  my ( $self, $path, %query ) = @_;
  my $page_size = delete $query{page_size} // $self->page_size;
  my ( @all, %seen );
  my $page = 1;
  # a broken answer whose next points at a page already fetched would loop
  # for ever; %seen is the floor under that
  while ( defined $page && $page > 0 && !$seen{$page}++ ) {
    my $data = await $self->_data_f( GET => $path.$self->_query( %query, page => $page, page_size => $page_size ) );
    last unless ref $data eq 'HASH';
    push @all, @{ $data->{results} || [] };
    $page = ref $data->{pagination} eq 'HASH' ? $data->{pagination}{next} : 0;
  }
  return \@all;
}

sub _find_one {
  my ( $self, $list, $key, $value ) = @_;
  my ( $found ) = grep { defined $_->{$key} && $_->{$key} eq $value } @$list;
  return $found;
}

# a finder called with nothing would otherwise fetch every object and compare
# each one against undef, warning once per row and finding nothing
sub _need {
  my ( $self, $what, $value ) = @_;
  return defined $value && length $value ? undef : $self->fail_validation( $what.' is needed' );
}

async sub _detail_f {
  my ( $self, $path ) = @_;
  my ( $object, $failed );
  eval { $object = await $self->_data_f( GET => $path ); 1 } or $failed = $@;
  # an answer with no body is not a failure, and $@ is empty there: telling
  # the two apart on the truth of $object would die with the empty string
  return $object unless defined $failed;
  return undef if blessed $failed && $failed->isa('WWW::Authentik::Error::API') && $failed->is_not_found;
  die $failed;
}

####  instance

sub version_f  { $_[0]->_data_f( GET => '/admin/version/' ) }
sub config_f   { $_[0]->_data_f( GET => '/root/config/' ) }
sub settings_f { $_[0]->_data_f( GET => '/admin/settings/' ) }
sub me_f       { $_[0]->_data_f( GET => '/core/users/me/' ) }


####  users

sub list_users_f  { my ( $self, %q ) = @_; $self->_paged_f( '/core/users/', %q ) }
sub get_user_f    { $_[0]->_data_f( GET => '/core/users/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_user_f { $_[0]->_data_f( POST => '/core/users/', $_[1] ) }
sub update_user_f { $_[0]->_data_f( PATCH => '/core/users/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_user_f { $_[0]->_done_f( DELETE => '/core/users/'.$_[0]->_esc( $_[1] ).'/' ) }

async sub find_user_f {
  my ( $self, $username ) = @_;
  if ( my $bad = $self->_need( 'find_user: a username', $username ) ) { return await $bad }
  return $self->_find_one( await( $self->list_users_f( username => $username ) ), 'username', $username );
}

sub set_password_f {
  my ( $self, $pk, $password ) = @_;
  return $self->_done_f( POST => '/core/users/'.$self->_esc($pk).'/set_password/', { password => $password } );
}

sub create_service_account_f {
  my ( $self, %arg ) = @_;
  return $self->fail_validation('create_service_account needs a name') unless defined $arg{name};
  return $self->_data_f( POST => '/core/users/service_account/',
    { name => $arg{name}, create_group => $arg{create_group} ? \1 : \0,
      exists $arg{expiring} ? ( expiring => $arg{expiring} ) : () } );
}

sub list_authenticators_f {
  my ( $self, $pk ) = @_;
  return $self->_data_f( GET => '/authenticators/admin/all/'.$self->_query( user => $pk ) );
}


####  groups

sub list_groups_f  { my ( $self, %q ) = @_; $self->_paged_f( '/core/groups/', %q ) }
sub get_group_f    { $_[0]->_data_f( GET => '/core/groups/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_group_f { $_[0]->_data_f( POST => '/core/groups/', $_[1] ) }
sub update_group_f { $_[0]->_data_f( PATCH => '/core/groups/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_group_f { $_[0]->_done_f( DELETE => '/core/groups/'.$_[0]->_esc( $_[1] ).'/' ) }

async sub find_group_f {
  my ( $self, $name ) = @_;
  if ( my $bad = $self->_need( 'find_group: a name', $name ) ) { return await $bad }
  return $self->_find_one( await( $self->list_groups_f( name => $name ) ), 'name', $name );
}

sub add_user_to_group_f {
  my ( $self, $uuid, $pk ) = @_;
  return $self->_done_f( POST => '/core/groups/'.$self->_esc($uuid).'/add_user/', { pk => $pk } );
}

sub remove_user_from_group_f {
  my ( $self, $uuid, $pk ) = @_;
  return $self->_done_f( POST => '/core/groups/'.$self->_esc($uuid).'/remove_user/', { pk => $pk } );
}


####  tokens

sub list_tokens_f  { my ( $self, %q ) = @_; $self->_paged_f( '/core/tokens/', %q ) }
sub get_token_f    { $_[0]->_data_f( GET => '/core/tokens/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_token_f { $_[0]->_data_f( POST => '/core/tokens/', $_[1] ) }
sub update_token_f { $_[0]->_data_f( PATCH => '/core/tokens/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_token_f { $_[0]->_done_f( DELETE => '/core/tokens/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_token_f {
  my ( $self, $identifier ) = @_;
  return $self->_need( 'find_token: an identifier', $identifier )
    || $self->_detail_f( '/core/tokens/'.$self->_esc($identifier).'/' );
}

sub view_token_key_f { $_[0]->_data_f( GET => '/core/tokens/'.$_[0]->_esc( $_[1] ).'/view_key/' ) }

sub set_token_key_f {
  my ( $self, $identifier, $key ) = @_;
  return $self->_done_f( POST => '/core/tokens/'.$self->_esc($identifier).'/set_key/', { key => $key } );
}


####  applications

sub list_applications_f  { my ( $self, %q ) = @_; $self->_paged_f( '/core/applications/', %q ) }
sub create_application_f { $_[0]->_data_f( POST => '/core/applications/', $_[1] ) }
sub update_application_f { $_[0]->_data_f( PATCH => '/core/applications/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_application_f { $_[0]->_done_f( DELETE => '/core/applications/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_application_f {
  my ( $self, $slug ) = @_;
  return $self->_need( 'find_application: a slug', $slug )
    || $self->_detail_f( '/core/applications/'.$self->_esc($slug).'/' );
}

sub check_access_f {
  my ( $self, $slug, %opt ) = @_;
  return $self->_data_f( GET => '/core/applications/'.$self->_esc($slug).'/check_access/'
    .$self->_query( defined $opt{for_user} ? ( for_user => $opt{for_user} ) : () ) );
}


####  oauth2 providers

sub list_oauth2_providers_f  { my ( $self, %q ) = @_; $self->_paged_f( '/providers/oauth2/', %q ) }
sub get_oauth2_provider_f    { $_[0]->_data_f( GET => '/providers/oauth2/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_oauth2_provider_f { $_[0]->_data_f( POST => '/providers/oauth2/', $_[1] ) }
sub update_oauth2_provider_f { $_[0]->_data_f( PATCH => '/providers/oauth2/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_oauth2_provider_f { $_[0]->_done_f( DELETE => '/providers/oauth2/'.$_[0]->_esc( $_[1] ).'/' ) }

async sub find_oauth2_provider_f {
  my ( $self, $name ) = @_;
  if ( my $bad = $self->_need( 'find_oauth2_provider: a name', $name ) ) { return await $bad }
  return $self->_find_one( await( $self->list_oauth2_providers_f( name => $name ) ), 'name', $name );
}

sub provider_setup_urls_f { $_[0]->_data_f( GET => '/providers/oauth2/'.$_[0]->_esc( $_[1] ).'/setup_urls/' ) }

sub preview_user_f {
  my ( $self, $pk, $user_pk ) = @_;
  return $self->_data_f( GET => '/providers/oauth2/'.$self->_esc($pk).'/preview_user/'
    .$self->_query( defined $user_pk ? ( for_user => $user_pk ) : () ) );
}


####  scope mappings

sub list_scope_mappings_f  { my ( $self, %q ) = @_; $self->_paged_f( '/propertymappings/provider/scope/', %q ) }
sub get_scope_mapping_f    { $_[0]->_data_f( GET => '/propertymappings/provider/scope/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_scope_mapping_f { $_[0]->_data_f( POST => '/propertymappings/provider/scope/', $_[1] ) }
sub update_scope_mapping_f { $_[0]->_data_f( PATCH => '/propertymappings/provider/scope/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_scope_mapping_f { $_[0]->_done_f( DELETE => '/propertymappings/provider/scope/'.$_[0]->_esc( $_[1] ).'/' ) }

async sub find_scope_mapping_f {
  my ( $self, $name ) = @_;
  if ( my $bad = $self->_need( 'find_scope_mapping: a name', $name ) ) { return await $bad }
  return $self->_find_one( await( $self->list_scope_mappings_f( name => $name ) ), 'name', $name );
}

async sub find_scope_mappings_by_scope_f {
  my ( $self, @scopes ) = @_;
  my @found;
  for my $scope (@scopes) {
    my ( $mapping ) = @{ await $self->list_scope_mappings_f( scope_name => $scope ) };
    die $self->validation_error_class->new( message => 'no scope mapping for the scope "'.$scope.'"' )
      unless $mapping;
    push @found, $mapping;
  }
  return \@found;
}

sub test_property_mapping_f {
  my ( $self, $uuid, %arg ) = @_;
  return $self->_data_f( POST => '/propertymappings/all/'.$self->_esc($uuid).'/test/', { %arg } );
}


####  flows

sub list_flows_f  { my ( $self, %q ) = @_; $self->_paged_f( '/flows/instances/', %q ) }
sub create_flow_f { $_[0]->_data_f( POST => '/flows/instances/', $_[1] ) }
sub update_flow_f { $_[0]->_data_f( PATCH => '/flows/instances/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_flow_f { $_[0]->_done_f( DELETE => '/flows/instances/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_flow_f {
  my ( $self, $slug ) = @_;
  return $self->_need( 'find_flow: a slug', $slug )
    || $self->_detail_f( '/flows/instances/'.$self->_esc($slug).'/' );
}

async sub export_flow_f {
  my ( $self, $slug ) = @_;
  return ( await $self->call_f( GET => '/flows/instances/'.$self->_esc($slug).'/export/' ) )->{content};
}


####  stages

sub stage_types_f { $_[0]->_data_f( GET => '/stages/all/types/' ) }
sub list_stages_f { my ( $self, %q ) = @_; $self->_paged_f( '/stages/all/', %q ) }

async sub find_stage_f {
  my ( $self, $name ) = @_;
  if ( my $bad = $self->_need( 'find_stage: a name', $name ) ) { return await $bad }
  return $self->_find_one( await( $self->list_stages_f( name => $name ) ), 'name', $name );
}

sub _stage_path {
  my ( $self, $type ) = @_;
  return ( undef, $self->fail_validation('a stage type is needed, for example password or authenticator/validate') )
    unless defined $type && length $type;
  return ( undef, $self->fail_validation('/stages/all/ can only be read: name the stage type, for example password') )
    if $type eq 'all';
  $type =~ s{\A/}{};
  $type =~ s{/\z}{};
  return ( '/stages/'.$type.'/', undef );
}

sub get_stage_f {
  my ( $self, $type, $uuid ) = @_;
  my ( $path, $bad ) = $self->_stage_path($type);
  return $bad || $self->_data_f( GET => $path.$self->_esc($uuid).'/' );
}

sub create_stage_f {
  my ( $self, $type, $rep ) = @_;
  my ( $path, $bad ) = $self->_stage_path($type);
  return $bad || $self->_data_f( POST => $path, $rep );
}

sub update_stage_f {
  my ( $self, $type, $uuid, $rep ) = @_;
  my ( $path, $bad ) = $self->_stage_path($type);
  return $bad || $self->_data_f( PATCH => $path.$self->_esc($uuid).'/', $rep );
}

sub delete_stage_f {
  my ( $self, $type, $uuid ) = @_;
  my ( $path, $bad ) = $self->_stage_path($type);
  return $bad || $self->_done_f( DELETE => $path.$self->_esc($uuid).'/' );
}


####  flow stage bindings

async sub list_bindings_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('list_bindings_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %q = %$pairs;
  # authentik wants the flow's UUID in target and answers a slug with a field
  # error, so flow => $slug is the readable way in
  $q{target} = await $self->_flow_pk_f( delete $q{flow} ) if defined $q{flow};
  return await $self->_paged_f( '/flows/bindings/', %q );
}

async sub _flow_pk_f {
  my ( $self, $flow ) = @_;
  return $flow if $flow =~ $self->uuid_pattern;
  my $found = await $self->find_flow_f($flow);
  die $self->validation_error_class->new( message => 'no flow "'.$flow.'"' ) unless $found;
  return $found->{pk};
}

sub get_binding_f    { $_[0]->_data_f( GET => '/flows/bindings/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_binding_f { $_[0]->_data_f( POST => '/flows/bindings/', $_[1] ) }
sub update_binding_f { $_[0]->_data_f( PATCH => '/flows/bindings/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_binding_f { $_[0]->_done_f( DELETE => '/flows/bindings/'.$_[0]->_esc( $_[1] ).'/' ) }


####  brands, certificates, blueprints

sub list_brands_f   { my ( $self, %q ) = @_; $self->_paged_f( '/core/brands/', %q ) }
sub current_brand_f { $_[0]->_data_f( GET => '/core/brands/current/' ) }
sub update_brand_f  { $_[0]->_data_f( PATCH => '/core/brands/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }

sub list_certificates_f { my ( $self, %q ) = @_; $self->_paged_f( '/crypto/certificatekeypairs/', %q ) }

async sub find_certificate_f {
  my ( $self, $name ) = @_;
  if ( my $bad = $self->_need( 'find_certificate: a name', $name ) ) { return await $bad }
  return $self->_find_one( await( $self->list_certificates_f( name => $name ) ), 'name', $name );
}

sub list_blueprints_f  { my ( $self, %q ) = @_; $self->_paged_f( '/managed/blueprints/', %q ) }
sub get_blueprint_f    { $_[0]->_data_f( GET => '/managed/blueprints/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_blueprint_f { $_[0]->_data_f( POST => '/managed/blueprints/', $_[1] ) }
sub apply_blueprint_f  { $_[0]->_data_f( POST => '/managed/blueprints/'.$_[0]->_esc( $_[1] ).'/apply/', {} ) }
sub delete_blueprint_f { $_[0]->_done_f( DELETE => '/managed/blueprints/'.$_[0]->_esc( $_[1] ).'/' ) }


####  resolve

async sub resolve_f {
  my ( $self, $rep ) = @_;
  my %out    = %$rep;
  my $fields = $self->resolvable_fields;
  if ( exists $out{scopes} ) {
    die $self->validation_error_class->new( message => 'give either scopes or property_mappings, not both' )
      if exists $out{property_mappings} || exists $out{property_mapping_names};
    my $scopes = delete $out{scopes};
    # an undef here is a mistake in the caller, and a costly one: taking it
    # for an empty list would strip every mapping off the provider
    die $self->validation_error_class->new( message => 'scopes is undef: give a list of scope names, '
      .'or an empty list to take every mapping away' )
      unless defined $scopes;
    die $self->validation_error_class->new( message => 'scopes takes a list of scope names' )
      unless ref $scopes eq 'ARRAY';
    $out{property_mappings} = [ map { $_->{pk} } @{ await $self->find_scope_mappings_by_scope_f(@$scopes) } ];
  }
  for my $field ( sort keys %$fields ) {
    my $spec   = $fields->{$field};
    my $forced = exists $out{ $spec->{force} };
    die $self->validation_error_class->new( message => 'give either '.$field.' or '.$spec->{force}.', not both' )
      if $forced && exists $out{$field};
    next unless $forced || exists $out{$field};
    my $value = $forced ? delete $out{ $spec->{force} } : $out{$field};
    # the forced form says "look this name up", so an undef there is a
    # mistake, not a wish to leave the field alone
    die $self->validation_error_class->new( message => $spec->{force}.' is undef: give a name to look up, '
      .'or '.$field.' to set the identifier itself' )
      if $forced && !defined $value;
    next unless defined $value;
    if ( $spec->{list} ) {
      # a for loop with a lexical, not a statement modifier: await needs one
      my @resolved;
      for my $one ( @{ ref $value eq 'ARRAY' ? $value : [$value] } ) {
        push @resolved, await $self->_resolve_one_f( $field, $spec, $one, $forced );
      }
      $out{$field} = \@resolved;
    }
    else {
      $out{$field} = await $self->_resolve_one_f( $field, $spec, $value, $forced );
    }
  }
  return \%out;
}

async sub _resolve_one_f {
  my ( $self, $field, $spec, $value, $forced ) = @_;
  die $self->validation_error_class->new( message => 'cannot set '.$field.': expected '.$spec->{what}
    .' as a name or an identifier, got a '.lc( ref $value ).' reference' )
    if ref $value;
  return $value if !$forced && $value =~ $spec->{raw};
  my $find  = $spec->{find}.'_f';
  my $found = await $self->$find($value);
  die $self->validation_error_class->new( message => 'cannot set '.$field.': no '.$spec->{what}.' named "'.$value.'"' )
    unless $found;
  return $found->{pk};
}


####  ensure

async sub _ensure_f {
  my ( $self, %arg ) = @_;
  my $current = await $arg{find}->();
  unless ($current) {
    my $object = await $arg{create}->();
    await $arg{after_create}->($object) if $arg{after_create};
    return { object => $object, changed => 'created' };
  }
  my $changes = $self->diff_class->changes( $current, $arg{wanted} );
  return { object => $current, changed => '' } unless %$changes;
  return { object => await $arg{update}->( $current, $changes ), changed => 'updated' };
}

async sub ensure_user_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('ensure_user_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %rep = %$pairs;
  return await $self->fail_validation('ensure_user needs a username') unless defined $rep{username};
  my $wanted   = await $self->resolve_f( \%rep );
  my $password = delete $wanted->{password};
  return await $self->_ensure_f(
    wanted => $wanted,
    find   => sub { $self->find_user_f( $rep{username} ) },
    create => sub { $self->create_user_f($wanted) },
    # a password is set when the user is created and never again, so running
    # a setup twice does not reset it; call set_password_f to change one
    after_create => sub { defined $password ? $self->set_password_f( $_[0]{pk}, $password ) : Future->done },
    update => sub { $self->update_user_f( $_[0]{pk}, $_[1] ) }
  );
}

async sub ensure_group_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('ensure_group_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %rep = %$pairs;
  return await $self->fail_validation('ensure_group needs a name') unless defined $rep{name};
  my $wanted = await $self->resolve_f( \%rep );
  return await $self->_ensure_f(
    wanted => $wanted,
    find   => sub { $self->find_group_f( $rep{name} ) },
    create => sub { $self->create_group_f($wanted) },
    update => sub { $self->update_group_f( $_[0]{pk}, $_[1] ) }
  );
}

async sub ensure_token_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('ensure_token_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %rep = %$pairs;
  return await $self->fail_validation('ensure_token needs an identifier') unless defined $rep{identifier};
  # authentik ignores expires and sets it from default_token_duration, so a
  # wanted value could never be reached and would report updated for ever
  return await $self->fail_validation( 'ensure_token cannot set expires: authentik ignores it and '
    .'sets the expiry from the instance setting default_token_duration. Use expiring to say whether it expires at all.' )
    if exists $rep{expires};
  my $wanted = await $self->resolve_f( \%rep );
  my $key    = delete $wanted->{key};
  return await $self->_ensure_f(
    wanted => $wanted,
    find   => sub { $self->find_token_f( $rep{identifier} ) },
    create => sub { $self->create_token_f($wanted) },
    # like a password: the key is put on the token when it is created
    after_create => sub { defined $key ? $self->set_token_key_f( $rep{identifier}, $key ) : Future->done },
    update => sub { $self->update_token_f( $rep{identifier}, $_[1] ) }
  );
}

async sub ensure_application_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('ensure_application_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %rep = %$pairs;
  return await $self->fail_validation('ensure_application needs a slug') unless defined $rep{slug};
  my $wanted = await $self->resolve_f( \%rep );
  return await $self->_ensure_f(
    wanted => $wanted,
    find   => sub { $self->find_application_f( $rep{slug} ) },
    create => sub { $self->create_application_f($wanted) },
    update => sub { $self->update_application_f( $rep{slug}, $_[1] ) }
  );
}

async sub ensure_oauth2_provider_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('ensure_oauth2_provider_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %rep = %$pairs;
  return await $self->fail_validation('ensure_oauth2_provider needs a name') unless defined $rep{name};
  my $wanted = await $self->resolve_f( \%rep );
  return await $self->_ensure_f(
    wanted => $wanted,
    find   => sub { $self->find_oauth2_provider_f( $rep{name} ) },
    create => sub {
      # authentik defaults grant_types to an empty list, and a provider with
      # an empty list answers every token request with invalid_grant. Which
      # grants were meant is not something this client guesses.
      return $self->fail_validation( 'ensure_oauth2_provider needs grant_types to create a provider: '
        .'authentik would store an empty list, and such a provider answers every token request with invalid_grant' )
        unless ref $wanted->{grant_types} eq 'ARRAY' && @{ $wanted->{grant_types} };
      return $self->create_oauth2_provider_f($wanted);
    },
    update => sub { $self->update_oauth2_provider_f( $_[0]{pk}, $_[1] ) }
  );
}

async sub ensure_scope_mapping_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('ensure_scope_mapping_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %rep = %$pairs;
  return await $self->fail_validation('ensure_scope_mapping needs a name') unless defined $rep{name};
  my $wanted = await $self->resolve_f( \%rep );
  return await $self->_ensure_f(
    wanted => $wanted,
    find   => sub { $self->find_scope_mapping_f( $rep{name} ) },
    create => sub { $self->create_scope_mapping_f($wanted) },
    update => sub { $self->update_scope_mapping_f( $_[0]{pk}, $_[1] ) }
  );
}

async sub ensure_flow_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('ensure_flow_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %rep = %$pairs;
  return await $self->fail_validation('ensure_flow needs a slug') unless defined $rep{slug};
  my $wanted = await $self->resolve_f( \%rep );
  return await $self->_ensure_f(
    wanted => $wanted,
    find   => sub { $self->find_flow_f( $rep{slug} ) },
    create => sub { $self->create_flow_f($wanted) },
    update => sub { $self->update_flow_f( $rep{slug}, $_[1] ) }
  );
}

async sub ensure_stage_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 2, @_ );
  return await $_[0]->fail_validation('ensure_stage_f: the arguments after the first 1 do not make pairs') unless $ok;
  my ( $self, $type ) = @_;
  my %rep = %$pairs;
  return await $self->fail_validation('ensure_stage needs a name') unless defined $rep{name};
  my ( $path, $bad ) = $self->_stage_path($type);
  return await $bad if $bad;
  my $wanted = await $self->resolve_f( \%rep );
  return await $self->_ensure_f(
    wanted => $wanted,
    find   => sub {
      my $find = async sub {
        my $stage = await $self->find_stage_f( $rep{name} );
        return undef unless $stage;
        # a stage name is unique across all types, so a name that belongs to
        # another type is a clash, not something to create or update
        my $whole = eval { await $self->get_stage_f( $type, $stage->{pk} ) };
        my $error = $@;
        return $whole if $whole;
        die $error unless blessed $error && $error->isa('WWW::Authentik::Error::API') && $error->is_not_found;
        die $self->validation_error_class->new( message => 'ensure_stage: there already is a stage named "'
          .$rep{name}.'", but not of the type '.$type.' ('.( $stage->{component} // 'unknown component' ).'). '
          .'Stage names are unique across all types in authentik.' );
      };
      return $find->();
    },
    create => sub { $self->create_stage_f( $type, $wanted ) },
    update => sub { $self->update_stage_f( $type, $_[0]{pk}, $_[1] ) }
  );
}

async sub ensure_binding_f {
  my ( $ok, $pairs ) = __PACKAGE__->pairs_or_fail( 1, @_ );
  return await $_[0]->fail_validation('ensure_binding_f: the arguments after the first 0 do not make pairs') unless $ok;
  my ( $self ) = @_;
  my %arg = %$pairs;
  for my $needed (qw( flow stage order )) {
    return await $self->fail_validation( 'ensure_binding needs '.$needed ) unless defined $arg{$needed};
  }
  my %wanted = %arg;
  # only "there is no such flow" becomes a validation error here; a refused
  # request or a 500 has to stay what it is instead of being reported as a
  # missing flow
  my $flow = delete $wanted{flow};
  unless ( $flow =~ $self->uuid_pattern ) {
    my $found = await $self->find_flow_f($flow);
    return await $self->fail_validation( 'ensure_binding: no flow "'.$flow.'"' ) unless $found;
    $flow = $found->{pk};
  }
  my $stage = $wanted{stage};
  unless ( $stage =~ $self->uuid_pattern ) {
    my $found = await $self->find_stage_f($stage);
    return await $self->fail_validation( 'ensure_binding: no stage "'.$stage.'"' ) unless $found;
    $stage = $found->{pk};
  }
  @wanted{qw( target stage )} = ( $flow, $stage );
  return await $self->_ensure_f(
    wanted => \%wanted,
    # a flow binds a stage at most once here; the order is what ensure moves
    find   => async sub { $self->_find_one( await( $self->list_bindings_f( target => $flow, stage => $stage ) ), 'stage', $stage ) },
    create => sub { $self->create_binding_f( \%wanted ) },
    update => sub { $self->update_binding_f( $_[0]{pk}, $_[1] ) }
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Authentik::API - authentik REST API v3, asynchronously, with idempotent ensure methods

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $api = $ak->api;

    my $user = await $api->find_user_f('alice');
    my $r    = await $api->ensure_user_f( username => 'alice', name => 'Alice', group_names => ['staff'] );
    print $r->{changed};        # 'created', 'updated' or ''

=head1 DESCRIPTION

The asynchronous L<WWW::Authentik::API>: every method with C<_f>, returning a
future of what the synchronous method returns. The rules of the
C<ensure_*_f> methods are the same, the comparison is the same
L<WWW::Authentik::Diff>, and names are resolved from the same table, so both
clients do the same thing to an authentik.

Nothing throws. A missing argument, a missing token or a name nothing matches
fails the future.

=head2 base_url

Required. The authentik URL without C</api/v3>.

=head2 token

The API token, sent as a bearer token with every call. Without it every
method fails with a validation error.

=head2 http

Required. The L<Net::Async::HTTP> to send through.

=head2 page_size

How many objects a C<list_*_f> asks for per request. Default 100.

=head2 diff_class

The class the C<ensure_*_f> methods compare with, L<WWW::Authentik::Diff> —
the synchronous client's, so the two cannot drift.

=head2 resolvable_fields

=head2 uuid_pattern

=head2 integer_pattern

The table L</resolve_f> works from and the two shapes it takes for an
identifier, all three taken from L<WWW::Authentik::API> rather than written
again, so that what counts as an identifier is decided in one place. The
lookup method named in the table is used with C<_f> appended.

=head2 api_url

    print $api->api_url;   # https://id.example.org/api/v3

=head2 call_f

    my $result = await $api->call_f( GET => '/core/users/?username=alice' );
    my $result = await $api->call_f( POST => '/core/groups/', { name => 'staff' } );

One request against the API, as C<call> in L<WWW::Authentik::API>. Mind the
trailing slash: authentik answers a path without one with 404.

=head2 version_f

=head2 config_f

=head2 settings_f

=head2 me_f

As in L<WWW::Authentik::API>.

=head2 list_users_f

=head2 find_user_f

=head2 get_user_f

=head2 create_user_f

=head2 update_user_f

=head2 delete_user_f

=head2 set_password_f

=head2 create_service_account_f

=head2 list_authenticators_f

As in L<WWW::Authentik::API>. C<find_user_f> matches the username exactly and
case-sensitively.

=head2 list_groups_f

=head2 find_group_f

=head2 get_group_f

=head2 create_group_f

=head2 update_group_f

=head2 delete_group_f

=head2 add_user_to_group_f

=head2 remove_user_from_group_f

As in L<WWW::Authentik::API>.

=head2 list_tokens_f

=head2 find_token_f

=head2 get_token_f

=head2 create_token_f

=head2 update_token_f

=head2 delete_token_f

=head2 view_token_key_f

=head2 set_token_key_f

As in L<WWW::Authentik::API>. C<expires> cannot be chosen; authentik sets it
from C<default_token_duration>.

=head2 list_applications_f

=head2 find_application_f

=head2 create_application_f

=head2 update_application_f

=head2 delete_application_f

=head2 check_access_f

As in L<WWW::Authentik::API>, including what a stale C<for_user> does.

=head2 list_oauth2_providers_f

=head2 find_oauth2_provider_f

=head2 get_oauth2_provider_f

=head2 create_oauth2_provider_f

=head2 update_oauth2_provider_f

=head2 delete_oauth2_provider_f

=head2 provider_setup_urls_f

=head2 preview_user_f

As in L<WWW::Authentik::API>.

=head2 list_scope_mappings_f

=head2 find_scope_mapping_f

=head2 find_scope_mappings_by_scope_f

=head2 get_scope_mapping_f

=head2 create_scope_mapping_f

=head2 update_scope_mapping_f

=head2 delete_scope_mapping_f

=head2 test_property_mapping_f

As in L<WWW::Authentik::API>.

=head2 list_flows_f

=head2 find_flow_f

=head2 create_flow_f

=head2 update_flow_f

=head2 delete_flow_f

=head2 export_flow_f

As in L<WWW::Authentik::API>. C<export_flow_f> gives the YAML back as a
string.

=head2 stage_types_f

=head2 list_stages_f

=head2 find_stage_f

=head2 get_stage_f

=head2 create_stage_f

=head2 update_stage_f

=head2 delete_stage_f

As in L<WWW::Authentik::API>. C<$type> is the path under C</stages/>;
C<all> is refused, because that endpoint can only be read.

=head2 list_bindings_f

    my $bindings = await $api->list_bindings_f( flow => 'my-flow' );

=head2 get_binding_f

=head2 create_binding_f

=head2 update_binding_f

=head2 delete_binding_f

As in L<WWW::Authentik::API>.

=head2 list_brands_f

=head2 current_brand_f

The brand that applies to this request, as the public view: it has neither
C<brand_uuid> nor C<domain>, so it cannot be handed to L</update_brand_f>.
Take the brand from L</list_brands_f> to change one, as in
L<WWW::Authentik::API/current_brand>.

=head2 update_brand_f

=head2 list_certificates_f

=head2 find_certificate_f

=head2 list_blueprints_f

=head2 get_blueprint_f

=head2 create_blueprint_f

=head2 apply_blueprint_f

=head2 delete_blueprint_f

As in L<WWW::Authentik::API>.

=head2 resolve_f

    my $rep = await $api->resolve_f( { authorization_flow => 'default-authentication-flow' } );

As C<resolve> in L<WWW::Authentik::API>, and from the same table: for every
field one shape counts as the identifier and everything else is a name, with
C<< <field>_name >> or C<< <field>_slug >> forcing the lookup. See
L<WWW::Authentik::API/resolve> for the table itself.

=head2 ensure_user_f

=head2 ensure_group_f

=head2 ensure_token_f

=head2 ensure_application_f

=head2 ensure_oauth2_provider_f

=head2 ensure_scope_mapping_f

=head2 ensure_flow_f

=head2 ensure_stage_f

=head2 ensure_binding_f

As the C<ensure_*> methods of L<WWW::Authentik::API>, returning a future of
C<< { object => \%rep, changed => 'created' | 'updated' | '' } >>. The same
keys are looked up, the same comparison is made, and the same things are
refused.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-authentik/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
