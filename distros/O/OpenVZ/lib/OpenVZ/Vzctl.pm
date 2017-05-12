package OpenVZ::Vzctl;

# ABSTRACT: Call OpenVZ vzctl command from your program

#XXX: Do we need to load and parse the VZ system config file?
#XXX: Need to abstract out the common code into a top level OpenVZ module.
#XXX: Need to handle version call
#XXX: Need to use 'on_fail' option for validate_with for smoother error
#     handling.


use 5.006;

use strict;
use warnings;

use namespace::autoclean;

use Carp;
use List::MoreUtils qw( any );
use OpenVZ ':all';
use Params::Validate ':all';
use Regexp::Common qw( URI net );
use Scalar::Util 'blessed';
use Sub::Exporter;

use parent 'OpenVZ';

our $VERSION = '0.01'; # VERSION

our $AUTOLOAD;

############################################################################
# Base structure describing the subcommands and their arguments.


# Every subcommand requires ctid and has the optional flag of C<quiet> or C<verbose>.  Though these flags are mutually exclusive,
# C<vzctl> will accept both at the same time.  Results are undefined when using both flag at the same time.  However, this code is
# setup to accept only one or the other.

# Surrounding a paremeter with square brackets ( [parm] ) will make the parm optional in C<subcommand_specs>.

