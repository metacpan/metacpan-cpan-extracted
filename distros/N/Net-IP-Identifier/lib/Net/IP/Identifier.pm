#!/usr/bin/perl
#===============================================================================
#      PODNAME:  Net::IP::Identifier
#     ABSTRACT:  Identify IPs that fall within collections of network blocks
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Mon Oct  6 10:20:33 PDT 2014
#===============================================================================

use 5.002;
use strict;
use warnings;

{
    package Local::Payload;
    use Moo;

    has entity => (
        is => 'rw',
        isa => sub { die "Not a Net::IP::Identifier::Plugin\n"
                        if (not $_[0]->does('Net::IP::Identifier_Role')); },
    );
    has ip => (
        is => 'rw',
        isa => sub { die "Not a Net::IP::Identifier::Net\n"
                        if (not $_[0]->isa('Net::IP::Identifier::Net')); },
    );
}


package Net::IP::Identifier;
use Getopt::Long qw(:config pass_through);
use File::Spec;
use Net::IP::Identifier::Net;
use Net::IP::Identifier::Binode;
use Net::IP::Identifier::Regex;
use Carp;
use Moo;
use namespace::clean;
use Module::Pluggable;

our $VERSION = '0.111'; # VERSION

has joiners => (
    is => 'rw',
    default => sub { [ ':', '.' ] },
);
has cidr => (
    is => 'rw',
);
has parents => (
    is => 'rw',
);
has overlaps => (
    is => 'rw',
);
has re => ( # regular expressions for IP addresses
    is => 'lazy',
    default => sub { Net::IP::Identifier::Regex->new },
);

my $imports;

my (undef, undef, $myName) = File::Spec->splitpath($0);

my $help_msg = <<EO_HELP

$myName [ options ] IP [ IP... ]

If IP belongs to a known entity (a Net::IP::Identifier::Plugin),
print the entity.

IP may be dotted decimal format: N.N.N.N, range format: N.N.N.N - N.N.N.N,
CIDR format: N.N.N.N/W, or a filename from which IPs will be extracted.  If
no IP or filename is found on the command line, STDIN is opened.

Options (may be abbreviated):
    parents   => prepend Net::IP::Identifier objects of parent entities
    cidr      => append Net::IP::Identifier::Net objects to entities
    filename  => read from file(s) instead of command line args
    overlaps  => show overlapping netblocks during binary tree construction
    help      => this message

EO_HELP
;

__PACKAGE__->run unless caller;     # modulino

sub run {
    my ($class) = @_;

    my %opts;
    my $overlaps;
    my $filename;
    my $help;

    exit 0 if (not
        GetOptions(
            'parents'    => \$opts{parents},
            'cidr'       => \$opts{cidr},
            'overlaps'   => \$overlaps,
            'filename=s' => \$filename,
            'help'       => \$help,
        )
    );

    if ($help) {
        print $help_msg;
        exit;
    }

    my $identifier = __PACKAGE__->new(%opts);

    unshift @ARGV, $filename if ($filename);
    if (not @ARGV) {
        $identifier->parse_fh(\*STDIN);
    }

    while (@ARGV) {
        my $arg = shift @ARGV;
        if (-f $arg) {
            open my $fh, '<', $arg;
            croak "Can't open $arg for reading\n" if not $fh;
            $identifier->parse_fh($fh);
            close $fh;
            next
        }
        elsif ($ARGV[0]        and  # accept N.N.N.N - N.N.N.N for network blocks too
               $ARGV[0] eq '-' and
               $ARGV[1]) {
            $arg .= shift(@ARGV) . shift(@ARGV);
        }

        print $identifier->identify($arg) || $arg, "\n";
    }

    if ($overlaps) {
        for my $return (@{$identifier->tree_overlaps}) {
            my @r = map { $identifier->join($_->payload->entity, $_->payload->ip); } @{$return};
            warn join(' => ', @r), "\n";
        }
    }
}

sub import {
    my ($class, @imports) = @_;

    $imports = \@imports if (@imports);   # save import list in class variable
}

