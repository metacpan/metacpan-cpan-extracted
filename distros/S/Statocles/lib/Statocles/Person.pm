package Statocles::Person;
our $VERSION = '0.086';
# ABSTRACT: Information about a person, including name and e-mail

#pod =head1 SYNOPSIS
#pod
#pod     # site.yml
#pod     site:
#pod         $class: Statocles::Site
#pod         author:
#pod             $class: Statocles::Person
#pod             name: Doug Bell
#pod             email: doug@example.com
#pod
#pod     # Perl code
#pod     my $person = Statocles::Person->new(
#pod         name => 'Doug Bell',
#pod         email => 'doug@example.com',
#pod     );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class stores information about a person, most commonly an author of
#pod a site or a document.
#pod
#pod This class can parse plain strings like C<< Doug Bell <doug@example.com> >>
#pod into an object with name and e-mail set correctly.
#pod
#pod Person objects stringify into the C<name> field, for
#pod backwards-compatibility.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Statocles::Document/author>
#pod
#pod =item L<Statocles::Site/author>
#pod
#pod =back
#pod
#pod =cut

use Statocles::Base 'Class';
use overload
    q{""} => sub { shift->name },
    ;

#pod =attr name
#pod
#pod The author's name. Required.
#pod
#pod =cut

has name => (
    is => 'rw',
    isa => Str,
    required => 1,
);

#pod =attr email
#pod
#pod The author's email. Optional.
#pod
#pod =cut

has email => (
    is => 'rw',
    isa => Str,
);

#pod =method new
#pod
#pod     my $person = Statocles::Person->new(
#pod         name => 'Doug Bell',
#pod         email => 'doug@example.com',
#pod     );
#pod
#pod     my $person = Statocles::Person->new( 'Doug Bell <doug@example.com>' );
#pod
#pod Construct a new Person object. Arguments can be a list of name/value pairs, or
#pod a single string with the format C<< Name <email@domain> >> (the e-mail part
#pod is optional).
#pod
#pod =cut

sub BUILDARGS {
    my ( $class, @args ) = @_;

    return $args[0] if @args == 1 && ref $args[0] eq 'HASH';

    if ( @args == 1 ) {
        if ( $args[0] =~ s/\s*<([^>]+)>\s*// ) {
            @args = (
                name => $args[0],
                email => $1,
            );
        }
        else {
            @args = (
                name => $args[0],
            );
        }
    }

    return { @args };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Person - Information about a person, including name and e-mail

=head1 VERSION

version 0.086

=head1 SYNOPSIS

    # site.yml
    site:
        $class: Statocles::Site
        author:
            $class: Statocles::Person
            name: Doug Bell
            email: doug@example.com

    # Perl code
    my $person = Statocles::Person->new(
        name => 'Doug Bell',
        email => 'doug@example.com',
    );

=head1 DESCRIPTION

This class stores information about a person, most commonly an author of
a site or a document.

This class can parse plain strings like C<< Doug Bell <doug@example.com> >>
into an object with name and e-mail set correctly.

Person objects stringify into the C<name> field, for
backwards-compatibility.

=head1 ATTRIBUTES

=head2 name

The author's name. Required.

=head2 email

The author's email. Optional.

=head1 METHODS

=head2 new

    my $person = Statocles::Person->new(
        name => 'Doug Bell',
        email => 'doug@example.com',
    );

    my $person = Statocles::Person->new( 'Doug Bell <doug@example.com>' );

Construct a new Person object. Arguments can be a list of name/value pairs, or
a single string with the format C<< Name <email@domain> >> (the e-mail part
is optional).

=head1 SEE ALSO

=over

=item L<Statocles::Document/author>

=item L<Statocles::Site/author>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
