use strict;
use warnings;
package Plack::App::DAIA::Test::Suite;
#ABSTRACT: Test DAIA Servers via a test scripting language
our $VERSION = '0.55'; #VERSION
use base 'Test::Builder::Module';
our @EXPORT = qw(provedaia);

use Test::More;
use Plack::App::DAIA::Test;
use Scalar::Util qw(reftype blessed);
use Test::JSON::Entails;
use JSON;
use Carp;

sub provedaia {
    my ($suite, %args) = @_;

    my $test  = __PACKAGE__->builder;
    my @lines;

    if ( ref($suite) ) {
        croak 'usage: provedaia( $file | $glob | $string )'
            unless reftype($suite) eq 'GLOB' or blessed($suite) and $suite->isa('IO::File');
        @lines = <$suite>;
    } elsif ( $suite !~ qr{^https?://} and $suite !~ /[\r\n]/ ) {
        open (my $fh, '<', $suite) or croak "failed to open daia test suite $suite";
        @lines = <$fh>;
        close $fh;
    } else {
        @lines = split /\n/, $suite;
    }

    my $line = 0;
    my $comment = '';
    my $json = undef;
    my %vars = ( server => $args{server} );
    my @ids;
    @ids = @{$args{ids}} if $args{ids};

    my $run = sub {
        my $server = $vars{server} or return;
        $json ||= '{ }';
        my $server_name = $server;
        if ( $server !~ qr{^https?://}) {
            no warnings 'redefine'; # we may load the same twice
            $_ = Plack::Util::load_psgi($server);
            if ( ref($_) ) {
                diag("loaded PSGI from $server");
                $server = $_;
            } else {
                fail("failed to load PSGI from $server");
                return;
            }
        }
        foreach my $id (@ids) {
            my $test_name = "$server_name?id=$id";
            $comment =~ s/^\s+|\s+$//g;
            $test_name .= " ($comment)" if $comment ne '';
            local $Test::Builder::Level = $Test::Builder::Level + 2; # called 2 levels above
            my $test_json = $json;
            $vars{id} = $id;
            $test_json =~ s/\$([a-z]+)/defined $vars{$1} ? $vars{$1} : "\$$1"/emg;
            $test_json = decode_json($test_json);
            if (ref($server)) {
                test_daia_psgi $server, $id => $test_json, $test_name;
            } else {
                test_daia $server, $id => $test_json, $test_name;
            }
        }
    };

    foreach (@lines) {
        if ($args{end}) {
            $args{end} = 0 if /__END__/;
            next;
        }
        chomp;
        $comment = $1 if /^#(.*)/;
        s/^(#.*|\s+)$//; # empty line or comment
        $line++;

        if (defined $json) {
            $json .= $_;
            if ($_ eq '') {
                $run->();
                $json = undef;
                $comment = '';
            }
        } elsif ( $_ eq '' ) {
            next;
        } elsif( $_ =~ qr{^([a-z]+)\s*=\s*(.*)}i ) {
            $comment = '';
            my ($key, $value) = ($1,$2);
            if ($1 =~ /^id[s]?/) {
                @ids = $value eq '' ? () : ($value);
            } else {
                $vars{$key} = $value;
            }
            diag( "$key = $value" ) if $args{verbose};
        } elsif( $_ =~ qr/^\s*{/ ) {
            $json = $_;
        } else { # identifier
            $comment = '';
            push @ids, $_;
        }
    }
    $run->();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::DAIA::Test::Suite - Test DAIA Servers via a test scripting language

=head1 VERSION

version 0.55

=head1 SYNOPSIS

    use Test::More;
    use Plack::App::DAIA::Test::Suite;

    provedaia <<SUITE, server => "http://example.com/your-daia-server";
    foo:bar

    # document expected
    { "document" : [ { } ] }
    SUITE

    done_testing;

=head1 METHODS

=head2 provedaia ( $suite [, %options ] )

Run a DAIA test suite from a string or stream (GLOB or L<IO::File>). A DAIA
test suite lists servers, identifiers, and DAIA/JSON response fragments to test
DAIA servers.  The command line client L<provedaia> is included in this
distribution for convenience.

Additional option supported so far are C<server> and C<ids>. The former is
equivalent to an inital C<server=...> statement in you test suite and the
latter is equivalent to an initial list of identifiers in you test suite.

If the option C<end> is set, all lines before C<__END__> are ignored in the
test suite script. The option C<verbose> adds more diagnostic messages.

=head1 TEST SUITE FORMAT

A test suite is defined in a text-based format that is parsed line by line.
Empty lines are ignored. There are four kinds of statements:

=over 4

=item comments

All lines starting with C<#> are treated as comments.

=item responses

All lines starting with C<{>} begin a response (fragment) in JSON format.
Following lines are treated as part of the JSON structure until an empty line
or the end of the file. References to assigned variables, such as C<$server>,
are replaced, including the special variable C<$id> for the current identifier.

=item assignements

All lines of the form C<key=value>, where C<key> contains of lowercase letters
a-z only, are treated as variable assignements. In particular, the variable
C<server> is used to set a server (an URL or a PSGI script) and the variable
C<id> can be used to reset the list of identifiers.

=item identifiers

All other non-empty lines are treated as identifiers. Identifiers are not
expected to be URI-encoded.

=back

Every time a response has been read, all preceding identifiers are used to
query the current server and the response is compared with
L<Test::JSON::Entails>. Here is an example of a test suite:

  server=http://example.com/your-daia-server

  # some document ids
  isbn:0486225437
  urn:isbn:0486225437
  http://example.org/this-is-also-an-id

  # the response must contain at least one document with the query id
  { "document" : [
    { "id" : "$id" }
  ] }

See the file C<app.psgi> and C<examples/daia-ubbielefeld.pl> for further
examples of test suites included in server implementations.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
