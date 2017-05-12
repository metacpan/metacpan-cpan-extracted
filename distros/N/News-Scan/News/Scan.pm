package News::Scan;

use 5.004;

use strict;
use vars qw( $VERSION $AUTOLOAD );

use Carp;
use IO::File;
use IO::Seekable;  ## get the seek constants
use Mail::Address;

use News::Scan::Article;
use News::Scan::Poster;
use News::Scan::Thread;

$VERSION = '0.53';

## play a fun little game here
my $Have_Net_NNTP = 0;
if (eval { require Net::NNTP }) {
    Net::NNTP->import;

    $Have_Net_NNTP++;
}

## methods defined for our instances
my %Permitted = (
    name     => undef,
    spool    => undef,
    period   => undef,
    aliases  => undef,

    nntp_server      => undef,
    nntp_auth_login  => undef,
    nntp_auth_passwd => undef,
    nntp_client      => undef,

    articles => undef,
    volume   => undef,

    header_volume => undef,
    header_lines  => undef,

    body_volume => undef,
    body_lines  => undef,

    orig_volume => undef,
    orig_lines  => undef,

    sig_volume => undef,
    sig_lines  => undef,
    signatures => undef,
);

sub new {
    my $class = shift;
    my $self = {
        news_scan_posters  => {},
        news_scan_xposts   => {},
        news_scan_threads  => {},
        news_scan_earliest => $^T,
        news_scan_latest   => 0,
        news_scan_excludes => [],
        news_scan_aliases  => {},
    };

    bless $self, $class;

    if (@_) {
        $self->configure(@_);

        if ($self->error) {
            return $self;
        }
    }

    $self->init;

    $self;
}

sub AUTOLOAD {
    my $self  = $_[0];
    my $class = ref $self || croak "`$self' is not an object";
    my $name  = $AUTOLOAD;

    $name =~ s/^.*:://;

    unless (exists $Permitted{$name}) {
        croak "Can't access `$name' field in class `$class'";
    }

    eval <<EOSub;
sub $name {
    my \$self = shift;

    \$self->error(0);

    if (\@_) {
        my \$old = \$self->{'news_scan_$name'};

        \$self->{'news_scan_$name'} = shift;

        return \$old;
    }
    else {
        return \$self->{'news_scan_$name'};
    }
}
EOSub

    goto &$name;
}

sub configure {
    my $self = shift;
    my %arg  = @_;

    $self->error(0);

    if (exists $arg{From}) {
        $self->from(delete $arg{From});
        return undef if $self->error;
    }
        
    if (exists $arg{Group}) {
        $self->name(delete $arg{Group});
    }

    if (exists $arg{Spool}) {
        $self->spool(delete $arg{Spool});
    }

    if (exists $arg{NNTPServer}) {
        $self->nntp_server(delete $arg{NNTPServer});
    }

    if (exists $arg{NNTPAuthLogin}) {
        $self->nntp_auth_login(delete $arg{NNTPAuthLogin});
    }

    if (exists $arg{NNTPAuthPasswd}) {
        $self->nntp_auth_passwd(delete $arg{NNTPAuthPasswd});
    }

    if (exists $arg{Period}) {
        $self->period(delete $arg{Period});
    }
    else {
        $self->period(7);
    }

    if (exists $arg{QuoteRE}) {
        $self->quote_re(delete $arg{QuoteRE});
        return undef if $self->error;
    }
    else {
        $self->quote_re('^\s{0,3}(?:>|:|\S+>|\+\+)');
    }

    if (exists $arg{Exclude}) {
        $self->exclude(delete $arg{Exclude});
        return undef if $self->error;
    }

    if (exists $arg{Aliases}) {
        $self->aliases(delete $arg{Aliases});
    }

    1;
}