{  # Quick, hide in here! And don't make a *sound*!

    my @vzctl_exports;

    push @vzctl_exports, 'execute';  # imported from OpenVZ

    my %vzctl = (

        destroy   => [],
        mount     => [],
        quotainit => [],
        quotaoff  => [],
        quotaon   => [],
        restart   => [],
        status    => [],
        stop      => [],
        umount    => [],
        exec      => [qw( command )],
        exec2     => [qw( command )],
        runscript => [qw( script )],
        start     => [qw( [force] [wait] )],
        enter     => [qw( [exec] )],
        chkpnt    => [qw( [create_dumpfile] )],
        restore   => [qw( [restore_dumpfile] )],
        create    => [qw( [config] [hostname] [ipadd] [ostemplate] [private] [root] )],

        set => [ qw(

                [applyconfig] [applyconfig_map] [avnumproc] [bootorder] [capability]
                [cpulimit] [cpumask] [cpus] [cpuunits] [dcachesize] [devices] [devnodes]
                [dgramrcvbuf] [disabled] [diskinodes] [diskspace] [features] [force]
                [hostname] [ioprio] [ipadd] [ipdel] [iptables] [kmemsize] [lockedpages]
                [name] [nameserver] [netif_add] [netif_del] [noatime] [numfile]
                [numflock] [numiptent] [numothersock] [numproc] [numpty] [numsiginfo]
                [numtcpsock] [onboot] [oomguarpages] [othersockbuf] [pci_add] [pci_del]
                [physpages] [privvmpages] [quotatime] [quotaugidlimit] [save]
                [searchdomain] [setmode] [shmpages] [swappages] [tcprcvbuf] [tcpsndbuf]
                [userpasswd] [vmguarpages]

                ),
        ],

    );

####################################


    push @vzctl_exports, 'known_commands';

    sub known_commands { return keys %vzctl }

####################################


    push @vzctl_exports, 'known_options';

    my $commands_rx = join q{|}, keys %vzctl;

    sub known_options { ## no critic qw( Subroutines::RequireArgUnpacking )

        #my @spec; $spec[0] = { type => SCALAR, regex => qr/^$commands_rx$/ };
        my @spec = ( { type => SCALAR, regex => qr/^$commands_rx$/ } );

        my @arg = validate_with( params => \@_, spec => \@spec );

        my @options = ( 'flag', 'ctid', @{ $vzctl{ $arg[0] } } );

        return wantarray ? @options : \@options;

    }

####################################


    my @capabilities = qw(

        chown dac_override dac_read_search fowner fsetid ipc_lock ipc_owner kill
        lease linux_immutable mknod net_admin net_bind_service net_broadcast
        net_raw setgid setpcap setuid setveid sys_admin sys_boot sys_chroot
        sys_module sys_nice sys_pacct sys_ptrace sys_rawio sys_resource sys_time
        sys_tty_config ve_admin

    );

    push @vzctl_exports, 'capabilities';

    sub capabilities { return wantarray ? @capabilities : \@capabilities }

####################################


    my @iptables_modules = qw(

        ip_conntrack ip_conntrack_ftp ip_conntrack_irc ip_nat_ftp ip_nat_irc
        iptable_filter iptable_mangle iptable_nat ipt_conntrack ipt_helper
        ipt_length ipt_limit ipt_LOG ipt_multiport ipt_owner ipt_recent
        ipt_REDIRECT ipt_REJECT ipt_state ipt_tcpmss ipt_TCPMSS ipt_tos ipt_TOS
        ipt_ttl xt_mac

    );

    push @vzctl_exports, 'iptables_modules';

    sub iptables_modules { return wantarray ? @iptables_modules : \@iptables_modules }

####################################


    my @features = qw( sysfs nfs sit ipip ppp ipgre bridge nfsd );

    push @vzctl_exports, 'features';

    sub features { return wantarray ? @features : \@features }

####################################

    my %validate = do {

        my $capability_names = join q{|}, @capabilities;
        my $iptables_names   = join q{|}, @iptables_modules;
        my $features_names   = join q{|}, @features;

        my %hash = (

            # XXX: Annoying.  Need to submit a bug for this.
            ## no critic qw( Variables::ProhibitPunctuationVars )
            avnumproc  => { type => SCALAR, regex     => qr{^\d+[gmkp]?(?::\d+[gmkp]?)?$}i },
            bootorder  => { type => SCALAR, regex     => qr{^\d+$} },
            capability => { type => SCALAR, regex     => qr{^(?:$capability_names):(?:on|off)$}i },
            cpumask    => { type => SCALAR, regex     => qr{^\d+(?:[,-]\d+)*|all$}i },
            ctid       => { type => SCALAR, callbacks => { 'validate ctid' => \&_validate_ctid } },
            devices    => { type => SCALAR, regex     => qr{^(?:(?:[bc]:\d+:\d+)|all:(?:r?w?))|none$}i },
            features   => { type => SCALAR, regex     => qr{^(?:$features_names):(?:on|off)$}i },
            flag       => { type => SCALAR, regex     => qr{^quiet|verbose$}i },
            force      => { type => UNDEF },
            ioprio     => { type => SCALAR, regex => qr{^[0-7]$} },
            onboot     => { type => SCALAR, regex => qr{^yes|no$}i },
            setmode    => { type => SCALAR, regex => qr{^restart|ignore$}i },
            userpasswd => { type => SCALAR, regex => qr{^(?:\w+):(?:\w+)$} },
            ## use critic

            applyconfig => { type => SCALAR, callbacks => { 'do not want empty strings' => sub { return $_[0] ne '' }, }, },

            command => {
                type      => SCALAR | ARRAYREF,
                callbacks => {
                    'do not want empty values' => sub {

                        return ref $_[0] eq ''
                            ? do { $_[0] ne '' }
                            : do { defined $_[0]->[0] && $_[0]->[0] ne '' };

                    },
                },
            },

            ipadd => {
                type      => SCALAR | ARRAYREF,
                callbacks => {
                    'do these look like valid ip(s)?' => sub {

                        my @ips = ref $_[0] eq 'ARRAY' ? @{ $_[0] } : $_[0];
                        return unless @ips;

                        # I'd rather not do
                        no warnings 'uninitialized'; ## no critic qw( TestingAndDebugging::ProhibitNoWarnings )

                        # but
                        # my @bad_ips = grep { defined    && ! /^$RE{net}{IPv4}$/ } @ips;
                        # my @bad_ips = grep { defined $_ && ! /^$RE{net}{IPv4}$/ } @ips;
                        # don't work and I'm not sure what else to try.
                        my @bad_ips = grep { ! /^$RE{net}{IPv4}$/ } @ips;
                        return ! @bad_ips;  # return 1 if there are no bad ips, undef otherwise.

                        #NOTE: I can't find a way to modify the incoming data, and it may not
                        #      be a good idea to do that in any case. Unless, and until, I can
                        #      figure out how to do this the right way this will be an atomic
                        #      operation. It's either all good, or it's not.

                    },
                },
            },

            ipdel => {
                type      => SCALAR | ARRAYREF,
                callbacks => {
                    'do these look like valid ip(s)?' => sub {

                        my @ips = ref $_[0] eq 'ARRAY' ? @{ $_[0] } : $_[0];
                        return unless @ips;

                        # see notes for ipadd
                        no warnings 'uninitialized'; ## no critic qw( TestingAndDebugging::ProhibitNoWarnings )
                        my @bad_ips = grep { ! /^$RE{net}{IPv4}$/ } @ips;
                        return 1 if any { $_ eq 'all' } @bad_ips;
                        return ! @bad_ips;

                        #NOTE: See ipadd note.

                    },
                },
            },

            iptables => {
                type      => SCALAR | ARRAYREF,
                callbacks => {
                    'see manpage for list of valid iptables names' => sub {

                        my @names;

                        if ( ref $_[0] eq 'ARRAY' ) {

                            @names = @{ $_[0] };
                            return if @names == 0;

                        } else {

                            return if ! defined $_[0] || $_[0] eq '';
                            my $names = shift;
                            @names = split /\s+/, $names;

                        }

                        # see notes for ipadd
                        no warnings 'uninitialized'; ## no critic qw( TestingAndDebugging::ProhibitNoWarnings )
                        my @bad_names = grep { ! /^(?:$iptables_names):o(?:n|ff)$/ } @names;
                        return ! @bad_names;

                        #NOTE: See ipadd note.

                    },
                },
            },

            create_dumpfile => {
                type      => SCALAR,
                callbacks => {
                    'does it look like a valid filename?' => sub {
                        return if $_[0] eq '';
                        my $file = sprintf 'file://localhost/%s', +shift;
                        $file =~ /^$RE{URI}{file}$/;
                    },
                },
            },

            restore_dumpfile => { type => SCALAR, callbacks => { 'does file exist?' => sub { -e ( +shift ) }, }, },

            devnodes => {
                type      => SCALAR,
                callbacks => {
                    'setting access to devnode' => sub {

                        return if ! defined $_[0] || $_[0] eq '';
                        return 1 if $_[0] eq 'none';
                        ( my $device = $_[0] ) =~ s/^(.*?):r?w?q?$/$1/;
                        $device = "/dev/$device";
                        return -e $device;

                    },
                },
            },

        );

        my %same = (

            # SCALAR checks
            applyconfig => [ qw(

                    applyconfig_map config hostname name netif_add netif_del ostemplate
                    pci_add pci_del private root searchdomain

                    ),
            ],

            #XXX: Need to make 'config', 'ostemplate', 'private' and 'root' more
            #     robust.  We can pull the data from the global config file to help
            #     validate this info.

            # SCALAR | ARRAYREF checks
            command => [qw( exec script )],

            # UNDEF checks
            force => [qw( save wait )],

            # INT checks
            bootorder => [qw( cpulimit cpus cpuunits quotatime quotaugidlimit )],

            # yes or no checks
            onboot => [qw( disabled noatime )],

            # ip checks
            ipadd => [qw( nameserver )],

            # hard|soft limits
            avnumproc => [ qw(

                    dcachesize dgramrcvbuf diskinodes diskspace kmemsize lockedpages numfile
                    numflock numiptent numothersock numproc numpty numsiginfo numtcpsock
                    oomguarpages othersockbuf physpages privvmpages shmpages swappages
                    tcprcvbuf tcpsndbuf vmguarpages

                    ),
            ],
        );

        for my $key ( keys %same ) {

            $hash{ $_ } = $hash{ $key } for @{ $same{ $key } };

        }

        %hash;

    };

    ############################################################################
    # Public functions

    #XXX: Some of these should be extracted out into common module (OpenVZ.pm?)

    my %global;
    my $spec = subcommand_specs( qw( flag ctid ) );
    my $subcommands = join q{|}, sort( known_commands() );
    $spec->{ subcommand } = { regex => qr/^$subcommands$/ }; ## no critic qw( ValuesAndExpressions::ProhibitAccessOfPrivateData )

    my %hash = ( command => 'vzctl' );

    push @vzctl_exports, 'vzctl';

    sub vzctl { ## no critic qw( Subroutines::RequireArgUnpacking )

        shift if blessed $_[0];

        my %arg = validate_with( params => @_, spec => $spec, allow_extra => 1, );

        my @params;

        push @params, ( sprintf '--%s', delete $arg{ flag } )
            if exists $arg{ flag };

        push @params, delete $arg{ subcommand };

        delete $arg{ ctid };
        push @params, $global{ ctid };

        for my $p ( keys %arg ) {

            # XXX: Need better way to determine if this is a bare option
            #      maybe '!option' to indicate this option should be bare?

            my $arg_name = $p =~ /^command|script$/ ? '' : "--$p";
            my $ref = ref $arg{ $p };

            if ( $ref eq 'ARRAY' ) {

                push @params, ( $arg_name, $_ ) for @{ $arg{ $p } };

            } elsif ( $ref eq '' ) {

                push @params, $arg_name;

                # coverage: I don't see a way to test for ! defined $arg{$p}
                # ... so we'll have to accept a 67% coverage for this one.

                push @params, $arg{ $p }
                    if defined $arg{ $p } && $arg{ $p } ne '';

            } else {

                croak "Don't know how to handle ref type $ref for $p";

            }
        } ## end for my $p ( keys %arg)

        @params = grep { $_ ne '' } @params;

        $hash{ params } = \@params;

        return execute( \%hash );

    } ## end sub vzctl

####################################

    push @vzctl_exports, 'subcommand_specs';

    sub subcommand_specs { ## no critic qw( Subroutines::RequireArgUnpacking )

        shift if blessed $_[0];

        my @args = validate_with( params => \@_, spec => [ { type => SCALAR } ], allow_extra => 1, );

        my %spec_hash;

        if ( defined $subcommands && $args[0] =~ /^$subcommands$/ ) {

            # then build predefined specification hash

            my @specs = @{ $vzctl{ +shift @args } };

            # Every subcommand has these two at a minimum.
            unshift @specs, '[flag]', 'ctid';

            for my $spec ( @specs ) {

                my $optional = $spec =~ s/^\[(.*)\]$/$1/;

                croak "Unknown spec $spec"
                    unless exists $validate{ $spec };

                next if any { /^-$spec$/ } @args;

                $spec_hash{ $spec } = $validate{ $spec };

                $spec_hash{ $spec }{ optional } = 1
                    if $optional;

            }
        } ## end if ( defined $subcommands...)

        # build custom specification hash if any args are left

        for my $spec ( @args ) {

            next if $spec =~ /^-/;
            next if exists $spec_hash{ $spec };

            croak "Unknown spec $spec"
                unless exists $validate{ $spec };

            $spec_hash{ $spec } = $validate{ $spec };

        }

        return \%spec_hash;

    } ## end sub subcommand_specs

############################################################################
    # Internal Functions

    #XXX: Should be extracted out into common module (OpenVZ.pm?)

    # Is the provided ctid a valid container identifier?

    sub _validate_ctid { ## no critic qw( Subroutines::RequireArgUnpacking )

        shift if blessed $_[0];

        #my ( $ctid, $params ) = @_;
        my $check_ctid = shift;

        {
            no warnings qw( numeric uninitialized ); ## no critic qw( TestingAndDebugging::ProhibitNoWarnings )

            # coverage: we can't check against ! exists, so we'll have to live
            # with a 71% coverage on this one.

            return 1
                if ( exists $global{ ctid } && $global{ ctid } == $check_ctid )
                || ( exists $global{ name } && $global{ name } eq $check_ctid );
        }

        # XXX: Need to modify this when vzlist is handled so we keep things
        # uncluttered.

        my ( $stdout, $stderr, $syserr ) = execute( { command => 'vzlist', params => [ '-Ho', 'ctid,name', $check_ctid ], } );

        ## no critic qw( ErrorHandling::RequireUseOfExceptions ValuesAndExpressions::ProhibitMagicNumbers )
        croak 'vzlist did not execute'
            if $syserr == -1;

        $syserr >>= 8;

        croak "Invalid or unknown container ($check_ctid): $stderr"
            if $syserr == 1;
        ## use critic

        $stdout =~ s/^\s*(.*?)\s*$/$1/;
        my ( $ctid, $name ) = split /\s+/, $stdout;

        $global{ ctid } = $ctid;
        $global{ name } = $name;

        return 1;

    } ## end sub _validate_ctid

    # Generate the code for each of the subcommands
    # https://metacpan.org/module/Sub::Exporter#Export-Configuration

    sub _generate_subcommand { ## no critic qw( Subroutines::RequireArgUnpacking )

        shift if blessed $_[0];

        #XXX: Need to handle case of calling class using something like
        #
        # use OpenVZ::vzctl set => { -as => 'setip', arg => 'ipadd' };
        #
        # and creating a sub that only accepts the ipadd parameter.

        #my ( $class, $name, $arg, $collection ) = @_;
        my ( undef, $subcommand ) = @_;
        my $subcommand_spec = subcommand_specs( $subcommand );

        my %sub_spec;

        $sub_spec{ spec } = $subcommand_spec;

        return sub {

            shift if blessed $_[0];

            $sub_spec{ params } = \@_;

            my %arg = validate_with( %sub_spec );
            $arg{ subcommand } = $subcommand;
            vzctl( \%arg );

        };
    } ## end sub _generate_subcommand

    # for oop stuff

    # XXX: Do we need/want to support methods for the various options (what is returned from subcommand_specs)?

    sub AUTOLOAD { ## no critic qw( Subroutines::RequireArgUnpacking ClassHierarchies::ProhibitAutoloading )

        carp "$_[0] is not an object"
            unless blessed $_[0];

        ( my $subcommand = $AUTOLOAD ) =~ s/^.*:://;

        carp "$subcommand is not a valid method"
            unless exists $vzctl{ $subcommand };

        ## no critic qw( TestingAndDebugging::ProhibitNoStrict References::ProhibitDoubleSigils )
        no strict 'refs';
        *$AUTOLOAD = _generate_subcommand( undef, $subcommand );

        goto &$AUTOLOAD;
        ## use critic

    } ## end sub AUTOLOAD

    # AUTOLOAD assumes DESTROY exists
    DESTROY { }

    push @vzctl_exports, ( $_ => \&_generate_subcommand ) for keys %vzctl;

############################################################################
    # Setup exporter

    my $config = {

        exports    => \@vzctl_exports,
        groups     => {},
        collectors => [],

    };

    Sub::Exporter::setup_exporter( $config );

}  # Ok, they're gone.  You can come out now.  Guys?  Hello?

