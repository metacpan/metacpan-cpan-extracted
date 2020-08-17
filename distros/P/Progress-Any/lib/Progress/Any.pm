package Progress::Any;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-07-10'; # DATE
our $DIST = 'Progress-Any'; # DIST
our $VERSION = '0.218'; # VERSION

use 5.010001;
use strict;
use warnings;

use Time::Duration qw();
use Time::HiRes qw(time);

sub import {
    my ($self, @args) = @_;
    my $caller = caller();
    for (@args) {
        if ($_ eq '$progress') {
            my $progress = $self->get_indicator(task => '');
            {
                no strict 'refs';
                my $v = "$caller\::progress";
                *$v = \$progress;
            }
        } else {
            die "Unknown import argument: $_";
        }
    }
}

# store Progress::Any objects for each task
our %indicators;  # key = task name

# store output objects
our %outputs;     # key = task name, value = [$outputobj, ...]

# internal attributes:
# - _elapsed (float*) = accumulated elapsed time so far
# - _start_time (float) = when is the last time the indicator state is changed
#     from 'stopped' to 'started'. when indicator is changed from 'started' to
#     'stopped', this will be set to undef.
# - _remaining = used to store user's estimation of remaining time. will be
#     unset after each update().

# return 1 if created, 0 if already created/initialized
sub _init_indicator {
    my ($class, $task, $default_target) = @_;

    #say "D: _init_indicator($task)";

    # prevent double initialization
    return $indicators{$task} if $indicators{$task};

    my $progress = bless({
        task        => $task,
        title       => $task,
        target      => $default_target,
        pos         => 0,
        state       => 'stopped',

        _remaining          => undef,
        _set_remaining_time => undef,
        _elapsed            => 0,
        _start_time         => 0,
    }, $class);
    $indicators{$task} = $progress;

    # if we create an indicator named a.b.c, we must also create a.b, a, and ''.
    if ($task =~ s/\.?\w+\z//) {
        $class->_init_indicator($task, 0);
    }

    $progress;
}

sub get_indicator {
    my ($class, %args) = @_;

    my %oargs = %args;

    my $task   = delete($args{task});
    if (!defined($task)) {
        my @caller = caller(0);
        #say "D:caller=".join(",",map{$_//""} @caller);
        $task = $caller[0] eq '(eval)' ? 'main' : $caller[0];
        $task =~ s/::/./g;
        $task =~ s/[^.\w]+/_/g;
    }
    die "Invalid task syntax '$task', please only use dotted words"
        unless $task =~ /\A(?:\w+(\.\w+)*)?\z/;

    my %uargs;

    my $p = $class->_init_indicator($task);
    for my $an (qw/title target pos remaining state/) {
        if (exists $args{$an}) {
            $uargs{$an} = delete($args{$an});
        }
    }
    die "Unknown argument(s) to get_indicator(): ".join(", ", keys(%args))
        if keys(%args);
    $p->_update(%uargs) if keys %uargs;

    $p;
}

my %attrs = (
    title     => {is => 'rw'},
    target    => {is => 'rw'},
    pos       => {is => 'rw'},
    state     => {is => 'rw'},
);

# create attribute methods
for my $an (keys %attrs) {
    next if $attrs{$an}{manual};
    my $code;
    if ($attrs{$an}{is} eq 'rw') {
        $code = sub {
            my $self = shift;
            if (@_) {
                $self->_update($an => shift);
            }
            $self->{$an};
        };
    } else {
        $code = sub {
            my $self = shift;
            die "Can't set value, $an is an ro attribute" if @_;
            $self->{$an};
        };
    }
    no strict 'refs';
    *{$an} = $code;
}

sub elapsed {
    my $self = shift;

    if ($self->{state} eq 'started') {
        return $self->{_elapsed} + (time()-$self->{_start_time});
    } else {
        return $self->{_elapsed};
    }
}

sub total_pos {
    my $self = shift;

    my $t = $self->{task};

    my $res = $self->{pos};
    for (keys %indicators) {
        if ($t eq '') {
            next if $_ eq '';
        } else {
            next unless index($_, "$t.") == 0;
        }
        $res += $indicators{$_}{pos};
    }
    $res;
}