sub init {
    my $self = shift;

    $self->error(0);

    $self->articles(0);
    $self->volume(0);

    $self->header_volume(0);
    $self->header_lines(0);

    $self->body_volume(0);
    $self->body_lines(0);

    $self->orig_volume(0);
    $self->orig_lines(0);

    $self->sig_volume(0);
    $self->sig_lines(0);
    $self->signatures(0);
}

sub earliest {
    my $self = shift;

    if (@_) {
        my $try = shift;

        if ($try < $self->{'news_scan_earliest'}) {
            $self->{'news_scan_earliest'} = $try;

            return 1;  ## indicate success
        }
        else {
            return 0;
        }
    }
    else {
        return $self->{'news_scan_earliest'};
    }
}

sub latest {
    my $self = shift;

    if (@_) {
        my $try = shift;

        if ($try > $self->{'news_scan_latest'}) {
            $self->{'news_scan_latest'} = $try;

            return 1;  ## indicate success
        }
        else {
            return 0;
        }
    }
    else {
        return $self->{'news_scan_latest'};
    }
}

sub from {
    my $self = shift;

    $self->error(0);

    if (@_) {
        my $old = $self->{'news_scan_from'};
        my $from = shift;

        if (lc($from) eq 'spool') {
            $self->{'news_scan_from'} = 'spool';
        }
        elsif (lc($from) eq 'nntp') {
            unless ($Have_Net_NNTP) {
                croak <<EORant;
You have requested to retrieve articles via NNTP, but you do not have
the Net::NNTP module installed (at least where perl can find it).  If
you do not have Net::NNTP, get thee immediately to the CPAN (point your
favorite web browser at http://www.perl.com/CPAN/).
EORant
            }

            $self->{'news_scan_from'} = 'nntp';
        }
        else {
            return $self->error("Invalid news source: `$from'");
        }

        return $old;
    }
    else {
        return $self->{'news_scan_from'};
    }
}

sub quote_re {
    my $self = shift;

    if (@_) {
        my $old = $self->{'news_scan_quote_re'};

        my $new = shift;
        unless (eval {
            local $SIG{'__DIE__'};
            local $_ = '';
            /$new/, 1
        }) {
            $@ =~ s/^(.*) at.*$/$1/s;
            return $self->error($@);
        }

        $self->error(0);
        $self->{'news_scan_quote_re'} = $new;

        return $old;
    }
    else {
        return $self->{'news_scan_quote_re'};
    }
}

sub exclude {
    my $self = shift;
    my $pariahs = shift;

    unless (defined $pariahs and ref $pariahs) {
        return $self->error("exclude takes a reference to an array");
    }

    $self->{'news_scan_excludes'} = $pariahs;

    my $matcher = 'local $_ = shift;';
    $matcher .= 'study;' if @$pariahs >= 5;

    local $_;
    for (@$pariahs) {
        unless (eval { local $SIG{'__DIE__'}; /$_/i, 1 }) {
            $@ =~ s/^(.*) at.*$/$1/s;
            return $self->error("Bad pattern: $@\n");
        }

        $matcher .= "return 1 if /$_/i;";
    }
    $matcher .= 'return 0;';

    $self->{'news_scan_excluded_sub'} = eval "sub { $matcher }";
    return $self->error("Failed to generate exclusion: $@") if $@;

    $self->error(0);
}

sub excludes { \@{ $_[0]->{'news_scan_excludes'} } }

sub excluded {
    my $self = shift;
    my $addr = shift;  ## Mail::Address (or descendant) object

    $self->error(0);

    ## exclude empty addresses
    return 1 unless (defined $addr and ref $addr);

    my $decision = $self->{'news_scan_excluded_sub'};
    unless (defined $decision and ref $decision) {
        return 0;
    }

    $decision->($addr->address);
}

sub nntp_connect {
    my $self = shift;

    $self->error(0);

    return if defined $self->nntp_client;

    my $client;
    my $nntp_host = '';
    my $nntp_port = '';
    my $server = $self->nntp_server || '';

    if ($server) {
        ($nntp_host, $nntp_port) = split /:/, $server;
    }

    my @args = ();
    push @args, $nntp_host           if $nntp_host;
    push @args, (Port => $nntp_port) if $nntp_port;

    $client = Net::NNTP->new(@args);

    unless (defined $client) {
        return $self->error("Failed to create Net::NNTP object");
    }

    my $login  = $self->nntp_auth_login  || '';
    my $passwd = $self->nntp_auth_passwd || '';
    if ($login and $passwd) {
        unless ($client->authinfo($login, $passwd)) {
            return $self->error("Authinfo failed");
        }
    }

    $self->nntp_client($client);

    1;
}

sub _next_nntp_article {
    my $self = shift;
    my $client;

    $client = $self->nntp_client;
    unless (defined $client) {
        unless ($self->nntp_connect) {
            return $self->error("Failed to establish NNTP connection: "
                                . $self->error);
        }

        $client = $self->nntp_client;

        unless ($client->group($self->name)) {
            return $self->error("Invalid group name: `" . $self->name . "'");
        }

        $self->{'news_scan_article_list'} = $client->listgroup;
    }

    $self->error(0);

    # retry if we need to skip cancelled articles
    while (@{$self->{'news_scan_article_list'}}) {
        my $article = shift @{$self->{'news_scan_article_list'}};

        my $fh = IO::File->new_tmpfile;
        unless (defined $fh) {
            return $self->error("Could not open temporary file: $!\n");
        }

        my $lines = $client->article($article);
        next unless ref $lines;

        print $fh @$lines;

        $fh->seek(0, SEEK_SET);

        return $fh;
    }
}

sub _next_spool_article {
    my $self = shift;
    my $spool = $self->spool;

    unless (defined $self->{'news_scan_article_list'}) {
        unless (defined $spool) {
            return $self->error("News spool directory unknown");
        }

        unless (opendir DIR, $spool) {
            return $self->error("Failed opendir $spool: $!");
        }

        $self->{'news_scan_article_list'}
            = [ grep { -f "$spool/$_" && -s _ } readdir DIR ];
    }

    $self->error(0);

    my $article = shift @{ $self->{'news_scan_article_list'} };
    return undef unless defined $article;

    my $fh = new IO::File "< $spool/$article";
    unless (defined $fh) {
        return $self->error("Failed open $spool/$article: $!");
    }

    $fh;
}

sub next_article {
    my $self = shift;
    my $how  = $self->from;

    unless (defined $how) {
        return $self->error("No news retrieval method specified!");
    }

    $self->error(0);

    if ($how eq 'nntp') {
        return $self->_next_nntp_article;
    }
    elsif ($how eq 'spool') {
        return $self->_next_spool_article;
    }
    else {
        return $self->error("Unknown news source `$how'");
    }
}

sub scan {
    my $self = shift;
    my $from;
    my $fh;
    my $article;

    unless (defined $self->name) {
        return $self->error("$self has no idea what its name is");
    }

    while ($fh = $self->next_article) {
        $article = News::Scan::Article->new($fh, Modify => 0, $self);

        if (defined $article and not $self->excluded($article->author)) {
            $self->add_article($article);
        }
    }

    if ($self->error) {
        return undef;
    }

    $self->error(0);

    1;
}

sub collect {
    my $self = shift;

    my $group;
    my $spool;

    $group = $self->name;
    unless (defined $group) {
        return $self->error("$self has no idea what group it is");
    }

    $spool = $self->spool;
    unless (defined $spool) {
        return $self->error("$self does not know where its spool is");
    }

    unless (-d $spool and -w _) {
        return $self->error("`$spool' not a directory or writable");
    }

    unless ($self->nntp_connect) {
        return $self->error("Failed to create Net::NNTP object: "
                            . $self->error);
    }
    
    my $client = $self->nntp_client;

    unless ($client->group($group)) {
        return $self->error("Invalid group name: `$group'");
    }

    local $_;

    my %seen;
    if (open SEEN, "$spool/.seen") {
        while (<SEEN>) {
            chomp;

            $seen{$_} = 1;
        }

        close SEEN;
    }

    for (grep { !-f "$spool/$_" && !$seen{$_} } @{ $client->listgroup }) {
        my $art = $client->article($_);
        unless ($art) {
            my $msg = $client->message;

            warn "$0: $group:$_: $msg\n";

            next;
        }

        unless (open ART, ">$spool/$_") {
            return $self->error("Failed to save article");
        }

        print ART @$art;
        close ART;
    }

    $self->error(0);

    1;
}

sub error {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_error'} = shift;

        return undef;
    }
    else {
        return $self->{'news_scan_error'};
    }
}

