package Test::Selenium::PhantomJS;
$Test::Selenium::PhantomJS::VERSION = '1.49';
use Moo;
extends 'Selenium::PhantomJS', 'Test::Selenium::Remote::Driver';

has 'webelement_class' => (
    is      => 'rw',
    default => sub { 'Test::Selenium::Remote::WebElement' },
);

1;

__END__

=head1 NAME

Test::Selenium::PhantomJS

=head1 SYNOPSIS

    my $test_driver = Test::Selenium::PhantomJS->new;
    $test_driver->get_ok('https://duckduckgo.com', "PhantomJS can load page");
    $test_driver->quit();

=head1 DESCRIPTION

A subclass of L<Selenium::PhantomJS> which provides useful testing functions.  Please see L<Selenium::PhantomJS> and L<Test::Selenium::Remote::Driver> for usage information.


