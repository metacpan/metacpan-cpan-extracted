package Silki::Schema::User;
{
  $Silki::Schema::User::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use feature ':5.10';

use Authen::Passphrase::BlowfishCrypt;
use DateTime;
use Digest::SHA qw( sha1_hex );
use Fey::Literal::Function;
use Fey::Object::Iterator::FromSelect;
use Fey::ORM::Exceptions qw( no_such_row );
use Fey::Placeholder;
use List::AllUtils qw( all any none first first_index );
use Moose::Util::TypeConstraints;
use Silki::Email qw( send_email );
use Silki::I18N qw( loc );
use Silki::Schema;
use Silki::Schema::Domain;
use Silki::Schema::Page;
use Silki::Schema::Permission;
use Silki::Schema::Role;
use Silki::Types qw( Int Str Bool );
use Silki::Util qw( string_is_empty );

use Fey::ORM::Table;
use MooseX::ClassAttribute;
use MooseX::Params::Validate qw( pos_validated_list validated_list );

my $Schema = Silki::Schema->Schema();

with 'Silki::Role::Schema::URIMaker';

with 'Silki::Role::Schema::SystemLogger' =>
    { methods => [ 'insert', 'update', 'delete' ] };

with 'Silki::Role::Schema::DataValidator' => {
    steps => [
        '_has_password_or_openid_uri',
        '_email_address_is_unique',
        '_normalize_and_validate_openid_uri',
        '_openid_uri_is_unique',
    ],
};

has_policy 'Silki::Schema::Policy';

has_table( $Schema->table('User') );

has_one 'creator' => ( table => $Schema->table('User') );

has_one 'image' => (
    table => $Schema->table('UserImage'),
    undef => 1,
);

has_many 'pages' => ( table => $Schema->table('Page') );

has best_name => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_best_name',
    clearer => '_clear_best_name',
);

has has_valid_password => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_has_valid_password',
    clearer => '_clear_has_valid_password',
);

has has_login_credentials => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_has_login_credentials',
    clearer => '_clear_has_login_credentials',
);

class_has _RoleInWikiSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildRoleInWikiSelect',
);

class_has _MemberWikiCountSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildMemberWikiCountSelect',
);

class_has _MemberWikiSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildMemberWikiSelect',
);

class_has _AllWikiCountSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildAllWikiCountSelect',
);

class_has _AllWikiSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildAllWikiSelect',
);

class_has _SharedWikiSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Union',
    lazy    => 1,
    builder => '_BuildSharedWikiSelect',
);

class_has _RecentlyViewedPagesSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildRecentlyViewedPagesSelect',
);

class_has _AllPageCountSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildAllPageCountSelect',
);

class_has _AllRevisionCountSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildAllRevisionCountSelect',
);

class_has _AllFileCountSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildAllFileCountSelect',
);

class_has 'SystemUser' => (
    is      => 'ro',
    isa     => __PACKAGE__,
    lazy    => 1,
    default => sub { __PACKAGE__->_FindOrCreateSystemUser() },
);

class_has 'GuestUser' => (
    is      => 'ro',
    isa     => __PACKAGE__,
    lazy    => 1,
    default => sub { __PACKAGE__->_FindOrCreateGuestUser() },
);

class_has _ActiveUserCountSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildActiveUserCountSelect',
);

class_has _ActiveUsersSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildActiveUsersSelect',
);

class_has _AllUsersSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildAllUsersSelect',
);

class_has _AllRevisionsForDeleteSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildAllRevisionsForDeleteSelect',
);

{
    my $select = __PACKAGE__->_MemberWikiCountSelect();

    query member_wiki_count => (
        select      => $select,
        bind_params => sub { $_[0]->user_id(), $select->bind_params() },
    );
}

