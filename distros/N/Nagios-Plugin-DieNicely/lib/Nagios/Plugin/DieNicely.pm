package Nagios::Plugin::DieNicely;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION     = '0.05';

our ($wanted_exit, $exit_description);

sub import {
    my ($class, $exit) = @_;
    my $translation = {
        'OK'       => 0,
	'WARNING'  => 1,
	'CRITICAL' => 2,
	'UNKNOWN'  => 3
    };
    if (not defined $exit){
        # by default we will exit critical
        $exit = 'CRITICAL';
    }
    if (not defined $translation->{$exit}){
        print "Nagios::Plugin::DieNicely doesn't know how to exit $exit\n";
        exit 3;
    } 
    
    $wanted_exit = $translation->{$exit};
    $exit_description = $exit;
}


sub _nagios_die {
    die @_ if $^S;
    die @_ if (not defined $^S);

    if (not defined $wanted_exit){
        # If someone only requires the module, and import is not called,
	# wanted_exit would be undefined. We also get here when the 
	# parameter passed to the class is not valid
        $wanted_exit = 2;
	$exit_description = 'CRITICAL';
    }

    print "$exit_description - ", @_;
    exit $wanted_exit;
}

$SIG{__DIE__} = \&_nagios_die;

=head1 NAME

Nagios::Plugin::DieNicely - Die in a Nagios output compatible way

=head1 SYNOPSIS

  use Nagios::Plugin::DieNicely;

  ... your plugin code goes here ...


  use Nagios::Plugin::DieNicely 'WARNING';

  ... now if you die, you will get a Nagios WARNING state ...

=head1 DESCRIPTION

When your Nagios plugins, or the modules that they use raise an unhandled exception with I<die>, I<croak> or I<confess>, the exception gets lost, and Nagios treats the output as an UNKNOWN state with no output from the plugin, as STDERR gets discarded by Nagios.

This module overrides perl's default behaviour of using exit code 255 and printing the error to STDERR (not Nagios friendly). Just using for exit code 2 (Nagios CRITICAL), and outputing the error to STDOUT with "CRITICAL - " prepended to the exception. Note that you can change the CRITICAL for WARNING, or even OK (not recommended)

=head1 USE

Just I<use> the module. If you want a Nagios error code other that B<CRITICAL>, then use the module passing one of: I<WARNING>, I<OK>, I<UNKNOWN>. I<CRITICAL> can be passed too (just for completeness).

  use Nagios::Plugin::DieNicely 'WARNING';
  use Nagios::Plugin::DieNicely 'UNKNOWN';
  use Nagios::Plugin::DieNicely 'CRITICAL';
  use Nagios::Plugin::DieNicely 'OK';

=head1 TODO

 - Get the shortname of the module through Nagios::Plugin if it is beeing used
 - Issue perl warnings to STDOUT, and possbily issue WARNING or CRITICAL

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

