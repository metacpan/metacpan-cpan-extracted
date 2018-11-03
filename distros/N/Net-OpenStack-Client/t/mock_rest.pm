# Original file from Net::OpenStack::Client
# Keep in sync when using in other repo

package mock_rest;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(load_mock_rest_data
    dump_method_history reset_method_history
    find_method_history method_history_ok
    );

use Test::More;
use Test::MockModule;
use JSON::XS;

my $json = JSON::XS->new()->canonical(1);

use File::Basename;
use Readonly;


Readonly my $DATA_DIR => 'rest_data';
Readonly my $BASE_DIR => dirname(__FILE__);
Readonly my %SUCCESS => {
    POST => 201,
    PUT => 204,
    DELETE => 204,
};

# Data file to load, relative to DATA_DIR
my @data_files = qw();

our $rc = Test::MockModule->new('REST::Client');
$rc->mock('setFollow', 1); # nothing useful to mock, but could be called

our $nic = Test::MockModule->new('Net::OpenStack::Client::REST');


# bunch of commands and their output
our %cmds;

# methods called
our @method_history = qw();


sub import
{
    my $class = shift;

    note "mock_rest importing files to load: @_";
    # Only load data if something is to be imported
    load_mock_rest_data(@_) if @_;

    $class->SUPER::export_to_level(1, $class, @EXPORT);
}

=head1 DESCRIPTION

mock_rest is a module to help unittest C<Net::OpenStack::Client>.

=head1 SYNOPSIS

Create a subdir C<rest_data> and add data files. The content of the files is
eval'ed and should populate a hash C<%cmds>.

You can select which data files to load on import using e.g.
    use mock_rest qw(file1 file2);

or later on using the exported C<load_mock_rest_data> function.
    use mock_rest;
    ...
    load_mock_rest_data(file1, file2);

(C<load_mock_rest_data> resets any already loaded data).

=head2 functions

=over

=item load_mock_rest_data

Reset data and load the files passed as arguments.
If none are passed, load all files in the directory.

=cut

sub load_mock_rest_data
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

    note "mock_rest ", scalar keys %cmds, " commands loaded";
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
        die "mock_rest _evalfn: $@";
    } else {
        note "mock_rest _evalfn done: $fn";
    };
}

=item REST::Client new

Return blessed instance, keep the options hashref in C<opts>

Also reset the method_history

=cut

$rc->mock('new', sub {
    my ($this, %opts) = @_;

    reset_method_history();

    my $class = ref($this) || $this;
    my $self = {
        opts => \%opts,
        code => undef,
        content => undef,
    };
    bless $self, $class;
    return $self;
});

=item REST::Client request

The method is saved in the method attribute.
The url is saved in the url attribute.

The value of each C<cmd> key is a regexp pattern; and it will be used to match
text generated from the passed data to the method.

The data is looked up in C<cmds> hash as follows:
sort all C<cmds> keys, first match wins and search less strict as follows

=over

=item C<cmd> key matches following text: 'method url content header=hval[,header2=hval2[,...]]'
Headers are sorted.

=item C<cmd> key matches following text: 'method url'

=item C<cmd> key matches following text: 'method content'

=item C<cmd> key matches following text: 'method header=hval[,header2=hval2[,...]]'
Headers are sorted.

=item C<cmd> key is open ended match for following text: 'method url content header=hval[,header2=hval2[,...]]'
(Open ended meaning the search pattern has to start with the C<cmd> key, but can have more fields or be final.)

=back

The space after the method name is significant, it is used to determine the used methodname.

=cut

sub _format { my $value = shift; return ref($value) eq 'ARRAY' ? join(',', @$value) : $value; }