{
    my $select = __PACKAGE__->_MemberWikiSelect();

    has_many member_wikis => (
        table       => $Schema->table('Wiki'),
        select      => $select,
        bind_params => sub { $_[0]->user_id(), $select->bind_params() },
    );
}

{
    my $select = __PACKAGE__->_AllWikiCountSelect();

    query all_wiki_count => (
        select      => $select,
        bind_params => sub { ( $_[0]->user_id() ) x 3 },
    );
}

{
    my $select = __PACKAGE__->_AllWikiSelect();

    has_many all_wikis => (
        table       => $Schema->table('Wiki'),
        select      => $select,
        bind_params => sub { ( $_[0]->user_id() ) x 3 },
    );
}

{
    my $select = __PACKAGE__->_AllPageCountSelect();

    query page_count => (
        select      => $select,
        bind_params => sub { ( $_[0]->user_id() ) },
    );
}

{
    my $select = __PACKAGE__->_AllRevisionCountSelect();

    query revision_count => (
        select      => $select,
        bind_params => sub { ( $_[0]->user_id() ) },
    );
}

{
    my $select = __PACKAGE__->_AllFileCountSelect();

    query file_count => (
        select      => $select,
        bind_params => sub { ( $_[0]->user_id() ) },
    );
}

with 'Silki::Role::Schema::Serializes' => {
    skip => ['password'],
};

my $UnusablePW = '*unusable*';
around insert => sub {
    my $orig  = shift;
    my $class = shift;
    my %p     = @_;

    if ( $p{requires_activation} && $p{disable_login} ) {
        die loc(
            'Cannot pass requires_activation and disable_login when inserting a user'
        );
    }

    if ( delete $p{requires_activation} ) {
        $p{confirmation_key}
            = $class->_make_confirmation_key( $p{email_address} );

        $p{password} = $UnusablePW;
    }
    elsif ( delete $p{disable_login} ) {
        $p{password}         = $UnusablePW;
        $p{openid_uri}       = undef;
        $p{confirmation_key} = undef;
    }
    elsif ( defined $p{password} ) {
        $p{password} = $class->_password_as_rfc2307( $p{password} );
    }

    $p{username} //= $p{email_address};

    $p{created_by_user_id} = $p{user}->user_id()
        if $p{user};

    return $class->$orig(%p);
};

around update => sub {
    my $orig = shift;
    my $self = shift;
    my %p    = @_;

    if (  !string_is_empty( $p{email_address} )
        && string_is_empty( $p{username} )
        && $self->username() eq $self->email_address() ) {
        $p{username} = $p{email_address};
    }

    unless ( string_is_empty( $p{password} ) ) {
        $p{password} = $self->_password_as_rfc2307( $p{password} );
    }

    if ( delete $p{disable_login} ) {
        $p{password}         = $UnusablePW;
        $p{openid_uri}       = undef;
        $p{confirmation_key} = undef;
    }

    $p{last_modified_datetime} = Fey::Literal::Function->new('NOW');

    return $self->$orig(%p);
};

after update => sub {
    $_[0]->_clear_best_name();
    $_[0]->_clear_has_valid_password();
    $_[0]->_clear_has_login_credentials();
};

around delete => sub {
    my $orig = shift;
    my $self = shift;
    my %p    = @_;

    Silki::Schema->RunInTransaction(
        sub {
            my $revisions = $self->_all_revisions_for_delete();
            while ( my $revision = $revisions->next() ) {
                $revision->delete( user => $p{user} );
            }

            $self->$orig(%p);
        }
    );
};

sub _system_log_values_for_insert {
    my $class = shift;
    my %p     = @_;

    my $msg = 'Created user: ' . $p{username};

    return (
        message   => $msg,
        data_blob => \%p,
    );
}

