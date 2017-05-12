#!/usr/bin/env perl
package Prophet::CLI::Command::Shell;
{
  $Prophet::CLI::Command::Shell::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::CLI::Command';
use File::Spec;
use Prophet::Util;
use Text::ParseWords qw(shellwords);
use Scalar::Util qw(weaken);

has name => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { Prophet::Util->updir($0) }
);

has term => (
    is      => 'ro',
    isa     => 'Term::ReadLine::Stub',
    lazy    => 1,
    handles => [qw/readline addhistory/],
    default => sub {
        my $self     = shift;
        my $weakself = $self;
        weaken($weakself);

        require Term::ReadLine;
        my $term = Term::ReadLine->new("Prophet shell");
        $term->Attribs->{completion_function} = sub {
            $weakself->_complete(@_);
        };
        return $term;
    },
);

our $HIST = $ENV{PROPHET_HISTFILE}
  || ( ( $ENV{HOME} || ( getpwuid($<) )[7] ) . "/.prophetreplhist" );
our $LEN = $ENV{PROPHET_HISTLEN} || 500;

sub usage_msg {
    my $self = shift;
    my $cmd  = $self->cli->get_script_name;

    return <<"END_USAGE";
usage: ${cmd}\[shell]
END_USAGE
}

sub prompt {
    my $self = shift;
    return $self->name . '> ';
}

sub preamble {
    return join "\n",
      "Prophet $Prophet::VERSION",
      'Type "help", "about", or "copying" for more information.',
      ;
}

sub read {
    my $self = shift;
    Prophet::CLI->end_pager;    # in case a previous command died
    $self->readline( $self->prompt );
}

sub eval {
    my $self = shift;
    my $line = shift;

    eval {
        local $SIG{__DIE__} = 'DEFAULT';
        my @args = shellwords($line);
        $self->cli->run_one_command(@args);
    };
    warn $@ if $@;
}

sub _run {
    my $self = shift;
    Prophet::CLI->end_pager;

    local $| = 1;

    print $self->preamble . "\n";

    # we don't want to run the pager for the shell

    $self->cli->interactive_shell(1);
    while ( defined( my $cmd = $self->read ) ) {
        next if $cmd =~ /^\s*$/;

        last
          if $cmd =~ /^\s*q(?:uit)?\s*$/i
          || $cmd =~ /^\s*exit\s*$/i;

        $self->eval($cmd);
    }
}

sub _complete {
    my ( $self, $last_word, $line, $start ) = @_;

    # we can't just use $last_word because we want all the text before the cursor to
    # matter, not just the current word

    my $dispatcher = $self->cli->dispatcher_class->new;

    # We're supposed to return only the completion of $last_word, not replacements
    # of $line. So for a completion that returns multiple words, this could screw
    # up and return only its last word.
    my @matches = map { s/^.* //; $_ } $dispatcher->complete($line);

    return @matches;
}

# make the REPL history persistent
sub run {
    my $self = shift;

    $self->print_usage if $self->has_arg('h');

    $self->_read_repl_history();
    $self->_run(@_);
    $self->_write_repl_history();
}

# we use eval here because only some Term::ReadLine subclasses support
# persistent history. it also seems that ->can doesn't work because of AUTOLOAD
# trickery. :(

sub _read_repl_history {
    my $self = shift;
    eval {
        local $SIG{__DIE__};
        $self->term->stifle_history($LEN);
        $self->term->ReadHistory($HIST)
          if -f $HIST;
    };
}

sub _write_repl_history {
    my $self = shift;

    eval {
        local $SIG{__DIE__};
        $self->term->WriteHistory($HIST)
          or warn "Unable to write to shell history file $HIST";
    };
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Shell

=head1 VERSION

version 0.751

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