sub total_target {
    my $self = shift;

    my $t = $self->{task};

    my $res = $self->{target};
    return undef unless defined($res);

    for (keys %indicators) {
        if ($t eq '') {
            next if $_ eq '';
        } else {
            next unless index($_, "$t.") == 0;
        }
        return undef unless defined $indicators{$_}{target};
        $res += $indicators{$_}{target};
    }
    $res;
}

sub percent_complete {
    my $self = shift;

    my $total_pos    = $self->total_pos;
    my $total_target = $self->total_target;

    return undef unless defined($total_target);
    if ($total_target == 0) {
        if ($self->{state} eq 'finished') {
            return 100;
        } else {
            return 0;
        }
    } else {
        return $total_pos / $total_target * 100;
    }
}

sub remaining {
    my $self = shift;

    if (defined $self->{_remaining}) {
        if ($self->{state} eq 'started') {
            my $r = $self->{_remaining}-(time()-$self->{_set_remaining_time});
            return $r > 0 ? $r : 0;
        } else {
            return $self->{_remaining};
        }
    } else {
        if (defined $self->{target}) {
            if ($self->{pos} == 0) {
                return 0;
            } else {
                return ($self->{target} - $self->{pos})/$self->{pos} *
                    $self->elapsed;
            }
        } else {
            return undef;
        }
    }
}

sub total_remaining {
    my $self = shift;

    my $t = $self->{task};

    my $res = $self->remaining;
    return undef unless defined $res;

    for (keys %indicators) {
        if ($t eq '') {
            next if $_ eq '';
        } else {
            next unless index($_, "$t.") == 0;
        }
        my $res2 = $indicators{$_}->remaining;
        return undef unless defined $res2;
        $res += $res2;
    }
    $res;
}

# the routine to use to update rw attributes, does validation and checks to make
# sure things are consistent.
sub _update {
    my ($self, %args) = @_;

    # no need to check for unknown arg in %args, it's an internal method anyway

    my $now = time();

    my $task = $self->{task};
    #use Data::Dump; print "D: _update($task) "; dd \%args;

  SET_TITLE:
    {
        last unless exists $args{title};
        my $val = $args{title};
        die "Invalid value for title, must be defined"
            unless defined($val);
        $self->{title} = $val;
    }

  SET_TARGET:
    {
        last unless exists $args{target};
        my $val = $args{target};
        die "Invalid value for target, must be a positive number or undef"
            unless !defined($val) || $val >= 0;
        # ensure that pos does not exceed target
        if (defined($val) && $self->{pos} > $val) {
            $self->{pos} = $val;
        }
        $self->{target} = $val;
        undef $self->{_remaining};
    }

  SET_POS:
    {
        last unless exists $args{pos};
        my $val = $args{pos};
        die "Invalid value for pos, must be a positive number"
            unless defined($val) && $val >= 0;
        # ensure that pos does not exceed target
        if (defined($self->{target}) && $val > $self->{target}) {
            $val = $self->{target};
        }
        $self->{pos} = $val;
        undef $self->{_remaining};
    }

  SET_REMAINING:
    {
        last unless exists $args{remaining};
        my $val = $args{remaining};
        die "Invalid value for remaining, must be a positive number"
            unless defined($val) && $val >= 0;
        $self->{_remaining} = $val;
        $self->{_set_remaining_time} = $now;
    }

  SET_STATE:
    {
        last unless exists $args{state};
        my $old = $self->{state};
        my $val = $args{state} // 'started';
        die "Invalid value for state, must be stopped/started/finished"
            unless $val =~ /\A(?:stopped|started|finished)\z/;
        last if $old eq $val;
        if ($val eq 'started') {
            $self->{_start_time} = $now;

            # automatically start parents
            my @parents;
            {
                my $t = $task;
                while (1) {
                    last unless $t =~ s/\.\w+\z//;
                    push @parents, $t;
                }
                push @parents, '';
            }
            for my $t (@parents) {
                my $p = $indicators{$t};
                if ($p->{state} ne 'started') {
                    $p->{state}       = 'started';
                    $p->{_start_time} = $now;
                }
            }
        } else {
            $self->{_elapsed} += $now - $self->{_start_time};
            if ($val eq 'finished') {
                die "BUG: Can't finish task '$task', pos is still < target"
                    if defined($self->{target}) &&
                        $self->{pos} < $self->{target};
                $self->{_remaining} = 0;
                $self->{_set_remaining_time} = $now;
            }
        }
        $self->{state} = $val;
    }

  DONE:
    #use Data::Dump; print "after update: "; dd $self;
    return;
}

