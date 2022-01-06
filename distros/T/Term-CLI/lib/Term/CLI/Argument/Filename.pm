#=============================================================================
#
#       Module:  Term::CLI::Argument::Filename
#
#  Description:  Class for file name arguments in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  23/01/18
#
#   Copyright (c) 2018 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Argument::Filename 0.054002;

use 5.014;
use warnings;

use Moo 1.000001;
use namespace::clean 0.25;
extends 'Term::CLI::Argument';

use File::Glob 'bsd_glob';
use Fcntl ':mode';

use namespace::clean;

sub complete {
    my $self    = shift;
    my $partial = shift;

    my $func_ref = $self->term->Attribs->{filename_completion_function}
        or return $self->_glob_complete($partial);

    if ($func_ref) {
        my $state = 0;
        my @list;
        while ( my $f = $func_ref->( $partial, $state ) ) {
            push @list, $f;
            $state = 1;
        }
        return @list;
    }
}

sub _glob_complete {
    my ( $self, $partial ) = @_;
    my @list = bsd_glob("$partial*");

    return if @list == 0;

    if (@list == 1) {
        if (-d $list[0]) {
            # Dumb trick to get readline to expand a directory
            # with a trailing "/", but *not* add a space.
            # Simulates the Gnu way of doing it.
            return ("$list[0]/", "$list[0]//");
        }
        return @list;
    }

    # If there is more than one possible completion,
    # add filetype suffixes.
    foreach (@list) {
        lstat;
        if ( -l _ )  { $_ .= q{@}; next }
        if ( -d _ )  { $_ .= q{/}; next }
        if ( -c _ )  { $_ .= q{%}; next }
        if ( -b _ )  { $_ .= q{#}; next }
        if ( -S _ )  { $_ .= q{=}; next }
        if ( -p _ )  { $_ .= q{=}; next }
        if ( -x _ )  { $_ .= q{*}; next }
    }
    return @list;
}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Filename - class for file name arguments in Term::CLI

=head1 VERSION

version 0.054002

=head1 SYNOPSIS

 use Term::CLI::Argument::Filename;

 my $arg = Term::CLI::Argument::Filename->new(name => 'arg1');

=head1 DESCRIPTION

Class for file name arguments in L<Term::CLI>(3p). Inherits from
the L<Term::CLI::Argument>(3p) class.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Argument>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

See L<Term::CLI::Argument>(3p).

=head1 ACCESSORS

See L<Term::CLI::Argument>(3p).

=head1 METHODS

See L<Term::CLI::Argument>(3p). Additionally:

=over

=item B<complete> ( I<PARTIAL> )

If present, use the C<filename_completion_function> function listed
in L<Term::ReadLine>'s C<Attribs>, otherwise use L<bsd_glob from
File::Glob|File::Glob/bsd_glob>.

Not every C<Term::ReadLine> implementation implements its own
filename completion function. The ones that do will ave the
C<Attrib-E<gt>{filename_completion_function}> attribute set.
L<Term::ReadLine::Gnu> does this, while L<Term::ReadLine::Perl> doesn't.

=back

=head1 SEE ALSO

L<Term::CLI::Argument>(3p),
L<Term::ReadLine::Gnu>(3p),
L<File::Glob>(3p),
L<Term::CLI>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
