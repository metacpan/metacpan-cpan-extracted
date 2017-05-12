# -*- perl -*-
#
# Test::AutoBuild::ErrorReport
#
# Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2006 Daniel Berrange
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id$

=pod

=head1 NAME

Test::AutoBuild::ErrorReport - details of a fatal error condition

=head1 SYNOPSIS

  use Test::AutoBuild::ErrorReport;

  # Create a new platform based on the host machine's native
  # environment
  $SIG{__DIE__} = sub {
    my $error = Test::AutoBuild::ErrorReport->new($_[0]);
    $error.save();
    die $error;
  };

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::ErrorReport;

use warnings;
use strict;
use Log::Log4perl;

use Sys::Hostname;
use File::Spec::Functions qw(catfile);
use Config;
use Data::Dumper;
use Carp qw(longmess);

use Class::MethodMaker
  get_set => [qw(
		 message
		 cause
		 trace
		 code
		 engine
		 )];

=item my $error = Test::AutoBuild::ErrorReport->new(message => $message,
						    [trace => $stacktrace,]);

Creates a new error report with the error message passed via the C<message>
parameter. The optional C<stacktrace> parameter can provide a call / stack
trace, and if omitted will be filled in automatically using C<Carp::longmess>.
The optional C<engine> parameter can be used to pass in an instance of the
C<Test::AutoBuild> class associated with the error.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my %params = @_;

    bless $self, $class;

    $self->message(exists $params{message} ? $params{message} : die "message parameter is required");
    $self->cause(exists $params{cause} ? $params{cause} : undef);
    $self->trace(exists $params{trace} ? $params{trace} : Carp::longmess);
    $self->engine(exists $params{engine} ? $params{engine} : undef);
    $self->code(join("-", hostname, $$, time));

    return $self;
}

use overload ('""' => 'stringify');
sub stringify {
    my $self = shift;
    return $self->message;
}

sub root_cause {
    my $self = shift;
    if ($self->cause) {
	return $self->cause;
    }
    return $self;
}

sub print {
    my $self = shift;
    $self->dump(\*STDOUT);
}

sub log {
    my $self = shift;

    my $file = catfile($ENV{HOME}, "autobuild-" . $self->code . ".log");
    $self->save($file);
    return $file;
}

sub save {
    my $self = shift;
    my $file = shift;
    open FILE, ">$file"
	or die "cannot save to $file: $!";
    $self->dump(\*FILE);
    close FILE
	or die "cannot close $file: $!";
}

sub dump {
    my $self = shift;
    my $fh = shift;

    print $fh "============================================================\n";
    print $fh " Test-AutoBuild Error Report\n";
    print $fh "============================================================\n";
    print $fh " Unique code: ", $self->code, "\n";
    print $fh " Error message: ", $self->message, "\n";
    print $fh "============================================================\n";
    print $fh " Trace: ", $self->trace, "\n";
    print $fh "============================================================\n";
    print $fh " Environment: \n";
    foreach (sort { $a cmp $b } keys %ENV) {
	print $fh "    ", $_, " = ", $ENV{$_}, "\n";
    }
    if (defined $self->engine && 0) {
	print $fh "============================================================\n";
	print $fh " Engine: \n";
	print $fh Dumper($self->engine), "\n";
    }
    print $fh "============================================================\n";
    print $fh " Platform config: \n";
    foreach (sort { $a cmp $b } keys %Config) {
	print $fh "    ", $_, " = ", (defined $Config{$_} ? $Config{$_} : ""), "\n";
    }
    print $fh "============================================================\n";

}

1; # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>

=cut
