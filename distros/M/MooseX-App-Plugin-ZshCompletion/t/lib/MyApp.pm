use strict;
use warnings;
use 5.010;

package MyApp;

use MooseX::App qw/ BashCompletion ZshCompletion /;

option 'verbose' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[be verbose],
); # Global option

has 'private' => ( 
    is              => 'rw',
); # not exposed

package MyApp::FetchMail;
use MooseX::App::Command; # important (also imports Moose)
extends qw(MyApp); # optional, only if you want to use global options from base class

use Moose::Util::TypeConstraints;

enum 'MailserverType', [qw(IMAP POP3)];

# Positional parameter
parameter 'server' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[Mailserver],
);

option 'servertype' => (
    is            => 'rw',
    isa           => 'MailserverType',
    required      => 1,
    documentation => q[Mailserver type: IMAP or POP3],
);

option 'max' => (
    is            => 'rw',
    isa           => 'Int',
    required      => 1,
    documentation => q[Maximum number of emails to fetch],
); # Option

option 'dir' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => q[Output 'dir'],
); # Option

option 'user' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[User],
); # Option

sub run {
    my ($self) = @_;
    # Do something
    my $server = $self->server;
    my $max = $self->max;
    if ($self->verbose) {
        say "Connecting to $server...";
        say "Fetching up to $max emails...";
    }
    my $count = int rand 150;
    $count = $max if $count >= $max;
    say "Fetched $count emails";
}

package MyApp::Lala;
use MooseX::App::Command; # important (also imports Moose)
extends qw(MyApp); # optional, only if you want to use global options from base class

use Moose::Util::TypeConstraints;

enum 'FooBar', [qw(foo bar boo)];

parameter 'bar' => (
    is            => 'rw',
    isa           => 'FooBar',
    required      => 1,
    cmd_position  => 2,
    documentation => q[bar],
);

parameter 'boo' => (
    is            => 'rw',
    isa           => 'FooBar',
    required      => 1,
    cmd_position  => 3,
    documentation => q[boo],
);

parameter 'foo' => (
    is            => 'rw',
    isa           => 'FooBar',
    required      => 1,
    cmd_position  => 1,
    documentation => q[foo],
);


sub run {
    my ($self) = @_;
    say sprintf "foo: %s, bar:%s, boo: %s", $self->foo, $self->bar, $self->boo;
}


1;
