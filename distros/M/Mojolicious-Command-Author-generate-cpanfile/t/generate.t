use List::Util 'sum';
use Mojo::Base -strict;
use Mojo::File qw(path tempdir);
use Test::More 0.99;

require Mojolicious;
require Mojolicious::Command::Author::generate::cpanfile;

ok my $cpanfile = Mojolicious::Command::Author::generate::cpanfile->new, 'constructor';
isa_ok $cpanfile->app, 'Mojolicious', 'command app';
ok $cpanfile->can('run'), 'can run';
ok $cpanfile->description, 'has a description';
like $cpanfile->usage, qr/cpanfile/, 'has usage information';

my $cwd = path;
my $dir = tempdir CLEANUP => 1;

sub module_version {
    sprintf('%1.2f', sum(map { ord($_) } split(//, $_[0])) / length($_[0]) / 87)
}

{
    no warnings qw(once redefine);
    *Mojolicious::Command::Author::generate::cpanfile::path = sub {
        Mock::Mojo::File->new('.');
    };

    *Mojolicious::Command::Author::generate::cpanfile::_module_version = sub {
        my ($module) = $_[1];

        return () if $module =~ /fnord/i;

        my $version = $module =~ /^Mojo::/ ? 0 : module_version($module);

        return ($module, $version);
    };

}

chdir $dir;

my ($out, $err) = run_run('-x');
ok !$out, 'no success output';
like $err, qr/^Unknown option: x/, 'right error output';
ok !-e $cpanfile->rel_file('cpanfile'), 'cpanfile does not exist';

($out, $err) = run_run();
like $out, qr/\[write\].*\/cpanfile/, 'right success output';
ok !$err, 'no error output';
ok -e $cpanfile->rel_file('cpanfile'), 'cpanfile exists';

my $content = $cpanfile->rel_file('cpanfile')->slurp;

is $content, <<EOT, 'right cpanfile content';
# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'Mojolicious', '$Mojolicious::VERSION';
requires 'IO::File', '@{[module_version("IO::File")]}';
requires 'List::Util', '@{[module_version("List::Util")]}';
requires 'Mojo::Base';
requires 'Storable', '@{[module_version("Storable")]}';

on test => sub {
    requires 'Test::Fatal', '@{[module_version("Test::Fatal")]}';
    requires 'Test::Mojo', '@{[module_version("Test::Mojo")]}';
    requires 'Test::More', '@{[module_version("Test::More")]}';
};
EOT

$cpanfile->rel_file('cpanfile')->remove;

($out, $err) = run_run(qw(-r Net::OpenSSH -r Mojolicious::Plugin::OpenAPI -l src -t xt));
like $out, qr/cpanfile/, 'right success output';
ok !$err, 'no error output';
ok -e $cpanfile->rel_file('cpanfile'), 'cpanfile exists';

$content = $cpanfile->rel_file('cpanfile')->slurp;

is $content, <<EOT, 'right cpanfile content';
# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'Mojolicious', '$Mojolicious::VERSION';
requires 'Acme::DWIM', '@{[module_version("Acme::DWIM")]}';
requires 'Catalyst', '@{[module_version("Catalyst")]}';
requires 'Mojolicious::Plugin::OpenAPI', '@{[module_version("Mojolicious::Plugin::OpenAPI")]}';
requires 'Net::OpenSSH', '@{[module_version("Net::OpenSSH")]}';

EOT

chdir $cwd;

done_testing;

sub run_run {
    my $buffer1 = my $buffer2 = '';
    open my $stdout, '>', \$buffer1;
    open my $stderr, '>', \$buffer2;
    local *STDOUT = $stdout;
    local *STDERR = $stderr;
    $cpanfile->run(@_);

    return ($buffer1, $buffer2);
}

package Mock::Mojo::File;

use Mojo::Base 'Mojo::File';
use Mojo::Loader 'data_section';

sub list_tree {
    my $self = shift;
    my $dir  = $self->to_string;
    my $mock_data = data_section('Mock::Data');
    my @files = grep { index($_, $dir) == 0 } keys %$mock_data;

    return Mojo::Collection->new(map { Mock::Mojo::File->new($_) } @files);
}

sub slurp {
    data_section('Mock::Data', shift->to_string) . <<EODATA;
__DATA__

use CGI;

EODATA
}

package Mock::Data;

__DATA__

@@ ./lib/My::A.pm

use Mojo::Base 'My::Base';
use List::Util 'sum';

sub frobnicate { "frobnitz " . sum(@_) }

"SUCCESS";

@@ ./lib/My::B.pm

use Mojo::Base 'My::Base';
use Class::Fnord;
use IO::File;

sub new {
    my $class = shift;
    require Storable;
    bless { @_ }, $class;
}

sub to_string {
    my $self = shift;
    
    return map { join(",", "$_: " . $self->{$_}) } keys %$self;
}

@@ ./src/Other::C.pm

use Catalyst qw/-Debug/;
use Acme::DWIM;

sub foo : Chained('/') Args() {
    my ( $self, $c ) = @_;
    require Class::Fnord;
    $c->forward('Other::C::View::TT');
}

1;

@@ ./t/x.t

use Test::More;
use Test::Mojo;
use Test::Fatal;
use My::Test::Foo;

use_ok('My::B');
isa_ok($o = My:B->new(foo => "bar"));

done_testing;

@@ ./t/lib/My/Test/Foo.pm

package My::Test::Foo;

use File::Temp;

ok 1;

1;