sub add_article {
    my $self    = shift;
    my $article = shift;

    return unless (defined $article and ref $article);

    $self->articles($self->articles + 1);
    $self->volume($self->volume + $article->size);

    $self->header_volume($self->header_volume + $article->header_size);
    $self->header_lines($self->header_lines + $article->header_lines);

    $self->body_volume($self->body_volume + $article->body_size);
    $self->body_lines($self->body_lines + $article->body_lines);

    $self->orig_volume($self->orig_volume + $article->orig_size);
    $self->orig_lines($self->orig_lines + $article->orig_lines);

    if (my $sig_size = $article->sig_size) {
        $self->signatures($self->signatures + 1);
        $self->sig_volume($self->sig_volume + $sig_size);
        $self->sig_lines($self->sig_lines + $article->sig_lines);
    }

    $self->add_poster($article);
    $self->add_crossposts($article);
    $self->add_to_thread($article);

    $self->error(0);
}

## poster bookkeeping stuff
sub add_poster {
    my $self = shift;
    my $art = shift;

    $self->error(0);

    my $posters = $self->{'news_scan_posters'};
    my $poster;

    if (exists $posters->{lc $art->author->address}) {
        $poster = $posters->{lc $art->author->address};
    }
    else {
        $posters->{lc $art->author->address} = new News::Scan::Poster $art;
        return;
    }

    $poster->message_ids($art->message_id);
    $poster->volume($poster->volume + $art->size);
    $poster->articles($poster->articles + 1);
    $poster->posted_to($art);

    $poster->header_volume($poster->header_volume + $art->header_size);
    $poster->header_lines($poster->header_lines + $art->header_lines);

    $poster->body_volume($poster->body_volume + $art->body_size);
    $poster->body_lines($poster->body_lines + $art->body_lines);

    $poster->orig_volume($poster->orig_volume + $art->orig_size);
    $poster->orig_lines($poster->orig_lines + $art->orig_lines);

    $poster->sig_volume($poster->sig_volume + $art->sig_size);
    $poster->sig_lines($poster->sig_lines + $art->sig_lines);
}

