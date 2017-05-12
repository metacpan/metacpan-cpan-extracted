package SilkiX::Converter::Kwiki;
BEGIN {
  $SilkiX::Converter::Kwiki::VERSION = '0.03';
}

use strict;
use warnings;
use namespace::autoclean;

use Cwd qw( abs_path );
use Encode qw( decode );
use File::Basename qw( basename );
use File::chdir;
use File::MimeInfo qw( mimetype );
use File::Slurp qw( read_file );
use HTML::Tidy;
use JSON qw( from_json );
use Kwiki              ();
use Kwiki::Attachments ();
use Path::Class qw( dir file );
use Scalar::Util qw( blessed );
use SilkiX::Converter::Kwiki::HTMLToWiki;
use Silki::Schema::File;
use Silki::Schema::Page;
use Silki::Schema::User;
use Silki::Schema::Wiki;
use URI::Escape qw( uri_unescape );

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

use MooseX::Getopt::OptionTypeMap;

with 'MooseX::Getopt::Dashes';

my $kwiki_dir = subtype as 'Str' => where { -d && -f "$_/plugins" };

has kwiki_root => (
    is       => 'ro',
    isa      => $kwiki_dir,
    required => 1,
);

has default_user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has wiki_name => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has fast => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has _wiki => (
    is  => 'rw',
    isa => 'Silki::Schema::Wiki',
);

has _kwiki => (
    is       => 'ro',
    isa      => 'Kwiki',
    lazy     => 1,
    builder  => '_build_kwiki',
    init_arg => undef,
);

my $file = subtype as 'Str' => where {-f};

has user_map_file => (
    is        => 'rw',
    writer    => '_set_user_map_file',
    isa       => $file,
    predicate => 'has_user_map_file',
);

has _user_map => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_user_map',
    init_arg => undef,
);

has _formatter => (
    is       => 'ro',
    isa      => 'Silki::Formatter::HTMLToWiki',
    lazy     => 1,
    builder  => '_build_formatter',
    init_arg => undef,
);

has debug => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has dump_page_titles => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has dump_usernames => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub BUILD {
    my $self = shift;
    my $p    = shift;

    unless ( $self->_wiki() ) {
        my $wiki = Silki::Schema::Wiki->new( title => $p->{wiki_name} );

        die "No such wiki $p->{wiki_name}" unless $wiki;

        $self->_set_wiki($wiki);
    }

    $self->_set_user_map_file( abs_path( $self->user_map_file ) )
        if $self->has_user_map_file;
}

sub run {
    my $self = shift;

    # Kwiki just assumes it is running from its root directory.
    local $CWD = $self->kwiki_root();

    if ( $self->dump_page_titles() ) {
        print "\n";
        print "All page titles in the Kwiki wiki ...\n";
        print $_->title, "\n" for $self->_kwiki()->hub()->pages()->all();
    }

    if ( $self->dump_usernames() ) {
        print "\n";
        print "All usernames in the Kwiki wiki ...\n";

        my %names;
        for my $page ( $self->_kwiki()->hub()->pages()->all() ) {
            for my $metadata ( reverse @{ $page->history() } ) {

                my $username = $metadata->{edit_by};
                my $date = $metadata->{edit_unixtime};

                $names{$username} ||= {
                    first_seen => $date,
                    last_seen  => $date,
                };

                if ( $date < $names{$username}{first_seen} ) {
                    $names{$username}{first_seen} = $date;
                }

                if ( $date > $names{$username}{last_seen} ) {
                    $names{$username}{last_seen} = $date;
                }
            }
        }

        for my $username ( sort { lc $a cmp lc $b } keys %names ) {
            print "$username - "
                . DateTime->from_epoch(
                epoch => $names{$username}{first_seen} )
                . ' to '
                . DateTime->from_epoch(
                epoch => $names{$username}{last_seen} )
                . "\n";
        }
    }

    exit if $self->dump_page_titles() || $self->dump_usernames();

    $self->_disable_pg_triggers() if $self->fast();

    eval {
        for my $page (
            map  { $_->[1] }
            sort { $a->[0] <=> $b->[0] }
            map {
                my $order = $_->title() eq 'HomePage' ? 0 : 1;
                [ $order, $_ ]
            } $self->_kwiki()->hub()->pages()->all()
            ) {

            $self->_convert_page($page);
        }

        $self->_enable_pg_triggers() if $self->fast();

        $self->_rebuild_searchable_text() if $self->fast();

        for my $user (
            grep { !$_->is_disabled() }
            grep { blessed $_} values %{ $self->_user_map() }
            ) {

            $self->_wiki->add_user(
                user => $user,
                role => Silki::Schema::Role->Member(),
            );
        }
    };

    if ( my $e = $@ ) {
        $self->_enable_pg_triggers();
        die $e;
    }
}

