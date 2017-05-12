# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SFML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5 + 3 + 9 + 2;
BEGIN { use_ok('SFML::Window') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $context = new SFML::Window::VideoMode(800, 600);

isa_ok($context, "SFML::Window::VideoMode");

can_ok($context, qw(isValid getWidth getHeight getBitsPerPixel setWidth setHeight setBitsPerPixel));

can_ok("SFML::Window::VideoMode", qw(getDesktopMode getFullscreenModes));

isa_ok(SFML::Window::VideoMode::getDesktopMode, "SFML::Window::VideoMode");

$context->setBitsPerPixel(16);
my $context2 = new SFML::Window::VideoMode(1920, 1080, 32);
isa_ok($context2, "SFML::Window::VideoMode");

{
	my $context3 = new SFML::Window::VideoMode(800, 600, 16);
	my $context4 = new SFML::Window::VideoMode(800, 600, 32);
	subtest 'stringify' => sub {
		is("$context",  '800x600:16');
		is("$context2", '1920x1080:32');
		is("$context3", '800x600:16');
		is("$context4", '800x600:32');
	};
	subtest 'array deref' => sub {
		is_deeply([ @{$context} ],  [ 800,  600,  16 ]);
		is_deeply([ @{$context2} ], [ 1920, 1080, 32 ]);
		is_deeply([ @{$context4} ], [ 800,  600,  32 ]);
	};
	subtest 'hash deref' => sub {
		is_deeply({ %{$context} },  { width => 800,  height => 600,  depth => 16 });
		is_deeply({ %{$context2} }, { width => 1920, height => 1080, depth => 32 });
		is_deeply({ %{$context4} }, { width => 800,  height => 600,  depth => 32 });
	};
	ok(not($context != $context3), '!= litmus') or diag("Operator overloading is probably broken -- != is probably comparing pointers or references.\n");
	subtest '==' => sub {
		optest($context, "==", $context3);
		optest($_, "==", $_) for ($context, $context2, $context3, $context4);
		noptest($context, "==", $context2);
		noptest($context, "==", $context4);
	};
	subtest '<' => sub {
		noptest($context, "<", $context);
		optest($context, "<", $context2);
		noptest($context, "<", $context3);
		optest($context, "<", $context4);
	};
	subtest '>' => sub {
		noptest($context, ">", $context);
		optest($context2, ">", $context);
		noptest($context3, ">", $context);
		optest($context4, ">", $context);
	};
	subtest '<=' => sub {
		optest($context, "<=", $context2);
		optest($context, "<=", $context3);
		optest($context, "<=", $context4);
		noptest($context, "<=", $context);
	};
	subtest '>=' => sub {
		optest($context2, ">=", $context);
		optest($context3, ">=", $context);
		optest($context4, ">=", $context);
		noptest($context, ">=", $context);
	};
	subtest '!=' => sub {
		optest($context, "!=", $context2);
		optest($context, "!=", $context4);
		noptest($_, "!=", $_) for ($context, $context2, $context3, $context4);
	};
};

sub optest {
	cmp_ok($_[0], $_[1], $_[2], sprintf "%s %s %s", @_);
}

sub noptest {
	ok(not(eval($_[0] . $_[1] . $_[2])), sprintf("not %s %s %s", @_));
}

our %t = qw(Width 800 Height 600 BitsPerPixel 16);
is(eval '$context->get' . $_, $t{$_}, $_) for keys %t;

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut
