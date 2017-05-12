package mock_rpc;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(load_mock_rpc_data
    reset_POST_history find_POST_history POST_history_ok
    );

use Test::More;
use Test::MockModule;

use File::Basename;
use Readonly;


Readonly my $DATA_DIR => 'rpc_data';
Readonly my $BASE_DIR => dirname(__FILE__);

Readonly my $NOMETHOD => 'NOMETHOD';

# Simple single content, without result
Readonly::Hash my %SINGLE_CONTENT => {
    error => undef,
    principal => 'admin@MY.REALM',
    version => '1.2.3'
};


# Simple empty single result
Readonly::Hash my %SINGLE_RESULT => {
    count => 1,
    truncated => 0,
    summary => 'single summary',
    result => [{}],
};


# Data file to load, relative to DATA_DIR
my @data_files = qw();

our $rc = Test::MockModule->new('REST::Client');
$rc->mock('setFollow', 1); # nothing useful to mock, but is called

our $nic = Test::MockModule->new('Net::FreeIPA::RPC');
our $json = Test::MockModule->new('JSON::XS');

# bunch of commands and their output
our %cmds;

# POST commands called
our @POST_history = qw();


sub import
{
    my $class = shift;

    note "importing files to load: @_";
    # Only load data if something is to be imported
    load_mock_rpc_data(@_) if @_;

    $class->SUPER::export_to_level(1, $class, @EXPORT);
}

=head1 DESCRIPTION

mock_rpc is a module to help unittest C<Net::FreeIPA>.

=head1 SYNOPSIS

Create a subdir C<rpc_data> and add data files. The content of the files is
eval'ed and should populate a hash C<%cmds>.

You can select which data files to load on import using e.g.
    use mock_rpc qw(file1 file2);

or later on using the exported C<load_mock_rpc_data> function.
    use mock_rpc;
    ...
    load_mock_rpc_data(file1, file2);

(C<load_mock_rpc_data> resets any already loaded data).

=head2 functions

=over

=item load_mock_rpc_data

Reset data and load the files passed as arguments. If none are passed, load all files in the directory.

=cut

sub load_mock_rpc_data
{

    my (@files) = @_;

    %cmds = ();

    my $dirname = "$BASE_DIR/$DATA_DIR";

    if (! @files) {
        opendir(DIR, $dirname) or die "Could not open $dirname\n";
        @files = grep { m/\w$/ } readdir(DIR);
        close DIR;
    }

    foreach my $file (@files) {
        _evalfn("$dirname/$file");
    }

    note scalar keys %cmds, " commands loaded";
};


=item _evalfn

Read and eval file

=cut

# split in multiple data files due to too long
# Read and eval file
sub _evalfn {
    my $fn = shift;
    open CODE, $fn;
    undef $\;
    my $code = join('', <CODE>);
    close CODE;
    eval $code;
    if ($@) {
        die "_evalfn: $@";
    } else {
        note "_evalfn done: $fn";
    };
}

=item REST::Client new

Return blessed instance, keep the options hashref in C<opts>

Also reset the POST_history

=cut

$rc->mock('new', sub {
    my ($this, %opts) = @_;

    reset_POST_history();

    my $class = ref($this) || $this;
    my $self = {
        opts => \%opts,
        code => undef,
        content => undef,
    };
    bless $self, $class;
    return $self;
});

=item REST::Client POST

The url is saved in the url attribute.
The value of each C<cmd> key is a regexp pattern; and it will be used to match
text generated from the passed data to the POST method.

The data is looked up in C<cmds> hash as follows:
sort all C<cmds> keys, first match wins and search less strict as follows

=over

=item C<cmd> key matches following text: 'method arg1[,arg2[,..]] opt=val[,opt2=val2[,...]]'
Option keys are sorted.

=item C<cmd> key matches following text: 'method arg1[,arg2[,..]]'

=item C<cmd> key matches following text: 'method opt=val[,opt2=val2[,...]]]'
Option keys are sorted.

=item C<cmd> key is open ended match for following text: 'method arg1[,arg2[,..]] opt=val[,opt2=val2[,...]]'
(Open ended meaning the search pattern has to start with the C<cmd> key, but can have more fields or be final.)

=back

If an id is prefixed to the cmd pattern, it will take precedence over none-matching id (id=0 is the default).

The space after the method name is significant, it is used to determine the used methodname.

=cut

sub _format { my $value = shift; return ref($value) eq 'ARRAY' ? join(',', @$value) : $value; }