sub posters {
    my %posters = %{ $_[0]->{'news_scan_posters'} };

    \%posters;
}

## crossposts bookkeeping stuff
sub add_crossposts {
    my $self = shift;
    my $art  = shift;

    my %uniq;
    local $_;
    for ($art->newsgroups) {
        $uniq{lc $_}++;
    }
    delete $uniq{lc $self->name};

    for (keys %uniq) {
        $self->{'news_scan_xposts'}{$_}++;
    }

    $self->error(0);
}

sub crossposts {
    my %xposts = %{ $_[0]->{'news_scan_xposts'} };

    \%xposts;
}

## thread bookkeeping stuff
sub add_to_thread {
    my $self = shift;
    my $art  = shift;

    my $threads = $self->{'news_scan_threads'};
    my $thread;

    $self->error(0);

    ## find the subject
    my $subj = $art->subject;
    $subj =~ s/
        ^Re           ## leading Re
        (?:\[.*?\])?  ## possible nonstandard crap
        :\s*          ## trailing : and optional whitespace
    //ix;

    if (exists $threads->{$subj}) {
        $thread = $threads->{$subj};
    }
    else {
        $threads->{$subj} = new News::Scan::Thread $art, $subj;

        return;
    }

    $thread->volume($thread->volume + $art->size);
    $thread->articles($thread->articles + 1);

    $thread->header_volume($thread->header_volume + $art->header_size);
    $thread->header_lines($thread->header_lines + $art->header_lines);

    $thread->body_volume($thread->body_volume + $art->body_size);
    $thread->body_lines($thread->body_lines + $art->body_lines);

    $thread->orig_volume($thread->orig_volume + $art->orig_size);
    $thread->orig_lines($thread->orig_lines + $art->orig_lines);

    $thread->sig_volume($thread->sig_volume + $art->sig_size);
    $thread->sig_lines($thread->sig_lines + $art->sig_lines);
}

