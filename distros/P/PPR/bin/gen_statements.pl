#! /usr/bin/env perl

use 5.014;
use warnings;
use List::Util 'max';
use PPI;
use experimentals;

my $MAX_DEPTH      = 10;
my $PLOT_WIDTH     = 50;

my $SOURCE_ROOT    = glob( shift // '~/src/Perl' );
die "Not a valid root directory: $SOURCE_ROOT" 
    if !-d $SOURCE_ROOT;

my $TEST_FILE_NAME = $SOURCE_ROOT;
   $TEST_FILE_NAME =~ s{/}{_}g;
   $TEST_FILE_NAME =~ s{\W}{-}g;
   $TEST_FILE_NAME = 'extended_tests/statements__' . $TEST_FILE_NAME;

say "Loading statements from: $SOURCE_ROOT\n" 
  . "into PPR testing file:   $TEST_FILE_NAME\n";

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
     q{{ $_->translate($_[0]{V}) } @{$_[0]{A}}},
    qr{Local::Null::Logger},
    qr{META_OPTIONS},
    qr{sub bin_uncompress},
    qr{sub scalar },
    qr{package Language::Basic},
    qr{package Object::InsideOut;},
    qr{MTIME_A},
    qr{Object::InsideOut::MODIFY_SCALAR_ATTRIBUTES = sub},
    qr{^undef %/;},
     q{->{$_}},
    qr{package DemonStration::Sandbox1;},
    qr{package Demon::Stration::Sandbox1;},
    qr{sub enlighten\(\@\)},
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
    if ($line =~ /^#<>>>>/) {
        if ($source_sample =~ /\S/) {

            my $matched
                = $source_sample =~ m{
                    \A (?&PerlOWS) (?&PerlStatement) (?&PerlOWS) \Z

                    $PPR::GRAMMAR
                }x;

            ok $matched => "Statement starting at line $start_line";
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

    my $statements_ref = eval { $document->find('PPI::Statement') }
        or next FILE;

    my @statements
        = map  { s{ is export\b}{ :export}g; $_ }
          grep {    !$seen{$_}
                 && !$_->isa('PPI::Statement::End')
                 && !$_->isa('PPI::Statement::Data')
                 && !$_->find('PPI::Token::HereDoc')
                 && $_ !~ / \A (?> , | => ) /xms
                 && $_ !~ / \A \s* - (?> [mys] | tr | q[qrwx] ) \s* \Z /xms
                 && $_ !~ / \A \s* :? \w+ \s* \Z /xms
                 && $_ !~ / \A \s* \{ .* [^\}] \s* \Z /xms
                 && $_ !~ / [:*][\$\@%] | --> | \$\w+ (?: : (?! [:] ) | [!?] ) /xms
               } @{$statements_ref}
                    or next FILE;

    say {$testfile} "#<>>>> $filelist[$n]";

    STATEMENT:
    for my $statement (@statements) {
        no warnings;
        next STATEMENT
            if $statement->isa('PPI::Statement::Expression')
            && !defined eval "sub { $statement }";

        my $statement_text = "$statement";
        for my $bug (@PPI_BUGS) {
            next STATEMENT if $statement_text ~~ $bug;
        }

        next STATEMENT
            if $statement =~ m{ \A \s* print \s+ form [^\n]* <<
                              | \A \s* \{ \s* form
                              }xms;

        if ($statement =~ m{ ^ format \s }xms) {
            $statement =~ s{ ^ \. \n \K .*}{}xms;
        }
        elsif ($statement =~ s{ ^ (?> package | sub ) [^\n]* \{ [^\n*]* \} \h* \n \K .* }{}xms) {
            # THE TEST ACTUALLY FIXES IT
        }
        elsif ($statement =~ m{ ^ package [^\n]* \{ }xms) {
            $statement =~ s{ ^ \} \K .*}{}xms;
        }

        say {$testfile} $statement;
        say {$testfile} "#<>>>>";

        $count += 1 + $statement =~ s/^#<>>>>/#<>>>>/;
    }
}

say "\n";
say "Found $count statements";

__END__

=head1 NAME

gen_statements.pl - Generate test of statement matching by scouring a source tree

=head1 VERSION

This documentation refers to gen_statements.pl version 0.0.1

=head1 USAGE

    gen_statements.pl [options]

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