$rc->mock('POST', sub {
    my ($self, $url, $data) = @_;

    $self->{url} = $url;

    # default success
    $self->{code} = 200;

    $self->{content} = { %SINGLE_CONTENT };
    $self->{content}->{result} = { %SINGLE_RESULT };

    my $id = $data->{id} || 0;
    $self->{content}->{id} = $id;

    my $method = $data->{method} || $NOMETHOD;
    my ($args, $opts) = @{$data->{params} || [[], {}]};
    my $args_txt = join(',', map {_format($_)} @$args);
    my $opts_txt = '';
    foreach my $key (sort keys %$opts) {
        $opts_txt .= ",$key="._format($opts->{$key});
    }
    $opts_txt =~ s/^,//;

    push(@POST_history, "$id $method $args_txt $opts_txt");

    note "POST url $url id $id data ", explain $data;

    # Binned results, one bin per class (update the pod above when increasing this)
    my $res = [ [], [], [], [], ];

    # Lookup data, set code and content
    foreach my $short (sort keys %cmds) {
        my $cmd = $cmds{$short}{cmd};
        my @fields = split(' ', $cmd);

        my $idmatch = 0;
        if ($fields[0] =~ m/^\d+$/) {
            $idmatch = $fields[0] == $id;
            shift(@fields);

            # There was an id specified, but there was no match.
            # So this is the wrong id
            next if (! $idmatch);
        };

        my $idx; # if undef, indicates a match and which sub-array in $res to add it

        my $match = sub {
            my ($index, $pat, $cmd_txt) = @_;
            return if defined($idx);

            $idx = $index if ($cmd_txt =~ m/$pat/);
            note "short $short idx ".(defined($idx) ? $idx : 'undef')." pat $pat cmd_txt $cmd_txt";
        };

        my $fmethod = $fields[0];
        if ($fmethod eq $method) {

            my $cmd_pat = join(' ', @fields);

            my $strict_pat = "^$cmd_pat\$";
            # Open ended searches
            my $open_pat = "^$cmd_pat( |\$)";

            # Most specific pattern first

            # Exact match, full command
            $match->(0, $strict_pat, "$method $args_txt $opts_txt");

            # method+args
            $match->(1, $strict_pat, "$method $args_txt");

            # method+opts
            $match->(2, $strict_pat, "$method $opts_txt");

            # method only
            $match->(3, $open_pat, "$method");
        }

        if (defined($idx)) {
            note "adding match short $short idx $idx idmatch $idmatch";
            if ($idmatch) {
                unshift(@{$res->[$idx]}, $short);
            } else {
                push(@{$res->[$idx]}, $short);
            }
        }
    }
    note "All results res ", explain $res;

    # Flatten res, first one wins
    my @allres;
    foreach my $r (@$res) {
        push(@allres, @$r);
    }

    if (@allres) {
        my $short = $allres[0];

        my $result = $cmds{$short}{result};
        my $code = $cmds{$short}{code};
        my $count = $cmds{$short}{count};
        my $error = $cmds{$short}{error};

        $self->{content}->{result}->{result} = $result if defined($result);
        $self->{content}->{result}->{count} = $count if defined($count);
        $self->{content}->{error} = $error if defined($error);
        $self->{code} = $code if defined($code);
    } else {
        my $msg;
        if ($method eq $NOMETHOD) {
            $msg = "url $url";
        } else {
            $msg = "method $method";
        }
        diag "POST: no match cmd found for $msg. Return default single result.";
    }

    return;
});

=item REST::Client responseCode

=cut

$rc->mock('responseCode', sub {
    my ($self) = @_;
    return $self->{code};
});

=item REST::Client responseCode

=cut

$rc->mock('responseContent', sub {
    my ($self) = @_;
    return $self->{content};
});

=item JSON:XS encode

do not encode, pass this as is to mocked C<REST::Client::POST>.

=cut

$json->mock('encode', sub {
    my ($self, $data) = @_;
    return $data;
});


=item JSON:XS decode

the content is a hashref, the return of the mocked C<REST::Client>

=cut

$json->mock('decode', sub {
    my ($self, $content) = @_;
    return $content;
});

=item reset_POST_history

=cut

sub reset_POST_history
{
    @POST_history = qw();
}

=item find_POST_history

Return all POST commands that were called matching C<pattern>.

=cut

sub find_POST_history
{
    my ($pattern) = @_;

    my @args = grep {m/$pattern/} @POST_history;

    return @args;
};

=item C<POST_history_ok>

Given a arrayref of commands, it checks the C<@POST_history> if all commands were
called in the given order (it allows for other commands to exist inbetween).
The commands are interpreted as regular expressions.

E.g. if C<@POST_history> is (x1, x2, x3) then
C<POST_history_ok([x1,X3])> returns 1 (Both x1 and x3 were called and in that order,
the fact that x2 was also called but not checked is allowed.).
C<POST_history_ok([x3,x2])> returns 0 (wrong order),
C<POST_history_ok([x1,x4])> returns 0 (no x4 command).

A optional second argument is an arrayref of command regexps that were not called.

=cut

# code from Test::Quattor

sub POST_history_ok
{
    my ($commands, $not_commands) = @_;

    die "POST_history_ok commands must be an arrayref" if ($commands && (ref($commands) ne 'ARRAY'));
    die "POST_history_ok not_commands must be an arrayref" if ($not_commands && (ref($not_commands) ne 'ARRAY'));

    if ($not_commands) {
        my @found;
        foreach my $nc (@$not_commands) {
            push(@found, grep {m/$nc/} @POST_history);
        };
        if (@found) {
            note "Found matches for not_commands, return false: @found";
            return 0;
        };
    }

    my $lastidx = -1;
    foreach my $cmd (@$commands) {
        # start iterating from lastidx+1
        my ( $index )= grep { $POST_history[$_] =~ /$cmd/  } ($lastidx+1)..$#POST_history;
        my $msg = "POST_history_ok command pattern '$cmd'";
        if (!defined($index)) {
            note "$msg no match; return false";
            return 0;
        } else {
            $msg .= " index $index (full command $POST_history[$index])";
            if ($index <= $lastidx) {
                note "$msg <= lastindex $lastidx; return false";
                return 0;
            } else {
                note "$msg; continue";
            }
        };
        $lastidx = $index;
    };
    # in principle, when you get here, all is ok.
    # but at least 1 command should be found, so lastidx should be > -1
    return $lastidx > -1;
}

=pod

=back

=cut

1;
