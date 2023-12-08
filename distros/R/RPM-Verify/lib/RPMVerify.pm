package RPM::Verify 1.000;

# PODNAME: RPM::Verify
# ABSTRACT: Run rpm -v on every installed rpm, and give you a descriptive hash of the relevant changes.

use strict;
use warnings;

no warnings qw{experimental};
use feature qw{signatures};

use Ref::Util qw{is_arrayref};
use List::Util qw{any};
use File::Which qw{which};


sub alterations(%options) {
    die "Cannot find rpm binary!"   unless which('rpm');
    die "Cannot find xargs binary!" unless which('xargs');

    my (@skipfiles, @skiptypes);
    @skiptypes = @{$options{skip_types}} if is_arrayref($options{skip_types});
    @skipfiles = @{$options{skip_files}} if is_arrayref($options{skip_files});

    my @skipext;
    if (any { 'config' eq $_ } @skiptypes) {
        push(@skipext, qr/\.conf$/, qr/\.cfg$/);
    }

    open(my $list, "-|", qq{rpm -qa | xargs -P 32 -- rpm -V}) or die "Could not acquire list of RPM changes!";

    #SM5DLUGT c <file>
    my @mapper = qw{size mode md5 fileno linkloc owner group mtime capabilities NOP NOP ftype NOP file};
    my %ftmap = (
        c => 'config',
        d => 'documentation',
        g => 'ghost',
        l => 'license',
        r => 'readme',
    );

    my %files;
    LINE: foreach my $line ( readline($list) ) {
        chomp $line;
        # Not an rpm -V row
        next unless ( $line =~ m/^(\S{8,9}|missing\s+[cdg]|missing)\s+(\S.*)$/ );
        my @parse = unpack("AAAAAAAAAAAAAA*", $line);
        my %parsed;
        for (my $pos=0; $pos < scalar(@parse); $pos++)  {
            # Ignore . and space
            next if index('.', $parse[$pos]) == 0;
            next if index(' ', $parse[$pos]) == 0;
            # File type is a special case
            my $key = $mapper[$pos];
            $key = $ftmap{$parse[$pos]} if $pos == 11;

            # Don't bother with things we want to skip.
            next LINE if @skiptypes && any { $_ eq $key } @skiptypes;

            my $value = $parse[$pos];
            $value = !!$value unless $pos == 13;

            #XXX Some authors of RPMs don't list configuration as...you know, configuration.
            next LINE if @skipext && $pos == 13 && any { $value =~ $_ } @skipext;

            $parsed{$key} = $value;
        }
        # Anything that's not an absolute path is just a broken RPM with a jacked FILES list
        next unless index( $parsed{file}, '/') == 0;

        $files{$parsed{file}} = \%parsed;
        $files{$parsed{file}}{provider} = qx[yum whatprovides -q $parsed{file} | head -n1];
        ($files{$parsed{file}}{provider}) = $files{$parsed{file}}{provider} =~ m/^(\S+) .*/;
    }
    close $list;

    return %files;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RPM::Verify - Run rpm -v on every installed rpm, and give you a descriptive hash of the relevant changes.

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    # Ask for everything changed that isn't config, ghost, documentation, readmes or license files
    # optionally pass a list of "known good" files which are modified without being config/ghosted
    # as it is a regrettably common occurrence for commercial software and admins to engage in such shenanigans

    use Data::Dumper;
    use RPM::Verify;

    print Dumper(RPM::Verify::alterations( skip_files => [qw{/bin/totally_not_suspicious_program}], skip_types => [qw{config ghost documentation readme license}] ));

=head1 SUBROUTINES

=head2 alterations(%options) = HASH

Dies in the event rpm or xargs aren't present on the system.
If you don't have an RPM managed system with these available, I can't help you.

The skip_types argument will disregard changes of the provided types.

The skip_files argument will disregard changes to a particular file.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/RPM-Verify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
