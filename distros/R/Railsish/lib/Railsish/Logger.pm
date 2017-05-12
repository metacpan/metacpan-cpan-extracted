package Railsish::Logger;
our $VERSION = '0.21';

use Any::Moose;
use Railsish::CoreHelpers ();
use Log::Dispatch;
use Log::Dispatch::File;
use Log::Dispatch::Screen;

has 'logger' => (
    is => "rw",
    isa => "Log::Dispatch",
    lazy_build => 1
);

sub _build_logger {
    my ($self) = @_;

    my $logger = Log::Dispatch->new;
    return $logger unless exists $ENV{APP_ROOT};

    my $logdir = Railsish::CoreHelpers::app_root("log");
    if (-d $logdir) {
        my $file = Railsish::CoreHelpers::app_root(log => "development.log");
        $logger->add(
            Log::Dispatch::File->new(
                name => "development",
                min_level => "debug",
                filename => $file));
    }

    $logger->add(
	Log::Dispatch::Screen->new(
	    name => "screen",
	    min_level => "debug",
            stderr => 1));

    return $logger;
}

sub debug {
    my ($self, $message) = @_;
    $self->logger->log(
	level => "debug",
	message => $message . "\n"
    );
}

__PACKAGE__->meta->make_immutable;

__END__
=head1 NAME

Railsish::Logger

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

