package Role::MimeInfo;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Moo::Role;
use namespace::autoclean;

use File::MimeInfo        ();
use File::MimeInfo::Magic ();
use IO::Scalar            ();
use IO::ScalarArray       ();
use Scalar::Util          ();
use overload              ();

=head1 NAME

Role::MimeInfo - Bolt-on type checking against GNOME shared-mime-info

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Moo; # or Moose or Mouse or whatever

    with 'Role::MimeInfo';

    # are you ready to check some mime types???

=head1 METHODS

=head2 mimetype

Proxy for L<File::MimeInfo::Magic/mimetype>.

=cut

sub mimetype {
    my (undef, $obj) = @_;
    return unless defined $obj;

    # treat as a filename if not a ref
    my $ref = ref $obj or return File::MimeInfo::mimetype($obj);
    my $bl  = Scalar::Util::blessed($obj);

    if ($ref eq 'GLOB' or ($bl and $ref->can('seek') and $ref->can('read'))) {
        return File::MimeInfo::Magic::mimetype($obj);
    }
    elsif ($ref eq 'SCALAR') {
        $obj = IO::Scalar->new($obj);
    }
    elsif ($ref eq 'ARRAY') {
        $obj = IO::ScalarArray->new($obj);
    }
    elsif (my $ov = overload::Method($obj, '""')) {
        my $tmp = $ov->($obj);
        $obj = IO::Scalar->new(\$tmp);
    }
    else {
        Carp::croak("mimetype: don't know how to dispatch $ref");
    }

    File::MimeInfo::Magic::mimetype($obj);
}

=head2 mimetype_isa

Proxy for L<File::MimeInfo/mimetype_isa> with additional
behaviour for self-identity and recursive type checking.

=cut

sub mimetype_isa {
    my (undef, $child, $ancestor) = @_;
    return unless defined $child;

    # strip and lowercase the parameters
    $child =~ s/^\s*([^;[:space:]]+).*?/\L$1/;

    # start queueing it up
    my %t = ($child => 1);

    my $canon = File::MimeInfo::mimetype_canon($child);
    $t{$canon}++ if $canon and $canon ne $child;

    if (defined $ancestor) {
        $ancestor =~ s/^\s*([^;[:space:]]+).*?/\L$1/;
        return 1 if $t{$ancestor};

        # canonicalize the ancestor and try again
        $ancestor = File::MimeInfo::mimetype_canon($ancestor) || $ancestor;
        return 1 if $t{$ancestor};
    }

    # now we recursively (okay, iteratively) check
    my @q = ($child);
    do {
        # this second loop is necessary because we get a list here
        for my $t (File::MimeInfo::mimetype_isa(shift @q)) {
            $t = lc $t; # JIC
            push @q, $t unless defined $t{$t};
            $t{$t}++;
        }
    } while @q;

    # just give true or false if an ancestor was supplied
    return !!$t{lc $ancestor} if defined $ancestor;

    # otherwise just cough up the whole pile
    return sort keys %t;
}

=head1 SEE ALSO

=over 4

=item

L<File::MimeInfo>

=item

L<Moo>

=back

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 TODO

=over 4

=item

Expose the rest of the interface of L<File::MimeInfo> in a reasonable
way.

=back

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/doriantaylor/p5-role-mimeinfo/issues> .

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Role::MimeInfo
