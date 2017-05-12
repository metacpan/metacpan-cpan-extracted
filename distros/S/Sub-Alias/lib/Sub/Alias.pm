package Sub::Alias;
use warnings;
use strict;
use 5.008;

use Sub::Exporter -setup => {
    exports => [ 'alias' ],
    groups => { default => [ 'alias' ] }
};

use Devel::BeginLift qw(alias);

use Devel::Declare qw();

our $VERSION = '0.03';

sub alias {
    my ($new_name, $old_name) = @_;
    my $caller = caller;

    if (defined($new_name) && defined($old_name)) {
        _alias($new_name, $old_name, $caller);
    }
    else {
        my $line = Devel::Declare::get_linestr;
        my $offset = Devel::Declare::get_linestr_offset;

        my $line2 = $line;
        if ($line2 =~ s/alias/Sub::Alias::_alias/) {
            substr($line, $offset, 0) = $line2;
            Devel::Declare::set_linestr($line);
        }
    }
    return 1;
}


sub _alias {
    my ($new_name, $old_name, $caller) = @_;
    $caller ||= caller;

    no strict;
    no warnings;
    *{"$caller\::${new_name}"} = ref($old_name) ? $old_name : *{"$caller\::${old_name}"};

    return 1;
}

1;

__END__

=head1 NAME

Sub::Alias - Simple subroutine alias.

=head1 VERSION

This document describes Sub::Alias version 0.01

=head1 SYNOPSIS

    use Sub::Alias;

    sub name { "David" }
    alias get_name => 'name';

    print get_name; # "David"

=head1 DESCRIPTION

This module does a compile-time code injection to let you define
subroute aliases with their names, but not code refs.

The not-so-scarily-described way to alias a sub looks like this:

    sub name { "..." }
    *get_name = \&name;

As you can see, it's a bit of trouble to type the whole line without
without making your finger jammed unless you're using some smart text
editors.

=head1 INTERFACE

=over

=item alias $new_name => $old_name

This function is exported by default.

The alias subroutine can be referenced by its name:

    alias get_name => 'name';

Or by its reference:

    alias get_name => \&name;

Also notice that doing this will actually call the C<name> function:

    alias get_name => name;

However, C<get_name> will still be an alias to C<name> funciton after this
statement.

It is recommended that you just pass function names as strings.

B<NOTICE:> If your new name depends on runtime data:

    alias $new_foo => \&foo;

You need to put them in a single line alone.

=back

=head1 DEPENDENCIES

L<Devel::BeginLift>, L<Devel::Declare>, L<Sub::Exporter>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-sub-alias@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, 2009, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
