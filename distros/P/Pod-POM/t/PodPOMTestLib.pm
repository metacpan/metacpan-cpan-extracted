# $Id: TestUtils.pm 4100 2009-02-25 22:20:47Z andrew $

package PodPOMTestLib;

use strict;
use vars qw(@EXPORT);

use parent 'Exporter';

use Pod::POM;
use Test::More;
use File::Slurper 0.004 qw/ read_binary /;
use YAML::Tiny;

# use Data::Dumper; # for debugging


@EXPORT = qw(run_tests get_tests);


#------------------------------------------------------------------------
# run_tests()
#
# Runs all the tests of the specified type/subtype (e.g. Pom => 'dump', 
# or View => $view
#------------------------------------------------------------------------

sub run_tests {
    my ($type, $subtype) = @_;
    my $view;

    my @tests = get_tests(@_);

    my $pod_parser = Pod::POM->new();

    if (lc $type eq 'view') {
        $view = "Pod::POM::View::$subtype";
        eval "use $view;";
        if ($@) {
            plan skip_all => "couldn't load $view";
            exit(0);
        }
    }

    plan tests => int @tests;

    # Select whether to use eq_or_diff() or is() according to whether
    # Test::Differences is available.

    eval {
	require Test::Differences;
	Test::Differences->import;
    };
    my $eq = $@ ? \&is : \&eq_or_diff;

    foreach my $test (@tests) {
      TODO:
        eval {
            local $TODO;
            $TODO = $test->options->{todo} || '';

            my $pom    = $pod_parser->parse_text($test->input)
                or die $pod_parser->error;
            my $result = $view ? $pom->present($view) : $pom->dump;

            $eq->($result, $test->expect, $test->title);
        };
        if ($@) {
            diag($@);
            fail($test->title);
        }
    }
}

#------------------------------------------------------------------------
# get_tests()
#
# Finds all the tests of the specified type/subtype
#------------------------------------------------------------------------

sub get_tests {
    my ($type, $subtype) = @_;
    (my $testcasedir = $0) =~ s{([^/]+)\.t}{testcases/};
    my (@tests, $testno);

    my $expect_ext = $type;
    $expect_ext .= "-$subtype" if $subtype;
    $expect_ext = lc $expect_ext;

    foreach my $podfile (sort <$testcasedir/*.pod>) {
	$testno++;
	(my $basepath = $podfile) =~ s/\.pod$//;
        (my $basename = $basepath) =~ s{.*/}{};
	next unless -f "${basepath}.$expect_ext";
	my ($title, $options);
	my $podtext = read_binary($podfile);
	my $expect  = read_binary("${basepath}.$expect_ext");
        require Encode;
        Encode::_utf8_on($expect);

        # fetch options from YAML files - need to work out semantics

	if (my $ymltext = -f "${basepath}.yml" && read_binary("${basepath}.yml")) {
	    my $data = Load $ymltext;
	    $title   = $data->{title};
            if (exists $data->{$expect_ext}) {
                $options = $data->{$expect_ext};
            }
        }
        
        push @tests, PodPOMTestCase->new( { input   => $podtext,
                                            options => $options || {},
                                            expect  => $expect,
                                            title   => $title || $basename } );

    }

    return @tests;
}

1;

package PodPOMTestCase;

use strict;

sub new {
    my ($class, $opts) = @_;

    return bless $opts, $class;
}

sub input   { return $_[0]->{input};   }
sub options { return $_[0]->{options}; }
sub expect  { return $_[0]->{expect};  }
sub title   { return $_[0]->{title};   }

1;
