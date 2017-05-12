## no critic
package Shell::Verbose;
{
  $Shell::Verbose::VERSION = '0.4';
}
## use critic
use strict;
use warnings;

=head1 NAME

Shell::Verbose - A verbose version of system()

=head1 SYNOPSIS

    # Nothing is exported by default
    use Shell::Verbose qw/verboseSystem vsys/;

    verboseSystem('echo "foo"');
    # echo "foo"
    # foo

    # Short form
    vsys('echo "foo"');
    # echo "foo"
    # foo

    # Returns a true value when the command is successful
    print "How did true fail!?\n" unless (vsys('true');

    Shell::Verbose->prefix('===> ');
    # ===> echo 'foo'
    # foo

    Shell::Verbose->before('Running the next line');
    # Running the next line
    # ===> echo 'foo'
    # foo

    Shell::Verbose->after('That was easy');
    # Running the next line
    # ===> echo 'foo'
    # foo
    # That was easy

=head1 DESCRIPTION

A simple wrapper for system() that prints the command

=head1 METHODS

=cut

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA = qw/Exporter/;
    @EXPORT_OK = qw/verboseSystem vsys/;
}

my $prefix = '';
my $before = '';
my $after = '';

sub prefix {
    shift;
    $prefix = shift;
    return $prefix
}

sub before {
    shift;
    $before = shift;
    return $before;
}

sub after {
    shift;
    $after = shift;
    return $after;
}

=head2 verboseSystem($command)

Run the specified command, printing the command along with before, prefix,
and after if defined.

Returns the inverse of shell success, that is a true value (1) if the command
exited with zero status (success) and a false value (0) if the command exited
with a non-zero status (failure).  See $? ($CHILD_ERROR) for the real deets.

=cut

sub verboseSystem {
    my $command = shift;

    print "$before\n" if ($before);
    print $prefix . $command . "\n";
    my $ret = (system($command) == 0);
    print "$after\n" if ($after);
    return $ret;
}

sub vsys {
    verboseSystem(@_);
}

=head1 SOURCE

L<https://github.com/dinomite/Shell-Verbose>

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>

=cut

1;