sub _should_update_output {
    my ($self, $output, $now, $priority) = @_;

    my $key = "$output";
    if (!defined($output->{_mtime})) {
        # output has never been updated, update
        return 1;
    } elsif ($self->{state} eq 'finished') {
        # finishing, update the output to show finished state
        return 1;
    } elsif ($output->{force_update}) {
        # this is an undocumented force update for now, the output itself or
        # something else can set this to force an update. but this will only be
        # done once because we delete the key; if another update wants to be
        # forced, they need to set this again.
        delete $output->{force_update};
        return 1;
    } elsif ($priority eq 'high') {
        # high priority, send to output module
        return 1;
    } else {
        # normal-/low-priority update, update if not too frequent
        if (!defined($output->{freq})) {
            # negative number means seconds, positive means pos delta. only
            # update if that number of seconds, or that difference in pos has
            # been passed.
            $output->{freq} = -0.5;
        }
        if ($output->{freq} == 0) {
            return 1;
        } if ($output->{freq} < 0) {
            return 1 if $now >= $output->{_mtime} - $output->{freq};
        } else {
            return 1 if abs($self->{pos} - $output->{_pos}) >= $output->{freq};
        }
        return 0;
    }
}

sub update {
    my ($self, %args) = @_;

    my $pos   = delete($args{pos}) // $self->{pos} + 1;
    my $state = delete($args{state}) // 'started';
    $self->_update(pos => $pos, state => $state);

    my $message  = delete($args{message});
    my $priority = delete($args{priority}) // 'normal';
    my $force_update = delete($args{force_update});
    die "Unknown argument(s) to update(): ".join(", ", keys(%args))
        if keys(%args);

    my $now = time();

    # find output(s) and call it
    {
        last unless $ENV{PROGRESS} // 1;
        my $task = $self->{task};
        while (1) {
            if ($outputs{$task}) {
                for my $output (@{ $outputs{$task} }) {
                    next unless $force_update ||
                        $self->_should_update_output($output, $now, $priority);
                    if (ref($message) eq 'CODE') {
                        $message = $message->();
                    }
                    $output->update(
                        indicator => $indicators{$task},
                        message   => $message,
                        priority  => $priority,
                        time      => $now,

                        # temporary, internal API. to let an output module know
                        # the same update() when there are multiple instances of
                        # it
                        _update_id => $now,
                    );
                    $output->{_mtime} = $now;
                    $output->{_pos}   = $pos;
                }
            }
            last unless $task =~ s/\.?\w+\z//;
        }
    }
}

sub start {
    my $self = shift;
    $self->_update(state => 'started');
}

sub stop {
    my $self = shift;
    $self->_update(state => 'stopped');
}

sub finish {
    my ($self, %args) = @_;
    $self->update(pos=>$self->{target}, state=>'finished', %args);
}

sub reset {
    my ($self, %args) = @_;
    $self->update(pos=>0, state=>'started', %args);
}

our $template_regex = qr{( # all=1
                             %
                             ( #width=2
                                 -?\d+ )?
                             ( #dot=3
                                 \.?)
                             ( #prec=4
                                 \d+)?
                             ( #conv=5
                                 [A-Za-z%])
                         )}x;

