package Solution::Error;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use Carp qw[];
    sub message { return $_[0]->{'message'} }
    sub fatal   { return $_[0]->{'fatal'} }

    sub new {
        my ($class, $args, @etc) = @_;
        $args
            = {message => (@etc ? sprintf($args, @etc) : $args)
               || 'Unknown error'}
            if $args
                && !(ref $args && ref $args eq 'HASH');
        $args->{'fatal'} = defined $args->{'fatal'} ? $args->{'fatal'} : 0;
        Carp::longmess() =~ m[^.+?\n\t(.+)]s;
        $args->{'message'} = sprintf '%s: %s %s', $class, $args->{'message'},
            $1;
        return bless $args, $class;
    }

    sub raise {
        my ($self) = @_;
        $self = ref $self ? $self : $self->new($_[1]);
        die $self->message if $self->fatal;
        warn $self->message;
    }
    sub render { return sprintf '[%s] %s', ref $_[0], $_[0]->message; }
    { package Solution::ArgumentError;   our @ISA = qw'Solution::Error' }
    { package Solution::ContextError;    our @ISA = qw'Solution::Error' }
    { package Solution::FilterNotFound;  our @ISA = qw'Solution::Error' }
    { package Solution::FileSystemError; our @ISA = qw'Solution::Error' }
    { package Solution::StandardError;   our @ISA = qw'Solution::Error' }
    { package Solution::SyntaxError;     our @ISA = qw'Solution::Error' }
    { package Solution::StackLevelError; our @ISA = qw'Solution::Error' }
}
1;