sub _system_log_values_for_update {
    my $self = shift;
    my %p    = @_;

    my $msg;
    if (   exists $p{is_disabled}
        && $p{is_disabled}
        && !$self->is_disabled() ) {

        $msg = 'Disabled user';
    }
    elsif ($self->is_disabled()
        && exists $p{is_disabled}
        && !$p{is_disabled} ) {

        $msg = 'Enabled user';
    }
    else {
        $msg = 'Updated user';
    }

    $msg .= ': ' . $self->best_name();

    my %blob = %p;
    delete $blob{last_modified_datetime};

    return (
        message   => $msg,
        data_blob => \%blob,
    );
}

sub _system_log_values_for_delete {
    my $self = shift;

    my $msg
        = 'Deleted user '
        . $self->best_name() . ' - '
        . ( $self->email_address() || $self->openid_uri() );

    return (
        message   => $msg,
        data_blob => {
            map { $_ => $self->$_() }
                qw(
                email_address
                username
                openid_uri
                display_name
                time_zone
                locale_code
                )
        }
    );
}

sub _make_confirmation_key {
    shift;

    return sha1_hex(
        shift, time, $$, rand(1_000_000_000),
        Silki::Config->instance()->secret()
    );
}

sub _password_as_rfc2307 {
    my $self = shift;
    my $pw   = shift;

    # XXX - require a certain length or complexity? make it
    # configurable?
    my $pass = Authen::Passphrase::BlowfishCrypt->new(
        cost        => 8,
        salt_random => 1,
        passphrase  => $pw,
    );

    return $pass->as_rfc2307();
}

sub _has_password_or_openid_uri {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    my $error = { message => loc('You must provide a password or OpenID.') };

    if ($is_insert) {

        # coverage - this is never going to be true if the around modifier on
        # insert defined above runs first, because it deletes the
        # disable_login parameter and sets a crypted password in the params
        # hash.
        return if $p->{disable_login};

        return $error
            if all { string_is_empty( $p->{$_} ) } qw( password openid_uri );

        return;
    }
    else {
        my $preserve_pw = delete $p->{preserve_password};

        # The preserve_password param will be set when a user is updated via a
        # preferences form of some sort. If they already have a valid
        # password, an empty password field in that form does not indicate
        # that the password in the dbms should be set to NULL.
        if (   exists $p->{password}
            && string_is_empty( $p->{password} )
            && $self->has_valid_password()
            && $preserve_pw ) {
            delete $p->{password};

            return;
        }

        return $error
            if all { exists $p->{$_} && string_is_empty( $p->{$_} ) }
            qw( password openid_uri );

        return
            if any { !string_is_empty( $p->{$_} ) } qw( password openid_uri );

        return if none { exists $p->{$_} } qw( password openid_uri );

        if ( exists $p->{password} && string_is_empty( $p->{password} ) ) {
            return unless string_is_empty( $self->openid_uri() );
        }
        elsif ( exists $p->{openid_uri}
            && string_is_empty( $p->{openid_uri} ) ) {
            return unless string_is_empty( $self->password() );
        }

        return $error;
    }
}

sub _email_address_is_unique {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return if string_is_empty( $p->{email_address} );

    return if !$is_insert && $self->email_address() eq $p->{email_address};

    return unless __PACKAGE__->new( email_address => $p->{email_address} );

    return {
        field   => 'email_address',
        message => loc(
            'The email address you provided is already in use by another user.'
        ),
    };
}

sub _normalize_and_validate_openid_uri {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return if string_is_empty( $p->{openid_uri} );

    my $uri = URI->new( $p->{openid_uri} );

    unless ( defined $uri->scheme()
        && $uri->scheme() =~ /^https?/ ) {
        return {
            field   => 'openid_uri',
            message => loc('The OpenID you provided is not a valid URI.'),
        };
    }

    $p->{openid_uri} = $uri->canonical() . q{};

    return;
}

sub _openid_uri_is_unique {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return if string_is_empty( $p->{openid_uri} );

    return
        if !$is_insert
            && $self->openid_uri()
            && $self->openid_uri() eq $p->{openid_uri};

    return unless __PACKAGE__->new( openid_uri => $p->{openid_uri} );

    return {
        field   => 'openid_uri',
        message => loc(
            'The OpenID URI you provided is already in use by another user.'
        ),
    };
}

