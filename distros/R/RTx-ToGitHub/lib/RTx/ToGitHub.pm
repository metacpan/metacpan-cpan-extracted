package RTx::ToGitHub;

use v5.10;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.09';

use CPAN::Meta;
use Carp;
use Data::Dumper::Concise;
use Encode qw( encode );
use IO::Prompt::Tiny;
use IPC::System::Simple qw( capturex );
use Path::Tiny;
use Pithub;
use RT::Client::REST::Ticket;
use RT::Client::REST::User;
use RT::Client::REST;
use Specio::Declare;
use Specio::Library::Builtins;
use Specio::Library::Numeric;
use Specio::Library::Perl;
use Specio::Library::String;
use Try::Tiny;
use URI::Escape qw( uri_escape );

use Moo;
use MooX::Options;

option dry => (
    is      => 'ro',
    isa     => t('Bool'),
    default => 0,
    doc     => 'Dry run only. No changes will be made to RT or GitHub.',
);

option prompt => (
    is          => 'ro',
    isa         => t('Bool'),
    negativable => 1,
    default     => 1,
    doc => 'Set this to false to disable all prompts for information. The'
        . ' command will die if it cannot determine all the needed parameters'
        . ' from CLI options or other means.',
);

option github_user => (
    is      => 'ro',
    isa     => t('NonEmptyStr'),
    format  => 's',
    lazy    => 1,
    builder => '_build_github_user',
    doc     =>
        'The GitHub user to use. Will default to github.user in your git config if available.'
        . ' Otherwise it will look at the remote URL and try to guess.',
);

option github_token => (
    is      => 'ro',
    isa     => t('NonEmptyStr'),
    format  => 's',
    lazy    => 1,
    builder => '_build_github_token',
    doc     =>
        'The GitHub token to use. Will default to github.token in your git config if available.',
);

option repo => (
    is      => 'ro',
    isa     => t('NonEmptyStr'),
    format  => 's',
    lazy    => 1,
    builder => '_build_repo',
    doc     =>
        'The GitHub repo to operate against. By default this will be determined'
        . ' by looking at URL for the origin remote.',
);

option pause_id => (
    is      => 'ro',
    isa     => t('NonEmptyStr'),
    format  => 's',
    lazy    => 1,
    builder => '_build_pause_id',
    doc     =>
        'Your PAUSE ID. This will be found by looking at ~/.pause if that file exists.',
);

option pause_password => (
    is      => 'ro',
    isa     => t('NonEmptyStr'),
    format  => 's',
    lazy    => 1,
    builder => '_build_pause_password',
    doc     =>
        'Your PAUSE password. This will be found by looking at ~/.pause if that file exists.',
);

option dist => (
    is      => 'ro',
    isa     => t('DistName'),
    format  => 's',
    lazy    => 1,
    builder => '_build_dist',
    doc     =>
        'The distribution name as seen on RT. By default this will be determined by'
        . ' looking at [MY]META.* files in the working directory, a dist.ini, or the repo name.',
);

option force => (
    is      => 'ro',
    isa     => t('Bool'),
    lazy    => 1,
    default => sub { $_[0]->test ? 1 : 0 },
    doc     => 'Create issues in GitHub even if one already exists.',
);

option resolve => (
    is          => 'ro',
    isa         => t('Bool'),
    negativable => 1,
    lazy        => 1,
    default     => sub { $_[0]->test ? 0 : 1 },
    doc         =>
        'Set this to false to to disable resolving RT tickets as they are converted.',
);

option ticket => (
    is        => 'ro',
    isa       => t('PositiveInt'),
    format    => 'i',
    predicate => '_has_ticket',
    doc       => 'Only operate on the given RT ticket.',
);

option test => (
    is      => 'ro',
    isa     => t('Bool'),
    lazy    => 1,
    default => 0,
    doc     =>
        'Run in test mode. This is equivalent to setting --no-resolve and --force.'
        . ' It also changes how GitHub tickets are formatted to avoid including'
        . ' @mentions of other people so they do not get a flood of email while you test.',
);

option debug_ua => (
    is      => 'ro',
    isa     => t('Bool'),
    lazy    => 1,
    default => 0,
    doc     => 'Use LWP::ConsoleLogger to debug the interactions with RT',
);

has _default_dist_name => (
    is      => 'ro',
    isa     => t('Str'),
    lazy    => 1,
    builder => '_build_default_dist_name',
);

has _pause_rc_values => (
    is      => 'ro',
    isa     => t( 'HashRef', of => t('NonEmptyStr') ),
    lazy    => 1,
    builder => '_build_pause_rc_values',
);

has _git_config => (
    is      => 'ro',
    isa     => t('HashRef'),
    lazy    => 1,
    builder => '_build_git_config',
);

has _rt_client => (
    is      => 'ro',
    isa     => object_isa_type('RT::Client::REST'),
    lazy    => 1,
    builder => '_build_rt_client',
);

has _pithub => (
    is      => 'ro',
    isa     => object_isa_type('Pithub'),
    lazy    => 1,
    builder => '_build_pithub',
);

has _rt_to_github_map => (
    is      => 'ro',
    isa     => t('HashRef'),
    lazy    => 1,
    builder => '_build_rt_to_github_map',
);

has _contributor_map => (
    is      => 'ro',
    isa     => t('HashRef'),
    lazy    => 1,
    builder => '_build_contributor_map',
);

sub run {
    my $self = shift;

    $self->_ensure_all_config;

    my $msg = sprintf(
        'Converting %s from the %s RT queue to the %s/%s GitHub repo.',
        ( $self->ticket ? 'ticket #' . $self->ticket : 'all tickets' ),
        $self->dist,
        $self->github_user,
        $self->repo
    );
    say $msg or die $!;
    if ( $self->resolve ) {
        say 'Will resolve all RT tickets.' or die $!;
    }
    unless ( $self->force ) {
        say 'Will skip tickets that are already converted.' or die $!;
    }

    $self->_convert_tickets;

    return 0;
}

sub _ensure_all_config {
    my $self = shift;

    # Each of these will look for a default and/or prompt the user if not set
    # on the CLI. If the value it comes up with is not valid (an empty string,
    # for example) it will die.
    $self->github_user;
    $self->github_token;
    $self->repo;
    $self->pause_id;
    $self->pause_password;
    $self->dist;

    return;
}

sub _build_git_config {
    my $self = shift;

    my %config;
    for my $line ( split /\n/, capturex(qw( git config --list )) ) {
        my ( $k, $v ) = split /=/, $line, 2;
        $config{$k} = $v;
    }

    return \%config;
}

