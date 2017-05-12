#line 1
#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Test-Perl-Critic-1.01/lib/Test/Perl/Critic.pm $
#     $Date: 2007-01-24 22:22:10 -0800 (Wed, 24 Jan 2007) $
#   $Author: thaljef $
# $Revision: 1183 $
########################################################################

package Test::Perl::Critic;

use strict;
use warnings;
use Carp qw(croak);
use English qw(-no_match_vars);
use Test::Builder qw();
use Perl::Critic qw();
use Perl::Critic::Violation qw();
use Perl::Critic::Utils;


#---------------------------------------------------------------------------

our $VERSION = 1.01;

#---------------------------------------------------------------------------

my $TEST        = Test::Builder->new();
my %CRITIC_ARGS = ();

#---------------------------------------------------------------------------

sub import {

    my ( $self, %args ) = @_;
    my $caller = caller;

    no strict 'refs';  ## no critic
    *{ $caller . '::critic_ok' }     = \&critic_ok;
    *{ $caller . '::all_critic_ok' } = \&all_critic_ok;

    $TEST->exported_to($caller);

    # -format is supported for backward compatibility
    if( exists $args{-format} ){ $args{-verbose} = $args{-format}; }
    %CRITIC_ARGS = %args;

    return 1;
}

#---------------------------------------------------------------------------

sub critic_ok {

    my ( $file, $test_name ) = @_;
    croak q{no file specified} if not defined $file;
    croak qq{"$file" does not exist} if not -f $file;
    $test_name ||= qq{Test::Perl::Critic for "$file"};

    my $critic = undef;
    my @violations = ();
    my $ok = 0;

    # Run Perl::Critic
    eval {
        # TODO: Should $critic be a global singleton?
        $critic     = Perl::Critic->new( %CRITIC_ARGS );
        @violations = $critic->critique( $file );
        $ok         = not scalar @violations;
    };

    # Evaluate results
    $TEST->ok( $ok, $test_name );


    if ($EVAL_ERROR) {           # Trap exceptions from P::C
        $TEST->diag( "\n" );     # Just to get on a new line.
        $TEST->diag( qq{Perl::Critic had errors in "$file":} );
        $TEST->diag( qq{\t$EVAL_ERROR} );
    }
    elsif ( not $ok ) {          # Report Policy violations
        $TEST->diag( "\n" );     # Just to get on a new line.
        $TEST->diag( qq{Perl::Critic found these violations in "$file":} );

        my $verbose = $critic->config->verbose();
        Perl::Critic::Violation::set_format( $verbose );
        for my $viol (@violations) { $TEST->diag("$viol") }
    }

    return $ok;
}

#---------------------------------------------------------------------------

sub all_critic_ok {

    my @dirs = @_ ? @_ : _starting_points();
    my @files = all_code_files( @dirs );
    $TEST->plan( tests => scalar @files );

    my $okays = grep { critic_ok($_) } @files;
    return $okays == @files;
}

#---------------------------------------------------------------------------

sub all_code_files {
    my @dirs = @_ ? @_ : _starting_points();
    return Perl::Critic::Utils::all_perl_files(@dirs);
}

#---------------------------------------------------------------------------

sub _starting_points {
    return -e 'blib' ? 'blib' : 'lib';
}

#---------------------------------------------------------------------------

1;


__END__

#line 412