sub _base_uri_path {
    my $self = shift;

    return '/user/' . $self->user_id();
}

sub domain {
    my $self = shift;

    my $wiki = $self->member_wikis()->next();
    $wiki ||= $self->all_wikis()->next();

    return $wiki ? $wiki->domain() : Silki::Schema::Domain->DefaultDomain();
}

sub EnsureRequiredUsersExist {
    my $class = shift;

    $class->_FindOrCreateSystemUser();

    $class->_FindOrCreateGuestUser();
}

{
    my $SystemUsername = 'system-user';

    sub _FindOrCreateSystemUser {
        my $class = shift;

        return $class->_FindOrCreateSpecialUser($SystemUsername);
    }
}

{
    my $GuestUsername = 'guest-user';

    sub _FindOrCreateGuestUser {
        my $class = shift;

        return $class->_FindOrCreateSpecialUser(
            $GuestUsername,
            Silki::Schema::User->SystemUser(),
        );
    }

    sub is_guest {
        my $self = shift;

        return $self->username() eq $GuestUsername;
    }
}

sub _FindOrCreateSpecialUser {
    my $class    = shift;
    my $username = shift;
    my $creator  = shift;

    my $user = eval { $class->new( username => $username ) };

    return $user if $user;

    return $class->_CreateSpecialUser( $username, $creator );
}

sub _CreateSpecialUser {
    my $class    = shift;
    my $username = shift;
    my $creator  = shift;

    my $domain = Silki::Schema::Domain->DefaultDomain();

    my $email = 'silki-' . $username . q{@} . $domain->email_hostname();

    my $display_name = join ' ', map {ucfirst} split /-/, $username;

    local $Silki::Role::Schema::SystemLogger::SkipLog = 1
        unless $creator;

    return $class->insert(
        display_name   => $display_name,
        username       => $username,
        email_address  => $email,
        password       => q{},
        disable_login  => 1,
        is_system_user => 1,
        user           => $creator,
    );
}

sub set_time_zone_for_dt {
    my $self = shift;
    my $dt   = shift;

    return $dt->clone()->set_time_zone( $self->time_zone() );
}

sub _build_best_name {
    my $self = shift;

    return $self->display_name() if length $self->display_name;

    my $username = $self->username();

    if ( $username =~ /\@/ ) {
        $username =~ s/\@.+$//;
    }

    return $username;
}

sub _build_has_valid_password {
    my $self = shift;

    return 0 if string_is_empty( $self->password() );
    return 0 unless $self->_password_is_encrypted();

    return 1;
}

sub _build_has_login_credentials {
    my $self = shift;

    return 1 if !string_is_empty( $self->openid_uri() );

    return 1 if $self->has_valid_password();

    return 0;
}

sub _password_is_encrypted {
    my $self = shift;

    return $self->password() =~ /^{CRYPT}/ ? 1 : 0;
}

sub requires_activation {
    my $self = shift;

    return defined $self->confirmation_key() && !$self->has_valid_password();
}

sub confirmation_uri {
    my $self = shift;
    my %p    = @_;

    die loc(
        'Cannot make a confirmation uri for a user who does not have a confirmation key.'
    ) unless defined $self->confirmation_key();

    my $view = $p{view} || 'preferences_form';

    $p{view} = 'confirmation/' . $self->confirmation_key() . q{/} . $view;

    return $self->uri(%p);
}

sub check_password {
    my $self = shift;
    my $pw   = shift;

    return if $self->is_system_user();

    return unless $self->has_valid_password();

    my $pass = Authen::Passphrase::BlowfishCrypt->from_rfc2307(
        $self->password() );

    return $pass->match($pw);
}