1;

__END__
=pod

=for :stopwords Alan Young applyconfig arrayref avnumproc bootorder config cpulimit cpumask
cpus cpuunits ctid CTID dcachesize devnodes dgramrcvbuf diskinodes
diskspace hashref hostname ioprio ipadd ipdel ips iptables kmemsize
lockedpages manpage nameserver noatime numfile numflock numiptent
numothersock numproc numpty numsiginfo numtcpsock onboot oomguarpages
ostemplate othersockbuf physpages privvmpages quotatime quotaugidlimit
regex searchdomain setmode shmpages subcommand subcommands swappages
tcprcvbuf tcpsndbuf undef userpasswd vmguarpages vzctl

=encoding utf-8

=head1 NAME

OpenVZ::Vzctl - Call OpenVZ vzctl command from your program

=head1 VERSION

  This document describes v0.01 of OpenVZ::Vzctl - released April 17, 2012 as part of OpenVZ.

=head1 SYNOPSIS

  use OpenVZ::Vzctl;

  #XXX: need to add more examples

=head1 DESCRIPTION

This program is a simple (or not so simple in some cases) wrapper around the 'vzctl' program.  It will do some basic verification on
options and parameters but it will not (currently) do sanity checks on the values.

=head2 NOTE

All of the commands for vzctl are implemented and all of the options for each command is provided for, but some commands and options
I don't use so I'm not sure how to test them.  Tests are welcome.

