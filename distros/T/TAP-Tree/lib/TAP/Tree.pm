package TAP::Tree;

use strict;
use warnings;
use v5.10.1;
use utf8;

our $VERSION = 'v0.0.5';

use Carp;
use autodie;
use Encode qw[decode];

sub new {
    my $class  = shift;
    my %params = @_;

    my $self = {
        tap_file    => $params{tap_file},
        tap_ref     => $params{tap_ref},
        tap_tree    => $params{tap_tree},

        utf8        => $params{utf8},

        is_parsed   => undef,

        result      => {
            version     => undef,
            plan        => undef,
            testline    => [],
            bailout     => undef,
        },
    };

    bless $self, $class;

    $self->_validate;
    $self->_initialize;

    return $self;
}

sub is_utf8     { return $_[0]->{utf8}      }
sub is_parsed   { return $_[0]->{is_parsed} }

sub _check_for_parsed { croak "not parsed" unless $_[0]->is_parsed }

sub summary {
    my $self = shift;

    $self->_check_for_parsed;

    my $failed_tests = 0;
    for my $testline ( @{ $self->{result}{testline} } ) {
        $failed_tests++ if ( $testline->{result} == 0 && ! $testline->{todo} );
    }

    my $is_bailout    = $self->{result}{bailout} ? 1 : 0;
    my $ran_tests     = scalar @{ $self->{result}{testline} };
    my $is_good_plan  = ( defined $self->{result}{plan}{number} ) ? 1 : 0;

    my $is_ran_all_tests = ( $is_good_plan and $ran_tests != 0 and $self->{result}{plan}{number} == $ran_tests ) ? 1 : 0;

    my $summary = {
        version         => $self->{result}{version},

        is_skipped_all  => defined $self->{result}{plan}{skip_all} ? 1 : 0,
        skip_all_msg    => $self->{result}{plan}{skip_all} ?
            $self->{result}{plan}{directive} : undef,

        is_bailout      => defined $self->{result}{bailout} ? 1 : 0,
        bailout_msg     => $self->{result}{bailout} ?
            $self->{result}{bailout}{message} : undef,

        planned_tests   => $self->{result}{plan}{number},
        ran_tests       => $ran_tests,
        failed_tests    => $failed_tests,

        is_good_plan    => $is_good_plan,
        is_ran_all_tests => $is_ran_all_tests,

        # for backward compatibility
        bailout     => $self->{result}{bailout},
        plan        => $self->{result}{plan},
        tests       => scalar @{ $self->{result}{testline} },
        fail        => $failed_tests,
    };

    return $summary;
}

sub tap_tree {
    my $self = shift;

    $self->_check_for_parsed;

    return $self->{result};
}

sub create_tap_tree_iterator {
    my $self   = shift;
    my %params = @_;

    require TAP::Tree::Iterator;
    my $iterator = TAP::Tree::Iterator->new( tap_tree => $self->tap_tree, %params );

    return $iterator;
}

sub _validate {
    my $self = shift;

    if ( $self->{tap_ref} ) {
        if ( $self->{tap_file} or $self->{tap_tree} ) {
            croak "Excessive parameter";
        }

        if ( ref( $self->{tap_ref} ) ne 'SCALAR' ) {
            croak "Parameter 'tap_ref' is not scalar reference";
        }

        return $self;
    }

    if ( $self->{tap_file} ) {
        if ( $self->{tap_ref} or $self->{tap_tree} ) {
            croak "Excessive parameter";
        }

        if ( ! -e -f -r -T $self->{tap_file} ) {
            croak "Paramter 'tap_file' is invalid:$self->{tap_file}";
        }

        return $self;
    }

    if ( $self->{tap_tree} ) {
        if ( $self->{tap_file} or $self->{tap_ref} ) {
            croak "Excessive parameter";
        }

        if ( ref( $self->{tap_tree} ) ne 'HASH' ) {
            croak "Parameter 'tap_tree' is not hash reference";
        }

        my @keys = qw[version plan testline];
        for my $key ( @keys ) {
            if ( ! defined $self->{tap_tree}{$key} ) {
                croak "Parameter 'tap_tree' is invalid tap tree:$key";
            }
        }

        return $self;
    }

    croak "No required parameter ( tap_ref or tap_file ot tap_tree )";
}

sub _initialize {
    my $self = shift;

    if ( $self->{tap_tree} ) {
        $self->{result} = $self->{tap_tree};    # Not deep copy.
        $self->{is_parsed}++;

        return $self;
    }

}

sub parse {
    my $self   = shift;

    if ( $self->{is_parsed} ) {
        croak "TAP is already parsed.";
    }

    my $path = ( $self->{tap_file} ) ? $self->{tap_file} : $self->{tap_ref};

    open my $fh, '<', $path;
    $self->{result} = $self->_parse( $fh );
    close $fh;

    $self->{is_parsed}++;

    return $self->{result};
}

