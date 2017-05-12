use Modern::Perl;
package Net::OpenXchange::Module::Contact;
BEGIN {
  $Net::OpenXchange::Module::Contact::VERSION = '0.001';
}

use Moose;
use namespace::autoclean;

# ABSTRACT: OpenXchange contact module

use HTTP::Request::Common;
use Net::OpenXchange::Object::Contact;

has 'path' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'contacts',
);

has 'class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'Net::OpenXchange::Object::Contact',
);

with 'Net::OpenXchange::Module';

sub all {
    my ($self, %args) = @_;

    my $req = GET(
        $self->req_uri(
            action  => 'all',
            columns => $self->columns,
            folder => $args{folder}->id,
        )
    );

    my $res = $self->_send($req);
    return map { $self->class->thaw($_) } @{ $res->{data} };
}

__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Module::Contact - OpenXchange contact module

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Module::Contact interfaces with the calendar API of
OpenXchange. It works with instances of
L<Net::OpenXchange::Object::Contact|Net::OpenXchange::Object::Contact>.

When using L<Net::OpenXchange|Net::OpenXchange>, an instance of this class is
provided as the C<contact> attribute.

=head1 METHODS

=head2 all

    my @contacts = $module_calendar->all(folder => $folder);

Fetch all contacts from the given folder

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

