package System::Timeout;
use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK $VERSION);
use IPC::Cmd qw(run);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(system timeout);

our $VERSION = '0.07';

sub system
{
    return timeout(@_);
}

sub timeout
{
	if ($_[0] !~ /^\d+$/)
	{
		my $r = CORE::system(@_);
		return $r;
	}
	else
	{
		my $timeout_secs = shift @_;
		my $ref_cmd = \@_;
		my $r = run(command => $ref_cmd, timeout=> $timeout_secs, verbose=>1, );
		return 0 if $r;
		return 1 unless $r;
	}
}

1;

__END__

=head1 NAME

System::Timeout - extend C<system> to allow timeout after specified seconds


=head1 SYNOPSIS

Normal Usage

  use System::Timeout qw(timeout);
  timeout("sleep 9"); # invoke CORE::system, will not timeout exit
  timeout("3", "sleep 9"); # timeout exit after 3 seconds

Overlay the Build-in C<system>

  use System::Timeout qw(system);
  system("3", "sleep 9");

Use the CLI tool

  % timeout --timeout=3 "sleep 9"  #Run command "Sleep 9" and timeout after 3 seconds


=head1 DESCRIPTION

This module extends C<system> to allow timeout after the specified seconds.
Also include a cli tool "timeout" which can be easily used to force command exit after specified seconds.


=head1 AUTHOR

Written by ChenGang, yikuyiku.com@gmail.com

L<http://blog.yikuyiku.com/>


=head1 COPYRIGHT

Copyright (c) 2011 ChenGang.
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<IPC::Open3>, L<IPC::Run>, L<IPC::Cmd>

=cut
