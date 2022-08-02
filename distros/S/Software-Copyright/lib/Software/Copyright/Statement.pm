#
# This file is part of Software-Copyright
#
# This software is Copyright (c) 2022 by Dominique Dumont <dod@debian.org>.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
package Software::Copyright::Statement;
$Software::Copyright::Statement::VERSION = '0.003';
use 5.20.0;
use warnings;

use Mouse;
use Array::IntSpan;
use Carp;
use Software::Copyright::Owner;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

use overload '""' => \&stringify;
use overload 'cmp' => \&compare;

has span => (
    is => 'ro',
    isa => 'Array::IntSpan',
    required => 1 , # may be an empty span
);

sub range ($self) {
    return scalar $self->span->get_range_list;
}

has owner => (
    is => 'rw',
    isa => 'Software::Copyright::Owner',
    required => 1,
    handles => {
        map { $_ => $_ } qw/name email record identifier/
    },
);

sub __clean_copyright ($c) {
    $c =~ s/^&copy;\s*//g;
    $c =~ s/\(c\)\s*//g;
    $c =~ s/(?<=\b\d{4})\s*-\s*\d{4}(?=\s*-\s*(\d{4})\b)//g;
    $c =~ s/(\d+)\s*-\s*(\d+)/$1-$2/g;
    $c =~ s/\b(\d{4}),?\s+([\S^\d])/$1, $2/g;
    $c =~ s/\s+by\s+//g;
    $c =~ s/(\\n)*all\s+rights?\s+reserved\.?(\\n)*\s*//gi; # yes there are literal \n
    $c = 'no-info-found' if $c =~ /^\*No/;
    $c =~ s/\(r\)//g;
    $c =~ s!^[\s,/*]|[\s,#/*-]+$!!g;
    $c =~ s/--/-/g;
    $c =~ s!\s+\*/\s+! !;
    # libuv1 has copyright like "2000, -present"
    $c =~ s![,\s]*-present!'-'.(localtime->year() + 1900)!e;
    # cleanup markdown copyright
    $c =~ s/\[([\w\s]+)\]\(mailto:([\w@.+-]+)\)/$1 <$2>/;
    return $c;
}

sub __split_copyright ($c) {
    my ($years,$owner) = $c =~ /^(\d\d[\s,\d-]+)(.*)/;
    # say "undef year in $c" unless defined $years;
    if (not defined $years) {
        # try owner and years in reversed order (works also without year)
        ($owner,$years) = $c =~ m/(.*?)(\d\d[\s,\d-]+)?$/;
    }

    return $c unless $owner;

    my @data = defined $years ? split /(?<=\d)[,\s]+/, $years : ();
    $owner =~ s/^[\s.,-]+|[\s,*-]+$//g;
    return ($owner,@data);
}

around BUILDARGS => sub ($orig, $class, @args) {
    my $c = __clean_copyright($args[0]);
    my ($owner_str, @data) = __split_copyright($c);

    my $span = Array::IntSpan->new();
    my $owner = Software::Copyright::Owner->new($owner_str);

    foreach my $year (@data) {
        last if $year =~ /[^\d-]/; # bail-out
        # take care of ranges written like 2002-3
        $year =~ s/^(\d\d\d)(\d)-(\d)$/$1$2-$1$3/;
        # take care of ranges written like 2014-15
        $year =~ s/^(\d\d)(\d\d)-(\d\d)$/$1$2-$1$3/;
        eval {
            $span->set_range_as_string($year, $owner->identifier);
        };
        if ($@) {
            warn "Invalid year span: '$year': $@";
            last;
        }
    }
    $span->consolidate();

    return $class->$orig({
        span => $span,
        owner => $owner,
    }) ;
};

sub stringify ($self,$=1,$=1) {
    my $range = $self->span->get_range_list;
    return $range ? $range . ', '. $self->owner : $self->owner;
}

sub compare ($self, $other, $swap) {
    # we must force stringify before calling cmp
    return "$self" cmp "$other";
}

sub merge ($self, $other) {
    if ($self->identifier eq $other->identifier ) {
        $self->email($other->email) if $other->email;
        $self->span->set_range_as_string(scalar $other->span->get_range_list, $other->identifier);
        $self->span->consolidate();
    }
    else {
        croak "Cannot merge statement with mismatching owners";
    }
}

1;

# ABSTRACT: single copyright statement class

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Copyright::Statement - single copyright statement class

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Software::Copyright::Statement;

 my $statement = Software::Copyright::Statement->new('2020,2021, Joe <joe@example.com>');

 $statement->name; # => is "Joe"
 $statement->email; # => is 'joe@example.com'
 $statement->range; # => is '2020, 2021'

 # merge records
 $statement->merge(Software::Copyright::Statement->new('2022, Joe <joe@example.com>'));
 $statement->range; # => is '2020-2022'

 # stringification
 "$statement"; # => is '2020-2022, Joe <joe@example.com>'

=head1 DESCRIPTION

This class holds one copyright statement, i.e. year range, name
and email of a copyright statement.

On construction, a cleanup is done to make the statement more
standard. Here are some cleanup example:

 2002-6 Joe => 2002-2006, Joe
 2001,2002,2003,2004 Joe => 2001-2004, Joe
 # found in markdown documents
 2002 Joe mailto:joe@example.com => 2002, Joe <joe@example.com>

=head1 CONSTRUCTOR

The constructor can be called without argument or with a string
containing:

=over

=item *

a year range (optional)

=item *

a name (mandatory)

=item *

an email address (optional)

=back

E.g:

 my $st = Software::Copyright::Statement->new();
 my $st = Software::Copyright::Statement->new('2002, Joe <joe@example.com>');

=head1 Methods

=head2 name

Set or get owner's name

=head2 email

Set or get owner's name

=head2 owner

Returns a L<Software::Copyright::Owner> object. This object can be
used as a string.

=head2 merge

Merge 2 statements. Note that the 2 statements must belong to the same
owner (the name attributes must be identical).

See the Synopsis for an example.

=head2 stringify

Returns a string containing a year range (if any), a name and email
(if any) of the copyright owner.

=head2 Operator overload

Operator C<""> is overloaded to call C<stringify>.

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Dominique Dumont <dod@debian.org>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