sub parse_fh {
    my ($self, $fh) = @_;

    my $ip_any = $self->re->IP_any;
    while(<$fh>) {
        my (@ips) = m/($ip_any)/;
        for my $ip (@ips) {
            print $self->identify($ip) || $ip, "\n";
        }
    }
}

sub load_entities {
    my ($self, @plugins) = @_;

    my $plugins = ref $plugins[0] eq 'ARRAY'    # accept array or ref
        ? $plugins[0]       # a ref was passed in
        : \@plugins;        # convert array to ref
    delete $self->{parent_of};
    delete $self->{entities};
    for my $plugin (@{$plugins}) {
#print "requiring $plugin\n";
        if (not $plugin =~ m/::/) {
            $plugin = __PACKAGE__ . "::Plugin::$plugin";
        }
        eval "CORE::require $plugin";   ## no critic # attempt to read in the plugin
        warn $@ if $@;
        my $p = $plugin && $plugin->new;
        next if not $p;
        if (not $p->does('Net::IP::Identifier_Role')) {
            print "$plugin doesn't satisfy the Net::IP::Identifier_Role - skipping\n";
            next;
        }
        push @{$self->{entities}}, $p;
        for my $child ($p->children) {
            $self->{parent_of}{$child} = $p;
        }
    }
    if (     @$plugins and
        (not   $self->{entities} or
            not @{$self->{entities}})) {
        croak "No plugins installed\n";
    }
    delete $self->{ip_tree};
}

sub entities {
    my ($self, @plugins) = @_;

    if (@_ > 1) {
        undef $imports;         # override imports with @plugins
#print "load args: ", join(' ', @plugins), "\n";
        $self->load_entities(@plugins);
    }

    if (not   $self->{entities} or
        not @{$self->{entities}}) {
        # if no plugins yet loaded, check import list
        # no import list? load everything we can find
        if ($imports) {
#print "load imports ", join(' ', @{$imports}), "\n";
            $self->load_entities($imports);
            undef $imports;     # only the first time
        }
        else {
#print "load imports ", join(' ', $self->plugins), "\n";
            $self->load_entities([ $self->plugins ]);
        }

        if (not   $self->{entities} or
            not @{$self->{entities}}) {
            croak "No entity Plugins found\n";
        }
    }

    return wantarray
        ? @{$self->{entities}}
        : $self->{entities};
}

sub ip_tree {
    my ($self, $version) = @_;

    croak "ip_tree(\$version) error: no version\n" if not $version;

    if (not $self->{ip_tree}) {
        my $root_v6 = Net::IP::Identifier::Binode->new;
        # Place the IPv4 block in the IPv6 tree (IPv4 mapped IPv6)
        my $root_v4 = $root_v6->construct(Net::IP::Identifier::Net->new('::ffff:0:0/96')->masked_ip);

        for my $entity ($self->entities) {
            for my $ip ($entity->ips) {
                my @ips = ($ip);
                if (not defined $ip->prefixlen) {
                    @ips = $ip->range_to_cidrs;
                }
                for my $ip (@ips) {
                    my $root = ($ip->version == 6) ? $root_v6 : $root_v4;
                    $root->construct($ip->masked_ip)->payload(
                        Local::Payload->new(
                            entity => $entity,
                            ip => $ip,
                        ),
                    );
                }
            }
        }
        $self->{ip_tree}{6} = $root_v6;
        $self->{ip_tree}{4} = $root_v4;
    }
    return $self->{ip_tree}{$version};
}

sub identify {
    my ($self, $ip) = @_;

    $ip = Net::IP::Identifier::Net->new($ip);
    my @ips = ($ip);
    if (not defined $ip->prefixlen) {
        @ips = $ip->range_to_cidrs;
    }

    my @return;
    for my $ip (@ips) {
        $self->ip_tree($ip->version)->follow($ip->masked_ip, sub {
                push @return, $_[0] if ($_[0]->payload);
                return 0;  # always continue
            },
        );
    }
    if (not @return) {
        return; # not found.
    }

    if (not $self->parents) {
        @return = ($return[-1]);    # just the last child
    }

    @return = map { $_->payload } @return;   # remove the Binode layer

    if (wantarray) {
        return $self->cidr
        ? map { $_->entity, $_->ip } @return
        : @return;
    }

    if ($self->cidr) {
        my @e = map { $self->join($_->entity, $_->ip) } @return;
        return join ' => ', @e;
    }
    my $r = join (' => ', map {
        $_->entity->name
        } @return);
    return $r;
}