sub threads {
    my %threads = %{ $_[0]->{'news_scan_threads'} };

    \%threads;
}

sub DESTROY {}

1;

__END__

=head1 NAME

News::Scan - gather and report Usenet newsgroup statistics

=head1 SYNOPSIS

    use News::Scan;

    my $scan = News::Scan->new;

=head1 DESCRIPTION

This module provides a class whose objects can be used to gather and
report Usenet newsgroup statistics.

=head1 CONSTRUCTOR

=item new ( [ OPTIONS ] )

C<OPTIONS> is a list of named parameters (i.e. given in key-value pairs).
Valid options are

=over 4

=item B<Group>

The value of this option is the name of the newsgroup you wish to scan.

=item B<From>

The value of this option should be either C<'spool'> or C<'NNTP'> (case is
not significant).  Any other value will produce an error (see the C<error>
method description below).  A value of C<'spool'> indicates that you would
like to
scan articles in a spool (see the B<Spool> option below).  A value of
C<'NNTP'> indicates that articles should be retrieved from your NNTP
server (see the B<NNTPServer> option below).

=item B<Spool>

The value of this option should be the path to the spool directory that
contains the articles you would like to scan.  This option is ignored
unless the value of B<From> is C<'spool'>.

=item B<NNTPServer>

The value of this option (in the form I<server>:I<port>, with both being
optional--see L<Net::NNTP> for the semantics of omitting one or both of
these parameters) indicates the NNTP server from which to retrieve
articles.  This option is ignored unless B<From> is C<'NNTP'>.  See the
description of the B<NNTPAuthLogin> and B<NNTPAuthPasswd> options below.

=item B<NNTPAuthLogin>

The value of this option should be a valid NNTP authentication login for
your NNTP server.  This option is only necessary if your NNTP server
requires authentication.

=item B<NNTPAuthPasswd>

The value of this option should be the password corresponding to the
login in B<NNTPAuthLogin>.  Having this hardcoded in a script is evil,
and there should be a much better way.

=item B<Period>

The value of this option indicates the length of the period (in days)
immediately prior to invocation of the program from which you would like
to scan articles.  The default period is seven (7) days.

=item B<QuoteRE>

The value of this option is a Perl regular expression that accepts quoted
lines and rejects unquoted or original lines.  The default regular
expression is C<^\s{0,3}(?:>|:|\S+>|\+\+)>.

=item B<Exclude>

The value of this option should be a reference to an array containing
regular expressions that accept email addresses of posters whose articles
you wish to ignore.

=item B<Aliases>

The value of this option should be a reference to a hash whose keys
are email addresses that should be transformed into the email addresses
that are their corresponding values, i.e. C<alias => 'real@address'>.

=back

=head1 METHODS

=over 4

=item configure ( [ OPTIONS ] )

C<OPTIONS> is a list of named parameters identical to those accepted by
C<new>.  Re-C<configure>-ing an object after scanning is probably a bad
idea.  This method returns C<undef> if it encounters an error.

=back

The following methods are the actual underlying methods used to set
and retrieve the configuration options of the same name (modulo case):

=over 4

=item name ( [ NEWSGROUP-NAME ] )