sub _build_kwiki {
    my $self = shift;

    # Magic voodoo to make Kwiki work. I don't really care to dig too
    # deep into this.
    my $kwiki = Kwiki->new();
    my $hub = $kwiki->load_hub( 'config*.*', -plugins => 'plugins' );
    $hub->registry()->load();
    $hub->add_hooks();
    $hub->pre_process();
    $hub->preload();

    return $kwiki;
}

sub _convert_page {
    my $self = shift;
    my $page = shift;

    if ( $self->_skip_page($page) ) {
        $self->_debug(q{});
        $self->_debug( "Skipping page " . $page->title() );
        return;
    }

    return if $page->title() eq 'Help';

    $page->title( $self->_proper_kwiki_title( $page->id ) );

    my $s_title = $self->_convert_title( $page->title );

    $self->_debug(q{});
    $self->_debug( "Converting page " . $page->title() . " to $s_title" );

    my @history = reverse @{ $page->history() };

    my $creator = $self->_convert_user( $history[0]->{edit_by} );

    my $s_page = Silki::Schema::Page->insert(
        title   => $s_title,
        user_id => $creator->user_id(),
        wiki_id => $self->_wiki()->wiki_id(),
    );

    my $attachment_map = $self->_convert_attachments( $page, $s_page );

    for my $revision (@history) {
        $self->_debug(" ... revision $revision->{revision_id}");

        my $user = $self->_convert_user( $revision->{edit_by} );

        my $content = $self->_convert_content(
            $attachment_map,
            scalar $self->_kwiki->hub->archive->fetch(
                $page, $revision->{revision_id}
            )
        );

        local $Silki::Schema::PageRevision::SkipPostChangeHack
            = $revision == $history[-1] ? 0 : 1;

        $s_page->add_revision(
            content => $content,
            user_id => $user->user_id(),
            creation_datetime =>
                DateTime->from_epoch( epoch => $revision->{edit_unixtime} ),
        );
    }
}

sub _skip_page {
    return 0;
}

# Kwiki completely breaks utf8 in page titles with its conversion
# routines. This redoes the conversion and unbreaks utf8.
sub _proper_kwiki_title {
    my $self = shift;
    my $id   = shift;

    my $title = uri_unescape($id);

    return decode( 'utf-8', $title );
}

sub _convert_title {
    my $self  = shift;
    my $title = shift;

    return 'Front Page' if $title eq 'HomePage';

    return $self->_de_studly($title);
}

sub _de_studly {
    my $eslf  = shift;
    my $title = shift;

    $title =~ s/([^A-Z])([A-Z])/$1 $2/g;

    return $title;
}

