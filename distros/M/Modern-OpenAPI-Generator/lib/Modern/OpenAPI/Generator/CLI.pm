package Modern::OpenAPI::Generator::CLI;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);
use Modern::OpenAPI::Generator ();

# Resolves --client / --server / --ui and --no-* from raw argv (before Getopt mutates it).
#
# No such flags  -> (1,1,1) full stack.
# Only --no-*    -> start from (1,1,1), turn off each mentioned flag.
# Any --client / --server / --ui (positive) appears -> start (0,0,0), apply all flags in order
# (--client --server does NOT imply --ui; add --ui explicitly if you want Swagger UI).
sub _resolve_feature_flags {
    my ($argv) = @_;
    my @tokens = grep { /^--(no-)?(client|server|ui)$/ } @$argv;
    return ( 1, 1, 1 ) unless @tokens;

    my $has_positive = grep { /^--(client|server|ui)$/ } @tokens;

    if ( !$has_positive ) {
        my ( $c, $s, $u ) = ( 1, 1, 1 );
        for (@tokens) {
            /^--no-client$/ && do { $c = 0; next };
            /^--no-server$/ && do { $s = 0; next };
            /^--no-ui$/     && do { $u = 0; next };
        }
        return ( $c, $s, $u );
    }

    my ( $c, $s, $u ) = ( 0, 0, 0 );
    for (@tokens) {
        if    (/^--client$/)       { $c = 1 }
        elsif (/^--no-client$/)    { $c = 0 }
        elsif (/^--server$/)       { $s = 1 }
        elsif (/^--no-server$/)    { $s = 0 }
        elsif (/^--ui$/)           { $u = 1 }
        elsif (/^--no-ui$/)        { $u = 0 }
    }
    return ( $c, $s, $u );
}

sub _pod2usage {
    my ( $verbose, $exitval ) = @_;
    pod2usage(
        -verbose => $verbose,
        -exitval  => $exitval,
        -input    => __FILE__,
    );
}

