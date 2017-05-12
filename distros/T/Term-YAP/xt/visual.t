use strict;
use warnings;
use Config;

my $yap;
my $sleep = 5;

my %params = (
    name      => 'testing',
    rotatable => 1,
    time      => 1
);

unless ( ( exists( $ENV{TERMYAP_DEVEL} ) ) and ( $ENV{TERMYAP_DEVEL} ) ) {

    require Test::Builder;
    my $test = Test::Builder->new;
    $test->skip_all(
'Not a developer machine. Set enviroment variable TERMYAP_DEVEL to 1 and use "perl -Ilib" instead of "prove" if you want to run this test correctly'
    );

}
else {

    print <<BLOCK;
Don't even bother trying to run this with prove... the output will not be the expected one.
Just use "perl -Ilib" to run this test and be able to see the ASCII animation.
Since you will be watching... you should see a "pulse bar" running for a while, stopping and starting again once more.
Something like this:

testing............................Done
testing...[  /             ] (0.400642 sec elapsed)

Now check it yourself:
BLOCK

    if ( $Config{useithreads} ) {

        require Term::YAP::iThread;
        $yap = Term::YAP::iThread->new( \%params );

    }
    else {

        require Term::YAP::Process;
        $yap = Term::YAP::Process->new( \%params );

    }

    $yap->start();
    sleep $sleep;
    $yap->stop();
    print "\n";
    sleep 1;
    $yap->start();
    sleep $sleep;
    $yap->stop();

}

print "\n";