sub fill_template {
    my ($self, $template0, %args) = @_;

    # TODO: some caching so "%e%e" produces two identical numbers

    my ($template, $opts);
    if (ref $template0 eq 'HASH') {
        $opts = $template0;
        $template = $opts->{template};
    } else {
        $template = $template0;
        $opts = {};
    }

    state $sub = sub {
        my %args = @_;

        my ($all, $width, $dot, $prec, $conv) = ($1, $2, $3, $4, $5);

        my $p = $args{indicator};

        my ($fmt, $sconv, $data);
        if ($conv eq 'n') {
            $data = $p->{task};
        } elsif ($conv eq 't') {
            $data = $p->{title};
        } elsif ($conv eq '%') {
            $data = '%';
        } elsif ($conv eq 'm') {
            $data = $args{message} // '';
        } elsif ($conv eq 'p') {
            my $val = $p->percent_complete;
            $width //= 3;
            if (defined $val) {
                $data = $val;
                $prec //= 0;
                $sconv = "f";
            } else {
                $data = '?';
            }
        } elsif ($conv eq 'P') {
            $data = $p->total_pos;
            $prec //= 0;
            $sconv = "f";
        } elsif ($conv eq 'T') {
            my $val = $p->total_target;
            if (defined $val) {
                $data = $val;
                $prec //= 0;
                $sconv = "f";
            } else {
                $data = '?';
            }
        } elsif ($conv eq 'e') {
            my $val = $p->elapsed;
            $val = 1 if $val < 1; # TMP, prevent duration() return "just now"
            $data = Time::Duration::concise(Time::Duration::duration($val));
            $width //= -8;
        } elsif ($conv eq 'r') {
            my $val = $p->total_remaining;
            if (defined $val) {
                $val = 1 if $val < 1; # TMP, prevent duration() return "just now
                $data = Time::Duration::concise(Time::Duration::duration($val));
            } else {
                $data = '?';
            }
            $width //= -8;
        } elsif ($conv eq 'R') {
            my $val = $p->total_remaining;
            if (defined $val) {
                $val = 1 if $val < 1; # TMP, prevent duration() return "just now
                $data = Time::Duration::concise(Time::Duration::duration($val)).
                    " left"; # XXX i18n
            } else {
                $val = $p->elapsed;
                $val = 1 if $val < 1; # TMP, prevent duration() return "just now
                $data = Time::Duration::concise(Time::Duration::duration($val)).
                    " elapsed"; # XXX i18n
            }
            $width //= -(8 + 1 + 7);
        } else {
            if ($opts->{handle_unknown_conversion}) {
                my @res = $opts->{handle_unknown_conversion}->(
                    indicator => $p,
                    args  => \%args,

                    all   => $all,
                    width => $width,
                    dot   => $dot,
                    conv  => $conv,
                    prec  => $prec,
                );
                if (@res) {
                    ($fmt, $data) = @res;
                } else {
                # return as-is
                    $fmt = '%s';
                    $data = $all;
                }
            } else {
                # return as-is
                $fmt = '%s';
                $data = $all;
            }
        }

        # sprintf format
        $sconv //= 's';
        $dot = "." if $sconv eq 'f';
        $fmt //= join("", grep {defined} ("%", $width, $dot, $prec, $sconv));

        #say "D:fmt=$fmt";
        sprintf $fmt, $data;
    };
    $template =~ s{$template_regex}{$sub->(%args, indicator=>$self)}egox;

    $template;
}

1;
# ABSTRACT: Record progress to any output

__END__

=pod

=encoding UTF-8

=head1 NAME

Progress::Any - Record progress to any output

=head1 VERSION

This document describes version 0.218 of Progress::Any (from Perl distribution Progress-Any), released on 2020-07-10.

=head1 SYNOPSIS

Example of using in a script with terminal progress bar as output (progress bar
will be cleared on C<finish()>):

 use Progress::Any '$progress';
 use Progress::Any::Output 'TermProgressBarColor';

 $progress->target(10);
 for (1..10) {
     $progress->update(message => "Doing item $_");
     sleep 1;
 }
 $progress->finish();

Sample output:

 % ./script.pl
  60% [Doing item 6====           ]3s left

Another example, this time with terminal message as output:

 use Progress::Any '$progress';
 use Progress::Any::Output 'TermMessage', template => '[%n] %P/%T (%6.2p%%) %m';

 $progress->target(10);
 for (1..10) {
     $progress->update(message => "Item $_/10");
     sleep 1;
 }
 sleep 1;
 $progress->finish(message => "Finished!");

