# NAME

Sys::Tlock - Locking with timeouts.

# VERSION

1.10

# SYNOPSIS

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

    # Checking lock is alive.
    my $t = $ARGV[0];
    die 'Tlock not taken.' if not tlock_alive('maint',$t);

    # Make time for fancy rotation task.
    tlock_renew('maint',600);
    do_fancy_log_rotation(547);

    # Call another script that requires this lock.
    system( './clean-up.sh' , $t );

    # Releasing the lock.
    tlock_release('maint',$t);

# DESCRIPTION

This module is handling tlocks, advisory locks with timeouts.

It is designed to allow separate programs to use the same tlocks between them. Even programs written in different languages. To do this safely, tlocks are paired with a lock token.

The tlocks are simply living in a lock directory in the filesystem. A distant predecessor to this module was written as a kludge to make locking work properly on a Windows server. But it turned out to be very handy to have tlocks in the filesystem, giving you an at-a-glance overview of them. And giving the non-scripting sysadmins easy access to view and manipulate them.

## ERRORS

The module might die on compile-time errors. It will not die on runtime errors. Runtime errors might return error values, might warn or might be ignored, whatever should be the most sensible for the particular error.

## CONFIGURATION

Each configuration parameter is set by the top most line that apply:

- 1. In a call, as named parameter with name "dir", "marker", "owner" or "patience".
- 2. Configuration file given in a call by a named parameter with the name "conf".
- 3. Directly in the use statement of your script, with key "dir", "marker", "owner" or "patience".
- 4. Configuration file given by a "conf" key in the use statement of your script.
- 5. Environment variable "tlock\_dir", "tlock\_marker", "tlock\_owner" or "tlock\_patience".
- 6. Configuration file given by the environment variable "tlock\_conf".
- 7. Configuration file "/etc/tlock.conf".
- 8. Default configuration.

On top of this, you can import the $dir, $marker, $owner and $patience variables and change them in your script. But that is a recipe for disaster, so know what you do, if you go that way.

Configuration files must start with a "tlock 1" line. Empty lines are allowed and so are comments starting with the # character. There are four directives:

`dir` For setting the lock directory. Write the full path.

`marker` For the marker (prefix) that all tlock directory names will get.

`owner` For the UID of the owner that will be set for tlock directories.

`patience` For the time that a call will wait for a lock release.

    tlock 1
    # Example configuration file for tlock.
    dir      /var/loglocks/
    patience 7.5

## TOKENS

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

## IN THE FILESYSTEM

Each tlock is a subdirectory of the lock directory. Their names are "${marker}.${label}". The default value for $marker is "tlock".

All the data for a tlock is in its directory. If it is removed from the lock directory, the tlock is released. If it is moved back in, it is alive again (unless it has timed out). If too much playing around has messed up the lock directory, running tlock\_zing on it cleans it up.

The lock directory also contains shortlived directories named "${marker}\_.${label}". They are per label master locks that help to make changes to the normal locks atomic.

# FUNCTIONS AND VARIABLES

Loaded by default:
[tlock\_take](#tlock_take-label-timeout),
[tlock\_renew](#tlock_renew-label-token-timeout),
[tlock\_release](#tlock_release-label-token),
[tlock\_alive](#tlock_alive-label-token),
[tlock\_taken](#tlock_taken-label),
[tlock\_expiry](#tlock_expiry-label),
[tlock\_zing](#tlock_zing)

Loaded on demand:
[tlock\_tstart](#tlock_tstart-label),
[tlock\_release\_careless](#tlock_release_careless-label),
[tlock\_token](#tlock_token-label),
[$dir](#dir),
[$marker](#marker),
[$owner](#owner),
[$patience](#patience)

- tlock\_take( $label , $timeout )

    Take the tlock with the given label, and set its timeout. The call returns the associated token. The token value is also assigned to the $\_ variable.

    Labels can be any non-empty string consisting of letters a-z or A-Z, digits 0-9, dashes "-", underscores "\_" and dots "." (PCRE: \[a-zA-Z0-9\\-\\\_\\.\]+)

    For backwards compatibility, it is possible to write tlock\_take($l,$t,patience => $p) as tlock\_take($l,$t,$p) instead. But it is deprecated and will issue a warning.

- tlock\_renew( $label , $token , $timeout )

    Reset the timeout of the tlock, so that it will time out $timeout seconds from the time that tlock\_renew is called.

- tlock\_release( $label , $token )

    Release the tlock.

- tlock\_alive( $label , $token )

    Returns true if the tlock is currently taken.

- tlock\_taken( $label )

    Returns true if a tlock with the given label is currently taken.

    The difference between tlock\_taken and tlock\_alive, is that alive can differentiate between different tlocks with the same label. Different tlocks with the same label can exist at different points in time.

- tlock\_expiry( $label )

    Returns the time when the current tlock with the given label will expire. It is given in epoch seconds.

- tlock\_zing()

    Cleans up locks in the lock directory. Takes care not to mess with any lock activity.

- tlock\_tstart( $label )

    Returns the time for the creation of the current tlock with the given label. It is given in epoch seconds. This function and the token function are identical.

    Only loaded on demand.

- tlock\_release\_careless( $label )

    Carelessly release any tlock with the given label, not caring about the token.

    Only loaded on demand.

- tlock\_token( $label )

    Returns the token for the current tlock with the given label.

    Only loaded on demand.

- $dir

    The directory containing the tlocks.

    Only loaded on demand.

- $marker

    The common prefix of the directory names used for tlocks.

    Prefixes can be any non-empty string consisting of letters a-z or A-Z, digits 0-9, dashes "-" and underscores "\_" (PCRE: \[a-zA-Z0-9\\-\\\_\]+). First character has to be a letter, and last character a letter or digit.

    Only loaded on demand.

- $owner

    The UID of the owner of the tlocks.

    Will be silently ignored if it cannot be set.

    Default value is -1. Which means the owner running the script.

    Only loaded on demand.

- $patience

    Patience is the time a call will try to take or change a tlock, before it gives up. For example when tlock\_take tries to take a tlock that is already taken, it is the number of seconds it should wait for that tlock to be released before giving up.

    Dont confuse patience with timeout.

    Default patience value is 2.5 seconds.

    Only loaded on demand.

## NAMED PARAMETERS

All the tlock subroutines can be given optional named parameters. They must be written after the mandatory parameters. The names can be "conf", "dir", "marker", "owner" and "patience". See the [CONFIGURATION](#configuration) chapter for more details.

# DEPENDENCIES

File::Basename

Time::HiRes

# KNOWN ISSUES

The author dare not guarantee that the locking is waterproof. But if there are conditions that breaks it, they must be very special. At the least, experience has shown it to be waterproof in practice.

Not tested on Windows, ironically enough.

# SEE ALSO

flock

# LICENSE & COPYRIGHT

(c) 2022-2023 Bjoern Hee

Licensed under the Apache License, version 2.0

https://www.apache.org/licenses/LICENSE-2.0.txt

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 737:

    You forgot a '=back' before '=head2'

- Around line 741:

    &#x3d;back without =over