If you want to know what commands and options are available read C<vzctl>s man page.  I followed that in creating this module.

=head1 FUNCTIONS

=head2 vzctl

C<vzctl> is used to call C<execute> with vzctl as the specific command.

C<vzctl> expects a hashref with the required keys C<subcommand> and C<ctid> and does B<NOT> check the validity of any remaining
keys.

A C<flag> key is optional and accepts C<quiet> and C<verbose>.

An example of a valid call would be

  my $result = vzctl({ subcommand => 'set', 'ctid' => 101, ipadd => '1.2.3.4', save => undef });

In this case, C<set> and C<101> would be validated, but C<1.2.3.4> and the value for C<save> would just be passed along to
C<execute> as is.

The C<undef> value in C<save> is a hint to C<vzctl> that the C<save> parameter should be passed as a switch (i.e., --save instead of
--save undef).

When a value is an arrayref, e.g., ipadd => [qw( 1.2.3.4 2.3.4.5 )]. C<vzctl> will send the same parameter multiple times.  The
previous example would become '--ipadd 1.2.3.4 --ipadd 2.3.4.5'.

You're probably better off if you use the functions designed for a specific command unless you know what you're doing.

=head2 subcommand_specs

C<subcommand_specs> expects a list.  The first element will be checked against a list of known subcommands for vzctl.

