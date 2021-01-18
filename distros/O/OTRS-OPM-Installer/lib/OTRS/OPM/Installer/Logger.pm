package OTRS::OPM::Installer::Logger;
$OTRS::OPM::Installer::Logger::VERSION = '0.05';
# ABSTRACT: A simple logger for OTRS::OPM::Installer

use strict;
use warnings;

use Moo;
use IO::All;
use File::Temp;
use Time::Piece;

my $file = File::Temp->new->filename;

has log  => ( is => 'ro', lazy => 1, default => sub { $file } );

for my $level (qw/notice info debug warn error/) {
    no strict 'refs';
    *{"OTRS::OPM::Installer::Logger::$level"} = sub {
        shift->print( $level, @_ );
    };
}

sub print {
    my ($self, $tag, %attr) = @_;

    my $attrs   = join " ", map{
        my $escaped = $attr{$_} // '';
        $escaped =~ s{\\}{\\\\}g;
        $escaped =~ s{"}{\\"}g;

        sprintf '%s="%s"', $_, $escaped
    }sort keys %attr;

    my $date    = localtime;
    my $message = sprintf "[%s] [%s %s] %s \n", uc $tag, $date->ymd, $date->hms, $attrs;
    $message >> io $self->log;
}

sub BUILD {
    my ($self, $param) = @_;

    if ( $param->{path} ) {
        $file = $param->{path};
    }

    my $date    = localtime;
    my $message = sprintf "[DEBUG] [%s %s] Start installation...\n", $date->ymd, $date->hms;

    $message > io $self->log
}
    
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Installer::Logger - A simple logger for OTRS::OPM::Installer

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use OTRS::OPM::Installer::Logger;
    
    my $logger = OTRS::OPM::Installer::Logger->new; # creates a new temporary file
    
    # or
    my $logger = OTRS::OPM::Installer::Logger->new(
        path => 'my_otrs_installer.log',
    );

    $logger->debug( message => 'message' );
    $logger->error( type => 'cpan', message => 'Cannot install module' );
    $logger->notice( message => 'test' );
    $logger->info( any_key => 'a value' );
    $logger->warn( module => 'test', text => 'a warning' );

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