sub run {
    my ( $class, @argv ) = @_;
    my @orig_argv = @argv;
    my $spec;
    my $output = '.';
    my $name;
    my ( $sync, $async ) = ( 1, 1 );
    my $skeleton   = 0;
    my $local_test = 0;
    my $force      = 0;
    my $merge      = 0;
    my @signatures;

    GetOptionsFromArray(
        \@argv,
        'spec=s'       => \$spec,
        'output|o=s'   => \$output,
        'name|n=s'     => \$name,
        'sync!'        => \$sync,
        'async!'       => \$async,
        'skeleton'     => \$skeleton,
        'local-test'   => \$local_test,
        'force'        => \$force,
        'merge'        => \$merge,
        'signature=s@' => \@signatures,
        'help|h|?'     => \my $help,
        'usage'        => \my $usage,
    ) or _pod2usage( 0, 2 );

    _pod2usage( 2, 0 ) if $help;
    _pod2usage( 0, 0 ) if $usage;

    my ( $client, $server, $ui ) = _resolve_feature_flags( \@orig_argv );

    $spec //= $argv[0];
    $output = '.' if !defined $output || !length $output;
    croak "Usage: oapi-perl-gen --name MyApp::API [--spec openapi.yaml] [--output DIR]\n" unless $spec;
    croak "--name is required (Perl package prefix)\n" unless $name;

    croak "At least one of --client, --server, or --ui must stay enabled "
      . "(use defaults or omit all --no-* flags).\n"
      if !$client && !$server && !$ui;

    if ( @signatures == 1 && $signatures[0] =~ /,/ ) {
        @signatures = split /,/, $signatures[0];
    }

    Modern::OpenAPI::Generator->new(
        spec_path      => $spec,
        output_dir     => $output,
        name           => $name,
        client         => $client,
        server         => $server,
        ui             => $ui,
        sync           => $sync,
        async          => $async,
        skeleton       => $skeleton,
        force          => $force,
        merge          => $merge,
        signatures     => \@signatures,
        local_test     => $local_test,
    )->run;

    print "Generated under $output (package $name)\n";
    return 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator::CLI - Command-line driver for L<Modern::OpenAPI::Generator> (C<oapi-perl-gen>)

=head1 SYNOPSIS

  oapi-perl-gen --name MyApp::API --output ./generated openapi.yaml

  oapi-perl-gen --name MyApp::API -o ./out ./spec/openapi.yaml

  oapi-perl-gen --help              # full manual (Pod::Usage)

  oapi-perl-gen --usage             # synopsis only (Pod::Usage)

=head1 OPTIONS

=over 4

=item C<--name> / C<-n> (required)

Root Perl package prefix (e.g. C<MyApp::API>). All generated modules use this
namespace.

=item C<--spec> I<FILE>

OpenAPI 3.x YAML or JSON document. You may pass the path as the first positional
argument instead of C<--spec>.

=item C<--output> / C<-o> I<DIR>

Output directory for the generated tree (default: current directory, C<.>).

=item C<--sync> / C<--no-sync>

Emit C<::Client::Sync> (default: on).

=item C<--async> / C<--no-async>

Emit C<::Client::Async> (default: on).

=item C<--skeleton>

Emit server controller stubs without C<TODO> comments.

=item C<--local-test>

With C<--server>: controllers use C<::StubData> and C<::Model::*> to return
random data shaped like the response schema instead of HTTP 501. Also emits
models when C<--no-client> but server and local-test are on.

=item C<--signature> I<hmac>

=item C<--signature> I<bearer>

Emit C<::Auth::Plugin::Hmac> and/or C<::Auth::Plugin::Bearer>. Repeat the flag
or pass a comma-separated list.

=item C<--force>

Overwrite existing files in the output tree.

=item C<--merge>

Skip writing a file if it already exists (unless C<--force> is also set).

=item C<--help> / C<-h> / C<-?>

Print full documentation (this manual) from POD via L<Pod::Usage>, then exit.

=item C<--usage>

Print only the synopsis section via L<Pod::Usage>, then exit.

=back

=head1 FEATURE SELECTION (client / server / Swagger UI)

Three independent toggles control what is emitted. Rules:

=over 4

=item Default

If your argument list contains I<none> of: C<--client>, C<--no-client>,
C<--server>, C<--no-server>, C<--ui>, C<--no-ui>, then all three features are
generated (full stack).

=item Only C<--no-*> flags

Each C<--no-client>, C<--no-server>, or C<--no-ui> turns that feature off; the
others stay on (example: C<--no-ui> gives client + server without embedded
Swagger UI).

=item At least one positive flag

If you pass any of C<--client>, C<--server>, or C<--ui> (without C<no->), the
generator starts from all-off and applies only what you set explicitly.
Example: C<--client --server> does I<not> imply C<--ui>.

=item Constraint

At least one of client, server, or UI must remain enabled.

=back

Examples:

  --client                    => client only
  --client --server           => client + server, no UI
  --client --server --ui      => client + server + Swagger UI
  --no-ui                     => client + server, no UI
  --no-server --no-ui         => client only

=head1 SWAGGER UI AND REQUEST ORIGIN

When server and UI are generated, C<GET /openapi.yaml> can prepend the current
request origin to C<servers> so Swagger UI “Try it out” targets the running
app. The generated C<script/server.pl> enables this when run with C<--local-test>
at runtime, or when C<OAPI_SWAGGER_LOCAL_ORIGIN> is set. This is separate from
the C<oapi-perl-gen --local-test> code-generation flag.

=head1 METHODS

=head2 run

  Modern::OpenAPI::Generator::CLI->run(@argv)

Class method used by the C<oapi-perl-gen> script. Parses C<@argv> with
L<Getopt::Long> (see L</OPTIONS>), applies feature flags (see L</FEATURE SELECTION (client / server / Swagger UI)>),
then constructs L<Modern::OpenAPI::Generator> with the same parameters the CLI
accepts and invokes C<< ->run >> on it. On success, prints one line to STDOUT
(C<Generated under ...>) and returns C<0>.

Invalid C<Getopt::Long> options trigger L<Pod::Usage> with exit status C<2>.
C<--help> and C<--usage> print documentation via L<Pod::Usage> and exit C<0>
before generation.

=head1 DESCRIPTION

Implements the C<oapi-perl-gen> driver: argument parsing, L<Pod::Usage> for
help, and delegation to L<Modern::OpenAPI::Generator>. See L</METHODS>.

=head1 SEE ALSO

L<Modern::OpenAPI::Generator>, L<Pod::Usage>, the C<oapi-perl-gen> script.

=head1 COPYRIGHT AND LICENSE

Same as L<Modern::OpenAPI::Generator>.

=cut
