use strictures 1;

package Mojito::Page::Git;
$Mojito::Page::Git::VERSION = '0.25';
use 5.010;
use Moo;
use Git::Wrapper;
use IO::File;
use File::Spec;
use Mojito::Auth;
use Try::Tiny;
use Data::Dumper::Concise;

with('Mojito::Role::DB');
with('Mojito::Role::Config');

=head1 Name

Mojito::Page::Git - the git backend

=cut

has dir => (
    is        => 'rw',
    lazy => 1,
    builder => '_build_dir',
);
sub _build_dir {
    die "You must have a 'git_repo' path in your conf file. e.g. git_repo => '/user/you/repos/mojito'" 
      if !$_[0]->config->{git_repo};
     $_[0]->config->{git_repo};
}
has git => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_git',
);

sub _build_git {
    my $self = shift;
    my $git  = Git::Wrapper->new( $self->dir );
    $git->init;
    return $git;
}

=head1 Methods

=head2 commit_page

Commit a page revision to the git repository.

=cut

sub commit_page {
    my ( $self, $page_struct, $params ) = @_;

    my $page_id = $params->{id};
    my $file = File::Spec->catfile( $self->dir, $page_id )
      || die "Can't ->catfile on dir", $self->dir, " and page_id $page_id $@";
    my $io = IO::File->new( ">" . $file )
      || die "Can't create new IO::File for file: $file. $@";
    $io->print( $page_struct->{page_source} );

    return if !$self->git->status->is_dirty;

    $self->git->add( {}, ${page_id} );
    if ( $params->{username} ) {
        if ( my $auth = Mojito::Auth->new( config => $self->config, username => $params->{username} ) ) {
            if ( my $user = $auth->get_user ) {
                my $name = $user->{first_name} . ' ' . $user->{last_name};
                $self->git->config( 'user.name',  $name );
                $self->git->config( 'user.email', $user->{email} );
            }
        }
    }
    $self->git->commit( { message => $params->{commit_message}||'no commit message' }, $page_id );

    return;
}

=head2 rm_page

Remove a page from the repo (done when deleting a page from the DB)

=cut

sub rm_page {
    my ( $self, $page_id ) = @_;

    try {
        $self->git->rm( {}, ${page_id} );
        $self->git->commit( { message => "Delete page" }, $page_id );
    }
    catch {
        warn "Tried to delete page: $page_id, but had problems: $_";  
    };
    
}

=head2 diff_page

Get the diff between two versions of a page.
Diff a Page: $m and $n are the number of ^ we'll use from HEAD.
Example:

    diff/3/1 would mean git diff HEAD^^^ HEAD^ $page_id

=cut

sub diff_page {
    my ( $self, $page_id, $m, $n ) = @_;
    
    # Defaults
    $m //= 1;
    $n //= 0;
    my $base = ('^') x $m;
    my $place = ('^') x $n;
    my @diff = $self->git->diff( {}, "HEAD${base}..HEAD${place}", ${page_id} );
    my $diff = join "\n", @diff;

    return $diff;
}

=head2 search_word

Search for a word using git grep and return the list of matching document ids.
NOTE: A document can be returned more than once so we'll make hash of documents
with the count of how many times they matched.

=cut

sub search_word {
    my ( $self, $search_word ) = ( shift, shift );

    #    warn "** Searching on $search_word";
    my @search_hits;
    my $no_hits = 0;
    try {
        @search_hits = $self->git->grep( { 'ignore_case' => 1 }, $search_word );
    }
    catch {
        $no_hits = 1;
    };
    return if $no_hits;

    my @page_ids = map { my ($file) = $_ =~ /^(\w+)\:/; $file; } @search_hits;
    my %hit_hash = ();
    %hit_hash = map { $_ => ++$hit_hash{$_} } @page_ids;
    return \%hit_hash;
}

=head2 get_author_for

Given a page id find the author of the last commit.

=cut

sub get_author_for {
    my ($self, $page_id) = (shift, shift);
    
    my $author = "Author Unknown";
    try {
        my @log = $self->git->log( {}, ${page_id} );
        $author = $log[0]->author;
        $author =~ s/\s+\<.*\>//;
    }
    catch {
        warn "Could not git log for page: ${page_id}"; 
    };

    return $author;
}

1