sub join {
    my ($self, @parts) = @_;

    my $joiners = $self->joiners;
    my $joiner = $joiners->[0];   # assume IPv4
    if (grep { $_->can('version') and $_->version eq '6' } @parts) {
        $joiner = $joiners->[1];  # use the IPv6 string
    }
    $joiner = ':' if (not defined $joiner);    # if all else fails...
    return join $joiner, @parts;
}

sub tree_overlaps {
    my ($self) = @_;

    my @overlaps;   # collect overlaps here.  each overlap is an array
                    # starting with the parent, followed by children.

    $self->ip_tree(6)->traverse_width_first(
        sub {
            my ($node, $level) = @_;

            my @overlap;    # a single overlap array, parent then children
            if ($node->payload and
                ($node->zero or $node->one)) {
                $node->traverse_width_first(
                    sub {
                        if ($_[0]->payload) {
                            push @overlap, $_[0];
                        }
                        return 0;   # always continue
                    }
                );
            }
            push @overlaps, \@overlap if (@overlap > 1);
            return @overlap > 1;    # stop if we found overlap
        },
    );

    return wantarray
    ? @overlaps
    : \@overlaps;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier - Identify IPs that fall within collections of network blocks

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier;
       or
 use Net::IP::Identifier ( qw( Microsoft Google ) );

=head1 DESCRIPTION

Net::IP::Identifier identifies IP addresses or netblocks that lie within a
select group of pre-identified netblocks.  This package contains a
collection of identified entities (in the Plugins directory).  These are
either large, well known entities (i.e: Google and Microsoft) or they are
owners of netblocks that have produced a lot of SPAM that arrived at my
server.

=head2 Methods

=over

=item run()

This module is a modulino, meaning it may be used as a module or as a
script.  The B<run> method is called when there is no caller and it is used
as a script.  B<run> parses the command line arguments and calls B<new()> to
create the object.  If a filename is specified, that file is read as the
input, otherwise the command line is used.

Input (from a file or the command line) is scanned for things that look
like IP (v4 or v6) addresses or blocks.  For each matching item, the
B<Net::IP::Identifer> object's B<identify> method is called on it (see
below).  If a match is found, the entity is printed, otherwise the original
IP is printed.

Example:

    /path/to/perl5/Net/IP/Identifier.pm 8.8.8.8

or

    echo 8.8.8.8 | /path/to/perl5/Net/IP/Identifier.pm 

prints 'Google'.

For command line help, run:

    /path/to/perl5/Net/IP/Identifier.pm --help

=item new( [ options ] )

Creates a new Net::IP::Identifier object.  The following options are available,
and are also available as accessors:

=over

=item parents => boolean

A format modifier.  See B<identify> below.

=item cidr => boolean

A format modifier.  See B<identify> below.

=item joiners => ( [ IPv4_string, IPv6_string ] )

Returns a reference to an array of two strings to use when 'join'ing
pieces.  The default is [ ':', '.' ] which uses ':' on IPv4 addresses and
'.' on  IPv6 addresses.

=back

=item entities ( [ @modules ] )

Returns the list of Plugin objects currently in use.

If @modules is defined, it should be an array of names of the Plugin
objects to 'require' (they will replace the current list):

    $identifier->entities( qw(
        Net::IP::Identifier::Plugin::Microsoft
        Net::IP::Identifier::Plugin::Google
        ...
    ) );

If no plugin modules are loaded, and @modules is not defined, the import
list (defined at 'use' time) is loaded.  If there is no import list, all
available modules found in Net::IP::Identifier::Plugins are 'required' and
matched against.  Loading a reference to an empty array:

    $identifier->entities( [] );

also loads all available plugins.

B<modules> may be passed as a reference to an array:

    $identifier->entities ( \@modules );

Plugins can also be loaded selectively at 'use' time (see B<SYNOPSIS>).

=item identify( IP )

