package Spellunker::CLI::Perl;
use 5.008005;
use strict;
use warnings;

use Getopt::Long;
use Spellunker::Perl;
use Term::ANSIColor qw(colored);
require Win32::Console::ANSI if $^O eq 'MSWin32';
use PPI;

use version; our $VERSION = version->declare("v0.3.2");

sub new {
    my $class = shift;
    bless {
        color => -t STDOUT ? 1 : 0,
    }, $class;
}

sub color { $_[0]->{color} }

sub run {
    my $self = shift;

    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case auto_help)]
    );
    $p->getoptions(
        'subname' => \my $subname,
        'v|version' => \my $show_version
    );
    if ($show_version) {
        print "spellunker-pod: $VERSION\n";
        exit 0;
    }

    if (@ARGV) {
        my $fail = 0;
        for my $filename (@ARGV) {
            my $spellunker = Spellunker::Perl->new_from_file($filename);
            my @err;
            push @err, $spellunker->check_comment();
            push @err, $spellunker->check_sub_name() if $subname;
            $self->_show_error($filename, @err);
            $fail++ if @err;
        }
        exit $fail;
    } else {
        my $content = join('', <>);
        my $spellunker = Spellunker::Perl->new_from_string($content);
        my @err;
        push @err, $spellunker->check_comment();
        push @err, $spellunker->check_sub_name() if $subname;
        $self->_show_error('-', @err);
        exit @err ? 1 : 0;
    }
}

sub _show_error {
    my ($self, $filename, @err) = @_;

    for (@err) {
        my ($lineno, $line, $errs) = @$_;
        my $result;
        if ($self->color) {
            $result = $line;
            $result =~ s!\Q$_!colored(['red'], $_)!e for @$errs;
        } else {
            $result = join ' ', @$errs;
        }
        print "$filename: $lineno: $result\n";
    }
}

1;
