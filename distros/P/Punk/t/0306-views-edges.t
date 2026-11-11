#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest qw(hit);

# The view registry's refusals, by message: an engine class that lacks new,
# one that lacks render, one registered twice, a registry handle that is not
# one; and a render through an inline engine that has both, with the engine
# options handed to its constructor.

{
    package VE::NoNew;
    sub render { 'x' }
    package VE::Fine;
    sub new { my ($class, @o) = @_; my %o = @o == 1 && ref $o[0] eq 'HASH' ? %{ $o[0] } : @o; bless { %o }, $class }
    sub render { my ($self, $template, $data) = @_; return "[$template:" . join(',', map { "$_=$data->{$_}" } sort keys %$data) . ":$self->{flavour}]" }
    package main;
}
use File::Temp ();
use File::Path ();
my $lib = File::Temp::tempdir(CLEANUP => 1);
File::Path::make_path("$lib/VE");
{ open my $fh, '>', "$lib/VE/NoRender.pm" or die; print $fh "package VE::NoRender;\nsub new { bless {}, shift }\n1;\n"; close $fh }
unshift @INC, $lib;
my $n = 0;
sub compiles {
    my ($body) = @_;
    my $pkg = 'VE' . ++$n;
    my $e = '';
    eval "package $pkg; use Punk; $body; $pkg->to_app; 1" or $e = $@;
    return $e;
}
like(compiles(q{ views '+VE::NoNew' => {} }), qr/engine 'VE::NoNew' \(VE::NoNew\) does not implement new/, 'an engine without new');
like(compiles(q{ views '+VE::NoRender' => {} }), qr/engine 'VE::NoRender' \(VE::NoRender\) does not implement render/, 'an engine without render');
like(compiles(q{ views '+VE::Fine' => {}; views '+VE::Fine' => {} }), qr/engine 'VE::Fine' registered twice/, 'an engine registered twice');
{
    package VEOk;
    use Punk;
    views '+VE::Fine' => { flavour => 'plain' };
    get '/' => sub { $_[0]->render('page', { a => 1, b => 2 }) };
    package main;
}
my $r = hit(VEOk->to_app, path => '/');
is($r->[0], 200, 'an inline engine with new and render serves');
is($r->[2][0], '[page:a=1,b=2:plain]', 'with the template, the data and its own options');
{
    my $e = '';
    eval { Punk::Views::engine(bless(\(my $x = 'no'), 'Punk::Views'), 'x'); 1 } or $e = $@;
    like($e, qr/Punk::Views: not a view registry/, 'a registry handle that is not one is refused');
}

done_testing;
