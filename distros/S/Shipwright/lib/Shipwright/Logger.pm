package Shipwright::Logger;
use strict;
use warnings;
use Shipwright::Util;
use Log::Log4perl;
use Scalar::Util qw/blessed/;

=head1 NAME

Shipwright::Logger - Log

=head1 SYNOPSIS

    use Shipwright::Logger;

=head2 new

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    if ( not Log::Log4perl->initialized ) {
        $class->_initialize_log4perl(@_);
    }
    return $self;
}

sub _initialize_log4perl {
    my $class = shift;
    my $ref   = $_[0];

    my ( $log_level, $log_file );

    if ( blessed $ref ) {

        # so it's an object, we assuming it has log_level and log_file subs
        $log_level = $ref->log_level;
        $log_file  = $ref->log_file;
    }
    elsif ( ref $ref ) {

        # it's a hashref
        $log_level = $ref->{log_level};
        $log_file  = $ref->{log_file};
    }
    else {

        # not ref at all
        my %hash = @_;
        $log_level = $hash{log_level};
        $log_file  = $hash{log_file};
    }

    $log_level = $log_level ? uc $log_level : 'FATAL';
    $log_file ||= '-';
    my %default = (
        'log4perl.rootLogger'             => "$log_level,File",
        'log4perl.appender.File.filename' => $log_file,
        'log4perl.appender.File'          => 'Log::Log4perl::Appender::File',
        'log4perl.appender.File.stderr'   => 1,
        'log4perl.appender.File.layout' =>
          'Log::Log4perl::Layout::PatternLayout',
        'log4perl.appender.File.layout.ConversionPattern' =>
        $log_file eq '-' ? '%m%n' : '%d %p> %F{1}:%L %M - %m%n',
    );

    Log::Log4perl->init( \%default );
}

1;

__END__

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
