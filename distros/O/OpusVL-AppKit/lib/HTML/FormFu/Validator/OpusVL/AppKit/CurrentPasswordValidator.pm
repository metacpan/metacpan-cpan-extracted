package HTML::FormFu::Validator::OpusVL::AppKit::CurrentPasswordValidator;

use strict;
use warnings;

use base 'HTML::FormFu::Validator';

sub validate_value {
    my ( $self, $value, $params ) = @_;

    my $c = $self->form->stash->{context};

    return 1 if($c->authenticate({ username => $c->user->username, password => $value }));

    die HTML::FormFu::Exception::Validator->new({
            message => 'Invalid password',
        });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Validator::OpusVL::AppKit::CurrentPasswordValidator

=head1 VERSION

version 2.29

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