=item spool ( [ SPOOL-DIRECTORY ] )

=item period ( [ INTERVAL-LENGTH ] )

=item aliases ( [ ALIASES-HASHREF ] )

=item from ( C<'NNTP'> | C<'spool'> )

=item quote_re ( [ QUOTE-REGEX-ARRAYREF ] )

=item exclude ( [ EXCLUSION-REGEX-ARRAYREF ] )

=item nntp_server ( [ [ NNTP-SERVER ]:[ NNTP-PORT ] ] )

=item nntp_auth_login ( [ LOGIN ] )

=item nntp_auth_passwd ( [ PASSWORD ] )

=back 

These methods can be used to retrieve information from the
C<News::Scan> object or ask it to perform some action.

=over 4

=item error ( [ MESSAGE ] )

Use this method to determine whether an object has encountered an error
condition.  The return value of C<error> is guaranteed to be C<0>
after any method completes successfully (except C<error>).  (Keep in
mind that this will also overwrite any previous error message.)  If there
has been an error, this method should return some useful message.

If provided, C<MESSAGE> sets the object's error message.

=item articles

Returns the number of articles accounted for.

=item volume

Returns the volume of traffic (in bytes) to the newsgroup in the period.

=item header_volume

Returns the volume (in bytes) generated by headers.

=item header_lines

Returns the number of lines consumed by headers.

=item body_volume

Returns the volume (in bytes) generated by message bodies.

=item body_lines

Returns the number of lines consumed by message bodies.

=item orig_volume

Returns the volume (in bytes) of text which has been determined to be
original (see B<QuoteRE>).  Note that original traffic is a subset of
body traffic.

=item orig_lines

Returns the number of lines that are determined to be original.

=item signatures

Returns the number of messages that had a cutline (/^-- $/).

=item sig_volume

Returns the volume (in bytes) generated by signatures.

=item sig_lines

Returns the number of lines consumed by signatures.

=item earliest ( [ TIME ] )

Use this method to determine the date (in seconds since the Epoch) that
the oldest article found within the period was posted to Usenet.

If C<TIME> is given, it is treated as a candidate for the earliest
article.  If C<TIME> is successful (i.e. is less than the previous
earliest), this method returns C<1>, else C<0>.

=item latest ( [ TIME ] )

Use this method to determine the date (in seconds since the Epoch) that
the youngest article found within the period was posted to Usenet.

If C<TIME> is given, it is treated as a candidate for the latest
article.  If C<TIME> is successful (i.e. is greater than the previous
latest), this method returns C<1>, else C<0>.

=item excludes

Returns the list of regular expressions used to determine
whether an article from a given email address should be ignored.

=item posters

Returns a reference to a hash whose keys are email addresses and whose
values are C<News::Scan::Poster> objects corresponding to those email
addresses.  See L<News::Scan::Poster>.

=item threads

Returns a reference to a hash whose keys are subjects and whose values
are C<News::Scan::Thread> objects corresponding to those subjects.  See
L<News::Scan::Thread>.

=item crossposts

Returns a reference to a hash whose keys are newsgroup names and whose
values are the number of times the corresponding groups have been
crossposted to.

=item collect

Use this method to mirror the articles from the specified  NNTP server
to the specified spool.  Please be kind to the NNTP server.

=item scan

Instruct the object to gather information about the newsgroup.

=back

=head1 EXAMPLES

See the F<eg/> directory in the I<News-Scan> distribution, available
from the CPAN--F<http://www.perl.com/CPAN/>.

=head1 SEE ALSO

L<perlre>, L<News::Scan::Poster>, L<News::Scan::Thread>,
L<News::Scan::Article>, L<Net::NNTP>

=head1 AUTHOR

Greg Bacon <gbacon@cs.uah.edu>

=head1 COPYRIGHT

Copyright (c) 1997 Greg Bacon.  All Rights Reserved.
This library is free software.  You may distribute and/or modify it under
the same terms as Perl itself.

=cut
