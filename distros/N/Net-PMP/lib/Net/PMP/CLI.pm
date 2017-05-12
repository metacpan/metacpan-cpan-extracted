package Net::PMP::CLI;
use Moose;
with 'MooseX::SimpleConfig';
with 'MooseX::Getopt';

use Net::PMP::Client;
use JSON;
use Data::Dump qw( dump );

our $VERSION = '0.006';

has '+configfile' =>
    ( default => $ENV{PMP_CLIENT_CONFIG} || ( $ENV{HOME} . '/.pmp.yaml' ) );

# keep attributes sorted as usage prints in this order
has 'child'   => ( is => 'rw', isa => 'Str', );
has 'debug'   => ( is => 'rw', isa => 'Bool', );
has 'expires' => ( is => 'rw', isa => 'Str' );
has 'file'    => ( is => 'rw', isa => 'Str' );
has 'guid'    => ( is => 'rw', isa => 'Str', );
has 'host' =>
    ( is => 'rw', isa => 'Str', default => 'https://api-sandbox.pmp.io', );
has 'id' => ( is => 'rw', isa => 'Str', required => 1, );
has 'label'   => ( is => 'rw', isa => 'Str' );
has 'limit'   => ( is => 'rw', isa => 'Int' );
has 'parent'  => ( is => 'rw', isa => 'Str', );
has 'pass'    => ( is => 'rw', isa => 'Str' );
has 'path'    => ( is => 'rw', isa => 'Str', );
has 'profile' => ( is => 'rw', isa => 'Str' );
has 'query'   => ( is => 'rw', isa => 'HashRef', );
has 'scope'   => ( is => 'rw', isa => 'Str' );
has 'secret'  => ( is => 'rw', isa => 'Str', required => 1, );
has 'tag'     => ( is => 'rw', isa => 'Str', );
has 'tags'    => ( is => 'rw', isa => 'ArrayRef', );
has 'title'   => ( is => 'rw', isa => 'Str', );
has 'user'    => ( is => 'rw', isa => 'Str' );

=head1 NAME

Net::PMP::CLI - command line application for Net::PMP::Client

=head1 SYNOPSIS

 use Net::PMP::CLI;
 my $app = Net::PMP::CLI->new_with_options();
 $app->run();

=head1 DESCRIPTION

This class is used by the C<pmpc> command-line tool.
It uses L<MooseX::SimpleConfig> and L<MooseX::Getopt> to allow
for simple configuration file and option parsing.

=head1 METHODS

With the exceptions of B<run> and B<init_client> all method
names are commands.

=head2 run

Main method. Calls commands passed via @ARGV.

=cut

sub _getopt_full_usage {
    my ( $self, $usage ) = @_;
    $usage->die( { post_text => $self->commands } );
}

sub _usage_format {
    return "usage: %c command %o";
}

sub run {
    my $self = shift;

    $self->debug and dump $self;

    my @cmds = @{ $self->extra_argv };

    if ( !@cmds or $self->help_flag ) {
        $self->usage->die( { post_text => $self->commands } );
    }

    for my $cmd (@cmds) {
        if ( !$self->can($cmd) ) {
            warn "No such command $cmd\n";
            $self->usage->die();
        }
        $self->$cmd();
    }

}

=head2 commands

Returns usage text for available commands.

=cut

sub commands {
    my $self = shift;
    my $txt  = <<EOF;
commands:
    search  --query tag=foo --query text=bar --query limit=100
    delete_by_search --query tag=foo --query text=bar --query limit=100
    add     --parent <guid> --child <guid>
    create  --profile <profile> --title <title> --tags foo --tags bar
    delete  --guid <guid>
    delete_by_tag --tag foo
    get     --path /path/to/resource
    groups
    put     --file /path/to/resource.json
    users
EOF
    return $txt;
}