sub is_authenticated {
    my $self = shift;

    return !$self->is_system_user();
}

sub can_edit_user {
    my $self = shift;
    my $user = shift;

    return 0 if $user->is_system_user();

    return 1 if $self->is_admin();

    return 1 if $self->user_id() == $user->user_id();

    return 0;
}

sub has_permission_in_wiki {
    my $self = shift;

    return 1 if $self->is_admin();

    my ( $wiki, $perm ) = validated_list(
        \@_,
        wiki       => { isa => 'Silki::Schema::Wiki' },
        permission => { isa => 'Silki::Schema::Permission' },
    );

    my $perms = $wiki->permissions();

    my $role = $self->role_in_wiki($wiki);

    return $perms->{ $role->name() }{ $perm->name() };
}

sub is_wiki_member {
    my $self = shift;
    my ($wiki) = pos_validated_list( \@_, { isa => 'Silki::Schema::Wiki' } );

    my $role_name = $self->_role_name_in_wiki($wiki);

    return defined $role_name;
}

sub role_in_wiki {
    my $self = shift;
    my ($wiki) = pos_validated_list( \@_, { isa => 'Silki::Schema::Wiki' } );

    return Silki::Schema::Role->Guest() if $self->is_guest();

    my $role_name = $self->_role_name_in_wiki($wiki);

    $role_name ||= 'Authenticated';

    return Silki::Schema::Role->$role_name();
}

sub _role_name_in_wiki {
    my $self = shift;
    my $wiki = shift;

    my $select = $self->_RoleInWikiSelect();

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    my $row = $dbh->selectrow_arrayref(
        $select->sql($dbh),
        {},
        $wiki->wiki_id(),
        $self->user_id(),
    );

    return unless $row;

    return $row->[0];
}

sub _BuildRoleInWikiSelect {
    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $select
        ->select( $Schema->table('Role')->column('name') )
        ->from( $Schema->table('Role'), $Schema->table('UserWikiRole') )
        ->where( $Schema->table('UserWikiRole')->column('wiki_id'),
                 '=', Fey::Placeholder->new() )
        ->and( $Schema->table('UserWikiRole')->column('user_id'),
               '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub _BuildMemberWikiCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $distinct = Fey::Literal::Term->new(
        'DISTINCT ',
        $Schema->table('Wiki')->column('wiki_id')
    );
    my $count = Fey::Literal::Function->new( 'COUNT', $distinct );

    $select->select($count);
    $class->_MemberWikiSelectBase($select);

    return $select;
}

sub _BuildMemberWikiSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    $select->select( $Schema->table('Wiki') );
    $class->_MemberWikiSelectBase($select);
    $select->order_by( $Schema->table('Wiki')->column('title') );

    return $select;
}

sub _MemberWikiSelectBase {
    my $class  = shift;
    my $select = shift;

    my $guest  = Silki::Schema::Role->Guest();
    my $authed = Silki::Schema::Role->Authenticated();
    my $read   = Silki::Schema::Permission->Read();

    #<<<
    $select
        ->from( $Schema->table('Wiki'), $Schema->table('UserWikiRole') )
        ->where( $Schema->table('UserWikiRole')->column('user_id'),
                 '=', Fey::Placeholder->new() );
    #>>>
    return;
}

sub wikis_shared_with {
    my $self = shift;
    my $user = shift;

    my $select = $self->_SharedWikiSelect();

    return Fey::Object::Iterator::FromSelect->new(
        classes => ['Silki::Schema::Wiki'],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [
            $self->user_id(), $user->user_id(),
            $self->user_id(), $self->user_id(),
            $user->user_id(), $user->user_id(),
        ],
    );
}