If the first element is a known subcommand a predefined hashref will be instantiated.  Any following elements will be treated as
additional specification names to be included.  Duplicates will be silently ignored.  If an element is preceded by a dash (-), that
element will be removed from the hashref.

If the first element is not a known subcommand a hashref will be created with the specification names provided, including the first
element.  Using a dash makes no sense in this context, but will not cause any problems.

C<subcommand_specs> will return the hashref described previously that can be used in the C<spec> option of C<Params::Validate>'s
C<validate_with> function.  E.g., the call

  my $spec = subcommand_specs( 'stop' );

will return a hashref into C<$spec> that looks like

  $spec = {
    flag  => { regex => qr/^quiet|verbose/, optional => 1 },
    ctid  => { callback => { 'validate ctid' => \&_validate_ctid } },
  }

while the call

  my $spec = subcommand_specs( 'ctid' );

would yield

  $spec = { ctid => { callback => { 'validate ctid' => \&_validate_ctid } } };

If a parameter is surrounded with square brackets ( [] ) the parameter is made optional.

=head2 known_commands

Returns a list of known vzctl commands

=head2 known_options

Given a command, returns a list of known options

=head2 capabilities

Returns a list of known capabilities for the C<vzctl set capability> option.

=head2 iptables_modules

Returns a list of known iptables modules for the C<vzctl set iptables> option.

