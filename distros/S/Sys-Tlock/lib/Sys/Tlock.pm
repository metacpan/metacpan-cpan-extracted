# Sys::Tlock.pm
# Locking with timeouts.
# (c) 2022-2023 Bjørn Hee
# Licensed under the Apache License, version 2.0
# https://www.apache.org/licenses/LICENSE-2.0.txt

package Sys::Tlock;

use experimental qw(signatures);
use strict;
# use Exporter qw(import);

our $VERSION = 0.12;

use File::Basename qw(basename dirname);
use Time::HiRes qw(sleep);
use Sys::Tlock::Config;

our @EXPORT = qwac('
    tlock_take     # Take the requested lock and give it the requested timeout, return a token.
    tlock_renew    # Set a new timeout, counting from now, for the given lock.
    tlock_release  # Remove the lock.
    tlock_alive    # True if the lock is still taken.
    tlock_taken    # True if the lock is taken, with any token.
    tlock_expiry   # Time when the lock expires.
    tlock_zing     # Clean up locks in the lock directory.
    ');

our @EXPORT_OK = qwac('
    tlock_release_careless # Remove the lock without caring about the token.
    tlock_token    # Token associated with lock.
    tlock_tstart   # Time when the lock was taken (= token).
    $dir           # The directory containing the locks.
    $marker        # The common prefix of the lock names.
    $patience      # Max waiting time in seconds, when taking a lock that is already taken.
    ');

our $dir;
our $marker;
our $patience;

# --------------------------------------------------------------------------- #
# Initialization and import.

my $home = $Config::home;


my $pnorm = sub( $p ) {
    return $p = s/([^\/])$/$1\//r;
    };


my $conf_file;
my $conf_was_read;
my $read_conf_file = sub {
    return undef if not defined $conf_file;
    return undef if not -f $conf_file;

    open my $cf , '<' , $conf_file
        or die 'Could not read configuration file "'.$conf_file.'".';
    my @cf = <$cf>;
    close $cf;
    die 'No tlock preface line in configuration file "'.$conf_file.'".'
        if $cf[0] !~ m/^tlock\s+(\d+)\s*$/;
    die 'Configuration file is too new for your tlock installation.'
        if $1 > 0;
    shift @cf;
    for my $line (map {s/^\s+//r} map {s/\s+$//r} map {s/#.*//r} @cf) {
        if ($line =~ m/^dir\s+(\S.*)$/) {
            $dir //= $pnorm->($1);
            }
        elsif ($line =~ m/^marker\s+(\S.*)$/) {
            $marker //= $1;
            }
        elsif ($line =~ m/^patience\s+(\S.*)$/) {
            $patience //= $1;
            };
        };

    $conf_was_read = 1;
    1;};


my $do_settings = sub { # is called by import
    $read_conf_file->();
    $dir //= $pnorm->($ENV{tlock_dir});
    $marker //= $ENV{tlock_marker};
    $patience //= $ENV{tlock_patience};
    $conf_file = $ENV{tlock_conf}; $read_conf_file->();
    $conf_file = '/etc/tlock.conf'; $read_conf_file->();
    $conf_file = $home.'default.conf'; $read_conf_file->();
    $dir //= $home.'locks/';
    die 'The tlock installation has been messed up.' if not $conf_was_read;
    die 'The lock directory "'.$dir.'" not found.' if not -d $dir;
    die 'Patience set to bad value "'.$patience.'".' if $patience !~ m/^\d+(?:\.\d+)?$/;
    die 'Patience set to bad value "0".' if $patience == 0;
    die 'Bad first character in marker.' if $marker !~ m/^[a-zA-Z]/;
    die 'Bad last character in marker.' if $marker !~ m/[a-zA-Z0-9]$/;
    die 'Bad character in marker.' if $marker =~ m/[^a-zA-Z0-9\-\_]/;
    1;};

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

sub import {
    my $modname = shift;

    my sub amp( $s ) {
        return undef if not defined $s;
        return $s if $s =~ m/^(?:conf|dir|marker|patience)$/;
        return $s =~ s/^([^\$\@\%\&])/\&$1/r;
        };
    my %check = map {(amp($_),1)}
        qw(conf dir marker patience) , @EXPORT , @EXPORT_OK;
    my sub exportcheck( $s ) {
        return 1 if $check{$s};
        die '"'.$s.'" not exported by module '.$modname.'.'."\n";
        };

    my $imports = 0;
    no strict "refs";
    while ($_ = amp shift) {
        exportcheck($_);
        $imports++;
        if    ( m/^\$(.*)$/ ) { *{"main::$1"} = \$$1; }
        elsif ( m/^\@(.*)$/ ) { *{"main::$1"} = \@$1; }
        elsif ( m/^\%(.*)$/ ) { *{"main::$1"} = \%$1; }
        elsif ( m/^\&(.*)$/ ) { *{"main::$1"} = \&$1; }
        else {
            die 'No '.$_.' value is given.' if scalar @_ == 0;
            $imports--;
            if    ( $_ eq 'conf' )     { $conf_file = shift; }
            elsif ( $_ eq 'dir' )      { $dir = shift; }
            elsif ( $_ eq 'marker' )   { $marker = shift; }
            elsif ( $_ eq 'patience' ) { $patience = shift; };
            };
        };
    use strict "refs";

    if ($imports == 0) {
        no strict "refs";
        for (map {amp($_)} @EXPORT) {
            if    ( m/^\$(.*)$/ ) { *{"main::$1"} = \$$1; }
            elsif ( m/^\@(.*)$/ ) { *{"main::$1"} = \@$1; }
            elsif ( m/^\%(.*)$/ ) { *{"main::$1"} = \%$1; }
            elsif ( m/^\&(.*)$/ ) { *{"main::$1"} = \&$1; };
            };
        use strict "refs";
        };

    $do_settings->();

    }; # sub import


sub qwac( $s ) {
# qw-like sub, allow comments.
    return
        grep {/./}
        map { split /\s+/ }
        map { s/#.*//r }
        split /\v+/ , $s;
    };

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

1;

# --------------------------------------------------------------------------- #
# Helper routines.

my $tdn = sub( $label ) {
# The tlock directory name.
    return $dir.$marker.'.'.$label;
    };


my $take_master = sub( $label , $p = $patience ) {
# Master lock has to be taken for any operation on the lock.

    my $now = time;

    while (1)
      { my $rv = mkdir $dir.$marker.'_.'.$label;
        last if $rv == 1; # second order success
        return if time - $now > $p;
        sleep(0.05);
      };

    1;};


my $release_master = sub( $label ) {
    rmdir $dir.$marker.'_.'.$label;
    1;};

# --------------------------------------------------------------------------- #
# Exportable routines.

sub tlock_take( $label , $timeout , $p = $patience ) {
# Take the requested lock and give it the requested timeout, return token.

    return undef if $label !~ m/^[a-zA-Z0-9\-\_\.]+$/;
    return undef if $timeout <= 0;

    $take_master->( $label ) or return;

    my $t;
    if ( not tlock_taken($label) ) {
        my $d = $tdn->($label);
        mkdir $d if not -e $d;
        mkdir $d.'/d' if not -e $d.'/d';
        $t = time;
        utime undef , $t , $d;
        utime undef , $timeout , $d.'/d';
        };

    $release_master->( $label );
    $_ = $t; return $_;
    };


sub tlock_renew( $label , $token , $timeout ) {
# Set a new timeout, counting from now, for the given lock.
    return undef if $timeout <= 0;
    $take_master->( $label ) or return undef;
    utime undef , time - $token + $timeout , $tdn->($label).'/d' if tlock_alive($label,$token);
    $release_master->( $label );
    return 1;
    };


sub tlock_release( $label , $token ) {
# Remove the lock.
    $take_master->( $label ) or return undef;
    my $t = tlock_token($label);
    if ($token == $t) {
        my $d = $tdn->($label);
        rmdir $d.'/d' if -e $d.'/d';
        rmdir $d      if -e $d;
        };
    $release_master->( $label );
    return 1;
    };


sub tlock_alive( $label , $token ) {
# True if the lock with the given token is still taken.
    my $t = tlock_token($label);
    return undef if not defined $t;
    return 1 if $token == $t;
    return undef;
    };


sub tlock_taken( $label ) {
# True if the lock is taken.
    return undef if not defined tlock_expiry($label);
    return 1;
  };


sub tlock_expiry( $label ) {
# Timestamp for when the lock expires.
    my $d = $tdn->($label);
    return undef if not -e $d;
    my $t = (stat($d))[9] + (stat($d.'/d'))[9];
    $t = undef if $t < time;
    return $t;
    };


sub tlock_zing() {
# Clean up all locks in the lock directory.
    my @dlist = glob($dir.'*');
    while (my $d = shift @dlist) {
        basename($d) =~ m/^\Q${marker}\E(?:|_)\.([a-zA-Z0-9\-\_\.]+)$/ or next;
        my $label = $1;
        tlock_take($label,10) or next;
        tlock_release($_,$label);
        };
    };

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

sub tlock_tstart( $label ) {
# Timestamp for when the lock was taken.
    return tlock_token($label);
    };


sub tlock_release_careless( $label ) {
# Remove the lock without caring about the token.
    $take_master->( $label ) or return undef;
    my $d = $tdn->($label);
    rmdir $d.'/d' if -e $d.'/d';
    rmdir $d      if -e $d;
    $release_master->( $label );
    return 1;
    };


sub tlock_token( $label ) {
# Token associated with the lock.
    my $d = $tdn->($label);
    return undef if not -e $d;
    return undef if tlock_expiry($label) < time; # timed out
    return (stat($d))[9];
    };

# --------------------------------------------------------------------------- #

=pod

=encoding utf8

=head1 NAME

Sys::Tlock - Locking with timeouts.

=head1 VERSION

0.12

=head1 SYNOPSIS

    use Sys::Tlock dir => '/var/myscript/locks/' , qw(tlock_take $patience);

    print "tlock patience is ${patience}\n";

    # taking a tlock for 5 minutes
    tlock_take('logindex',300) || die 'Failed taking the tlock.';
    my $token = $_;

    move_old_index();

    # hand over to that other script
    exec( "/usr/local/loganalyze/loganalyze" , $token );

    -----------------------------------------------------------

    use Sys::Tlock;
    # /etc/tlock.conf sets dir to "/var/myscript/locks/"

    # checking lock is alive
    my $t = $ARGV[0];
    die 'Tlock not taken.' if not tlock_alive('logrotate',$t);

    do_fancy_log_rotation(547);
    system( './clean-up.sh' , $t ) or warn 'Clean-up failed.';

    # releasing the lock
    tlock_release('logrotate',$t);

=head1 DESCRIPTION

This module is handling tlocks, advisory locks with timeouts.

They are implemented as simple directories that are created and deleted in the lock directory.

A distant predecessor to this module was written many years ago as a kludge to make locking work properly on a Windows server. But it turned out to be very handy to have tlocks in the filesystem, giving you an at-a-glance overview of them. Even the non-scripting sysadmins could easily view and manipulate tlocks.

The module is designed to allow separate programs to use the same tlocks between them. Even programs written in different languages. To do this safely, tlocks are paired with a lock token.

=head2 CONFIGURATION

The configuration parameters are set using this process:

=over

=item 1: Directly in the use statement of your script, with keys "dir", "marker" and "patience".

=item 2: Configuration file given by a "conf" key in the use statement of your script.

=item 3: Environment variables "tlock_dir", "tlock_marker" and "tlock_patience".

=item 4: Configuration file given by the environment variable "tlock_conf".

=item 5: Configuration file "/etc/tlock.conf".

=item 6: Default configuration.

=back

On top of this, you can import the $dir, $marker and $patience variables and change them in your script. But that is a recipe for disaster, so know what you do, if you go that way.

Configuration files must start with a "tlock 0" line. Empty lines are allowed and so are comments starting with the # character. There are three directives:

=over

=item C<dir> For setting the lock directory. Write the full path.

=item C<marker> For the marker (prefix) that all tlock directory names will get.

=item C<patience> For the time that the take method will wait for a lock release.

=back

    tlock 0
    # Example configuration file for tlock.
    dir      /var/loglocks/
    patience 7.5

=head2 TOKENS

Safe use of tlocks involve tokens, which are just timestamps of when the lock was taken.

Without tokens, something like this could happen...

    script1 takes lockA
    script1 freezes
    lockA times out
    script2 takes lockA
    script1 resumes
    script1 releases lockA
    script3 takes lockA

Now both script2 and script3 "have" lockA!

=head2 IN THE FILESYSTEM

Each tlock is a subdirectory of the lock directory. Their names are "${marker}.${label}". The default value for $marker is "tlock".

Each of the tlock directories has a sub directory named "d". The mtimes of these two directories saves the token and the timeout.
There also are some very shortlived directories named "${marker}_.${label}". They are per label master locks. They help making changes to the normal locks atomic.

=head1 FUNCTIONS AND VARIABLES

Loaded by default:
L<tlock_take|/tlock_take( $label , $timeout )>,
L<tlock_renew|/tlock_renew( $label , $token , $timeout )>,
L<tlock_release|/tlock_release( $label , $token )>,
L<tlock_alive|/tlock_alive( $label , $token )>,
L<tlock_taken|/tlock_taken( $label )>,
L<tlock_expiry|/tlock_expiry( $label )>,
L<tlock_zing|/tlock_zing()>

Loaded on demand:
L<tlock_tstart|/tlock_tstart( $label )>,
L<tlock_release_careless|/tlock_release_careless( $label )>,
L<tlock_token|/tlock_token( $label )>,
L<$dir|/$dir>,
L<$marker|/$marker>,
L<$patience|/$patience>

=over

=item tlock_take( $label , $timeout )

Take the tlock with the given label, and set its timeout. The call returns the associated token.

Labels can be any non-empty string consisting of letters a-z or A-Z, digits 0-9, dashes "-", underscores "_" and dots "." (PCRE: [a-zA-Z0-9\-\_\.]+)

It is possible to set a per call special patience value, by adding it as a third variable, like this: tlock_take( 'busylock' , $t , 600 )

The token value is also assigned to the $_ variable.

=item tlock_renew( $label , $token , $timeout )

Reset the timeout of the tlock, so that it will time out $timeout seconds from the time that tlock_renew is called.

=item tlock_release( $label , $token )

Release the tlock.

=item tlock_alive( $label , $token )

Returns true if the tlock is currently taken.

=item tlock_taken( $label )

Returns true if a tlock with the given label is currently taken.

The difference between tlock_taken and tlock_alive, is that alive can differentiate between different tlocks with the same label. Different tlocks with the same label can exist at different points in time.

=item tlock_expiry( $label )

Returns the time when the current tlock with the given label will expire. It is given in epoch seconds.

=item tlock_zing()

Cleans up locks in the lock directory. Takes care not to mess with any lock activity.

=item tlock_tstart( $label )

Returns the time for the creation of the current tlock with the given label. It is given in epoch seconds. This function and the token function are identical.

Only loaded on demand.

=item tlock_release_careless( $label )

Carelessly release any tlock with the given label, not caring about the token.

Only loaded on demand.

=item tlock_token( $label )

Returns the token for the current tlock with the given label.

Only loaded on demand.

=item $dir

The directory containing the tlocks.

Only loaded on demand.

=item $marker

The common prefix of the directory names used for tlocks.

Prefixes can be any non-empty string consisting of letters a-z or A-Z, digits 0-9, dashes "-" and underscores "_" (PCRE: [a-zA-Z0-9\-\_]+). First character has to be a letter, and last character a letter or digit.

Only loaded on demand.

=item $patience

Patience is the time a method will try to take or change a tlock, before it gives up. For example when tlock_take tries to take a tlock that is already taken, it is the number of seconds it should wait for that tlock to be released before giving up.

Dont confuse patience with timeout.

Default patience value is 2.5 seconds.

Only loaded on demand.

=back

=head1 DEPENDENCIES

File::Basename

Time::HiRes

=head1 KNOWN ISSUES

The author dare not guarantee that the locking is waterproof. But if there are conditions that breaks it, they must be very special. At the least, experience has shown it to be waterproof in practice.

Not tested on Windows, ironically enough.

=head1 SEE ALSO

flock

=head1 LICENSE & COPYRIGHT

(c) 2022-2023 Bjoern Hee
Licensed under the Apache License, version 2.0
https://www.apache.org/licenses/LICENSE-2.0.txt

=cut

# --------------------------------------------------------------------------- #

