#
# This file is part of Software-Copyright
#
# This software is Copyright (c) 2022 by Dominique Dumont <dod@debian.org>.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
package Software::Copyright;
$Software::Copyright::VERSION = '0.007';
use 5.20.0;
use warnings;
use utf8;
use Unicode::Normalize;

use Mouse;
use Mouse::Util::TypeConstraints;
use MouseX::NativeTraits;

use Storable qw/dclone/;

use Software::Copyright::Statement;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

use overload '""' => \&stringify;
use overload 'eq' => \&is_equal;
use overload 'ne' => \&is_not_equal;

sub _clean_copyright ($c) {
    # cut off everything after and including the first non-printable
    # (spare \n and \c though)
    $c =~ s![\x00-\x09\x0b\x0c\x0e\x1f].*!!;
    return $c;
}

sub _create_or_merge ($result, $c) {
    my $st = Software::Copyright::Statement->new($c);
    my $name = NFKD($st->name // '');
    if ($result->{$name}) {
        $result->{$name}->merge($st);
    }
    elsif ($st->name) {
        $result->{$name} = $st;
    }
    elsif ($st->record) {
        $result->{$st->record} = $st;
    }
    else {
        $result->{unknown} = $st;
    }

    return;
}

subtype 'Copyright::Software::StatementHash' => as 'HashRef[Software::Copyright::Statement]';
coerce 'Copyright::Software::StatementHash' => from 'Str' => via {
    my $str = $_ ;
    my $result = {} ;
    my @year_only_data;
    my @data = split( m!(?:\s+/\s+)|(?:\s*\n\s*)!, $str);
    # split statement that can be licensecheck output or debfmt data
    foreach my $c ( @data ) {
        if ($c =~ /^[\d\s,.-]+$/) {
            push @year_only_data, $c;
        }
        else {
            # copyright contain letters, so hopefully some name
            _create_or_merge($result, $c);
        }
    }

    # year only data is dropped when other more significant data is
    # present (with names)
    if (@data eq @year_only_data) {
        # got only year data, save it.
        foreach my $c ( @data ) {
            _create_or_merge($result, $c);
        }
    }
    return $result;
};

has statement_by_name => (
    is => 'ro',
    coerce => 1,
    traits => ['Hash'],
    isa => 'Copyright::Software::StatementHash',
    default => sub { {} },
    handles => {
        statement_list => 'values',
        owners => 'keys',
        statement => 'get',
        set_statement => 'set',
    },
    required => 1,
);

around BUILDARGS => sub ($orig, $class, @args) {
    my $str = _clean_copyright($args[0]);

    # cleanup
    $str =~ /^[\s\W]+|[\s\W]+$/g;

    return $class->$orig({
        statement_by_name => $str,
    }) ;
};

sub merge ($self, $input) {
    my $other = ref($input) ? $input : Software::Copyright->new($input);

    foreach my $owner ($other->owners) {
        my $from = $other->statement($owner);
        my $target = $self->statement($owner);
        if ($target) {
            $target->merge($from);
        }
        else {
            $self->set_statement($owner, dclone($from));
        }
    }
    return;
}

sub stringify ($self, $=1, $=1) {
    return join("\n", reverse sort $self->statement_list);
}

sub is_equal ($self, $other, $=1) {
    return $self->stringify eq $other->stringify;
}

sub is_not_equal ($self, $other, $=1) {
    return $self->stringify ne $other->stringify;
}

sub is_valid ($self) {
    return (scalar grep {$_->name || $_->record } $self->statement_list) ? 1 : 0;
}

sub contains($self, $input) {
    my $other = ref($input) ? $input : Software::Copyright->new($input);

    my $result = 1 ;
    foreach my $other_owner ($other->owners) {
        my $other_st = $other->statement($other_owner);
        my $self_st = $self->statement($other_owner);
        if ($self_st) {
            $result &&= $self_st->contains($other_st);
        }
        else {
            $result = 0;
        }
    }
    return $result;
}

1;

# ABSTRACT: Copyright class

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Copyright - Copyright class

=head1 VERSION

version 0.007

=head1 SYNOPSIS

 use Software::Copyright;

 my $copyright = Software::Copyright->new('2020,2021, Joe <joe@example.com>');

 # stringification
 my $s = "$copyright"; # => is "2020, 2021, Joe <joe\@example.com>"

 # add with merge
 $copyright->merge('2018-2020 Averell');

 # after addition
 $s = "$copyright"; # => is "2020, 2021, Joe <joe\@example.com>\n2018-2020, Averell"

 # merge statement which adds email
 $copyright->merge('2016, Averell <averell@example.com>');

 $s = "$copyright"; # => is "2020, 2021, Joe <joe\@example.com>\n2016, 2018-2020, Averell <averell\@example.com>"

=head1 DESCRIPTION

This class holds a copyright statement, i.e. a set of year range, name
and email.

=head1 CONSTRUCTOR

The constructor is called with a copyright statement string. This string can be
spread on several lines. The constructor is also compatible with the string given by
Debian's L<licensecheck>, i.e. the statements can be separated by "C</>".

=head1 Methods

=head2 statement

Get the L<Software::Copyright::Statement> object of a given user.

=head2 statement_list

Returns a list of L<Software::Copyright::Statement> object for all users.

=head2 stringify

Returns a string containing a cleaned up copyright statement.

=head2 is_valid

Returns true if the copyright contains valid records, i.e. records with names.

=head2 owners

Return a list of statement owners. An owner is either a name or a record.

=head2 statement

Returns the L<Software::Copyright::Statement> object for the given owner:

  my $statement = $copyright->statement('Joe Dalton');

=head2 merge

Merge in a statement. This statement is either merged with a existing
statement when the owner match or appended to the list of statements.

The statement parameter can either be a string or an
L<Software::Copyright::Statement> object.

=head2 contains

Return 1 if the other copyright is contained in current copyright,
i.e. all other statements are contained in current statements (See
L<Copyright::Statement/"contains"> for details on statement
containment).

For instance:

=over

=item *

C<2016, Joe> copyright is contained in C<2014-2020, Joe> copyright.

=item *

C<2016, Joe> is contained in C<2014-2020, Joe / 2019, Jack>

=item *

C<2010, Joe> is B<not> contained in C<2014-2020, Joe>

=back

=head1 Operator overload

Operator C<"">, C<eq> and C<ne> are overloaded.

=head1 See also

L<Software::Copyright::Statement>, L<Software::Copyright::Owner>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Dominique Dumont <dod@debian.org>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
