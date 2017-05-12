package Net::Google::DocumentsList;
use Any::Moose;
use Net::Google::DataAPI;
use Net::Google::DataAPI::Auth::ClientLogin::Multiple;
use Net::Google::DocumentsList::Metadata;
use URI;
use URI::Escape;
use 5.008001;

our $VERSION = '0.09';

with 'Net::Google::DataAPI::Role::Service';

has '+gdata_version' => (default => '3.0');
has '+namespaces' => (
    default => sub {
        {
            gAcl => 'http://schemas.google.com/acl/2007',
            batch => 'http://schemas.google.com/gdata/batch',
            docs => 'http://schemas.google.com/docs/2007',
            app => 'http://www.w3.org/2007/app',
        }
    },
);

has username => (is => 'ro', isa => 'Str');
has password => (is => 'ro', isa => 'Str');
has account_type => (is => 'ro', isa => 'Str', required => 1, default => 'HOSTED_OR_GOOGLE');
has source => (is => 'ro', isa => 'Str', required => 1, default => __PACKAGE__ . '-' . $VERSION);

sub _build_auth {
    my ($self) = @_;
    Net::Google::DataAPI::Auth::ClientLogin::Multiple->new(
        source => $self->source,
        accountType => $self->account_type,
        services => {
            'docs.google.com' => 'writely',
            'spreadsheets.google.com' => 'wise',
            '*docs.googleusercontent.com' => 'writely',
        },
        username => $self->username,
        password => $self->password,
    );
}

feedurl item => (
    entry_class => 'Net::Google::DocumentsList::Item',
    default => 'https://docs.google.com/feeds/default/private/full',
    is => 'ro',
);

feedurl root_item => (
    entry_class => 'Net::Google::DocumentsList::Item',
    default => 'https://docs.google.com/feeds/default/private/full/folder%3Aroot/contents',
    can_add => 0,
    is => 'ro',
);

feedurl change => (
    entry_class => 'Net::Google::DocumentsList::Change',
    default => 'https://docs.google.com/feeds/default/private/changes',
    can_add => 0,
    is => 'ro',
);

with 'Net::Google::DocumentsList::Role::HasItems';

around root_items => sub {
    my ($next, $self, $cond) = @_;

    my @items;
    my $resource_id = delete $cond->{resource_id};
    if (my $cats = delete $cond->{category}) {
        $cats = [ "$cats" ] unless ref $cats eq 'ARRAY';
        @items = $self->items_with_category('root_item', $cats, $cond);
    } else {
        @items = $next->($self, $cond);
    }
    if ($self->can('sync')) {
        @items = grep {$_->parent eq $self->_url_with_resource_id} @items;
    }
    if ($resource_id) {
        @items = grep {$_->resource_id eq $resource_id} @items;
    }
    @items;
};

sub metadata {
    my ($self, $args) = @_;
    my $uri = URI->new(
        sprintf("https://docs.google.com/feeds/metadata/%s", 
            uri_escape_utf8(delete $args->{user_id} || 'default')
        )
    );
    $uri->query_form($args);
    my $atom = eval {$self->get_entry($uri)} or return;
    Net::Google::DocumentsList::Metadata->new(
        atom => $atom,
        service => $self,
    );
}

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;
__END__

=head1 NAME

Net::Google::DocumentsList - Perl interface to Google Documents List Data API

=head1 SYNOPSIS

  use Net::Google::DocumentsList;

  my $client = Net::Google::DocumentsList->new(
    username => 'myname@gmail.com',
    password => 'p4$$w0rd'
  );
  

=head1 DESCRIPTION

Net::Google::DocumentsList is a Perl interface to Google Documents List Data 
API.

=head1 METHODS

=head2 new

creates Google Documents List Data API client.

  my $clinet = Net::Google::DocumentsList->new(
    username => 'foo.bar@gmail.com',
    password => 'p4ssw0rd',
    source   => 'MyClient', 
        # optional, default is 'Net::Google::DocumentsList'
    account_type => 'GOOGLE',
        # optional, default is 'HOSTED_OR_GOOGLE'
  );

You can set alternative authorization module like this:

  my $oauth = Net::Google::DataAPI::Auth::OAuth->new(...);
  my $client = Net::Google::DocumentsList->new(
    auth => $oauth,
  );

Make sure Documents List Data API would need those scopes:

=over 2

=item * http://docs.google.com/feeds/

=item * http://spreadsheets.google.com/feeds/

=item * http://docs.googleusercontent.com/

=back

=head2 add_item, items, item, add_folder, folders, folder

These methods are implemented in 
L<Net::Google::DocumentsList::Role::HasItems>.

=head2 root_items, root_item

These methods gets items on your 'root' directory. 
parameters are same as 'items' and 'item' methods.

You can not do add_root_item (it's useless). use add_item method instead.

=head2 metadata

you can get metadata of current logged in user. returned object is Net::Google::DocumentsList::Metadata.

  my $meatadata = Net::Google::DocumentsList->new(...)->metadata;

=head2 changes, change

returns Net::Google::DocumentsList::Change objects with calling 'changes', first item of them with 'change'.

  my $service = Net::Google::DocumentsList->new(...);
  my $changestamp = $service->metadata->largest_changestamp;
  my @changes = $service->changes(
    {
        'start-index' => $changestamp - 10,
        'max-results' => 10,
    }
  );

You can specify 'start-index', 'max-results' parameters to get fewer changes.

=head1 AUTHOR

Noubo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<XML::Atom>

L<Net::Google::AuthSub>

L<Net::Google::DataAPI>

L<Net::Google::DocumentsList::Role::HasItems>

L<http://code.google.com/apis/documents/docs/3.0/developers_guide_protocol.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
