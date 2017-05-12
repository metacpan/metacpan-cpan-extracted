##
# name:      Mo::Benchmarks
# abstract:  Benchmarks for Moose Family Modules
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

use 5.010;

use Mouse 0.93 ();
use MouseX::App::Cmd 0.08 ();

#------------------------------------------------------------------------------#
package Mo::Benchmarks;

our $VERSION = '0.10';

#------------------------------------------------------------------------------#
package Mo::Benchmarks::Command;
use App::Cmd::Setup -command;
use Mouse;
extends 'MouseX::App::Cmd::Command';

sub validate_args {}

# Semi-brutal hack to suppress extra options I don't care about.
around usage => sub {
    my $orig = shift;
    my $self = shift;
    my $opts = $self->{usage}->{options};
    @$opts = grep { $_->{name} ne 'help' } @$opts;
    return $self->$orig(@_);
};

#-----------------------------------------------------------------------------#
package Mo::Benchmarks;
use App::Cmd::Setup -app;
use Mouse;
extends 'MouseX::App::Cmd';

use Module::Pluggable
  require     => 1,
  search_path => [ 'Mo::Benchmarks::Command' ];
Mo::Benchmarks->plugins;

#------------------------------------------------------------------------------#
package Mo::Benchmarks::Command::constructor;
Mo::Benchmarks->import( -command );
use Mouse;
extends 'Mo::Benchmarks::Command';

use Benchmark ':all';

use constant abstract => 'Run constructor benchmarks';
use constant usage_desc =>
    'mo-benchmarks constructor --count=1000000 Moose Mouse Moo Mo';

has count => (
    is => 'ro',
    isa => 'Num',
    documentation => 'Number of times to run a test',
);

sub execute {
    my ($self, $opt, $args) = @_;
    my @mo = map lc, grep !/^--/, @$args;
    @mo = qw'mo moo mouse moose' unless @mo;
    my $tests = {
        map {
            my $t = $_;
            my $l = lc($t);
            my $m =
            eval <<"...";
package $l;
use $t;
has good => (is => 'ro');
has bad => (is => 'ro');
has ugly => (is => 'rw');
$l->new(good => 'Perl', bad => 'Python', ugly => 'Ruby');
...
            my $v = do { no strict 'refs'; ${$t."::VERSION"} };
            ($l => [ "$t $v" =>
                sub {
#                     my $m =
                    $l->new(good => 'Perl', bad => 'Python', ugly => 'Ruby');
#                     $m->good;
#                     $m->bad;
#                     $m->ugly;
#                     $m->ugly('Bunny');
                }
            ])
        } qw(Mo Moo Mouse Moose)
    };

    my $count = $self->count || 1000;
    my $num = 1;
    timethese($count, {
        map {
            (
                $num++ . ") $_->[0]",
                $_->[1]
            )
        } map $tests->{$_}, @mo
    });
}

#------------------------------------------------------------------------------#
package Mo::Benchmarks::Command;

# Common subroutines:

1;

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...
