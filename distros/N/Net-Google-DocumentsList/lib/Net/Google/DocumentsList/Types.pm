package Net::Google::DocumentsList::Types;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use DateTime::Format::Atom;

subtype 'Net::Google::DocumentsList::Types::ACL::Scope'
    => as 'HashRef'
    => where {
        my $args = shift;
#        scalar keys %$args == 2 &&
        defined $args->{type};
#        defined $args->{value};
    };

subtype 'Net::Google::DocumentsList::Types::DateTime'
    => as 'DateTime';

coerce 'Net::Google::DocumentsList::Types::DateTime'
    => from 'Str'
    => via {
        DateTime::Format::Atom->new->parse_datetime(shift);
    };

1;
