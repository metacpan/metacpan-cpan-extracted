#! /usr/bin/env perl

use 5.014;
use warnings;
use List::Util 'max';
use PPI;
use experimentals;

my $MAX_DEPTH      = 10;
my $PLOT_WIDTH     = 50;
my $SOURCE_ROOT    = '~/src/Perl';
my $TEST_FILE_NAME = 'dt/real_blocks.t';

# The following modules mess with standard Perl syntax,
# so standard PPR can't understand the code...

my $IGNORE_FILES = join '|', qw{
    /Language/Pythonesque/
    /Perl6/Classes/
    /Keyword-Declare/
    /PPR/
    prob\d*\.pl
    minimize_bug.t
};

my $IGNORE_USERS_OF = join '|', qw{
    Dios
    Kavorka
    Keyword::Declare
    Method::Signatures
    NewMultimethods
    Object::InsideOut::Declare
    Class::Contract
    Object::Result
    List::Gather
    Perl6::
},
    q{Attribute::Handlers::Prospective \s++ 'Perl6'}
;

# PPI has some problems too...
my @PPI_BUGS = (
    qr{\\%/},
);

# Where to start...
my $rootdir = $ARGV[0] // $SOURCE_ROOT;

# Grab all the Perl files...
my @filelist = glob
               join q{ },
               map { $rootdir . ('/*' x $_) . '/*.{pm,pl,t}' }
               1..$MAX_DEPTH;

# Create the test file...
my $testfile = IO::File->new($TEST_FILE_NAME, 'w')
    or die "Could not open test file '$TEST_FILE_NAME' for writing\n";

# Set up the test...
print {$testfile} <<'TEST_FILE_HEADER';
use warnings;
use strict;

use Test::More;
use PPR;

my $source_sample = q{};
my $start_line;

while (my $line = <DATA>) {
    if ($line =~ /^####/) {
        if ($source_sample =~ /\S/) {

            my $matched
                = $source_sample =~ m{
                    \A (?&PerlOWS) (?&PerlBlock) (?&PerlOWS) \Z

                    $PPR::GRAMMAR
                }x;

            ok $matched => "Block starting at line $start_line";
            note $source_sample if !$matched;
        }
        $source_sample = q{};
        $start_line = undef;
    }
    else {
        $start_line //= $.;
        $source_sample .= $line;
    }
}

done_testing();


__DATA__
TEST_FILE_HEADER

# Draw the progress bar...
my $scale = @filelist / $PLOT_WIDTH;
print {*STDERR} '0% |' . (' ' x $PLOT_WIDTH) . " | 100%\r0% |";

my %seen;
my $count = 0;

FILE:
for my $n ( keys @filelist ) {
    # Report progress...
    print {*STDERR} '=' if $n % $scale == 0;

    # Skip weird places...
    next FILE if $filelist[$n] =~ $IGNORE_FILES;

    # Parse the file...
    my $document = eval{ PPI::Document->new( $filelist[$n] ) };
    next FILE if !eval{ $document->complete }
              || $document =~ m{ \b use \s++ (?> $IGNORE_USERS_OF )
                               | \b use_ok \s++ (?: qq?\{ | ['"] )?+ (?> $IGNORE_USERS_OF )
                               }xms;

    my $blocks_ref = eval { $document->find('PPI::Structure::Block') }
        or next FILE;

    my @blocks
        = map  { s{ is export\b}{ :export}g; $_ }
          grep {    !$seen{$_}
                 && $_ !~ / ^ \{ .* [^\}] $ /x
                 && !$_->find('PPI::Token::HereDoc')
               } @{$blocks_ref}
                    or next FILE;

    say {$testfile} "#### $filelist[$n]";

    for my $block (@blocks) {
        no warnings;

        next if "$block" ~~ @PPI_BUGS;

        next if $block =~ m{ \A \s* \{ \s* form }xms;

        say {$testfile} $block;
        say {$testfile} "####";

        $count += 1 + $block =~ s/^####/####/;
    }
}

say "\n";
say "Found $count blocks";

__END__

=head1 NAME

gen_blocks.pl - Generate test of block matching by scouring a source tree

=head1 VERSION

This documentation refers to gen_blocks.pl version 0.0.1

=head1 USAGE

    gen_blocks.pl [options]

=head1 REQUIRED ARGUMENTS

=over

None

=back

=head1 OPTIONS

=over

None

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 BUGS

None reported.
Bug reports and other feedback are most welcome.


=head1 AUTHOR

Damian Conway C<< DCONWAY@cpan.org >>


=head1 COPYRIGHT

Copyright (c) 2017, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.