sub _convert_user {
    my $self       = shift;
    my $kwiki_user = shift;

    $kwiki_user = $self->default_user()
        unless defined $kwiki_user && length $kwiki_user;

    return Silki::Schema::User->GuestUser()
        if $kwiki_user eq 'AnonymousGnome';

    return Silki::Schema::User->SystemUser()
        if $kwiki_user eq 'kwiki-install';

    my $user;

    return $self->_user_map()->{$kwiki_user}
        if blessed $self->_user_map()->{$kwiki_user};

    $self->_debug("Looking for user mapping from $kwiki_user");

    $user = $self->_resolve_from_map($kwiki_user);

    if ( $user && !ref $user ) {
        $kwiki_user = $user;
        undef $user;
    }

    if ($user) {
        my $email
            = blessed $user ? $user->email_address() : $user->{email_address};
        $self->_debug(" ... found an explicit mapping to $email");
    }
    else {
        $self->_debug(' ... using implicit mapping');
    }

    $user ||= {};
    for my $key (
        qw( email_address password display_name time_zone is_disabled )) {
        next if exists $user->{$key};

        my $meth = '_default_' . $key . '_for_user';
        $user->{$key} = $self->$meth( $kwiki_user, $user );
    }

    my $s_user
        = blessed $user
        ? $user
        : Silki::Schema::User->new( email_address => $user->{email_address} );

    if ($s_user) {
        $self->_debug(' ... found a user in the database');
    }
    else {
        my $status = $user->{is_disabled} ? 'disabled' : 'active';
        my $msg = qq{ ... creating a new $status user};
        $msg .= qq{, password is "$user->{password}"}
            unless $user->{is_disabled};

        $self->_debug($msg);

        $s_user = Silki::Schema::User->insert(
            %{$user},
            user => Silki::Schema::User->SystemUser(),
        );
    }

    $self->_user_map->{$kwiki_user} = $s_user;
}

sub _resolve_from_map {
    my $self = shift;
    my $key  = shift;

    my $start = $key;
    my $x = 0;

    while (1) {
        my $value = $self->_user_map()->{$key};

        return $value if ref $value;

        return $key unless defined $value;

        $self->_debug(" ... following map from $key to $value" );

        $key = $value;

        if ($x++ > 10 ) {
            die "Could not resolve mapping for $start after 10 iterations";
        }
    }
}

sub _default_password_for_user {
    return 'change me';
}

sub _default_display_name_for_user {
    my $self       = shift;
    my $kwiki_user = shift;

    return $kwiki_user;
}

sub _default_email_address_for_user {
    my $self       = shift;
    my $kwiki_user = shift;

    return $kwiki_user . '@localhost.localdomain';
}

sub _default_time_zone_for_user {
    my $self       = shift;
    my $kwiki_user = shift;

    return 'America/New_York';
}

sub _default_is_disabled_for_user {
    return 0;
}

sub _build_user_map {
    my $self = shift;

    my $map;
    $map = from_json( read_file( $self->user_map_file() ) )
        if $self->has_user_map_file;
    $map ||= {};

    return $map;
}

sub _convert_attachments {
    my $self   = shift;
    my $page   = shift;
    my $s_page = shift;

    return unless $self->_kwiki()->hub()->can('attachments');

    return
        unless $self->_kwiki()->hub()->attachments()
            ->get_attachments( $page->id() );

    my $dir = dir(
        $self->_kwiki()->hub()->attachments()->plugin_directory(),
        $page->id()
    );

    my %map;
    for my $kwiki_file ( @{ $self->_kwiki()->hub()->attachments()->files() } )
    {
        $self->_debug( ' ... attachment ' . $kwiki_file->name() );

        my $file_path = $dir->file( $kwiki_file->name() );

        next unless -s $file_path;

        my $file = Silki::Schema::File->insert(
            filename  => $kwiki_file->name(),
            mime_type => mimetype( $file_path->stringify() ),
            file_size => -s $file_path,
            contents  => scalar read_file( $file_path->stringify() ),
            user_id   => Silki::Schema::User->SystemUser()->user_id(),
            page_id   => $s_page->page_id(),
        );

        $map{ $kwiki_file->name() } = $file;
    }

    return \%map;
}

