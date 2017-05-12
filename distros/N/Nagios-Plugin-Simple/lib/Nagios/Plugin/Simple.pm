package Nagios::Plugin::Simple;
use strict;
use warnings;

our $VERSION='0.06';

=head1 NAME

Nagios::Plugin::Simple - Simple and Minimalistic Nagios Plugin Package

=head1 SYNOPSIS

  use Nagios::Plugin::Simple;
  my $nps=Nagios::Plugin::Simple->new;
  $nps->ok("I'm OK") if &ok;
  $nps->warning("I'm a bit sickly") if &sick;
  $nps->critical("Barf...");
  $nps->unknown("Huh?");

In the true spirit of Perl you can even do a one-liner.

  perl -MNagios::Plugin::Simple -e 'Nagios::Plugin::Simple->new->ok("")';echo $?


=head1 DESCRIPTION

This is the package that I use mostly because I feel the L<Nagios::Plugin> is too encompassing.  I feel that it is the scripts responsibility to handle arguments and thus this package does not do that nor will do that.  If you want argument handling use one of the GetOpt packages.

=head1 USAGE

  use Nagios::Plugin::Simple;
  my $nps=Nagios::Plugin::Simple->new;
  if (&ok) {$nps->ok("good!")} else {$nps->critical("bad!")};


=head1 CONSTRUCTOR

=head2 new

  my $nps=Nagios::Plugin::Simple->new();

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self=shift;
  %$self=@_;
}

=head2 ok

Exits script with ok status code.

  $nps->ok("I'm OK");

Prints "OK: %s" and exits with a code 0.

  STDOUT => "OK: I'm OK\n",  EXIT=>0

=cut

sub ok {
  my $self=shift;
  my $string=shift;
  $self->status(OK=>$string);
}

=head2 warning

Exits script with warning status code.

  $nps->warning("I'm a bit sickly");

Prints "Warning: %s" and exits with a code 1.

  STDOUT => "Warning: I'm a bit sickly\n",  EXIT=>1

=cut

sub warning {
  my $self=shift;
  my $string=shift;
  $self->status(Warning=>$string);
}

=head2 critical

Exits script with critical status code.

  $nps->critical("Barf...");

Prints "Critical: %s" and exits with a code 2.

  STDOUT => "Critical: Barf...\n",  EXIT=>2

=cut

sub critical {
  my $self=shift;
  my $string=shift;
  $self->status(Critical=>$string);
}

=head2 unknown

Exits script with unknown status code.

  $nps->unknown("Huh?")

Prints "Unknown: %s" and exits with a code 3.

  STDOUT => "Unknown: Huh?\n",  EXIT=>3

=cut

sub unknown {
  my $self=shift;
  my $string=shift;
  $self->status(Unknown=>$string);
}

=head2 code

Exits script by status code.  This works best if your status is actually stored as a code 0, 1, 2, or 3 in a variable.

  $nps->code($code => $string);

Examples:

  $nps->code(0 => "I'm OK!");
  $nps->code(1 => "I'm a bit sickly");
  $nps->code(2 => "Barf...");
  $nps->code(3 => "Huh?")

Prints ``$status: %s'' and exits with $code.

=cut

sub code {
  my $self=shift;
  my $code=shift;
  my $string=shift;
  my %status=reverse $self->codes;
  my $status=$status{$code};
  $self->status($status, $string);
}

=head2 status

Exits script by status string.  This works best if your string is actually stored as "OK", "Warning", etc in a variable

  $nps->status($status    => $string);

Examples:

  $nps->status("OK"       => "I'm OK!");
  $nps->status("Warning"  => "I'm a bit sickly");
  $nps->status("Critical" => "Barf...");
  $nps->status("Unknown"  => "Huh?")

Prints ``$status: %s'' and exits with correct code.

=cut

sub status {
  my $self=shift;
  my $status=shift;
  my $string=shift;
  $string='' unless defined($string);
  my %codes=map {uc($_)} $self->codes;
  #use Data::Dumper;
  #print Dumper([\%codes]);
  my $code=$codes{uc($status)};
  die(qq{Error: Exit code not defined for "$status"}) unless defined($code);
  printf "%s: %s\n", $status, $string;
  exit $code;
}

=head2 codes

Returns a hash of the Nagios status codes.

  my %codes=$nps->codes;           #(OK=>0, Warning=>1, Critical=>2, Unknown=>3)
  my $codes=$nps->codes;           #{OK=>0, Warning=>1, Critical=>2, Unknown=>3}
  my %status=reverse $self->codes; #(0=>"OK", 1=>"Warning", ...)

=cut

sub codes {
 #my $self=shift;
  my @data=(OK=>0, Warning=>1, Critical=>2, Unknown=>3);
  return wantarray ? @data : {@data};
}

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    STOP, LLC
    account=>perl,tld=>com,domain=>michaelrdavis
    http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Nagios::Plugin>, L<Getopt::Std>, L<Getopt::Long>

=cut

1;
