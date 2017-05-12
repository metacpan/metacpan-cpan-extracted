package SmokeRunner::Multi::TestSet::SVN;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Represents a set of test based on an SVN checkout
$SmokeRunner::Multi::TestSet::SVN::VERSION = '0.21';
use strict;
use warnings;

use base 'SmokeRunner::Multi::TestSet';

use DateTime::Format::Strptime;
use File::Spec;
use File::Which;
use SmokeRunner::Multi::SafeRun qw( safe_run );


sub _new
{
    my $class = shift;
    my %p     = @_;

    return unless -d File::Spec->catdir( $p{set_dir}, '.svn' );

    return bless \%p, $class;
}

sub _last_mod_time
{
    my $self = shift;

    my $uri = $self->_svn_uri();

    my $output = $self->_run_svn( 'info', $uri );

    die "Cannot get last_mod_time for SVN set in " . $self->set_dir()
        unless $output =~ /^Last Changed Date: (\S+) (\S+) (\S+)/m;

    my ( $date, $time, $tz ) = ( $1, $2, $3 );

    my $parser = 
        DateTime::Format::Strptime->new
            ( pattern   => '%F %T',
              time_zone => $tz,
            );

    return $parser->parse_datetime("$date $time")->epoch;
}

sub _svn_uri
{
    my $self = shift;

    return $self->{svn_uri} if $self->{svn_uri};

    my $output = $self->_run_svn( 'info', $self->set_dir() );

    die "Cannot determine svn URI\n"
        unless $output =~ /^URL: (\S+)/m;

    return $self->{svn_uri} = $1;
}

sub update_files
{
    my $self = shift;

    $self->_run_svn(  'up', $self->set_dir() );
}

sub _run_svn
{
    my $self = shift;

    my $stdout;
    my $stderr;
    safe_run( command       => 'svn',
              args          => [@_],
              stdout_buffer => \$stdout,
              stderr_buffer => \$stderr,
            );

    die "Error running svn:\n$stderr\n"
        if $stderr;

    return $stdout;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi::TestSet::SVN - Represents a set of test based on an SVN checkout

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  my $set = SmokeRunner::Multi::TestSet->new( set_dir => 'path/to/set' );

=head1 DESCRIPTION

This test set subclass will be used when a test set is an SVN
checkout, which is determined by looking for a F<.svn> directory in
the set directory.

=head1 METHODS

This class provides the following methods:

=head2 $set->last_mod_time()

This subclass will run F<svn info> on the checkout's URI to get the
last modified time for the whole set, not just test files.

=head2 $set->update_files()

This calls F<svn up> to update the test set.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-smokerunner-multi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 LiveText, Inc., All Rights Reserved.

This program is free software; you can redistribute it and /or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by LiveText, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