# gibberish that will not be present in any real page. We can use this
# to delimit things that need to be dealt with _after_ the kwiki ->
# html -> markdown conversion.
my $Marker = 'asfkjsdkglsjdglkjsga09dsug0329jt3poi3p41o6j24963109ytu0cgsv';

sub _convert_content {
    my $self           = shift;
    my $attachment_map = shift;
    my $content        = shift;

    return q{} unless defined $content && length $content;

    my $counter = 1;
    my %post_convert;
    $content =~ s/\{file:?\s*([^}]+)}/
               $post_convert{$counter++} = [ 'attachment', $1 ];
               $Marker . ':' . ( $counter - 1 )/eg;

    my $kwiki_html = $self->_kwiki->hub->formatter->text_to_html($content);

    my $markdown = $self->_formatter()->html_to_wikitext($kwiki_html);

    $markdown =~ s/$Marker:(\d+)/
                   $self->_post_convert( $post_convert{$1}, $attachment_map )/eg;

    return $markdown;
}

sub _post_convert {
    my $self           = shift;
    my $action         = shift;
    my $attachment_map = shift;

    if ( $action->[0] eq 'attachment' ) {
        $self->_attachment_link( $action->[1], $attachment_map );
    }
    else {
        die "Unknown post-convert action: $action->[0]";
    }
}

sub _attachment_link {
    my $self           = shift;
    my $filename       = shift;
    my $attachment_map = shift;

    my $file = $attachment_map->{$filename}
        or return q{};

    return '{{file:' . $file->filename() . '}}';
}

sub _build_formatter {
    my $self = shift;

    my $wiki_link_fixer = sub {
        return $self->_convert_wiki_link( $_[0] );
    };

    return SilkiX::Converter::Kwiki::HTMLToWiki->new(
        wiki            => $self->_wiki(),
        wiki_link_fixer => $wiki_link_fixer,
    );
}

sub _convert_wiki_link {
    my $self        = shift;
    my $kwiki_title = shift;

    return $self->_convert_title($kwiki_title);
}

sub _disable_pg_triggers {
    my $self = shift;

    my $dbh = Silki::Schema->DBIManager()->default_source()->dbh();

    $dbh->do( q{ALTER TABLE "Page" DISABLE TRIGGER USER} );
    $dbh->do( q{ALTER TABLE "PageRevision" DISABLE TRIGGER USER} );
}

sub _enable_pg_triggers {
    my $self = shift;

    my $dbh = Silki::Schema->DBIManager()->default_source()->dbh();

    $dbh->do( q{ALTER TABLE "Page" ENABLE TRIGGER USER} );
    $dbh->do( q{ALTER TABLE "PageRevision" ENABLE TRIGGER USER} );
}

sub _rebuild_searchable_text {
    my $self = shift;

    my $sql = <<'EOF';
INSERT INTO "PageSearchableText"
  (page_id, ts_text)
SELECT pages.page_id,
       setweight(to_tsvector('pg_catalog.english', pages.title), 'A') ||
       setweight(to_tsvector('pg_catalog.english', pages.content), 'B')
  FROM ( SELECT p.page_id, p.title, pr.content
           FROM "Page" AS p, "PageRevision" AS pr
          WHERE revision_number =
                ( SELECT MAX(revision_number)
                    FROM "PageRevision"
                   WHERE page_id = p.page_id )
            AND p.page_id = pr.page_id
            AND p.wiki_id = ?
       ) AS pages
EOF

    my $dbh = Silki::Schema->DBIManager()->default_source()->dbh();

    $dbh->do( $sql, {}, $self->_wiki()->wiki_id() );
}

sub _debug {
    my $self = shift;

    return unless $self->debug();

    my $msg = shift;

    print STDERR $msg, "\n";
}

