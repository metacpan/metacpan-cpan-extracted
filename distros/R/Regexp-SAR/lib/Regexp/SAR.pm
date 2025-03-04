package Regexp::SAR;
# ABSTRACT: Regexp::SAR - perl module implementing regular expression engine for handling matching events (Simple API for Regexp)




use strict;
use warnings;


require XSLoader;
XSLoader::load( 'Regexp::SAR' );


sub new {
    my $class = shift;

    my $obj = [];
    my $rootNode = Regexp::SAR::buildRootNode();
    return bless \$rootNode, $class;
}

sub addRegexp {
    my ( $rootRef, $regexpStr, $handler ) = @_;
    my $reLength = length $regexpStr;
    unless ($reLength) {
        return;
    }
    Regexp::SAR::buildPath( $$rootRef, $regexpStr, $reLength, $handler );
}

sub match {
    my ( $rootRef, $matchStr ) = @_;
    if (ref $matchStr) {
        Regexp::SAR::lookPathRef( $$rootRef, $matchStr, 0 );
    }
    else {
        Regexp::SAR::lookPath( $$rootRef, $matchStr, 0 );
    }
}

sub matchRef {
    my ( $rootRef, $matchStr ) = @_;
    Regexp::SAR::lookPathRef( $$rootRef, $matchStr, 0 );
}

sub matchFrom {
    my ( $rootRef, $matchStr, $pos ) = @_;
    if (ref $matchStr) {
        Regexp::SAR::lookPathRef( $$rootRef, $matchStr, $pos );
    }
    else {
        Regexp::SAR::lookPath( $$rootRef, $matchStr, $pos );
    }
}

sub matchAt {
    my ( $rootRef, $matchStr, $pos ) = @_;
    Regexp::SAR::lookPathAtPos( $$rootRef, $matchStr, $pos );
}

sub stopMatch {
    my ( $rootRef ) = @_;
    Regexp::SAR::stop($$rootRef);
}

sub continueFrom {
    my ( $rootRef, $from ) = @_;
    Regexp::SAR::continue($$rootRef, $from);
}