=head2 features

Returns a list of known features for the C<vzctl set features> option.

=head1 VZCTL COMMANDS

=head2 chkpnt

C<chkpnt> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

Can be either a CTID or name. The command C<vzlist -Ho name,ctid value> is used to determine if C<value> is a valid identifier.

=item create_dumpfile (optional)

Expects a scalar that looks like a file but does not check if it's possible to write to the specified file.  L<Regexp::Common>'s
C<URI> regex is used to determine what looks like a file.

=back

See the C<vzctl> manpage for information on the C<chkpnt> command.

=head2 create

C<create> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=item config (optional)

Expects a scalar, but doesn't check validity of value.

=item hostname (optional)

Expects a scalar, but doesn't check validity of value.

=item ipadd (optional)

Expects a scalar or a reference to an array. L<Regexp::Common>'s C<net IPv4> regex is used to determine if the values are valid
looking ips.

=item ostemplate (optional)

Expects a scalar, but doesn't check validity of value.

=item private (optional)

Expects a scalar, but doesn't check validity of value.

=item root (optional)

Expects a scalar, but doesn't check validity of value.

=back

See the C<vzctl> manpage for information on the C<create> command.

=head2 destroy

C<destroy> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=back

See the C<vzctl> manpage for information on the C<destroy> command.

=head2 enter

C<enter> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=item exec (optional)

Expects a scalar or reference to an array but doesn't check for the validity of the command.

=back

See the C<vzctl> manpage for information on the C<enter> command.

=head2 exec

C<exec> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=item command (required)

Expects a scalar or a reference to an array but doesn't check for the validity of the command.

=back

See the C<vzctl> manpage for information on the C<exec> command.

=head2 exec2

C<exec2> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=item command (required)

Expects a scalar or a reference to an array but doesn't check for the validity
of the command.

=back

See the C<vzctl> manpage for information on the C<exec2> command.

=head2 mount

C<mount> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=back

See the C<vzctl> manpage for information on the C<mount> command.

=head2 quotainit

C<quotainit> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=back

See the C<vzctl> manpage for information on the C<quotainit> command.

=head2 quotaoff

C<quotaoff> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=back

See the C<vzctl> manpage for information on the C<quotaoff> command.

=head2 quotaon

C<quotaon> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=back

See the C<vzctl> manpage for information on the C<quotaon> command.

=head2 restart

C<restart> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=back