$rc->mock('request', sub {
    my ($self, $method, $url, $body, $headers) = @_;

    $self->{method} = $method;
    $self->{url} = $url;

    # TODO: support versioned cmds
    my $id = 0;

    # default success
    $self->{code} = $SUCCESS{$method} || 200;
    $self->{result} = $json->encode({success => 1});
    $self->{headers} = {'Content-Type' => 'application/json'};

    my $body_txt = defined($body) ? "$body" : "";
    my $hdr_txt = '';
    foreach my $key (sort keys %$headers) {
        $hdr_txt .= ",$key="._format($headers->{$key});
    }
    $hdr_txt =~ s/^,//;

    push(@method_history, "$method $url $body_txt $hdr_txt");

    note "mock_rest $method url $url body $body_txt", explain $headers;

    # Binned results, one bin per class (update the pod above when increasing this)
    my $res = [ [], [], [], [], [], ];

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
            $match->(0, $strict_pat, "$method $url $body_txt $hdr_txt");

            # method+url
            $match->(1, $strict_pat, "$method $url");

            # method+body
            $match->(2, $strict_pat, "$method $body_txt");

            # method+headers
            $match->(3, $strict_pat, "$method $hdr_txt");

            # method only
            $match->(4, $open_pat, "$method");
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
        my $headers = $cmds{$short}{headers};
        my $code = $cmds{$short}{code};
        my $error = $cmds{$short}{error};

        $self->{result} = ref($result) ? $json->encode($result) : $result if defined($result);
        $self->{headers} = $headers if defined($headers);
        $self->{error} = $error if defined($error);
        $self->{code} = $code if defined($code);
    } else {
        diag "$method: no match cmd found for method $method. success=1 response";
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
    return $self->{result};
});

=item REST::Client responseHeaders

=cut

$rc->mock('responseHeaders', sub {
    my ($self) = @_;
    return keys %{$self->{headers}};
});

=item REST::Client responseHeader

=cut

$rc->mock('responseHeader', sub {
    my ($self, $hdr) = @_;
    die "mock_rest responseHeader: no header" if ! defined($hdr);
    return $self->{headers}->{$hdr};
});

=item dump_method_history

diag explain the history

=cut

sub dump_method_history
{
    diag "mock_rest: current history ", explain \@method_history;
}

=item reset_method_history

=cut

sub reset_method_history
{
    @method_history = qw();
}

=item find_method_history

Return all method commands that were called matching C<pattern>.

=cut

sub find_method_history
{
    my ($pattern) = @_;

    my @args = grep {m/$pattern/} @method_history;

    return @args;
};

=item C<method_history_ok>

Given a arrayref of commands, it checks the C<@method_history> if all commands were
called in the given order (it allows for other commands to exist inbetween).
The commands are interpreted as regular expressions.

E.g. if C<@method_history> is (x1, x2, x3) then
C<method_history_ok([x1,X3])> returns 1 (Both x1 and x3 were called and in that order,
the fact that x2 was also called but not checked is allowed.).
C<method_history_ok([x3,x2])> returns 0 (wrong order),
C<method_history_ok([x1,x4])> returns 0 (no x4 command).

A optional second argument is an arrayref of command regexps that were not called.

=cut

# code from Test::Quattor

sub method_history_ok
{
    my ($commands, $not_commands) = @_;

    die "method_history_ok commands must be an arrayref" if ($commands && (ref($commands) ne 'ARRAY'));
    die "method_history_ok not_commands must be an arrayref" if ($not_commands && (ref($not_commands) ne 'ARRAY'));

    if ($not_commands) {
        my @found;
        foreach my $nc (@$not_commands) {
            push(@found, grep {m/$nc/} @method_history);
        };
        if (@found) {
            note "Found matches for not_commands, return false: @found";
            return 0;
        };
    }

    my $lastidx = -1;
    foreach my $cmd (@$commands) {
        # start iterating from lastidx+1
        my ( $index )= grep { $method_history[$_] =~ /$cmd/  } ($lastidx+1)..$#method_history;
        my $msg = "method_history_ok command pattern '$cmd'";
        if (!defined($index)) {
            note "FAIL $msg no match; return false";
            return 0;
        } else {
            $msg .= " index $index (full command $method_history[$index])";
            if ($index <= $lastidx) {
                note "FAIL $msg <= lastindex $lastidx; return false";
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
