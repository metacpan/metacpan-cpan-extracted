package Pegex::Cmd;
our $VERSION = '0.28';

#-----------------------------------------------------------------------------#
package Pegex::Cmd;

use Pegex::Cmd::Mo;

use Getopt::Long;

use constant abstract =>
    'Compile a Pegex grammar to some format.';
use constant usage_desc =>
    'pegex compile --to=<output format> [grammar_file.pgx]';

# Output format. One of: yaml, json, perl, perl6, python.
has to => ();

# Regex format: raw, perl.
has regex => ();

# Use the bootstrap compiler
has boot => ();

# Starting rules to combinate
has rules => (
    default => sub {
        $ENV{PEGEX_COMBINATE_RULES}
        ? [ split / +/, $ENV{PEGEX_COMBINATE_RULES} ]
        : []
    },
);

my %formats = map {($_,1)} qw'yaml json perl';
my %regexes = map {($_,1)} qw'perl raw';
my %commands = map {($_,1)} qw'compile help version';
sub usage;
sub error;

sub run {
    my ($self, @argv) = @_;

    my ($command, $args) = $self->getopt(@argv);
    @ARGV = ();

    $self->$command($args);
}

sub help {
    print usage;
}

sub compile {
    my ($self, $args) = @_;

    my $to = $self->to or
        error "--to=perl|yaml|json required";

    my $regex = $self->regex ||
        $to eq 'perl' ? 'perl' : 'raw';

    die "'$to' is an invalid --to= format"
        unless $formats{$to};
    die "'$regex' is an invalid --regex= format"
        unless $regexes{$regex};

    my $input = scalar(@$args)
        ? $self->slurp($args->[0])
        : do { local $/; <> };
    my $compiler_class = $self->boot
        ? 'Pegex::Bootstrap'
        : 'Pegex::Compiler';

    eval "use $compiler_class; 1" or die $@;
    my $compiler = $compiler_class->new();
    $compiler->parse($input)->combinate(@{$self->rules});
    $compiler->native if $regex eq 'perl';

    my $output =
        $to eq 'perl' ? $compiler->to_perl :
        $to eq 'yaml' ? $compiler->to_yaml :
        $to eq 'json' ? $compiler->to_json :
        do { die "'$to' format not supported yet" };
    print STDOUT $output;
}

sub version {
    require Pegex;

    print <<"...";
The 'pegex' compiler command v$VERSION

Using the Perl Pegex module v$Pegex::VERSION
...
}

sub getopt {
    my ($self, @argv) = @_;

    local @ARGV = @argv;

    GetOptions(
        "to=s" => \$self->{to},
        "boot" => \$self->{boot},
    ) or error;

    if (not @ARGV) {
        print usage;
        exit 0;
    }

    my $command = shift @ARGV;
    $commands{$command} or
        error "Invalid command '$command'";

    return $command, [@ARGV];
}

sub slurp {
    my ($self, $file) = @_;
    open my $fh, $file or
        die "Can't open '$file' for input";
    local $/;
    <$fh>;
}

sub error {
    my $msg = usage;

    $msg = "Error: $_[0]\n\n$msg" if @_;

    die $msg;
}

sub usage {
    <<'...';
pegex <command> [<options>] [<input-file>]

Commands:

   compile: Compile a Pegex grammar to some format
   version: Show Pegex version
      help: Show help

Options:
   -t,--to=:     Output type: yaml, json, perl
   -b, --boot:   Use the Pegex Bootstrap compiler
   -r, --rules=: List of starting rules

...
}

1;
