package MySQL::Config;

# ----------------------------------------------------------------------
# MySQL::Config - 
# Copyright (C) 2003 darren chamberlain <darren@cpan.org>
# ----------------------------------------------------------------------

use strict;
use base qw(Exporter);
use vars qw($VERSION $GLOBAL_CNF @EXPORT @EXPORT_OK);

use Carp qw(carp);
use File::Spec;

$VERSION    = '1.04';
$GLOBAL_CNF = "/etc/%s.cnf" unless defined $GLOBAL_CNF;
@EXPORT     = qw(load_defaults);
@EXPORT_OK  = qw(parse_defaults);

# ======================================================================
#                        --- Public Functions ---
# ======================================================================

sub load_defaults {
    my ($conf_file, $groups, $argc, $argv) = @_;
    my ($user_cnf, $ini, $field);
    $ini = [ ];

    # ------------------------------------------------------------------
    # Sanity checking:
    #   * $conf_file should be a string, defaults to "my"
    #   * $groups should be a ref to an array
    #   * $argc should be a ref to a scalar
    #   * $argv should be a ref to an array
    # ------------------------------------------------------------------
    $conf_file = "my" unless defined $conf_file && ! ref($conf_file);
    $groups = [ $groups ]
        unless ref $groups eq 'ARRAY';

    if (defined $argc) {
        $argc = \$argc
            unless ref $argc eq 'SCALAR';
    }
    else {
        $argc = \(my $i = 0);
    }

    $argv = \@ARGV unless defined $argv;
    $argv = [ $argv ]
        unless ref $argv eq 'ARRAY';

    $user_cnf = File::Spec->catfile($ENV{HOME}, ".$conf_file.cnf");

    # ------------------------------------------------------------------
    # Parse the global config and user's config
    # ------------------------------------------------------------------
    _parse($ini, sprintf $GLOBAL_CNF, $conf_file);
    _parse($ini, $user_cnf);

    # ------------------------------------------------------------------
    # Pull out the appropriate pieces, based on @$groups
    # ------------------------------------------------------------------
    @$groups = map { $_->[0] } @$ini unless @$groups;
    $groups = join '|', map { quotemeta($_) } @$groups;

    push @$argv, map { $$argc++; sprintf "--%s=%s", $_->[1], $_->[2] }
                 grep { $_->[0] =~ /^$groups$/ } @$ini;

    1;
}

sub parse_defaults {
    my ($conf_file, $groups) = @_;
    my ($count, $argv, %ini);
    $argv = [ ];

    load_defaults($conf_file, $groups, \$count, $argv);

    for (@$argv) {
        next unless /^--(.*?)=(.*)$/;
        my $name = $1;
        my $value = $2; 

        if ($value =~ /=/) {
            $ini{ $name } = { }
                unless exists($ini{ $name }) &&
                    ref($ini{ $name }) eq 'HASH';
            my ($subname, $subvalue) = split /\s*=\s*/, $value, 2;
            $ini{ $name }->{ $subname } = $subvalue;
        }
        else {
            $ini{ $name } = $value;
        }
    }

    return wantarray ? %ini : \%ini;
}

# ======================================================================
#                        --- Private Functions ---
# ======================================================================