Sample output:

 % ./script.pl
 [] 1/10 ( 10.00%) Item 1/10
 [] 2/10 ( 20.00%) Item 2/10
 ...
 [] 10/10 (100.00%) Item 10/10
 [] 10/10 (100.00%) Finished!

Example of using in a module as well as script:

 # in lib/MyApp.pm
 package MyApp;
 use Progress::Any;

 sub download {
     my @urls = @_;
     return unless @urls;
     my $progress = Progress::Any->get_indicator(
         task => "download", pos=>0, target=>~~@urls);
     for my $url (@urls) {
         # download the $url ...
         $progress->update(message => "Downloaded $url");
     }
     $progress->finish;
 }

 # in script.pl
 use MyApp;
 use Progress::Any::Output;
 Progress::Any::Output->set('TermProgressBarColor');

 MyApp::download("url1", "url2", "url3", "url4", "url5");

Sample output:

 % ./script.pl
  20% [====== Downloaded url1           ]0m00s Left

Example that demonstrates multiple indicator objects:

 use Progress::Any;
 use Progress::Any::Output;

 my $pdl = Progress::Any->get_indicator(task => 'download');
 Progress::Any::Output->set({task=>'download'}, 'TermMessage', template => '[%-8t] [%P/%2T] %m');
 my $pcp = Progress::Any->get_indicator(task => 'copy');
 Progress::Any::Output->set({task=>'copy'    }, 'TermMessage', template => '[%-8t] [%P/%2T] %m');

 $pdl->target(10);
 $pdl->update(message => "downloading A");
 $pcp->update(message => "copying A");
 sleep 1;
 $pdl->update(message => "downloading B");
 $pcp->update(message => "copying B");

will show something like:

 [download] [1/10] downloading A
 [copy    ] [1/ ?] copying A
 [download] [2/10] downloading B
 [copy    ] [2/ ?] copying B

=head2 Example of using with Perinci::CmdLine

If you use L<Perinci::CmdLine>, you can mark your function as expecting a
Progress::Any object and it will be supplied to you in a special argument
C<-progress>:

 use File::chdir;
 use Perinci::CmdLine;
 $SPEC{check_dir} = {
     v => 1.1,
     args => {
         dir => {summary=>"Path to check", schema=>"str*", req=>1, pos=>0},
     },
     features => {progress=>1},
 };
 sub check_dir {
     my %args = @_;
     my $progress = $args{-progress};
     my $dir = $args{dir};
     (-d $dir) or return [412, "No such dir: $dir"];
     local $CWD = $dir;
     opendir my($dh), $dir;
     my @ent = readdir($dh);
     $progress->pos(0);
     $progress->target(~~@ent);
     for (@ent) {
         # do the check ...
         $progress->update(message => $_);
         sleep 1;
     }
     $progress->finish;
     [200];
 }
 Perinci::CmdLine->new(url => '/main/check_dir')->run;

=head1 DESCRIPTION

C<Progress::Any> is an interface for applications that want to display progress
to users. It decouples progress updating and output, rather similar to how
L<Log::Any> decouples log producers and consumers (output). The API is also
rather similar to Log::Any, except I<Adapter> is called I<Output> and
I<category> is called I<task>.

Progress::Any records position/target and calculates elapsed time, estimated
remaining time, and percentage of completion. One or more output modules
(Progress::Any::Output::*) display this information.

In your modules, you typically only need to use Progress::Any, get one or more
indicators, set target and update it during work. In your application, you use
Progress::Any::Output and set/add one or more outputs to display the progress.
By setting output only in the application and not in modules, you separate the
formatting/display concern from the logic.

Screenshots:

=head1 STATUS

API might still change, will be stabilized in 1.0.

=begin HTML

<p><img src="http://blogs.perl.org/users/perlancar/progany-tpc-sample.jpg" /><br />Using TermProgressBarColor output

<p><img src="http://blogs.perl.org/users/perlancar/progany-dn-sample.jpg" /><br />Using DesktopNotify output

=end HTML

The list of features:

=over

=item * multiple progress indicators

You can use different indicator for each task/subtask.

=item * customizable output