sub _BuildSharedWikiSelect {
    my $class = shift;

    my $explicit_wiki_select = Silki::Schema->SQLFactoryClass()->new_select();

    $explicit_wiki_select->select( $Schema->table('Wiki') );
    $class->_ExplicitWikiSelectBase($explicit_wiki_select);

    my $implicit_wiki_select = Silki::Schema->SQLFactoryClass()->new_select();

    $implicit_wiki_select->select( $Schema->table('Wiki') );
    $class->_ImplicitWikiSelectBase($implicit_wiki_select);

    my $intersect1 = Silki::Schema->SQLFactoryClass()->new_intersect;
    $intersect1->intersect( $explicit_wiki_select, $explicit_wiki_select );

    my $intersect2 = Silki::Schema->SQLFactoryClass()->new_intersect;
    $intersect2->intersect( $implicit_wiki_select, $implicit_wiki_select );

    my $union = Silki::Schema->SQLFactoryClass()->new_union;

    # To use an ORDER BY with a UNION in Pg, you specify the column as a
    # number (ORDER BY 5).
    my $title_idx = first_index { $_->name() eq 'title' }
    $Schema->table('Wiki')->columns();
    #<<<
    $union
        ->union( $intersect1, $intersect2 )
        ->order_by( Fey::Literal::Term->new($title_idx) );
    #>>>
    return $union;
}

sub _BuildAllWikiCountSelect {
    my $class = shift;

    my $explicit_wiki_select = Silki::Schema->SQLFactoryClass()->new_select();

    $explicit_wiki_select->select(
        $Schema->table('Wiki')->column('wiki_id') );
    $class->_ExplicitWikiSelectBase($explicit_wiki_select);

    my $implicit_wiki_select = Silki::Schema->SQLFactoryClass()->new_select();

    $implicit_wiki_select->select(
        $Schema->table('Wiki')->column('wiki_id') );
    $class->_ImplicitWikiSelectBase($implicit_wiki_select);

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $distinct = Fey::Literal::Term->new(
        'DISTINCT ',
        $Schema->table('Wiki')->column('wiki_id')
    );
    my $count = Fey::Literal::Function->new( 'COUNT', $distinct );

    #<<<
    $select
        ->select($count)->from( $Schema->table('Wiki') )
        ->where( $Schema->table('Wiki')->column('wiki_id'),
                 'IN', $explicit_wiki_select )
        ->where('or')
        ->where( $Schema->table('Wiki')->column('wiki_id'),
                 'IN', $implicit_wiki_select );
    #>>>
    return $select;
}

sub _BuildAllWikiSelect {
    my $class = shift;

    my $explicit_wiki_select = Silki::Schema->SQLFactoryClass()->new_select();

    my $is_explicit1 = Fey::Literal::Term->new('1 AS is_explicit');
    $is_explicit1->set_can_have_alias(0);
    $explicit_wiki_select->select( $Schema->table('Wiki'), $is_explicit1 );
    $class->_ExplicitWikiSelectBase($explicit_wiki_select);

    my $implicit_wiki_select = Silki::Schema->SQLFactoryClass()->new_select();

    my $is_explicit0 = Fey::Literal::Term->new('0 AS is_explicit');
    $is_explicit0->set_can_have_alias(0);
    $implicit_wiki_select->select( $Schema->table('Wiki'), $is_explicit0 );
    $class->_ImplicitWikiSelectBase($implicit_wiki_select);

    my $union = Silki::Schema->SQLFactoryClass()->new_union;

    # To use an ORDER BY with a UNION in Pg, you specify the column as a
    # number (ORDER BY 5).
    my $is_explicit_idx = ( scalar $Schema->table('Wiki')->columns() ) + 1;

    my $title_idx = first_index { $_->name() eq 'title' }
    $Schema->table('Wiki')->columns();

    $union->union( $explicit_wiki_select, $implicit_wiki_select )->order_by(
        Fey::Literal::Term->new($is_explicit_idx),
        'DESC',
        Fey::Literal::Term->new($title_idx),
        'ASC',
    );

    return $union;
}

