package Sys::Cmd::Template;
use strict;
use warnings;
use 5.006;
use Carp qw/croak confess/;
use Exporter::Tidy default => [qw/cmd_template/];
use File::Spec::Functions qw/splitdir/;
use File::Which;
use Sys::Cmd;
use Sys::Cmd::Mo qw/is default/;

our $VERSION = '0.85.4';
our $CONFESS;

sub cmd_template {
    my @cmd = grep { ref $_ ne 'HASH' } @_;

    my $bin = $cmd[0];
    defined $bin || confess '$cmd must be defined';

    if ( !-f $bin and splitdir($bin) < 2 ) {
        $cmd[0] = which($bin);
    }

    my $opts = ( grep { ref $_ eq 'HASH' } @_ )[0];

    my %args = $opts ? %$opts : ();
    $args{cmd} = \@cmd;

    return Sys::Cmd::Template->new(%args);
}

has 'cmd' => (
    is  => 'rw',
    isa => sub { ref $_[0] eq 'ARRAY' || confess "cmd must be ARRAYREF" },
    default => sub { [] },
);

has 'dir' => (
    is        => 'rw',
    predicate => 'have_dir',
);

has 'encoding' => (
    is        => 'rw',
    predicate => 'have_encoding',
);

has 'env' => (
    is        => 'rw',
    isa       => sub { ref $_[0] eq 'HASH' || confess "env must be HASHREF" },
    predicate => 'have_env',
);

has 'input' => (
    is        => 'rw',
    predicate => 'have_input',
);

sub run {
    my $self = shift;
    my $proc = $self->spawn(@_);
    my @out  = $proc->stdout->getlines;
    my @err  = $proc->stderr->getlines;

    $proc->close;

    if ( $proc->exit != 0 ) {
        confess( join( '', @err ) . 'Command exited with value ' . $proc->exit )
          if $CONFESS;
        croak( join( '', @err ) . 'Command exited with value ' . $proc->exit );
    }

    if (wantarray) {
        return @out;
    }
    else {
        return join( '', @out );
    }
}

sub runx {
    my $self = shift;
    my $proc = $self->spawn(@_);
    my @out  = $proc->stdout->getlines;
    my @err  = $proc->stderr->getlines;

    $proc->close;

    if ( $proc->exit != 0 ) {
        confess( join( '', @err ) . 'Command exited with value ' . $proc->exit )
          if $CONFESS;
        croak( join( '', @err ) . 'Command exited with value ' . $proc->exit );
    }

    if (wantarray) {
        return @out, @err;
    }
    else {
        return join( '', @out, @err );
    }
}

sub spawn {
    my $self = shift;
    my %args = ( cmd => [ @{ $self->cmd }, grep { ref $_ ne 'HASH' } @_ ], );

    my $opts = ( grep { ref $_ eq 'HASH' } @_ )[0] || {};

    if ( exists $opts->{dir} ) {
        $args{dir} = $opts->{dir};
    }
    elsif ( $self->have_dir ) {
        $args{dir} = $self->dir;
    }

    if ( exists $opts->{encoding} ) {
        $args{encoding} = $opts->{encoding};
    }
    elsif ( $self->have_encoding ) {
        $args{encoding} = $self->encoding;
    }

    if ( $self->have_env ) {
        $args{env} = { %{ $self->env } };
    }

    if ( exists $opts->{env} ) {
        while ( my ( $key, $val ) = each %{ $opts->{env} } ) {
            $args{env}->{$key} = $val;
        }
    }

    if ( exists $opts->{input} ) {
        $args{input} = $opts->{input};
    }
    elsif ( $self->have_input ) {
        $args{input} = $self->input;
    }

    return Sys::Cmd->new(%args);
}

1;

__END__


=head1 NAME

Sys::Cmd::Template - command/process templates for Sys::Cmd

=head1 VERSION

0.85.4 (2016-06-06) Development release

=head1 SYNOPSIS

    use Sys::Cmd::Template qw/cmd_template/;

    my $git = cmd_template('git', {
        dir => '/proj/subdir',
        env => { GIT_DIR => '/proj/.git' },
    });

    # Get command output, raise exception on failure:
    $output = $git->run('status');

    # Feed command some input, get output as lines,
    # raise exception on failure:
    @output = $git->run(qw/commit -F -/, { input => 'feedme' });

    # Spawn and interact with a process:
    $proc = $git->spawn( @subcmd, { encoding => 'iso-8859-3'} );

    while (my $line = $proc->stdout->getline) {
        $proc->stdin->print("thanks");
    }

    my @errors = $proc->stderr->getlines;
    $proc->close();     # Done!

    # read exit information
    $proc->exit();      # exit status
    $proc->signal();    # signal
    $proc->core();      # core dumped? (boolean)

