package Silki::Schema::Domain;
{
  $Silki::Schema::Domain::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Net::Interface;
use Silki::Config;
use Silki::I18N qw( loc );
use Silki::Schema;
use Silki::Types qw( Bool HashRef Int Str );
use Socket qw( AF_INET );
use Sys::Hostname qw( hostname );
use URI;

use Fey::ORM::Table;
use MooseX::ClassAttribute;
use MooseX::Params::Validate qw( validated_hash validated_list );

with 'Silki::Role::Schema::URIMaker';

with 'Silki::Role::Schema::DataValidator' => {
    steps => [
        '_web_hostname_is_unique',
        '_email_hostname_is_unique',
    ],
};

has_policy 'Silki::Schema::Policy';

my $Schema = Silki::Schema->Schema();

has_table( $Schema->table('Domain') );

query wiki_count => (
    select      => __PACKAGE__->_WikiCountSelect(),
    bind_params => sub { $_[0]->domain_id() },
);

class_has 'DefaultDomain' => (
    is      => 'ro',
    isa     => __PACKAGE__,
    lazy    => 1,
    default => sub { __PACKAGE__->_FindOrCreateDefaultDomain() },
);

class_has _AllDomainSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildAllDomainSelect',
);

has uri_params => (
    is       => 'ro',
    isa      => HashRef,
    lazy     => 1,
    builder  => '_build_uri_params',
    init_arg => undef,
);

around insert => sub {
    my $orig  = shift;
    my $class = shift;
    my %p     = @_;

    $p{email_hostname} //= $p{web_hostname};

    return $class->$orig(%p);
};

sub _web_hostname_is_unique {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return
        if !$is_insert
            && exists $p->{web_hostname}
            && $p->{web_hostname} eq $self->web_hostname();

    return unless __PACKAGE__->new( web_hostname => $p->{web_hostname} );

    return {
        field   => 'web_hostname',
        message => loc(
            'The web hostname you provided is already in use by another domain.'
        ),
    };
}

sub _email_hostname_is_unique {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return
        if !$is_insert
            && exists $p->{email_hostname}
            && $p->{email_hostname} eq $self->email_hostname();

    return unless __PACKAGE__->new( email_hostname => $p->{email_hostname} );

    return {
        field   => 'email_hostname',
        message => loc(
            'The email hostname you provided is already in use by another domain.'
        ),
    };
}

sub _base_uri_path {
    return q{/};
}

sub entity_uri {
    my $self = shift;
    my %p    = @_;

    $p{view}
        = 'domain/'
        . $self->domain_id()
        . ( $p{view} ? q{/} . $p{view} : q{} );

    return $self->uri(%p);
}

sub EnsureRequiredDomainsExist {
    my $class = shift;

    $class->_FindOrCreateDefaultDomain();
}

sub _FindOrCreateDefaultDomain {
    my $class = shift;

    my $hostname = $ENV{SILKI_HOSTNAME} || $class->_SystemHostname();

    my $domain = $class->new( web_hostname => $hostname );
    return $domain if $domain;

    return $class->insert( web_hostname => $hostname );
}

sub _SystemHostname {
    for my $name (
        hostname(),
        map { scalar gethostbyaddr( $_->address(), AF_INET ) }
        grep { $_->address() } Net::Interface->interfaces()
        ) {
        return $name if $name =~ /\.[^.]+$/;
    }

    die 'Cannot determine system hostname.';
}

sub domain { $_[0] }

sub _build_uri_params {
    my $self = shift;

    return {
        scheme => ( $self->requires_ssl() ? 'https' : 'http' ),
        host => $self->web_hostname(),
    };
}

sub application_uri {
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        path      => { isa => Str,     optional => 1 },
        fragment  => { isa => Str,     optional => 1 },
        query     => { isa => HashRef, default  => {} },
        with_host => { isa => Bool,    default  => 0 },
    );

    return $self->_make_uri(%p);
}

sub _WikiCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $wiki_t = $Schema->table('Wiki');

    my $count
        = Fey::Literal::Function->new( 'COUNT', $wiki_t->column('wiki_id') );

    #<<<
    $select
        ->select($count)
        ->from( $wiki_t )
        ->where( $wiki_t->column('domain_id'), '=',
                 Fey::Placeholder->new() );
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

    my $select = $class->_AllDomainSelect()->clone();
    $select->limit( $limit, $offset );

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    return Fey::Object::Iterator::FromSelect->new(
        classes     => 'Silki::Schema::Domain',
        select      => $select,
        dbh         => $dbh,
        bind_params => [ $select->bind_params() ],
    );
}

sub _BuildAllDomainSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $domain_t = $Schema->table('Domain');

    #<<<
    $select
        ->select($domain_t)
        ->from($domain_t)
        ->order_by( $domain_t->column('web_hostname') );
    #>>>
    return $select;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a domain

__END__
=pod

=head1 NAME

Silki::Schema::Domain - Represents a domain

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

