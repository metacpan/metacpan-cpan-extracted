package Mojo::Log::Syslog;
use strict;
use warnings;
use Mojo::Base 'Mojo::Log';
use File::Basename 'basename';
use Sys::Syslog qw(:standard :macros);
use Carp;

our $VERSION = '1.0';

sub new {
    my $class = shift;
    local %_ = @_;
    my $ident = delete $_{ident} || basename($0);
    my $facility = delete $_{facility} || LOG_USER;
    my $level = delete $_{level} || 'debug';
    my $logopt = delete $_{logopt} || 'ndelay,pid';
    if (ref($logopt) eq 'ARRAY') {
	$logopt = join(',', @$logopt);
    }
    croak "unrecognized arguments" if keys(%_);
    openlog($ident, $logopt, $facility);
    return $class->SUPER::new(level => $level);
}

sub debug { shift->_syslog(debug => LOG_DEBUG => @_) }
sub warn  { shift->_syslog(warn  => LOG_WARN  => @_) }
sub info  { shift->_syslog(info  => LOG_INFO  => @_) }
sub error { shift->_syslog(error => LOG_ERROR => @_) }
sub fatal { shift->_syslog(fatal => LOG_CRIT  => @_) }

sub _syslog {
    my ($self, $level, $prio, @args) = @_;
    $self->{_priority} = $prio;
    $self->${\ "SUPER::$level"}(@args);
}

sub append {
    my ($self, $msg) = @_;
    syslog($self->{_priority}, "%s", $msg);
}

has format => sub { shift->short ? \&_fmt_short : \&_fmt_long };

sub _fmt_short {
    my (undef, undef, @lines) = @_;
    return join("\n", @lines);
}

sub _fmt_long {
    my (undef, $level, @lines) = @_;
    return "[$level]: ".join("\n", @lines);
}

1;
__END__

=head1 NAME

Mojo::Log::Syslog - syslog for Mojo projects

=head1 SYNOPSIS

    use Mojo::Log::Syslog;

    $logger = new Mojo::Log::Syslog(facility => 'user',
                                    ident => 'myapp',
                                    level => 'warn');

    app->log($logger);

=head1 DESCRIPTION

Syslog-based logger for Mojo applications.

=head1 CONSTRUCTOR

The B<Mojo::Log::Syslog> constructor takes the following keyword arguments,
all of which are optional:

=over 4

=item B<facility =E<gt>> I<FACILITY>

Sets the syslog facility to use. Valid facility names are: C<auth>,
C<authpriv>, C<cron>, C<daemon>, C<ftp>, C<kern>, C<local0> through
C<local7>, C<lpr>, C<mail>, C<news>, C<user>, and C<uucp>. See also
B<Sys::Syslog>(3), section B<Facilities>.

The default is C<user>.

=item B<ident =E<gt>> I<STRING>

Syslog message identifier. Defaults to the base name from B<$0>.

=item B<logopt =E<gt>> I<OPTLIST>

Defines the list of options for B<openlog>. I<OPTLIST> is either a string
with comma-separated option names or a list reference containing option
names. The following two options are equivalent:

    logopt => "ndelay,pid,nowait"

    logopt => [qw(ndeay pid nowait)]

See B<Sys::Syslog>(3) for a list of available option names.
    
Defaults to C<ndelay,pid>.

=item B<level E<gt>> I<NAME>

Sets minimum logging level. See B<Mojo::Log>, for a list of levels.    
    
=back

=head1 METHODS

All methods are inherited from B<Mojo::Log>. The methods B<debug>, B<warn>,
B<info>, and B<error> log their messages using the corresponding B<syslog>
priorities. The method B<fatal> uses the C<crit> (B<LOG_CRIT>) priority.    
    
=head1 EXAMPLE

=head2 Using with Mojolicious::Lite

    use Mojolicious::Lite;
    use Mojo::Log::Syslog;

    my $logger = new Mojo::Log::Syslog(facility => 'local0',
                                       level => 'warn');
    app->log($logger);

=head2 Using with Mojolicious

    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my $self = shift;
 
        my $logger = new Mojo::Log::Syslog(facility => 'local0',
                                           level => 'warn');
        $self->app->log($logger);
    }

=head1 SEE ALSO

B<Mojo::Log>(3),     
B<Mojolicious>(3),
B<Mojolicious::Guides>(1),
L<http://mojolicious.org>.

=cut
    