Output is handled by one of C<Progress::Any::Output::*> modules. Currently
available outputs: C<Null> (no output), C<TermMessage> (display as simple
message on terminal), C<TermProgressBarColor> (display as color progress bar on
terminal), C<LogAny> (log using L<Log::Any>), C<Callback> (call a subroutine).
Other possible output ideas: IM/Twitter/SMS, GUI, web/AJAX, remote/RPC (over
L<Riap> for example, so that L<Perinci::CmdLine>-based command-line clients can
display progress update from remote functions).

=item * multiple outputs

One or more outputs can be used to display one or more indicators.

=item * hierarchical progress

A task can be divided into subtasks. If a subtask is updated, its parent task
(and its parent, and so on) are also updated proportionally.

=item * message

Aside from setting a number/percentage, allow including a message when updating
indicator.

=item * undefined target

Target can be undefined, so a bar output might not show any bar (or show them,
but without percentage indicator), but can still show messages.

=item * retargetting

Target can be changed in the middle of things.

=back

=head1 EXPORTS

=head2 $progress => OBJ

The root indicator. Equivalent to:

 Progress::Any->get_indicator(task => '')

=head1 ATTRIBUTES

Below are the attributes of an indicator/task:

=head2 task

String. Default: from caller's package, or C<main>.

Task name. If not specified will be set to caller's package (C<::> will be
replaced with C<.>), e.g. if you are calling this method from
C<Foo::Bar::baz()>, then task will be set to C<Foo.Bar>. If caller is code
inside eval, C<main> will be used instead.

=head2 title

String. Default: task name.

Specify task title. Task title is a longer description for a task and can
contain spaces and other characters. It is displayed in some outputs, as well as
using C<%t> in C<fill_template()>. For example, for a task called C<copy>, its
title might be C<Copying files to remote server>.

=head2 target

Non-negative number. Default: 0.

The total number of items to finish. Can be set to undef to mean that we don't
know (yet) how many items there are to finish (in which case, we cannot estimate
percent of completion and remaining time).

=head2 pos

Non-negative number. Default: 0.

The number of items that are already done. It cannot be larger than C<target>,
if C<target> is defined. If C<target> is set to a value smaller than C<pos> or
C<pos> is set to a value larger than C<target>, C<pos> will be changed to be
C<target>.

=head2 state

String. Default: C<stopped>.

State of task/indicator. Either: C<stopped>, C<started>, or C<finished>.
Initially it will be set to C<stopped>, which means elapsed time won't be
running and will stay at 0. C<update()> will set the state to C<started> to get
elapsed time to run. At the end of task, you can call C<finish()> (or
alternatively set C<state> to C<finished>) to stop the elapsed time again.

The difference between C<stopped> and C<finished> is: when C<target> and C<pos>
are both at 0, percent completed is assumed to be 0% when state is C<stopped>,
but 100% when state is C<finished>.

=head1 METHODS

=head2 get_indicator

Usage:

 Progress::Any->get_indicator(%args) => obj

Get a progress indicator for a certain task. C<%args> contain attribute values,
at least C<task> must be specified.

Note that this module maintains a list of indicator singleton objects for each
task (in C<%indicators> package variable), so subsequent C<get_indicator()> for
the same task will return the same object.

=head2 update

Usage:

 $progress->update(%args)

Update indicator. Will also, usually, update associated output(s) if necessary.

Arguments:

=over

=item * pos => NUM

Set the new position. If unspecified, defaults to current position + 1. If pos
is larger than target, outputs will generally still show 100%. Note that
fractions are allowed.

=item * message => str|code

Set a message to be displayed when updating indicator.

Aside from a string, you can also pass a coderef here. It can be used to delay
costly calculation. The message will only be calculated when actually sent to
output.

=item * priority => str ("normal"|"low"|"high", default: "normal")

Set importance level of this update. Default is C<normal>. Output can choose to
ignore updates lower than a certain level.

=item * state => STR

Can be set to C<finished> to finish a task.

=item * force_update => BOOL

Default false. Some outputs choose only to update themselves after a certain
amount of time or number of updates have passed; this forces their update.

=back

=head2 finish