sub _ExplicitWikiSelectBase {
    my $class  = shift;
    my $select = shift;

    $select->from( $Schema->tables( 'Wiki', 'UserWikiRole' ) )->where(
        $Schema->table('UserWikiRole')->column('user_id'),
        '=', Fey::Placeholder->new()
    );

    return;
}

sub _ImplicitWikiSelectBase {
    my $class  = shift;
    my $select = shift;

    my $explicit = Silki::Schema->SQLFactoryClass()->new_select();
    $explicit->select( $Schema->table('Wiki')->column('wiki_id') );
    $class->_ExplicitWikiSelectBase($explicit);
    #<<<
    $select
        ->from( $Schema->tables( 'Wiki', 'Page' ) )
        ->from( $Schema->tables( 'Page', 'PageRevision' ) )
        ->where( $Schema->table('PageRevision')->column('user_id'),
                 '=', Fey::Placeholder->new() )
        ->and( $Schema->table('Wiki')->column('wiki_id'),
               'NOT IN', $explicit );
    #>>>
    return;
}

sub recently_viewed_pages {
    my $self = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_RecentlyViewedPagesSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => ['Silki::Schema::Page'],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $self->user_id() ],
    );
}

sub _BuildRecentlyViewedPagesSelect {
    my $class = shift;

    my ( $page_t, $page_view_t ) = $Schema->tables( 'Page', 'PageView' );

    my $max_func = Fey::Literal::Function->new(
        'MAX',
        $page_view_t->column('view_datetime')
    );

    my $max_datetime = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $max_datetime
        ->select($max_func)
        ->from( $page_view_t )
        ->where( $page_view_t->column('page_id'),
                 '=', $page_t->column('page_id') );
    #>>>
    my $viewed_select = Silki::Schema->SQLFactoryClass()->new_select();
    #<<<
    $viewed_select
        ->select($page_t)
        ->from( $page_t, $page_view_t )
        ->where( $page_view_t->column('user_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_view_t->column('view_datetime') , '=', $max_datetime )
        ->order_by(
            $page_view_t->column('view_datetime'), 'DESC',
            $page_t->column('title'),              'ASC',
        );
    #>>>
    return $viewed_select;
}

sub send_invitation_email {
    my $self = shift;

    $self->_send_email( @_, template => 'invitation' );
}

sub send_activation_email {
    my $self = shift;

    $self->_send_email( @_, template => 'activation' );
}

sub forgot_password {
    my $self = shift;

    $self->update(
        confirmation_key =>
            $self->_make_confirmation_key( $self->email_address() ),
        user => Silki::Schema::User->SystemUser(),
    );

    $self->_send_email(
        @_,
        sender   => $self,
        subject  => loc('Password reset for Silki'),
        template => 'forgot-password',
    );
}

sub _send_email {
    my $self = shift;
    my ( $wiki, $sender, $domain, $message, $subject, $template )
        = validated_list(
        \@_,
        wiki   => { isa => 'Silki::Schema::Wiki', optional => 1 },
        sender => { isa => 'Silki::Schema::User' },
        domain => {
            isa     => 'Silki::Schema::Domain',
            default => Silki::Schema::Domain->DefaultDomain()
        },
        message  => { isa => Str, optional => 1 },
        subject  => { isa => Str, optional => 1 },
        template => { isa => Str },
        );

    die "Cannot send an invitation email without a wiki."
        if $template eq 'invitation' && !$wiki;

    $subject ||=
        $wiki
        ? loc(
        'You have been invited to join the %1 wiki at %2',
        $wiki->title(),
        $wiki->domain()->web_hostname(),
        )
        : loc(
        'Activate your user account on the %1 server',
        $self->domain()->web_hostname()
        );

    my $from = Email::Address->new(
        $sender->best_name(),
        $sender->email_address()
    )->format();

    my $to = Email::Address->new(
        $self->best_name(),
        $self->email_address(),
    )->format();

    send_email(
        from            => $from,
        subject         => $subject,
        to              => $to,
        template        => $template,
        template_params => {
            user    => $self,
            wiki    => $wiki,
            domain  => $domain,
            sender  => $sender,
            message => $message,
        },
    );

    return;
}

sub ActiveUsers {
    my $class = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $class->_ActiveUsersSelect()->clone();
    $select->limit( $limit, $offset );

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    return Fey::Object::Iterator::FromSelect->new(
        classes     => 'Silki::Schema::User',
        select      => $select,
        dbh         => $dbh,
        bind_params => [ $select->bind_params() ],
    );
}

sub _BuildActiveUsersSelect {
    my $class = shift;

    my $select = $class->_AllUsersSelect()->clone();

    my $user_t = $Schema->table('User');

    $select->where( $user_t->column('is_disabled'), '=', 0 );

    return $select;
}

sub ActiveUserCount {
    my $class = shift;

    my $select = $class->_ActiveUserCountSelect();

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    my $vals = $dbh->selectrow_arrayref(
        $select->sql($dbh), {},
        $select->bind_params()
    );

    return $vals ? $vals->[0] : 0;
}

sub _BuildActiveUserCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $user_t = $Schema->table('User');

    my $count
        = Fey::Literal::Function->new( 'COUNT', $user_t->column('user_id') );

    #<<<
    $select
        ->select($count)
        ->from($user_t)
        ->where( $user_t->column('is_disabled'), '=', 0 );
    #>>>
    return $select;
}

sub All {
    my $class = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $class->_AllUsersSelect()->clone();
    $select->limit( $limit, $offset );

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    return Fey::Object::Iterator::FromSelect->new(
        classes     => 'Silki::Schema::User',
        select      => $select,
        dbh         => $dbh,
        bind_params => [ $select->bind_params() ],
    );
}

sub _BuildAllUsersSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $user_t = $Schema->table('User');

    my $order_by = Fey::Literal::Term->new(
        q{CASE WHEN display_name = '' THEN username ELSE display_name END});

    #<<<
    $select
        ->select($user_t)
        ->from($user_t)
        ->order_by($order_by);
    #>>>
    return $select;
}

