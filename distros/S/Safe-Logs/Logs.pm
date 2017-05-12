package Safe::Logs;

require 5.005;
use strict;
use warnings;
no warnings "redefine";		# We make this a few times

use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

$VERSION = '1.00';

require Exporter;

@ISA = qw(Exporter);

%EXPORT_TAGS =
(
 Carp		=> [ qw(carp croak confess cluck) ],
 Syslog		=> [ qw(syslog) ],
 );

push @{$EXPORT_TAGS{all}}, @{$EXPORT_TAGS{$_}} 
for grep { $_ ne 'all' } keys %EXPORT_TAGS;

push @{$EXPORT_TAGS{all}}, 'protect';

@EXPORT_OK = @{$EXPORT_TAGS{all}}; 

=pod

=head1 NAME

Safe::Logs - Perl extension to avoid terminal emulator vulnerabilities

=head1 SYNOPSIS

  use Safe::Logs;		# Always override warn() and die()
  use Safe::Logs qw(:all);	# override eveything this module knows
  use Safe::Logs qw(:Carp);	# Only override Carp:: methods
  use Safe::Logs qw(:Syslog);	# Only override syslog()
  use Safe::Logs qw(protect);	# protect() for use on your own

				# Or combine a few
  use Safe::Logs qw(:Syslog :Carp);

=head1 DESCRIPTION

As shown by the people at Digital Defense, there are a number of
vulnerabilities that can be remotely exploited in the terminal
emulators that are so common today. These vulnerabilities might allow
an attacker to execute arbitrary commands by a number of methods. The
easiest one, illustrated on
http://www.digitaldefense.net/labs/papers/Termulation.txt shows how to
compromise a remote host by sending carefully chosen requests that end
up in log files. It is then a matter of time for an innocent command
such as

    tail -f poisoned.log

To wreak havoc in your system.

You must C<use> this module as the last in the list so that it can
override the methods exported from other modules.

This module is a quick solution for this vulnerability. What it does
is very simple: It replaces ocurrences of the ESC character in the
output of any common logging mechanism such as C<use warnings>,
C<warn>, C<use Carp> and C<die>.

It does so by overriding the functions with a safer alternative so
that no code needs to be changed. Hopefully this will be followed by
better solutions from other Perl developers.

Note that in order for this protection to be effective, this module
must be C<use>d as the last module (ie, after all the modules it can
override) in order for proper method replacement to occur.

The protection can also be invoked by the C<protect> method, which
takes a list of arguments and returns the same list, with all ESC
characters safely replaced. This method is provided so that you can
call it by yourself.

Tipically, you will want to issue an C<use Safe::Logs qw(:all)> after
the last module is C<use>d in your code, to automatically benefit from
the most common level of protection agains the attacks describen in
the paper.

=cut

				# This is the core of our protection. Replace
				# the escape character by an inocuous symbol

sub _protect
{
    my $msg = $_[0];
    return $_[0] if ref $_[0];
    $msg =~ s/\x1b/[esc]/g;
    return $msg;
}

sub protect
{
    return map { _protect $_ } @_;
}

=pod

The list of methods or functions that this module replaces are as
follows.

=cut

				# This eases the task of replacing a method
				# from other package

sub _build
{
    no strict 'refs';
    my $name = shift;
    my $r_orig = \&$name;
    $name =~ s/^.*:://;
    *$name = sub { $r_orig->( protect @_ ) };
}

=pod

=over

=item C<CORE::warn>

The standard Perl C<warn()>.

=cut

*CORE::GLOBAL::warn = sub
{
  CORE::warn(protect @_);
};

=pod

=item C<CORE::die>

The standard Perl C<die()>.

=cut

*CORE::GLOBAL::die = sub
{
  CORE::die(protect @_);
};

=pod

=item C<Carp::carp>

=item C<Carp::croak>

=item C<Carp::confess>

=item C<Carp::cluck>

All the methods from C<Carp> are overridden by this module.

=cut

_build('Carp::carp');
_build('Carp::croak');
_build('Carp::confess');
_build('Carp::cluck');

=pod

=item C<Sys::Syslog>

=item C<Unix::Syslog>

The known and common C<syslog()> calls are automatically overridden by
this module.

=cut

_build('main::syslog');

=pod

=item C<warnings::warn>

=item C<warnings::warnif>

Calls from C<warnings::> are automatically overridden by this module.

=cut

my $clone_warn = \&warnings::warn;
my $clone_warnif = \&warnings::warn;

*warnings::warn = sub
{
    @_ = protect @_;
    goto $clone_warn;
};

*warnings::warnif = sub
{
    @_ = protect @_;
    goto $clone_warnif;
};

1;
__END__

=pod

=head2 EXPORT

Many. The methods are exported or overridden according to this

  main::warn()		-	Always overridden
  main::die()		-	Always overridden
  warnings::warn()	-	Always overridden
  warnings::warnif()	-	Always overridden

  Carp::croak()		-	Only exported with :Carp or :all
  Carp::carp()		-	Only exported with :Carp or :all
  Carp::confess()	-	Only exported with :Carp or :all
  Carp::cluck()		-	Only exported with :Carp or :all

  main::syslog()	-	Only exported with :Syslog or :all

  protect()		-	Only exported with 'protect' or :all

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.2 with options

  -ACOXcfkn
	Safe::Logs
	-v
	0.01

=back


=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1), Carp(3), warnings(3), Sys::Syslog(3), Unix::Syslog(3), Termulation.txt.

=cut
