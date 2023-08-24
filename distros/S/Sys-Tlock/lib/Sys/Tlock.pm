# Sys::Tlock.pm
# Locking with timeouts.
# (c) 2022-2023 Bjørn Hee
# Licensed under the Apache License, version 2.0
# https://www.apache.org/licenses/LICENSE-2.0.txt

package Sys::Tlock;

use experimental qw(signatures);
use strict;
# use Exporter qw(import);

our $VERSION = 1.11;

use File::Basename qw(basename dirname);
use Time::HiRes qw(gettimeofday sleep);
use Sys::Tlock::Config;

my sub qwac( $s ) {grep{/./} map{split /\s+/} map{s/#.*//r} split/\v+/ , $s;};

our @EXPORT = qwac '
    tlock_take     # Take the requested lock and give it the requested timeout, return a token.
    tlock_renew    # Set a new timeout, counting from now, for the given lock.
    tlock_release  # Remove the lock.
    tlock_alive    # True if the lock is still taken.
    tlock_taken    # True if the lock is taken, with any token.
    tlock_expiry   # Time when the lock expires.
    tlock_zing     # Clean up locks in the lock directory.
    ';

our @EXPORT_OK = qwac '
    tlock_release_careless # Remove the lock without caring about the token.
    tlock_token    # Token associated with lock.
    tlock_tstart   # Time when the lock was taken (= token).
    $dir           # The directory containing the locks.
    $marker        # The common prefix of the lock names.
    $owner         # The UID of the owner of the lock directories.
    $patience      # Max waiting time in seconds, when taking a lock that is already taken.
    ';

our $dir;
our $marker;
our $owner;
our $patience;
my $gid;

# --------------------------------------------------------------------------- #
# Initialization and import.

my $home = $Sys::Tlock::Config::home;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

my sub dir_check( $d ) {
    return undef if not defined $d;
    if (not -d $d) { warn 'The lock directory "'.$d.'" not found.'; return undef; };
    return ($d =~ s/(?<!\/)$/\//r);
    };


my sub marker_check( $m ) {
    return undef if not defined $m;
    if ($m !~ m/^[a-zA-Z]/) { warn 'Bad first character in marker.'; return undef; };
    if ($m !~ m/[a-zA-Z0-9]$/) { warn 'Bad last character in marker.'; return undef; };
    if ($m =~ m/[^a-zA-Z0-9\-\_]/) {warn 'Bad character in marker.'; return undef; };
    return $m;
    };


my sub owner_check( $o ) {
    return undef if not defined $o;
    return [-1,-1] if $o == -1;
    my $g = (getpwuid($o))[3];
    if (not defined $g) { warn 'Owner "'.$o.'" not found.'; return undef; };
    return [$o,$g];
    };


my sub patience_check( $p ) {
    return undef if not defined $p;
    if ($p !~ m/^\d+(\.\d+)?$/n) { warn 'Patience set to bad value "'.$p.'".'; return undef; };
    return $p;
    };

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

my $memo = {};

my sub read_conf( $cf ) {
# Read and parse configuration file, return hashref with settings.

    return {} if not defined $cf;
    if (not -f $cf) {
        warn 'Could not find configuration file "'.$cf.'".';
        return undef;
        };

    return $memo->{$cf} if exists $memo->{$cf};

    my $setting = {};

    my $fh;
    if (open $fh , '<' , $cf) {;}
    else {
        warn 'Could not read configuration file "'.$cf.'".';
        return undef;
        };

    my $line = <$fh>;
    if ($line !~ m/^tlock\s+(\d+)\s*$/) {
        warn 'No tlock preface line in configuration file "'.$cf.'".';
        return undef;
        };
    if ($1 > 1) {
        warn 'Configuration file "'.$cf.'" is too new for your tlock installation.';
        return undef;
        };

    while ($line = <$fh>) {
        $line =~ s/#.*//;
        $line =~ s/\s+$//;
        if ($line =~ m/^\s*dir\s+(\S.*)$/) {
            $_ = dir_check($1);
            if (not defined) { $setting = undef; last; };
            $setting->{dir} = $_;
            }
        elsif ($line =~ m/^\s*marker\s+(\S.*)$/) {
            $_ = marker_check($1);
            if (not defined) { $setting = undef; last; };
            $setting->{marker} = $_;
            }
        elsif ($line =~ m/^\s*owner\s+(\d+|-1)$/) {
            $_ = owner_check($1);
            if (not defined) { $setting = undef; last; };
            $setting->{owner} = $_;
            }
        elsif ($line =~ m/^\s*patience\s+(\S.*)$/) {
            $_ = patience_check($1);
            if (not defined) { $setting = undef; last; };
            $setting->{patience} = $_;
            }
        elsif ($line =~ m/\S/) {
            warn 'Configuration line "'.$line.'" is not valid.';
            $setting = undef; last;
            };
        };

    close $fh;
    $memo->{$cf} = $setting;
    return $setting;
    }; # sub read_conf

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

my sub dir( $hr ) {
# For getting dir value when in runtime.
    return dir_check($hr->{dir}) // read_conf($hr->{conf})->{dir} // $dir;
    };


my sub marker( $hr ) {
# For getting marker value when in runtime.
    return marker_check($hr->{marker}) // read_conf($hr->{conf})->{marker} // $marker;
    };


my sub owner( $hr ) {
# For getting owner value when in runtime.
    return [-1,-1] if $^O eq 'MSWin32';
    return owner_check($hr->{owner}) // read_conf($hr->{conf})->{owner} // [$owner,$gid];
    };


my sub patience( $hr ) {
# For getting patience value when in runtime.
    return patience_check($hr->{patience}) // read_conf($hr->{conf})->{patience} // $patience;
    };

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

my %from_use = ();


my sub undefdie( $x ) { # For compile-time errors.
    die if not defined $x;
    return $x;
    };


my sub undefempty( $x ) {
    return {} if not defined $x;
    return $x;
    };


my sub set_defaults() { # Run at compile-time. Called by import.

    $dir =
        $from_use{dir} //
        undefdie(read_conf($from_use{conf}))->{dir} //
        dir_check($ENV{tlock_dir}) //
        undefdie(read_conf($ENV{tlock_conf}))->{dir} //
        undefempty(read_conf('/etc/tlock.conf'))->{dir} //
        undefdie(read_conf($home.'default.conf'))->{dir} //
        $home.'locks/';

    $marker =
        $from_use{marker} //
        undefdie(read_conf($from_use{conf}))->{marker} //
        marker_check($ENV{tlock_marker}) //
        undefdie(read_conf($ENV{tlock_conf}))->{marker} //
        undefempty(read_conf('/etc/tlock.conf'))->{marker} //
        undefdie(read_conf($home.'default.conf'))->{marker};

    my $og =
        $from_use{owner} //
        undefdie(read_conf($from_use{conf}))->{owner} //
        owner_check($ENV{tlock_owner}) //
        undefdie(read_conf($ENV{tlock_conf}))->{owner} //
        undefempty(read_conf('/etc/tlock.conf'))->{owner} //
        undefdie(read_conf($home.'default.conf'))->{owner} //
        [-1,-1];
    ($owner,$gid) = $og->@*;

    $patience =
        $from_use{patience} //
        undefdie(read_conf($from_use{conf}))->{patience} //
        patience_check($ENV{tlock_patience}) //
        undefdie(read_conf($ENV{tlock_conf}))->{patience} //
        undefempty(read_conf('/etc/tlock.conf'))->{patience} //
        undefdie(read_conf($home.'default.conf'))->{patience};

    if (defined $from_use{conf}) {
    # Check conf, in case it was given but not needed.
        read_conf($from_use{conf}) // die;
        };

    1;};

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

sub import {
    my $mynsp = shift;
    my $calnsp = caller;

    my sub amp( $s ) {
        return undef if not defined $s;
        return $s if $s =~ m/^(?:conf|dir|marker|owner|patience)$/;
        return $s =~ s/^([^\$\@\%\&])/\&$1/r;
        };
    my %check = map {(amp($_),1)}
        qw(conf dir marker owner patience) , @EXPORT , @EXPORT_OK;
    my sub exportcheck( $s ) {
        return 1 if $check{$s};
        die '"'.$s.'" not exported by module '.$mynsp.'.'."\n";
        };

    my $imports = 0;
    while ($_ = amp shift) {
        exportcheck($_);
        $imports++;
        no strict "refs";
        if    ( m/^\$(.*)$/ ) { *{"${calnsp}::$1"} = \$$1; }
        elsif ( m/^\@(.*)$/ ) { *{"${calnsp}::$1"} = \@$1; }
        elsif ( m/^\%(.*)$/ ) { *{"${calnsp}::$1"} = \%$1; }
        elsif ( m/^\&(.*)$/ ) { *{"${calnsp}::$1"} = \&$1; }
        else {
            die 'No '.$_.' value is given.' if scalar @_ == 0;
            $imports--;
            if    ( $_ eq 'conf' )     { $from_use{conf} = shift; }
            elsif ( $_ eq 'dir' )      { $from_use{dir} = dir_check shift; }
            elsif ( $_ eq 'marker' )   { $from_use{marker} = marker_check shift; }
            elsif ( $_ eq 'owner' )    { $from_use{owner} = owner_check shift; }
            elsif ( $_ eq 'patience' ) { $from_use{patience} = patience_check shift; };
            };
        use strict "refs";
        };

    if ($imports == 0) {
        for (map {amp($_)} @EXPORT) {
            no strict "refs";
            if    ( m/^\$(.*)$/ ) { *{"${calnsp}::$1"} = \$$1; }
            elsif ( m/^\@(.*)$/ ) { *{"${calnsp}::$1"} = \@$1; }
            elsif ( m/^\%(.*)$/ ) { *{"${calnsp}::$1"} = \%$1; }
            elsif ( m/^\&(.*)$/ ) { *{"${calnsp}::$1"} = \&$1; };
            use strict "refs";
            };
        };

    set_defaults;

    }; # sub import

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

1;

# --------------------------------------------------------------------------- #

# Each tlock is a directory in $dir.
#
# $dir
# └── $marker.$label
#     └── d
# 
# It has three values encoded: label, token and duration.
# - label is encoded in the directory name
# - token is the mtime of the directory, converted to an integer
# - duration is the mtime of the d subdirectory, converted to an integer
# The lock expires on time: token + duration
# 
# There are also shortlived per label master locks, that also are directories.
# 
# $dir
# └── $marker_.$label
# 
# They are for making changes on tlocks atomic.
# 
# Some background info:
#     https://rcrowley.org/2010/01/06/things-unix-can-do-atomically.html

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Helper routines.

my sub tdn( $label , $d , $m ) {
# The tlock directory name.
    return $d.$m.'.'.$label;
    };


my sub take_master( $label , $d , $m , $p ) {
# Master lock has to be taken for any operation on the lock.

    my $now = gettimeofday;

    while (1)
      { my $rv = mkdir $d.$m.'_.'.$label;
        last if $rv == 1; # second order success
        return if gettimeofday - $now > $p;
        sleep(0.05);
      };

    1;};


my sub release_master( $label , $d , $m ) {
    rmdir $d.$m.'_.'.$label;
    1;};

# --------------------------------------------------------------------------- #
# Exportable routines.

sub tlock_take( $label , $timeout , @nampar ) {
# Take the requested lock and give it the requested timeout, return token.

    return if $label !~ m/^[a-zA-Z0-9\-\_\.]+$/;
    return if $timeout <= 0;
    my $n;
    if (scalar @nampar == 1) { # For backwards compatability. Will be removed.
        $n = {patience => $nampar[0]};
        warn 'The optional patience parameter in tlock_take is deprecated. Use a named parameter instead.';
        }
    else {
        $n = {@nampar};
        };
    my $d = dir($n);
    my $m = marker($n);
    my ($o,$g) = owner($n)->@*;
    my $p = patience($n);

    take_master($label,$d,$m,$p) or return;

    my $t;
    if ( not tlock_taken($label,$n->%*) ) {
        my $tdn = tdn($label,$d,$m);
        mkdir $tdn if not -e $tdn;
        chown $o , $g , $tdn;
        mkdir $tdn.'/d' if not -e $tdn.'/d';
        chown $o , $g , $tdn.'/d';
        $t = int time;
        utime undef , $t , $tdn;
        utime undef , $timeout , $tdn.'/d';
        };

    release_master($label,$d,$m);
    $_ = $t; return $_;
    }; # sub tlock_take


sub tlock_renew( $label , $token , $timeout , %nampar ) {
# Set a new timeout, counting from now, for the given lock.
    return if $timeout <= 0;
    my $n = {%nampar};
    my $d = dir($n);
    my $m = marker($n);
    my $p = patience($n);
    take_master($label,$d,$m,$p) or return;
    utime undef , int(time) - $token + $timeout , tdn($label,$d,$m).'/d'
      if tlock_alive($label,$token,%nampar);
    release_master($label,$d,$m);
    return 1;
    };


sub tlock_release( $label , $token , %nampar ) {
# Remove the lock.
    my $n = {%nampar};
    my $d = dir($n);
    my $m = marker($n);
    my $p = patience($n);
    take_master($label,$d,$m,$p) or return;
    my $t = tlock_token($label,%nampar);
    if ($token == $t) {
        my $tdn = tdn($label,$d,$m);
        rmdir $tdn.'/d' if -e $tdn.'/d';
        rmdir $tdn      if -e $tdn;
        };
    release_master($label,$d,$m);
    return 1;
    };


sub tlock_alive( $label , $token , %nampar ) {
# True if the lock with the given token is still taken.
    my $t = tlock_token($label,%nampar);
    return if not defined $t;
    return 1 if $token == $t;
    return;
    };


sub tlock_taken( $label , %nampar ) {
# True if the lock is taken.
    return if not defined tlock_expiry($label,%nampar);
    return 1;
  };


sub tlock_expiry( $label , %nampar ) {
# Timestamp for when the lock expires.
    my $n = {%nampar};
    my $d = dir($n);
    my $m = marker($n);
    my $tdn = tdn($label,$d,$m);
    return if not -e $tdn;
    my $t = int( (stat($tdn))[9] + (stat($tdn.'/d'))[9] );
    $t = undef if $t < int(time);
    return $t;
    };


sub tlock_zing( %nampar ) {
# Clean up all locks in the lock directory.
    my $n = {%nampar};
    my $d = dir($n);
    my $m = marker($n);
    my @dlist = glob($d.'*');
    while (my $d = shift @dlist) {
        basename($d) =~ m/^\Q${m}\E(?:|_)\.([a-zA-Z0-9\-\_\.]+)$/ or next;
        my $label = $1;
        tlock_take($label,10,%nampar) or next;
        tlock_release($label,$_,%nampar);
        };
    };

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

sub tlock_tstart( $label , %nampar ) {
# Timestamp for when the lock was taken.
    return tlock_token($label,%nampar);
    };


sub tlock_release_careless( $label , %nampar ) {
# Remove the lock without caring about the token.
    my $n = {%nampar};
    my $d = dir($n);
    my $m = marker($n);
    my $p = patience($n);
    take_master($label,$d,$m,$p) or return;
    my $tdn = tdn($label,$d,$m);
    rmdir $tdn.'/d' if -e $tdn.'/d';
    rmdir $tdn      if -e $tdn;
    release_master($label,$d,$m);
    return 1;
    };


sub tlock_token( $label , %nampar ) {
# Token associated with the lock.
    my $n = {%nampar};
    my $d = dir($n);
    my $m = marker($n);
    my $tdn = tdn($label,$d,$m);
    return if not -e $tdn;
    return if tlock_expiry($label,%nampar) < int(time); # timed out
    return int( (stat($tdn))[9] );
    };

# --------------------------------------------------------------------------- #

=pod

=encoding utf8

=head1 NAME

Sys::Tlock - Locking with timeouts.

=head1 VERSION

1.11

=head1 SYNOPSIS

    use Sys::Tlock;

    # Taking a tlock for 5 minutes, in that diectory.
    tlock_take('maint',300,dir=>'/var/logsystem/locks/')
      or die 'Failed taking the tlock.';
    my $token = $_;

    move_old_index();

    # Hand over to that other script.
    exec( '/usr/local/logrotate/logrotate.pl' , $token );

    -----------------------------------------------------------

    use Sys::Tlock
        dir => '/var/logsystem/locks/' ,
        owner => scalar getpwnam('logsystem') ,
        qw(tlock_release tlock_renew $patience);

    print "tlock patience is ${patience}\n";

    # Checking that tlock is alive.
    my $t = $ARGV[0];
    die 'Tlock not taken.' if not tlock_alive('maint',$t);

    # Make time for fancy rotation task.
    tlock_renew('maint',600);
    do_fancy_log_rotation(547);

    # Call another script that requires this tlock.
    system( './clean-up.sh' , $t );

    # Releasing the tlock.
    tlock_release('maint',$t);

=head1 DESCRIPTION

This module is handling tlocks, advisory locks with timeouts.

It is designed to allow separate programs to use the same tlocks between them. Even programs written in different languages. To do this safely, each tlock is paired with a token.

The tlocks are simply living in a lock directory in the filesystem. A distant predecessor to this module was written as a kludge to make locking work properly on a Windows server. But it turned out to be very handy to have tlocks in the filesystem, giving you an at-a-glance overview of them. And giving the non-scripting sysadmins easy access to view and manipulate them.

=head2 ERRORS

The module might die on compile-time errors. It will not die on runtime errors. Runtime errors might return error values, might warn or might be ignored, whatever should be the most sensible for the particular error.

=head2 CONFIGURATION

Each configuration parameter is set by the top most line that apply:

=over

=item 1. In a call, as named parameter with name "dir", "marker", "owner" or "patience".

=item 2. Configuration file given in a call by a named parameter with the name "conf".

=item 3. Directly in the use statement of your script, with key "dir", "marker", "owner" or "patience".

=item 4. Configuration file given by a "conf" key in the use statement of your script.

=item 5. Environment variable "tlock_dir", "tlock_marker", "tlock_owner" or "tlock_patience".

=item 6. Configuration file given by the environment variable "tlock_conf".

=item 7. Configuration file "/etc/tlock.conf".

=item 8. Default configuration.

=back

On top of this, you can import the $dir, $marker, $owner and $patience variables and change them in your script. But that is a recipe for disaster, so know what you do, if you go that way.

Configuration files must start with a "tlock 1" line. Empty lines are allowed and so are comments starting with the # character. There are four directives:

C<dir> For setting the lock directory. Write the full path.

C<marker> For the marker (prefix) that all tlock directory names will get.

C<owner> For the UID of the owner that will be set for tlock directories.

C<patience> For the time that a call will wait for a tlock release.

    tlock 1
    # Example configuration file for tlock.
    dir      /var/loglocks/
    patience 7.5

=head2 TOKENS

Safe use of tlocks involve tokens, which are just timestamps of when the tlock was taken.

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

All the data for a tlock is in its directory. If it is removed from the lock directory, the tlock is released. If it is moved back in, it is alive again (unless it has timed out). If too much playing around has messed up the lock directory, running tlock_zing on it cleans it up.

The lock directory also contains shortlived directories named "${marker}_.${label}". They are per label master locks that help to make changes to the tlocks atomic.

=head1 SUBROUTINES AND VARIABLES

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
L<$owner|/$owner>,
L<$patience|/$patience>

=over

=item tlock_take( $label , $timeout )

Take the tlock with the given label, and set its timeout. The call returns the associated token. The token value is also assigned to the $_ variable.

Labels can be any non-empty string consisting of letters a-z or A-Z, digits 0-9, dashes "-", underscores "_" and dots "." (PCRE: [a-zA-Z0-9\-\_\.]+)

For backwards compatibility, it is possible to write tlock_take($l,$t,patience => $p) as tlock_take($l,$t,$p) instead. But it is deprecated and will issue a warning.

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

Cleans up tlocks in the lock directory. Takes care not to mess with any lock activity.

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

=item $owner

The UID of the owner of the tlocks.

Will be silently ignored if it cannot be set.

Default value is -1. Which means the owner running the script.

Only loaded on demand.

=item $patience

Patience is the number of seconds a call will try to take or change a tlock, before it gives up. For example when tlock_take tries to take a tlock that is already taken, it is the number of seconds it should wait for that tlock to be released before giving up.

Patience can be set to any non-negative fractional number. If it is set to 0, a call only tries once before giving up.

Dont confuse patience with timeout.

Default patience value is 0.

Only loaded on demand.

=back

=head2 NAMED PARAMETERS

All the tlock subroutines can be given optional named parameters. They must be written after the mandatory parameters. The names can be "conf", "dir", "marker", "owner" and "patience". See the L<CONFIGURATION|/CONFIGURATION> chapter for more details.

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