# ----------------------------------------------------------------------
# _parse($file)
#
# Parses an ini-style file into an array of [ group, name, value ]
# array refs.
# ----------------------------------------------------------------------
sub _parse {
    my $ini = shift;
    my $file = shift;
    my $current;
    local ($_, *INI);

    return { } unless -f $file && -r _;

    $ini ||= [ ];
    unless (open INI, $file) {
        carp "Couldn't open $file: $!";
        return { };
    }
    while (<INI>) {
        s/[;#].*$//;
        s/^\s*//;
        s/\s*$//;

        next unless length;

        /^\s*\[(.*)\]\s*$/
            and $current = $1, next;

        $_ = join '=', $_, 1
            unless /=/;

        my ($n, $v) = split /\s*=\s*/, $_, 2;
        if ($v =~ /\s/) {
            $v =~ s/"/\\"/g;
            $v = qq("$v") 
        }

        push @$ini, [ $current, $n, $v ];
    }

    unless (close INI) {
        carp "Couldn't close $file: $!";
    }

    return $ini;
}

1;

__END__

=head1 NAME

MySQL::Config - Parse and utilize MySQL's /etc/my.cnf and ~/.my.cnf files

=head1 SYNOPSIS

    use MySQL::Config;

    my @groups = qw(client myclient);
    my $argc = 0;
    my @argv = ();

    load_defaults "my", \@groups, \$argc, \@argv;

=head1 DESCRIPTION

C<MySQL::Config> emulates the C<load_defaults> function from
F<libmysqlclient>.  Just like C<load_defaults>, it will fill an aray
with long options, ready to be parsed by C<getopt_long>, a.k.a.
C<Getopt::Long>.

=head1 THE my.cnf FILE

MySQL's F<my.cnf> file is a mechanism for storing and reusing command
line arguments.  These command line arguments are grouped into
I<groups> using a simple INI-style format:

    ; file: ~/.my.cnf

    [client]
    user = darren
    host = db1
    pager = less -SignMEX

    [mytop]
    color = 1
    header = 0

Each element in C<[>, C<]> pairs is a I<group>, and each call to
C<load_defaults> will specify 0 or more groups from which to grab
options.  For example, grabbing the I<client> group from the above
config file would return the I<user>, I<host>, and I<pager> items.
These items will be formatted as command line options, e.g.,
I<--user=darren>.

=head1 USING MySQL::Config

=head2 load_defaults("name", \@groups, \$count, \@ary)

C<load_defaults> takes 4 arguments: a string denoting the name of the
config file (which should generally be I<my>); a reference to an array
of groups from which options should be returned; a reference to a
scalar that will hold the total number of parsed elements; and a
reference to an array that will hold the final versions of the
extracted name, value pairs.  This final array will be in a format
suitable for processing with C<Getopt::Long>:

    --user=username
    --password=password

and so on.

If the final array reference is missing, C<@ARGV> will be used.  Options
will be pushed onto the end of the array, leaving what is already in
place undisturbed.

The scalar (the third argument to C<load_defaults>) will contain the
number of elements parsed from the config files.

=head2 parse_defaults("name", \@groups)

C<load_defaults> has an un-Perlish interface, mostly because it is
exactly the same signature as the version from the C API.  There is
also a function, not exported by default, called C<parse_defaults>,
which returns a hash of parsed (name, value) pairs (or a hashref
in scalar context):

    use MySQL::Config qw(parse_defaults);

    my %cfg = parse_defaults "my", \@groups;

C<%cfg> looks like:

    %cfg = (
        "user" => "username",
        "password" => "password",
    )

and so on.  This might be a more natural interface for some programs;
however, C<load_defaults> is more true to the original.

Because C<parse_defaults> flattens the arguments into a hash, it makes
special allowances for variables that contain multiple C<=>; these are
turned into nested hashes.  For example, the MySQL's I<set-variable>
option can contain name value pairs, like so:

    set-variable    = key_buffer=16M
    set-variable    = max_allowed_packet=1M
    set-variable    = table_cache=64
    set-variable    = sort_buffer=512K
    set-variable    = net_buffer_length=8K
    set-variable    = myisam_sort_buffer_size=8M

These will be turned into a nested hash like this:

    'set-variable' => {
                        'myisam_sort_buffer_size' => '8M',
                        'sort_buffer' => '512K',
                        'max_allowed_packet' => '16M',
                        'key_buffer' => '16M',
                        'table_cache' => 64,
                        'net_buffer_length' => '8K'
                      },

This is not done for C<load_defaults>, as C<Getopt::Long> will
correctly handle variables with embedded C<=> if the option is
passed a hash reference.

=head1 USING SOMETHING OTHER THAN "my" AS THE FIRST STRING

This string controls the name of the configuration file; the names
work out to, basically F<~/.${cfg_name}.cnf> and
F</etc/${cnf_name}.cnf>.

If you are using this module for mysql clients, then this should
probably remain I<my>.  Otherwise, you are free to mangle this however
you choose:

    $ini = parse_defaults 'superapp', [ 'foo' ];

=head1 SUPPORT

C<MySQL::Config> is supported by the author.

=head1 VERSION

This is C<MySQL::Config>, version 1.04.

=head1 AUTHOR

darren chamberlain E<lt>darren@cpan.orgE<gt>

=head1 COPYRIGHT

(C) 2003 darren chamberlain

This library is free software; you may distribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Perl>