sub _list_items {
    my ( $self, $label, $urn ) = @_;
    my $client = $self->init_client();
    my $root   = $client->get_doc();
    my $q      = $root->query($urn);
    my $uri    = $q->as_uri( { limit => 200 } );     # TODO random big number
    my $res    = $client->get_doc($uri) or return;
    my $items  = $res->get_items();
    while ( my $item = $items->next ) {
        my $profile = $item->get_profile;
        $profile =~ s,^.+/,,;
        printf(
            "%s [%s]: %s [%s]\n",
            $label, $profile, ( $item->get_title || '[missing title]' ),
            $item->get_uri,
        );
        if ( $item->has_items ) {
            my $iitems = $item->get_items;
            while ( my $iitem = $iitems->next ) {
                my $iprofile = $iitem->get_profile;
                $iprofile =~ s,^.+/,,;
                printf( " contains: %s [%s] [%s]\n",
                    $iitem->get_title, $iitem->get_uri, $iprofile );
            }
        }
    }
}

=head2 search( I<query> )

Executes search for I<query> and prints results to stdout.

=cut

sub search {
    my $self   = shift;
    my $query  = $self->query or die "--query required for search\n";
    my $client = $self->init_client();
    my $res    = $client->search($query) or return;
    my $items  = $res->get_items();
    while ( my $item = $items->next ) {
        my $profile = $item->get_profile || 'root';
        $profile =~ s,^.+/,,;
        printf( "%s: %s [%s]\n",
            $profile, $item->get_title, $item->get_uri, );
    }
}

=head2 delete_by_search( I<query> )

Execute search for I<query> and deletes the results.

=cut

sub delete_by_search {
    my $self   = shift;
    my $query  = $self->query or die "--query required for search\n";
    my $client = $self->init_client();
    my $res    = $client->search($query) or return;
    my $items  = $res->get_items();
    while ( my $item = $items->next ) {
        if ( $client->delete($item) ) {
            printf( "Deleted %s\n", $item->get_uri );
        }
    }
}

=head2 create

Create or update a resource via Net::PMP::Client.
Requires the C<--profile> and C<--title> options.

=cut

sub create {
    my $self    = shift;
    my $profile = $self->profile or die "--profile required for create\n";
    my $title   = $self->title or die "--title required for create\n";
    my $tags    = $self->tags || [];
    my $client  = $self->init_client;

    # verify profile first
    my $prof_doc = $self->get( '/profiles/' . $profile );
    if ( !$prof_doc ) {
        die "invalid profile: $profile\n";
    }
    my $doc = Net::PMP::CollectionDoc->new(
        version    => $client->get_doc->version,
        attributes => { title => $title, tags => $tags, },
        links      => {
            profile => [ { href => $client->host . '/profiles/' . $profile } ]
        },
    );
    $client->save($doc);
    printf( "%s saved as '%s' at %s\n",
        $profile, $doc->get_title, $doc->get_uri );
}

=head2 create_credentials

Create a credential set. Requires --user and --pass options,
and optionally --scope --expires --label.

=cut

sub create_credentials {
    my $self    = shift;
    my $user    = $self->user or die "--user required";
    my $pass    = $self->pass or die "--pass required";
    my $scope   = $self->scope;
    my $expires = $self->expires;
    my $label   = $self->label;
    my $client  = $self->init_client;
    my $creds   = $client->create_credentials(
        username => $user,
        password => $pass,
        scope    => $scope,
        expires  => $expires,
        label    => $label,
    );

    if ($creds) {
        printf( "Credentials created: %s\n", dump($creds) );
    }
    else {
        printf("Failed to create credentials\n");
    }
}

=head2 delete

Deletes a resource. Requires the C<--guid> option.

=cut

sub delete {
    my $self   = shift;
    my $guid   = $self->guid or die "--guid required for delete\n";
    my $client = $self->init_client;
    my $doc    = $client->get_doc_by_guid($guid);
    if ( !$doc ) {
        die "Cannot delete non-existent doc $guid\n";
    }
    if ( $client->delete($doc) ) {
        printf( "Deleted %s\n", $guid );
    }
    else {
        printf( "Failed to delete %s\n", $guid );    # never get here, croaks
    }
}

=head2 delete_by_tag([I<tag>])

