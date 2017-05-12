#!/usr/bin/perl -w

#
#   POE::Component::Child - Test suite
#   Copyright (C) 2001-2003 Erick Calder
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

$, = " "; $\ = $/;

my $t1 = 5;    		# number of
my $t2 = 5;    		# tests per
my $t3 = 2;         # section
my $t4 = 3;

# $t1 = $t2 = $t3 = 0;

use Cwd; $CWD = cwd();
$SRV = "$CWD/echosrv";
eval "use File::Temp qw/tempdir/";
$t3 = 0 if $@;

eval "use Test::Simple tests => 4 + $t1 + $t2 + $t3 + $t4";

my $debug = $ENV{DEBUG} || 0;
sub POE::Kernel::TRACE_GARBAGE ()  { 1 }
sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE qw(Component::Child Filter::Stream);
ok(1, 'use PoCo::Child'); # If we made it this far, we're ok.

my %t1 = (    				# tests a non-interactive client
    stdout	=> "t1_out",
    stderr	=> "t1_err",
    error	=> "t1_error",
    done	=> "t1_done",
    died	=> "t1_died",
    );

my %t2 = (    				# tests interactive client
    stderr	=> "t2_err",
    error	=> "t2_error",
    died	=> "t2_died",
    );

my %t3 = (
    stdout  => "t3_out",
    );

my %t4 = (
    stderr  => "t4_error",
    died    => "t4_died",
    done    => "t4_done",
    );

my %t = reverse(%t1, %t2, %t3, %t4);

# test non-interactive child

if ($t1) {
    $t1 = POE::Component::Child->new(
    	events => \%t1, debug => $debug
    	);
    ok(defined $t1 && $t1->isa('POE::Component::Child'), "[1] init - non-interactive");
    $t1->run($^X, $SRV, "--stdout");
    }

# test interactive child

if ($t2) {
    $t2 = POE::Component::Child->new(
    	writemap => { quit => "bye" },
    	events => { %t2, done => \&t2_done },
    	debug => $debug
    	);
    ok(defined $t2 && $t2->isa('POE::Component::Child'), "[2] init - interactive");
    $t2->run($^X, $SRV);
    }

# test other stuff

if ($t3) {
    $TMPDIR = tempdir(DIR => cwd(), CLEANUP => 1);
    $t3 = POE::Component::Child->new(
    	events => \%t3, debug => $debug, chdir => $TMPDIR,
    	);
    ok(defined $t3 && $t3->isa('POE::Component::Child'), "[3] init - other");
    $t3->run("pwd");
    }

if ($t4) {
    $t4 = POE::Component::Child->new(
    	events => \%t4, debug => $debug
    	);
    ok(defined $t4 && $t4->isa('POE::Component::Child'), "[4] init - pipe close");
    $t4->run($^X, $SRV);
    }

# create main session

$r = POE::Session->create(
    package_states => [
        main => [ keys %t ]
        ],
    inline_states => {
    	_start => sub {
            $_[KERNEL]->alias_set("main");
            $t2->write("hej");
            $t4->write('hello');
            },
    	_stop => sub { print "_stop" if $debug; },
    	_default => \&_default,
    	}
    );

ok(defined($r), "session created");

# POEtry in motion

POE::Kernel->run();

ok(cwd() eq $CWD, "dir change restored");
ok(1, "all tests successful");

# --- event handlers - non-interactive child ----------------------------------

sub t1_out {
    my ($self, $args) = @_[ARG0 .. $#_];
    local $_ = $args->{out};

    ok(/server/, "[1]: standard output");
    }

sub t1_err {
    my ($self, $args) = @_[ARG0 .. $#_];
    my $err = $args->{out} =~ /server/;
    ok($err, $err ? "[1]: standard error" : "[1]: $args->{out}");
    }

BEGIN { $t1n = 0; }
sub t1_done {
    my ($self, $args) = @_[ARG0 .. $#_];

    if ($t1n++ == 0) {
    	$t1->run($^X, $SRV, "--stderr");
    	}

    else {
    	ok(1, "[1]: done event");
    	$t1->run($^X, $SRV, "--die");
    	}
    }

sub t1_died {
    ok(1, "[1]: died tested");
    }

sub t1_error {
    my ($self, $args) = @_[ARG0 .. $#_];
    ok(0, "[1]: unexpected error: $args->{error}");
    }

# --- event handlers - interactive child --------------------------------------

sub t2_err {
    my ($self, $args) = @_[ARG0 .. $#_];
    ok($args->{out} eq "hej", "[2]: client write tested");
    $t2->quit();
    }

BEGIN { $t2n = 0; }
sub t2_done {
    my ($self, $args) = @_[ARG0 .. $#_];

    if ($t2n++) {
    	ok(0, "[2]: kill problem");
    	return;
    	}

    ok(1, "[2]: callback references");
    ok(1, "[2]: quit method");
    $t2->run($^X, $SRV);
    $t2->kill();
    }

sub t2_died {
    my ($kernel, $self, $args) = @_[KERNEL, ARG0 .. $#_];
    ok(1, "[2]: killed");
    }
    
sub t2_error {
    my ($self, $args) = @_[ARG0 .. $#_];
    ok(0, "[2]: unexpected error: $args->{error}");
    }

sub t3_out {
    my ($self, $args) = @_[ARG0 .. $#_];
    ok($args->{out} eq $TMPDIR, "[3]: dir change");
    }

sub t4_error {
    my ($self, $args) = @_[ARG0 .. $#_];
    ok($args->{out} eq "hello", "[4]: child talks");
    $self->quit();
    }

sub t4_died {
    ok(1, "[4]: stdout closed");
    }

sub t4_done {
    ok(1, "[5]: done");
    }

sub _default {
    return unless $debug;
    print qq/> _default: "$_[ARG0]" event, args: @{$_[ARG1]}/;
    exit if $_[ARG1][0] eq "INT";
    }