See the C<vzctl> manpage for information on the C<restart> command.

=head2 restore

C<restore> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=item restore_dumpfile

Checks if the file exists, but does not check for validity of file format.

=back

See the C<vzctl> manpage for information on the C<restore> command.

=head2 runscript

C<runscript> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=item script (required)

Expects a scalar or a reference to an array but doesn't check for the validity of the script.

=back

See the C<vzctl> manpage for information on the C<runscript> command.

=head2 set

C<set> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=item applyconfig

=item applyconfig_map

=item hostname

=item name

=item netif_add

=item netif_del

=item pci_add

=item pci_del

=item searchdomain

Expects a scalar. No other validation is performed.

=item avnumproc

=item dcachesize

=item dgramrcvbuf

=item diskinodes

=item diskspace

=item kmemsize

=item lockedpages

=item numfile

=item numflock

=item numiptent

=item numothersock

=item numproc

=item numpty

=item numsiginfo

=item numtcpsock

=item oomguarpages

=item othersockbuf

=item physpages

=item privvmpages

=item shmpages

=item swappages

=item tcprcvbuf

=item tcpsndbuf

=item vmguarpages

Expects an integer followed by an optional 'g', 'm', 'k' or 'p', followed optionally by a colon and an integer and an optional 'g',
'm', 'k' or 'p'.  E.g., 5M or 5M:15M.

=item bootorder

=item cpulimit

=item cpus

=item cpuunits

=item quotatime

=item quotaugidlimit

Expects an integer.

=item capability

Expects one of the following capabilities

    chown dac_override dac_read_search fowner fsetid ipc_lock ipc_owner kill lease linux_immutable mknod net_admin net_bind_service
    net_broadcast net_raw setgid setpcap setuid setveid sys_admin sys_boot sys_chroot sys_module sys_nice sys_pacct sys_ptrace
    sys_rawio sys_resource sys_time sys_tty_config ve_admin

joined with either 'on' or 'off' with a colon. E.g., 'chown:on'.

=item cpumask

Expects either a comma separated list of integers or the word 'all'.

=item devices

Expects a device that matches the regex

  /^(?:(?:(?:b|c):\d+:\d+)|all:(?:r?w?))|none$/

No other validation is performed.

XXX Better explanation needed here.

=item devnodes

=item features

Expects one of the following features

  sysfs nfs sit ipip ppp ipgre bridge nfsd

followed by a colon and either 'on' or 'off'.

=item force

=item save

Expects either undef or the empty string.

=item ioprio

Expects a single integer from 0 to 7.

=item ipadd

=item ipdel

Expects either an array reference or a space separated list of ips to be added or deleted. L<Regexp::Common>'s C<net IPv4> regex is
used to determine if the ips look valid.  No other validation is performed.

C<ipdel> also accepts 'all' to delete all ips.

=item iptables

Expects either an array reference or space separated list of one or more of the following

    ip_conntrack ip_conntrack_ftp ip_conntrack_irc ip_nat_ftp ip_nat_irc iptable_filter iptable_mangle iptable_nat ipt_conntrack
    ipt_helper ipt_length ipt_limit ipt_LOG ipt_multiport ipt_owner ipt_recent ipt_REDIRECT ipt_REJECT ipt_state ipt_tcpmss
    ipt_TCPMSS ipt_tos ipt_TOS ipt_ttl xt_mac

=item nameserver

=item disabled

=item noatime

=item onboot

Expects either 'yes' or 'no'.

=item setmode

Expects either 'restart' or 'ignore'.

=item userpasswd

Expects two strings separated by a colon.  No other validation is performed on the value.

=back

See the C<vzctl> manpage for information on the C<set> command.

=head2 start

C<start> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=item force

=item wait

Expects either undef or the empty string.

=back

See the C<vzctl> manpage for information on the C<start> command.

=head2 status

C<status> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=back

See the C<vzctl> manpage for information on the C<status> command.

=head2 stop

C<stop> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=back

See the C<vzctl> manpage for information on the C<stop> command.

=head2 umount

C<umount> expects a hash reference with the following keys and values.

=over 4

=item ctid (required)

See C<chkpnt> for details.

=back

See the C<vzctl> manpage for information on the C<umount> command.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<OpenVZ|OpenVZ>

=back

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

