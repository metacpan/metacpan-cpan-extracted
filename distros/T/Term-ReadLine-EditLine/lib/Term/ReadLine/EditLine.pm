package Term::ReadLine::EditLine;
use strict;
use warnings;
use 5.008005;
our $VERSION = '1.1.1';

use Term::EditLine;
use Term::ReadLine;
use Carp ();

our @ISA = qw(Term::ReadLine::Stub);

sub ReadLine { __PACKAGE__ }

sub new {
    my $class = shift;
    unless (@_ > 0) {
        Carp::croak("Usage: Term::ReadLine::EditLine->new(\$program[, IN, OUT])");
    }
    my $editline = Term::EditLine->new(@_);
    $editline->set_editor('emacs'); # set emacs as default mode.
    my $self = bless {
        editline => $editline,
        IN       => $_[1] || *STDIN,
        OUT      => $_[2] || *STDOUT,
    }, $class;
}

sub editline { $_[0]->{editline} }

sub readline {
    my ($self, $prompt) = @_;
    if (defined($prompt)) {
        $self->editline->set_prompt($prompt);
    }
    $self->editline->gets();
}

sub addhistory {
    my ($self, $history) = @_;
    $self->editline->history_enter($history);
}

sub IN  { $_[0]->{IN} }
sub OUT { $_[0]->{OUT} }

sub MinLine { undef }

sub findConsole {
    my $console;
    my $consoleOUT;
 
    if (-e "/dev/tty" and $^O ne 'MSWin32') {
    $console = "/dev/tty";
    } elsif (-e "con" or $^O eq 'MSWin32') {
       $console = 'CONIN$';
       $consoleOUT = 'CONOUT$';
    } else {
    $console = "sys\$command";
    }
 
    if (($^O eq 'amigaos') || ($^O eq 'beos') || ($^O eq 'epoc')) {
    $console = undef;
    }
    elsif ($^O eq 'os2') {
      if ($DB::emacs) {
    $console = undef;
      } else {
    $console = "/dev/con";
      }
    }
 
    $consoleOUT = $console unless defined $consoleOUT;
    $console = "&STDIN" unless defined $console;
    if ($console eq "/dev/tty" && !open(my $fh, "<", $console)) {
      $console = "&STDIN";
      undef($consoleOUT);
    }
    if (!defined $consoleOUT) {
      $consoleOUT = defined fileno(STDERR) && $^O ne 'MSWin32' ? "&STDERR" : "&STDOUT";
    }
    ($console,$consoleOUT);
}

sub Attribs { +{ } }

sub Features {
    +{ }
}

1;
__END__

=encoding utf8

=for stopwords libedit readline

=head1 NAME

Term::ReadLine::EditLine - Term::ReadLine style wrapper for Term::EditLine

=head1 SYNOPSIS

    use Term::ReadLine;

    my $t = Term::ReadLine->new('program name');
    while (defined($_ = $t->readline('prompt> '))) {
        ...
        $t->addhistory($_) if /\S/;
    }

=head1 DESCRIPTION

Term::ReadLine::EditLine provides L<Term::ReadLine> interface using L<Term::EditLine>.

=head1 MOTIVATION

L<Term::ReadLine::Gnu> is great, but it's hard to install on Mac OS X. Because it has pre-installed
libedit but it does not contain GNU readline.

Term::ReadLine::EditLine is very easy to install on OSX.

=head1 INTERFACE

You can use following methods in Term::ReadLine interface.

=over 4

=item Term::ReadLine->new($program_name[, IN, OUT])

=item $t->addhistory($history)

=item my $line = $t->readline()

=item $t->ReadLine()

=item $t->IN()

=item $t->OUT()

=item $t->findConsole()

=item $t->Attribs()

=item $t->Features()

=back

Additionally, you can use C<< $t->editline() >> method to access L<Term::EditLine> instance.

=head1 ENVIRONMENT

The Term::ReadLine interface module uses the PERL_RL variable to decide which module to load; so if you want to use this module for all your perl applications, try something like:

    export PERL_RL=EditLine

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

This module provides interface for L<Term::ReadLine>, based on L<Term::EditLine>.

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