sub _parse {
    my ( $self, $fh ) = @_;

    my $result = {
        version     => undef,
        plan        => undef,
        testline    => [],
        bailout     => undef,
        parse_error => [],
    };

    my @subtest_lines;
    while ( my $line_raw = <$fh> ) {

        my $line = ( $self->{utf8} ) ? decode( 'UTF-8', $line_raw ) : $line_raw;

        chomp $line;

        next if ( $line =~ /!\s*#/ );   # skip all comments.

        # Bail Out!
        # NOTE
        # 'Test-Simple < 0.98_01' can't handle BAIL_OUT in subtest correctly.
        # Since TAP-Tree requires 'Test-Simple >= 1.001002'.
        if ( $line =~ /^Bail out!\s+(.*)/ ) {
            $result->{bailout} = {
                str     => $line,
                message => $1,
            };

            last;
        }

        # tap version

        # Deleted the parsing code for the version of tha TAP.
        # Since a specified of a version is unnecessary
        # for the version lower than 12
        # It is due to add when supporting version 13.

        # plan
        if ( $line =~ /^(\s*)1\.\.\d+(\s#.*)?$/ ) {

            if ( $1 ) { # subtest
                push @subtest_lines, $line;
            } else {
                if ( $result->{plan}{number} ) {
                    croak "Invalid TAP sequence. Plan is already specified.";
                }

                $result->{plan} = $self->_parse_plan( $line );
            }

            next;
        }

        # testline
        if ( $line =~ /^(\s*)(not )?ok/ ) {

            if ( $1 ) { # subtest
                push @subtest_lines, $line;
            } else {
                my $subtest = $self->_parse_subtest( \@subtest_lines );
                push @{ $result->{testline} },
                     $self->_parse_testline( $line, $subtest );
            }

            next;
        }

        # 'unknown' line.
        push @{ $self->{result}{parse_error} }, $line;
    }

    if ( ! $result->{version} ) {
        $result->{version}{number} = 12;    # Default tap version is '12' now.
    }

    if ( ! $result->{plan} ) {
        $result->{plan}{number} = undef;
    }

    return $result;
}

sub _parse_plan {
    my $self = shift;
    my $line = shift;

    my $plan = {
        str         => $line,
        number      => undef,
        skip_all    => undef,
        directive   => undef,
    };

    {
        $line =~ /^1\.\.(\d+)\s*(# .*)?/;

        $plan->{number} = $1;
        $plan->{skip_all}++ if ( $plan->{number} == 0 );

        if ( $2 ) {
            $plan->{directive} = $2;
            $plan->{directive} =~ s/^#\s+//;
        }
    }

    return $plan;
}

sub _parse_testline {
    my $self    = shift;
    my $line    = shift;
    my $subtest = shift;

    my $testline = {
        str         => $line,
        result      => undef,       # 1 (ok) or 0 (not ok)
        test_number => undef,
        description => undef,
        directive   => undef,
        todo        => undef,       # is todo test?
        skip        => undef,       # is skipped?
        subtest     => $subtest,
    };

    {
        $line =~ /(not )?ok\s*(\d+)?(.*)?/;

        $testline->{result} = $1 ? 0 : 1;
        $testline->{test_number} = $2 if $2;    # test number is optional

        my $msg = $3;

        if ( $msg && $msg =~ /^\s?(-\s.+?)?\s*(#\s.+?)?\s*$/ ) {
            if ( $1 ) { # matched description
                $testline->{description} = $1;
                $testline->{description} =~ s/^-\s//;
            }

            if ( $2 ) { # matched directive
                $testline->{directive} = $2;
                $testline->{directive} =~ s/^#\s//;
                $testline->{todo}++ if ( $testline->{directive} =~ /TODO/i );
                $testline->{skip}++ if ( $testline->{directive} =~ /skip/i );
            }
        }
    }

    return $testline;
}

sub _parse_subtest {
    my $self        = shift;
    my $subtest_ref = shift;

    return unless $subtest_ref;
    return unless @{ $subtest_ref };

    my $subtest_result = {
        plan        => undef,
        testline    => [],
        subtest     => undef,
    };

    my $indent;
    {
        $subtest_ref->[-1] =~ /^(\s+).*/;
        $indent = length( $1 );
    }

    my @subtest_more;
    while( @{ $subtest_ref } ) {
        my $subtest_line = shift @{ $subtest_ref };

        my ( $indent_current, $line );
        {
            $subtest_line   =~ /^(\s+)(.*)/;
            $indent_current = length( $1 );
            $line           = $2;
        }

        if ( $indent_current > $indent ) {
            push @subtest_more, $subtest_line;
            next;
        }

        # parse plan
        if ( $line =~ /^1\.\.\d+/ ) {
            $subtest_result->{plan} = $self->_parse_plan( $line );
            next;
        }

        # parse testline
        if ( $line =~ /^(not )?ok/ ) {
            my $subtest = $self->_parse_subtest( \@subtest_more );
            push @{ $subtest_result->{testline} },
                 $self->_parse_testline( $line, $subtest );
            next;
        }
    }

    return $subtest_result;
}

1;

__END__

=pod

=head1 NAME

TAP::Tree - TAP (Test Anything Protocol) parser which supported the subtest

=head1 SYNOPSIS

Parses a TAP output.

  use v5.10.1;
  require TAP::Tree;
  my $tap = <<'END';
  1..2
      ok 1 - sub test 1
      1..1
  ok 1 - test 1
  not ok 2 - test 2
  END

  my $taptree = TAP::Tree->new( tap_ref => \$tap );
  my $tree = $taptree->parse;   # return value is hash reference simply.

  say $tree->{plan}{number};             # -> print 2
  say $tree->{testline}[0]{description}; # -> print test 1
  say $tree->{testline}[1]{description}; # -> print test 2

  say $tree->{testline}[0]{subtest}{testline}[0]{description};
  # -> print sub test 1

Summarises the parsed TAP output

  my $summary = $taptree->summary;
  say $summary->{planned_tests}; # -> print 2
  say $summary->{ran_tests};     # -> print 2
  say $summary->{failed_tests};  # -> print 1 ... number of failed tests.
                                # 'TODO' tests are counted as 'ok', not 'not ok'

Iterates the parsed TAP

  my $iterator = $taptree->create_tap_tree_iterator( subtest => 1 );
  
  while ( my $result = $iterator->next ) {
      say '>' x $result->{indent} . $result->{testline}{description};
  }

  # -> print
  #   test 1
  #   >sub test 1
  #   test 2

=head1 DESCRIPTION

TAP::Tree is a simple parser of TAP which supported the subtest. 

It parses the data of a TAP format to the data of tree structure.

Moreover, the iterator for complicated layered tree structure is also prepared.

=head1 METHODS

=over 2

=item * new

  require TAP::Tree;
  my $taptree = TAP::Tree->new( tap_ref => $tap_ref );

Creates the instance of C<TAP::Tree>.

Specify the reference to the scalar variable which stored the outputs of TAP as tap_ref of an arguments. 

The arguments can be specified C<tap_file> and C<tap_tree> in addition to C<tap_ref>.

C<tap_file> is specified the path to file which stored the outputs of TAP.

  my $taptree = TAP::Tree->new( tap_file => $path );

C<tap_tree> is specified the data of the tree structure which C<TAP::Tree> parsed.

  my $taptree = TAP::Tree->new( tap_tree => $parsed_tap );

C<utf8> is specified, when TAP is encoded by UTF-8. 

  my $taptree = TAP::Tree->new( tap_ref => $tap_ref, utf8 => 1 );

=item * parse

  require TAP::Tree;
  my $taptree = TAP::Tree->new( tap_ref => $tap_ref );
  my $tree    = $taptree->parse;

  say $tree->{plan}{number};
  say $tree->{testline}[0]->{description};

Parses a output of TAP and returns the tree structure data. The return value is a hash reference and all of the parsed result of TAP are stored.

Please dump the detailed content of inclusion :)

  {
      version   => {},  # the version number of TAP (usually 12). 
      plan      => {},  # the hash reference in which the numbers of tests.
      testline  => [],  # the array reference in which the result of each tests.
      bailout   => {},  # the hash reference in which an informational about Bailout.
  }

=item * summary

Returns the summary  of the TAP output.

The contents of a summary is below ( hash reference ).

  version          -> the version number of TAP (usually 12).
  is_skipped_all   -> the flag that shows whether all the tests were skipped.
  skip_all_msg     -> the message that shows the reason of skip tests.
  is_bailout       -> the flag that shows whether bailout the tests.
  bailout_msg      -> the message that shows the reason of bailout.
  planned_tests    -> the number of the planned tests.
  ran_tests        -> the number of the ran tests.
  failed_tests     -> the number of the failed tests.
  is_good_plan     -> the flag that shows whether the number of plan is set.
  is_ran_all_tests -> the flag that shows whether the all tests are ran.

=item * create_tap_tree_iterator

C<TAP::Tree> makes becomes the complicated structure where a hierarchy is deep, when there is a subtest. 

Therefore, the iterator which can follow a tree strucutre data easily is prepared for C<TAP::Tree>. 

  my $taptree = TAP::Tree->new( tap_ref => $tap_ref );
  $taptree->parse;
  my $iterator = $taptree->create_tap_tree_iterator( subtest => 1);

  my $test = $iterator->next;
  say $test->{testline}{description};

Specify arguments C<subtest>, when following subtest. 

=back

=head1 ISSUE REPORT

L<https://github.com/magnolia-k/p5-TAP-Tree/issues>

=head1 COPYRIGHT

copyright 2014- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
