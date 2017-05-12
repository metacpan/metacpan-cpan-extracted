package SparkX::Form::Field::Validator::Regex;
our $VERSION = '0.2102';


# ABSTRACT: Validates a field matches a regular expression

use Moose::Role;

has regex => (
    isa      => 'Maybe[RegexpRef]',
    is       => 'rw',
    required => 0,
    default  => undef,
);

has errmsg_regex => (
    isa      => 'Str',
    is       => 'rw',
    required => 0,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        $self->human_name . ' failed the regex.'
    },
);

sub _regex {
    my ($self) = @_;

    return unless $self->regex;

    if ($self->value !~ $self->regex) {
        $self->error($self->errmsg_regex);
    }
    return $self;
}

after '_validate' => sub { return shift->_regex };

1;



=pod

=head1 NAME

SparkX::Form::Field::Validator::Regex - Validates a field matches a regular expression

=head1 VERSION

version 0.2102

=head1 DESCRIPTION

A regular expression validation mix-in. Adds two fields plus action.
Makes sure that C<value> matches the expression.

=head1 ACCESSORS

=head2 C<regex> => Str

RegexRef to match.
Required, no default.

=head2 errmsg_regex => Str

Allows you to provide a custom error message for when the match fails.
Required, no default.



=head1 AUTHOR

  James Laver L<http://jameslaver.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by James Laver C<< <sprintf qw(%s@%s.%s cpan jameslaver com)> >>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

