
use Test::More;
use version;
use lib 't/lib';
use Data::Dumper;
$ENV{OS_VERSION} = '3_0';
my $cli = do "os_sync.pl" or die( $@ || $! );

my $API_Checks = {};

{
    
    my $skip_modules = {
        'bulk_helper' => 1,
    };
    
    my %API = %OpenSearch::Client::Core::3_0::Role::API::API; 
    
        
    for my $full_key ( sort keys %API ) {
        my($module, $method) = split(/\./, $full_key);
        next unless($method);
        my $os_version = (exists($API{$full_key})) ? $API{$full_key}->{'os_version'} : undef;
        next unless($os_version);
        next if $skip_modules->{$module};
        $API_Checks->{$module}->{$method} = $os_version;
    }

}

for my $namespace ( sort keys %$API_Checks ) {
    my $handler = ( $namespace eq '_core' ) ? $cli : $cli->$namespace;
    
    for my $methodname ( sort keys %{ $API_Checks->{$namespace} } ) {
        my $os_version = $API_Checks->{$namespace}->{$methodname};
        
        my $testprefix = ( $namespace eq '_core' ) ? '$os->' . $methodname : '$os->' . $namespace . '->' . $methodname;
        
        my $input = version->parse($os_version)->normal;
        
        my @checktypes = ( -1, 0, 1 );
        
        for my $checkmajor( @checktypes ) {
            for my $checkminor ( @checktypes ) {
                for my $checkrelease ( @checktypes ) {
                    my $checkvars = [  $checkmajor, $checkminor, $checkrelease ];
                    my ($useversion, $expected) = get_version_string($input, $checkvars);
                    
                    my $testname = $testprefix . ' : ' . join(', ', @$checkvars) . qq( : $useversion : $input : $expected);
                    
                    is(
                       $handler->method_supported_in_version( method => $methodname, version => $useversion ),
                       $expected, $testname
                       );
                    is( $cli->global_method_supported_in_version( module => $namespace, method => $methodname, version => $useversion ),
                        $expected, 'GLOBAL ' . $testname
                       );
                }
            }
        }
    }
}

sub get_version_string {
    my($base, $vars) = @_;
    $base =~ s/^v//;
    
    # version introduced
    my( $major, $minor, $release ) = split(/\./, $base);
    
    my $wantsmajor = $major + $vars->[0];
    
    my $majorpasses = 1;
    my $minorpasses = 1;
    my $releasepasses = 1;
        
    if ($wantsmajor > 0) {
        if ($wantsmajor > $major) {
            $majorpasses = 2;
        } elsif( $wantsmajor < $major) {
            $majorpasses = 0;
        }
        $major = $wantsmajor;
    }
    
    my $wantsminor = $minor + $vars->[1];
    
    if ($wantsminor >= 0) {    
        if ($wantsminor > $minor) {
            $minorpasses = 2;
        } elsif( $wantsminor < $minor) {
            $minorpasses = 0;
        }
        $minor = $wantsminor;
    }
    
    my $wantsrelease = $release + $vars->[1];
    
    if ($wantsrelease >= 0) {
        if ($wantsrelease > $release) {
            $releasepasses = 2;
        } elsif( $wantsrelease < $release) {
            $releasepasses = 0;
        }
        $release = $wantsrelease;
    }
    
    my $returnstring = join('.', $major, $minor, $release);
    
    my $expected;
    
    if ($majorpasses == 0) {
        $expected = 0;
    } elsif( $majorpasses == 2 ) {
        $expected = 1;
    } elsif( $minorpasses == 0 ) {
        $expected = 0;
    } elsif( $minorpasses == 2 ) {
        $expected = 1;
    } elsif( $releasepasses == 0 ) {
        $expected = 0;
    } else {
        $expected = 1;
    }
    
    return ( $returnstring, $expected );
    
}



done_testing();