use strict;
use warnings;
use Config;
use constant SLEEP => 5;

validate_env();
my %params = (
    name      => 'testing',
    rotatable => 1,
    time      => 1
);
run_test( \%params );
$params{name} = 'A really long name to see how this goes';
run_test( \%params );
$params{size} = 30;
run_test( \%params );
$params{size} = 5;
run_test( \%params );

sub validate_env {

    unless ( ( exists( $ENV{TERMYAP_DEVEL} ) ) and ( $ENV{TERMYAP_DEVEL} ) ) {
        require Test::Builder;
        my $test = Test::Builder->new;
        $test->skip_all(
            'Not a developer machine. Set enviroment variable TERMYAP_DEVEL
 to 1 and use "perl -Ilib" instead of "prove" if you want to run this test correctly'
        );
        exit;
    }
    else {
        print <<BLOCK;
Don't even bother trying to run this with prove... the output will not be the
expected one.

Just use "perl -Ilib" to run this test and be able to see the ASCII animation.
Since you will be watching... you should see a "pulse bar" running for a while,
stopping and starting again once more.

Something like this:

testing............................Done
testing...[  /             ] (0.400642 sec elapsed)

Now check it yourself:
BLOCK
    }
}

sub run_test {
    my $params_ref = shift;
    my $yap;

    if ( $Config{useithreads} ) {
        require Term::YAP::iThread;
        $yap = Term::YAP::iThread->new($params_ref);
    }
    else {
        require Term::YAP::Process;
        $yap = Term::YAP::Process->new($params_ref);
    }

    $yap->start();
    sleep SLEEP;
    $yap->stop();
    print "\n";
    sleep 1;
    $yap->start();
    sleep SLEEP;
    $yap->stop();
    print "\n";

}
