package OpenPlugin::Log;

# $Id: Log.pm,v 1.17 2003/04/28 17:43:48 andreychek Exp $

use strict;
use OpenPlugin::Plugin;

@OpenPlugin::Log::ISA     = qw( OpenPlugin::Plugin );
$OpenPlugin::Log::VERSION = sprintf("%d.%02d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'log' }

sub log {
    my $self = shift;
    my $level = shift || 0;

    warn "The log function is deprecated!\n";
    my $msg = join( ' ', @_ );
    warn( $msg, $level );
}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Log - Log messages

=head1 SYNOPSIS

 $OP->log->debug( "The flyswatter is in the corner." );
 $OP->log->info(  "Successfully read the newspaper." );
 $OP->log->warn(  "Watch out for that tree!" );
 $OP->log->error( "A general exception error has occurred." );
 $OP->log->fatal( "Humpty Dumpty had a great fall." );

=head1 DESCRIPTION

This logging interface is built on top of L<Log::Log4perl>.  It comes with five
predefined logging levels, and the ability to dispatch logs to one or more
sources.

First, you can configure the logging level in the config file.  By default, the
logging level is C<WARN>.  That means that messages of level C<WARN>, C<ERROR>,
and C<FATAL> will be shown.  This allows you to control how much logging takes
place.  Typically, you would just leave the logging level at C<WARN>.  But what
happens when things aren't working quite right?  You can increase the
information to be logged by setting the log level to C<INFO> or C<DEBUG>.

What happens when you're working with a large application, and you only wish to
debug one portion of your program?  This is where Log4perl really starts to
shine.  Using an OO-like heirarchy, you can set different logging levels
for any portion of your application.  Additionally, you can alter the
destination of the log information based on this same heirarchy.

For an excellent introduction into how you can use this logging facility,
please check out L<Retire your debugger, log smartly with
Log::Log4perl!|http://www.perl.com/pub/a/2002/09/11/log4perl.html>.

=head1 METHODS

B<debug( $message )>

B<info( $message )>

B<warn( $message )>

B<error( $message )>

B<fatal( $message )>

Log C<$message> when at that level or higher.  Returns true if a message was
logged, false otherwise.

B<is_debug()>

B<is_info()>

B<is_warn()>

B<is_error()>

B<is_fatal()>

Determine's the current log level.  Returns true if at that level or higher,
false otherwise.

B<more_logging( $delta )>

B<less_logging( $delta )>

B<inc_level( $delta )>

B<dev_level( $delta )>

This allows you to increase or decrease the current level of logging from
within your program.  C<$delta> must be a positive integer.

=head1 BUGS

None known.

=head1 TO DO

None known.

=head1 SEE ALSO

L<OpenPlugin>, L<Log::Log4perl>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
