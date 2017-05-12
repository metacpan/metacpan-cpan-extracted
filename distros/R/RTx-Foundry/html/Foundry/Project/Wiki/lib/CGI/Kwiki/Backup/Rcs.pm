package CGI::Kwiki::Backup::Rcs;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki::Backup';
use File::Spec;

use constant RCS_DIR => 'metabase/rcs';

sub file_path {
    my ($self, $page_id) = @_;
    RCS_DIR . '/' . $self->escape($page_id) . ',v';
}

my $user_name = '';
sub new {
    my ($class) = shift;
    my $self = $class->SUPER::new(@_);
    unless (-d RCS_DIR) {
        mkdir RCS_DIR;
        umask 0000;
        chmod 0777, RCS_DIR;
        $user_name = 'kwiki-install';
        for my $page_id ($self->database->pages) {
            $self->commit($page_id);
        }
    }
    return $self;
}
    
sub commit {
    my ($self, $page_id) = @_;
    my $rcs_file_path = $self->file_path($page_id);
    if (not -f $rcs_file_path) {
        $self->shell("rcs -q -i $rcs_file_path < /dev/null");
    }
    my $msg = $self->escape($user_name || $self->metadata->edit_by);
    my $page_file_path = $self->database->file_path($page_id);
    $self->shell(qq{ci -q -l -m"$msg" $page_file_path $rcs_file_path});
}

sub has_history {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    -f $self->file_path($page_id);
}

sub history {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;
    my $rcs_file_path = $self->file_path($page_id);
    open RLOG, "rlog -zLT $rcs_file_path |"
      or DIE $!; 
    binmode(RLOG, ':utf8') if $self->use_utf8;
    local $/;
    my $input = <RLOG>;
    close RLOG;
    (my $rlog = $input) =~ s/\n=+$.*\Z//ms;
    my @rlog = split /^-+\n/m, $rlog;
    shift(@rlog);
    my $history = [];
    for (@rlog) {
        /^revision\s+(\S+).*?
         ^date:\s+(.+?);.*?\n
         (.*)
        /xms or die "Couldn't parse rlog for '$page_id':\n$rlog";
        push @$history,
          {
            revision => $1,
            file_rev => $1,
            date => $2,
            edit_by => $self->unescape($3),
          };
    }
    return $history;
}

sub file_rev {
    my ($self, $page_id, $revision) = @_;
    return $revision;
}

sub fetch {
    my ($self, $page_id, $revision) = @_;
    my $rcs_file_path = $self->file_path($page_id);
    
    local($/, *CO);
    open CO, qq{co -q -p$revision $rcs_file_path |}
      or die $!;
    binmode(CO, ':utf8') if $self->use_utf8;
    <CO>;
}

sub diff {
    my ($self, $page_id, $r1, $r2, $context) = @_;
    $context ||= 1000000;
    my $rcs_file_path = $self->file_path($page_id);

    local(*RCSDIFF);
    open RCSDIFF, qq{rcsdiff -q -r$r1 -r$r2 --unified=$context $rcs_file_path |}
      or die "rcsdiff failed:\n$!";
    binmode(RCSDIFF, ':utf8') if $self->use_utf8;
    my $line1 = <RCSDIFF>;
    my $line2 = <RCSDIFF>;
    $line2 =~ s/\+/%2B/g; # counter ->unescape
    local $/;
    return($self->unescape($line1) . $self->unescape($line2) . <RCSDIFF>);
}

sub shell {
    my ($self, $command) = @_;
    use Cwd;
    $! = undef;
    system($command) == 0 
      or die "$command failed: $! | " . Cwd::cwd();
}

1;