sub _all_revisions_for_delete {
    my $self = shift;

    my $select = $self->_AllRevisionsForDeleteSelect();

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    return Fey::Object::Iterator::FromSelect->new(
        classes     => 'Silki::Schema::PageRevision',
        select      => $select,
        dbh         => $dbh,
        bind_params => [ $self->user_id() ],
    );
}

sub _BuildAllRevisionsForDeleteSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $rev_t = $Schema->table('PageRevision');

    #<<<
    $select
        ->select($rev_t)
        ->from($rev_t)
        ->where( $rev_t->column('user_id'), '=', Fey::Placeholder->new() )
        ->order_by( $rev_t->column('page_id'), 'ASC',
                    $rev_t->column('revision_number'), 'DESC',
                  );
    #>>>
    return $select;
}

sub _BuildAllPageCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $page_t = $Schema->table('Page');

    my $count
        = Fey::Literal::Function->new( 'COUNT', $page_t->column('page_id') );

    #<<<
    $select
        ->select($count)
        ->from($page_t)
        ->where( $page_t->column('user_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub _BuildAllRevisionCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $rev_t = $Schema->table('PageRevision');

    my $count
        = Fey::Literal::Function->new( 'COUNT', $rev_t->column('page_id') );

    #<<<
    $select
        ->select($count)
        ->from($rev_t)
        ->where( $rev_t->column('user_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub _BuildAllFileCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $file_t = $Schema->table('File');

    my $count
        = Fey::Literal::Function->new( 'COUNT', $file_t->column('file_id') );

    #<<<
    $select
        ->select($count)
        ->from($file_t)
        ->where( $file_t->column('user_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a user

__END__
=pod

=head1 NAME

Silki::Schema::User - Represents a user

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

