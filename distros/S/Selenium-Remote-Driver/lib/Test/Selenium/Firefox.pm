package Test::Selenium::Firefox;
$Test::Selenium::Firefox::VERSION = '1.12';
use Moo;
extends 'Selenium::Firefox', 'Test::Selenium::Remote::Driver';

1;

__END__

=head1 NAME

Test::Selenium::Firefox

=head1 SYNOPSIS

    my $test_driver = Test::Selenium::Firefox->new;
    $test_driver->get_ok('https://duckduckgo.com', "Firefox can load page");
    $test_driver->quit();

=head1 DESCRIPTION

A subclass of L<Selenium::Firefox> which provides useful testing functions.  Please see L<Selenium::Firefox> and L<Test::Selenium::Remote::Driver> for usage information.

