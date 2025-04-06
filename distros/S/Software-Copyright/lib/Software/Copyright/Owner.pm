#
# This file is part of Software-Copyright
#
# This software is Copyright (c) 2022 by Dominique Dumont <dod@debian.org>.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
package Software::Copyright::Owner;
$Software::Copyright::Owner::VERSION = '0.015';
use warnings;
use 5.20.0;
use utf8;
use Unicode::Normalize;

use Mouse;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

use overload '""' => \&stringify;

has name => (
    is => 'rw',
    isa => 'Str',
);

has record => (
    is => 'rw',
    isa => 'Str',
);

has email => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_email',
);

around BUILDARGS => sub ($orig, $class, @args) {
    my $params = {  } ;

    # detect garbage in string argument
    if ($args[0] !~ /^[[:alpha:]]/) {
        # don't try to be smart, keep the record as is: garbage in, garbage out
        $params->{record} = $args[0];
    }
    elsif ($args[0] =~ /\b(and|,)\b/) {
        # combined records, do not try to extract name and email.
        $params->{record} = NFC($args[0]);
    }
    elsif ($args[0] =~ /([^<]+)<([^>]+)>$/) {
        # see https://www.unicode.org/faq/normalization.html
        $params->{name} = NFC($1);
        $params->{email} = $2;
    }
    else {
        $params->{name} = NFC($args[0]);
    }
    return $class->$orig($params) ;
};

sub BUILD ($self, $args) {
    my $name = $self->name;
    if (defined $name) {
        $name =~ s/\s+$//;
        $name =~ s/^\s+//;
        $self->name($name);
    }
    return;
}

sub identifier ($self) {
    return $self->name // $self->record // '';
}

sub stringify ($self, $=1, $=1) {
    if (my $str = $self->name) {
        $str .= " <".$self->email.">" if $self->has_email;
        return $str;
    }
    else {
        return $self->record // '';
    }
}

1;

# ABSTRACT: Copyright owner class

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Copyright::Owner - Copyright owner class

=head1 VERSION

version 0.015

=head1 SYNOPSIS

 use Software::Copyright::Owner;

 # one owner
 my $owner = Software::Copyright::Owner->new('Joe <joe@example.com>');

 $owner->name; # => is "Joe"
 $owner->email; # => is 'joe@example.com'
 $owner->identifier; # => is 'Joe'

 # stringification
 my $s = "$owner"; # => is 'Joe <joe@example.com>'

 # several owners, separated by "and" or ","
 my $owner2 = Software::Copyright::Owner->new('Joe <joe@example.com>, William, Jack and Averell');

 $owner2->name; # => is undef
 $owner2->email; # => is undef
 $owner2->record; # => is 'Joe <joe@example.com>, William, Jack and Averell'
 $owner2->identifier; # => is 'Joe <joe@example.com>, William, Jack and Averell'

 # stringification
 $s = "$owner2"; # => is 'Joe <joe@example.com>, William, Jack and Averell'

=head1 DESCRIPTION

This class holds the name and email of a copyright holder.

=head1 CONSTRUCTOR

The constructor can be called without argument or with a string
containing a name and an optional email address. E.g:

 my $owner = Software::Copyright::Owner->new();
 my $owner = Software::Copyright::Owner->new('Joe');
 my $owner = Software::Copyright::Owner->new('Joe <joe@example.com>');

It can also be called with copyright assignment involving more than
one person. See synopsis for details.

=head1 Methods

=head2 name

Set or get owner's name. Note that names with Unicode characters are
normalized to Canonical Composition (NFC). Name can be empty when the
copyright owners has more that one name (i.e. C<John Doe and Jane
Doe>) or if the string passed to C<new()> contains unexpected
information (like a year).

=head2 record

Set or get the record of a copyright. The record is set by constructor
when the owner contains more than one name or if the owner contains
unexpected information.

=head2 identifier

Returns C<name> or C<record>.

=head2 email

Set or get owner's email

=head2 stringify

Returns a string containing name (or record) and email (if any) of the copyright
owner.

=head2 Operator overload

Operator C<""> is overloaded to call C<stringify>.

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Dominique Dumont <dod@debian.org>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
