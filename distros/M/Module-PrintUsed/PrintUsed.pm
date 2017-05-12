package Module::PrintUsed;

use 5.006;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.06';

sub ModulesList {
    my @modules;
    
    foreach (sort keys %INC) {
        my $name = $_;
        $name =~ s|[\\/]|::|g;
        $name =~ s|\.pm$||;
        
        my $version;
        {
            # Prevent warnings caused by autosplitted modules.
            # See RT#48573.
            no warnings;
            $version = eval " \$$name\::VERSION " || '';
        }
        push @modules, { name => $name, version => $version,
            path => $INC{$_} };
    }
    
    return @modules;
}

sub FormattedModulesList {
    my $text = "\nModules used by $0:\n";
    my @modules = ModulesList();
    
    foreach (@modules) {
    	my $lengthName = 25 - length($_->{name});
    	$lengthName = 0 unless $lengthName > 0;
    	my $lengthVersion = 8 - length($_->{version});
    	$lengthVersion = 0 unless $lengthVersion > 0;
    	
        $text .= " - $_->{name} " . (" " x $lengthName) .
            "$_->{version} " . (" " x $lengthVersion) .
            "$_->{path}\n";
    }
    $text .= "\n";
    
    return $text;
}

END {
    print STDERR FormattedModulesList();
}


1;
__END__
=encoding UTF-8

=head1 NAME

Module::PrintUsed - Prints modules used by your script when your script ends

=head1 SYNOPSIS

  use Module::PrintUsed;

=head1 DESCRIPTION

This module helps you to check which modules (and scripts) were C<use>d or C<require>d during the runtime of your script. It prints the list of modules to STDERR, including version numbers and paths.

Module::PrintUsed contains an C<END {}> block that will be executed when your script exits (even if it died).

=head2 USAGE VIA PERL5OPT

It is possible to print a list of modules used even without modifying your perl scripts or programs. To achieve this, set the PERL5OPT environment variable to "-MModule::PrintUsed".

Unix command-line example:

    env PERL5OPT=-MModule::PrintUsed perl myscript.pl

Windows command-line example:

    set PERL5OPT=-MModule::PrintUsed
    perl myscript.pl

=head1 FUNCTIONS

=over 4

=item C<Module::PrintUsed::ModulesList()>

Returns a list of modules used in the format

    @modules = ({name => 'Some::Module', version => '0.1',
                 path => '/home/thisuser/lib/Some/Module.pm'}, ...);

=item C<Module::PrintUsed::FormattedModulesList()> 

Returns a scalar that contains a pretty-printed version of the
modules list.

=back

=head1 DEVELOPMENT NOTES

Please report any bugs sing the CPAN RT system. The development repository for this module is hosted on GitHub: L<http://github.com/crenz/Module-PrintUsed/>.

=head1 THANKS

Thanks to Slaven Rezić for pointing out that Module::PrintUsed can be used with the PERL5OPT environment variable, and for alerting me to warnings caused by autosplitted modules.

=head1 SEE ALSO

A more sophisticated way of finding module dependencies without having
to execute the script is performed by L<Module::ScanDeps>.

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2015 Christian Renz E<lt>crenz @ web42.comE<gt>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
