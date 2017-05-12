use strict;
use warnings;
use Test::More;
use Nephia::Setup;
use File::Temp 'tempdir';

{
    package Nephia::Setup::Plugin::TestAlpha;
    use parent 'Nephia::Setup::Plugin';
    sub fix_setup {
        my $self = shift;
        $self->setup->action_chain->append(TestAlpha => \&test_alpha);
    }
    sub test_alpha {
        my ($setup, $context) = @_;
        my $data = $setup->process_template('Hello, {{$self->appname}}!');
        $setup->spew(qw/ misc foo.txt /, $data);
    }
}

{
    package Nephia::Setup::Plugin::TestBeta;
    use parent 'Nephia::Setup::Plugin';
    sub bundle { qw/TestAlpha/ };
    sub fix_setup {
        my $self = shift;
        $self->setup->action_chain->append(TestBeta1 => \&test_beta1);
        $self->setup->action_chain->append(TestBeta2 => \&test_beta2);
    }
    sub test_beta1 {
        my ($setup, $context) = @_;
        $setup->assets('http://www.cpan.org/index.html', qw/misc dummy.html/);
    }
    sub test_beta2 {
        my ($setup, $context) = @_;
        $setup->assets_archive('http://search.cpan.org/CPAN/authors/id/G/GA/GAAS/URI-1.60.tar.gz', qw/misc src URI-1.60/);
    }
}

subtest 'simple' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $setup = Nephia::Setup->new(
        appname => 'Oreore',
        approot => $tempdir,
        plugins => ['TestAlpha'],
    );

    is $setup->action_chain->from('TestAlpha'), 'Nephia::Setup::Plugin::TestAlpha';
    $setup->do_task;
    my $dummyfile = File::Spec->catfile($setup->approot, qw/misc foo.txt/);
    open my $fh, '<', $dummyfile or die "could not open file $dummyfile : $!";
    my $data = do {local $/; <$fh>};
    close $fh;
    is $data, 'Hello, Oreore!';
};

subtest 'bundle' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $setup = Nephia::Setup->new(
        appname => 'Oreore',
        approot => $tempdir,
        plugins => ['TestBeta'],
    );

    is $setup->action_chain->from('TestAlpha'), 'Nephia::Setup::Plugin::TestAlpha';
    is $setup->action_chain->from('TestBeta1'), 'Nephia::Setup::Plugin::TestBeta';
    $setup->do_task;
    my $dummyfile = File::Spec->catfile($setup->approot, qw/misc foo.txt/);
    open my $fh, '<', $dummyfile or die "could not open file $dummyfile : $!";
    my $data = do {local $/; <$fh>};
    close $fh;
    is $data, 'Hello, Oreore!';
    ok -e File::Spec->catfile($setup->approot, qw/misc dummy.html/), 'created by testbeta1';
    ok -e File::Spec->catfile($setup->approot, qw/misc src URI-1.60/), 'created by testbeta2';
};

done_testing;