sub DESTROY {
    my ( $rootRef ) = @_;
    Regexp::SAR::cleanAll($$rootRef);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::SAR - Regexp::SAR - perl module implementing regular expression engine for handling matching events (Simple API for Regexp)

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Regexp::SAR;
    
    my $sar1 = new Regexp::SAR;
    my $matched = 0;
    $sar1->addRegexp('abc', sub {$matched = 1;});
    $sar1->match('mm abc nn');
    if ($matched) {
        #proc matching        
    }
    
    #################################################
    #index many regexp for single match run
    my @matched;
    my $sar2 = new Regexp::SAR;
    my $regexps = [
                    ['ab+c', 'First Match'],
                    ['\d+', 'Second Match'],
                  ];
    my $string;
    foreach my $re (@$regexps) {
        my ($reStr, $reTitle) = @$re;
        $sar2->addRegexp( $reStr,
                        sub {
                            my ($from, $to) = @_;
                            my $matchStr = substr($string, $from, $to - $from);
                            push @matched, "$reTitle: $matchStr";
                            $sar2->continueFrom($to);
                        } );
    }
    $string = 'first abbbbc second 123 end';
    $sar2->match(\$string);
    # @matched has ('First Match: abbbbc', 'Second Match: 123')

    #################################################
    #get third match and stop
    my $sar3 = new Regexp::SAR;
    my $matchedStr3;
    my $matchCount = 0;
    my $string3 = 'aa11 bb22 cc33 dd44';
    $sar3->addRegexp('\w+', sub {
                                my ($from, $to) = @_;
                                ++$matchCount;
                                if ($matchCount == 3) {
                                    $matchedStr3 = substr($string3, $from, $to - $from);
                                    $sar3->stopMatch(); 
                                }
                                else {
                                    $sar3->continueFrom($to);
                                }
                            });
    $sar3->match($string3);
    # $matchCount is 3, $matchedStr3 is 'cc33'
    
    #################################################
    #get match only at certain position
    my $sar4 = new Regexp::SAR;
    my $matchedStr4;
    my $string4 = 'aa11 bb22 cc33 dd44';
    $sar4->addRegexp('\w+', sub {
                                my ($from, $to) = @_;
                                $matchedStr4 = substr($string4, $from, $to - $from);
                            });
    $sar4->matchAt($string4, 5);
    #$matchedStr4 is 'bb22'
    
    #################################################
    #negative matching
    my $sar5 = new Regexp::SAR;
    $sar5->addRegexp('a\^\d+b', sub { print "Matched\n"; });
    $sar5->match('axyzb');

=head1 DESCRIPTION

Regexp::SAR (Simple API for Regexp) module build trie structure
for many regular expressions and store match handler for each
regular expression that will be called when match occurs.
There is no limit for number of regular expressions.
Handler called immediately on match and it get matching start
and end positions in matched string. Matching can be started from
any point in matching string. Match handler can decide from which
point matching should continue or it can stop matching at all.

=head1 NAME

Regexp::SAR - perl module implementing regular expression engine for handling matching events (Simple API for Regexp)

=head1 METHODS

=head2 new()

Create new Regexp::SAR object. Every object store it's own trie
structure separately. When object goes out of scope object and it's
internal data structure will be cleared from memory.

=head2 addRegexp

Add regular expression for handling. First parameter is regular
expression string. Second parameter is reference to subroutine
that will be called when match on this regexp occurs. Handler
subroutine get as input two integers, matching start and matching
end. Matching start is position of first matching character.
Matching end is position after last matching character.

  my $sar = new Regexp::SAR;
  my $string = 'a123b';
  $sar->addRegexp('\d+', sub {
                              my ($from, $to) = @_;
                              # $from is 1
                              # $to is 4
                              $sar->stopMatch();
                          });
  $sar->match($string);

=head2 match

Process matching all added regular expressions on matching string
passed to C<match> as parameter. C<match> can accept matching string
as reference to scalar, it useful when matching string is very long.

=head2 matchFrom

Process matching from specific position. Get two parameters: matching
string and number from which start processing. C<match> subroutine
is syntactic sugar form C<matchFrom> when second parameter is 0.

=head2 matchAt

Process matching from specific position and do not continue on next
characters.

=head2 continueFrom

C<continueFrom> subroutine called in matching handler and define
from which position continue matching after it finished matching
on current position.

=head2 stopMatch

C<stopMatch> subroutine called in matching handler and send signal
to Regexp::SAR object do not continue matching on next characters.

=head1 Matching rules

=over

=item *

Continue matching process character by character even if there was match.

  my $sar = new Regexp::SAR;
  my $string = 'a123b';
  $sar->addRegexp('\d+', sub {
                              my ($from, $to) = @_;
                              $matchedStr = substr($string, $from, $to - $from);
                              print "Found number is: $matchedStr\n";
                          });
  $sar->match($string);

Above code will print 3 times strings: '123', '23', '3'
In case it should be matched only once use C<continueFrom>.

=item *

Call all matching handlers that could be found from matching position.

  my $sar = new Regexp::SAR;
  $sar->addRegexp('new', sub { print "new found\n"; });
  $sar->addRegexp('new york', sub { print "new york found\n"; });
  $sar->match('new york');

Above code will print "new found", then print "new york found"

=item *

Call all matching handlers from different regular expressions
that match same matched string.

  my $sar = new Regexp::SAR;
  $sar->addRegexp('1', sub { print "one found\n"; });
  $sar->addRegexp('\d', sub { print "digit found\n"; });
  $sar->match('1');

Above code will print both 'one found' and 'digit found'

=back

=head1 Character class abbreviations

=over

=item *

'.' matches any character

=item *

'\s' matches space character (checked by internal isSPACE)

=item *

'\d' matches digit character (checked by internal isDIGIT)

=item *

'\w' matches alphanumeric character (checked by internal isALNUM)

=item *

'\a' matches alpha character (checked by internal isALPHA)

=item *

'\^' matches any character that is not followed character or class abbreviation

=back

=head1 Matching repetitions

=over

=item *

'?' means: match 1 or 0 times

=item *

'*' means: match 0 or more times

=item *

'+' means: match 1 or more times

=back

=head1 '\' escape character

For matching '\' character in matching string regular expression string should
iclude it 4 times '\\\\'.

  my $sar = new Regexp::SAR;
  my $string = 'a b\c d';
  $sar->addRegexp('b\\\\c', sub { print "Matched\n"; });
  $sar->match($string);

=head1 Unicode support

Currently this module does not support unicode matching

=head1 Examples

Many usage examples can be found in "OOUsage.t" file

=head1 AUTHOR

Pinkhas Nisanov <pinkhas@nisanov.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Pinkhas Nisanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