{
    use Spoon::Hub;

    package
        Spoon::Hub;

    no warnings 'redefine';

    # shuts up a warning during global destruction
    sub remove_hooks {
        my $self  = shift;
        my $hooks = $self->all_hooks;
        while (@$hooks) {
            my $hook = pop(@$hooks)
                or next;
            $hook->unhook;
        }
    }
}

1;

# ABSTRACT: Convert a Kwiki wiki to a Silki wiki



=pod

=head1 NAME

SilkiX::Converter::Kwiki - Convert a Kwiki wiki to a Silki wiki

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  kwiki2silki --wiki           'Silki Wiki Title'   \
              --kwiki-root     /path/to/kwiki       \
              --user-map-file  /path/to/map.json    \
              --default-user   DefaultNameFromKwiki \
              --fast

  SILKIX_CONVERTER=MyCustomConversionSubclass \
    kwiki2silki --wiki           'Silki Wiki Title'   \
                --kwiki-root     /path/to/kwiki       \
                --user-map-file  /path/to/map.json    \
                --default-user   DefaultNameFromKwiki

=head1 DESCRIPTION

This module lets you convert a Kwiki wiki into a Silki wiki. The primary
interface is via the F<kwiki2silki> script that ships with this distribution.

If you define a C<SILKIX_CONVERTER> environment variable, then this class will
be used to do the conversion. This lets you create a custom subclass, which
can be useful, especially when it comes to default values for users and for
mapping page titles from Kwiki to Silki.

=head1 WARNINGS

If you pass the C<--fast> option, the converter disables some database
triggers in order to speed things up, and restores them at the end of the
conversion. It attempts to restore them if the process fails mid-stream, but
this is software, and software has bugs.

If you have other wikis which are in use, make sure to backup your database
with F<pg_dump>. Also, shut down the web UI during the conversion, or else
other wikis could end up corrupted because of the missing triggers.

The converter assumes that the wiki you're writing to is effectively
empty. Don't try to convert into an already-in-use wiki!

Basically, this software is rough, and could mess you up. Be careful.

=head1 KWIKI PLUGINS

This module assumes that your Kwiki install has certain plugins. It assumes
that your Kwiki install has one of the archive plugins installed, though it
doesn't matter which one.

You also will need the L<Kwiki::Attachments> module installed. This may fail
tests, but just force it (sigh). However, if your kwiki install does not load
the attachments plugin, that's ok. If it does, then this converter will
convert attachments too.

=head1 USER MAP FILE

By default, the converter does a dumb mapping of kwiki usernames to Silki
users. The email address is C<$kwiki_user@localhost.localdomain>.

If you want to make useful accounts for users, you can create a user map JSON
file.

This should be a JSON object (aka hash) where the keys are Kwiki
usernames. The values can either be an object describing the user for Silki,
or another key name. If it is another key name, then the converter follows the
references until it finds an object or ten links have been followed, at which
point it blows up.

The Silki user object in the user map can have the following keys:

=over 4

=item * email_address

=item * password

Defaults to "change me".

=item * display_name

The name used by Silki to display the user. This can be empty.

=item * time_zone

Must be an Olson time zone. Defaults to "America/New_York".

=item * is_disabled

A boolean which defaults to false.

=back

=head1 CONVERTING TITLES

By default, titles are converted by splitting StudlyCaps words apart, so
"RandomKwikiPage" becomes "Random Kwiki Page".

The one exception is that the Kwiki "HomePage" becomes the Silki "Front Page".

You can use a converter subclass to add more intelligence to this process.

Also, you'll need to manually delete your wiki's front page (for now).

=head1 DUMPING TITLES AND USERS

The F<kwiki2silki> script can dump all titles and users from your kwiki
install:

  kwiki2silki --wiki           'Silki Wiki Title'   \
              --kwiki-root     /path/to/kwiki       \
              --dump-page-titles                    \
              --dump-usernames

This is very handy in helping you come up with a user map.

=head1 AUTHOR

  Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