sub _build_github_user {
    my $self = shift;

    my $name = $self->_git_config->{'github.user'};
    if ( !defined $name
        && ( $self->_git_config->{'remote.origin.url'} // q{} )
        =~ m{github\.com[:/]([^/]+)} ) {

        $name = $1;
    }

    $name = IO::Prompt::Tiny::prompt( 'GitHub user:', ( $name // q{} ) )
        if $self->prompt;

    return $name;
}

sub _build_github_token {
    my $self = shift;

    my $token = $self->_git_config->{'github.token'};

    $token = IO::Prompt::Tiny::prompt( 'GitHub token:', ( $token // q{} ) )
        if $self->prompt;

    return $token;
}

sub _build_repo {
    my $self = shift;

    my ($repo)
        = ( $self->_git_config->{'remote.origin.url'} // q{} )
        =~ m{github\.com[:/].+?/(.+?)(?:\.git)?$};

    $repo = IO::Prompt::Tiny::prompt( 'GitHub repo:', ( $repo // q{} ) )
        if $self->prompt;

    return $repo;
}

sub _build_pause_id {
    my $self = shift;

    my $id = $self->_pause_rc_values->{user};

    $id = IO::Prompt::Tiny::prompt( 'PAUSE ID:', ( $id // q{} ) )
        if $self->prompt;

    return $id;
}

sub _build_pause_password {
    my $self = shift;

    my $password = $self->_pause_rc_values->{password};

    $password
        = IO::Prompt::Tiny::prompt( 'PAUSE password:', ( $password // q{} ) )
        if $self->prompt;

    return $password;
}

sub _build_pause_rc_values {
    my $pause_rc = path( $ENV{HOME}, '.pause' );
    return {} unless $pause_rc->exists;

    my %config;
    for my $line ( $pause_rc->lines( { chomp => 1 } ) ) {
        my ( $k, $v ) = split / +/, $line, 2;
        $config{$k} = $v;
    }

    return \%config;
}

sub _build_dist {
    my $self = shift;

    my $dist = $self->_dist_from_local_files;
    $dist //= $self->repo;

    $dist = IO::Prompt::Tiny::prompt( 'RT distro name:', ( $dist // q{} ) )
        if $self->prompt;

    return $dist;
}

sub _dist_from_local_files {
    my ($meta) = grep {-r} qw( MYMETA.json MYMETA.yml META.json META.yml );
    if ($meta) {
        my $cm = CPAN::Meta->load_file($meta);
        return $cm->name;
    }
    elsif ( -r 'dist.ini' ) {
        my $dist = path('dist.ini');
        for my $line ( $dist->lines( { chomp => 1 } ) ) {
            my ($name) = $line =~ /name\s*=\s*(\S+)/;
            return $name if defined $name;

            # We'll assume that plugin config always comes after core dzil
            # config
            last if $line =~ /^\[/;
        }
    }
}

sub _convert_tickets {
    my $self = shift;

    my $query = sprintf( <<'EOF', $self->dist );
Queue = '%s'
and
( Status = 'new' or Status = 'open' or Status = 'stalled' or Status = 'patched')
EOF
    $query .= sprintf( 'and id = %s', $self->ticket ) if $self->_has_ticket;

    my @rt_tickets = $self->_rt_client->search(
        type  => 'ticket',
        query => $query,
    );

    for my $id (@rt_tickets) {
        unless ( $self->force ) {
            if ( my $issue = $self->_rt_to_github_map->{$id} ) {
                say
                    "Ticket #$id is already on GitHub as $issue->{number} ($issue->{html_url})"
                    or die $!;
                next;
            }
        }

        $self->_convert_one_ticket($id);
    }
}

sub _build_rt_client {
    my $self = shift;

    my $rt = RT::Client::REST->new( server => 'https://rt.cpan.org/' );

    if ( $self->debug_ua ) {
        require LWP::ConsoleLogger;
        my $logger = LWP::ConsoleLogger->new(
            dump_params => 1,
        );
        $rt->_ua->add_handler(
            'response_done',
            sub { $logger->response_callback(@_) }
        );
        $rt->_ua->add_handler(
            'request_send',
            sub { $logger->request_callback(@_) }
        );
    }

    $rt->login(
        username => $self->pause_id,
        password => $self->pause_password,
    );

    return $rt;
}

sub _build_pithub {
    my $self = shift;

    return Pithub->new(
        user  => $self->github_user,
        repo  => $self->repo,
        token => $self->github_token,
    );
}

sub _build_rt_to_github_map {
    my $self = shift;

    my $issues = $self->_pithub->issues->list;
    $issues->auto_pagination(1);

    my %map;
    while ( my $issue = $issues->next ) {
        next unless exists $issue->{body};
        if ( $issue->{body} =~ /\[rt\.cpan\.org #(\d+)\]/ ) {
            $map{$1} = $issue;
        }
    }

    return \%map;
}

sub _convert_one_ticket {
    my $self = shift;
    my $id   = shift;

    my ( $ticket, $trunc_subject, $main, @comments )
        = $self->_extract_ticket_data($id);

    my @args = ( $id, $trunc_subject, $main, @comments );
    if ( $self->dry ) {
        $self->_print_dry_ticket(@args);
    }
    else {
        my $gh_url = $self->_make_github_issue(@args)
            or return;
        $self->_close_rt_ticket( $id, $ticket, $gh_url );
    }
}

sub _extract_ticket_data {
    my $self = shift;
    my $id   = shift;

    my $ticket = RT::Client::REST::Ticket->new(
        rt => $self->_rt_client,
        id => $id,
    );
    $ticket->retrieve;

    my $subject = $ticket->subject;
    my $trunc_subject
        = length($subject) <= 24
        ? $subject
        : ( substr( $subject, 0, 20 ) . ' ...' );
    my $status = $ticket->status;
    my $body
        = "Migrated from [rt.cpan.org #$id](https://rt.cpan.org/Ticket/Display.html?id=$id) (status was '$status')\n";

    $body .= "\nRequestors:\n";
    $body .= join q{},
        map {"* $_\n"}
        map { $self->_maybe_tag_email($_) } $ticket->requestors;

    my @attach_links;
    my $attach = $ticket->attachments->get_iterator;
    while ( my $i = $attach->() ) {
        my $xact   = $i->transaction_id;
        my $att_id = $i->id;
        my $name   = $i->file_name or next;
        push @attach_links, sprintf(
            '[%s](https://rt.cpan.org/Ticket/Attachment/%s/%s/%s)',
            $name,
            $xact,
            $att_id,
            uri_escape($name),
        );
    }
    if (@attach_links) {
        my $attach_list = join( q{}, map {"* $_\n"} @attach_links );
        $body .= "\nAttachments:\n$attach_list\n";
    }

    my $create = $ticket->transactions( type => 'Create' )->get_iterator->();
    my $from   = $self->_transaction_from($create);
    $body .= sprintf( "\n%s\n\n%s\n\n", $from, $create->content );

    my @comments;
    my $rt_comments
        = $ticket->transactions( type => 'Correspond' )->get_iterator;
    while ( my $c = $rt_comments->() ) {
        my $c_from = $self->_transaction_from($c);
        push @comments,
            { body => sprintf( "%s\n\n%s\n", $c_from, $c->content ) };
    }

    return (
        $ticket,
        $trunc_subject,
        {
            title  => $subject,
            body   => $body,
            labels => [ ( $status eq 'stalled' ? 'stalled' : () ) ],
        },
        @comments,
    );
}

{
    my %cache;

    sub _transaction_from {
        my $self  = shift;
        my $trans = shift;

        my $user = $cache{ $trans->creator } ||= do {
            try {
                my $u = RT::Client::REST::User->new(
                    id => $trans->creator,
                    rt => $trans->rt,
                );
                $u->retrieve;
                $u;
            };
        };

        my $email;
        $email = lc $user->email_address if $user;
        $email //= lc $trans->creator;

        return sprintf(
            'From %s on %s:',
            $self->_maybe_tag_email($email),
            $trans->created
        );
    }
}

sub _maybe_tag_email {
    my $self  = shift;
    my $email = shift;

    my $text         = $email;
    my $contributors = $self->_contributor_map;
    $text
        .= ' (@'
        . ( $self->test ? q{ } : q{} )
        . $contributors->{ lc $email } . ')'
        if $contributors->{ lc $email };

    return $text;
}

sub _build_contributor_map {
    local $@ = undef;
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    my $map = eval do { local $/ = undef; <DATA> };
    die $@ if $@;
    return $map;
}

sub _print_dry_ticket {
    my $self          = shift;
    my $id            = shift;
    my $trunc_subject = shift;
    my $main          = shift;
    my @comments      = @_;

    say "----------------------------------\n" or die $!;

    say "ticket #$id ($trunc_subject) would be copied to github as:"
        or die $!;

    $main->{body} =~ s/^/    /gm;
    say "    Subject: $main->{title}\n\n$main->{body}" or die $!;

    for my $c (@comments) {
        say '    ----' or die $!;
        $c->{body} =~ s/^/    /gm;
        say $c->{body} or die $!;
    }
    say "\n" or die $!;

    return;
}

sub _make_github_issue {
    my $self          = shift;
    my $id            = shift;
    my $trunc_subject = shift;
    my $main          = shift;
    my @comments      = @_;

    my $result;
    return unless try {
        $result = $self->_pithub->issues->create(
            data => {
                title => encode( 'UTF-8', $main->{title} ),
                body  => encode( 'UTF-8', $main->{body} ),
            }
        );
        1;
    }
    catch {
        say "Ticket #$id ($trunc_subject) had an error posting to Github: $_"
            or die $!;
        0;
    };

    unless ( $result->success ) {
        say "Ticket #$id ($trunc_subject) had an error posting to Github:"
            or die $!;
        say Dumper( $result->content ) or die $!;
        return;
    }
    my $issue = $result->first;

    my $gh_id  = $issue->{number};
    my $gh_url = $issue->{html_url};
    say "Ticket #$id ($trunc_subject) copied to GitHub as #$gh_id ($gh_url)"
        or die $!;

    for my $c (@comments) {
        my $c_result = $self->_pithub->issues->comments->create(
            issue_id => $gh_id,
            data     => { body => encode( 'UTF-8', $c->{body} ) },
        );
        unless ( $c_result->success ) {
            say "Error adding a comment to issue #$gh_id:" or die $!;
            say Dumper( $c_result->content )               or die $!;
            return;
        }
    }

    return $gh_url;
}

sub _close_rt_ticket {
    my $self   = shift;
    my $id     = shift;
    my $ticket = shift;
    my $gh_url = shift;

    return unless $self->resolve;

    return unless try {
        $self->_rt_client->correspond(
            ticket_id => $id,
            message   => "Ticket migrated to GitHub as $gh_url"
        );
        $ticket->status('resolved');
        $ticket->store;
        1;
    }
    catch {
        say "Error closing ticket #$id on RT" or die $!;
        0;
    };

    say "Closed ticket #$id on RT" or die $!;
}

if ( RT::Client::REST->VERSION <= 0.50 ) {
    no warnings 'redefine';

    ## no critic (ValuesAndExpressions::ProhibitInterpolationOfLiterals, RegularExpressions::ProhibitUnusualDelimiters, ValuesAndExpressions::ProhibitCommaSeparatedStatements)

#<<<
    *RT::Client::REST::Object::from_form = sub {
    my $self = shift;

    unless (@_) {
        RT::Client::REST::Object::NoValuesProvidedException->throw;
    }

    my $hash = shift;

    unless ('HASH' eq ref($hash)) {
        RT::Client::REST::Object::InvalidValueException->throw(
            "Expecting a hash reference as argument to 'from_form'",
        );
    }

    # lowercase hash keys
    my $i = 0;
    $hash = { map { ($i++ & 1) ? $_ : lc } %$hash };

    my $attributes = $self->_attributes;
    my %rest2attr;  # Mapping of REST names to our attributes;
    while (my ($attr, $value) = each(%$attributes)) {
        my $rest_name = (exists($attributes->{$attr}{rest_name}) ?
                         lc($attributes->{$attr}{rest_name}) : $attr);
        $rest2attr{$rest_name} = $attr;
    }

    # Now set attributes:
    while (my ($key, $value) = each(%$hash)) {
        # Handle custom fields, ideally /(?(1)})/ would be appened to RE
    if( $key =~ m%^(?:cf|customfield)(?:-|\.\{)([#\s\w_:()?/-]+)% ){
        $key = $1;

            # XXX very sketchy. Will fail on long form data e.g; wiki CF
            if ($value =~ /,/) {
                $value = [ split(/\s*,\s*/, $value) ];
            }

            $self->cf($key, $value);
            next;
        }

        unless (exists($rest2attr{$key})) {
            warn "Unknown key: $key\n";
            next;
        }

    # Fix for https://rt.cpan.org/Ticket/Display.html?id=118729
        if ($key ne 'content' && $value =~ m/not set/i) {
            $value = undef;
        }

        my $method = $rest2attr{$key};
        if (exists($attributes->{$method}{form2value})) {
            $value = $attributes->{$method}{form2value}($value);
        } elsif ($attributes->{$method}{list}) {
            $value = [split(/\s*,\s*/, $value)],
        }

        $self->$method($value);
    }

    return;
}
#>>>
}

1;

# ABSTRACT: Convert rt.cpan.org tickets to GitHub issues

=pod

=encoding UTF-8

=head1 NAME

RTx::ToGitHub - Convert rt.cpan.org tickets to GitHub issues

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    $> rt-to-github.pl

=head1 DESCRIPTION

This is a tool to convert RT tickets to GitHub issues. When you run it, it
will:

=over 4

=item 1. Prompt you for any info it needs

Run with C<--no-prompt> to disable prompts, in which case it will either use
the command line options you provide or look in various config files and C<git
config> for needed info.

=item 2. Make GitHub issues for each RT ticket

The body of the ticket will be the new issue body, with replies converted to
comments. Requestors and others participating in the discussion will be
converted to C<@username> mentions on GitHub. The conversion is based on a
one-time data dump made by pulling author data from MetaCPAN to make an email
address to GitHub username map. Patches to this map are welcome.

Only tickets with the "new", "open", "patched", or "stalled" status are
converted. Stalled tickets are given a "stalled" label on GitHub.

=item 3. Close the RT ticket

Unless you pass the C<--no-resolve> option.

=back

=for Pod::Coverage .*

=head1 COMMAND LINE OPTIONS

This command accepts the following flags:

=head2 --dry

Run in dry-run mode. No issues will be created and no RT tickets will be
resolved. This will just print some output to indicate what _would_ have
happened.

=head2 --no-prompt

By default you will be prompted to enter various bits of info, even if you
give everything needed on the CLI. If you pass this flag, then only CLI
options and inferred config values will be used.

=head2 --github-user

The github user to use. This defaults to looking for a "github.user" config
item in your git config.

=head2 --github-token

The github token to use. This defaults to looking for a "github.token" config
item in your git config.

=head2 --repo

The repo name to use. By default this is determined by looking at the URL for
the remote named "origin". This should just be the repo name by itself,
without a username. So pass "Net-Foo", not "username/Net-Foo".

=head2 --pause-id

Your PAUSE ID. If you have a F<~/.pause> file this will be parsed for your
username.

=head2 --pause-password

Your PAUSE password. If you have a F<~/.pause> file this will be parsed for
your password.

=head2 --dist

The distribution name which is used for your RT queue name. By default, this
is taken by looking for F<[MY]META.*> files or looking in a F<dist.ini> in the
current directory. This falls back to the repo name.

=head2 --no-resolve

If you pass this flag then the RT tickets are not marked as closed as they are
converted.

=head2 --ticket

You can specify a single RT ticket to convert by giving a ticket ID number.

=head2 --force

By default, if a matching issue already exists on GitHub, the ticket will not
be converted. Pass this flag to force a new issue to be created anyway.

=head1 CREDITS

Much of the code in this module was taken from David Golden's conversion
script at L<https://github.com/dagolden/zzz-rt-to-github>.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/RTx-ToGitHub/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for RTx-ToGitHub can be found at L<https://github.com/houseabsolute/RTx-ToGitHub>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<https://www.urth.org/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Dan Stewart Michiel Beijen

=over 4

=item *

Dan Stewart <danielandrewstewart@gmail.com>

=item *

Michiel Beijen <michiel.beijen@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by David Golden and Dave Rolsky.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut

__DATA__
# This was produced from public MetaCPAN API data using
# ./dev-bin/metacpan-github-names.pl in this distro
{
  "#####\@juerd.nl" => "juerd",
  "a\@ngs.io" => "ngs",
  "aanari\@cpan.org" => "aanari",
  "aar\@cpan.org" => "alexrj",
  "aassad\@cpan.org" => "arhuman",
  "abablabab\@cpan.org" => "abablabab",
  "abbypan\@cpan.org" => "abbypan",
  "abbypan\@gmail.com" => "abbypan",
  "abe\@cpan.org" => "xtaran",
  "abe\@debian.org" => "xtaran",
  "abeltje\@cpan.org" => "abeltje",
  "aberndt\@cpan.org" => "bentglasstube",
  "abh\@cpan.org" => "abh",
  "abraxxa\@cpan.org" => "abraxxa",
  "acalpini\@cpan.org" => "dada",
  "accardo\@cpan.org" => "mixedconnections",
  "acme\@astray.com" => "acme",
  "adam.prime\@utoronto.ca" => "jsut",
  "adam.stokes\@ubuntu.com" => "battlemidget",
  "adam\@clarke.id.au" => "adamc00",
  "adamc\@cpan.org" => "adamc00",
  "adamjs\@cpan.org" => "battlemidget",
  "adie\@cpan.org" => "adrianh",
  "adrianh\@quietstars.com" => "adrianh",
  "aduitsis\@cpan.org" => "aduitsis",
  "adulau\@cpan.org" => "adulau",
  "adulau\@foo.be" => "adulau",
  "aivaturi\@cpan.org" => "aivaturi",
  "ajpage\@cpan.org" => "andrewjpage",
  "akiym\@cpan.org" => "akiym",
  "akkornel\@cpan.org" => "akkornel",
  "akreal\@cpan.org" => "akreal",
  "akron\@cpan.org" => "akron",
  "alabamapaul\@gmail.com" => "alabamapaul",
  "alec\@cpan.org" => "alecchen",
  "alex\@chmrr.net" => "alexmv",
  "alexbio\@cpan.org" => "ghedo",
  "alexchorny\@gmail.com" => "chorny",
  "alexm\@cpan.org" => "alexm",
  "alexmv\@cpan.org" => "alexmv",
  "ali\@anari.me" => "aanari",
  "ambs\@cpan.org" => "ambs",
  "ambs\@perl-hackers.net" => "ambs",
  "amd\@cpan.org" => "amd",
  "amirite\@cpan.org" => "sharabash",
  "amorette\@cpan.org" => "am0c",
  "andk\@cpan.org" => "andk",
  "andreas.koenig.7os6vvqr\@franz.ak.mind.de" => "andk",
  "andreas.marienborg\@gmail.com" => "omega",
  "andreas\@andreasvoegele.com" => "voegelas",
  "andrefs\@cpan.org" => "andrefs",
  "andremar\@cpan.org" => "omega",
  "andrew+perl\@andrew-jones.com" => "andrewrjones",
  "andrew\@cpan.org" => "afresh1",
  "andy\@petdance.com" => "petdance",
  "andychilton\@gmail.com" => "chilts",
  "antipasta\@cpan.org" => "antipasta",
  "apocal\@cpan.org" => "apocalypse",
  "aprime\@cpan.org" => "jsut",
  "aquilina\@cpan.org" => "mjaquilina",
  "arc\@cpan.org" => "arc",
  "arcanez\@cpan.org" => "arcanez",
  "arfreitas\@cpan.org" => "glasswalk3r",
  "arhuman\@gmail.com" => "arhuman",
  "aristotle\@cpan.org" => "ap",
  "arjones\@cpan.org" => "andrewrjones",
  "arodland\@cpan.org" => "arodland",
  "arpad.szasz\@plenum.ro" => "arpadszasz",
  "arpi\@cpan.org" => "arpadszasz",
  "ashevchuk\@cpan.org" => "ashevchuk",
  "ashley\@cpan.org" => "pangyre",
  "ask\@perl.org" => "abh",
  "athomason\@cpan.org" => "athomason",
  "atodorov\@cpan.org" => "atodorov",
  "atodorov\@otb.bg" => "atodorov",
  "atrox\@cpan.org" => "atrox",
  "aubertg\@cpan.org" => "guillaumeaubert",
  "audreyt\@cpan.org" => "audreyt",
  "auggy\@cpan.org" => "missaugustina",
  "autarch\@gmail.com" => "autarch",
  "autarch\@urth.org" => "autarch",
  "avar\@cpan.org" => "avar",
  "avenj\@cobaltirc.org" => "avenj",
  "avenj\@cpan.org" => "avenj",
  "avkhozov\@cpan.org" => "avkhozov",
  "awncorp\@cpan.org" => "alnewkirk",
  "awwaiid\@cpan.org" => "awwaiid",
  "awwaiid\@thelackthereof.org" => "awwaiid",
  "ayoung\@cpan.org" => "harleypig",
  "b2gills\@gmail.com" => "b2gills",
  "backstrom\@cpan.org" => "backstrom",
  "barbie\@cpan.org" => "barbie",
  "barbie\@missbarbell.co.uk" => "barbie",
  "barefoot\@cpan.org" => "barefootcoder",
  "barefootcoder\@gmail.com" => "barefootcoder",
  "baskarn\@cpan.org" => "virendrabaskar",
  "bbarker\@cpan.org" => "bbarker",
  "bbyrd\@cpan.org" => "sineswiper",
  "bcde\@cpan.org" => "ruzhnikov",
  "bdfoy\@cpan.org" => "briandfoy",
  "bdr\@cpan.org" => "highflying",
  "beanz\@cpan.org" => "beanz",
  "belden.lyman\@gmail.com" => "belden",
  "belden\@cpan.org" => "belden",
  "ben.whosgonna.com\@gmail.com" => "whosgonna",
  "ben\@bdr.org" => "highflying",
  "ben\@vinnerd.com" => "bvinnerd",
  "bernhard\@cpan.org" => "amannb",
  "berov\@cpan.org" => "kberov",
  "bessarabv\@cpan.org" => "bessarabov",
  "bgills\@cpan.org" => "b2gills",
  "bgray\@cpan.org" => "util",
  "bhann\@cpan.org" => "c0bra",
  "bherweyer\@cpan.org" => "kulag",
  "bhserror\@cpan.org" => "peroumal1",
  "biffen\@cpan.org" => "biffen",
  "bigpresh\@cpan.org" => "bigpresh",
  "bingos\@cpan.org" => "bingos",
  "bjakubski\@cpan.org" => "bjakubski",
  "bkb\@cpan.org" => "benkasminbullock",
  "blabos\@cpan.org" => "blabos",
  "blas.gordon\@gmail.com" => "zipf",
  "blhotsky\@cpan.org" => "reyjrar",
  "blom\@cpan.org" => "b10m",
  "bluefeet\@cpan.org" => "bluefeet",
  "bluefeet\@gmail.com" => "bluefeet",
  "bob\@cpan.org" => "rjw1",
  "bob\@randomness.org.uk" => "rjw1",
  "bobtfish\@bobtfish.net" => "bobtfish",
  "bobtfish\@cpan.org" => "bobtfish",
  "boethin\@cpan.org" => "boethin",
  "boethin\@xn--domain.net" => "boethin",
  "bokutin\@bokut.in" => "bokutin",
  "bokutin\@cpan.org" => "bokutin",
  "bollwarm\@ijz.me" => "bollwarm",
  "book\@cpan.org" => "book",
  "bor\@cpan.org" => "bor",
  "bowtie\@cpan.org" => "kevindawson",
  "bphillips\@cpan.org" => "brianphillips",
  "brad.lhotsky\@gmail.com" => "reyjrar",
  "brad\@divisionbyzero.net" => "reyjrar",
  "brainbuz\@cpan.org" => "brainbuz",
  "brian.d.foy\@gmail.com" => "briandfoy",
  "bricas\@cpan.org" => "bricas",
  "broq\@cpan.org" => "broquaint",
  "brunov\@cpan.org" => "brunov",
  "btik-cpan\@scoubidou.com" => "maxatome",
  "burnersk\@cpan.org" => "burnersk",
  "bvinnerd\@cpan.org" => "bvinnerd",
  "c.kras\@pcc-online.net" => "htbaa",
  "cadavis\@cpan.org" => "chadadavis",
  "cafe01\@gmail.com" => "cafe01",
  "cafegratz\@cpan.org" => "cafe01",
  "caio\@cpan.org" => "caio",
  "calid1984\@gmail.com" => "calid",
  "calid\@cpan.org" => "calid",
  "carlos\@cpan.org" => "carloslima",
  "carwash\@cpan.org" => "carwash",
  "castaway\@desert-island.me.uk" => "castaway",
  "cbrandt\@cpan.org" => "cbrandtbuffalo",
  "cdraug\@cpan.org" => "carandraug",
  "cebjyre\@cpan.org" => "cebjyre",
  "chad.a.davis\@gmail.com" => "chadadavis",
  "chandwer\@cpan.org" => "chandwer",
  "chansen\@cpan.org" => "chansen",
  "chilts\@cpan.org" => "chilts",
  "chim\@cpan.org" => "wu-wu",
  "chip\@pobox.com" => "chipdude",
  "chips\@cpan.org" => "chipdude",
  "chisel\@chizography.net" => "chiselwright",
  "chisel\@cpan.org" => "chiselwright",
  "cho45\@lowreal.net" => "cho45",
  "chorny\@cpan.org" => "chorny",
  "chris.handwerker\@gmail.com" => "chandwer",
  "chris.prather\@tamarou.com" => "perigrin",
  "chris\@bingosnet.co.uk" => "bingos",
  "chris\@prather.org" => "perigrin",
  "chris\@wps.io" => "rsrchboy",
  "chrisv\@cpan.org" => "chrisv",
  "chsanch\@cpan.org" => "chsanch",
  "cindy\@cpan.org" => "cindylinz",
  "cjfields\@bioperl.org" => "cjfields",
  "cjfields\@cpan.org" => "cjfields",
  "cjm\@cpan.org" => "madsen",
  "ckras\@cpan.org" => "htbaa",
  "claes\@surfar.nu" => "claesjac",
  "claesjac\@cpan.org" => "claesjac",
  "clicktx\@cpan.org" => "clicktx",
  "cng\@cpan.org" => "cngarrison",
  "cono\@cpan.org" => "cono",
  "contact\@delonnewman.name" => "delonnewman",
  "cooper\@cpan.org" => "cooper",
  "cornelius\@cpan.org" => "c9s",
  "cosimo\@cpan.org" => "cosimo",
  "covington\@cpan.org" => "mfcovington",
  "cpan.ibobyr\@gmail.com" => "ilya-bobyr",
  "cpan.nospamthanks\@iijo.org" => "kablamo",
  "cpan.wade\@anomaly.org" => "gwadej",
  "cpan\@5thplane.com" => "lukec",
  "cpan\@aaroncrane.co.uk" => "arc",
  "cpan\@abablabab.co.uk" => "abablabab",
  "cpan\@audreyt.org" => "audreyt",
  "cpan\@caioromao.com" => "caio",
  "cpan\@imail.com" => "krimdomu",
  "cpan\@lug-nut.com" => "jayceh",
  "cpan\@maff.scot" => "maffsie",
  "cpan\@openstrike.co.uk" => "openstrike",
  "cpan\@papercreatures.com" => "eaglecolt",
  "cpan\@petermblair.com" => "petermblair",
  "cpan\@pgarrett.net" => "kingpong",
  "cpan\@referencethis.com" => "iarna",
  "cpan\@sartak.org" => "sartak",
  "cpan\@triv.org" => "ctriv",
  "cpan\@zoffix.com" => "zoffixznet",
  "crein\@cpan.org" => "ctriv",
  "crux\@cpan.org" => "vlet",
  "crzedpsyc\@cpan.org" => "crazedpsyc",
  "cseaton\@cpan.org" => "chilledham",
  "cside.story\@gmail.com" => "cside",
  "cside\@cpan.org" => "cside",
  "csson\@cpan.org" => "csson",
  "ctreptow\@cpan.org" => "ctreptow",
  "cub\@cpan.org" => "cub-uanic",
  "curtis\@cpan.org" => "aggrolite",
  "cvlibrary\@cpan.org" => "cv-library",
  "cweyl\@alumni.drew.edu" => "rsrchboy",
  "cynovg\@cpan.org" => "cynovg",
  "dada\@perl.it" => "dada",
  "dadams\@cpan.org" => "dudley5000",
  "dagolden\@cpan.org" => "dagolden",
  "dakkar\@cpan.org" => "dakkar",
  "dakkar\@thenautilus.net" => "dakkar",
  "damog\@cpan.org" => "damog",
  "dams\@cpan.org" => "dams",
  "dan.blanchard\@gmail.com" => "dan-blanchard",
  "dana\@acm.org" => "danaj",
  "danaj\@cpan.org" => "danaj",
  "dandv\@cpan.org" => "dandv",
  "dapatrick\@cpan.org" => "dap",
  "data\@cpan.org" => "datamuc",
  "dave\@houseabsolute.com" => "autarch",
  "dave\@perlhacks.com" => "davorg",
  "davecross\@cpan.org" => "davorg",
  "david.wheeler\@iovation.com" => "theory",
  "david.wheeler\@pgexperts.com" => "theory",
  "david\@axiombox.com" => "damog",
  "david\@cantrell.org.uk" => "drhyde",
  "david\@dorward.me.uk" => "dorward",
  "david\@justatheory.com" => "theory",
  "david\@kineticode.com" => "theory",
  "david\@lunar-theory.com" => "theory",
  "david\@olrik.dk" => "davidolrik",
  "david\@weekly.org" => "dweekly",
  "davido\@cpan.org" => "daoswald",
  "davidp\@preshweb.co.uk" => "bigpresh",
  "dazjorz\@cpan.org" => "sgielen",
  "dbb008\@gmail.com" => "dbb",
  "dbb\@cpan.org" => "dbb",
  "dblanchard\@ets.org" => "dan-blanchard",
  "dboehmer\@cpan.org" => "dboehmer",
  "dburke\@addictmud.org" => "dwburke",
  "dburke\@cpan.org" => "dwburke",
  "dcantrell\@cpan.org" => "drhyde",
  "dcpetrov\@cpan.org" => "dpetrov",
  "dday\@cpan.org" => "davidlday",
  "ddrp\@cpan.org" => "daybologic",
  "ddumont\@cpan.org" => "dod38fr",
  "dean\@fragfest.com.au" => "djzort",
  "delon\@cpan.org" => "delonnewman",
  "derf\@cpan.org" => "derf",
  "deusex\@cpan.org" => "deusex80",
  "dev.ashevchuk\@gmail.com" => "ashevchuk",
  "dev\@just4i.ru" => "kadavr",
  "develop\@traveljury.com" => "clintongormley",
  "dew\@cpan.org" => "dweekly",
  "dexter\@cpan.org" => "dex4er",
  "dgkontop\@cpan.org" => "dgkontopoulos",
  "dgl\@cpan.org" => "dgl",
  "dgl\@dgl.cx" => "dgl",
  "dichi\@cpan.org" => "bluescreen10",
  "dichoso\@gmail.com" => "bluescreen10",
  "diegok\@cpan.org" => "diegok",
  "digory\@cpan.org" => "jdigory",
  "dineshd\@cpan.org" => "dinesh-it",
  "diocles\@cpan.org" => "diocles",
  "dionys\@cpan.org" => "dionys",
  "diz\@cpan.org" => "tripside",
  "djcurtis\@cpan.org" => "derekjamescurtis",
  "djo\@cpan.org" => "davidolrik",
  "djzort\@cpan.org" => "djzort",
  "dmaki\@cpan.org" => "lestrrat",
  "dmcbride\@cpan.org" => "dmcbride",
  "dmitri\@cpan.org" => "dtikhonov",
  "dmol\@cpan.org" => "basiliscos",
  "doherty\@cpan.org" => "doherty",
  "dolmen\@cpan.org" => "dolmen",
  "dominic\@oneandoneis2.com" => "oneandoneis2",
  "domm\@cpan.org" => "domm",
  "dongxu.ma\@gmail.com" => "dxma/cpan",
  "dongxu\@cpan.org" => "dxma/cpan",
  "dorward\@cpan.org" => "dorward",
  "doug\@hcsw.org" => "hoytech",
  "doug\@somethingdoug.com" => "dougwilson",
  "dougdude\@cpan.org" => "dougwilson",
  "doy\@cpan.org" => "doy",
  "dpavlin\@cpan.org" => "dpavlin",
  "dpavlin\@rot13.org" => "dpavlin",
  "draegtun\@cpan.org" => "draegtun",
  "drako\@cpan.org" => "drako",
  "drebolo\@cpan.org" => "drebolo",
  "drolsky\@cpan.org" => "autarch",
  "drtech\@cpan.org" => "clintongormley",
  "dsblanch\@cpan.org" => "dan-blanchard",
  "dsheroh\@cpan.org" => "dsheroh",
  "dtikhonov\@live.com" => "dtikhonov",
  "dudleyadams\@gmail.com" => "dudley5000",
  "duelafn\@cpan.org" => "duelafn",
  "duffee\@cpan.org" => "duffee",
  "dvinci\@cpan.org" => "dvinciguerra",
  "dwheeler\@cpan.org" => "theory",
  "eagle\@eyrie.org" => "rra",
  "ebaudrez\@cpan.org" => "ebaudrez",
  "ecarroll\@cpan.org" => "evancarroll",
  "eco\@ecocode.net" => "ecocode",
  "ecocode\@cpan.org" => "ecocode",
  "edenc\@cpan.org" => "edenc",
  "edipreto\@cpan.org" => "edipretoro",
  "edipretoro\@gmail.com" => "edipretoro",
  "egga\@cpan.org" => "egga",
  "egiles\@cpan.org" => "egiles",
  "eitz\@cpan.org" => "eitz",
  "elemecca\@cpan.org" => "elemecca",
  "elliott\@cpan.org" => "eaglecolt",
  "emazep\@cpan.org" => "emazep",
  "enell\@cpan.org" => "zipf",
  "esaym\@cpan.org" => "smith153",
  "ether\@cpan.org" => "karenetheridge",
  "exc\@cpan.org" => "viliampucik",
  "exodist7\@gmail.com" => "exodist",
  "exodist\@cpan.org" => "exodist",
  "explorer\@cpan.org" => "joaquinferrero",
  "fabrice.gabolde\@gmail.com" => "fgabolde",
  "fany\@cpan.org" => "fany",
  "fawaka\@gmail.com" => "leont",
  "fayland\@cpan.org" => "fayland",
  "fayland\@gmail.com" => "fayland",
  "fco\@cpan.org" => "fco",
  "fernandocorrea\@gmail.com" => "fco",
  "ferreira\@cpan.org" => "aferreira",
  "fga\@cpan.org" => "fgabolde",
  "fibo\@cpan.org" => "fibo",
  "fkalter\@cpan.org" => "freekkalter",
  "flora\@cpan.org" => "rafl",
  "flygoast\@cpan.org" => "flygoast",
  "flygoast\@gmail.com" => "flygoast",
  "foxcool\@cpan.org" => "foxcool",
  "fractal\@cpan.org" => "hoytech",
  "fred\@redhotpenguin.com" => "redhotpenguin",
  "freek\@kalteronline.org" => "freekkalter",
  "frew\@cpan.org" => "frioux",
  "frimicc\@cpan.org" => "frimicc",
  "frioux\@gmail.com" => "frioux",
  "froggs\@cpan.org" => "froggs",
  "fvox\@cpan.org" => "fvox",
  "g.psy.va\@gmail.com" => "gfx",
  "gabriel.vieira\@gmail.com" => "gabrielmad",
  "gabriel\@cpan.org" => "gabrielmad",
  "garcer\@cpan.org" => "garcer",
  "garu\@cpan.org" => "garu",
  "gchild\@cpan.org" => "gordolio",
  "gchild\@gordonchild.com" => "gordolio",
  "gcj\@cpan.org" => "gatlin",
  "gdey\@cpan.org" => "gdey",
  "gdey_cpan\@deyfamily.org" => "gdey",
  "geidies\@cpan.org" => "geidies",
  "gempesaw\@cpan.org" => "gempesaw",
  "gene\@cpan.org" => "ology",
  "genehack\@cpan.org" => "genehack",
  "genehack\@genehack.org" => "genehack",
  "getty\@cpan.org" => "getty",
  "gfuji\@cpan.org" => "gfx",
  "ggoldbach\@cpan.org" => "glauschwuffel",
  "ghealton\@cpan.org" => "gilbertshub",
  "gideon\@cpan.org" => "gideondsouza",
  "gilbert\@healton.net" => "gilbertshub",
  "glitchmr\@cpan.org" => "glitchmr",
  "glitchmr\@myopera.com" => "glitchmr",
  "gnustavo\@cpan.org" => "gnustavo",
  "goncales\@cpan.org" => "italogoncales",
  "gortan\@cpan.org" => "mephinet",
  "goschwald\@maxmind.com" => "oschwald",
  "grantm\@cpan.org" => "grantm",
  "gray\@cpan.org" => "gray",
  "gregoa\@cpan.org" => "gregoa",
  "gregoa\@debian.org" => "gregoa",
  "gregor+pause\@comodo.priv.at" => "gregoa",
  "guenter\@perlhipster.com" => "lifeofguenter",
  "gugod\@cpan.org" => "gugod",
  "gugod\@gugod.org" => "gugod",
  "guimard\@cpan.org" => "guimard",
  "guksza\@gmail.com" => "uksza",
  "gvl\@cpan.org" => "ggl",
  "gwadej\@cpan.org" => "gwadej",
  "gwilliams\@cpan.org" => "kasei",
  "h.m.brand\@xs4all.nl" => "tux",
  "haarg\@cpan.org" => "haarg",
  "hackman\@cpan.org" => "hackman",
  "haggai\@cpan.org" => "alanhaggai",
  "halkeye\@cpan.org" => "halkeye",
  "hammer\@cpan.org" => "kadavr",
  "hanenkamp\@cpan.org" => "zostay",
  "harleypig\@gmail.com" => "harleypig",
  "harsha\@foobar.systems" => "harsha-mudi",
  "hb\@zecure.org" => "zit-hb",
  "hdp\@cpan.org" => "hdp",
  "hdp\@pobox.com" => "hdp",
  "helena\@cpan.org" => "liruoko",
  "helmut\@wollmersdorfer.at" => "wollmers",
  "hernan\@cpan.org" => "hernan604",
  "hideakio\@cpan.org" => "hideo55",
  "hinrik.sig\@gmail.com" => "hinrik",
  "hinrik\@cpan.org" => "hinrik",
  "hjansen\@cpan.org" => "heikojansen",
  "hkoba\@cpan.org" => "hkoba",
  "hma\@cpan.org" => "hma",
  "hmbrand\@cpan.org" => "tux",
  "hollie\@cpan.org" => "hollie",
  "houston\@cpan.org" => "openstrike",
  "hrafnkell\@cpan.org" => "kelihlodversson",
  "hunter\@missoula.org" => "mateu",
  "hurricup\@cpan.org" => "hurricup",
  "hurricup\@evstigneev.com" => "hurricup",
  "iam\@nnutter.com" => "nnutter",
  "ibobyr\@cpan.org" => "ilya-bobyr",
  "ido\@ido50.net" => "ido50",
  "idoperel\@cpan.org" => "ido50",
  "ikruglov\@cpan.org" => "ikruglov",
  "ilmari.vacklin\@iki.fi" => "wolverian",
  "ilmari\@cpan.org" => "ilmari",
  "ilmari\@ilmari.org" => "ilmari",
  "im.perlish\@gmail.com" => "perlish",
  "info\@code301.com" => "csson",
  "info\@mschuette.name" => "mschuett",
  "ingy\@cpan.org" => "ingydotnet",
  "ioanr\@cpan.org" => "ioanrogers",
  "ioncache\@cpan.org" => "ioncache",
  "ioncache\@gmail.com" => "ioncache",
  "isillitoe\@cpan.org" => "sillitoe",
  "italo.goncales\@gmail.com" => "italogoncales",
  "iv\@wolverian.net" => "wolverian",
  "ivan\@bessarabov.ru" => "bessarabov",
  "ivanwills\@cpan.org" => "ivanwills",
  "ivanych\@cpan.org" => "ivanych",
  "ivaturi\@gmail.com" => "aivaturi",
  "iwata\@cpan.org" => "iwata",
  "jacoby\@cpan.org" => "jacoby",
  "jacquesg\@cpan.org" => "jacquesg",
  "jahiy\@cpan.org" => "jahiy",
  "jaitken\@cpan.org" => "loonypandora",
  "jakob.voss\@gbv.de" => "nichtich",
  "james\@lovedthanlost.net" => "jamtur01",
  "jamtur\@cpan.org" => "jamtur01",
  "jandrew\@cpan.org" => "jandrew",
  "jasei\@cpan.org" => "jasei",
  "jason.a.may\@gmail.com" => "jasonmay",
  "jasonjayr+oss\@gmail.com" => "jasonjayr",
  "jasonjayr\@cpan.org" => "jasonjayr",
  "jasonmay\@cpan.org" => "jasonmay",
  "jay.hannah\@iinteractive.com" => "jhannah",
  "jayallen\@cpan.org" => "jayallen",
  "jayce\@cpan.org" => "jayceh",
  "jbarrett\@cpan.org" => "jbarrett",
  "jberger\@cpan.org" => "jberger",
  "jdennes\@cpan.org" => "jdennes",
  "jdrago_999\@yahoo.com" => "jdrago999",
  "jeff\@thaljef.org" => "thaljef",
  "jeff\@zeroclue.com" => "jlavallee",
  "jeffa\@cpan.org" => "jeffa",
  "jeremy\@ziprecruiter.com" => "jleader",
  "jesse.luehrs\@iinteractive.com" => "doy",
  "jeteve\@cpan.org" => "jeteve",
  "jfried\@cpan.org" => "krimdomu",
  "jfwilkus\@cpan.org" => "jfwilkus",
  "jgamble\@cpan.org" => "jgamble",
  "jhannah\@cpan.org" => "jhannah",
  "jhthorsen\@cpan.org" => "jhthorsen",
  "jinzang\@cpan.org" => "jinzang",
  "jipipayo\@cpan.org" => "jipipayo",
  "jiskiras\@gmail.com" => "ljepson",
  "jjnapiork\@cpan.org" => "jjn1056",
  "jkegl\@cpan.org" => "jeffreykegler",
  "jkg\@cpan.org" => "jkg",
  "jkutej\@cpan.org" => "jozef",
  "jlavallee\@cpan.org" => "jlavallee",
  "jleader\@alumni.caltech.edu" => "jleader",
  "jleader\@cpan.org" => "jleader",
  "jmates\@cpan.org" => "thrig",
  "jmates\@example.org" => "thrig",
  "jmcnamara\@cpan.org" => "jmcnamara",
  "jmcveigh\@outlook.com" => "jmcveigh",
  "jnbek\@cpan.org" => "jnbek",
  "jns\@gellyfish.co.uk" => "jonathanstowe",
  "joaocosta\@cpan.org" => "joaocosta",
  "joaocosta\@zonalivre.org" => "joaocosta",
  "joel.a.berger\@gmail.com" => "jberger",
  "joenio\@cpan.org" => "joenio",
  "joenio\@joenio.me" => "joenio",
  "joergsteinkamp\@yahoo.de" => "joergsteinkamp",
  "john\@jbrt.org" => "jbarrett",
  "johnd\@cpan.org" => "jdrago999",
  "johntrammell\@gmail.com" => "trammell",
  "jonasbn\@cpan.org" => "jonasbn",
  "jpinkham\@cpan.org" => "jpinkham",
  "jquelin\@cpan.org" => "jquelin",
  "jraspass\@gmail.com" => "jraspass",
  "jrmash\@cpan.org" => "jrmash",
  "jrobinson\@cpan.org" => "castaway",
  "jstowe\@cpan.org" => "jonathanstowe",
  "jtrammell\@cpan.org" => "trammell",
  "juerd\@cpan.org" => "juerd",
  "juster\@cpan.org" => "juster",
  "justin.d.hunter\@gmail.com" => "arcanez",
  "jwb\@cpan.org" => "jwbargsten",
  "jwieland\@cpan.org" => "jwieland",
  "kablamo\@cpan.org" => "kablamo",
  "kan.fushihara\@gmail.com" => "kan",
  "kanishka\@cpan.org" => "kanishkablack",
  "kaoru\@cpan.org" => "kaoru",
  "kaoru\@slackwise.net" => "kaoru",
  "kappa\@cpan.org" => "kappa",
  "kappa\@yandex.com" => "kappa",
  "karjala\@cpan.org" => "akarelas",
  "karl\@kornel.us" => "akkornel",
  "karman\@cpan.org" => "karpet",
  "karupa\@cpan.org" => "karupanerura",
  "kate\@cpan.org" => "katekirby",
  "kcowgill\@cpan.org" => "kcowgill",
  "kedare\@cpan.org" => "kedare",
  "kent\@c2group.net" => "kcowgill",
  "kentafly88\@gmail.com" => "kfly8",
  "kentfredric\@gmail.com" => "kentfredric",
  "kentnl\@cpan.org" => "kentfredric",
  "kesin1202000\@gmail.com" => "kesin11",
  "kesin\@cpan.org" => "kesin11",
  "keszler\@cpan.org" => "keszler",
  "keszler\@srkconsulting.com" => "keszler",
  "kfly\@cpan.org" => "kfly8",
  "khampton\@cpan.org" => "ubu",
  "khampton\@totalcinema.com" => "ubu",
  "khs\@cpan.org" => "sng2c",
  "kiel\@comcen.com.au" => "kielstr",
  "kielstr\@cpan.org" => "kielstr",
  "kio\@cpan.org" => "ki0",
  "kip.hampton\@tamarou.com" => "ubu",
  "kixx\@cpan.org" => "kixx",
  "kjetilk\@cpan.org" => "kjetilk",
  "klopp\@cpan.org" => "klopp",
  "klopp\@yandex.ru" => "klopp",
  "kmx\@cpan.org" => "kmx",
  "komarov\@cpan.org" => "komarov",
  "konobi\@cpan.org" => "konobi",
  "koorchik\@cpan.org" => "koorchik",
  "kovensky\@cpan.org" => "kovensky",
  "ksuri\@cpan.org" => "ksurent",
  "ktat\@cpan.org" => "ktat",
  "ktdreyer\@cpan.org" => "ktdreyer",
  "ktdreyer\@ktdreyer.com" => "ktdreyer",
  "kthakore\@cpan.org" => "kthakore",
  "kwilliams\@cpan.org" => "kenahoo",
  "kyle\@cpan.org" => "kyleha",
  "kyleha\@gmail.com" => "kyleha",
  "lbrocard\@cpan.org" => "acme",
  "ldidry\@cpan.org" => "ldidry",
  "lecstor\@cpan.org" => "lecstor",
  "leejo\@cpan.org" => "leejo",
  "lenjaffe\@cpan.org" => "vampirechicken",
  "lenjaffe\@lenjaffe.com" => "vampirechicken",
  "leont\@cpan.org" => "leont",
  "leprevost\@cpan.org" => "leprevost",
  "lichtkind\@cpan.org" => "lichtkind",
  "likhatski\@cpan.org" => "likhatskiy",
  "likhatskiy\@gmail.com" => "likhatskiy",
  "limitusus\@cpan.org" => "limitusus",
  "linhehuo\@gmail.com" => "zitsen",
  "lisantra\@cpan.org" => "mgatto",
  "liyanage\@cpan.org" => "liyanage",
  "ljepson\@cpan.org" => "ljepson",
  "llap\@cpan.org" => "ranguard",
  "llap\@cuckoo.org" => "ranguard",
  "logie\@cpan.org" => "logie17",
  "lomky\@cpan.org" => "lomky",
  "lorn\@cpan.org" => "lorn",
  "losyme\@cpan.org" => "losyme",
  "lrr\@cpan.org" => "lmrodriguezr",
  "ltp\@cpan.org" => "ltp",
  "lukec\@cpan.org" => "lukec",
  "lxp\@cpan.org" => "lx",
  "m\@japh.se" => "trapd00r",
  "maf\@cpan.org" => "mark-5",
  "maff\@cpan.org" => "maffsie",
  "mail\@atrox.me" => "atrox",
  "mail\@memowe.de" => "memowe",
  "mail\@robert.io" => "rpicard",
  "mail\@tobyinkster.co.uk" => "tobyink",
  "maio\@cpan.org" => "maio",
  "majensen\@cpan.org" => "majensen",
  "majlis\@cpan.org" => "martin-majlis",
  "mallen\@cpan.org" => "mrallen1",
  "mamod.mehyar\@gmail.com" => "mamod",
  "mamod\@cpan.org" => "mamod",
  "manwar\@cpan.org" => "manwar",
  "marc\@marcbradshaw.net" => "marcbradshaw",
  "marc\@questright.com" => "semifor",
  "marcc\@cpan.org" => "eiro",
  "marcussen\@cpan.org" => "wireghoul",
  "marghi\@cpan.org" => "marghidanu",
  "marian.schubert\@gmail.com" => "maio",
  "mark\@twoshortplanks.com" => "2shortplanks",
  "markellis\@cpan.org" => "markwellis",
  "markf\@cpan.org" => "2shortplanks",
  "maros\@cpan.org" => "maros",
  "martin\@majlis.cz" => "martin-majlis",
  "martin\@sluka.de" => "fany",
  "masaki.nakagawa\@gmail.com" => "masaki",
  "masaki\@cpan.org" => "masaki",
  "mateu\@cpan.org" => "mateu",
  "mathieu.poussin\@capside.com" => "kedare",
  "mathieu.poussin\@netyxia.net" => "kedare",
  "matt\@lessthan3.net" => "mattdees",
  "mattdees\@cpan.org" => "mattdees",
  "mattk\@cpan.org" => "atomicstack",
  "mattp\@cpan.org" => "mphill22",
  "mauke\@cpan.org" => "mauke",
  "maxs\@cpan.org" => "maxatome",
  "mbradshaw\@cpan.org" => "marcbradshaw",
  "mcartmell\@cpan.org" => "mcartmell",
  "mcmahon\@cpan.org" => "joemcmahon",
  "mdb\@cpan.org" => "markdbenson",
  "mdietrich\@cpan.org" => "rainboxx",
  "me+dev\@peter-r.co.uk" => "pwr22",
  "me\@berekuk.ru" => "berekuk",
  "me\@evancarroll.com" => "evancarroll",
  "me\@mark.atwood.name" => "fallenpegasus",
  "melezhik\@cpan.org" => "melezhik",
  "melezhik\@gmail.com" => "melezhik",
  "melo\@cpan.org" => "melo",
  "melo\@simplicidade.org" => "melo",
  "memowe\@cpan.org" => "memowe",
  "mephinet\@gmx.net" => "mephinet",
  "mfontani\@cpan.org" => "mfontani",
  "mgatto\@lisantra.com" => "mgatto",
  "mgould\@cpan.org" => "pozorvlak",
  "mgrimes\@cpan.org" => "mvgrimes",
  "mhcrnl\@cpan.org" => "mhcrnl",
  "mhcrnl\@gmail.com" => "mhcrnl",
  "mhoward\@cpan.org" => "merrilymeredith",
  "mi\@ya.ru" => "mishin",
  "michael\@cpan.org" => "vivtek",
  "michael\@thegrebs.com" => "mikegrb",
  "michiel.beijen\@gmail.com" => "mbeijen",
  "michielb\@cpan.org" => "mbeijen",
  "mikegrb\@cpan.org" => "mikegrb",
  "miket\@cpan.org" => "miketonks",
  "mikihoshi\@cpan.org" => "kan",
  "mikkoi\@cpan.org" => "mikkoi",
  "miles\@assyrian.org.uk" => "pozorvlak",
  "minimal\@cpan.org" => "naturalist",
  "mirko.westermeier\@uni-muenster.de" => "memowe",
  "mirko\@westermeier.de" => "memowe",
  "mirod\@cpan.org" => "mirod",
  "mishin\@cpan.org" => "mishin",
  "mithaldu\@cpan.org" => "wchristian",
  "mithun\@cpan.org" => "mithun",
  "mixas\@cpan.org" => "mr-mixas",
  "miyagawa\@bulknews.net" => "miyagawa",
  "miyagawa\@cpan.org" => "miyagawa",
  "mjemmeson\@cpan.org" => "mjemmeson",
  "mjevans\@cpan.org" => "mjegh",
  "mjg\@phoenixtrap.com" => "mjgardner",
  "mjgardner\@cpan.org" => "mjgardner",
  "mlx\@cpan.org" => "midlifexis",
  "mmcleric\@cpan.org" => "berekuk",
  "mmims\@cpan.org" => "semifor",
  "mmusgrove\@cpan.org" => "mrmuskrat",
  "module\@renee-baecker.de" => "reneeb",
  "mohammad.anwar\@yahoo.com" => "manwar",
  "moodfarm\@cpan.org" => "27escape",
  "moollaza\@cpan.org" => "moollaza",
  "moollaza\@fastmail.fm" => "moollaza",
  "moritz\@cpan.org" => "moritz",
  "moriya\@cpan.org" => "gardejo",
  "moshen\@cpan.org" => "moshen",
  "motemen\@cpan.org" => "motemen",
  "motemen\@gmail.com" => "motemen",
  "moznion\@cpan.org" => "moznion",
  "moznion\@gmail.com" => "moznion",
  "mperry\@cpan.org" => "mperry2",
  "mport\@cpan.org" => "mport",
  "mr.daniel.brook\@gmail.com" => "broquaint",
  "mra\@cpan.org" => "fallenpegasus",
  "mrallen1\@yahoo.com" => "mrallen1",
  "mramberg\@cpan.org" => "marcusramberg",
  "mrf\@cpan.org" => "ungrim97",
  "mrpants\@cpan.org" => "mrpants",
  "mruiz\@cpan.org" => "miquelruiz",
  "mschuett\@cpan.org" => "mschuett",
  "mschwern\@cpan.org" => "schwern",
  "mstemle\@cpan.org" => "manchicken",
  "mstrat\@cpan.org" => "mstratman",
  "mtw\@cpan.org" => "mtw",
  "mucker\@cpan.org" => "harsha-mudi",
  "mudler\@cpan.org" => "mudler",
  "mudler\@dark-lab.net" => "mudler",
  "mugifly\@cpan.org" => "mugifly",
  "mydimension+cpan\@gmail.com" => "mydimension",
  "mydmnsn\@cpan.org" => "mydimension",
  "mysz\@cpan.org" => "msztolcman",
  "mziescha\@cpan.org" => "mziescha",
  "nadim.khemir\@gmail.com" => "nkh",
  "nakiro\@cpan.org" => "nakiro",
  "nathan.mcfarland\@nmcfarl.org" => "nmcfarl",
  "nathanpc\@cpan.org" => "nathanpc",
  "nathanpc\@dreamintech.net" => "nathanpc",
  "navi\@cpan.org" => "naviltsev",
  "nebulous\@cpan.org" => "nebulous",
  "nebulous\@crashed.net" => "nebulous",
  "neil\@bowers.com" => "neilbowers",
  "neilb\@cpan.org" => "neilbowers",
  "nerdgrrl\@cpan.org" => "nerdgrrl",
  "nevesenin\@cpan.org" => "nevesenin",
  "nfg\@cpan.org" => "nfg",
  "nglenn\@cpan.org" => "garfieldnate",
  "ngs\@cpan.org" => "ngs",
  "nkh\@cpan.org" => "nkh",
  "nmcfarl\@cpan.org" => "nmcfarl",
  "nmelnick\@cpan.org" => "nmelnick",
  "nnutter\@cpan.org" => "nnutter",
  "norbert.truchsess\@t-online.de" => "ntruchsess",
  "norbu\@cpan.org" => "norbu09",
  "notbenh\@cpan.org" => "notbenh",
  "nrr\@corvidae.org" => "nrr",
  "nrr\@cpan.org" => "nrr",
  "ntruchses\@cpan.org" => "ntruchsess",
  "nukosuke\@cpan.org" => "nukosuke",
  "nwellnhof\@cpan.org" => "nwellnhof",
  "nx2zdk\@gmail.com" => "zdk",
  "oalders\@cpan.org" => "oalders",
  "odc\@cpan.org" => "oliwer",
  "odyniec\@cpan.org" => "odyniec",
  "olaf\@wundercounter.com" => "oalders",
  "olaf\@wundersolutions.com" => "oalders",
  "oleg\@cpan.org" => "olegwtf",
  "oliver\@cpan.org" => "ollyg",
  "olof\@cpan.org" => "olof",
  "omega\@palle.net" => "omega",
  "oneonetwo\@cpan.org" => "oneandoneis2",
  "onken\@netcubed.de" => "monken",
  "onlyjob\@cpan.org" => "onlyjob",
  "orange\@cpan.org" => "bollwarm",
  "oschwald\@cpan.org" => "oschwald",
  "oschwald\@gmail.com" => "oschwald",
  "ovid\@cpan.org" => "ovid",
  "ovn.tatar\@gmail.com" => "ovntatar",
  "ovntatar\@cpan.org" => "ovntatar",
  "pablo.rodriguez.gonzalez\@gmail.com" => "pablrod",
  "pablrod\@cpan.org" => "pablrod",
  "pacman\@cpan.org" => "peczenyj",
  "pacoeb\@cpan.org" => "pacoesteban",
  "pagaltzis\@gmx.de" => "ap",
  "patch\@cpan.org" => "patch",
  "pattawan\@cpan.org" => "oiami",
  "paul\@pjcj.net" => "pjcj",
  "pause\@sjor.sg" => "sgielen",
  "pavelsr\@cpan.org" => "pavelsr",
  "pblair\@cpan.org" => "petermblair",
  "pcm\@cpan.org" => "petermartini",
  "pdcawley\@bofh.org.uk" => "pdcawley",
  "pdcawley\@cpan.org" => "pdcawley",
  "pdonelan\@cpan.org" => "pdonelan",
  "pdurden\@cpan.org" => "alabamapaul",
  "peco\@cpan.org" => "xpeco",
  "pek\@cpan.org" => "petrkle",
  "pekingsam\@cpan.org" => "yanxueqing621",
  "pepl\@cpan.org" => "pepl",
  "perigrin\@cpan.org" => "perigrin",
  "perl\@0ne.us" => "apocalypse",
  "perl\@aaroncrane.co.uk" => "arc",
  "perl\@cjmweb.net" => "madsen",
  "perl\@peknet.com" => "karpet",
  "perl\@rainboxx.de" => "rainboxx",
  "perler\@cpan.org" => "monken",
  "perlish\@cpan.org" => "perlish",
  "petdance\@cpan.org" => "petdance",
  "pete\@clueball.com" => "sheriff",
  "peter\@makholm.net" => "pmakholm",
  "petercj\@cpan.org" => "pryrt",
  "pgraemer\@cpan.org" => "pgraemer",
  "phaylon\@cpan.org" => "phaylon",
  "philip\@cpan.org" => "kingpong",
  "philipp.gortan\@apa.at" => "mephinet",
  "phipster\@cpan.org" => "lifeofguenter",
  "phred\@cpan.org" => "redhotpenguin",
  "pine\@cpan.org" => "pine",
  "pinemz\@gmail.com" => "pine",
  "piotr.roszatycki\@gmail.com" => "dex4er",
  "pityonline\@gmail.com" => "pityonline",
  "pjcj\@cpan.org" => "pjcj",
  "pjf\@cpan.org" => "pjf",
  "pjf\@perltraining.com.au" => "pjf",
  "pjfl\@cpan.org" => "pjfl",
  "plicease\@cpan.org" => "plicease",
  "plu\@cpan.org" => "plu",
  "plu\@pqpq.de" => "plu",
  "pmakholm\@cpan.org" => "pmakholm",
  "podonnell\@cpan.org" => "phillipod",
  "polettix\@cpan.org" => "polettix",
  "potatogim\@cpan.org" => "potatogim",
  "potatogim\@potatogim.net" => "potatogim",
  "powerman\@cpan.org" => "powerman",
  "pragmatic\@cpan.org" => "pragmatic",
  "prairie\@cpan.org" => "prairienyx",
  "preaction\@cpan.org" => "preaction",
  "ps\@phillipadsmith.com" => "phillipadsmith",
  "pshajdo\@gmail.com" => "trinitum",
  "psmith\@cpan.org" => "phillipadsmith",
  "ptop\@cpan.org" => "pityonline",
  "pushtaev.vm\@gmail.com" => "vadimpushtaev",
  "pushtaev\@cpan.org" => "vadimpushtaev",
  "pwes\@cpan.org" => "jest",
  "pwr\@cpan.org" => "pwr22",
  "q\@cono.org.ua" => "cono",
  "rafl\@debian.org" => "rafl",
  "rafl\@perldition.org" => "rafl",
  "rakesh.shardiwal\@gmail.com" => "shardiwal",
  "ralesk\@cpan.org" => "ralesk",
  "raz\@cpan.org" => "jraspass",
  "rbo\@cpan.org" => "rbo",
  "rbragg\@cpan.org" => "rbragg",
  "rcaputo\@cpan.org" => "rcaputo",
  "rct+cpan\@thompsonclan.org" => "darwinawardwinner",
  "redicaps\@cpan.org" => "woosley",
  "redicaps\@gmail.com" => "woosley",
  "reg.metacpan\@entropy.ch" => "liyanage",
  "reini.urban\@gmail.com" => "rurban",
  "reisinge\@cpan.org" => "jreisinger",
  "reneeb\@cpan.org" => "reneeb",
  "revmischa\@cpan.org" => "revmischa",
  "rgarcia\@cpan.org" => "rgs",
  "rgs\@consttype.org" => "rgs",
  "rhaen\@cpan.org" => "rhaen",
  "rhoelz\@cpan.org" => "hoelzro",
  "ribasushi\@cpan.org" => "ribasushi",
  "riche\@cpan.org" => "rpcme",
  "ritou.06\@gmail.com" => "ritou",
  "ritou\@cpan.org" => "ritou",
  "rjbs\@cpan.org" => "rjbs",
  "rjray\@blackperl.com" => "rjray",
  "rjray\@cpan.org" => "rjray",
  "rkinyon\@cpan.org" => "robkinyon",
  "rkitover\@cpan.org" => "rkitover",
  "rkitover\@prismnet.com" => "rkitover",
  "rlopes\@cpan.org" => "rafaelol",
  "rns\@cpan.org" => "rns",
  "rob+cpan\@hoelz.ro" => "hoelzro",
  "rob.kinyon\@gmail.com" => "robkinyon",
  "robin\@smidsrod.no" => "robinsmidsrod",
  "robins\@cpan.org" => "robinsmidsrod",
  "robn\@cpan.org" => "robn",
  "robn\@robn.io" => "robn",
  "rock\@ccls-online.de" => "giftnuss",
  "rocky\@cpan.org" => "rocky",
  "rokenrol\@gmail.com" => "gatlin",
  "romanf\@cpan.org" => "moltar",
  "roryrjb\@cpan.org" => "roryrjb",
  "rpicard\@cpan.org" => "rpicard",
  "rra\@cpan.org" => "rra",
  "rsimoes\@cpan.org" => "rsimoes",
  "rsrchboy\@cpan.org" => "rsrchboy",
  "rthompson\@cpan.org" => "darwinawardwinner",
  "rtkh\@cpan.org" => "khrt",
  "rurban\@cpan.org" => "rurban",
  "ruslan.zakirov\@gmail.com" => "ruz",
  "ruz\@bestpractical.com" => "ruz",
  "ruz\@cpan.org" => "ruz",
  "rwstauner\@cpan.org" => "rwstauner",
  "s.denaxas\@gmail.com" => "spiros",
  "salva\@cpan.org" => "salva",
  "sam\@maltera.com" => "elemecca",
  "samuelhoffman2\@gmail.com" => "minicruzer",
  "samyotte\@phirelight.com" => "unusedphd",
  "sanbeg\@cpan.org" => "sanbeg",
  "sanko\@cpan.org" => "sanko",
  "saper\@cpan.org" => "maddingue",
  "sargie\@cpan.org" => "sheriff",
  "sartak\@cpan.org" => "sartak",
  "satoh\@cpan.org" => "cho45",
  "schwigon\@cpan.org" => "renormalist",
  "sden\@cpan.org" => "spiros",
  "sdt\@cpan.org" => "sdt",
  "seb\@geidi.es" => "geidies",
  "sebbe\@cpan.org" => "eckankar",
  "sekia\@cpan.org" => "sekia",
  "sekimura\@cpan.org" => "sekimura",
  "sekimura\@gmail.com" => "sekimura",
  "sfandino\@yahoo.com" => "salva",
  "shantanu.bhadoria\@gmail.com" => "shantanubhadoria",
  "shantanu\@cpan.org" => "shantanubhadoria",
  "shardiwal\@cpan.org" => "shardiwal",
  "sharifulin\@gmail.com" => "sharifulin",
  "sharifuln\@cpan.org" => "sharifulin",
  "sharyanto\@cpan.org" => "sharyanto",
  "shaw\@cpan.org" => "sshaw",
  "shay\@cpan.org" => "steve-m-hay",
  "sherwin\@cpan.org" => "sherwind",
  "sherwin\@daganato.com" => "sherwind",
  "sherwind\@gmail.com" => "sherwind",
  "shigeta\@cpan.org" => "comewalk",
  "shlomif\@cpan.org" => "shlomif",
  "shlomif\@shlomifish.org" => "shlomif",
  "shoorick\@cpan.org" => "shoorick",
  "shootnix\@cpan.org" => "shootnix",
  "shootnix\@gmail.com" => "shootnix",
  "shuff\@cpan.org" => "hakamadare",
  "simonw\@cpan.org" => "simonwistow",
  "sjhoffman\@cpan.org" => "minicruzer",
  "sjn\@cpan.org" => "sjn",
  "sjohnston\@cpan.org" => "sjohnston",
  "skaji\@cpan.org" => "skaji",
  "skim\@cpan.org" => "tupinek",
  "sknpp\@cpan.org" => "giftnuss",
  "skreuzer\@cpan.org" => "skreuzer",
  "skunix\@cpan.org" => "chandwer",
  "sky\@riseup.net" => "skysymbol",
  "skysymbol\@cpan.org" => "skysymbol",
  "slaven\@rezic.de" => "eserte",
  "sleung\@cpan.org" => "stvleung",
  "slobo\@cpan.org" => "slobo",
  "slobodan\@miskovic.ca" => "slobo",
  "slu\@cpan.org" => "soren",
  "smonf\@cpan.org" => "smonff",
  "smonff\@riseup.net" => "smonff",
  "snelius\@cpan.org" => "snelius30",
  "sng2nara\@gmail.com" => "sng2c",
  "soft-cpan\@temporalanomaly.com" => "beanz",
  "songmu\@cpan.org" => "songmu",
  "spacebat\@cpan.org" => "spacebat",
  "squeek\@cpan.org" => "squeeks",
  "srezic\@cpan.org" => "eserte",
  "sri\@cpan.org" => "kraih",
  "srynobio\@cpan.org" => "srynobio",
  "sscaffidi\@cpan.org" => "hercynium",
  "stas\@sysd.org" => "creaktive",
  "stefans\@cpan.org" => "stefansbv",
  "steinkamp\@cpan.org" => "joergsteinkamp",
  "stephanj\@cpan.org" => "stephan48",
  "stephen\@cpan.org" => "stephenenelson",
  "stephenenelson\@mac.com" => "stephenenelson",
  "stevan\@cpan.org" => "stevan",
  "stevenl\@cpan.org" => "stevenl",
  "stevenwh.lee\@gmail.com" => "stevenl",
  "sthebert\@cpan.org" => "sebthebert",
  "stratman\@gmail.com" => "mstratman",
  "struan\@cpan.org" => "struan",
  "stt\@onetool.pm" => "sebthebert",
  "stuifzand\@cpan.org" => "pstuifzand",
  "sungo\@cpan.org" => "sungo",
  "sungo\@sungo.us" => "sungo",
  "sunnyp\@cpan.org" => "sunnypatel4141",
  "sunnypatel4141\@gmail.com" => "sunnypatel4141",
  "sutt\@cpan.org" => "shaneutt",
  "swuecho\@cpan.org" => "swuecho",
  "symkat\@cpan.org" => "symkat",
  "syohex\@cpan.org" => "syohex",
  "syp\@cpan.org" => "creaktive",
  "syxanash\@cpan.org" => "syxanash",
  "szabgab\@cpan.org" => "szabgab",
  "szabgab\@gmail.com" => "szabgab",
  "szbalint\@cpan.org" => "szbalint",
  "t.akiym\@gmail.com" => "akiym",
  "tadam\@cpan.org" => "tadam",
  "tapper\@cpan.org" => "tapper",
  "taryk\@cpan.org" => "taryk",
  "team\@cpan.org" => "team-at-cpan",
  "techman\@cpan.org" => "techman83",
  "teejay\@cpan.org" => "hashbangperl",
  "tex\@cpan.org" => "gittex",
  "thaljef\@cpan.org" => "thaljef",
  "thecrux\@gmail.com" => "vlet",
  "themanchicken\@gmail.com" => "manchicken",
  "thilp\@cpan.org" => "thilp",
  "tim.bunce\@pobox.com" => "timbunce",
  "timb\@cpan.org" => "timbunce",
  "tinita\@cpan.org" => "perlpunk",
  "tmueller\@cpan.org" => "tmueller",
  "tmurray\@cpan.org" => "frezik",
  "tmurray\@wumpus-cave.net" => "frezik",
  "tobybro\@cpan.org" => "tobybro",
  "tobyink\@cpan.org" => "tobyink",
  "todd\@rinaldo.us" => "toddr",
  "toddr\@cpan.org" => "toddr",
  "tokarev\@cpan.org" => "nohuhu",
  "tokuhirom+cpan\@gmail.com" => "tokuhirom",
  "tokuhirom\@cpan.org" => "tokuhirom",
  "tomfahle\@cpan.org" => "tomfahle",
  "tomhukins\@cpan.org" => "tomhukins",
  "tomita\@cpan.org" => "tomill",
  "tony\@develop-help.com" => "tonycoz",
  "tonyc\@cpan.org" => "tonycoz",
  "torsten\@raudss.us" => "getty",
  "toru\@cpan.org" => "torus",
  "toru\@torus.jp" => "torus",
  "toshioito\@cpan.org" => "debug-ito",
  "trcjr\@cpan.org" => "trcjr",
  "trizen\@cpan.org" => "trizen",
  "trizenx\@gmail.com" => "trizen",
  "tsibley\@cpan.org" => "tsibley",
  "tudor\@marghidanu.com" => "marghidanu",
  "tynovsky\@cpan.org" => "tynovsky",
  "typester\@cpan.org" => "typester",
  "typester\@gmail.com" => "typester",
  "ubermonk\@gmail.com" => "spacebat",
  "ugexe\@cpan.org" => "ugexe",
  "uksza\@cpan.org" => "uksza",
  "uksza\@uksza.net" => "uksza",
  "undef\@cpan.org" => "und3f",
  "ungrim97\@gmail.com" => "ungrim97",
  "ungrim97\@hotmail.com" => "ungrim97",
  "unusedphd\@cpan.org" => "unusedphd",
  "vanstyn\@cpan.org" => "vanstyn",
  "veinian\@163.com" => "vinian",
  "ver\@0xff.su" => "github.com/verolom",
  "verolom\@cpan.org" => "github.com/verolom",
  "viliam.pucik\@gmail.com" => "viliampucik",
  "vinian\@cpan.org" => "vinian",
  "vlyon\@cpan.org" => "vlyon",
  "voegelas\@cpan.org" => "voegelas",
  "voj\@cpan.org" => "nichtich",
  "vovkasm\@cpan.org" => "vovkasm",
  "vovkasm\@gmail.com" => "vovkasm",
  "vroom\@blockstackers.com" => "tvroom",
  "vroom\@cpan.org" => "tvroom",
  "vs\@vs-dev.com" => "vsespb",
  "vsespb\@cpan.org" => "vsespb",
  "vtfrvl\@cpan.org" => "vtfrvl",
  "vti\@cpan.org" => "vti",
  "walde.christian\@gmail.com" => "wchristian",
  "walde.christian\@googlemail.com" => "wchristian",
  "wallace\@reis.me" => "wreis",
  "wanleung\@cpan.org" => "wanleung",
  "wanleung\@linkomnia.com" => "wanleung",
  "warthurt\@cpan.org" => "warthurton",
  "warthurton\@warthurton.com" => "warthurton",
  "wellnhofer\@aevum.de" => "nwellnhof",
  "wesm\@cpan.org" => "wesq3",
  "wftk\@vivtek.com" => "vivtek",
  "whosgonna\@cpan.org" => "whosgonna",
  "will\@worrbase.com" => "worr",
  "william\@tuffbizz.com" => "woodruffw",
  "winter\@cpan.org" => "iarna",
  "wki\@cpan.org" => "wki",
  "woldrich\@cpan.org" => "trapd00r",
  "wolfgang\@kinkeldei.de" => "wki",
  "wolfsage\@cpan.org" => "wolfsage",
  "wolfsage\@gmail.com" => "wolfsage",
  "wollmers\@cpan.org" => "wollmers",
  "wolverian\@cpan.org" => "wolverian",
  "wonko\@cpan.org" => "mpeters",
  "woodruffw\@cpan.org" => "woodruffw",
  "worr\@cpan.org" => "worr",
  "wreis\@cpan.org" => "wreis",
  "wsdookadr\@cpan.org" => "wsdookadr",
  "x.guimard\@free.fr" => "guimard",
  "xaerxess\@cpan.org" => "xaerxess",
  "xaerxess\@gmail.com" => "xaerxess",
  "xaicron\@cpan.org" => "xaicron",
  "xaoc\@cpan.org" => "cpanxaoc",
  "xeno\@cpan.org" => "xenoterracide",
  "xenoterracide\@gmail.com" => "xenoterracide",
  "xiaodong\@cpan.org" => "xuxiaodong",
  "xlat\@cpan.org" => "xlat",
  "xmltwig\@gmail.com" => "mirod",
  "xsawyerx\@cpan.org" => "xsawyerx",
  "xxdlhy\@gmail.com" => "xuxiaodong",
  "y.songmu\@gmail.com" => "songmu",
  "yakex\@cpan.org" => "yak1ex",
  "yanick+cpan\@babyl.dyndns.org" => "yanick",
  "yanick\@cpan.org" => "yanick",
  "yanother\@cpan.org" => "maki-daisuke",
  "yanxueqing10\@163.com" => "yanxueqing621",
  "yko\@cpan.org" => "yko",
  "ysasaki\@cpan.org" => "ysasaki",
  "ysyrota\@cpan.org" => "ysyrota",
  "yury.zavarin\@gmail.com" => "tadam",
  "yuuki\@cpan.org" => "y-uuki",
  "zakame\@cpan.org" => "zakame",
  "zdk\@cpan.org" => "zdk",
  "zdm\@cpan.org" => "zdm",
  "zenbae\@cpan.org" => "jmcveigh",
  "zero\@cpan.org" => "alistratov",
  "ziguzagu\@cpan.org" => "ziguzagu",
  "zithb\@cpan.org" => "zit-hb",
  "zitsen\@cpan.org" => "zitsen",
  "zmughal\@cpan.org" => "zmughal",
  "zoffix\@cpan.org" => "zoffixznet",
  "zoncoen\@cpan.org" => "zoncoen",
  "zpmorgan\@cpan.org" => "zpmorgan",
  "zwon\@cpan.org" => "trinitum",
  "zzz\@cpan.org" => "zzzcpan"
}