=head1 DESCRIPTION

B<Sys::Cmd::Template> provides "template" objects for system commands.
This is useful when you need to make repeated calls to an external
binary with the same options or environment settings. "git" and "gpg"
are good examples of such commands.

A B<Sys::Cmd::Template> object should represent the common elements of
the calls to your external command. The C<run>, C<runx> and C<spawn>
methods then merge their arguments and options with these common
elements and execute the result with L<Sys::Cmd>.

A single function is exported on demand by this module:

=over 4

=item cmd_template( @cmd, [\%opt] ) => Sys::Cmd::Template

Create a new L<Sys::Cmd::Template> object.  The first element of
C<@cmd> will be looked up using L<File::Which> if it is not found as a
relative file name. C<%opt> is an optional hashref containing any of
the following key/values:

=over 4

=item dir

The working directory the command will be run in.

=item encoding

An string value identifying the encoding of the input/output
file-handles. Has no default but L<Sys::Cmd> will default this to
'utf8'.

=item env

A hashref containing key/values to be added to the current environment
at run-time. If a key has an undefined value then the key is removed
from the environment altogether.

=item input

A string which is fed to each command via its standard input, which is
then closed.

=back

=back

B<Sys::Cmd::Template> objects (documented below) can of course be
created using the standard C<new> constructor if you prefer that to the
C<cmd_template> function:

    $proc = Sys::Cmd::Template->new(
        cmd => \@cmd,
        dir => '/',
        env => { SOME => 'VALUE' },
        encoding => 'iso-8859-3',
        input => 'feedme',
    );

Note that B<Sys::Cmd::Template> objects created this way will not
lookup the command using L<File::Which> the way the C<cmd_template>
function does.

=head1 CONSTRUCTOR

=over 4

=item new(%args) => Sys::Cmd::Template

Create a new L<Sys::Cmd> template object. %args can contain any one of
the C<cmd>, C<dir>, C<encoding>, C<env> and C<input> values as defined
as attributes below.

=back

=head1 ATTRIBUTES

In contrast with L<Sys::Cmd> the attributes defined here can be
modified, and the new values will be used on subsequent method calls.

=over 4

=item cmd

An array ref containing the command and its arguments.

=item dir

The working directory the command will be run in.

=item encoding

An string value identifying the encoding of the input/output
file-handles. Defaults to 'utf8'.

=item env

A hashref containing key/values to be added to the current environment
at run-time. If a key has an undefined value then the key is removed
from the environment altogether.

=item input

A string which is fed to the command via its standard input, which is
then closed. Most likely you won't ever want to use this, but it is
here for completeness.

=back

=head1 METHODS

=over 4

=item run( @cmd, [\%opt] ) => $output | @output

B<Append> C<@cmd> to the C<cmd> attribute, execute it using L<Sys::Cmd>
and return what the command sent to its C<STDOUT>, raising an exception
in the event of error. In array context returns a list instead of a
plain string.

The command elements can be modified from your objects values with an
optional hashref containing the following key/values:

=over 4

=item dir

The working directory the command will be run in. Will B<replace> an
existing C<dir> attribute.

=item encoding

An string value identifying the encoding of the input/output
file-handles. Defaults to 'utf8'.  Will B<replace> an existing C<dir>
attribute.

=item env

A hashref containing key/values to be added to the current environment
at run-time. If a key has an undefined value then the key is removed
from the environment altogether. Will be B<merged> with an existing
C<env> attribute.

=item input

A string which is fed to the command via its standard input, which is
then closed.  Will B<replace> an existing C<input> attribute.

=back

=item runx( @cmd, [\%opt] ) => $outerrput | @outerrput

The same as the C<run> method but with the command's C<STDERR> output
appended to the C<STDOUT> output.

=item spawn( @cmd, [\%opt] ) => Sys::Cmd

Returns a B<Sys::Cmd> object representing the process running @cmd
(appended to the C<cmd> attribute), with attributes set according to
the optional \%opt hashref.

=back

=head1 SEE ALSO

L<Sys::Cmd>

=head1 SUPPORT

=over

=item Bug Reporting

    https://rt.cpan.org/Public/Bug/Report.html?Queue=Sys-Cmd

=item Source Code

    git clone git://github.com/mlawren/sys-cmd.git

=back

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