Deletes all resources that match a search for tag.

=cut

sub delete_by_tag {
    my $self = shift;
    my $tag = shift || $self->tag;
    defined $tag or die "--tag required for delete_by_tag\n";

    # optional profile if defined
    my $profile = $self->profile;
    my $limit = $self->limit || 100;

    my %args = ( tag => $tag, limit => $limit );
    if ($profile) {
        $args{profile} = $profile;
    }
    my $client = $self->init_client;

    my $matches = $client->search( \%args );
    if ($matches) {
        my $res = $matches->get_items();
        while ( my $item = $res->next ) {
            if ( $client->delete($item) ) {
                printf( "Deleted %s\n", $item->get_uri );
            }
        }
    }
}

=head2 users

List all users.

=cut

sub users {
    my $self = shift;
    my $urn  = "urn:collectiondoc:query:users";
    $self->_list_items( 'User', $urn );
}

=head2 groups

List all groups.

=cut

sub groups {
    my $self = shift;
    my $urn  = "urn:collectiondoc:query:groups";
    $self->_list_items( 'Group', $urn );
}

=head2 get([I<path>])

Issues a get_doc() for the URI represented by I<path>. If I<path>
is not explicitly passed, looks at the C<--path> option.

Dumps the resource for I<path> to stdout.

=cut

sub get {
    my $self = shift;
    my $path = shift || $self->path;
    if ( !$path ) {
        die "--path required for get\n";
    }
    my $client = $self->init_client;
    my $uri    = $client->host . $path;
    my $doc    = $client->get_doc($uri);
    if ( $doc eq '0' ) {
        printf( "No such path: %s [%s]\n",
            $self->path, $client->last_response->status_line );
    }
    else {
        #dump $doc;
        print $doc->as_json;
    }
}

=head2 put([I<filename>])

Reads I<filename> and PUTs it to the server. If missing, the file()
attribute will be checked instead.

I<filename> should represent a ready-to-save CollectionDoc in JSON format.
A simple string substitution will be performed, replacing C<${HOSTNAME}> with
the base PMP host for the configured environment.

=cut

sub put {
    my $self = shift;
    my $filename = shift || $self->file();
    if ( !$filename ) {
        die "--file required for put\n";
    }
    my $client   = $self->init_client;
    my $hostname = $client->host;

    # slurp file
    my $fh = IO::File->new("< $filename")
        or die "Can't read file $filename: $!";
    local $/;
    my $buf = <$fh>;

    # string sub
    $buf =~ s/\$\{HOSTNAME\}/$hostname/g;

    # decode as hashref
    my $json = decode_json($buf);

    # write it
    my $doc = Net::PMP::CollectionDoc->new($json);
    $client->save($doc);
    printf( "%s saved as %s\n", $filename, $doc->get_uri() );
}

=head2 add( I<parent_doc>, I<child_doc> )

Save I<child_doc> as child of I<parent_doc>.

=cut

sub add {
    my $self = shift;
    my $parent = shift || $self->parent;
    if ( !$parent ) {
        die "--parent required for add_item\n";
    }
    my $child = shift || $self->child;
    if ( !$child ) {
        die "--child required for add_item\n";
    }
    my $client     = $self->init_client;
    my $parent_doc = $client->get_doc_by_guid($parent);
    my $child_doc  = $client->get_doc_by_guid($child);
    if ( !$parent_doc ) {
        die "could not find parent $parent\n";
    }
    if ( !$child_doc ) {
        die "could not find child $child\n";
    }
    $parent_doc->add_item($child_doc);
    $client->save($parent_doc);
    printf( "child %s saved to parent %s\n", $child, $parent );
}

=head2 init_client

Instantiates and caches a Net::PMP::Client instance.

=cut

sub init_client {
    my $self = shift;
    return $self->{_client} if $self->{_client};
    my $client = Net::PMP::Client->new(
        id     => $self->id,
        secret => $self->secret,
        host   => $self->host,
        debug  => $self->debug,
    );
    $self->{_client} = $client;
    return $client;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PMP/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut
