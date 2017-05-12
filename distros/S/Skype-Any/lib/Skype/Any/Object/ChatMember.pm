package Skype::Any::Object::ChatMember;
use strict;
use warnings;
use parent qw/Skype::Any::Object/;

sub property { shift->SUPER::property('CHATMEMBER', @_) }

__PACKAGE__->_mk_bool_property(qw/is_active/);

1;
__END__

=head1 NAME

Skype::Any::Object::ChatMember - ChatMember object for Skype::Any

=head1 SYNOPSIS

    use Skype::Any;

    my $skype = Skype::Any->new;
    my $chatmember = $skype->chatmember($id);

=head1 METHODS

=over 4

=item C<< $chatmember->property($property[, $value]) >>

=over 4

=item chatname

=item identity

=item role

=item is_active

=back

=back

=cut
