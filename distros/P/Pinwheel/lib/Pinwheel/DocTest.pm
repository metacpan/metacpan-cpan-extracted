package Pinwheel::DocTest;

use strict;
use warnings;

use Data::Dumper;
use PPI;
use Test::Builder;
use Test::More;


sub p
{
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    return Dumper(shift) . "\n";
}

sub is_silent
{
    my ($coderef, $d) = @_;

    $d = PPI::Document->new($coderef);
    return $d->find_any(sub {
        $_[1]->isa('PPI::Token::Operator') and $_[1]->content eq '='
    });
}

sub _expand_ellipsis
{
    my ($s) = @_;
    $s = join('.*',
        map { s/([\$\^\.\*\+\?\(\)\{\}\[\]\|\\])/\\$1/g; $_ }
        split(/\.\.\./, $s)
    );
    return qr/^$s$/s;
}

sub run_tests
{
    my ($pkg, $tests) = @_;
    my ($test, $fh, $testfn, $output, $got);

    $test = Test::More->builder;
    $fh = $test->todo_output;
    local $Test::Builder::Level = 0;
    foreach (@$tests) {
        my ($input, $expected, $line, $comment) = @$_;
        tie(*STDOUT, 'Pinwheel::DocTest::CaptureOut');
        $got = eval qq{
            package $pkg;
            no strict qw(vars subs refs);
#line $line "console"
            $input;
        };
        $output = <STDOUT>;
        untie(*STDOUT);
        if ($@) {
            $got = $@;
        } elsif (is_silent(\$input)) {
            $got = undef;
        } else {
            $got = p($got);
            $got = $output . $got if defined($output);
        }
        if (defined($expected) && $expected =~ /\.\.\./) {
            $expected = _expand_ellipsis($expected);
            $testfn = 'like';
        } else {
            $testfn = 'is_eq';
        }
        if ($comment) {
            $comment =~ s/^\s*\n//s;
            $comment =~ s/\s*$//;
            $comment =~ s/\n/\n# /g;
            print $fh "# $comment\n";
        }
        eval qq{
            package $pkg;
#line $line "console"
            \$test->$testfn(\$got, \$expected);
        };
    }
}


sub test_file
{
    my ($filename) = @_;
    my ($fh, $pkg, $end, @tests);
    my ($in_doctest, $indent, $input, $output, $line, $comment);

    open($fh, "< $filename");
    $pkg = caller();
    $end = 0;
    $in_doctest = 0;

    while (!$end) {
        $_ = <$fh>;
        $end = !defined($_);
        # Fake a blank line at the end to ensure the final test is picked up
        $_ = '' if $end;

        if (/^=begin\s+doctest\b/) {
            $in_doctest = 1;
        } elsif (!$in_doctest) {
            next;
        } elsif (/^(\s*)>>> (.+)/) {
            if (defined($input)) {
                push @tests, [$input, $output, $line, $comment];
                $comment = undef;
            }
            $indent = $1;
            $input = $2 . "\n";
            $output = undef;
            $line = $.;
        } elsif (defined($input) && (/^\s*$/ || /^=cut\b/)) {
            $in_doctest = 0 if /^=cut\b/;
            push @tests, [$input, $output, $line, $comment];
            $input = undef;
            $comment = undef;
        } elsif (!defined($input)) {
            if (/^=cut\b/) {
                $in_doctest = 0;
            } else {
                $comment = ($comment || '') . $_;
            }
        } elsif (!defined($output) && /^$indent\.\.\. (.+)/) {
            $input .= $1 . "\n";
        } elsif (/^$indent<BLANKLINE>\s*$/) {
            $output = ($output || '') . "\n";
        } else {
            /^$indent(.+)/;
            $output = ($output || '') . $1 . "\n";
        }
    }
    run_tests($pkg, \@tests);

    close($fh);
}



package Pinwheel::DocTest::CaptureOut;

sub TIEHANDLE
{
    return bless([], $_[0]);
}

sub PRINTF
{
    my ($self, $format, @args) = @_;
    push @$self, sprintf($format, @args);
}

sub PRINT
{
    my ($self, @args) = @_;
    push @$self, join('', @args);
}

sub READLINE
{
    my ($self) = @_;
    return scalar(@$self) ? join('', @$self) : undef;
}



package Pinwheel::DocTest::Mock;

use Carp;
use overload '&{}' => \&getfn;

our $AUTOLOAD;


sub new
{
    my ($class, $name) = @_;
    return bless({name => $name, results => {}}, $class);
}

sub getfn
{
    my ($self) = @_;

    return sub {
        my $result;
        print "Called $self->{name} with " . Pinwheel::DocTest::p(\@_);
        $result = $self->{results}{''};
        return $result->(@_) if (ref($result) eq 'CODE');
        return $result;
    };
}

sub AUTOLOAD
{
    my $self = shift;
    my ($name, $result);

    $name = $AUTOLOAD;
    $name =~ s/.*:://;
    return unless ($name =~ /[a-z]/);
    if ($name =~ /(.+)_returns$/ || $name =~ /^returns$/) {
        $self->{results}{$1 || ''} = shift;
        return;
    }

    print "Called $self->{name}\->$name with " . Pinwheel::DocTest::p(\@_);
    $result = $self->{results}{$name};
    return $result->(@_) if (ref($result) eq 'CODE');
    return $result;
}


1;
