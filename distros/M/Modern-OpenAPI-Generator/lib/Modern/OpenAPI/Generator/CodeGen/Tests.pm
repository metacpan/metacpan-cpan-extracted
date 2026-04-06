package Modern::OpenAPI::Generator::CodeGen::Tests;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);

sub generate {
    my ( $class, %arg ) = @_;
    my $writer = $arg{writer}   // croak 'writer';
    my $base   = $arg{base}     // croak 'base';

    my $client  = $arg{client}  // 1;
    my $server  = $arg{server}  // 1;
    my $ui      = $arg{ui}      // 1;
    my $sync    = $arg{sync}    // 1;
    my $async   = $arg{async}   // 1;
    my $sigs    = $arg{signatures} // [];
    my $ui_only    = $arg{ui_only}    // 0;
    my $local_test = $arg{local_test} // 0;

    my @use;
    push @use, "use_ok q($base\::Client::Core);"       if $client;
    push @use, "use_ok q($base\::Client::Result);"     if $client;
    push @use, "use_ok q($base\::Client::Ops);"        if $client;
    push @use, "use_ok q($base\::Client::Sync);"       if $client && $sync;
    push @use, "use_ok q($base\::Client::Async);"     if $client && $async;
    push @use, "use_ok q($base\::Server);" if $server || $ui_only;
    push @use, "use_ok q($base\::Server::Controller);" if $server && !$ui_only;
    push @use, "use_ok q($base\::StubData);" if $server && $local_test && !$ui_only;

    for my $sig (@$sigs) {
        if ( $sig eq 'hmac' ) {
            push @use, "use_ok q($base\::Auth::Plugin::Hmac);";
        }
        elsif ( $sig eq 'bearer' ) {
            push @use, "use_ok q($base\::Auth::Plugin::Bearer);";
        }
    }

    my $content;
    if (!@use) {
        $content = <<'T';
# Tests for generated modules (not for Modern::OpenAPI::Generator).
use v5.26;
use strict;
use warnings;
use Test::More;
plan skip_all => 'no modules selected for this output (--no-client --no-server --no-ui)';
T
    }
    else {
        my $use_block = join "\n", @use;
        $content = <<"T";
# Tests for generated modules (not for Modern::OpenAPI::Generator).
# From the generated project root:  prove -l t

use v5.26;
use strict;
use warnings;
use Test::More;

use FindBin qw(\$Bin);
use File::Spec;

BEGIN {
  unshift \@INC, File::Spec->catdir( \$Bin, File::Spec->updir, 'lib' );
}

$use_block

done_testing;
T
    }

    $writer->write( 't/00-load-generated.t', $content );
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator::CodeGen::Tests - Generate F<t/00-load-generated.t> for output tree

=head1 DESCRIPTION

Smoke C<use_ok> tests for the modules that were actually generated (client,
server, auth stubs, etc.).

=head2 generate

Class method. Passes through the same feature flags as the main generator.

=cut
