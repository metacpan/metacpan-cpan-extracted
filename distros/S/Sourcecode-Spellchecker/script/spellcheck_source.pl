#!/usr/bin/perl
use strict;
use warnings;
use Sourcecode::Spellchecker;

# Parse the command-line arguments
if (@ARGV < 1 ){
    die qq(Usage: spellcheck_source.pl source1.cpp source2.cpp ...);
}
my @fileNames = @ARGV;
foreach my $fileName (@fileNames) {
    print "Checking $fileName...\n";

    # Scan for misspellings
    my $checker = Sourcecode::Spellchecker->new;
    my @results = $checker->spellcheck($fileName);

    if (@results) {
        print scalar(@results) . " misspellings found:\n";
        foreach my $result (@results) {
            print "$fileName:$result->{line}: '$result->{misspelling}' "
              . "should be '$result->{correction}'\n";
        }
    }
    else {
        print "No spelling mistakes found.\n";
    }
}

__END__

=head1 NAME

spellcheck_sourcecode.pl - Scans source code for common misspellings.

=head1 SYNOPSIS

  perl spellcheck_sourcecode.pl test.cpp

=head1 DESCRIPTION

Check a source file (e.g. C, C++, Perl, or Java) for common misspellings in comments, string literals, and identifiers.

=head1 SEE ALSO

C<Sourcecode::Spellcheck> - Identifies common misspellings in source code.

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Zachary D. Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