Usage:

 $progress->finish(%args)

Equivalent to:

 $progress->update(
     ( pos => $progress->target ) x !!defined($progress->target),
     state => 'finished',
     %args,
 );

=head2 reset

Usage:

 $progress->reset(%args)

Equivalent to:

 $progress->update(
     pos => 0,
     state => 'started',
     %args,
 );

=head2 start

Usage:

 $progress->start()

Set state to C<started>.

=head2 stop

Usage:

 $progress->stop()

Set state to C<stopped>.

=head2 elapsed

Usage:

 $progress->elapsed() => float

Get elapsed time. Just like a stop-watch, when state is C<started> elapsed time
will run and when state is C<stopped>, it will freeze.

=head2 remaining

Usage:

 $progress->remaining() => undef|float

Give estimated remaining time until task is finished, which will depend on how
fast the C<update()> is called, i.e. how fast C<pos> is approaching C<target>.
Will be undef if C<target> is undef.

=head2 total_remaining

Usage:

 $progress->total_remaining() => undef|FLOAT

Give estimated remaining time added by all its subtasks' remaining. Return undef
if any one of those time is undef.

=head2 total_pos

Usage:

 $progress->total_pos() => float

Total of indicator's pos and all of its subtasks'.

=head2 total_target

Usage:

 $progress->total_target() => undef|float

Total of indicator's target and all of its subtasks'. Return undef if any one of
those is undef.

=head2 percent_complete

Usage:

 $progress->percent_complete() => undef|float

Give percentage of completion, calculated using C<< total_pos / total_target *
100 >>. Undef if total_target is undef.

=head2 fill_template

Usage:

 $progress->fill_template($template) => str

Fill template with values, like in C<sprintf()>. Usually used by output modules.
Available templates:

=over

=item * C<%(width)n>

Task name (the value of the C<task> attribute). C<width> is optional, an
integer, like in C<sprintf()>, can be negative to mean left-justify instead of
right.

=item * C<%(width)t>

Task title (the value of the C<title> attribute).

=item * C<%(width)e>

Elapsed time (the result from the C<elapsed()> method). Currently using
L<Time::Duration> concise format, e.g. 10s, 1m40s, 16m40s, 1d4h, and so on.
Format might be configurable and localizable in the future. Default width is -8.
Examples:

 2m30s
 10s

=item * C<%(width)r>

Estimated remaining time (the result of the C<total_remaining()> method).
Currently using L<Time::Duration> concise format, e.g. 10s, 1m40s, 16m40s, 1d4h,
and so on. Will show C<?> if unknown. Format might be configurable and
localizable in the future. Default width is -8. Examples:

 1m40s
 5s

=item * C<%(width)R>

Estimated remaining time I<or> elapsed time, if estimated remaining time is not
calculatable (e.g. when target is undefined). Format might be configurable and
localizable in the future. Default width is -(8+1+7). Examples:

 30s left
 1m40s elapsed

=item * C<%(width).(prec)p>

Percentage of completion (the result of the C<percent_complete()> method).
C<width> and C<precision> are optional, like C<%f> in Perl's C<sprintf()>,
default is C<%3.0p>. If percentage is unknown (due to target being undef), will
show C<?>.

=item * C<%(width)P>

Current position (the result of the C<total_pos()> method).

=item * C<%(width)T>

Target (the result of the C<total_target()> method). If undefined, will show
C<?>.

=item * C<%m>

Message (the C<update()> parameter). If message is unspecified, will show empty
string.

=item * C<%%>

A literal C<%> sign.

=back

=head1 FAQ

=head1 ENVIRONMENT

=head2 PROGRESS

Boolean. Default 1. Can be set to 0 to display progress output.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Progress-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Progress-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Progress-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Progress::Any::Examples> distribution contains example scripts.

Other progress modules on CPAN: L<Term::ProgressBar>,
L<Term::ProgressBar::Simple>, L<Time::Progress>, among others.

Output modules: C<Progress::Any::Output::*>

See examples on how Progress::Any is used by other modules: L<Perinci::CmdLine>
(supplying progress object to functions), L<Git::Bunch> (using progress object).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