Try to identify IP with an entity.  IP may be a B<Net::IP> or
B<Net::IP::Identifier::Net> object or any of the string formats acceptable
to B<Net::IP>->new() or B<Net::IP::Identifier::Net>->new().

If the IP cannot be identified with an entity, B<undef> is returned.

If the IP belongs to an included identity (see B<PLUGINS>), the return value is
modified by the format flags.

When all modifiers are false, the return value is the name of
the entity (e.g: 'Yahoo').

When B<cidr> is true, the Net::IP::Identifier::Net object of the matching
netblock is appended to the result.

When B<parents> is true, any parent (and grandparent, etc) entities are
prepended to the result.

Flags may be used concurrently.

In scalar context, a string is return where the pieces are joined using
B<joiner>.  In array context, the array of pieces is returned.

=item join ( @parts )

Gets the B<joiners>, then scans B<@parts> looking for objects which I<can> identify
themselves as IPv4 vs. IPv6.  Uses the appropriate element of B<joiners>, and returns
a 'join'ed string.

=item tree_overlaps

During construction of the binary tree, there may be netblocks that overlap
with existing netblocks.  This function checks the tree for overlaps.  It
returns an array where each element represents an overlap.  Each overlap is
an array of B<Net::IP::Identifier::Binode> objects, the first one being the
parent of the overlap, and subsequent entries in the array being the
overlapping children.

When used as a modulino, the B<overlaps> command line argument runs this
method and prints the result.

=back

=head1 PLUGINS

Net::IP::Identifier uses the Module::Pluggable module to support plugins.
See B<entities> for details on controlling which Plugins are loaded.

Plugins uploaded to CPAN should be well known entities, or entities with
wide netblocks.  Let's not congest CPAN with a multitude of class C
netblocks.

Entities with child netblocks can name them in a B<children> subroutine.
If you want to add a netblock as a child, you'll need to arrange with the
parent's CPAN owner to add it.  This relationship is independant of the
network hierarchy, and is currently ignored by Net::IP::Identifier.

Plugins must satisfy the Net::IP::Identifier_Role (see Role::Tiny).
Supplying the entity name and setting the list of netblocks in B<ips> in
the B<new> method is sufficient.  See the existing Plugins for examples.

Test your plugin by running B<Identifier.pm> with the C<overlaps> flag.
C<overlaps> causes overlapping netblocks to be reported.  Overlaps are not
necessarily an error and there may be overlaps caused by modules other than
your new Plugin.

=head1 check_plugin

The B<check_plugin> script in the C<extra> directory checks the IP
addresses and blocks in your plugin source code.  It can also be used on
raw data such as a page from Hurricane Electric (thanks to Hurricane
Electric for providing this information from their BGP Toolkit):

    http://bgp.he.net/search?search[search]=baidu&commit=Search

Copy and paste the entire page into a file, then run:

    extra/check_plugin filename

The first part of the output is diagnostic output while running 'jwhois'
commands.  jwhois may fail to complete on some addresses.  Sometimes
re-running B<check_plugin> resolves the issue.  If not, remove that line from
the file and verify that address 'by hand', perhaps using a web-based WHOIS
such as

    http://whois.arin.net

B<check_plugin> builds a binary tree of the IP addresses and creates a list
of the IP addresses and blocks, printing diagnostic information as it goes.
You can invoke -v and -vv for extra levels of verbosity.  Then
B<check_plugin> prints a line: 'Result:' followed by output suitable for
inclusion in the Plugin module's $self->ips() declaration (in its B<new>
method).

You must provide a regular expression for matching the B<entity>.
B<check_plugin> expects to find that entity somewhere within the WHOIS
output (if not found, that net will not be included in the Results list).
The regular expression is extracted from the last name in a 'package'
declaration, from the file name, or from the text following
'_ENTITY_REGEX_' on any line.  The entity matching is done caselessly.

You can run, for example:

    extra/check_plugin [ -v | -vv ] lib/Net/IP/Identifier/Plugin/UPS.pm

to get a feeling for how it should look.

=head1 SEE ALSO

=over

=item Net::IP

=item Net::IP::Identifier::Net

=item Net::IP::Identifier::Plugins::Google (and other plugins in this directory)

=item Module::Pluggable

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
