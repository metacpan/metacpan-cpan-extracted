package Parse::StackTrace::Type::Python::Frame;
use Moose;
use Parse::StackTrace::Exceptions;
use Data::Dumper;

extends 'Parse::StackTrace::Frame';

has 'error_location' => (is => 'ro', isa => 'Int');

our $FUNCTIONLESS_FRAME = qr/
    ^\s*File\s*"(.+?)",   # 1 file
    \s*(?:line)?\s*(\d+)  # 2 line
/x;

our $FULL_FRAME = qr/
    $FUNCTIONLESS_FRAME,
    \s*in\s*(\S+)       # 3 function
/x;
  
our $DJANGO_FRAME = qr/
    ^\s*File\s*"(.+?)"  # 1 file
    \s*in\s+(\S+)       # 2 function
    \s*(\d+)\.          # 3 line
    \s+(.+)             # 4 code
/x;

use constant SYNTAX_ERROR_CARET => qr/^\s*\^\s*$/;

sub parse {
    my ($class, %params) = @_;
    my $lines = $params{'lines'};
    my $debug = $params{'debug'};
    
    my ($parsed, $remaining_lines) = $class->_run_regexes($lines, $debug, [
        { regex => $FULL_FRAME, fields => [qw(file line function)] },
        { regex => $FUNCTIONLESS_FRAME, fields => [qw(file line)] },
        { regex => $DJANGO_FRAME, fields => [qw(file function line code)]},
    ]);
    
    if ($parsed and !exists $parsed->{function}) {
        $parsed->{function} = '';
    }
    
    if (!$parsed) {
        my $text = join("\n", @$lines);
        Parse::StackTrace::Exception::NotAFrame->throw(
            "Not a valid Python stack frame: $text"
        );
    }

    if (!$parsed->{code}) {
        my $code_line = shift @$remaining_lines;
        foreach my $line (@$remaining_lines) {
            if ($line =~ SYNTAX_ERROR_CARET) {
                my $caret_pos = index($line, '^');
                # Account for leading space on the code line
                if ($code_line =~ /^(\s+)/) {
                    $caret_pos -= length($1);
                }
                $parsed->{error_location} = $caret_pos;
                print "Error Location: $caret_pos" if $debug;
                last;
            }
            $code_line .= " $line";
        }
        
        $code_line = trim($code_line);
        if ($code_line) {
            $parsed->{code} = $code_line;
        }
    }
   
    print STDERR "Parsed As: " . Dumper($parsed) if $debug;
    return $class->new(%$parsed);
}

sub _run_regexes {
    my ($class, $lines, $debug, $tests) = @_;
    
    my (@remaining_lines, $parsed);
    foreach my $test (@$tests) {
        @remaining_lines = @$lines;
        $parsed = _check_lines_against_regex(\@remaining_lines, $test->{regex},
                                             $test->{fields}, $debug);
        return ($parsed, \@remaining_lines) if $parsed;
    }
    return ();
}

sub _check_lines_against_regex {
    my ($lines, $regex, $fields, $debug) = @_;

    my $text = '';
    while (my $line = shift @$lines) {
        $text .= " $line";
        if ($text =~ $regex) {
            my @matches = ($1, $2, $3, $4);
            my %parsed;
            for (my $i = 0; $i < scalar(@$fields); $i++) {
                $parsed{$fields->[$i]} = $matches[$i];
            }
            return \%parsed;
        }
    }
    
    print STDERR "Failed Match Against $regex: [$text]\n" if $debug;
    
    return undef;

}

sub trim {
    my $str = shift;
    return undef if !defined $str;
    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    return $str;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Parse::StackTrace::Type::Python::Frame - A frame from a Python stack trace

=head1 DESCRIPTION

This is an implementation of L<Parse::StackTrace::Frame>.

Python frames always have a C<file> and C<line> specified.

Most frames also have a C<function>. If they don't, the C<function> will
be an empty string.

Every frame should have C<code> specified, though there's always a chance
that we're parsing an incomplete traceback, in which case C<code> will be
C<undef>.

There is also an extra accessor for Python frames called C<error_location>.
If this trace is because of a SyntaxError, then this is an integer
indicating what character (starting from 0) in the C<code> Python thinks
the syntax error starts at.