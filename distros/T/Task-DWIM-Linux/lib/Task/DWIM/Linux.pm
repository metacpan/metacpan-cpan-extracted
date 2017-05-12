package Task::DWIM::Linux;

use 5.008;
use strict;
use warnings;
our $VERSION = '0.10';

use Config::Tiny;

my %modules;

sub get_modules {
    read_modules('Linux.txt');

    #read_modules('Async.txt');         # Task-Kensho-Async-0.28
    #read_modules('Catalyst.txt');      # Task-Kensho-WebDev-0.29 -> Task-Catalyst-4.02
    #read_modules('CLI.txt');           # Task-Kensho-CLI-0.29
    #read_modules('Config.txt');        # Task-Kensho-Config-0.28
    #read_modules('CPAN.txt');          # Task-Kensho-ModuleDev-0.28
    #read_modules('Compression.txt');   #
    #read_modules('Core.txt');          # A sublist of the Core (and dual life) modules
    #read_modules('Dancer.txt');        #
    #read_modules('Database.txt');      # Task-Kensho-DBDev-0.28
    #read_modules('DateTime.txt');      # Task-Kensho-Dates-0.28
    #read_modules('DistZilla.txt');     # Task-Kensho-ModuleDev-0.28
    #read_modules('Email.txt');         # Task-Kensho-Email-0.28
    #read_modules('Encryption.txt');    #
    #read_modules('Exceptions.txt');    # Task-Kensho-Exceptions-0.28
    ## Task-Kensho-Hackery-0.28 in various places
    #read_modules('Logging.txt');       # Task-Kensho-Logging-0.01
    #read_modules('Modules.txt');       #
    #read_modules('Moose.txt');         # Task-Kensho-OOP-0.28 -> Task-Moose-0.03 (TryCatch moved to Exceptions)
    #read_modules('OOP.txt');           #
    ## Task-Kensho-Scalability-0.28 (CHI)
    #read_modules('Serialization.txt'); #
    #read_modules('Science.txt');       #
    #read_modules('Spreadsheet.txt');   # Task-Kensho-ExcelCSV-0.28
    #read_modules('Test.txt');          # Task-Kensho-Testing-0.29
    ## Task-Kensho-Toolchain-0.28 (App::cpanminus  local::lib version)
    #read_modules('Web.txt');           # Task-Kensho-WebDev-0.29
    #read_modules('WebClient.txt');     # Task-Kensho-WebCrawling-0.28
    #read_modules('XML.txt');           # Task-Kensho-XML-0.28

    #read_modules('tasks.txt');
    #if ($^O eq 'MSWin32') {
    #    # Currently only the Windows version supports the desktop option
    #    # (it needs a threaded perl)
    #    read_modules('Desktop.txt');
    #    read_modules('Windows.txt');
    #} else {
    #    read_modules('NoWindows.txt');
    #}

    return %modules;
}

sub read_modules {
    my ($file) = @_;

    $file = "lists/$file";

    return if not -e '.git' and not -e $file;

    my $config = Config::Tiny->read( $file, 'utf8' );
    foreach my $name (keys %$config) {
        $modules{$name} = $config->{$name}{version};
    }

    #open my $fh, '<', $file or die "Could not open '$file' $!";
    #while (my $line = <$fh>) {
    #    chomp $line;
    #    next if $line =~ /^\s*(#.*)?$/;
    #    $line =~ s/\s*#.*//;
    #    my ($name, $version) = split /\s*=\s*/, $line;
    #    die "No version in '$line'" if not defined $version;
    #    if (exists $modules{$name}) {
    #        die "Module '$name' has 2 entries. One with '$modules{$name}' and the other one with '$version'";
    #    }
    #    $modules{$name} = $version;
    #}
    #close $fh;
    return;
}


1;

__END__

=pod

=head1 NAME

Task::DWIM::Linux - A Task module for DWIM Perl L<http://dwimperl.com/>

=head1 DESCRIPTION

Just a list of modules to be installed as part of the DWIM Perl distribution

=head1 AUTHOR

Gabor Szabo L<http://szabgab.com>

If you are interested, contact me to take over the maintenance.

=head1 SEE ALSO

L<Task>, L<http://dwimperl.com/>

=head1 COPYRIGHT

Copyright 2012-2014 Gabor Szabo.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

